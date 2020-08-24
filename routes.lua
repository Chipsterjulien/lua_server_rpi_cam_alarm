local exec = require( 'external.exec' )
local fileExists = require( 'external.fileExists' )
local loadPID = require( 'external.loadPID' )
local savePID = require( 'external.savePID' )

local routes = {}

local function startVideoAndStream( pidFilename, launchProcessList, stopProcessList, action )
  if fileExists( pidFilename ) then
    return routes.stateAlarm( pidFilename )
  end

  -- Launch all processes in list
  for _, cmd in ipairs( launchProcessList ) do
    os.execute( cmd )
  end

  -- Get process pid
  local pidObjectList = {}
  for _, procName in ipairs( stopProcessList ) do
    local pid = exec( 'pgrep ^' .. procName .. '$' )
    table.insert( pidObjectList, { pid = pid, name = procName } )
  end

  -- Check if process does not start
  local errorsMessages = {}
  for _, obj in ipairs( pidObjectList ) do
    if tonumber( obj.pid ) == nil then
      table.insert( errorsMessages, 'Unable to start ' .. obj.name )
    end
  end

  -- If found error, stop all processes
  if #errorsMessages ~= 0 then
    for _, obj in ipairs( pidObjectList ) do
      if tonumber( obj.pid ) ~= nil then
        os.execute( 'kill %s' .. obj.pid )
      end
    end

    return nil, table.concat( errorsMessages, ' | ' )
  end

  -- Put all pid in a list
  local pidList = {}
  for _, pidObject in pairs( pidObjectList ) do
    table.insert( pidList, tonumber( pidObject.pid ) )
  end

  -- Add alarm or stream starting to table
  pidList[ action ] = 'start'

  -- Save table to pidFile
  local err = savePID( pidFilename, pidList )
  if err then
    for _, obj in ipairs( pidObjectList ) do
      if tonumber( obj.pid ) ~= nil then
        os.execute( 'kill ' .. obj.pid )
      end
    end

    return nil, err
  end

  return { [ action ] = 'start' }, nil
end

local function stopVideoAndStream( pidFilename, action )
  local pidList = loadPID( pidFilename )

  if pidList then
    for i=#pidList, 1, -1 do
      os.execute( 'kill ' .. pidList[i] )
    end

    os.remove( pidFilename )
  end

  return { [ action ] = 'stop' }, nil
end

------
-- roads
--------

function routes.stateAlarm( pidFilename )
  local pidList = loadPID( pidFilename )
  if pidList == nil then
    return { alarm = 'stop', stream = 'stop'}, nil
  end

  if pidList.alarm ~= nil then
    return { alarm = 'start' }, nil
  end
  if pidList.stream ~= nil then
    return { stream = 'start' }, nil
  end
end

function routes.startAlarm( data )
  local pidFilename = data.default.pidFile
  local launchProcessList = data.alarm.launchProcessList
  local stopProcessList = data.alarm.stopProcessList
  local action = 'alarm'

  return startVideoAndStream( pidFilename, launchProcessList, stopProcessList, action )
end

function routes.startStream( data )
  local pidFilename = data.default.pidFile
  local launchProcessList = data.stream.launchProcessList
  local stopProcessList = data.stream.stopProcessList
  local action = 'stream'

  return startVideoAndStream( pidFilename, launchProcessList, stopProcessList, action )
end

function routes.stopAlarm( data )
  local pidFilename = data.default.pidFile
  local action = 'alarm'

  return stopVideoAndStream( pidFilename, action )
end

function routes.stopStream( data )
  local pidFilename = data.default.pidFile
  local action = 'stream'

  return stopVideoAndStream( pidFilename, action )
end

return routes
