local routes = {}

local function startVideoAndStream( pidFilename, launchProcessList, stopProcessList, action, toml, external )
  if external.fileExists( pidFilename ) then
    return routes.stateAlarm( pidFilename, toml, external )
  end

  -- Launch all processes in list
  for _, cmd in ipairs( launchProcessList ) do
    os.execute( cmd )
  end

  -- Get process pid
  local pidObjectList = {}
  for _, procName in ipairs( stopProcessList ) do
    local pid = external.exec( 'pgrep ^' .. procName .. '$' )
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
  local err = external.savePID( pidFilename, pidList, toml )
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

local function stopVideoAndStream( pidFilename, action, toml, external )
  local pidList = external.loadPID( pidFilename, toml )

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

function routes.stateAlarm( pidFilename, toml, external )
  local pidList = external.loadPID( pidFilename, toml )
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

function routes.startAlarm( data, toml, external )
  local pidFilename = data.default.pidFile
  local launchProcessList = data.alarm.launchProcessList
  local stopProcessList = data.alarm.stopProcessList
  local action = 'alarm'

  return startVideoAndStream( pidFilename, launchProcessList, stopProcessList, action, toml, external )
end

function routes.startStream( data, toml, external )
  local pidFilename = data.default.pidFile
  local launchProcessList = data.stream.launchProcessList
  local stopProcessList = data.stream.stopProcessList
  local action = 'stream'

  return startVideoAndStream( pidFilename, launchProcessList, stopProcessList, action, toml, external )
end

function routes.stopAlarm( data, toml, external )
  local pidFilename = data.default.pidFile
  local action = 'alarm'

  return stopVideoAndStream( pidFilename, action, toml, external )
end

function routes.stopStream( data, toml, external )
  local pidFilename = data.default.pidFile
  local action = 'stream'

  return stopVideoAndStream( pidFilename, action, toml, external )
end

return routes
