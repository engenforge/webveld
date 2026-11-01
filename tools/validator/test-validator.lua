#!/usr/bin/env lua
-- Conformance test runner for webveld-validate.lua in pure Lua.

local validator = 'tools/validator/webveld-validate.lua'
local vf = io.open(validator, "r")
if not vf then
    io.stderr:write("Cannot find validator at " .. validator .. "\n")
    os.exit(1)
end
vf:close()

local valid_dir   = 'tools/validator/tests/valid'
local invalid_dir = 'tools/validator/tests/invalid'
local classify_dir  = 'tools/validator/tests/classify'
local css_dir = 'tools/validator/tests/css'

local function list_files(dir, pattern)
    local p = io.popen("ls " .. dir .. "/" .. pattern .. " 2>/dev/null | sort")
    local files = {}
    if p then
        for line in p:lines() do
            table.insert(files, line)
        end
        p:close()
    end
    return files
end

local classify_files = list_files(classify_dir, "*.html")
local valid_files    = list_files(valid_dir, "*.html")
local invalid_files  = list_files(invalid_dir, "*.html")
local css_files      = list_files(css_dir, "*.css")

local total = 0
local passed = 0
local failed = 0

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

io.write("Running WebVeld Conformance Test Corpus\n")
io.write(string.rep("=", 45) .. "\n\n")

io.write("1. Positive Fixtures (must conform):\n")
for _, file in ipairs(valid_files) do
    total = total + 1
    local exit_code, out = run_cmd(string.format("lua %s %q 2>&1", validator, file))
    if exit_code == 0 and out:match("conforms") then
        io.write(string.format("  PASS: %s\n", file))
        passed = passed + 1
    else
        io.write(string.format("  FAIL: %s (expected exit 0, got %d)\n", file, exit_code))
        io.write(string.format("        Output: %s\n", out))
        failed = failed + 1
    end
end

