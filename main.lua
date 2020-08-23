#!/usr/bin/luajit

-- Dependencies:
--  nginx + lua mod
--  raspivid
--  streameye
--  lua socket version 5.1 (restart after reboot)
--  pgrep

-- Using:
--  curl localhost:8180/api/state
--  or
--  http localhost:8180/api/state

package.path = package.path .. ';/app/?.lua'

local ngx = ngx or require( 'ngx' )

local confFile = '/app/cfg/camAlarm.toml'

local json = require('json')
local toml = require('toml')
local routes = require('routes')
local external = require('external')

local getWebRoutes = {
  [ '/stateAlarm' ] = function( data ) return routes.stateAlarm( data.default.pidFile, toml, external ) end,
  [ '/startAlarm' ] = function( data ) return routes.startAlarm( data, toml, external ) end,
  [ '/stopAlarm' ] = function( data ) return routes.stopAlarm( data, toml, external ) end,
  [ '/startStream' ] = function( data ) return routes.startStream( data, toml, external ) end,
  [ '/stopStream' ] = function( data ) return routes.stopStream( data, toml, external ) end,
}

------
-- functions
------------

local function errorResponse( debug, codeINT, errorStr )
  -- In debug mode, send the right error otherwise, to "counter" somes attacks, send a status code to 200
  if debug then
    ngx.status = codeINT
    ngx.say( json.encode( { error = errorStr } ) )
  else
    ngx.status = 200
  end

  ngx.log( ngx.STDERR, errorStr )
end

local function checkIfAlarmNeedsToBeRestart()
  local data = external.loadConfig( confFile, toml )

  -- Check if confFile is loaded
  if not data then
    io.stderr:write( 'No data in ' .. confFile .. '\n' )
    os.exit( 1 )
  end

  local pidFile = data.default.pidFile

  -- Check if pidFile exists
  if not external.fileExists( pidFile ) then return end

  -- Check if alarm is running, not streaming
  local pidFileData = external.loadPID( pidFile, toml )
  if pidFileData and pidFileData.alarm then
    local http = require( 'socket.http' )

    os.remove( pidFile )

    local port = data.default.port
    local routeInitial = data.default.routeInitial

    if not routeInitial:find( '^/' ) then routeInitial = '/' .. routeInitial end
    if not routeInitial:find( '/$' ) then routeInitial = routeInitial .. '/' end

    local road = 'http://localhost:' .. tostring( port ) .. routeInitial .. 'startAlarm'

    http.request(road)
  end
end

local function main()
  local data = external.loadConfig( confFile, toml )
  local debug = data.debug or false

  -- Check if confFile is loaded
  if not data then
    errorResponse( debug, 500, confFile .. ' is empty or does not exist' )
    ngx.exit( 500 )
  end

  -- Check if request method is not GET
  if ngx.var.request_method ~= 'GET' then
    -- Request method does not exist
    errorResponse( debug, 405, ngx.var.request_method .. ' method is not supported in ' .. ngx.var.uri .. ' call' )
    ngx.exit( 405 )
  end

  local routeInitial = data.default.routeInitial:gsub( '/$', '' )
  local road = ngx.var.uri:gsub( routeInitial, '' )

  -- If road and ngx.var.uri are identical then road is not good
  if road == ngx.var.uri then
    errorResponse( debug, 404, road .. ' URL does not exist' )
    ngx.exit( 404 )
  end

  -- Check if road exists
  if not getWebRoutes[road] then
    errorResponse( debug, 404, ngx.var.uri .. ' URL does not exist' )
    ngx.exit( 404 )
  end

  local err, state
  local pidFile = data.default.pidFile

  -- Check if it can possible to save pidFile
  err = external.isPermitToWriteToDirectory( pidFile )
  if err then
    errorResponse( debug, 500, 'Unable to save ' .. pidFile )
    ngx.exit( 500 )
  end

  -- Call the right road
  state, err = getWebRoutes[ road ]( data )
  if err ~= nil then
    errorResponse( debug, 404, err )
    ngx.exit( 404 )
  end

  -- Add location to state
  state.where = data.default.where
  if not state.alarm then state.alarm = 'stop' end
  if not state.stream then state.stream = 'stop' end

  -- Send response
  ngx.say( json.encode( state ) )
  ngx.exit( 200 )
end

------
-- Start here
-------------

if not arg or #arg == 0 then
  main()
else
  checkIfAlarmNeedsToBeRestart()
end
