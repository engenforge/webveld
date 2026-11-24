#!/usr/bin/env lua
-- WebVeld conformance checker in pure Lua.
-- Element, attribute, CSS property name, and input type allowlists are
-- parsed from doc/webveld-spec.md at run time. Section 6.2 enumerated values,
-- Section 6.3 selectors, and Section 6.4 units are defined in static tables
-- verified against specification text by automated drift checks in the test suite.
-- See README.md for what this does not check.

local function resolve_spec_path()
    local env_spec = os.getenv("WEBVELD_SPEC")
    if env_spec and #env_spec > 0 then
        return env_spec
    end

    local pkgdatadir = '@@PKGDATADIR@@'
    local script_dir = "."
    if arg and arg[0] then
        local dir = arg[0]:match("^(.*)[/\\][^/\\]+$")
        if dir then script_dir = dir end
    end

    local candidates = {
        'doc/webveld-spec.md',
        script_dir .. '/../share/webveld/doc/webveld-spec.md',
        script_dir .. '/../share/webveld/webveld-spec.md',
        script_dir .. '/../../doc/webveld-spec.md',
        pkgdatadir .. '/doc/webveld-spec.md',
        pkgdatadir .. '/webveld-spec.md',
        '/usr/local/share/webveld/doc/webveld-spec.md',
        '/usr/local/share/webveld/webveld-spec.md',
        '/usr/share/webveld/doc/webveld-spec.md',
        '/usr/share/webveld/webveld-spec.md',
    }

    for _, cand in ipairs(candidates) do
        local f = io.open(cand, "r")
        if f then
            f:close()
            return cand
        end
    end
    return 'doc/webveld-spec.md'
end

local spec_path = resolve_spec_path()
local spec_file = io.open(spec_path, "r")
if not spec_file then
    io.stderr:write("cannot read " .. spec_path .. " (set WEBVELD_SPEC)\n")
    os.exit(1)
end
local spec = spec_file:read("*a")
spec_file:close()

-- --- 4.3 allowed elements ---
local el_sec = spec:match("### 4%.3 Allowed elements(.-)### 4%.4") or ""
local element = {}
local element_count = 0
for code in el_sec:gmatch("`([a-z0-9]+)`") do
    if not element[code] then element_count = element_count + 1 end
    element[code] = true
end

-- --- 5.1 global attributes ---
local g_sec = spec:match("### 5%.1 Global attributes(.-)### 5%.2") or ""
local global = {}
for code in g_sec:gmatch("`([a-z%-]+)`") do
    global[code] = true
end
global["ltr"] = nil
global["rtl"] = nil

-- --- 5.2 element-specific attributes and input types ---
local a_sec = spec:match("### 5%.2 Element%-specific attributes(.-)### 5%.3") or ""
local attr = {}
for row in a_sec:gmatch("[^\r\n]+") do
    if row:match("^|%s*`") then
        local parts = {}
        for p in (row .. "|"):gmatch("([^|]*)|") do
            table.insert(parts, p)
        end
        local els = parts[2]
        local as = parts[3]
        if as then
            as = as:gsub("%([^)]*%)", "") -- drop parenthetical value lists
            local es = {}
            for e in els:gmatch("`([a-z0-9]+)`") do
                table.insert(es, e)
            end
            local atts = {}
            for a in as:gmatch("`([a-zA-Z%-]+)") do
                table.insert(atts, a)
            end
            for _, e in ipairs(es) do
                if not attr[e] then attr[e] = {} end
                for _, a in ipairs(atts) do
                    table.insert(attr[e], a)
                end
            end
        end
    end
end

-- Precompute the full allowed-attribute set per element so tag scanning does
-- an O(1) table lookup instead of rebuilding a table on every opening tag.
local allowed_attrs = {}
for e in pairs(element) do
    local t = {}
    for k, v in pairs(global) do t[k] = v end
    if attr[e] then
        for _, a in ipairs(attr[e]) do
            t[a:lower()] = true
        end
    end
    allowed_attrs[e] = t
end

local t_line = spec:match("Allowed `input` types: ([^\r\n]+)") or ""
local itype = {}
local itype_count = 0
for t in t_line:gmatch("`([a-z]+)`") do
    if not itype[t] then itype_count = itype_count + 1 end
    itype[t] = true
end

-- --- 6.2 allowed properties ---
-- Only the bold-labelled groups list properties; surrounding prose must not
-- leak into the allowlist, so parse the groups rather than the whole section.
local p_sec = spec:match("### 6%.2 Allowed properties(.-)### 6%.3") or ""
local prop = {}
local prop_count = 0
for line in p_sec:gmatch("[^\r\n]+") do
    local group = line:match("^%*%*[^*]+:%*%*(.*)$")
    if group then
        group = group:gsub("%([^)]*%)", "")
        for p in group:gmatch("`([a-z%-]+)`") do
            if not prop[p] then prop_count = prop_count + 1 end
            prop[p] = true
        end
    end
end

-- --- 6.2 enumerated property values ---
local enum_values = {
    ["display"] = { ["block"]=true, ["inline"]=true, ["inline-block"]=true, ["none"]=true, ["flex"]=true, ["grid"]=true },
    ["flex-direction"] = { ["row"]=true, ["column"]=true, ["row-reverse"]=true, ["column-reverse"]=true },
    ["flex-wrap"] = { ["nowrap"]=true, ["wrap"]=true, ["wrap-reverse"]=true },
    ["justify-content"] = { ["flex-start"]=true, ["flex-end"]=true, ["center"]=true, ["space-between"]=true, ["space-around"]=true },
    ["align-items"] = { ["flex-start"]=true, ["flex-end"]=true, ["center"]=true, ["stretch"]=true },
    ["align-content"] = { ["flex-start"]=true, ["flex-end"]=true, ["center"]=true, ["space-between"]=true, ["space-around"]=true, ["stretch"]=true },
    ["text-align"] = { ["left"]=true, ["right"]=true, ["center"]=true, ["justify"]=true, ["start"]=true, ["end"]=true },
    ["text-decoration"] = { ["none"]=true, ["underline"]=true, ["line-through"]=true },
    ["text-transform"] = { ["none"]=true, ["uppercase"]=true, ["lowercase"]=true, ["capitalize"]=true },
    ["white-space"] = { ["normal"]=true, ["nowrap"]=true, ["pre"]=true, ["pre-wrap"]=true, ["pre-line"]=true },
    ["overflow-wrap"] = { ["normal"]=true, ["break-word"]=true, ["anywhere"]=true },
    ["word-break"] = { ["normal"]=true, ["break-all"]=true, ["keep-all"]=true },
    ["background-repeat"] = { ["repeat"]=true, ["repeat-x"]=true, ["repeat-y"]=true, ["no-repeat"]=true },
    ["list-style-position"] = { ["inside"]=true, ["outside"]=true },
    ["border-collapse"] = { ["collapse"]=true, ["separate"]=true },
    ["caption-side"] = { ["top"]=true, ["bottom"]=true },
    ["empty-cells"] = { ["show"]=true, ["hide"]=true },
    ["overflow"] = { ["visible"]=true, ["hidden"]=true, ["scroll"]=true, ["auto"]=true },
    ["overflow-x"] = { ["visible"]=true, ["hidden"]=true, ["scroll"]=true, ["auto"]=true },
    ["overflow-y"] = { ["visible"]=true, ["hidden"]=true, ["scroll"]=true, ["auto"]=true },
    ["cursor"] = { ["auto"]=true, ["default"]=true, ["pointer"]=true, ["text"]=true },
    ["box-sizing"] = { ["content-box"]=true, ["border-box"]=true },
    ["font-style"] = { ["normal"]=true, ["italic"]=true },
    ["font-weight"] = { ["100"]=true, ["200"]=true, ["300"]=true, ["400"]=true, ["500"]=true, ["600"]=true, ["700"]=true, ["800"]=true, ["900"]=true, ["normal"]=true, ["bold"]=true },
    ["vertical-align"] = { ["baseline"]=true, ["top"]=true, ["middle"]=true, ["bottom"]=true, ["sub"]=true, ["super"]=true },
}

