-- "basic" test module for vstruct
-- Tests a variety of non-floating-point usage.
-- Does not test floating point operations - see test/fp-*endian.lua for those,
-- since there are quite a lot of them.

local vstruct = require "vstruct"
local test = require "vstruct.test.common"

local x = test.x
local T = test.autotest

test.group "basic tests"

T("true",   "> b8",   x"0000 0000 0000 0001", true)
T("false",    "> b8",   x"0000 0000 0000 0000", false)

T("unsigned", "< u3",   x"FE FF FF", 2^24-2)
T("signed",   "< i3",   x"FE FF FF", -2)

T("c str",    "z",    "foobar\0baz", "foobar", "foobar\0")
T("padded str", "z10",    "foobar\0baz", "foobar", "foobar\0\0\0\0")

T("fixed str",  "s4",   "foobar", "foob", "foob")

T("counted str","< c4",   x"06000000".."foobar", "foobar")

T("bitmask",  "> m1",   x"FA", {{ false, true, false, true, true, true, true, true }})
T("bitmask",  "> m2",   x"FA 78", {{ false, false, false, true; true, true, true, false; false, true, false, true; true, true, true, true }})
T("bitmask",  "< m2",   x"78 FA", {{ false, false, false, true; true, true, true, false; false, true, false, true; true, true, true, true }})

T("skip/pad", "x4u1",   x"00 00 00 00 02", 2)
T("skip/pad value", "x4,255u1",   x"FF FF FF FF 02", 2)

T("seek @",   "@2 u1x2",  x"00 00 02 00 00", 2)
T("seek +",   "+2 u1x2",  x"00 00 02 00 00", 2)
T("seek -",   "+4-2 u1x2",x"00 00 02 00 00", 2)

T("little-endian", "< u2",  x"00 01", 256)
T("big-endian", "> u2",   x"00 01", 1)

if test.bigendian() then
  T("host-endian","= u2", x"01 00", 256)
  T("endianness leak (1)", "< u2", x"00 01", 256)
  T("endianness leak (2)", "u2", x"00 01", 1)
else
  T("host-endian","= u2", x"01 00", 1)
  T("endianness leak (1)", "> u2", x"00 01", 1)
  T("endianness leak (2)", "u2", x"00 01", 256)
end

T("bitpack [>b]", "> [2| x15 b1 ]",  x"00 01", true)
T("bitpack [<b]", "< [2| x15 b1 ]",  x"01 00", true)
T("bitpack [>u]", "> [2| 4*u4 ]",  x"12 34", {1,2,3,4})
T("bitpack [<u]", "< [2| 4*u4 ]",  x"12 34", {3,4,1,2})
T("bitpack [>i]", "> [2| 4*i4 ]",  x"12 EF", {1,2,-2,-1})
T("bitpack [<i]", "< [2| 4*i4 ]",  x"12 EF", {-2,-1,1,2})
T("bitpack [>m]", "> [2| m5 m3 x8 ]",  x"12 00", {{false,false,false,true,false},{false,true,false}})
T("bitpack [<m]", "< [2| m5 m3 x8 ]",  x"00 12", {{false,false,false,true,false},{false,true,false}})
T("bitpack [x,v]", "> [2| x8,1 x8,0 ]", x"FF 00", {})

T("fixed point >",  "> p2,8", x"40 80", 64.5)
T("fixed point <",  "< p2,8", x"40 80", -127.75)

T("repetition", "> 4*u1", x"01 02 03 04", { 1, 2, 3, 4 })
T("groups", "> 2*(u1 i1)", x"01 FF 02 FE", { 1, -1, 2, -2 })
T("tables", "> 2*{ u1 i1 }", x"01 FF 02 FE", { { 1, -1 }, { 2, -2 } })
T("names", "> coords:{ x:u1 y:u1 } coords.z:u1", x"01 02 03", { coords = { x = 1, y = 2, z = 3 } })

T("backref-repeat", "count:u1 #count*u1", x"04 80 FF 11 22", { count = 4; 128, 255, 17, 34 })
T("backref-seek", "offset:u1 @#offset u1",
  x"02 00 03 00 00", { offset = 2; 3 }, x"02 00 03")
T("backref-str", "< size:u2 str:s#size",
  "\x10\x00abcdefghijklmnopqrstuvwxyz", { size = 16; str = "abcdefghijklmnop"; },
  "\x10\x00abcdefghijklmnop")

T("scoping", "outer:{ size:u1 s#size inner:{ size:u1 s#size } } outer.inner.size:u1",
  "\x0Aouter-text\x0Cinner-string\x0C",
  { outer = { size = 10; "outer-text"; inner = { size = 12; "inner-string" }}})

T("nesting", "header:{ size:u1 offset:u1 } @#header.offset s#header.size",
  "\x04\x06    text", { header = { size = 4; offset = 6; }; "text" },
  "\x04\x06\x00\x00\x00\x00text")

T("UCS-2 z",  "> z,2",  x"0061 0062 0000 FFFF", "\0a\0b", x"0061 0062 0000")
T("UCS-2 z8", "> z8,2", x"0061 0062 0000 FFFF", "\0a\0b", x"0061 0062 0000 0000")

T("repeated repeat", "2*2*u1", x"01 01 01 01", { 1, 1, 1, 1 })

local sizeof = {
  ["u4 b1 x2"] = 7;
  ["c4"] = false;
  ["z"] = false;
  ["z64"] = 64;
  ["> coords:{ x:u1 y:u1 } coords.z:u1"] = 3;
  ["@2 u1x2"] = false;
  ["< size:u2 str:s#size"] = false;
}

for format,expected_size in pairs(sizeof) do
  local actual_size = vstruct.sizeof(format) or false
  test.record("sizeof", actual_size == expected_size,
    string.format("[%s]: %s != %s", format, expected_size, actual_size))
end

local i = 1
for val in vstruct.records("u1", x"01 02 03 04 05 06", true) do
  test.record("stream-unpacked #"..i, val == i, val)
  i = i+1
end

local i = 1
for val in vstruct.records("i:u1", x"01 02 03 04 05 06") do
  test.record("stream #"..i, val.i == i, val.i)
  i = i+1
end

vstruct.compile("coord", "x:u1 y:u1 z:u1")
T("splice", "> position:{ &coord }", x"01 02 03", { position = { x = 1, y = 2, z = 3 } })
