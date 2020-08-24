local toml = require( 'toml' )
local readEntireFile = require( 'readEntireFile' )
local isTableEmpty = require( 'isTableEmpty' )

local function loadConfig( filename )
  local tomlStr = readEntireFile( filename )

  if not tomlStr then
    return nil, filename .. ' config file is not existed'
  end

  -- Config file must endling by empty line
  tomlStr = tomlStr .. '\n'

  local data = toml.parse( tomlStr )

  if isTableEmpty( data ) then
    return nil, filename .. ' is an empty config file'
  end

  return data, nil
end

return loadConfig