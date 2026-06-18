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
    local proj = reaper.EnumProjects(i)
    if not proj then break end
    local name = reaper.GetProjectName(proj, "")
    local ps = reaper.GetPlayStateEx(proj)
    table.insert(projects, { index = i, name = name or "", playstate = ps })
    i = i + 1
  end

  local curr_name = reaper.GetProjectName(nil, "")
  local curr_idx = 0
  for i, p in ipairs(projects) do
    if p.name == curr_name then
      curr_idx = i - 1
      break
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