-- 6.2: permitted on every property, including those with enumerated values
local css_wide_keywords = { ["inherit"] = true, ["initial"] = true, ["unset"] = true }
local forbidden_css_wide_keywords = { ["revert"] = true, ["revert-layer"] = true }

-- --- 5.1 / 5.2 enumerated attribute values ---
local meta_names = {
    ["viewport"] = true, ["description"] = true, ["keywords"] = true, ["author"] = true,
    ["color-scheme"] = true, ["generator"] = true, ["robots"] = true, ["theme-color"] = true,
}
local link_rels = { ["stylesheet"] = true, ["icon"] = true, ["alternate"] = true }

-- --- 6.3 allowed pseudo-classes and pseudo-elements ---
local allowed_pseudo_classes = {
    ["hover"] = true, ["focus"] = true, ["active"] = true, ["visited"] = true,
    ["link"] = true, ["first-child"] = true, ["last-child"] = true, ["nth-child"] = true,
    ["target"] = true, ["checked"] = true, ["disabled"] = true, ["required"] = true,
    ["valid"] = true, ["invalid"] = true,
    -- CSS2 single-colon compatibility for pseudo-elements:
    ["before"] = true, ["after"] = true, ["first-line"] = true, ["first-letter"] = true,
}
local allowed_pseudo_elements = {
    ["before"] = true, ["after"] = true, ["first-line"] = true, ["first-letter"] = true,
}

-- --- 6.4 allowed units ---
local allowed_units = {
    ["px"] = true, ["pt"] = true, ["cm"] = true, ["mm"] = true, ["in"] = true,
    ["em"] = true, ["rem"] = true, ["ex"] = true, ["ch"] = true, ["%"] = true,
    ["vw"] = true, ["vh"] = true, ["vmin"] = true, ["vmax"] = true,
}

-- Extracts rules from a comment-free CSS string, respecting @media blocks
local function extract_rules(css)
    local stripped = css:gsub('"(.-)"', '""'):gsub("'(.-)'", "''")
    stripped = stripped:gsub("[uU][rR][lL]%s*%([^)]*%)", "url()")
    local rules = {}
    local depth = 0
    local in_media = false
    local current_sel = ""
    local i = 1
    local len = #stripped
    local last_sep = 1

    while i <= len do
        local brace = stripped:find("[{}]", i)
        if not brace then break end
        local c = stripped:sub(brace, brace)
        if c == "{" then
            local header = stripped:sub(last_sep, brace - 1):gsub("^%s+", ""):gsub("%s+$", "")
            local h_l = header:lower()
            if h_l:match("^@media%f[%A]") then
                in_media = true
            elseif h_l:match("^@font%-face%f[%A]") or h_l:match("^@keyframes%f[%A]") then
                -- at-rule header
            else
                current_sel = header
            end
            depth = depth + 1
            last_sep = brace + 1
        else
            local decls = stripped:sub(last_sep, brace - 1)
            if current_sel ~= "" then
                table.insert(rules, { sel = current_sel, decls = decls, in_media = in_media })
                current_sel = ""
            end
            depth = depth - 1
            if depth <= 0 then
                in_media = false
                depth = 0
            end
            last_sep = brace + 1
        end
        i = brace + 1
    end
    return rules
end

local args = {}
for i = 1, #arg do
    table.insert(args, arg[i])
end

if #args == 0 then
    io.stderr:write(string.format([[usage: %s [--classify] [--css] [--format=text|json] PATH...

  PATH             HTML/CSS file or directory (searched recursively).
  --css            Treat every input as a style sheet rather than a document.
                   Inputs ending in .css are detected without this.
  --format=json    Emit findings as JSON, for callers that would otherwise
                   parse the prose.
  --classify       Report each document as Conforming, Extended or
                   Non-conforming (section 2.6).
]], arg[0] or "webveld-validate"))
    os.exit(1)
end


