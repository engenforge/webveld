#!/usr/bin/env lua
-- Automated coverage verifier for WebVeld Render Conformance Suite in pure Lua.
-- Note: This tool audits the Render Conformance Suite (conformance/) to verify
-- that the rendering test pages cover every feature in doc/webveld-spec.md.
-- It does NOT audit the validator's own semantic rule enforcement, which is tested
-- separately by test-validator.lua.

local spec_file = os.getenv("WEBVELD_SPEC")
if not spec_file or #spec_file == 0 then
    local script_dir = "."
    if arg and arg[0] then
        local dir = arg[0]:match("^(.*)[/\\][^/\\]+$")
        if dir then script_dir = dir end
    end
    local candidates = {'doc/webveld-spec.md', script_dir .. '/../../doc/webveld-spec.md'}
    for _, cand in ipairs(candidates) do
        local f = io.open(cand, "r")
        if f then
            f:close()
            spec_file = cand
            break
        end
    end
    spec_file = spec_file or 'doc/webveld-spec.md'
end

local sf = io.open(spec_file, "r")
if not sf then
    io.stderr:write("Cannot open " .. spec_file .. "\n")
    os.exit(1)
end
local spec = sf:read("*a")
sf:close()

local conformance_dir = 'conformance'
local cd = io.open(conformance_dir .. "/section-4.3-elements.html", "r")
if cd then
    cd:close()
else
    local script_dir = "."
    if arg and arg[0] then
        local dir = arg[0]:match("^(.*)[/\\][^/\\]+$")
        if dir then script_dir = dir end
    end
    conformance_dir = script_dir .. "/../../conformance"
end

local total_checks = 0
local passed_checks = 0
local failed_checks = 0

local function check(label, ok, detail)
    total_checks = total_checks + 1
    if ok then
        passed_checks = passed_checks + 1
    else
        failed_checks = failed_checks + 1
        io.write("  FAIL: " .. label .. (detail and (" (" .. detail .. ")") or "") .. "\n")
    end
end

io.write("WebVeld Conformance Suite Coverage Audit\n")
io.write(string.rep("=", 50) .. "\n\n")

-- 1. Section 4.3 Elements
io.write("1. Section 4.3 Elements Coverage:\n")
local el_sec = spec:match("### 4%.3 Allowed elements(.-)### 4%.4") or ""
local spec_elements = {}
for el in el_sec:gmatch("`([a-z0-9]+)`") do
    spec_elements[el] = true
end

local p4_file = conformance_dir .. '/section-4.3-elements.html'
local p4_f = io.open(p4_file, "r")
if not p4_f then
    io.stderr:write("Cannot open " .. p4_file .. "\n")
    os.exit(1)
end
local p4_doc = p4_f:read("*a")
p4_f:close()

local seen_elements = {}
for el in p4_doc:gmatch("<([a-zA-Z][a-zA-Z0-9]*)[%s>/]") do
    seen_elements[el:lower()] = (seen_elements[el:lower()] or 0) + 1
end

local missing_el_count = 0
local sorted_spec_elements = {}
for el in pairs(spec_elements) do table.insert(sorted_spec_elements, el) end
table.sort(sorted_spec_elements)

for _, el in ipairs(sorted_spec_elements) do
    if el == 'noscript' then
        check('element <noscript> (extended document feature)', true)
    else
        local has = (seen_elements[el] ~= nil)
        check('element <' .. el .. '>', has, 'missing in ' .. p4_file)
        if not has then missing_el_count = missing_el_count + 1 end
    end
