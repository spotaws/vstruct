-- A node that holds either a number, or a reference to an already-read, named
-- field which contains a number.
local Node = require "vstruct.ast.Node"
local Number = Node:copy()

-- Partially based on get() in Name.lua. Does not support numeric indices, only
-- string ones.
local function get(data, key)
  local val
  for name in key:gmatch("([^%.]+)%.") do
    if data[name] == nil then
      val = nil
      break
    end
    data = data[name]
  end
  val = data[key:match("[^%.]+$")]

  assert(val ~= nil, 'vstruct: backreferenced field "'..key..'" has not been read yet')
  assert(type(val) == 'number', 'vstruct: backreferenced field "'..key..'" is not a numeric type')
  return val
end

function Number:__init(text)
  if text:match('^#') then
    self.key = text:sub(2,-1)
  else
    self.value = assert(tonumber(text), 'vstruct: numeric constant "'..text..'" is not a number')
  end
end

-- This does not support the regular read/write interface; the only thing you
-- can do with it is get its contained number.
function Number:get(data)
  if self.value then
    return self.value
  else
    return get(data, self.key)
  end
end

return Number

