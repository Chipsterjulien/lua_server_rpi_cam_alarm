local readEntireFile = require( 'external.readEntireFile' )
local toml = require( 'toml' )

local function loadPID( filename )
  local tomlStr = readEntireFile( filename )
  if tomlStr == nil then return nil end

  return toml.parse( tomlStr )
end

return loadPID