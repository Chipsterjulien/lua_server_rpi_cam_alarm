local function splitN( str, sep, maxSplit )
  sep = sep or ' '
  maxSplit = maxSplit or #str
  local t = {}
  local s = 1
  local e, f = str:find(sep, s, true)

  while e do
    maxSplit = maxSplit - 1
    if maxSplit <= 0 then break end

    table.insert(t, str:sub(s, e - 1))
    s = f + 1
    e, f = str:find(sep, s, true)
  end

  if s <= #str then
    table.insert(t, str:sub(s))
  end

  return t
end

return splitN