#!/usr/bin/env lua
-- =============================================================================
-- Compare Blitz and Chromium on WebVeld rule 1 (parity)
-- Spec section 3.1: "equivalence of content, not identity of pixels"
-- Compares:
--   CONTENT:   Reader-visible text of whole document as an ordered token sequence
--   STRUCTURE: Sequence of elements each engine produced a box for
--   GEOMETRY:  Each element's box within tolerance
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Minimal JSON encoder / decoder
-- -----------------------------------------------------------------------------
local json = {}

local function escape_json_str(s)
  local rep = {
    ["\\"] = "\\\\", ["\""] = "\\\"", ["\b"] = "\\b",
    ["\f"] = "\\f", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t"
  }
  return "\"" .. s:gsub("[\\\"\b\f\n\r\t]", rep) .. "\""
end

function json.encode(val, indent, depth)
  indent = indent or 0
  depth = depth or 0
  local pad = string.rep("  ", depth)
  local pad_next = string.rep("  ", depth + 1)
  local nl = (indent > 0) and "\n" or ""
  local sp = (indent > 0) and " " or ""

  if val == nil then
    return "null"
  elseif type(val) == "boolean" then
    return val and "true" or "false"
  elseif type(val) == "number" then
    if val ~= val or val == math.huge or val == -math.huge then return "null" end
    if math.floor(val) == val then return string.format("%d", val) end
    return tostring(val)
  elseif type(val) == "string" then
    return escape_json_str(val)
  elseif type(val) == "table" then
    if val.__is_array then
      if #val == 0 then return "[]" end
      local parts = {}
      for i = 1, #val do
        table.insert(parts, pad_next .. json.encode(val[i], indent, depth + 1))
      end
      return "[" .. nl .. table.concat(parts, "," .. nl) .. nl .. pad .. "]"
    elseif val.__is_object then
      local keys = {}
      for k in pairs(val) do
        if k ~= "__is_object" and k ~= "__is_array" then table.insert(keys, tostring(k)) end
      end
      if #keys == 0 then return "{}" end
      table.sort(keys)
      local parts = {}
      for _, k in ipairs(keys) do
        local v_encoded = json.encode(val[k], indent, depth + 1)
        table.insert(parts, pad_next .. escape_json_str(k) .. ":" .. sp .. v_encoded)
      end
      return "{" .. nl .. table.concat(parts, "," .. nl) .. nl .. pad .. "}"
    end

    local is_arr = true
    local max_idx = 0
    local count = 0
    for k in pairs(val) do
      count = count + 1
      if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
        is_arr = false
        break
      end
      if k > max_idx then max_idx = k end
    end
    if is_arr and max_idx ~= count then is_arr = false end

    if is_arr then
      if count == 0 then return "[]" end
      local parts = {}
      for i = 1, max_idx do
        table.insert(parts, pad_next .. json.encode(val[i], indent, depth + 1))
      end
      return "[" .. nl .. table.concat(parts, "," .. nl) .. nl .. pad .. "]"
    else
      if count == 0 then return "{}" end
      local keys = {}
      for k in pairs(val) do table.insert(keys, tostring(k)) end
      table.sort(keys)
      local parts = {}
      for _, k in ipairs(keys) do
        local v_encoded = json.encode(val[k], indent, depth + 1)
        table.insert(parts, pad_next .. escape_json_str(k) .. ":" .. sp .. v_encoded)
      end
      return "{" .. nl .. table.concat(parts, "," .. nl) .. nl .. pad .. "}"
    end
  end
  return "null"
end

local function skip_ws(str, pos)
  return str:match("^%s*()", pos)
end

