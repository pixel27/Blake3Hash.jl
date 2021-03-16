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
@inline function rot16(x::VECTOR)::VECTOR
    x = reinterpret(Vec{8, UInt16}, x)
    r = shufflevector(x, Val((1, 0, 3, 2, 5, 4, 7, 6)))
    return reinterpret(VECTOR, r)
end

@inline function rot12(x::VECTOR)::VECTOR
    return (x >> 12) ⊻ (x << 20)
end

@inline function rot8(x::VECTOR)::VECTOR
    x = reinterpret(Vec{16, UInt8}, x)
    r = shufflevector(x, Val((1, 2, 3, 0, 5, 6, 7, 4, 9, 10, 11, 8, 13, 14, 15, 12)))
    return reinterpret(VECTOR, r)
end

@inline function rot7(x::VECTOR)::VECTOR
    return (x >> 7) ⊻ (x << 25)
end
