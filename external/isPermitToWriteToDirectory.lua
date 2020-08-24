local getRandomString = require( 'external.getRandomString' )

local function isPermitToWriteToDirectory( path )
  local filename = getRandomString( 10 )
  if not path:find( '/$' ) then path = path .. '/' end

  local fullFilename = path .. filename
  local fd = io.open( fullFilename )
  if fd then
    fd:close()
    os.remove( fd )

    return true
  end

  return false
end

return isPermitToWriteToDirectory