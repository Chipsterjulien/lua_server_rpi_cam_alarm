local fileExists = require( 'external.fileExists' )
local loadConfig = require( 'external.loadConfig' )
local errorResponse = require( 'external.errorResponse' )
local loadPID = require( 'external.loadPID' )

local function checkIfAlarmNeedsToBeRestart( confFile )
  local data, err = loadConfig( confFile )

  if err then
    errorResponse( 500, err )
  end

  local pidFile = data.default.pidFile

  -- Check if pidFile exists
  if not fileExists( pidFile ) then return end

  -- Check if alarm is running, not streaming
  local pidFileData = loadPID( pidFile )
  if pidFileData and pidFileData.alarm then
    local http = require( 'socket.http' )

    os.remove( pidFile )

    local port = data.default.port
    local routeInitial = data.default.routeInitial

    if not routeInitial:find( '^/' ) then routeInitial = '/' .. routeInitial end
    if not routeInitial:find( '/$' ) then routeInitial = routeInitial .. '/' end

    local road = 'http://localhost:' .. tostring( port ) .. routeInitial .. 'startAlarm'

    http.request( road )
  end
end

return checkIfAlarmNeedsToBeRestart