#!/usr/bin/env lua
-- =============================================================================
-- WebVeld Render Conformance Diff Runner: Blitz vs Chromium vs Firefox
-- Calibrates Blitz's rendering parity against Chromium by establishing
-- the Firefox vs Chromium inter-engine reference noise floor across:
-- 1. conformance/*.html (spec conformance suite)
-- 2. tools/validator/tests/valid/*.html (valid test fixtures)
-- 3. tools/render-diff/fixtures/*.html (targeted feature gap fixtures)
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
-- System and Path Helpers
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

local function round2(num)
  return math.floor(num * 100 + 0.5) / 100
end

local function run_cmd(cmd)
  local handle = io.popen(cmd .. " 2>&1")
  local output = handle:read("*a") or ""
  local success, _, code = handle:close()
  return success, output, code
end

local function get_script_dir()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*)/[^/]+$") or "."
end

local SCRIPT_DIR = resolve_path(get_script_dir())
local WORKSPACE_ROOT = resolve_path(SCRIPT_DIR .. "/../..")
local BLITZ_BIN = os.getenv("BLITZ_BIN")
  or (os.getenv("BLITZ_ROOT") and resolve_path(os.getenv("BLITZ_ROOT") .. "/target/release/examples/conformance_render"))
  or resolve_path(WORKSPACE_ROOT .. "/../blitz/target/release/examples/conformance_render")
local DEFAULT_OUT_DIR = WORKSPACE_ROOT .. "/tools/render-diff/output"

local DEFAULT_WIDTH = 800
local DEFAULT_HEIGHT = 1000
local SCALE = 1.0

-- -----------------------------------------------------------------------------
-- Renderers
-- -----------------------------------------------------------------------------
local function render_chromium(html_path, out_png, width, height)
  local file_url = "file://" .. resolve_path(html_path)
  local cmd = string.format("chromium --headless=new --no-sandbox --screenshot=%q --window-size=%d,%d %q",
                            out_png, width, height, file_url)
  local ok, out = run_cmd(cmd)
  if not file_exists(out_png) then
    error(string.format("Chromium failed to generate screenshot: %s", out))
  end
end

local function render_firefox(html_path, out_png, width, height)
  local file_url = "file://" .. resolve_path(html_path)
  local cmd = string.format("firefox --headless --screenshot %q --window-size %d,%d %q",
                            out_png, width, height, file_url)
  local ok, out = run_cmd(cmd)
  if not file_exists(out_png) then
    error(string.format("Firefox failed to generate screenshot: %s", out))
  end
end

local function render_blitz(html_path, out_png, width, height, scale)
  if not file_exists(BLITZ_BIN) then
    error(string.format("Blitz conformance_render binary not found at %s. Set BLITZ_BIN=/path/to/conformance_render or BLITZ_ROOT=/path/to/blitz (see tools/render-diff/blitz-example/README.md)", BLITZ_BIN))
  end
  local cmd = string.format("%q %q %q %d %d %.1f",
                            BLITZ_BIN, resolve_path(html_path), out_png, width, height, scale or SCALE)
  local ok, out = run_cmd(cmd)
  if not ok or not file_exists(out_png) then
    error(string.format("Blitz failed to render %s: %s", html_path, out))
  end
end

local function compare_images(ref_png, test_png, diff_png, width, height)
  if not file_exists(ref_png) or not file_exists(test_png) then
    return nil
  end

  -- 1. AE with 5% fuzz
  local cmd_ae = string.format("compare -metric AE -fuzz 5%% %q %q %q", ref_png, test_png, diff_png)
  local _, output_ae = run_cmd(cmd_ae)
  local ae_str = output_ae:match("^(%S+)")
  local ae_pixels = ae_str and tonumber(ae_str) or -1.0

  -- 2. RMSE
  local cmd_rmse = string.format("compare -metric RMSE %q %q null:", ref_png, test_png)
  local _, output_rmse = run_cmd(cmd_rmse)
  local rmse_norm = -1.0
  local norm_str = output_rmse:match("%(([^%)]+)%)")
  if norm_str and tonumber(norm_str) then
    rmse_norm = round2(tonumber(norm_str) * 100.0)
  end

  local total_pixels = width * height
  local diff_percent = (ae_pixels >= 0) and (ae_pixels / total_pixels * 100.0) or 100.0

  return {
    ae_pixels = (ae_pixels >= 0) and math.floor(ae_pixels) or -1,
    total_pixels = total_pixels,
    diff_percent = round2(diff_percent),
    rmse_percent = rmse_norm
  }
end

-- -----------------------------------------------------------------------------
-- Suite Runner
-- -----------------------------------------------------------------------------
local function glob_files(pattern)
  local files = {}
  local p = io.popen("ls -1 " .. pattern .. " 2>/dev/null")
  if p then
    for line in p:lines() do
      local trimmed = line:match("^%s*(.-)%s*$")
      if trimmed ~= "" then table.insert(files, trimmed) end
    end
    p:close()
  end
  table.sort(files)
  return files
end

local function run_suite(fixtures, out_dir, width, height, enable_firefox, enable_blitz)
  os.execute("mkdir -p " .. string.format("%q", out_dir))
  local results = {}

  for _, html_path in ipairs(fixtures) do
    local filename = html_path:match("([^/]+)$")
    local rel_name = filename:match("^(.*)%.[^.]+$") or filename
    local parent_dir = html_path:match("^(.*)/[^/]+$") or ""
    local category = parent_dir:match("([^/]+)$") or ""
    local test_id = category .. "_" .. rel_name

    local chr_png = out_dir .. "/" .. test_id .. "_chromium.png"
    local ff_png = out_dir .. "/" .. test_id .. "_firefox.png"
    local blitz_png = out_dir .. "/" .. test_id .. "_blitz.png"

    local diff_blitz_chr = out_dir .. "/" .. test_id .. "_diff_blitz_chr.png"
    local diff_ff_chr = out_dir .. "/" .. test_id .. "_diff_ff_chr.png"

    io.write(string.format("Testing %s/%s (%dx%d) ... ", category, filename, width, height))
    io.flush()

    local chr_err, ff_err, blitz_err = nil, nil, nil

    local ok_chr, err_chr = pcall(render_chromium, html_path, chr_png, width, height)
    if not ok_chr then chr_err = tostring(err_chr) end

    if enable_firefox then
      local ok_ff, err_ff = pcall(render_firefox, html_path, ff_png, width, height)
      if not ok_ff then ff_err = tostring(err_ff) end
    end

    if enable_blitz then
      local ok_bl, err_bl = pcall(render_blitz, html_path, blitz_png, width, height)
      if not ok_bl then blitz_err = tostring(err_bl) end
    end

    local m_blitz_chr = nil
    if enable_blitz and not chr_err and not blitz_err then
      m_blitz_chr = compare_images(chr_png, blitz_png, diff_blitz_chr, width, height)
    end

    local m_ff_chr = nil
    if enable_firefox and not chr_err and not ff_err then
      m_ff_chr = compare_images(chr_png, ff_png, diff_ff_chr, width, height)
    end

    local info = {}
    if m_ff_chr then
      table.insert(info, string.format("FF noise floor: %s%% (%s px)", m_ff_chr.diff_percent, m_ff_chr.ae_pixels))
    end
    if m_blitz_chr then
      table.insert(info, string.format("Blitz diff: %s%% (%s px)", m_blitz_chr.diff_percent, m_blitz_chr.ae_pixels))
    end

    if #info > 0 then
      print(string.format("[OK] %s", table.concat(info, ", ")))
    else
      print(string.format("[FAIL] chr: %s, ff: %s, blitz: %s", tostring(chr_err), tostring(ff_err), tostring(blitz_err)))
    end

    table.insert(results, {
      category = category,
      filename = filename,
      path = category .. "/" .. filename,
      errors = { chromium = chr_err, firefox = ff_err, blitz = blitz_err },
      metrics = {
        blitz_vs_chr = m_blitz_chr,
        ff_vs_chr = m_ff_chr
      }
    })
  end

  return results
end

-- -----------------------------------------------------------------------------
-- Statistical Analysis & Calibration Reporting
-- -----------------------------------------------------------------------------
local function compute_distribution(vals)
  if not vals or #vals == 0 then return nil end
  local t = {}
  for i, v in ipairs(vals) do t[i] = v end
  table.sort(t)
  local count = #t
  local min_v = t[1]
  local max_v = t[count]
  local sum = 0
  for _, v in ipairs(t) do sum = sum + v end
  local mean_v = sum / count
  local median_v
  if count % 2 == 1 then
    median_v = t[math.ceil(count / 2)]
  else
    local m = count / 2
    median_v = (t[m] + t[m + 1]) / 2
  end
  local stdev_v = 0.0
  if count > 1 then
    local var_sum = 0
    for _, v in ipairs(t) do
      var_sum = var_sum + (v - mean_v)^2
    end
    stdev_v = math.sqrt(var_sum / (count - 1))
  end
  return {
    count = count,
    min = round2(min_v),
    max = round2(max_v),
    mean = round2(mean_v),
    median = round2(median_v),
    stdev = round2(stdev_v)
  }
end

local function print_calibration_report(results)
  print("\n" .. string.rep("=", 80))
  print("CALIBRATION REPORT: BLITZ VS CHROMIUM AGAINST FIREFOX NOISE FLOOR")
  print(string.rep("=", 80))

  local header = string.format("%-42s | %-16s | %-16s | Status", "Fixture", "FF Noise Floor", "Blitz vs Chr")
  print(header)
  print(string.rep("-", #header))

  local ff_all, blitz_all = {}, {}
  local ff_valid, blitz_valid = {}, {}
  local ff_conf, blitz_conf = {}, {}
  local ff_gaps, blitz_gaps = {}, {}

  for _, r in ipairs(results) do
    local fname = string.format("%s/%s", r.category, r.filename)
    local m_ff = r.metrics and r.metrics.ff_vs_chr
    local m_blitz = r.metrics and r.metrics.blitz_vs_chr

    local ff_str = m_ff and string.format("%s%% (%s px)", m_ff.diff_percent, m_ff.ae_pixels) or "N/A"
    local blitz_str = m_blitz and string.format("%s%% (%s px)", m_blitz.diff_percent, m_blitz.ae_pixels) or "N/A"

    local status = ""
    if m_ff and m_blitz then
      local diff_p = m_blitz.diff_percent
      local floor_p = m_ff.diff_percent
      if diff_p <= floor_p * 1.2 or diff_p < 1.0 then
        status = "Within noise floor"
      elseif diff_p <= floor_p * 2.0 then
        status = "Near floor"
      else
        status = string.format("Elevated (%s%% above floor)", round2(diff_p - floor_p))
      end
    end

    print(string.format("%-42s | %-16s | %-16s | %s", fname, ff_str, blitz_str, status))

    if m_ff then
      table.insert(ff_all, m_ff.diff_percent)
      if r.category == "valid" then table.insert(ff_valid, m_ff.diff_percent)
      elseif r.category == "conformance" then table.insert(ff_conf, m_ff.diff_percent)
      else table.insert(ff_gaps, m_ff.diff_percent) end
    end

    if m_blitz then
      table.insert(blitz_all, m_blitz.diff_percent)
      if r.category == "valid" then table.insert(blitz_valid, m_blitz.diff_percent)
      elseif r.category == "conformance" then table.insert(blitz_conf, m_blitz.diff_percent)
      else table.insert(blitz_gaps, m_blitz.diff_percent) end
    end
  end

  print("\n" .. string.rep("=", 80))
  print("SUMMARY DISTRIBUTIONS (Diff Percent %)")
  print(string.rep("=", 80))
  print(string.format("%-25s | %-18s | %-6s | %-6s | %-6s | %-6s", "Cohort", "Metric", "Min", "Max", "Mean", "Median"))
  print(string.rep("-", 75))

  local function print_dist(label, name, dist)
    if dist then
      print(string.format("%-25s | %-18s | %-6s | %-6s | %-6s | %-6s",
        label, name, tostring(dist.min), tostring(dist.max), tostring(dist.mean), tostring(dist.median)))
    end
  end

  print_dist(string.format("Valid Fixtures (%d)", #ff_valid), "Firefox floor", compute_distribution(ff_valid))
  print_dist(string.format("Valid Fixtures (%d)", #blitz_valid), "Blitz vs Chr", compute_distribution(blitz_valid))
  print(string.rep("-", 75))
  print_dist(string.format("Conformance Suite (%d)", #ff_conf), "Firefox floor", compute_distribution(ff_conf))
  print_dist(string.format("Conformance Suite (%d)", #blitz_conf), "Blitz vs Chr", compute_distribution(blitz_conf))
  print(string.rep("-", 75))
  print_dist(string.format("Targeted Gaps (%d)", #ff_gaps), "Firefox floor", compute_distribution(ff_gaps))
  print_dist(string.format("Targeted Gaps (%d)", #blitz_gaps), "Blitz vs Chr", compute_distribution(blitz_gaps))
  print(string.rep("-", 75))
  print_dist(string.format("All Fixtures (%d)", #ff_all), "Firefox floor", compute_distribution(ff_all))
  print_dist(string.format("All Fixtures (%d)", #blitz_all), "Blitz vs Chr", compute_distribution(blitz_all))
  print(string.rep("=", 80))
end

-- -----------------------------------------------------------------------------
-- CLI Entry Point
-- -----------------------------------------------------------------------------
local function main()
  local args = {
    conformance_only = false,
    valid_only = false,
    fixtures_only = false,
    include_probes = false,
    file = nil,
    no_firefox = false,
    no_blitz = false,
    width = DEFAULT_WIDTH,
    height = DEFAULT_HEIGHT,
    out_dir = DEFAULT_OUT_DIR
  }

  local i = 1
  while i <= #arg do
    local a = arg[i]
    if a == "--conformance-only" then
      args.conformance_only = true
    elseif a == "--valid-only" then
      args.valid_only = true
    elseif a == "--fixtures-only" then
      args.fixtures_only = true
    elseif a == "--include-probes" then
      args.include_probes = true
    elseif a == "--no-firefox" then
      args.no_firefox = true
    elseif a == "--no-blitz" then
      args.no_blitz = true
    elseif a == "--file" then
      i = i + 1
      args.file = arg[i]
    elseif a:match("^%-%-file=(.*)$") then
      args.file = a:match("^%-%-file=(.*)$")
    elseif a == "--width" then
      i = i + 1
      args.width = tonumber(arg[i]) or DEFAULT_WIDTH
    elseif a:match("^%-%-width=(%d+)$") then
      args.width = tonumber(a:match("^%-%-width=(%d+)$")) or DEFAULT_WIDTH
    elseif a == "--height" then
      i = i + 1
      args.height = tonumber(arg[i]) or DEFAULT_HEIGHT
    elseif a:match("^%-%-height=(%d+)$") then
      args.height = tonumber(a:match("^%-%-height=(%d+)$")) or DEFAULT_HEIGHT
    elseif a == "--out-dir" then
      i = i + 1
      args.out_dir = arg[i]
    elseif a:match("^%-%-out%-dir=(.*)$") then
      args.out_dir = a:match("^%-%-out%-dir=(.*)$")
    elseif a == "-h" or a == "--help" then
      print("Usage: lua run_diff.lua [options]")
      print("Options:")
      print("  --conformance-only   Run only conformance suite")
      print("  --valid-only         Run only validator valid fixtures")
      print("  --fixtures-only      Run only targeted gap fixtures")
      print("  --include-probes     Include non-conforming probes")
      print("  --file PATH          Run a single file")
      print("  --no-firefox         Disable Firefox rendering")
      print("  --no-blitz           Disable Blitz rendering")
      print("  --width N            Viewport width (default: 800)")
      print("  --height N           Viewport height (default: 1000)")
      print("  --out-dir DIR        Output directory (default: tools/render-diff/output)")
      os.exit(0)
    end
    i = i + 1
  end

  local fixtures = {}
  if args.file then
    table.insert(fixtures, resolve_path(args.file))
  else
    if not args.valid_only and not args.fixtures_only then
      local conf_files = glob_files(WORKSPACE_ROOT .. "/conformance/*.html")
      for _, f in ipairs(conf_files) do table.insert(fixtures, f) end
    end
    if not args.conformance_only and not args.fixtures_only then
      local valid_files = glob_files(WORKSPACE_ROOT .. "/tools/validator/tests/valid/*.html")
      for _, f in ipairs(valid_files) do table.insert(fixtures, f) end
    end
    if not args.conformance_only and not args.valid_only then
      local target_files = glob_files(WORKSPACE_ROOT .. "/tools/render-diff/fixtures/*.html")
      for _, f in ipairs(target_files) do table.insert(fixtures, f) end
      if args.include_probes then
        local probe_files = glob_files(WORKSPACE_ROOT .. "/tools/render-diff/probes/*.html")
        for _, f in ipairs(probe_files) do table.insert(fixtures, f) end
      end
    end
  end

  print(string.format("Found %d fixtures to test.", #fixtures))
  local results = run_suite(
    fixtures,
    args.out_dir,
    args.width,
    args.height,
    not args.no_firefox,
    not args.no_blitz
  )

  local summary_file = args.out_dir .. "/summary.json"
  local f = io.open(summary_file, "w")
  if f then
    f:write(json.encode(results, 2) .. "\n")
    f:close()
    print(string.format("\nSummary written to %s", summary_file))
  else
    io.stderr:write(string.format("Warning: could not write %s\n", summary_file))
  end

  if not args.no_firefox and not args.no_blitz then
    print_calibration_report(results)
  end
end

main()
