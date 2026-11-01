#!/usr/bin/env lua
-- Test corpus for webveld-profile-check.lua in pure Lua.
--
-- Three things are asserted, and the third is the one that matters most:
--
--   1. Positive fixtures pass the profile they claim.
--   2. Negative fixtures are rejected -- a checker that passes everything would
--      make the first set meaningless.
--   3. Every positive fixture also conforms to full WebVeld, and every pico
--      fixture also conforms to nano. That is the profiles' "upward validity"
--      claim, which both documents make by construction; this checks it holds
--      against the implementations rather than only in the prose.

local checker   = 'tools/validator/webveld-profile-check.lua'
local validator = 'tools/validator/webveld-validate.lua'

local cf = io.open(checker, "r")
if not cf then io.stderr:write("cannot find " .. checker .. "\n"); os.exit(1) end
cf:close()
local vf = io.open(validator, "r")
if not vf then io.stderr:write("cannot find " .. validator .. "\n"); os.exit(1) end
vf:close()

local dir = 'tools/validator/tests/profile'

local pass = {
    [dir .. '/pico-pass.html'] = 'pico',
    [dir .. '/nano-pass.html'] = 'nano',
    [dir .. '/nano-pass.css']  = 'nano',
}

local fail = {
    [dir .. '/pico-fail-elements.html']   = 'pico',
    [dir .. '/pico-fail-attributes.html'] = 'pico',
    [dir .. '/pico-fail-viewport.html']   = 'pico',
    [dir .. '/nano-fail-elements.html']   = 'nano',
    [dir .. '/nano-fail-attributes.html'] = 'nano',
    [dir .. '/nano-fail.css']             = 'nano',
}

local total = 0
local passed = 0

local function report(ok, label)
    total = total + 1
    if ok then passed = passed + 1 end
    io.write(string.format("  %s: %s\n", ok and 'PASS' or 'FAIL', label))
end

local function run_cmd(cmd)
    local p = io.popen(cmd .. "; echo \"___EXIT:$?___\"")
    if not p then return 1, "" end
    local out = p:read("*a")
    p:close()
    local exit_str = out:match("___EXIT:(%d+)___%s*$")
    local exit_code = tonumber(exit_str) or 0
    out = out:gsub("___EXIT:%d+___%s*$", "")
    return exit_code, out
end

local function check(profile, files)
    local args_str = ""
    for _, f in ipairs(files) do
        args_str = args_str .. " " .. string.format("%q", f)
    end
    return run_cmd(string.format("lua %s --profile=%s %s 2>&1", checker, profile, args_str))
end

io.write("Running WebVeld profile checker corpus\n")
io.write(string.rep("=", 45) .. "\n\n")

io.write("1. Positive fixtures (must conform to their profile):\n")
local sorted_pass = {}
for f in pairs(pass) do table.insert(sorted_pass, f) end
table.sort(sorted_pass)

for _, f in ipairs(sorted_pass) do
    local code, out = check(pass[f], {f})
    local ok = (code == 0 and out:match("conforms") ~= nil and not out:match("^drift:") and not out:match("\ndrift:"))
    report(ok, string.format("%s against webveld-%s", f, pass[f]))
end

io.write("\n2. Negative fixtures (must be rejected):\n")
local sorted_fail = {}
for f in pairs(fail) do table.insert(sorted_fail, f) end
table.sort(sorted_fail)

for _, f in ipairs(sorted_fail) do
    local code = check(fail[f], {f})
    report(code == 1, string.format("%s rejected by webveld-%s", f, fail[f]))
end

io.write("\n3. Upward validity:\n")
for _, f in ipairs(sorted_pass) do
    if not f:match("%.css$") then
        local code, out = run_cmd(string.format("lua %s %q 2>&1", validator, f))
        report(code == 0 and out:match("conforms") ~= nil, string.format("%s conforms to full WebVeld", f))
    end
end
for _, f in ipairs(sorted_pass) do
    if pass[f] == 'pico' then
        local code, out = check('nano', {f})
        report(code == 0 and out:match("conforms") ~= nil, string.format("%s conforms to webveld-nano", f))
    end
end

local spec_negative = {
    [dir .. '/nano-fail-attributes.html'] = 'uses the style attribute, which section 6.1 forbids outright',
}
io.write("\n4. Negative fixtures are profile-negative, not spec-negative:\n")
for _, f in ipairs(sorted_fail) do
    if f:match("%.html$") then
        local why = spec_negative[f]
        if why then
            io.write(string.format("  SKIP: %s -- %s\n", f, why))
        else
            local code, out = run_cmd(string.format("lua %s %q 2>&1", validator, f))
            report(code == 0 and out:match("conforms") ~= nil, string.format("%s conforms to full WebVeld", f))
        end
    end
end

io.write("\n" .. string.rep("=", 45) .. "\n")
io.write(string.format("%d of %d tests passed\n", passed, total))
os.exit(passed == total and 0 or 1)
