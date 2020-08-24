local splitN = require( 'external.splitN' )
local slice = require( 'external.slice' )

local function getRootPath( path )
  local pathSplitted = splitN( path, '/' )
  pathSplitted = slice( pathSplitted, 1, #pathSplitted - 1 )

  return table.concat( pathSplitted, '/' )
end

return getRootPath