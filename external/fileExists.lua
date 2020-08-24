local function fileExists( filename )
   local fd = io.open( filename, 'r' )
   if fd ~= nil then io.close( fd ) return true else return false end
end

return fileExists