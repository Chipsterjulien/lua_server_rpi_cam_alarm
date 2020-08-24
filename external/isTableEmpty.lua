local function isTableEmpty( data )
  if next( data ) == nil then
    return true
  end

  return false
end

return isTableEmpty