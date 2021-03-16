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

struct Output
    chaining::CHAINING
    block::BLOCK
    block_len::UInt32
    counter::UInt64
    flags::UInt32
end

function chaining_value(self::Output)::CHAINING
    return compress(
        self.chaining,
        self.block,
        self.block_len,
        self.counter,
        self.flags
    )
end

function hash(
            self::Output,
            out::AbstractVector{UInt8}
        )::Nothing

    if length(out) == 32
        out = reinterpret(UInt32, out)
        # ---------------------------------------------------------------------------------
        # Normal case, produce a 256bit hash.
        cv = compress(
            self.chaining,
            self.block,
            self.block_len,
            UInt64(0),
            self.flags | ROOT
        )
        vstore(cv[1], out, 1)
        vstore(cv[2], out, 5)
    else
        # ---------------------------------------------------------------------------------
        # Extended case, produce however many bits' the caller wants.
        todo    = length(out)
        offset  = 1
        counter = UInt64(0)

        # Handle the full 64 byte chunks.
        while todo >= 64
            todo -= 64
            compress_xof(
                self.chaining,
                self.block,
                self.block_len,
                counter,
                self.flags | ROOT,
                out, offset
            )
            offset  += 64
            counter += 1
        end

        # Handle the last few bytes.
        if todo > 0
            buffer = Vector{UInt8}(undef, 64)
            compress_xof(
                self.chaining,
                self.block,
                self.block_len,
                counter,
                self.flags | ROOT,
                buffer, 1
            )
            copyto!(out, offset, buffer, 1, todo)
        end
    end
    nothing
end
