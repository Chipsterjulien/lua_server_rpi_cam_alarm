local function readEntireFile( filename )
  local fd = io.open( filename, 'rb' )

  if fd == nil then return nil end

  local content = fd:read( '*a' )
  fd:close()

  return content
end

return readEntireFile