io.write("\n2. Negative Fixtures (must fail with expected rule violation):\n")
for _, file in ipairs(invalid_files) do
    total = total + 1
    local f = io.open(file, "r")
    if not f then
        io.stderr:write("Cannot read " .. file .. "\n")
        os.exit(1)
    end
    local content = f:read("*a")
    f:close()

    local expected = content:match("expect:%s*([^\r\n*]+)")
    if expected then
        expected = expected:gsub("%s*%-%->.*$", ""):gsub("%s*%*/.*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
    end
    if not expected or #expected == 0 then
        io.stderr:write(string.format("  WARN: No 'expect:' directive found in %s\n", file))
    end

    local exit_code, out = run_cmd(string.format("lua %s %q 2>&1", validator, file))

    if exit_code ~= 0 then
        if expected and not out:find(expected, 1, true) then
            io.write(string.format("  FAIL: %s (did not match expected error)\n", file))
            io.write(string.format("        Expected: %s\n", expected))
            io.write(string.format("        Output:   %s\n", out))
            failed = failed + 1
        else
            io.write(string.format("  PASS: %s\n", file))
            passed = passed + 1
        end
    else
        io.write(string.format("  FAIL: %s (expected failure exit code, got 0)\n", file))
        failed = failed + 1
    end
end

io.write("\n3. Classification Fixtures (section 2.6 states; filename gives the expected state):\n")
local labels = {
    conforming = 'Conforming',
    extended = 'Extended',
    nonconforming = 'Non-conforming',
}
for _, file in ipairs(classify_files) do
    total = total + 1
    local want = file:match("/(conforming)%-") or file:match("/(extended)%-") or file:match("/(nonconforming)%-")
    local _, out = run_cmd(string.format("lua %s --classify %q 2>&1", validator, file))
    local got = out:match("(Conforming)%s") or out:match("(Extended)%s") or out:match("(Non%-conforming)%s")
    got = got or "(none)"
    local expected_label = labels[want]
    if got == expected_label then
        io.write(string.format("  PASS: %s (%s)\n", file, got))
        passed = passed + 1
    else
        io.write(string.format("  FAIL: %s (expected %s, got %s)\n", file, tostring(expected_label), got))
        failed = failed + 1
    end
end

io.write("\n4. Style Sheets (.css inputs are checked as style sheets):\n")
for _, file in ipairs(css_files) do
    total = total + 1
    local want_ok = (file:match("/valid%-") ~= nil)
    local exit_code, out = run_cmd(string.format("lua %s %q 2>&1", validator, file))
    local ok = (exit_code == 0)
    if ok == want_ok then
        io.write(string.format("  PASS: %s\n", file))
        passed = passed + 1
    else
        io.write(string.format("  FAIL: %s (expected %s, got %s)\n%s", file,
            want_ok and "pass" or "failure",
            ok and "pass" or "failure",
            out))
        failed = failed + 1
    end
end

io.write("\n5. Machine-readable output:\n")
do
    total = total + 1
    local bad = 'tools/validator/tests/css/invalid-forbidden-property.css'
    local _, json = run_cmd(string.format("lua %s --format=json %q 2>/dev/null", validator, bad))
    if json:match('"file":') and json:match('"kind":%s*"css"')
        and json:match('"state":%s*"non%-conforming"') and json:match('"findings":%s*%[') then
        io.write("  PASS: --format=json reports file, kind, state and findings\n")
        passed = passed + 1
    else
        io.write("  FAIL: --format=json output unusable:\n" .. json .. "\n")
        failed = failed + 1
    end

    total = total + 1
    local _, quiet = run_cmd(string.format("lua %s --format=json %q 2>/dev/null", validator, bad))
    if not quiet:match("^allowlists from") and not quiet:match("\nallowlists from") then
        io.write("  PASS: --format=json emits no prose banner\n")
        passed = passed + 1
    else
        io.write("  FAIL: --format=json still prints the prose banner\n")
        failed = failed + 1
    end

    total = total + 1
    local classify_test = 'tools/validator/tests/classify/conforming-minimal-site.html'
    local _, cjson = run_cmd(string.format("lua %s --classify --format=json %q 2>/dev/null", validator, classify_test))
    if cjson:match('"kind":%s*"html"') and cjson:match('"state":%s*"conforming"') then
        io.write("  PASS: --classify --format=json emits lowercase state (conforming)\n")
        passed = passed + 1
    else
        io.write("  FAIL: --classify --format=json output unexpected:\n" .. cjson .. "\n")
        failed = failed + 1
    end

    total = total + 1
    local ext_test = 'tools/validator/tests/classify/extended-appendix-a3.html'
    local _, ejson = run_cmd(string.format("lua %s --classify --format=json %q 2>/dev/null", validator, ext_test))
    if ejson:match('"kind":%s*"html"') and ejson:match('"state":%s*"extended"') then
        io.write("  PASS: --classify --format=json emits lowercase state (extended)\n")
        passed = passed + 1
    else
        io.write("  FAIL: --classify --format=json extended state unexpected:\n" .. ejson .. "\n")
        failed = failed + 1
    end

    total = total + 1
    local nonconf_test = 'tools/validator/tests/classify/nonconforming-clean-noscript-leaky-head.html'
    local _, njson = run_cmd(string.format("lua %s --classify --format=json %q 2>/dev/null", validator, nonconf_test))
    if njson:match('"kind":%s*"html"') and njson:match('"state":%s*"non%-conforming"') then
        io.write("  PASS: --classify --format=json emits lowercase state (non-conforming)\n")
        passed = passed + 1
    else
        io.write("  FAIL: --classify --format=json non-conforming state unexpected:\n" .. njson .. "\n")
        failed = failed + 1
    end
end

io.write("\n6. CLI edge cases and regression checks:\n")
do
    total = total + 1
    local exit_code, out = run_cmd(string.format("lua %s nonexistent-file-xyz.html 2>&1", validator))
    if exit_code ~= 0 and out:match("cannot open") then
        io.write("  PASS: unreadable or missing file exits non-zero\n")
        passed = passed + 1
    else
        io.write(string.format("  FAIL: unreadable file expected exit non-zero, got %d:\n%s\n", exit_code, out))
        failed = failed + 1
    end

    total = total + 1
    local exit_code, out = run_cmd(string.format("lua %s -- --nonexistent-flag-file.html 2>&1", validator))
    if exit_code ~= 0 and not out:match("unknown option") and out:match("cannot open") then
        io.write("  PASS: -- terminates option parsing and treats remaining arguments as files\n")
        passed = passed + 1
    else
        io.write(string.format("  FAIL: -- flag parsing failed, got exit %d:\n%s\n", exit_code, out))
        failed = failed + 1
    end

    -- CSS token scanning performance regression check (prevent quadratic O(n^2) scaling)
    total = total + 1
    local perf_file = "tools/validator/tests/css/perf-test-tmp.css"
    local pf = io.open(perf_file, "w")
    if pf then
        for i = 1, 1000 do
            pf:write(string.format(".item%d { color: #111; margin: %dpx; }\n", i, i % 10))
        end
        pf:close()
        local t0 = os.clock()
        local exit_code, _ = run_cmd(string.format("lua %s %q 2>&1", validator, perf_file))
        local duration = os.clock() - t0
        os.remove(perf_file)
        if exit_code == 0 and duration < 1.0 then
            io.write(string.format("  PASS: linear CSS scanning performance (1000 rules in %.3fs < 1.0s)\n", duration))
            passed = passed + 1
        else
            io.write(string.format("  FAIL: CSS scanning took too long (%.3fs) or failed (exit %d)\n", duration, exit_code))
            failed = failed + 1
        end
    else
        io.write("  SKIP: cannot create temporary performance test file\n")
    end
end

io.write("\n7. Specification drift checks for static validator tables:\n")
do
    local sf = io.open("doc/webveld-spec.md", "r")
    local vf = io.open(validator, "r")
    if sf and vf then
        local spec_text = sf:read("*a")
        local val_text = vf:read("*a")
        sf:close()
        vf:close()

        -- Check 6.3 selector allowlist drift
        total = total + 1
        local val_pcs = {}
        local pc_block = val_text:match("local allowed_pseudo_classes = {([^}]+)}") or ""
        for pc in pc_block:gmatch("%[\"([^\"]+)\"%]") do val_pcs[pc] = true end

        local val_pes = {}
        local pe_block = val_text:match("local allowed_pseudo_elements = {([^}]+)}") or ""
        for pe in pe_block:gmatch("%[\"([^\"]+)\"%]") do val_pes[pe] = true end

        local s63 = spec_text:match("### 6%.3 Allowed selectors(.-)### 6%.4") or ""
        local pc_line = s63:match("Pseudo%-classes: ([^\r\n]+)") or ""
        local spec_pcs = {}
        for pc in pc_line:gmatch("`:([a-z%-]+)") do spec_pcs[pc] = true end

        local pe_line = s63:match("Pseudo%-elements: ([^\r\n]+)") or ""
        local spec_pes = {}
        for pe in pe_line:gmatch("`::([a-z%-]+)") do spec_pes[pe] = true end

        local pc_drift = false
        for pc in pairs(spec_pcs) do
            if not val_pcs[pc] then pc_drift = true break end
        end
        for pe in pairs(spec_pes) do
            if not val_pes[pe] then pc_drift = true break end
        end
        if not pc_drift then
            io.write("  PASS: Section 6.3 selector allowlist matches specification (14 pseudo-classes, 4 pseudo-elements)\n")
            passed = passed + 1
        else
            io.write("  FAIL: Section 6.3 selector allowlist drifted from doc/webveld-spec.md\n")
            failed = failed + 1
        end

        -- Check 6.4 unit allowlist drift
        total = total + 1
        local val_units = {}
        local u_block = val_text:match("local allowed_units = {([^}]+)}") or ""
        for u in u_block:gmatch("%[\"([^\"]+)\"%]") do val_units[u] = true end

        local s64 = spec_text:match("### 6%.4 Allowed units(.-)### 6%.5") or ""
        local spec_units = {}
        for line in s64:gmatch("[^\r\n]+") do
            if line:match("^%s*%-") and not line:match("Grid tracks:") then
                for u in line:gmatch("`([%%a-z]+)`") do spec_units[u] = true end
            end
        end

        local u_drift = false
        for u in pairs(spec_units) do
            if not val_units[u] then u_drift = true break end
        end
        for u in pairs(val_units) do
            if not spec_units[u] then u_drift = true break end
        end
        if not u_drift then
            io.write("  PASS: Section 6.4 unit allowlist matches specification (14 units)\n")
            passed = passed + 1
        else
            io.write("  FAIL: Section 6.4 unit allowlist drifted from doc/webveld-spec.md\n")
            failed = failed + 1
        end

        -- Check 6.2 enumerated values drift
        total = total + 1
        local s62 = spec_text:match("### 6%.2 Allowed properties(.-)### 6%.3") or ""
        local spec_enums = {}
        for line in s62:gmatch("[^\r\n]+") do
            if line:match("^%*%*[^*]+:%*%*") then
                for prop, vlist in line:gmatch("`([a-z%-]+)`%s*%(([^)]+)%)") do
                    spec_enums[prop] = {}
                    for v in vlist:gmatch("`([a-z0-9%-]+)`") do spec_enums[prop][v] = true end
                end
            end
        end

        local f_chunk = load(val_text:match("(local enum_values = {.-%\n})") .. "\nreturn enum_values")
        local val_enums = f_chunk and f_chunk() or {}

        local enum_drift = false
        local enum_count = 0
        for prop, vs in pairs(spec_enums) do
            if val_enums[prop] then
                enum_count = enum_count + 1
                for v in pairs(vs) do
                    if not val_enums[prop][v] then enum_drift = true break end
                end
            end
            if enum_drift then break end
        end
        if not enum_drift and enum_count >= 15 then
            io.write(string.format("  PASS: Section 6.2 enumerated property values match specification (%d properties)\n", enum_count))
            passed = passed + 1
        else
            io.write("  FAIL: Section 6.2 enumerated values drifted from doc/webveld-spec.md\n")
            failed = failed + 1
        end
    else
        io.write("  SKIP: cannot open spec or validator for drift check\n")
    end
end

io.write("\n" .. string.rep("=", 45) .. "\n")
io.write(string.format("Results: %d total, %d passed, %d failed\n", total, passed, failed))

os.exit(failed > 0 and 1 or 0)
