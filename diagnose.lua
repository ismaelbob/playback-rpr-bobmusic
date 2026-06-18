local proj = reaper.EnumProjects(0)
if not proj then
  reaper.ShowConsoleMsg("EnumProjects(0) returned nil\n")
  return
end
reaper.ShowConsoleMsg("proj type: " .. type(proj) .. "\n")

-- Try all calling conventions
local a, b = reaper.GetProjectName(proj, "")
reaper.ShowConsoleMsg("Convention 1: GetProjectName(proj, '')\n")
reaper.ShowConsoleMsg("  a=" .. tostring(a) .. " type(a)=" .. type(a) .. "\n")
reaper.ShowConsoleMsg("  b=" .. tostring(b) .. " type(b)=" .. type(b) .. "\n")

local ret = reaper.GetProjectName(proj, "")
reaper.ShowConsoleMsg("Convention 2: ret = GetProjectName(proj, '')\n")
reaper.ShowConsoleMsg("  ret=" .. tostring(ret) .. " type(ret)=" .. type(ret) .. "\n")

-- Try with nil proj (current project)
local c, d = reaper.GetProjectName(nil, "")
reaper.ShowConsoleMsg("Convention 3: GetProjectName(nil, '')\n")
reaper.ShowConsoleMsg("  c=" .. tostring(c) .. " type(c)=" .. type(c) .. "\n")
reaper.ShowConsoleMsg("  d=" .. tostring(d) .. " type(d)=" .. type(d) .. "\n")

-- Try buf size as number
local e, f = reaper.GetProjectName(proj, 260)
reaper.ShowConsoleMsg("Convention 4: GetProjectName(proj, 260)\n")
reaper.ShowConsoleMsg("  e=" .. tostring(e) .. " type(e)=" .. type(e) .. "\n")
reaper.ShowConsoleMsg("  f=" .. tostring(f) .. " type(f)=" .. type(f) .. "\n")

-- Try with no buffer arg
local g = reaper.GetProjectName(proj)
reaper.ShowConsoleMsg("Convention 5: GetProjectName(proj) (no buf)\n")
reaper.ShowConsoleMsg("  g=" .. tostring(g) .. " type(g)=" .. type(g) .. "\n")
