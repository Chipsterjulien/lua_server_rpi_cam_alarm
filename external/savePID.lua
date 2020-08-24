local toml = require( 'toml' )

local function savePID( filename, pidList )
  local f = io.open( filename, 'w' )
  if not f then
    return 'Unable to write data in ' .. filename
  end

  f:write( toml.encode( pidList ) )
  f:close()

  return nil
end

return savePID