-- Runs the section 4-9 checks over one piece of markup and returns the
-- violations. Options: fragment = true skips the document-structure checks of
-- 4.1/4.2 and the heading hierarchy, for markup that is not a whole document
-- (a `noscript` body under 2.5); allow_noscript = true suppresses the 2.3.7
-- rejection, for the classification of 2.6 where `noscript` is expected.
local function check_doc(dom, o)
    o = o or {}
    local bad = {}

    -- elements and attributes via quote-aware tag scanner
    local seen_el = {}
    local open_count = {}
    local reported = {}
    local bad_attrs = {}
    local has_inline_style = false
    local heading_bad = {}
    local prev_h = 0
    local value_bad_list = {}
    local seen_value_bad = {}
    local function add_value_bad(msg)
        if not seen_value_bad[msg] then
            seen_value_bad[msg] = true
            table.insert(value_bad_list, msg)
        end
    end
    local el_attrs = {
        meta = {},
        link = {},
        img = {},
        a = {},
        form = {},
        input = {},
    }
    local current_form_attrs = nil
    local pos = 1
    local dom_len = #dom

    while pos <= dom_len do
        local tag_start, tag_name_end, slash, el_name = dom:find("<(/?)([a-zA-Z][a-zA-Z0-9%-]*)", pos)
        if not tag_start then break end

        local el = el_name:lower()
        seen_el[el] = (seen_el[el] or 0) + 1

        local tag_end = nil
        local cur = tag_name_end + 1
        while cur <= dom_len do
            local hit = dom:find("[\"'>]", cur)
            if not hit then break end
            local ch = dom:sub(hit, hit)
            if ch == '>' then
                tag_end = hit
                break
            else
                local q_end = dom:find(ch, hit + 1, true)
                if not q_end then break end
                cur = q_end + 1
            end
        end

        if not tag_end then
            pos = tag_name_end + 1
        else
            pos = tag_end + 1
            if slash == "/" then
                if el == "form" then
                    current_form_attrs = nil
                end
            else
                open_count[el] = (open_count[el] or 0) + 1

                if #el == 2 and el:sub(1, 1) == "h" then
                    local lvl = tonumber(el:sub(2, 2))
                    if lvl and lvl >= 1 and lvl <= 6 then
                        if prev_h > 0 and lvl > prev_h + 1 then
                            table.insert(heading_bad, string.format("heading hierarchy skips a level: <h%d> followed by <h%d> (9)", prev_h, lvl))
                        end
                        prev_h = lvl
                    end
                end

                local attrs_str = ""
                if tag_end > tag_name_end + 1 then
                    attrs_str = dom:sub(tag_name_end + 1, tag_end - 1)
                    if attrs_str:find("/", 1, true) then
                        attrs_str = attrs_str:gsub("/%s*$", "")
                    end
                end

                if el == "form" then
                    current_form_attrs = attrs_str
                    table.insert(el_attrs.form, attrs_str)
                elseif el == "input" then
                    table.insert(el_attrs.input, { attrs = attrs_str, form = current_form_attrs })
                elseif el == "img" then
                    table.insert(el_attrs.img, attrs_str)
                elseif attrs_str ~= "" then
                    if el == "meta" or el == "link" or el == "a" then
                        table.insert(el_attrs[el], attrs_str)
                    end
                end

                local a_len = #attrs_str
                if a_len > 0 then
                    local allow = allowed_attrs[el]
                    local a_pos = 1
                    while a_pos <= a_len do
                        local s_idx, e_idx, a_name = attrs_str:find("%s+([a-zA-Z%-]+)", a_pos)
                        if not s_idx then break end
                        local after = e_idx + 1
                        local val_s, val_e = nil, nil
                        local eq_s, eq_e = attrs_str:find("^%s*=%s*", after)
                        if eq_e then
                            after = eq_e + 1
                            local q = attrs_str:sub(after, after)
                            if q == '"' or q == "'" then
                                local q_end = attrs_str:find(q, after + 1, true)
                                if q_end then
                                    val_s, val_e = after + 1, q_end - 1
                                    after = q_end + 1
                                else
                                    after = a_len + 1
                                end
                            else
                                local u_end = attrs_str:find("[%s>]", after)
                                if u_end then
                                    val_s, val_e = after, u_end - 1
                                    after = u_end
                                else
                                    val_s, val_e = after, a_len
                                    after = a_len + 1
                                end
                            end
                        end
                        a_pos = after

                        local a = a_name:lower()
                        if a == "style" then
                            has_inline_style = true
                        elseif a == "tabindex" and val_s then
                            local tv = attrs_str:sub(val_s, val_e):lower()
                            if tv ~= "0" and tv ~= "-1" then
                                add_value_bad("tabindex must be 0 or -1 (5.1)")
                            end
                        elseif a == "dir" and val_s then
                            local dv = attrs_str:sub(val_s, val_e):lower()
                            if dv ~= "ltr" and dv ~= "rtl" then
                                add_value_bad("dir must be ltr or rtl (5.1)")
                            end
                        end
                        if allow and not allow[a] then
                            local key = el .. "/" .. a
                            if not reported[key] then
                                reported[key] = true
                                table.insert(bad_attrs, string.format("attribute `%s` is not permitted on <%s> (5.1/5.2/5.3)", a, el))
                            end
                        end
                    end
                end
            end
        end
    end

    local sorted_el = {}
    for e in pairs(seen_el) do
        table.insert(sorted_el, e)
    end
    table.sort(sorted_el)
    for _, e in ipairs(sorted_el) do
        if e ~= "doctype" and not element[e] then
            table.insert(bad, string.format("element <%s> is not permitted (4.3/4.4)", e))
        end
    end
    if seen_el["noscript"] and not o.allow_noscript then
        table.insert(bad, "element <noscript> is permitted only in extended documents (2.3.7, 2.5, 4.3)")
    end

    for _, a_err in ipairs(bad_attrs) do
        table.insert(bad, a_err)
    end

    -- enumerated attribute values (5.1, 5.2) and link data: URLs (7.1)
    local function attr_value(attrs, name)
        local v = attrs:match("%f[%w%-]" .. name .. "%s*=%s*\"([^\"]*)\"")
            or attrs:match("%f[%w%-]" .. name .. "%s*=%s*'([^']*)'")
            or attrs:match("%f[%w%-]" .. name .. "%s*=%s*([^%s\"'>]+)")
        return v and v:lower()
    end
    for _, attrs in ipairs(el_attrs.meta) do
        local attrs_l = attrs:lower()
        local name = attr_value(attrs_l, "name")
        if name and not meta_names[name] then
            add_value_bad(string.format("meta name `%s` is not permitted (5.2)", name))
        end
        if name == "viewport" then
            local content = attr_value(attrs_l, "content") or ""
            if content:match("user%-scalable") or content:match("maximum%-scale") then
                add_value_bad("meta viewport must not set user-scalable or maximum-scale (5.2)")
            end
        end
        local property = attr_value(attrs_l, "property")
        if property and not property:match("^og:") then
            add_value_bad(string.format("meta property `%s` is not permitted; only og:* properties are (5.2)", property))
        end
    end
    for _, attrs in ipairs(el_attrs.link) do
        local attrs_l = attrs:lower()
        local rel = attr_value(attrs_l, "rel")
        if rel and not link_rels[rel] then
            add_value_bad(string.format("link rel `%s` is not permitted (5.2)", rel))
        end
        local href = attr_value(attrs_l, "href")
        if href and href:match("^%s*data:") and not (rel == "icon" and href:match("^%s*data:image/png[;,]")) then
            add_value_bad("`data:` in <link href> is permitted only for a PNG icon (7.1)")
        end
    end
    for _, inp in ipairs(el_attrs.input) do
        local attrs_l = inp.attrs:lower()
        if attrs_l:match("%f[%w%-]checked%f[^%w%-]") then
            local ty = attr_value(attrs_l, "type") or "text"
            if ty ~= "checkbox" and ty ~= "radio" then
                add_value_bad("`checked` is permitted only on checkbox and radio inputs (5.2)")
            end
        end
    end

    -- details requires summary as its first child (4.3)
    local dom_l = nil
    local function get_dom_l()
        if not dom_l then dom_l = dom:lower() end
        return dom_l
    end

    if open_count["details"] then
        local dl = get_dom_l()
        for body in dl:gmatch("<details%f[^%w%-][^>]*>(.-)<") do
            if body:match("%S") then
                add_value_bad("<details> must have <summary> as its first child (4.3)")
            end
        end
        for after in dl:gmatch("<details%f[^%w%-][^>]*>%s*(<[^%s>]*)") do
            if after ~= "<summary" then
                add_value_bad("<details> must have <summary> as its first child (4.3)")
            end
        end
    end

    for _, v_err in ipairs(value_bad_list) do
        table.insert(bad, v_err)
    end

    -- inline style attribute
    if has_inline_style then
        table.insert(bad, "inline style attribute is forbidden (6.1)")
    end


    -- CSS
    local cp = {}
    if open_count["style"] then
        local dl = get_dom_l()
        local s_pos = 1
        while true do
            local st_s, st_content_s = dl:find("<style[^>]*>", s_pos)
            if not st_s then break end
            local end_s, end_e = dl:find("</style%s*>", st_content_s + 1)
            local blk
            if end_s then
            blk = dom:sub(st_content_s + 1, end_s - 1)
            s_pos = end_e + 1
        else
            blk = dom:sub(st_content_s + 1)
            s_pos = #dom + 1
        end

        if blk:find("/*", 1, true) then
            blk = blk:gsub("/%*.-%*/", "")
        end
        local blk_l = blk:lower()

        if blk_l:find("@import", 1, true) then
            table.insert(bad, "@import is forbidden (6.7)")
        end
        if blk_l:find("important", 1, true) and blk_l:match("!%s*important%f[%A]") then
            table.insert(bad, "!important is forbidden in author style sheets (2.3.4, 6.1)")
        end

        if blk_l:find("@media", 1, true) then
            local media_depth = 0
            local in_media = false
            local b_pos = 1
            local blk_len = #blk

            local next_m_s, next_m_e = blk_l:find("@media%f[%A]", 1)
            local next_u_s, next_u_e = blk_l:find("url%s*%(", 1)
            local next_l_s = blk:find("{", 1, true)
            local next_r_s = blk:find("}", 1, true)

            while b_pos <= blk_len do
                if next_m_s and next_m_s < b_pos then next_m_s, next_m_e = blk_l:find("@media%f[%A]", b_pos) end
                if next_u_s and next_u_s < b_pos then next_u_s, next_u_e = blk_l:find("url%s*%(", b_pos) end
                if next_l_s and next_l_s < b_pos then next_l_s = blk:find("{", b_pos, true) end
                if next_r_s and next_r_s < b_pos then next_r_s = blk:find("}", b_pos, true) end

                local next_tok = nil
                local next_s = blk_len + 1
                local next_e = blk_len + 1

                if next_m_s and next_m_s < next_s then next_tok = "@media"; next_s = next_m_s; next_e = next_m_e end
                if next_u_s and next_u_s < next_s then next_tok = "url"; next_s = next_u_s; next_e = next_u_e end
                if next_l_s and next_l_s < next_s then next_tok = "{"; next_s = next_l_s; next_e = next_l_s end
                if next_r_s and next_r_s < next_s then next_tok = "}"; next_s = next_r_s; next_e = next_r_s end

                if not next_tok then break end

                if next_tok == "@media" then
                    if in_media then
                        table.insert(bad, "nested @media rules are forbidden (6.6)")
                    end
                    in_media = true
                elseif next_tok == "url" then
                    if in_media then
                        table.insert(bad, "url() inside a media-query block is forbidden (6.6)")
                    end
                elseif next_tok == "{" then
                    media_depth = media_depth + 1
                elseif next_tok == "}" then
                    media_depth = media_depth - 1
                    if media_depth <= 0 then
                        in_media = false
                    end
                end
                b_pos = next_e + 1
            end

            for cond in blk_l:gmatch("@media%s*([^{]*){") do
                -- words outside parentheses are media types, modifiers, or `and`
                for word in cond:gsub("%b()", " "):gmatch("[%a%-]+") do
                    if word == "not" or word == "only" then
                        table.insert(bad, "the `not` and `only` media query modifiers are forbidden (6.6)")
                    elseif word ~= "and" and word ~= "print" then
                        table.insert(bad, "media types other than print are forbidden in @media (6.6)")
                    end
                end
                for group in cond:gmatch("%b()") do
                    if group:match("[<>=]") then
                        table.insert(bad, "media query range syntax is forbidden; use min-width or max-width (6.6)")
                    end
                end
                for feat in cond:gmatch("%(%s*([%-a-z]+)%s*[:)]") do
                    if feat ~= "width" and feat ~= "min-width" and feat ~= "max-width" and feat ~= "prefers-color-scheme" then
                        table.insert(bad, string.format("media feature `%s` is not permitted (6.6)", feat))
                    end
                end
                for scheme in cond:gmatch("prefers%-color%-scheme%s*:%s*([%a%-]+)") do
                    if scheme ~= "light" and scheme ~= "dark" then
                        table.insert(bad, "prefers-color-scheme must be light or dark (6.6)")
                    end
                end
            end
        end

        if blk_l:find("keyframes", 1, true) and (blk_l:match("@keyframes%f[%A]") or blk_l:match("@%-webkit%-keyframes%f[%A]")) then
            table.insert(bad, "@keyframes is forbidden (6.7)")
        end

        if blk_l:find("gradient", 1, true) then
            if blk_l:match("%f[%a]linear%-gradient%s*%(") or blk_l:match("%f[%a]radial%-gradient%s*%(")
               or blk_l:match("%f[%a]conic%-gradient%s*%(") or blk_l:match("%f[%a]repeating%-linear%-gradient%s*%(")
               or blk_l:match("%f[%a]repeating%-radial%-gradient%s*%(") or blk_l:match("%f[%a]repeating%-conic%-gradient%s*%(") then
                table.insert(bad, "gradients are forbidden (6.7)")
            end
        end
        if blk_l:find("var", 1, true) and blk_l:match("%f[%a]var%s*%(") then
            table.insert(bad, "var() is forbidden; custom properties are outside the subset (6.7)")
        end

        if blk_l:find("@font-face", 1, true) then
            if blk_l:match("@font%-face[^}]*local%s*%(") then
                table.insert(bad, "local() in @font-face is forbidden (6.5)")
            end
            if blk_l:match("@font%-face[^{]*{[^}]*src%s*:[^;}]*url%s*%(%s*[\"']?https?://") then
                table.insert(bad, "cross-origin URL in @font-face src is forbidden (6.5, 7.3)")
            end
        end

        if blk_l:find("grid", 1, true) then
            if blk_l:match("grid%-template%-areas%s*:") then
                table.insert(bad, "grid-template-areas is forbidden; grid is a bounded subset (6.2, 6.7)")
            end
            if blk_l:match("grid%-auto%-flow%s*:") then
                table.insert(bad, "grid-auto-flow is forbidden; grid is a bounded subset (6.2, 6.7)")
            end
            if blk_l:match("grid%-auto%-rows%s*:") or blk_l:match("grid%-auto%-columns%s*:") then
                table.insert(bad, "grid-auto-rows/grid-auto-columns are forbidden; implicit tracks are outside the subset (6.2, 6.7)")
            end
            if blk_l:match("grid%-template[^;{}]*%f[%a]fit%-content%s*%(") then
                table.insert(bad, "fit-content() is forbidden in a track list (6.2, 6.7)")
            end
            if blk_l:match("grid%-template[^;{}]*%f[%a]subgrid%f[%A]") then
                table.insert(bad, "subgrid is forbidden (6.2, 6.7)")
            end
            if blk_l:match("display%s*:%s*inline%-grid%f[%A]") then
                table.insert(bad, "display: inline-grid is forbidden; only `grid` is permitted (6.2)")
            end
        end
        if blk_l:find("repeat", 1, true) then
            if blk_l:match("repeat%s*%(%s*auto%-fill%f[%A]") or blk_l:match("repeat%s*%(%s*auto%-fit%f[%A]") then
                table.insert(bad, "repeat() with auto-fill or auto-fit is forbidden; use a literal count (6.2, 6.7)")
            end
            for count_str in blk_l:gmatch("repeat%s*%(%s*(%d+)%s*,") do
                local c = tonumber(count_str)
                if c and c > 10000 then
                    table.insert(bad, string.format("repeat(%s) exceeds the 10,000 track bound (2.3.18, 6.2)", count_str))
                end
            end
        end

        if blk_l:find("url", 1, true) then
            for u in blk:gmatch("[uU][rR][lL]%s*%(%s*[\"']?([^\"')]+)") do
                local u_l = u:lower()
                if u_l:match("^https?://") or u_l:match("^//") then
                    table.insert(bad, "absolute URL in url(): subresources must be same-origin, and a validator cannot resolve the document's origin — use a relative URL (2.3.15, 7.2)")
                end
                local mime = u_l:match("^data:([^;,]+)")
                if mime then
                    if mime ~= "image/png" and mime ~= "image/jpeg" then
                        table.insert(bad, "data: URL in url() must be image/png or image/jpeg (7.1, 7.4)")
                    end
                end
            end
        end

        local rules = extract_rules(blk)
        local seen_rule_bad = {}
        local function add_rule_bad(msg)
            if not seen_rule_bad[msg] then
                seen_rule_bad[msg] = true
                table.insert(bad, msg)
            end
        end

        for _, r in ipairs(rules) do
            if r.sel:find(":", 1, true) then
                local sel = r.sel
                if sel:find("[", 1, true) then
                    sel = sel:gsub("%[[^%]]*%]", "")
                end
                local sel_l = sel:lower()

                if sel_l:find(":visited", 1, true) and sel_l:match(":visited%f[%A]") then
                    local vdecls_l = r.decls:lower()
                    if vdecls_l:match("background%-image%s*:") then
                        table.insert(bad, "background-image in :visited is forbidden (6.3)")
                    end
                    for vp in vdecls_l:gmatch("([%-a-z]+)%s*:") do
                        if vp ~= "color" and vp ~= "background-color" and vp ~= "border-color" and vp ~= "outline-color" then
                            table.insert(bad, string.format("property `%s` in :visited is forbidden; only color properties are permitted (6.3)", vp))
                        end
                    end
                end

                if sel_l:find(":focus", 1, true) and sel_l:match(":focus%f[%A]") then
                    local f_l = r.decls:lower()
                    local removes_outline = f_l:match("outline%s*:%s*none")
                        or f_l:match("outline%-style%s*:%s*none")
                        or f_l:match("outline%-width%s*:%s*0%f[^.0-9]")
                        or f_l:match("outline%s*:[^;]*%f[%w]0%f[%W]")
                    if removes_outline then
                        local has_indicator = f_l:match("%f[%a]background%-color%s*:")
                            or f_l:match("%f[%a]border%s*:")
                            or f_l:match("%f[%a]border%-[a-z]+%s*:")
                            or f_l:match("%f[%a]color%s*:")
                        if not has_indicator then
                            table.insert(bad, "a :focus rule removes the outline without establishing another visible indicator (9)")
                        end
                    end
                end

                local s_single = sel_l
                if sel_l:find("::", 1, true) then
                    for pe in sel_l:gmatch("::([%a%-]+)") do
                        if not allowed_pseudo_elements[pe] then
                            add_rule_bad(string.format("selector ::%s is forbidden (6.3)", pe))
                        end
                    end
                    s_single = sel_l:gsub("::[%a%-]+", "")
                end
                for pc in s_single:gmatch(":([%a%-]+)") do
                    if pc == "has" or pc == "is" or pc == "where" then
                        add_rule_bad(string.format("selector :%s() is forbidden (6.7)", pc))
                    elseif not allowed_pseudo_classes[pc] then
                        add_rule_bad(string.format("selector :%s is forbidden (6.3)", pc))
                    end
                end
                if sel_l:find(":nth-child", 1, true) then
                    for nth_arg in sel:gmatch(":[nN][tT][hH]%-[cC][hH][iI][lL][dD]%s*%(([^)]*)%)") do
                        local a = nth_arg:gsub("%s+", ""):lower()
                        local valid = (a == "odd" or a == "even" or a:match("^[+-]?%d+$") or a:match("^[+-]?%d*n$") or a:match("^[+-]?%d*n[+-]%d+$"))
                        if not valid then
                            add_rule_bad(string.format("invalid :nth-child argument `%s` (6.3)", nth_arg))
                        end
                    end
                end
            end

            for stmt in (r.decls .. ";"):gmatch("([^;]+);") do
                local pname, pval = stmt:match("^%s*([^:]-)%s*:%s*(.-)%s*$")
                if pname then
                    pname = pname:lower()
                    local val_l = pval:lower()

                    if pname ~= "" then
                        cp[pname] = (cp[pname] or 0) + 1
                    end

                    local css_wide = css_wide_keywords[val_l]
                    if forbidden_css_wide_keywords[val_l] then
                        add_rule_bad(string.format("value `%s` is not permitted for `%s` (6.2)", pval, pname))
                    elseif css_wide then
                        -- inherit/initial/unset satisfy every value restriction
                    elseif enum_values[pname] then
                        if not enum_values[pname][val_l] then
                            if pname == "display" and val_l == "inline-grid" then
                                add_rule_bad("display: inline-grid is forbidden; only `grid` is permitted (6.2)")
                            else
                                add_rule_bad(string.format("value `%s` is not permitted for `%s` (6.2)", pval, pname))
                            end
                        end
                    end

                    if pname == "content" then
                        local sel_l = r.sel:lower()
                        if not (sel_l:match("::before") or sel_l:match("::after") or sel_l:match(":before") or sel_l:match(":after")) then
                            add_rule_bad("content property is permitted only on ::before and ::after (6.2)")
                        end
                        if not css_wide and val_l ~= '""' and val_l ~= "''" and val_l ~= "none" and val_l ~= "normal" then
                            add_rule_bad("content value must be a quoted string, none, or normal (6.2)")
                        end
                    elseif pname == "border-radius" then
                        if pval:find("/", 1, true) then
                            add_rule_bad("slash syntax in border-radius is forbidden (6.2)")
                        end
                    elseif pname == "list-style" then
                        if val_l:find("url", 1, true) and val_l:match("%f[%a]url%s*%(") then
                            add_rule_bad("url() in list-style is forbidden (6.2)")
                        end
                    elseif pname == "background-image" then
                        if not css_wide and val_l ~= "none" and not (val_l:find("url", 1, true) and val_l:match("%f[%a]url%s*%(")) then
                            add_rule_bad("background-image must be a URL or none (6.2)")
                        end
                    elseif pname == "clip-path" then
                        if not css_wide and val_l ~= "none" and not val_l:match("^inset%s*%(") and not val_l:match("^rect%s*%(") then
                            add_rule_bad(string.format("value `%s` is not permitted for `clip-path` (6.2)", pval))
                        end
                    end
                    if val_l:find("fit-content", 1, true) and pname ~= "grid-template-columns" and pname ~= "grid-template-rows" and val_l:match("%f[%a]fit%-content%s*%(") then
                        add_rule_bad("fit-content() is forbidden (6.2, 6.7)")
                    end

                    if pval:find("%d") then
                        local s_unit = pval
                        if s_unit:find("#", 1, true) then
                            s_unit = s_unit:gsub("#%x+", " ")
                        end
                        if val_l:find("url", 1, true) then
                            s_unit = s_unit:gsub("[uU][rR][lL]%s*%([^)]*%)", " ")
                        end
                        local pos = 1
                        while pos <= #s_unit do
                            local s_idx, e_idx, num, u = s_unit:find("([0-9]*%.?[0-9]+)([%a%%]+)", pos)
                            if not s_idx then break end
                            local prev = s_idx > 1 and s_unit:sub(s_idx - 1, s_idx - 1) or " "
                            local is_ident = false
                            if prev:match("[%a_]") then
                                is_ident = true
                            elseif prev == "-" then
                                local p2 = s_idx > 2 and s_unit:sub(s_idx - 2, s_idx - 2) or " "
                                if p2:match("[%a_%-]") then
                                    is_ident = true
                                end
                            end
                            if not is_ident then
                                local ul = u:lower()
                                local is_allowed = allowed_units[ul]
                                if ul == "fr" and (pname == "grid-template-columns" or pname == "grid-template-rows") then
                                    is_allowed = true
                                end
                                if not is_allowed then
                                    if ul == "fr" then
                                        add_rule_bad("unit `fr` is permitted only in grid track lists (6.2, 6.4)")
                                    else
                                        add_rule_bad(string.format("unit `%s` is not permitted (6.4)", u))
                                    end
                                end
                            end
                            pos = e_idx + 1
                        end
                    end
                end
            end
        end
        end
    end

    local sorted_cp = {}
    for p in pairs(cp) do
        table.insert(sorted_cp, p)
    end
    table.sort(sorted_cp)
    for _, p in ipairs(sorted_cp) do
        if not prop[p] then
            table.insert(bad, string.format("CSS property `%s` is not permitted (6.2)", p))
        end
    end

    -- document structure (whole documents only; a 2.5 noscript body has none)
    if not o.fragment then
        local dl = get_dom_l()
        if not dl:match("<!doctype%s+html%s*>") then
            table.insert(bad, "missing <!DOCTYPE html> (4.1)")
        end
        if not dl:match("<html[^>]*%slang%s*=") then
            table.insert(bad, "<html> requires lang (4.1)")
        end
        if not dl:match("<meta[^>]*charset%s*=%s*[\"']?utf%-8") then
            table.insert(bad, "missing <meta charset=\"utf-8\"> (4.2)")
        end
        local titles = open_count["title"] or 0
        if titles ~= 1 then
            table.insert(bad, string.format("expected exactly one <title>, found %d (4.3)", titles))
        end
        local mains = open_count["main"] or 0
        if mains > 1 then
            table.insert(bad, string.format("at most one <main> per document, found %d (4.3)", mains))
        end

        -- heading hierarchy (9)
        for _, h_err in ipairs(heading_bad) do
            table.insert(bad, h_err)
        end
    end

    -- images, forms, inputs
    for _, a in ipairs(el_attrs.img) do
        local a_l = a:lower()
        if not a_l:match("%salt%s*=") then
            table.insert(bad, "<img> requires alt (5.2, 9)")
        end
        if a_l:match("%f[%a]src%s*=%s*[\"']?https?://") or a_l:match("%f[%a]src%s*=%s*[\"']?//") then
            table.insert(bad, "absolute URL in img src: subresources must be same-origin, and a validator cannot resolve the document's origin — use a relative URL (2.3.15, 7.2)")
        elseif a_l:match("%f[%a]src%s*=%s*[\"']?data:([^;,]+)") then
            local mime = a_l:match("%f[%a]src%s*=%s*[\"']?data:([^;,]+)")
            if mime ~= "image/png" and mime ~= "image/jpeg" then
                table.insert(bad, "data: image URL must be image/png or image/jpeg (7.1, 7.4)")
            end
        end
        if not a_l:match("%f[%a]src%s*=%s*[\"']?data:") then
            local src_ext = a_l:match("%f[%a]src%s*=%s*[\"']?[^\"'>%s]*%.([a-zA-Z0-9]+)[%?#][^\"'>%s]*[\"'>%s]")
                         or a_l:match("%f[%a]src%s*=%s*[\"']?[^\"'>%s]*%.([a-zA-Z0-9]+)[\"'>%s]")
            if src_ext then
                if src_ext ~= "png" and src_ext ~= "jpeg" and src_ext ~= "jpg" then
                    table.insert(bad, string.format("image format `.%s` is not permitted; documents reference PNG and JPEG only (2.3.16, 7.4)", src_ext))
                end
            end
        end
    end

    -- subresources referenced by <link>: origin, and the icon format baseline
    for _, a in ipairs(el_attrs.link) do
        local rel = a:match("%f[%a][rR][eE][lL]%s*=%s*[\"']?([a-zA-Z%-]+)")
        rel = (rel or ""):lower()
        local href = a:match("%f[%a][hH][rR][eE][fF]%s*=%s*[\"']?([^\"'>%s]+)")
        if href then
            local href_l = href:lower()
            if rel == "stylesheet" or rel == "icon" then
                if href_l:match("^https?://") or href_l:match("^//") then
                    table.insert(bad, string.format("absolute URL in <link rel=\"%s\">: subresources must be same-origin, and a validator cannot resolve the document's origin — use a relative URL (2.3.15, 7.2)", rel))
                end
            end
            if rel == "icon" then
                local ext = href_l:match("%.([a-zA-Z0-9]+)[%?#]") or href_l:match("%.([a-zA-Z0-9]+)$")
                if ext and ext ~= "png" then
                    table.insert(bad, string.format("site icon format `.%s` is not permitted; a conforming document references a PNG icon (5.2, 7.4)", ext))
                end
            end
        end
    end

    -- navigation positions take any registered scheme except script URLs and
    -- local-file navigation; document data: URLs stay out (7.1)
    for _, a in ipairs(el_attrs.a) do
        if a:find(":", 1, true) then
            local sch = a:match("%f[%a][hH][rR][eE][fF]%s*=%s*[\"']?([a-zA-Z0-9%+%.%-]+):")
            if sch then
                local s = sch:lower()
                if s == "javascript" or s == "vbscript" then
                    table.insert(bad, string.format("URL scheme `%s:` is script execution in a URL and is forbidden (7.1)", s))
                elseif s == "file" then
                    table.insert(bad, "`file:` must not be navigated to from a remote document (7.1)")
                elseif s == "data" then
                    table.insert(bad, "`data:` is permitted only for images in src or url(), not for navigation (7.1)")
                end
            end
        end
    end

    for _, a in ipairs(el_attrs.form) do
        local a_l = a:lower()
        if not a_l:match("%saction%s*=") then
            table.insert(bad, "<form> requires action (5.2)")
        end
        local m = a_l:match("method%s*=%s*[\"']?(%w+)")
        if m and m ~= "get" and m ~= "post" then
            table.insert(bad, "form method must be get or post (5.2)")
        end
        local sch = a:match("%f[%a][aA][cC][tT][iI][oO][nN]%s*=%s*[\"']?([a-zA-Z0-9%+%.%-]+):")
        if sch then
            local s = sch:lower()
            if s ~= "http" and s ~= "https" then
                table.insert(bad, string.format("form action scheme `%s:` is not permitted; submission is unmodified HTTP (7.1, 8)", s))
            end
        end
    end

    local labelable = 0
    for _, inp in ipairs(el_attrs.input) do
        local a = inp.attrs
        local ty = a:match("[tT][yY][pP][eE]%s*=%s*[\"']?([a-zA-Z]+)")
        ty = (ty or "text"):lower()
        if not itype[ty] then
            table.insert(bad, string.format("input type=\"%s\" is not permitted (5.2)", ty))
        end
        if ty ~= "submit" and ty ~= "reset" and ty ~= "hidden" and ty ~= "button" and ty ~= "image" then
            labelable = labelable + 1
        end
        local auto = a:match("[aA][uU][tT][oO][cC][oO][mM][pP][lL][eE][tT][eE]%s*=%s*[\"']?([a-zA-Z%-]+)")
        if auto then
            local v = auto:lower()
            if v ~= "username" and v ~= "current-password" and v ~= "new-password" and v ~= "off" then
                table.insert(bad, string.format("autocomplete=\"%s\" is not one of username, current-password, new-password, off (5.2)", v))
            end
        end
        local pat = a:match("%f[%a][pP][aA][tT][tT][eE][rR][nN]%s*=%s*[\"']([^\"']+)[\"']")
        if pat then
            if pat:match("%(%?[=!<]") or pat:match("\\[1-9]") then
                table.insert(bad, "pattern attribute must not use lookaround or backreferences (2.3.9, 5.2)")
            end
        end
        if ty == "password" then
            local form_str = inp.form
            if not (form_str and form_str:lower():match("action%s*=%s*[\"']?https:")) then
                table.insert(bad, "a form containing a password field requires an https action (5.2)")
            end
        end
    end

    local labels = open_count["label"] or 0
    if labels < labelable then
        table.insert(bad, string.format("%d labelable inputs but only %d <label> elements (9)", labelable, labels))
    end

    return bad
