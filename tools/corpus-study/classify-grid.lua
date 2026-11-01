#!/usr/bin/env lua
-- Assigns each grid-using site in the corpus to lowest bounded-subset tier in pure Lua.

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
    io.stderr:write(string.format("no corpus at %s/out/ok.tsv\n", W))
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

local function pct(x, t)
    if not t or t == 0 then return 0 end
    return 100 * (x or 0) / t
end

local function match_intrinsic(str)
    local s = " " .. str:lower() .. " "
    for _, kw in ipairs({"auto", "min%-content", "max%-content"}) do
        if s:match("[%s,%(%/]" .. kw .. "[%s,%)%/]") then return true end
    end
    return false
end

local tiers = {"T0", "T1", "T2", "T3", "out"}
local tier = { A = {}, B = {}, C = {}, ALL = {} }
local n = { A = 0, B = 0, C = 0, ALL = 0 }
local feat = { A = {}, B = {}, C = {}, ALL = {} }
local grid_sites = { A = 0, B = 0, C = 0, ALL = 0 }

for line in ok_file:lines() do
    local clean_line = line:gsub("[\r\n]+$", "")
    local cohort, url, id = clean_line:match("([^\t]+)\t([^\t]+)\t([^\t]+)")
    if id then
        local css = slurp(W .. "/css/" .. id .. ".css")
        n[cohort] = (n[cohort] or 0) + 1
        n.ALL = n.ALL + 1

        local css_l = css:lower()
        if css_l:match("display%s*:%s*grid") or css_l:match("display%s*:%s*inline%-grid") or css_l:match("grid%-template") then
            grid_sites[cohort] = (grid_sites[cohort] or 0) + 1
            grid_sites.ALL = grid_sites.ALL + 1

            local track_list = {}
            for tr in css_l:gmatch("grid%-template[%-a-z]*%s*:([^;{}]*)") do
                table.insert(track_list, tr)
            end
            local tracks = table.concat(track_list, ";")

            local f = {}
            f.areas = (css_l:match("grid%-template%-areas%s*:") ~= nil)
            f.subgrid = (tracks:match("%f[%a]subgrid%f[%A]") ~= nil)
            f.implicit = (css_l:match("grid%-auto%-rows%s*:") ~= nil) or (css_l:match("grid%-auto%-columns%s*:") ~= nil)
            f.dense = (css_l:match("grid%-auto%-flow%s*:[^;{}]*%f[%a]dense%f[%A]") ~= nil)
                   or (css_l:match("grid%-auto%-flow%s*:[^;{}]*%f[%a]column%f[%A]") ~= nil)
            f.fitcontent = (tracks:match("%f[%a]fit%-content%s*%(") ~= nil)
            f.autorepeat = (tracks:match("%f[%a]repeat%s*%(%s*auto%-fill%f[%A]") ~= nil)
                        or (tracks:match("%f[%a]repeat%s*%(%s*auto%-fit%f[%A]") ~= nil)
            f.minmax = (tracks:match("%f[%a]minmax%s*%(") ~= nil)
            f.intrinsic = match_intrinsic(tracks)
            f.placement = (css_l:match("grid%-column%s*:") ~= nil)
                       or (css_l:match("grid%-column%-start%s*:") ~= nil)
                       or (css_l:match("grid%-column%-end%s*:") ~= nil)
                       or (css_l:match("grid%-row%s*:") ~= nil)
                       or (css_l:match("grid%-row%-start%s*:") ~= nil)
                       or (css_l:match("grid%-row%-end%s*:") ~= nil)
                       or (css_l:match("grid%-area%s*:") ~= nil)
                       or (css_l:match("grid%-area%-start%s*:") ~= nil)
                       or (css_l:match("grid%-area%-end%s*:") ~= nil)
            f.autoplaced = not f.placement

            local t
            if f.areas or f.subgrid or f.implicit or f.dense or f.fitcontent then
                t = 'out'
            elseif f.autorepeat then
                t = 'T3'
            elseif f.minmax or f.intrinsic then
                t = 'T2'
            elseif f.autoplaced then
                t = 'T1'
            else
                t = 'T0'
            end

            tier[cohort][t] = (tier[cohort][t] or 0) + 1
            tier.ALL[t] = (tier.ALL[t] or 0) + 1

            for k, val in pairs(f) do
                feat[cohort][k] = (feat[cohort][k] or 0) + (val and 1 or 0)
                feat.ALL[k]     = (feat.ALL[k] or 0)     + (val and 1 or 0)
            end
        end
    end
end
ok_file:close()

local cohorts = {}
for _, c in ipairs({'A', 'B', 'C', 'ALL'}) do
    if (grid_sites[c] or 0) > 0 then
        table.insert(cohorts, c)
    end
end

io.write("GRID USERS PER COHORT\n")
for _, c in ipairs(cohorts) do
    io.write(string.format("  %-4s %3d of %3d sites (%.0f%%)\n", c, grid_sites[c], n[c], pct(grid_sites[c], n[c])))
end

io.write("\nLOWEST TIER COVERING EACH SITE'S USAGE (% of that cohort's grid users)\n")
local header_tiers = {}
for _, t in ipairs(tiers) do table.insert(header_tiers, string.format(" %6s", t)) end
io.write(string.format("  %-4s%s\n", "", table.concat(header_tiers, "")))

for _, c in ipairs(cohorts) do
    local row = {}
    for _, t in ipairs(tiers) do
        table.insert(row, string.format(" %5.0f%%", pct(tier[c][t], grid_sites[c])))
    end
    io.write(string.format("  %-4s%s\n", c, table.concat(row, "")))
end

io.write("\nCUMULATIVE COVERAGE — a subset drawn at this tier serves this share of grid users\n")
for _, c in ipairs(cohorts) do
    local run = 0
    local cum = {}
    for _, t in ipairs({'T0', 'T1', 'T2', 'T3'}) do
        run = run + (tier[c][t] or 0)
        table.insert(cum, pct(run, grid_sites[c]))
    end
    io.write(string.format("  %-4s T0 %3.0f%%   T0-T1 %3.0f%%   T0-T2 %3.0f%%   T0-T3 %3.0f%%\n",
        c, cum[1], cum[2], cum[3], cum[4]))
end

io.write("\nFEATURE USE AMONG GRID USERS (% of that cohort's grid users)\n")
local order = {'autoplaced', 'placement', 'intrinsic', 'minmax', 'autorepeat', 'areas', 'implicit', 'dense', 'fitcontent', 'subgrid'}
local f_header = {}
for _, c in ipairs(cohorts) do table.insert(f_header, string.format(" %7s", c .. ' n=' .. (grid_sites[c] or 0))) end
io.write(string.format("  %-11s%s\n", 'FEATURE', table.concat(f_header, "")))

for _, k in ipairs(order) do
    local row = {}
    for _, c in ipairs(cohorts) do
        table.insert(row, string.format(" %6.0f%%", pct(feat[c][k], grid_sites[c])))
    end
    io.write(string.format("  %-11s%s\n", k, table.concat(row, "")))
end

io.write("\nRead `autoplaced` as: declares a track list and no explicit placement anywhere,\n")
io.write("so its items must be flowed by the auto-placement algorithm. That is the T0/T1 line.\n")
