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

mutable struct Buffer{TYPE}
    offset::Int
    data::TYPE
    Buffer() = new{MVector{64, UInt8}}(0, zeros(MVector{64, UInt8}))
    Buffer(data::TYPE) where TYPE = new{TYPE}(0, data)
end

function clear(
            b::Buffer
        )
    b.offset = 0
    fill!(b.data, UInt8(0))
end

function Base.view(
            b::Buffer,
            bytes::Int
        )
    retval = view(b.data, (b.offset+1):(b.offset+bytes))
    b.offset += bytes
    return retval
end

function block_view(
            b::Buffer
        )::BLOCK
    access = reinterpret(UInt32, view(b, BLOCK_LEN))

    return BLOCK((
        vload(VECTOR, access, 1),
        vload(VECTOR, access, 5),
        vload(VECTOR, access, 9),
        vload(VECTOR, access, 13)
    ))
end

function as_block(
            b::Buffer{MVector{64, UInt8}}
        )
    data = reinterpret(UInt32, view(b.data, 1:64))

    return BLOCK((
        VECTOR((data[1], data[2], data[3], data[4])),
        VECTOR((data[5], data[6], data[7], data[8])),
        VECTOR((data[9], data[10], data[11], data[12])),
        VECTOR((data[13], data[14], data[15], data[16]))
    ))
end

function remaining(
            b::Buffer
        )::Int
    return length(b.data) - b.offset
end

function Base.length(
            b::Buffer
        )::Int
    return b.offset
end