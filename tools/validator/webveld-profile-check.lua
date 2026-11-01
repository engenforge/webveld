#!/usr/bin/env lua
-- Profile conformance checker for webveld-pico and webveld-nano in pure Lua.
--
-- webveld-validate checks the full specification only. A document can pass
-- it while using elements, attributes and properties a profile removes, because
-- a profile is a restriction on top of conformance rather than a variant of it.
-- This asks the narrower question.
--
-- Run webveld-validate first. This script assumes its input already conforms
-- to full WebVeld (sections 4-9) and checks only the profile restrictions:
--
--   webveld-pico   R1 elements, R2 attributes, R3 no style sheets at all
--   webveld-nano   R1 elements, R2 attributes, R3 properties/selectors/at-rules
--
-- Usage:
--   webveld-profile-check.lua [--profile=nano|pico] FILE...   (.html and .css)

local PROFILE = {
    pico = {
        doc      = 'doc/profiles/webveld-pico.md',
        elements = {
            'html', 'head', 'body', 'title', 'meta',
            'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
            'p', 'ul', 'ol', 'li', 'blockquote', 'pre', 'hr',
            'a', 'code',
        },
        global   = {'lang', 'id'},
        attr     = {
            meta = {'charset', 'name', 'content'},
            a    = {'href', 'title'},
        },
        css      = nil,
        values   = {},
    },
    nano = {
        doc      = 'doc/profiles/webveld-nano.md',
        elements = {
            'html', 'head', 'body', 'title', 'meta', 'link', 'style',
            'header', 'main', 'footer', 'nav', 'article', 'section', 'aside',
            'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
            'p', 'ul', 'ol', 'li', 'blockquote', 'pre', 'figure', 'figcaption', 'hr', 'div',
            'a', 'strong', 'em', 'i', 'b', 'u', 'code', 'kbd', 'samp', 'var', 'abbr', 'cite', 'q', 'mark', 'small', 'sub', 'sup',
            'del', 'ins', 'time', 'br', 'span',
            'img',
        },
        global   = {
            'lang', 'id', 'class', 'dir', 'title',
            'role', 'aria-label', 'aria-labelledby', 'aria-describedby',
            'aria-hidden', 'aria-expanded', 'aria-controls',
        },
        attr     = {
            meta       = {'charset', 'name', 'property', 'content'},
            link       = {'rel', 'href', 'type'},
            a          = {'href', 'rel', 'hreflang'},
            img        = {'src', 'alt', 'width', 'height'},
            ol         = {'start', 'reversed'},
            blockquote = {'cite'},
            q          = {'cite'},
            abbr       = {'title'},
            del        = {'datetime', 'cite'},
            ins        = {'datetime', 'cite'},
            time       = {'datetime'},
            code       = {'data-lang'},
        },
        css      = {
            'margin', 'margin-top', 'margin-right', 'margin-bottom', 'margin-left',
            'padding', 'padding-top', 'padding-right', 'padding-bottom', 'padding-left',
            'width', 'max-width', 'min-width', 'height',
            'border', 'border-width', 'border-style', 'border-color',
            'border-top', 'border-right', 'border-bottom', 'border-left',
            'border-radius', 'box-sizing',
            'outline', 'outline-width', 'outline-style', 'outline-color', 'outline-offset',
            'font-family', 'font-size', 'font-weight', 'font-style', 'line-height',
            'text-align', 'text-decoration', 'text-transform', 'letter-spacing', 'word-spacing',
            'white-space', 'overflow-wrap', 'word-break',
            'color', 'background-color', 'opacity',
            'list-style', 'list-style-type', 'list-style-position',
            'display',
        },
        values   = { display = {'none'} },
    },
}

local name = 'nano'
local files = {}

local args = {}
for i = 1, #arg do
    table.insert(args, arg[i])
end

