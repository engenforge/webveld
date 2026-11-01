#!/usr/bin/env lua
-- Classifies float rules in crawled corpus in pure Lua.

local script_dir = "."
if arg and arg[0] then
    local dir = arg[0]:match("^(.*)/[^/]+$")
    if dir then script_dir = dir end
end

local function run_cmd(cmd)
    local p = io.popen(cmd)
    if not p then return "" end
    local out = p:read("*a")
    p:close()
    return out:gsub("%s+$", "")
end

local W = run_cmd(string.format("%q/snapshot.sh resolve 2>/dev/null", script_dir))
if not W or #W == 0 then
    io.stderr:write("no corpus available — run fetch.sh, or snapshot.sh list to see the cache\n")
    os.exit(1)
end

local ok_file = io.open(W .. "/out/ok.tsv", "r")
if not ok_file then
    io.stderr:write("no corpus available — run fetch.sh, or snapshot.sh list to see the cache\n")
    os.exit(1)
end

local FP = run_cmd(string.format("%q/snapshot.sh fingerprint 2>/dev/null", script_dir))
if not FP or #FP == 0 then FP = "unfingerprinted" end

io.stderr:write(string.format("corpus %s\nfingerprint %s\n\n", W, FP))

local function slurp(path)
    local f = io.open(path, "rb")
    if not f then return "" end
    local d = f:read("*a")
    f:close()
    return d or ""
end

local function has_any(str, keywords)
    for _, kw in ipairs(keywords) do
        if str:match(kw) then return true end
    end
    return false
end

local fig_kws = {"img", "figure", "photo", "avatar", "thumb", "logo", "icon", "pull%-?quote", "aside"}
local lay_kws = {"nav", "menu", "header", "footer", "sidebar", "col", "grid", "row", "left", "right", "wrap", "container", "main", "toc"}
local clr_kws = {"clear", "clearfix", "group"}

local kind = { figure = 0, layout = 0, clearfix = 0, other = 0 }
local sites = 0
local rules = 0

for line in ok_file:lines() do
    local clean_line = line:gsub("[\r\n]+$", "")
    local c, u, id = clean_line:match("([^\t]+)\t([^\t]+)\t([^\t]+)")
    if id then
        local css = slurp(W .. "/css/" .. id .. ".css")
        local hit = false

        for sel_raw, body in css:gmatch("([^{}]+){([^{}]+)}") do
            local body_l = body:lower()
            if body_l:match("float%s*:%s*left") or body_l:match("float%s*:%s*right") then
                local sel = sel_raw:lower():gsub("%s+", " ")
                sel = sel:gsub("^.*[};]", "")
                rules = rules + 1
                hit = true

                if has_any(sel, fig_kws) then
                    kind.figure = kind.figure + 1
                elseif has_any(sel, lay_kws) then
                    kind.layout = kind.layout + 1
                elseif has_any(sel, clr_kws) then
                    kind.clearfix = kind.clearfix + 1
                else
                    kind.other = kind.other + 1
                end
            end
        end

        if hit then sites = sites + 1 end
    end
end
ok_file:close()

io.write(string.format("sites with float rules: %d, float rules total: %d\n", sites, rules))
local sorted_kinds = {}
for k in pairs(kind) do table.insert(sorted_kinds, k) end
table.sort(sorted_kinds, function(a, b)
    if kind[a] ~= kind[b] then return kind[a] > kind[b] end
    return a < b
end)

for _, k in ipairs(sorted_kinds) do
    local pct = (rules > 0) and (100 * kind[k] / rules) or 0
    io.write(string.format("%-10s %4d (%2.0f%%)\n", k, kind[k], pct))
end
