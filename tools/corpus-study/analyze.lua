#!/usr/bin/env lua
-- Feature frequency and primary layout-model analysis in pure Lua.

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

local feat = {
    "flex", "grid", "float", "pos_abs", "gap", "custom_props", "media",
    "dark", "anim", "radius", "box_sizing", "font_face", "gfonts",
    "viewport", "details", "script", "svg", "srcset", "lazy",
    "table", "aria", "checked", "checkbox_hack"
}

local function slurp(path)
    local f = io.open(path, "rb")
    if not f then return "" end
    local d = f:read("*a")
    f:close()
    return d or ""
end

local function pct(a, b)
    if not b or b == 0 then return 0 end
    return 100 * (a or 0) / b
end

local function has_pattern(str, ...)
    local s = str:lower()
    for i = 1, select("#", ...) do
        local pat = select(i, ...)
        if s:match(pat) then return 1 end
    end
    return 0
end

local agg = { A = {}, B = {}, C = {}, ALL = {} }
local n = { A = 0, B = 0, C = 0, ALL = 0 }
local rows = {}

for line in ok_file:lines() do
    local clean_line = line:gsub("[\r\n]+$", "")
    local cohort, url, id = clean_line:match("([^\t]+)\t([^\t]+)\t([^\t]+)")
    if cohort and id then
        local html = slurp(W .. "/pages/" .. id .. ".html")
        local css  = slurp(W .. "/css/" .. id .. ".css")
        if #html > 0 then
            local f = {}
            f.flex          = has_pattern(css, "display%s*:%s*flex", "display%s*:%s*inline%-flex", "flex%-direction", "justify%-content", "align%-items")
            f.grid          = has_pattern(css, "display%s*:%s*grid", "display%s*:%s*inline%-grid", "grid%-template")
            f.float         = has_pattern(css, "float%s*:%s*left", "float%s*:%s*right")
            f.pos_abs       = has_pattern(css, "position%s*:%s*absolute", "position%s*:%s*fixed", "position%s*:%s*sticky")
            f.gap           = has_pattern(css, "[^%-a-z]gap%s*:")
            f.custom_props  = has_pattern(css, "var%s*%(%s*%-%-", "%-%-[a-z][%w%-]*%s*:")
            f.media         = has_pattern(css, "@media")
            f.dark          = has_pattern(css, "prefers%-color%-scheme")
            f.anim          = has_pattern(css, "transition%s*:", "animation%s*:", "transform%s*:")
            f.radius        = has_pattern(css, "border%-radius")
            f.box_sizing    = has_pattern(css, "box%-sizing")
            f.font_face     = has_pattern(css, "@font%-face")
            f.gfonts        = has_pattern(css .. html, "fonts%.googleapis%.com", "fonts%.gstatic%.com")
            f.viewport      = has_pattern(html, "name%s*=%s*[\"']?viewport")
            f.details       = has_pattern(html, "<details[%s>]")
            f.script        = has_pattern(html, "<script[%s>]")
            f.svg           = has_pattern(html, "<svg[%s>]")
            f.srcset        = has_pattern(html, "srcset%s*=")
            f.lazy          = has_pattern(html, "loading%s*=%s*[\"']?lazy")
            f.table         = has_pattern(html, "<table[%s>]")
            f.aria          = has_pattern(html, "%saria%-[a-z]+%s*=", "%srole%s*=")
            f.checked       = has_pattern(css, ":checked")
            f.checkbox_hack = has_pattern(css, ":checked%s*[~%+]")

            n[cohort] = (n[cohort] or 0) + 1
            n.ALL = n.ALL + 1

            for _, k in ipairs(feat) do
                agg[cohort][k] = (agg[cohort][k] or 0) + f[k]
                agg.ALL[k] = (agg.ALL[k] or 0) + f[k]
            end

            local model = (f.grid == 1) and "grid" or (f.flex == 1) and "flex" or (f.float == 1) and "float" or "flow"
            agg[cohort]["m_" .. model] = (agg[cohort]["m_" .. model] or 0) + 1
            agg.ALL["m_" .. model] = (agg.ALL["m_" .. model] or 0) + 1

            local both_ff = (f.flex == 1 and f.float == 1) and 1 or 0
            agg[cohort].both_ff = (agg[cohort].both_ff or 0) + both_ff
            agg.ALL.both_ff = (agg.ALL.both_ff or 0) + both_ff

            local feat_digits = {}
            for _, k in ipairs(feat) do table.insert(feat_digits, tostring(f[k])) end
            table.insert(rows, {cohort, url, tostring(#html), tostring(#css), table.concat(feat_digits, "")})
        end
    end
end
ok_file:close()

io.write(string.format("%-28s %6s %6s %6s %6s\n", 'FEATURE (% of sites)',
    'A n=' .. (n.A or 0), 'B n=' .. (n.B or 0), 'C n=' .. (n.C or 0), 'ALL'))

for _, k in ipairs(feat) do
    io.write(string.format("%-28s %5.0f%% %5.0f%% %5.0f%% %5.0f%%\n", k,
        pct(agg.A[k], n.A), pct(agg.B[k], n.B), pct(agg.C[k], n.C), pct(agg.ALL[k], n.ALL)))
end

io.write("\nPRIMARY LAYOUT MODEL (% of sites)\n")
for _, m in ipairs({'m_grid', 'm_flex', 'm_float', 'm_flow'}) do
    io.write(string.format("%-28s %5.0f%% %5.0f%% %5.0f%% %5.0f%%\n", m,
        pct(agg.A[m], n.A), pct(agg.B[m], n.B), pct(agg.C[m], n.C), pct(agg.ALL[m], n.ALL)))
end

io.write(string.format("%-28s %5.0f%% %5.0f%% %5.0f%% %5.0f%%\n", 'flex AND float both used',
    pct(agg.A.both_ff, n.A), pct(agg.B.both_ff, n.B), pct(agg.C.both_ff, n.C), pct(agg.ALL.both_ff, n.ALL)))

local out_f = io.open(W .. "/out/rows.tsv", "w")
if out_f then
    for _, r in ipairs(rows) do
        out_f:write(table.concat(r, "\t") .. "\n")
    end
    out_f:close()
end