for _, a in ipairs(args) do
    local prof_opt = a:match("^%-%-profile=(.+)$")
    if prof_opt then
        name = prof_opt
        if not PROFILE[name] then
            io.stderr:write(string.format("unknown profile '%s' (expected nano or pico)\n", name))
            os.exit(1)
        end
    elseif a:match("^%-") then
        io.stderr:write(string.format("unknown option %s\n", a))
        os.exit(1)
    else
        table.insert(files, a)
    end
end

if #files == 0 then
    io.stderr:write(string.format("usage: %s [--profile=nano|pico] FILE...\n", arg[0] or "webveld-profile-check"))
    os.exit(1)
end

local profile = PROFILE[name]
local element = {}
for _, e in ipairs(profile.elements) do element[e] = true end
local global = {}
for _, g in ipairs(profile.global) do global[g] = true end
local prop = {}
if profile.css then
    for _, p in ipairs(profile.css) do prop[p] = true end
end
local values = profile.values or {}

local function check_drift(p_name, prof, el_set, prop_set, val_map)
    local path = os.getenv("WEBVELD_PROFILE_DOC")
    if not path then
        local doc_rel = prof.doc
        local doc_base = doc_rel:match("[^/]+$")
        local pkgdatadir = '@@PKGDATADIR@@'
        local script_dir = "."
        if arg and arg[0] then
            local dir = arg[0]:match("^(.*)[/\\][^/\\]+$")
            if dir then script_dir = dir end
        end

        local candidates = {
            doc_rel,
            script_dir .. "/../share/webveld/" .. doc_rel,
            script_dir .. "/../share/webveld/profiles/" .. doc_base,
            script_dir .. "/../share/webveld/" .. doc_base,
            script_dir .. "/../../" .. doc_rel,
            pkgdatadir .. "/" .. doc_rel,
            pkgdatadir .. "/profiles/" .. doc_base,
            pkgdatadir .. "/" .. doc_base,
            "/usr/local/share/webveld/" .. doc_rel,
            "/usr/local/share/webveld/profiles/" .. doc_base,
            "/usr/share/webveld/" .. doc_rel,
            "/usr/share/webveld/profiles/" .. doc_base,
        }
        for _, cand in ipairs(candidates) do
            local f = io.open(cand, "r")
            if f then
                f:close()
                path = cand
                break
            end
        end
        if not path then
            local root = (arg and arg[0] or ""):gsub("tools/validator/[^/]+$", "")
            if root == "" then root = "./" end
            path = root .. doc_rel
        end
    end

    local f = io.open(path, "r")
    if not f then return end
    local doc = f:read("*a")
    f:close()

    local r1 = doc:match("### R1%. Elements(.-)### R2%.")
    if r1 then
        local named = {}
        for row in r1:gmatch("[^\r\n]+") do
            if row:match("^%s*|") then
                for el in row:gmatch("`([a-z][a-z0-9]*)`") do
                    named[el] = true
                end
            end
        end
        local named_keys = {}
        for k in pairs(named) do table.insert(named_keys, k) end
        table.sort(named_keys)
        for _, k in ipairs(named_keys) do
            if not el_set[k] then
                io.stderr:write(string.format("drift: webveld-%s R1 names <%s>, checker does not allow it\n", p_name, k))
            end
        end
        local el_keys = {}
        for k in pairs(el_set) do table.insert(el_keys, k) end
        table.sort(el_keys)
        for _, k in ipairs(el_keys) do
            if not named[k] then
                io.stderr:write(string.format("drift: checker allows <%s>, webveld-%s R1 does not name it\n", k, p_name))
            end
        end
    end

    if not prof.css then return end

    local known_value = {}
    for _, vals in pairs(val_map) do
        for _, v in ipairs(vals) do known_value[v] = true end
    end
    local r3 = doc:match("%*%*Properties%*%*(.-)%*%*Selectors%*%*")
    if r3 then
        for line in r3:gmatch("[^\r\n]+") do
            local group = line:match("^%-%s*%*%*[^*]+:%*%*(.*)$")
            if group then
                for p in group:gmatch("`([a-z][a-z%-]+)`") do
                    if not prop_set[p] and not known_value[p] then
                        io.stderr:write(string.format("drift: webveld-%s R3 names `%s`, checker does not allow it\n", p_name, p))
                    end
                end
            end
        end
    end
