local Node = require "vstruct.ast.Node"

local Repeat = Node:copy()

function Repeat:__init(count, child)
  self.child = child
  self.count = count
  if count.value and child.size then
    self.size = count:get(nil) * child.size
  else
    -- Child has runtime-deferred size, or count is a backreference
    self.size = nil
  end
end

function Repeat:read(fd, data)
  for i=1,self.count:get(data) do
    self.child:read(fd, data)
  end
end

function Repeat:readbits(bits, data)
  for i=1,self.count:get(data) do
    self.child:readbits(bits, data)
  end
end

function Repeat:write(fd, data)
  for i=1,self.count:get(data.data) do
    self.child:write(fd, data)
  end
end

function Repeat:writebits(bits, data)
  for i=1,self.count:get(data.data) do
    self.child:writebits(bits, data)
  end
end

return Repeat
