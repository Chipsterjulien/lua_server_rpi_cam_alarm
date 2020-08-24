local function exec( cmd )
  local handle = io.popen( cmd )
  local output = handle:read( '*a' )
  handle:close()

  return output
end

return exec