end

check_drift(name, profile, element, prop, values)

local function check_css(css)
    if not profile.css then
        return {"R3: author style sheets are excluded from this profile entirely"}
    end

    local bad = {}
    css = css:gsub("/%*.-%*/", "")
    if css:lower():match("!%s*important") then
        table.insert(bad, "6.1: !important is forbidden")
    end

    local at = {}
    for rule in css:gmatch("@([a-zA-Z%-]+)") do
        local r_l = rule:lower()
        if not at[r_l] then
            at[r_l] = true
            if r_l ~= "media" then
                table.insert(bad, string.format("R3: at-rule @%s is not in the profile", rule))
            end
        end
    end

    for cond in css:gmatch("@[mM][eE][dD][iI][aA]([^{]*){") do
        local c = cond:gsub("^%s+", ""):gsub("%s+$", "")
        local c_l = c:lower()
        if not c_l:match("^%(%s*prefers%-color%-scheme%s*:%s*light%s*%)$")
           and not c_l:match("^%(%s*prefers%-color%-scheme%s*:%s*dark%s*%)$") then
            table.insert(bad, string.format("R3: @media condition '%s' is not in the profile", c))
        end
    end

    local seen = {}
    for sel, body in css:gmatch("([^{}]+){([^{}]*)}") do
        local sel_clean = sel:gsub("^%s+", ""):gsub("%s+$", "")
        for s in (sel_clean .. ","):gmatch("([^,]+),") do
            local s_clean = s:gsub("^%s+", ""):gsub("%s+$", "")
            local bare = s_clean:gsub(":[fF][oO][cC][uU][sS]%f[%A]", "")
            if bare:match(":") and not seen["p:" .. s_clean] then
                seen["p:" .. s_clean] = true
                table.insert(bad, string.format("R3: pseudo-class or pseudo-element in '%s'", s_clean))
            end
            if s_clean:match("%[") and not seen["a:" .. s_clean] then
                seen["a:" .. s_clean] = true
                table.insert(bad, string.format("R3: attribute selector in '%s'", s_clean))
            end
            if s_clean:match("[%+~]") and not seen["s:" .. s_clean] then
                seen["s:" .. s_clean] = true
                table.insert(bad, string.format("R3: sibling combinator in '%s'", s_clean))
            end
        end

        for decl in (body .. ";"):gmatch("([^;]+);") do
            local p_str, v_str = decl:match("^%s*([a-zA-Z%-]+)%s*:%s*(.-)%s*$")
            if p_str then
                local p = p_str:lower()
                local v = v_str
                if not prop[p] then
                    if not seen["d:" .. p] then
                        seen["d:" .. p] = true
                        table.insert(bad, string.format("R3: property %s is not in the profile", p))
                    end
                else
                    local allowed = values[p]
                    if allowed then
                        local v_clean = v:gsub("^%s+", ""):gsub("%s+$", ""):lower()
                        local is_ok = false
                        for _, a_val in ipairs(allowed) do
                            if v_clean == a_val:lower() then
                                is_ok = true
                                break
                            end
                        end
                        if not is_ok and not seen["v:" .. p .. ":" .. v] then
                            seen["v:" .. p .. ":" .. v] = true
                            table.insert(bad, string.format("R3: %s: %s is not in the profile (only %s)", p, v:gsub("^%s+", ""):gsub("%s+$", ""), table.concat(allowed, ", ")))
                        end
                    end
                end
            end
        end
    end

    return bad
end

