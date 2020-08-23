local external = {}

local function getRandomString(length)
  math.randomseed(os.clock()^5)

  local res = ""
  for _=1, length do
    res = res .. string.char(math.random(97,122))
  end

  return res
end

function external.exec(cmd)
  local handle = io.popen(cmd)
  local output = handle:read("*a")
  handle:close()

  return output
end

function external.fileExists(filename)
   local f = io.open(filename, "r")
   if f ~= nil then io.close(f) return true else return false end
end

function external.getRootPath(path)
  local pathSplitted = external.splitN(path, "/")
  pathSplitted = external.slice(pathSplitted, 1, #pathSplitted - 1)

  return table.concat(pathSplitted, "/")
end

function external.isTableEmpty(data)
  for _ in pairs(data) do
    return false
  end

  return true
end

function external.isPermitToWriteToDirectory(path)
  local filename = getRandomString(10)
  if not path:find("/$") then path = path .. "/" end

  local fullFilename = path .. filename
  local fn = io.open(fullFilename)
  if fn then
    fn:close()
    os.remove(fn)

    return true
  end

  return false
end

function external.join(root, filename)
  if root:find("/$") then
    return root .. filename
  else
    return root .. "/" .. filename
  end
end

function external.loadConfig(filename, toml)
  local tomlStr = external.readEntireFile(filename)
  local data = toml.parse(tomlStr)

  if data == nil or external.isTableEmpty(data) then
    ngx.log(ngx.STDERR, "Config file is empty. Exiting …")
    os.exit(1)
  end

  return data
end

function external.loadPID(filename, toml)
  local tomlStr = external.readEntireFile(filename)
  if tomlStr == nil then return nil end

  return toml.parse(tomlStr)
end

function external.readEntireFile(filename)
  local f = io.open(filename, "rb")

  if f == nil then return nil end

  local content = f:read("*a")
  f:close()

  return content
end

function external.savePID(filename, pidList, toml)
  local f = io.open(filename, "w")
  if not f then return string.format("Unable to write data in %s", filename) end

  f:write(toml.encode(pidList))
  f:close()

  return nil
end

function external.splitN(str, sep, maxSplit)
  sep = sep or ' '
  maxSplit = maxSplit or #str
  local t = {}
  local s = 1
  local e, f = str:find(sep, s, true)

  while e do
    maxSplit = maxSplit - 1
    if maxSplit <= 0 then break end

    table.insert(t, str:sub(s, e - 1))
    s = f + 1
    e, f = str:find(sep, s, true)
  end

  if s <= #str then
    table.insert(t, str:sub(s))
  end

  return t
end

function external.slice(tbl, first, last, step)
  local sliced = {}

  for i=first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

return external