function json.decode(str)
  local pos = 1
  local function parse_val()
    pos = skip_ws(str, pos)
    local c = str:sub(pos, pos)
    if c == "{" then
      pos = pos + 1
      local obj = {}
      pos = skip_ws(str, pos)
      if str:sub(pos, pos) == "}" then pos = pos + 1; return obj end
      while true do
        pos = skip_ws(str, pos)
        if str:sub(pos, pos) ~= "\"" then error("expected string key at position " .. pos) end
        local key = parse_val()
        pos = skip_ws(str, pos)
        if str:sub(pos, pos) ~= ":" then error("expected colon at position " .. pos) end
        pos = pos + 1
        local val = parse_val()
        obj[key] = val
        pos = skip_ws(str, pos)
        local sep = str:sub(pos, pos)
        if sep == "}" then pos = pos + 1; break
        elseif sep == "," then pos = pos + 1
        else error("expected , or } at position " .. pos) end
      end
      return obj
    elseif c == "[" then
      pos = pos + 1
      local arr = {}
      pos = skip_ws(str, pos)
      if str:sub(pos, pos) == "]" then pos = pos + 1; return arr end
      while true do
        local val = parse_val()
        table.insert(arr, val)
        pos = skip_ws(str, pos)
        local sep = str:sub(pos, pos)
        if sep == "]" then pos = pos + 1; break
        elseif sep == "," then pos = pos + 1
        else error("expected , or ] at position " .. pos) end
      end
      return arr
    elseif c == "\"" then
      pos = pos + 1
      local chars = {}
      while pos <= #str do
        local b = str:sub(pos, pos)
        if b == "\"" then
          pos = pos + 1
          return table.concat(chars)
        elseif b == "\\" then
          pos = pos + 1
          local esc = str:sub(pos, pos)
          if esc == "\"" or esc == "\\" or esc == "/" then table.insert(chars, esc)
          elseif esc == "b" then table.insert(chars, "\b")
          elseif esc == "f" then table.insert(chars, "\f")
          elseif esc == "n" then table.insert(chars, "\n")
          elseif esc == "r" then table.insert(chars, "\r")
          elseif esc == "t" then table.insert(chars, "\t")
          elseif esc == "u" then
            local hex = str:sub(pos+1, pos+4)
            pos = pos + 4
            local code = tonumber(hex, 16)
            if code then table.insert(chars, utf8.char(code)) end
          end
          pos = pos + 1
        else
          local chunk = str:match("^[^\"\\]+", pos)
          table.insert(chars, chunk)
          pos = pos + #chunk
        end
      end
      error("unterminated string at position " .. pos)
    elseif str:sub(pos, pos + 3) == "true" then
      pos = pos + 4
      return true
    elseif str:sub(pos, pos + 4) == "false" then
      pos = pos + 5
      return false
    elseif str:sub(pos, pos + 3) == "null" then
      pos = pos + 4
      return nil
    else
      local num_str = str:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
      if num_str and #num_str > 0 then
        pos = pos + #num_str
        return tonumber(num_str)
      end
      error("unexpected char: " .. c .. " at position " .. pos)
    end
  end
  return parse_val()
end

-- -----------------------------------------------------------------------------
-- Path and Process Helpers
-- -----------------------------------------------------------------------------
local function resolve_path(p)
  local h = io.popen("realpath " .. string.format("%q", p) .. " 2>/dev/null")
  if h then
    local res = h:read("*l")
    h:close()
    if res and #res > 0 then return res end
  end
  return p
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close(); return true end
  return false
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local c = f:read("*a")
  f:close()
  return c
end

local function get_script_dir()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*)/[^/]+$") or "."
end

local SCRIPT_DIR = resolve_path(get_script_dir())
local ROOT = resolve_path(SCRIPT_DIR .. "/../..")
local BLITZ_BIN = os.getenv("BLITZ_BIN")
  or (os.getenv("BLITZ_ROOT") and resolve_path(os.getenv("BLITZ_ROOT") .. "/target/release/examples/conformance_render"))
  or resolve_path(ROOT .. "/../blitz/target/release/examples/conformance_render")

-- Elements that never carry reader-visible content, so their geometry is noise.
local SKIP = {
  html = true, head = true, meta = true, title = true,
  style = true, link = true, script = true, base = true
}

-- Elements the two engines legitimately model differently.
local NO_BOX = {
  a = true, strong = true, em = true, i = true, b = true, u = true,
  code = true, kbd = true, samp = true, var = true, abbr = true, cite = true,
  q = true, mark = true, small = true, sub = true, sup = true, del = true,
  ins = true, dfn = true, time = true, br = true, wbr = true, span = true,
  tbody = true, thead = true, tfoot = true, tr = true, col = true, colgroup = true
}