end

-- --- 2.6 classification -------------------------------------------------
-- Conforming, Extended or Non-conforming, decided from the document alone by
-- the algorithm section 2.6 states: strip `script` and `noscript`, run the 2.3
-- check over what remains, and run the sections 4-9 checks over the `noscript`
-- content.
local function classify(dom)
    local dom_l = dom:lower()
    local has_script = (dom_l:match("<script[%s>]") ~= nil)
    local has_noscript = (dom_l:match("<noscript[%s>]") ~= nil)

    local core = dom
    if has_script then
        core = core:gsub("<[sS][cC][rR][iI][pP][tT]%f[%A][^>]*>.-</[sS][cC][rR][iI][pP][tT]%s*>", "")
        core = core:gsub("<[sS][cC][rR][iI][pP][tT]%f[%A][^>]*%/?>", "")
    end
    if has_noscript then
        core = core:gsub("<[nN][oO][sS][cC][rR][iI][pP][tT]%f[%A][^>]*>.-</[nN][oO][sS][cC][rR][iI][pP][tT]%s*>", "")
    end
    local core_bad = check_doc(core)

    local ns_parts = {}
    for ns_content in dom:gmatch("<[nN][oO][sS][cC][rR][iI][pP][tT][^>]*>(.-)</[nN][oO][sS][cC][rR][iI][pP][tT]%s*>") do
        table.insert(ns_parts, ns_content)
    end
    local ns = table.concat(ns_parts, "\n")
    local ns_bad = {}
    if has_noscript then
        ns_bad = check_doc(ns, { fragment = true, allow_noscript = true })
    end

    if not has_script and not has_noscript and #core_bad == 0 then
        return "Conforming", {}
    end
    if has_script and has_noscript and #core_bad == 0 and #ns_bad == 0 then
        return "Extended", {}
    end

    local why = {}
    if not has_script and (#core_bad > 0 or has_noscript) then
        table.insert(why, "no `script`, so not an extended document (2.5 clause 1)")
    end
    if has_script and not has_noscript then
        table.insert(why, "carries `script` but no `noscript` (2.5 clause 2)")
    end
    for _, b in ipairs(core_bad) do
        table.insert(why, "outside `script` and `noscript`: " .. b)
    end
    for _, b in ipairs(ns_bad) do
        table.insert(why, "inside `noscript`: " .. b)
    end
    return "Non-conforming", why
end

local classify_opt = false
local force_css = false
local format = "text"
local inputs = {}

local idx = 1
while idx <= #args do
    local a = args[idx]
    if a == "--classify" then
        classify_opt = true
    elseif a == "--css" then
        force_css = true
    elseif a:match("^%-%-format=(.+)$") then
        format = a:match("^%-%-format=(.+)$")
    elseif a == "--" then
        idx = idx + 1
        while idx <= #args do
            table.insert(inputs, args[idx])
            idx = idx + 1
        end
        break
    elseif a:match("^%-%-") then
        io.stderr:write(string.format("%s: unknown option %s\n", arg[0] or "webveld-validate", a))
        os.exit(1)
    else
        table.insert(inputs, a)
    end
    idx = idx + 1
end

if format ~= "text" and format ~= "json" then
    io.stderr:write(string.format("%s: --format must be text or json\n", arg[0] or "webveld-validate"))
    os.exit(1)
end

local function shell_quote(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function is_dir(path)
    local f = io.open(path, "r")
    if not f then
        return false
    end
    local _, rerr = f:read(0)
    f:close()
    return rerr ~= nil
end

local function is_target_file(path, css_only)
    local lower = path:lower()
    if css_only then
        return lower:match("%.css$") ~= nil
    end
    return lower:match("%.html$") ~= nil
        or lower:match("%.htm$") ~= nil
        or lower:match("%.css$") ~= nil
end

local function collect_dir_files(dir, css_only)
    local clean = dir:gsub("/+$", "")
    if clean == "" then clean = "/" end
    local found = {}
    local p = io.popen("find " .. shell_quote(clean) .. " -type f 2>/dev/null | sort")
    if p then
        for line in p:lines() do
            if is_target_file(line, css_only) then
                table.insert(found, line)
            end
        end
        p:close()
    end
    return found
end

local files = {}
local failed = 0

for _, input in ipairs(inputs) do
    if is_dir(input) then
        local found = collect_dir_files(input, force_css)
        if #found == 0 then
            failed = failed + 1
            io.stderr:write(string.format("%s: no matching files in %s\n", arg[0] or "webveld-validate", input))
        else
            for _, f in ipairs(found) do
                table.insert(files, f)
            end
        end
    else
        table.insert(files, input)
    end
end

-- A style sheet is not a document, and handing one to the document checks
-- reported a missing doctype while never looking at the rules -- so an external
-- style sheet, which is the ordinary case, went unchecked entirely. Wrapping it
-- in a minimal conforming document runs the section 6 checks against it and
-- nothing else: any finding that comes back is the style sheet's own.
local function as_document(css)
    return '<!DOCTYPE html>\n<html lang="en">\n<head>\n'
        .. '<meta charset="utf-8">\n<title>style sheet</title>\n'
        .. '<style>\n' .. css .. '\n</style>\n</head>\n<body><p>x</p></body>\n</html>\n'
end

local function json_string(v)
    v = v or ""
    v = v:gsub("\\", "\\\\")
    v = v:gsub('"', '\\"')
    v = v:gsub("\n", "\\n")
    v = v:gsub("\t", "\\t")
    v = v:gsub("[%z\1-\31]", function(c)
        return string.format("\\u%04x", string.byte(c))
    end)
    return '"' .. v .. '"'
end

if format == "text" then
    io.write(string.format("allowlists from %s: %d elements, %d properties, %d input types\n\n",
        spec_path, element_count, prop_count, itype_count))
end

local results = {}

for _, file in ipairs(files) do
    local f = io.open(file, "r")
    if not f then
        failed = failed + 1
        local is_css = force_css or (file:lower():match("%.css$") ~= nil)
        if format == "json" then
            table.insert(results, {
                file = file,
                kind = is_css and "css" or "html",
                state = "non-conforming",
                findings = { "cannot open file" },
            })
        else
            io.stderr:write(string.format("%s: cannot open %s\n", arg[0] or "webveld-validate", file))
        end
    else
        local h = f:read("*a")
        f:close()

        local is_css = force_css or (file:lower():match("%.css$") ~= nil)
        local dom = is_css and as_document(h) or h
        if dom:find("<!--", 1, true) then
            dom = dom:gsub("<!%-%-.-%-%->", "")
        end

        if classify_opt and not is_css then
            local state, why = classify(dom)
            if format == "json" then
                table.insert(results, {
                    file = file,
                    kind = "html",
                    state = state:lower(),
                    findings = why,
                })
            else
                io.write(string.format("%-14s %s\n", state, file))
                for _, w in ipairs(why) do
                    io.write("  - " .. w .. "\n")
                end
            end
            if state == "Non-conforming" then
                failed = failed + 1
            end
        else
            local bad = check_doc(dom)
            if #bad > 0 then
                failed = failed + 1
            end

            if format == "json" then
                table.insert(results, {
                    file = file,
                    kind = is_css and "css" or "html",
                    state = (#bad > 0) and "non-conforming" or "conforming",
                    findings = bad,
                })
            elseif #bad > 0 then
                io.write(file .. "\n")
                for _, b in ipairs(bad) do
                    io.write("  - " .. b .. "\n")
                end
            else
                io.write(file .. ": conforms\n")
            end
        end
    end
end

if format == "json" then
    io.write("[\n")
    for i, r in ipairs(results) do
        local f_lines = {}
        for _, fd in ipairs(r.findings or {}) do
            table.insert(f_lines, "      " .. json_string(fd))
        end
        local f_str = ""
        if #f_lines > 0 then
            f_str = "\n" .. table.concat(f_lines, ",\n") .. "\n    "
        end
        local comma = (i == #results) and "" or ","
        io.write(string.format("  {\"file\": %s, \"kind\": %s, \"state\": %s, \"findings\": [%s]}%s\n",
            json_string(r.file),
            json_string(r.kind or "html"),
            json_string(r.state),
            f_str,
            comma))
    end
    io.write("]\n")
end

os.exit(failed > 0 and 1 or 0)