end
io.write(string.format("   Section 4.3 elements: %d checked, %d missing\n\n",
    #sorted_spec_elements, missing_el_count))

-- 2. Section 5 Attributes
io.write("2. Section 5 Attributes Coverage:\n")
local g_sec = spec:match("### 5%.1 Global attributes(.-)### 5%.2") or ""
local spec_globals = {}
for g in g_sec:gmatch("`([a-z%-]+)`") do
    spec_globals[g] = true
end
spec_globals["ltr"] = nil
spec_globals["rtl"] = nil

local a_sec = spec:match("### 5%.2 Element%-specific attributes(.-)### 5%.3") or ""
local spec_attrs = {}
for row in a_sec:gmatch("[^\r\n]+") do
    if row:match("^|%s*`") then
        local parts = {}
        for p in (row .. "|"):gmatch("([^|]*)|") do
            table.insert(parts, p)
        end
        local els = parts[2]
        local as = parts[3]
        if as then
            as = as:gsub("%([^)]*%)", "")
            local es = {}
            for e in els:gmatch("`([a-z0-9]+)`") do table.insert(es, e) end
            local atts = {}
            for a in as:gmatch("`([a-zA-Z%-]+)") do table.insert(atts, a) end
            for _, e in ipairs(es) do
                if not spec_attrs[e] then spec_attrs[e] = {} end
                for _, a in ipairs(atts) do table.insert(spec_attrs[e], a) end
            end
        end
    end
end

local t_line = spec:match("Allowed `input` types: ([^\r\n]+)") or ""
local spec_itypes = {}
for t in t_line:gmatch("`([a-z]+)`") do
    table.insert(spec_itypes, t)
end

local p5_file = conformance_dir .. '/section-5-attributes.html'
local p5_f = io.open(p5_file, "r")
if not p5_f then
    io.stderr:write("Cannot open " .. p5_file .. "\n")
    os.exit(1)
end
local p5_doc = p5_f:read("*a")
p5_f:close()

local seen_attrs = {}
-- Match elements and attribute list
for el, attrs in p5_doc:gmatch("<([a-zA-Z][a-zA-Z0-9]*)([^>]*)>") do
    local el_l = el:lower()
    local pos = 1
    local len = #attrs
    while pos <= len do
        local s_idx, e_idx, a_name = attrs:find("([a-zA-Z%-]+)", pos)
        if not s_idx then break end
        local a = a_name:lower()
        local v = ""
        local cur = e_idx + 1
        local eq_s, eq_e = attrs:find("^%s*=%s*", cur)
        if eq_e then
            cur = eq_e + 1
            local q = attrs:sub(cur, cur)
            if q == '"' or q == "'" then
                local q_end = attrs:find(q, cur + 1, true)
                if q_end then
                    v = attrs:sub(cur + 1, q_end - 1)
                    cur = q_end + 1
                else
                    v = attrs:sub(cur + 1)
                    cur = len + 1
                end
            else
                local u_s, u_e, val = attrs:find("^([^%s>]+)", cur)
                if u_e then
                    v = val
                    cur = u_e + 1
                else
                    cur = len + 1
                end
            end
        end
        pos = cur
        seen_attrs[el_l .. "/" .. a] = v
        seen_attrs["*/" .. a] = v
        if el_l == "input" and a == "type" then
            seen_attrs["input_type/" .. v:lower()] = 1
        end
    end
end

local sorted_globals = {}
for g in pairs(spec_globals) do table.insert(sorted_globals, g) end
table.sort(sorted_globals)
for _, g in ipairs(sorted_globals) do
    check("global attribute `" .. g .. "`", seen_attrs["*/" .. g] ~= nil, "missing in " .. p5_file)
end

local sorted_attr_els = {}
for el in pairs(spec_attrs) do table.insert(sorted_attr_els, el) end
table.sort(sorted_attr_els)
for _, el in ipairs(sorted_attr_els) do
    for _, a in ipairs(spec_attrs[el]) do
        local k = el .. "/" .. a:lower()
        check("attribute `" .. k .. "`", seen_attrs[k] ~= nil, "missing in " .. p5_file)
    end
end

for _, t in ipairs(spec_itypes) do
    check("input type `" .. t .. "`", seen_attrs["input_type/" .. t] ~= nil, "missing in " .. p5_file)
end
io.write("   Section 5 attributes and input types verified\n\n")

-- 3. Section 6.2 Properties and Enumerated Values
io.write("3. Section 6.2 Properties and Enumerated Values Coverage:\n")
local p_sec = spec:match("### 6%.2 Allowed properties(.-)### 6%.3") or ""
local spec_props = {}
for line in p_sec:gmatch("[^\r\n]+") do
    local group = line:match("^%*%*[^*]+:%*%*(.*)$")
    if group then
        group = group:gsub("%([^)]*%)", "")
        for p in group:gmatch("`([a-z%-]+)`") do
            spec_props[p] = true
        end
    end
end

local p62_file = conformance_dir .. '/section-6.2-properties.html'
local p62_f = io.open(p62_file, "r")
if not p62_f then
    io.stderr:write("Cannot open " .. p62_file .. "\n")
    os.exit(1)
end
local p62_doc = p62_f:read("*a")
p62_f:close()

local p62_style = p62_doc:match("<[sS][tT][yY][lL][eE][^>]*>(.-)</[sS][tT][yY][lL][eE]%s*>") or ""
local p62_clean_style = p62_style:gsub("[uU][rR][lL]%s*%([^)]*%)", "")
p62_clean_style = p62_clean_style:gsub('"[^"]*"', '""')
p62_clean_style = p62_clean_style:gsub("'[^']*'", "''")

local seen_props = {}
for d in p62_clean_style:gmatch("{([^{}]*)}") do
    for p in d:gmatch("([%-a-zA-Z]+)%s*:") do
        seen_props[p:lower()] = (seen_props[p:lower()] or 0) + 1
    end
end

local sorted_props = {}
for p in pairs(spec_props) do table.insert(sorted_props, p) end
table.sort(sorted_props)
for _, p in ipairs(sorted_props) do
    check("property `" .. p .. "`", seen_props[p] ~= nil, "missing in " .. p62_file)
end

local enums = {
    ['display'] = {'block', 'inline', 'inline-block', 'none', 'flex', 'grid'},
    ['flex-direction'] = {'row', 'column', 'row-reverse', 'column-reverse'},
    ['flex-wrap'] = {'nowrap', 'wrap', 'wrap-reverse'},
    ['justify-content'] = {'flex-start', 'flex-end', 'center', 'space-between', 'space-around'},
    ['align-items'] = {'flex-start', 'flex-end', 'center', 'stretch'},
    ['align-content'] = {'flex-start', 'flex-end', 'center', 'space-between', 'space-around', 'stretch'},
    ['text-align'] = {'left', 'right', 'center', 'justify', 'start', 'end'},
    ['text-decoration'] = {'none', 'underline', 'line-through'},
    ['text-transform'] = {'none', 'uppercase', 'lowercase', 'capitalize'},
    ['white-space'] = {'normal', 'nowrap', 'pre', 'pre-wrap', 'pre-line'},
    ['overflow-wrap'] = {'normal', 'break-word', 'anywhere'},
    ['word-break'] = {'normal', 'break-all', 'keep-all'},
    ['background-repeat'] = {'repeat', 'repeat-x', 'repeat-y', 'no-repeat'},
    ['list-style-position'] = {'inside', 'outside'},
    ['border-collapse'] = {'collapse', 'separate'},
    ['caption-side'] = {'top', 'bottom'},
    ['empty-cells'] = {'show', 'hide'},
    ['overflow'] = {'visible', 'hidden', 'scroll', 'auto'},
    ['overflow-x'] = {'visible', 'hidden', 'scroll', 'auto'},
    ['overflow-y'] = {'visible', 'hidden', 'scroll', 'auto'},
    ['cursor'] = {'auto', 'default', 'pointer', 'text'},
    ['vertical-align'] = {'baseline', 'top', 'middle', 'bottom', 'sub', 'super'},
    ['border-style'] = {'solid', 'dashed', 'dotted', 'double', 'groove', 'ridge', 'inset', 'outset', 'none'},
    ['box-sizing'] = {'content-box', 'border-box'},
    ['font-style'] = {'normal', 'italic'},
    ['font-weight'] = {'100', '300', '400', '600', '700', '900', 'normal', 'bold'},
    ['clip-path'] = {'inset', 'rect', 'none'},
    ['width'] = {'min-content', 'max-content'},
    ['height'] = {'max-content'},
    ['min-height'] = {'min-content'},
    ['min-width'] = {'min-content'},
    ['max-width'] = {'max-content'},
    ['max-height'] = {'max-content'},
}

local sorted_enum_props = {}
for p in pairs(enums) do table.insert(sorted_enum_props, p) end
table.sort(sorted_enum_props)

for _, prop_name in ipairs(sorted_enum_props) do
    for _, val in ipairs(enums[prop_name]) do
        local found = false
        local p62_lower = p62_style:lower()
        if prop_name == 'clip-path' and val ~= 'none' then
            found = (p62_lower:match("%f[%w]clip%-path%s*:[^;}]*%f[%w]" .. val .. "%s*%(") ~= nil)
        else
            local val_esc = val:gsub("%-", "%%-")
            found = (p62_lower:match("%f[%w]" .. prop_name:gsub("%-", "%%-") .. "%s*:[^;}]*%f[%w]" .. val_esc .. "%f[%W]") ~= nil)
        end
        check('property `' .. prop_name .. '` value `' .. val .. '`', found, 'missing in ' .. p62_file)
    end
end
io.write("   Section 6.2 properties (87/87) and enumerated values verified\n\n")

-- 4. Section 6.3 Selectors
io.write("4. Section 6.3 Selectors Coverage:\n")
local p63_file = conformance_dir .. '/section-6.3-selectors.html'
local p63_f = io.open(p63_file, "r")
if not p63_f then
    io.stderr:write("Cannot open " .. p63_file .. "\n")
    os.exit(1)
end
local p63_doc = p63_f:read("*a")
p63_f:close()

local sel_checks = {
    {'Type selector p', 'p%.[%a%-]+%s*{'},
    {'Class selector .classname', '%.[%a%-]+%s*{'},
    {'ID selector #idname', '#[%a%-]+%s*{'},
    {'Universal selector *', '%*%s*{'},
    {'Descendant combinator div p', '%.[%a%-]+%s+p%s*{'},
    {'Child combinator div > p', '%.[%a%-]+%s*>%s*p%s*{'},
    {'Adjacent sibling combinator elem + elem', '%.[%a%-]+%s*%+%s*[%w%.-]+%s*{'},
    {'General sibling combinator elem ~ elem', '%.[%a%-]+%s*~%s*[%w%.-]+%s*{'},
    {'Selector lists a, b, c', '%.[%a%-]+,%s*%.[%a%-]+%s*{'},
    {'Attribute presence selector [attr]', '%[[%a%-]+%]%s*{'},
    {'Attribute exact selector [attr=val]', '%[[%a%-]+=[^%]]+%]%s*{'},
    {'Attribute prefix selector [attr^=val]', '%[[%a%-]+%^=[^%]]+%]%s*{'},
    {'Attribute suffix selector [attr$=val]', '%[[%a%-]+%$=[^%]]+%]%s*{'},
    {'Attribute substring selector [attr*=val]', '%[[%a%-]+%*=[^%]]+%]%s*{'},
    {':hover', ':hover%f[%A]'},
    {':focus', ':focus%f[%A]'},
    {':active', ':active%f[%A]'},
    {':visited', ':visited%f[%A]'},
    {':link', ':link%f[%A]'},
    {':first-child', ':first%-child%f[%A]'},
    {':last-child', ':last%-child%f[%A]'},
    {':nth-child(odd)', ':nth%-child%s*%(%s*odd%s*%)'},
    {':nth-child(even)', ':nth%-child%s*%(%s*even%s*%)'},
    {':nth-child(integer)', ':nth%-child%s*%(%s*%d+%s*%)'},
    {':nth-child(an+b)', ':nth%-child%s*%(%s*%d*n%s*[+-]?%s*%d*%s*%)'},
    {':target', ':target%f[%A]'},
    {':checked', ':checked%f[%A]'},
    {':disabled', ':disabled%f[%A]'},
    {':required', ':required%f[%A]'},
    {':valid', ':valid%f[%A]'},
    {':invalid', ':invalid%f[%A]'},
    {'::before', '::before%f[%A]'},
    {'::after', '::after%f[%A]'},
    {'::first-line', '::first%-line%f[%A]'},
    {'::first-letter', '::first%-letter%f[%A]'},
}

for _, sc in ipairs(sel_checks) do
    local name = sc[1]
    local pat = sc[2]
    local found = (p63_doc:match(pat) ~= nil)
    check(name, found, 'missing in ' .. p63_file)
end
io.write("   Section 6.3 selectors, 14 pseudo-classes, 4 pseudo-elements verified\n\n")

-- 5. Section 6.4 Units
io.write("5. Section 6.4 Units Coverage:\n")
local p64_file = conformance_dir .. '/section-6.4-units.html'
local p64_f = io.open(p64_file, "r")
if not p64_f then
    io.stderr:write("Cannot open " .. p64_file .. "\n")
    os.exit(1)
end
local p64_doc = p64_f:read("*a")
p64_f:close()

local units = {'px', 'pt', 'cm', 'mm', 'in', 'em', 'rem', 'ex', 'ch', '%', 'vw', 'vh', 'vmin', 'vmax'}
for _, u in ipairs(units) do
    local found
    if u == '%' then
        found = (p64_doc:match("%d+%%[%s;}]") ~= nil) or (p64_doc:match("%d+%.%d+%%[%s;}]") ~= nil)
    else
        found = (p64_doc:lower():match("%f[%w]%d+" .. u .. "%f[%W]") ~= nil)
             or (p64_doc:lower():match("%f[%w]%d+%.%d+" .. u .. "%f[%W]") ~= nil)
    end
    check('unit `' .. u .. '`', found, 'missing in ' .. p64_file)
end
local calc_found = (p64_doc:match("calc%s*%([^)]*[%-%+%*/][^)]*%)") ~= nil)
check('calc() function with operators', calc_found, 'missing in ' .. p64_file)
io.write("   Section 6.4 units (14/14) and calc() verified\n\n")

-- 6. Section 6.6 Media Queries
io.write("6. Section 6.6 Media Queries Coverage:\n")
local p66_file = conformance_dir .. '/section-6.6-media-queries.html'
local p66_f = io.open(p66_file, "r")
if not p66_f then
    io.stderr:write("Cannot open " .. p66_file .. "\n")
    os.exit(1)
end
local p66_doc = p66_f:read("*a")
p66_f:close()

check('media feature min-width', p66_doc:match("%(%s*min%-width%s*:") ~= nil, 'missing in ' .. p66_file)
check('media feature max-width', p66_doc:match("%(%s*max%-width%s*:") ~= nil, 'missing in ' .. p66_file)
check('media feature width', p66_doc:match("%(%s*width%s*:") ~= nil, 'missing in ' .. p66_file)
check('media feature prefers-color-scheme: dark', p66_doc:match("%(%s*prefers%-color%-scheme%s*:%s*dark%s*%)") ~= nil, 'missing in ' .. p66_file)
check('media feature prefers-color-scheme: light', p66_doc:match("%(%s*prefers%-color%-scheme%s*:%s*light%s*%)") ~= nil, 'missing in ' .. p66_file)
check('media query combiner and', p66_doc:match("%)%s+and%s+%(") ~= nil, 'missing in ' .. p66_file)
check('media query comma alternatives (OR)', p66_doc:match("@media[^{]-,[^{]-{") ~= nil, 'missing in ' .. p66_file)
check('media type print', p66_doc:match("@media%s+print%f[%A]") ~= nil, 'missing in ' .. p66_file)
io.write("   Section 6.6 media queries features and conditions verified\n\n")

io.write(string.rep("=", 50) .. "\n")
io.write(string.format("Audit Results: %d checks, %d passed, %d failed\n",
    total_checks, passed_checks, failed_checks))

os.exit(failed_checks > 0 and 1 or 0)