-- Injected JavaScript probe to extract layout boxes and visible text from Chromium.
local PROBE = [=[
<script>
(function () {
  var out = [];
  document.querySelectorAll('*').forEach(function (el) {
    if (el.id === '__webveld_dump') return;
    var t = '';
    for (var i = 0; i < el.childNodes.length; i++) {
      var n = el.childNodes[i];
      if (n.nodeType === 3) t += ' ' + n.nodeValue;
    }
    var r = el.getBoundingClientRect();
    out.push({
      kind: 'element',
      name: el.tagName.toLowerCase(),
      x: Math.round(r.left * 10) / 10, y: Math.round(r.top * 10) / 10,
      w: Math.round(r.width * 10) / 10, h: Math.round(r.height * 10) / 10,
      text: t.replace(/\s+/g, ' ').trim()
    });
  });
  var INLINE = {a:1,strong:1,em:1,i:1,b:1,u:1,code:1,kbd:1,samp:1,var:1,abbr:1,cite:1,
                q:1,mark:1,small:1,sub:1,sup:1,del:1,ins:1,dfn:1,time:1,br:1,wbr:1,span:1};
  var SKIPTAG = {head:1,script:1,style:1,title:1,meta:1,link:1,noscript:1};
  var parts = [];
  (function walk(n) {
    if (n.nodeType === 3) { parts.push(n.nodeValue); return; }
    if (n.nodeType !== 1) return;
    var tag = n.tagName.toLowerCase();
    if (SKIPTAG[tag] || n.id === '__webveld_dump') return;
    if (n.checkVisibility && !n.checkVisibility({checkVisibilityCSS: true,
                                                 contentVisibilityAuto: true})) return;
    if (getComputedStyle(n).display === 'none') return;
    if (tag === 'select') return;
    if (!INLINE[tag]) parts.push(' ');
    if (tag === 'textarea' || (tag === 'input' && /^(submit|reset|button)$/.test(n.type))) {
      parts.push(' ' + (n.value || '') + ' ');
      return;
    }
    for (var i = 0; i < n.childNodes.length; i++) walk(n.childNodes[i]);
  })(document.body);
  var body = parts.join('').replace(/\s+/g, ' ').trim();
  var p = document.createElement('pre');
  p.id = '__webveld_dump';
  p.textContent = JSON.stringify({ text: body, boxes: out });
  document.body.appendChild(p);
})();
</script>
]=]

local function chromium_dump(html_path, width, height)
  local src = read_file(html_path)
  if not src then error("Could not read " .. html_path) end

  local injected
  if src:find("</body>") then
    injected = src:gsub("</body>", PROBE .. "</body>", 1)
  else
    injected = src .. PROBE
  end

  local tmp_path = string.format("/tmp/webveld_dump_%d_%d.html", os.time(), math.random(10000, 99999))
  local f = io.open(tmp_path, "w")
  if not f then error("Could not create temp file " .. tmp_path) end
  f:write(injected)
  f:close()

  local cmd = string.format("chromium --headless --disable-gpu --no-sandbox --window-size=%d,%d --virtual-time-budget=3000 --dump-dom %q 2>/dev/null",
                            width, height, "file://" .. tmp_path)
  local p = io.popen(cmd)
  local stdout = p:read("*a") or ""
  p:close()
  os.remove(tmp_path)

  local raw = stdout:match('<pre id="__webveld_dump">(.-)</pre>')
  if not raw then
    error("Chromium produced no dump (is the probe reaching the page?)")
  end

  raw = raw:gsub("&quot;", "\""):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
  return json.decode(raw)
end

local function blitz_dump(html_path, width, height)
  if not file_exists(BLITZ_BIN) then
    error(string.format("Blitz conformance_render binary not found at %s. Set BLITZ_BIN=/path/to/conformance_render or BLITZ_ROOT=/path/to/blitz (see tools/render-diff/blitz-example/README.md)", BLITZ_BIN))
  end

  local out_path = string.format("/tmp/webveld_blitz_%d_%d.json", os.time(), math.random(10000, 99999))
  local cmd = string.format("%q %q %q %d %d 1.0 >/dev/null 2>&1",
                            BLITZ_BIN, resolve_path(html_path), out_path, width, height)
  local ok = os.execute(cmd)
  if not ok or not file_exists(out_path) then
    if file_exists(out_path) then os.remove(out_path) end
    error(string.format("Blitz failed to dump layout for %s", html_path))
  end

  local raw = read_file(out_path)
  os.remove(out_path)
  if not raw then error("Could not read Blitz dump") end
  return json.decode(raw)
