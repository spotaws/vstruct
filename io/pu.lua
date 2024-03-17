-- signed fixed point
-- format is pTOTAL_SIZE,FRACTIONAL_SIZE
-- Fractional size is in bits, total size in bytes.
-- FIXME: this should support bitpacks

local io = require "vstruct.io"
local pu = {}

function pu.size(size, frac)
  assert(size, "format requires a size")
  assert(frac, "format requires a fractional-part size")
  if tonumber(size) and tonumber(frac) then
    -- Check only possible if both values were specified at compile time
    assert(size*8 >= frac, "fixed point number has more fractional bits than total bits")
  end

  return size
end

function pu.read(fd, buf, size, frac)
  return io("u", "read", fd, buf, size)/(2^frac)
end

function pu.write(fd, data, size, frac)
  return io("u", "write", fd, data * 2^frac, size)
end

return pu
