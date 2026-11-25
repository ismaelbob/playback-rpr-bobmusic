-- session_bridge.lua
-- REAPER Lua script for PlaybackRPR web interface
-- Enumerates all open project tabs and exposes data for playback.html
--
-- Installation:
--   1. REAPER → Actions → Show action list → ReaScript: Load...
--   2. Select this file
--   3. Right-click on the script in the list → Copy selected action Command ID
--   4. Paste that ID into playback.html (const BRIDGE_CMD)

local function json_escape(s)
  if not s then return '""' end
  s = tostring(s)
  s = s:gsub('\\', '\\\\')
  s = s:gsub('"', '\\"')
  s = s:gsub('\n', '\\n')
  s = s:gsub('\r', '\\r')
  s = s:gsub('\t', '\\t')
  return '"' .. s .. '"'
end

local function write_json()
  local resource = reaper.GetResourcePath()
  local filepath = resource .. "/reaper_www_root/playback_data.json"

  local projects = {}
  local i = 0
  while true do
    local proj, filename = reaper.EnumProjects(i, "")
    if not proj then break end
    local name = reaper.GetProjectName(proj, "")
    local ps = reaper.GetPlayStateEx(proj)
    table.insert(projects, {
      index = i,
      name = name or "",
      filename = filename or "",
      proj = proj,
      playstate = ps
    })
    i = i + 1
  end

  -- Identify the active tab by project handle so duplicate/untitled names
  -- cannot point at the wrong one. Fall back to the full file path if needed.
  local curr_proj, curr_filename = reaper.EnumProjects(-1, "")
  local curr_idx = 0
  local found = false
  for i, p in ipairs(projects) do
    if p.proj == curr_proj then
      curr_idx = p.index
      found = true
      break
    end
  end
  if not found and curr_filename and curr_filename ~= "" then
    for i, p in ipairs(projects) do
      if p.filename == curr_filename then
        curr_idx = p.index
        break
      end
    end
  end

  local parts = {}
  for i, p in ipairs(projects) do
    table.insert(parts, '{"index":' .. p.index .. ',"name":' .. json_escape(p.name) .. ',"playstate":' .. (p.playstate or 0) .. '}')
  end
  local json = '{"projects":[' .. table.concat(parts, ",") .. '],"currentIndex":' .. curr_idx .. '}'

  local file = io.open(filepath, "w")
  if file then
    file:write(json)
    file:close()
  else
    reaper.ShowConsoleMsg("PlaybackRPR ERROR: could not write " .. filepath .. "\n")
  end
end

write_json()