end

local function visible(records)
  local out = {}
  for _, r in ipairs(records) do
    if not SKIP[r.name] then table.insert(out, r) end
  end
  return out
end

-- -----------------------------------------------------------------------------
-- Sequence Matcher (LCS-based token diffing matching Python difflib)
-- -----------------------------------------------------------------------------
local function split_words(str)
  local words = {}
  for w in str:gmatch("%S+") do table.insert(words, w) end
  return words
end

local function get_opcodes(a, b)
  local m, n = #a, #b
  local dp = {}
  for i = 0, m do
    dp[i] = {}
    for j = 0, n do dp[i][j] = 0 end
  end
  for i = 1, m do
    for j = 1, n do
      if a[i] == b[j] then
        dp[i][j] = dp[i-1][j-1] + 1
      else
        dp[i][j] = math.max(dp[i-1][j], dp[i][j-1])
      end
    end
  end

  local raw = {}
  local i, j = m, n
  while i > 0 or j > 0 do
    if i > 0 and j > 0 and a[i] == b[j] then
      table.insert(raw, {"equal", i, j})
      i = i - 1; j = j - 1
    elseif j > 0 and (i == 0 or dp[i][j-1] >= dp[i-1][j]) then
      table.insert(raw, {"insert", i, j})
      j = j - 1
    elseif i > 0 and (j == 0 or dp[i][j-1] < dp[i-1][j]) then
      table.insert(raw, {"delete", i, j})
      i = i - 1
    end
  end

  local fwd = {}
  for k = #raw, 1, -1 do
    table.insert(fwd, raw[k])
  end

  local ops = {}
  local ai, bj = 0, 0
  local k = 1
  while k <= #fwd do
    local tag = fwd[k][1]
    if tag == "equal" then
      local start_a, start_b = ai, bj
      while k <= #fwd and fwd[k][1] == "equal" do
        ai = ai + 1; bj = bj + 1; k = k + 1
      end
      table.insert(ops, {"equal", start_a, ai, start_b, bj})
    else
      local start_a, start_b = ai, bj
      local has_del, has_ins = false, false
      while k <= #fwd and fwd[k][1] ~= "equal" do
        if fwd[k][1] == "delete" then ai = ai + 1; has_del = true
        else bj = bj + 1; has_ins = true end
        k = k + 1
      end
      local optype = (has_del and has_ins) and "replace" or (has_del and "delete" or "insert")
      table.insert(ops, {optype, start_a, ai, start_b, bj})
    end
  end
  return ops
end

local function repr70(s)
  local sub = s:sub(1, 70)
  local escaped = sub:gsub("\\", "\\\\"):gsub("'", "\\'")
  return "'" .. escaped .. "'"
end

local function compare_content(text_a, text_b)
  local ta = split_words(text_a)
  local tb = split_words(text_b)

  if #ta == #tb then
    local same = true
    for idx = 1, #ta do
      if ta[idx] ~= tb[idx] then same = false; break end
    end
    if same then return true, {} end
  end

  local problems = {}
  local ops = get_opcodes(ta, tb)
  for _, o in ipairs(ops) do
    local op, i1, i2, j1, j2 = o[1], o[2], o[3], o[4], o[5]
    if op ~= "equal" then
      local chr_slice = table.concat(ta, " ", i1 + 1, i2)
      local bl_slice = table.concat(tb, " ", j1 + 1, j2)
      local chr_side = (chr_slice ~= "") and chr_slice or "(nothing)"
      local bl_side = (bl_slice ~= "") and bl_slice or "(nothing)"
      local verb = (op == "delete") and "MISSING from blitz" or ((op == "insert") and "EXTRA in blitz" or "ALTERED")
      table.insert(problems, string.format("    %s: chromium=%s blitz=%s", verb, repr70(chr_side), repr70(bl_side)))
      if #problems >= 6 then
        table.insert(problems, "    … further differences suppressed")
        break
      end
    end
  end
  return false, problems
