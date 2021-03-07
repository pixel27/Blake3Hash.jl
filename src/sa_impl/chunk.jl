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

function words_from_le_bytes_16(
            bytes::AbstractVector{UInt8}
        )::SVector{16, UInt32}
    local words = reinterpret(UInt32, bytes)
    return SVector{16, UInt32}(
        ltoh(words[1]),  ltoh(words[2]),  ltoh(words[3]),  ltoh(words[4]),
        ltoh(words[5]),  ltoh(words[6]),  ltoh(words[7]),  ltoh(words[8]),
        ltoh(words[9]),  ltoh(words[10]), ltoh(words[11]), ltoh(words[12]),
        ltoh(words[13]), ltoh(words[14]), ltoh(words[15]), ltoh(words[16])
    )
end

mutable struct ChunkState
    chaining_value::SVector{8, UInt32}
    chunk_counter::UInt64
    block::Vector{UInt8}
    block_len::UInt8
    blocks_compressed::UInt8
    flags::UInt32
end

function ChunkState(
            key::SVector{8, UInt32},
            chunk_counter::UInt64,
            flags::UInt32
        )::ChunkState
    return ChunkState(key, chunk_counter, zeros(UInt8, BLOCK_LEN), 0, 0, flags)
end

function reset(
            self::ChunkState,
            key::SVector{8, UInt32},
            chunk_counter::UInt64,
            flags::UInt32
        )::Nothing
    self.chaining_value    = key
    self.chunk_counter     = chunk_counter
    self.block_len         = 0
    self.blocks_compressed = 0
    self.flags             = flags
    fill!(self.block, UInt8(0))
    nothing
end

function len(
            self::ChunkState
        )::UInt
    return BLOCK_LEN * UInt(self.blocks_compressed) + UInt(self.block_len)
end

function start_flag(
            self::ChunkState
        )::UInt32
    if self.blocks_compressed == 0
        return CHUNK_START
    end

    return 0
end

function update(
            self::ChunkState,
            input::AbstractVector{UInt8}
        )::Nothing
    local data = view(input, 1:length(input))

    while isempty(data) == false
        # If the block buffer is full, compress it and clear it. More
        # input is coming, so this compression is not CHUNK_END.

        if UInt(self.block_len) == BLOCK_LEN
            self.chaining_value = first_8_words(compress(
                self.chaining_value,
                words_from_le_bytes_16(self.block),
                self.chunk_counter,
                UInt32(BLOCK_LEN),
                self.flags | start_flag(self)
            ))
            self.blocks_compressed += UInt8(1)
            fill!(self.block, UInt8(0))
            self.block_len = 0
        end

        local want = BLOCK_LEN - UInt(self.block_len)
        local take = min(want, length(data))
        copyto!(self.block, self.block_len+1, data, 1, take)
        self.block_len += UInt8(take)
        data = view(data, (take+1):length(data))
    end
end

function output(self::ChunkState)::Output
    return Output(
        self.chaining_value,
        words_from_le_bytes_16(self.block),
        self.chunk_counter,
        self.block_len,
        self.flags | start_flag(self) | CHUNK_END
    )
end