local function check_html(doc)
    local bad = {}
    local seen = {}

    -- Strip comments first
    local clean_doc = doc:gsub("<!%-%-.-%-%->", "")

    for el_raw, rest in clean_doc:gmatch("<([a-zA-Z][a-zA-Z0-9]*)([^>]*)>") do
        local el = el_raw:lower()
        if not element[el] then
            if not seen["el:" .. el] then
                seen["el:" .. el] = true
                table.insert(bad, string.format("R1: element <%s> is not in the profile", el))
            end
        end

        -- Parse attributes from rest
        local a_pos = 1
        local rest_len = #rest
        while a_pos <= rest_len do
            local s_idx, e_idx, a_name = rest:find("([a-zA-Z][a-zA-Z0-9%-]*)", a_pos)
            if not s_idx then break end
            local after = e_idx + 1
            local eq_s, eq_e = rest:find("^%s*=%s*", after)
            if eq_e then
                after = eq_e + 1
                local q = rest:sub(after, after)
                if q == '"' or q == "'" then
                    local q_end = rest:find(q, after + 1, true)
                    after = q_end and (q_end + 1) or (rest_len + 1)
                else
                    local u_end = rest:find("[%s>]", after)
                    after = u_end and u_end or (rest_len + 1)
                end
            end
            a_pos = after

            local a = a_name:lower()
            local allowed = global[a]
            if not allowed and profile.attr[el] then
                for _, att in ipairs(profile.attr[el]) do
                    if att:lower() == a then
                        allowed = true
                        break
                    end
                end
            end
            if not allowed then
                local k = "at:" .. el .. ":" .. a
                if not seen[k] then
                    seen[k] = true
                    table.insert(bad, string.format("R2: attribute %s on <%s> is not in the profile", a, el))
                end
            end
        end

        if el == "link" and element["link"] then
            local rel = rest:match("%f[%a][rR][eE][lL]%s*=%s*[\"']?([a-zA-Z%-]+)")
            if rel then
                local rel_l = rel:lower()
                if rel_l ~= "stylesheet" and rel_l ~= "icon" and rel_l ~= "alternate" then
                    table.insert(bad, string.format("R2: <link rel=\"%s\"> is not in the profile", rel))
                end
            end
        end

        -- pico R2: meta name is admitted only as the standard viewport declaration
        if el == "meta" and name == "pico" then
            local m_name = rest:match("%f[%w%-][nN][aA][mM][eE]%s*=%s*[\"']?([^\"'%s>]+)")
            if m_name then
                local content = rest:match("%f[%w%-][cC][oO][nN][tT][eE][nN][tT]%s*=%s*\"([^\"]*)\"")
                    or rest:match("%f[%w%-][cC][oO][nN][tT][eE][nN][tT]%s*=%s*'([^']*)'") or ""
                local normalized = content:lower():gsub("%s+", "")
                if m_name:lower() ~= "viewport" then
                    table.insert(bad, string.format("R2: <meta name=\"%s\"> is not in the profile (only viewport)", m_name))
                elseif normalized ~= "width=device-width,initial-scale=1" then
                    table.insert(bad, "R2: meta viewport content must be exactly width=device-width, initial-scale=1")
                end
            end
        end
    end

    if clean_doc:lower():match("<[^>]*%sstyle%s*=") then
        table.insert(bad, "R3: inline style attribute")
    end

    for style_blk in clean_doc:gmatch("<[sS][tT][yY][lL][eE][^>]*>(.-)</[sS][tT][yY][lL][eE]%s*>") do
        local css_bads = check_css(style_blk)
        for _, b in ipairs(css_bads) do
            table.insert(bad, b)
        end
    end

    return bad
end

local failed = 0
for _, file in ipairs(files) do
    local f = io.open(file, "r")
    if not f then
        io.stderr:write("cannot read " .. file .. "\n")
        os.exit(1)
    end
    local doc = f:read("*a")
    f:close()

    local bad
    if file:lower():match("%.css$") then
        bad = check_css(doc)
    else
        bad = check_html(doc)
    end

    if #bad > 0 then
        failed = failed + 1
        io.write(file .. ":\n")
        for _, b in ipairs(bad) do
            io.write("  " .. b .. "\n")
        end
    else
        io.write(string.format("%s: conforms to webveld-%s\n", file, name))
    end
end

os.exit(failed > 0 and 1 or 0)