end

local function compare_structure(a, b)
  local ca, cb = {}, {}
  for _, r in ipairs(a) do
    if not NO_BOX[r.name] then ca[r.name] = (ca[r.name] or 0) + 1 end
  end
  for _, r in ipairs(b) do
    if not NO_BOX[r.name] then cb[r.name] = (cb[r.name] or 0) + 1 end
  end

  local missing = { __is_object = true }
  for k, count_a in pairs(ca) do
    local count_b = cb[k] or 0
    if count_a > count_b then missing[k] = count_a - count_b end
  end

  local extra = { __is_object = true }
  for k, count_b in pairs(cb) do
    local count_a = ca[k] or 0
    if count_b > count_a then extra[k] = count_b - count_a end
  end

  return missing, extra
end

local function compare_geometry(a, b, tol_px, tol_pct)
  local n = math.min(#a, #b)
  local within = 0
  local worst = {}

  for i = 1, n do
    local ai, bi = a[i], b[i]
    if ai.name == bi.name then
      local deltas = {}
      local all_ok = true
      local max_not_ok = 0
      for _, k in ipairs({"x", "y", "w", "h"}) do
        local val_a = ai[k] or 0
        local val_b = bi[k] or 0
        local d = math.abs(val_a - val_b)
        local allowed = math.max(tol_px, math.abs(val_a) * tol_pct)
        local ok = (d <= allowed)
        if not ok then
          all_ok = false
          if d > max_not_ok then max_not_ok = d end
        end
        table.insert(deltas, { k = k, d = d, ok = ok })
      end

      if all_ok then
        within = within + 1
      else
        local off_parts = {}
        for _, delta in ipairs(deltas) do
          if not delta.ok then
            table.insert(off_parts, string.format("%sΔ%.0f", delta.k, delta.d))
          end
        end
        table.insert(worst, {
          max_d = max_not_ok,
          name = ai.name,
          idx = i - 1,
          off = table.concat(off_parts, ", ")
        })
      end
    end
  end

  table.sort(worst, function(x, y)
    if x.max_d ~= y.max_d then return x.max_d > y.max_d end
    if x.name ~= y.name then return x.name < y.name end
    return x.idx < y.idx
  end)

  local worst5 = {}
  for idx = 1, math.min(5, #worst) do
    table.insert(worst5, worst[idx])
  end
  return within, n, worst5
end

-- -----------------------------------------------------------------------------
-- CLI Entry Point
-- -----------------------------------------------------------------------------
local function main()
  local files = {}
  local width = 800
  local height = 1000
  local tol_px = 10.0
  local tol_pct = 0.05
  local json_out = nil

  local i = 1
  while i <= #arg do
    local a = arg[i]
    if a == "--width" then
      i = i + 1
      width = tonumber(arg[i]) or 800
    elseif a:match("^%-%-width=(%d+)$") then
      width = tonumber(a:match("^%-%-width=(%d+)$")) or 800
    elseif a == "--height" then
      i = i + 1
      height = tonumber(arg[i]) or 1000
    elseif a:match("^%-%-height=(%d+)$") then
      height = tonumber(a:match("^%-%-height=(%d+)$")) or 1000
    elseif a == "--tol-px" then
      i = i + 1
      tol_px = tonumber(arg[i]) or 10.0
    elseif a:match("^%-%-tol%-px=(.*)$") then
      tol_px = tonumber(a:match("^%-%-tol%-px=(.*)$")) or 10.0
    elseif a == "--tol-pct" then
      i = i + 1
      tol_pct = tonumber(arg[i]) or 0.05
    elseif a:match("^%-%-tol%-pct=(.*)$") then
      tol_pct = tonumber(a:match("^%-%-tol%-pct=(.*)$")) or 0.05
    elseif a == "--json" then
      i = i + 1
      json_out = arg[i]
    elseif a:match("^%-%-json=(.*)$") then
      json_out = a:match("^%-%-json=(.*)$")
    elseif a == "-h" or a == "--help" then
      print("Usage: lua compare_content.lua [options] file1.html [file2.html ...]")
      print("Options:")
      print("  --width N       Viewport width (default: 800)")
      print("  --height N      Viewport height (default: 1000)")
      print("  --tol-px N      Absolute box tolerance in px (default: 10)")
      print("  --tol-pct N     Relative box tolerance (default: 0.05)")
      print("  --json PATH     Write machine-readable results to JSON file")
      os.exit(0)
    elseif not a:match("^%-%-") then
      table.insert(files, a)
    end
    i = i + 1
  end

  if #files == 0 then
    io.stderr:write("Error: no input files provided\n")
    os.exit(2)
  end

  local results = { __is_array = true }
  local failures = 0

  for _, path in ipairs(files) do
    print(string.format("\n%s", path))
    local chr_d, bl_d
    local ok_chr, err_chr = pcall(function() return chromium_dump(path, width, height) end)
    local ok_bl, err_bl = pcall(function() return blitz_dump(path, width, height) end)

    if not ok_chr or not ok_bl then
      print(string.format("  ERROR %s", tostring(not ok_chr and err_chr or err_bl)))
      failures = failures + 1
    else
      chr_d = err_chr
      bl_d = err_bl
      local chr_r = visible(chr_d.boxes)
      local bl_r = visible(bl_d.boxes)

      local ok, problems = compare_content(chr_d.text, bl_d.text)
      local missing, extra = compare_structure(chr_r, bl_r)
      local within, n, worst = compare_geometry(chr_r, bl_r, tol_px, tol_pct)
      local pct = (n > 0) and (100.0 * within / n) or 0.0

      local n_words_chr = #split_words(chr_d.text)
      local n_words_bl = #split_words(bl_d.text)
      print(string.format("  content   %s   (%d words in chromium, %d in blitz)",
                          ok and "MATCH" or "DIFFERS", n_words_chr, n_words_bl))
      for _, p in ipairs(problems) do print(p) end

      local missing_keys = {}
      for k in pairs(missing) do
        if k ~= "__is_object" and k ~= "__is_array" then table.insert(missing_keys, k) end
      end
      table.sort(missing_keys)

      local extra_keys = {}
      for k in pairs(extra) do
        if k ~= "__is_object" and k ~= "__is_array" then table.insert(extra_keys, k) end
      end
      table.sort(extra_keys)

      local has_missing = (#missing_keys > 0)
      local has_extra = (#extra_keys > 0)

      if has_missing or has_extra then
        local bits = {}
        if has_missing then
          local missing_parts = {}
          for _, k in ipairs(missing_keys) do
            table.insert(missing_parts, string.format("<%s>x%d", k, missing[k]))
          end
          table.insert(bits, "dropped by blitz: " .. table.concat(missing_parts, ", "))
        end
        if has_extra then
          local extra_parts = {}
          for _, k in ipairs(extra_keys) do
            table.insert(extra_parts, string.format("<%s>x%d", k, extra[k]))
          end
          table.insert(bits, "only in blitz: " .. table.concat(extra_parts, ", "))
        end
        print(string.format("  structure DIFFERS   %s", table.concat(bits, "; ")))
      else
        print(string.format("  structure MATCH     (%d boxes)", #chr_r))
      end

      print(string.format("  geometry  %d/%d boxes within ±%.0fpx or %.0f%%  (%.0f%%)",
                          within, n, tol_px, tol_pct * 100, pct))
      for _, w in ipairs(worst) do
        print(string.format("    <%s> #%d: %s", w.name, w.idx, w.off))
      end

      if not ok or has_missing then
        failures = failures + 1
      end

      table.insert(results, {
        file = tostring(path),
        content_match = ok,
        structure_dropped = missing,
        structure_extra = extra,
        geometry_within = within,
        geometry_total = n,
        geometry_percent = math.floor(pct * 10 + 0.5) / 10
      })
    end
  end

  if json_out then
    local f = io.open(json_out, "w")
    if f then
      f:write(json.encode(results, 2) .. "\n")
      f:close()
    else
      io.stderr:write(string.format("Warning: could not write JSON to %s\n", json_out))
    end
  end

  print(string.format("\n%d compared, %d with content or structure differences", #results, failures))
  os.exit(failures > 0 and 1 or 0)
end

main()
