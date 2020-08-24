local json = require( 'json' )
local ngx = ngx or require( 'ngx' )

local function errorResponse( codeINT, errorStr )
  ngx.status = codeINT
  ngx.log( ngx.STDERR, errorStr )

  ngx.say( json.encode( { error = errorStr, code = codeINT } ) )

  ngx.log( ngx.NOTICE, string.format( '\n\nError elapsed time: %.2f ms\n\n', ( os.clock() - initTime ) * 1000 ) )

  ngx.exit( codeINT )
end

return errorResponse