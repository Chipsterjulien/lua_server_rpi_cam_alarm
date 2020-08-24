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

package.path = package.path .. ';/app/?.lua;/app/external/?.lua;/app/third-party/?.lua'

local json = require('json')
local routes = require('routes')

local checkIfAlarmNeedsToBeRestart = require( 'external.checkIfAlarmNeedsToBeRestart' )
local errorResponse = require( 'external.errorResponse' )
local loadConfig = require( 'external.loadConfig' )
local isPermitToWriteToDirectory = require( 'external.isPermitToWriteToDirectory' )

local ngx = ngx or require( 'ngx' )

local confFile = '/app/cfg/camAlarm.toml'

local getWebRoutes = {
  [ '/stateAlarm' ] = function( data ) return routes.stateAlarm( data.default.pidFile ) end,
  [ '/startAlarm' ] = function( data ) return routes.startAlarm( data ) end,
  [ '/stopAlarm' ] = function( data ) return routes.stopAlarm( data ) end,
  [ '/startStream' ] = function( data ) return routes.startStream( data ) end,
  [ '/stopStream' ] = function( data ) return routes.stopStream( data ) end,
}

------
-- functions
------------

local function main()
  local data, err = loadConfig( confFile )

  if err then
    errorResponse( 500, err )
  end

  -- Check if request method is not GET
  if ngx.var.request_method ~= 'GET' then
    -- Request method does not exist
    errorResponse( 405, ngx.var.request_method .. ' method is not supported in ' .. ngx.var.uri .. ' call' )
    ngx.exit( 405 )
  end

  local routeInitial = data.default.routeInitial:gsub( '/$', '' )
  local road = ngx.var.uri:gsub( routeInitial, '' )

  -- If road and ngx.var.uri are identical then road is not good
  if road == ngx.var.uri then
    errorResponse( 404, road .. ' URL does not exist' )
    ngx.exit( 404 )
  end

  -- Check if road exists
  if not getWebRoutes[ road ] then
    errorResponse( 404, ngx.var.uri .. ' URL does not exist' )
    ngx.exit( 404 )
  end

  local state
  local pidFile = data.default.pidFile

  -- Check if it can possible to save pidFile
  err = isPermitToWriteToDirectory( pidFile )
  if err then
    errorResponse( 500, 'Unable to save ' .. pidFile )
    ngx.exit( 500 )
  end

  -- Call the right road
  state, err = getWebRoutes[ road ]( data )
  if err ~= nil then
    errorResponse( 404, err )
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

initTime = os.clock()

if not arg or #arg == 0 then
  main()
else
  checkIfAlarmNeedsToBeRestart( confFile )
end
