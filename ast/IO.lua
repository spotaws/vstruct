local io = require "vstruct.io"
local unpack = table.unpack or unpack
local Number = require "vstruct.ast.Number"
local Node = require "vstruct.ast.Node"
local IO = Node:copy()

local function is_backref(arg)
  return arg:match('^#[%a_][%w_.]*$')
end

local function str2args(args)
  local argv = { n = 0; has_backrefs = false; }
  if args then
    local args = args..","

    for arg in args:gmatch("([^,]*),") do
      if #arg == 0 then arg = nil
      elseif tonumber(arg) then arg = tonumber(arg)
      elseif is_backref(arg) then
        arg = Number(arg)
        argv.has_backrefs = true
      end
      argv.n = argv.n +1
      argv[argv.n] = arg
    end
  end
  return argv
end

function IO:__init(name, args)
  self.name = name
  self.argv = str2args(args)
  self.size = io(name, "size", self:get_argv())
  self.hasvalue = io(name, "hasvalue", self:get_argv())
end

function IO:read(fd, data)
  local buf

  if self.size and self.size > 0 then
    buf = fd:read(self.size)
    assert(buf and #buf == self.size, "attempt to read past end of buffer in format "..self.name)
  end

  return io(self.name, "read", fd, buf, self:get_argv(data))
end

function IO:readbits(bits, data)
  return io(self.name, "readbits", bits, self:get_argv(data))
end

function IO:write(fd, ctx)
  local buf = io(self.name, "write", fd, ctx.data, self:get_argv_ctx(ctx))
  if buf then
    fd:write(buf)
  end
end

function IO:writebits(bits, ctx)
  local buf = io(self.name, "writebits", bits, ctx.data, self:get_argv_ctx(ctx))
  if buf then
    fd:write(buf)
  end
end

function IO:get_argv(data)
  -- Usually the contents were determined at compile-time and we can just
  -- unpack it as is.
  if not self.argv.has_backrefs then
    return unpack(self.argv, 1, self.argv.n)
  end

  -- If backreferences were involved, we have to try to resolve them.
  local buf = {}
  for i=1,self.argv.n do
    if self.argv[i] then
      buf[i] = self.argv[i]:get(data)
    end
  end

  return unpack(buf, 1, self.argv.n)
end

-- Get fully resolved argv from a write context rather than from the actual
-- data structure.
function IO:get_argv_ctx(ctx)
  if ctx.parent then
    return self:get_argv(ctx.parent.data)
  else
    return self:get_argv(ctx.data)
  end
end

return IO
