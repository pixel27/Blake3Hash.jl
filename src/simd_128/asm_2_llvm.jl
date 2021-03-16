# MIT License
#
# Copyright (c) 2020 Joshua E Gentry

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
using SIMD

@inline function shuffle(
            x1::VECTOR,
            v::Tuple{Int, Int, Int, Int}
        )::VECTOR
    return shufflevector(x1, Val((v[4], v[3], v[2], v[1])))
end

@inline function shuffle(
            x1::VECTOR,
            x2::VECTOR,
            v::Tuple{Int, Int, Int, Int}
        )::VECTOR
    return shufflevector(x1, x2, Val((v[4], v[3], 4+v[2], 4+v[1])))
end

@inline function blend(x1::VECTOR, x2::VECTOR, mask::UInt8)::VECTOR
    local c1 = reinterpret(Vec{8, UInt16}, x1)
    local c2 = reinterpret(Vec{8, UInt16}, x2)
    local m = (
        (mask & 0x01) != 0 ? 8  : 0,
        (mask & 0x02) != 0 ? 9  : 1,
        (mask & 0x04) != 0 ? 10 : 2,
        (mask & 0x08) != 0 ? 11 : 3,
        (mask & 0x10) != 0 ? 12 : 4,
        (mask & 0x20) != 0 ? 13 : 5,
        (mask & 0x40) != 0 ? 14 : 6,
        (mask & 0x80) != 0 ? 15 : 7
    )
    local r = shufflevector(c1, c2, Val(m))

    return reinterpret(VECTOR, r)
end

@inline function unpacklo_64(x1::VECTOR, x2::VECTOR)::VECTOR
    local t1 = reinterpret(Vec{2, UInt64}, x1)
    local t2 = reinterpret(Vec{2, UInt64}, x2)
    local r  = shufflevector(t1, t2, Val((0, 2)))
    return reinterpret(VECTOR, r)
end

@inline function unpackhi_64(x1::VECTOR, x2::VECTOR)::VECTOR
    local t1 = reinterpret(Vec{2, UInt64}, x1)
    local t2 = reinterpret(Vec{2, UInt64}, x2)
    local r  = shufflevector(t1, t2, Val((1, 3)))
    return reinterpret(VECTOR, r)
end

@inline function unpackhi_32(x1::VECTOR, x2::VECTOR)::VECTOR
    return shufflevector(x1, x2, Val((2, 6, 3, 7)))
end

@inline function unpacklo_32(x1::VECTOR, x2::VECTOR)::VECTOR
    return shufflevector(x1, x2, Val((0, 4, 1, 5)))
end
