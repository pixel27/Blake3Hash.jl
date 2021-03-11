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

@inline function ltoh_array(block::AbstractVector{UInt32})::SVector{16, UInt32}
    @inbounds return SVector{16, UInt32}(
        ltoh(block[1]),  ltoh(block[2]),  ltoh(block[3]),  ltoh(block[4]),
        ltoh(block[5]),  ltoh(block[6]),  ltoh(block[7]),  ltoh(block[8]),
        ltoh(block[9]),  ltoh(block[10]), ltoh(block[11]), ltoh(block[12]),
        ltoh(block[13]), ltoh(block[14]), ltoh(block[15]), ltoh(block[16])
    )
end

@inline function ltoh_array(input::AbstractVector{UInt8}, offset::Int)::SVector{16, UInt32}
    block = reinterpret(UInt32, view(input, offset:(offset+BLOCK_LEN-1)))

    return ltoh_array(block)
end

mutable struct ChunkState
    chaining_value::SVector{8, UInt32}
    chunk_counter::UInt64
    block::Vector{UInt32}
    block_len::Int
    blocks_compressed::Int
    flags::UInt32
end

function ChunkState(
            key::SVector{8, UInt32},
            chunk_counter::UInt64,
            flags::UInt32
        )::ChunkState
    return ChunkState(key, chunk_counter, zeros(UInt32, BLOCK_LEN÷4), 0, 0, flags)
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

@inline function data(
            self::ChunkState
        )::UInt
    return BLOCK_LEN * self.blocks_compressed + self.block_len
end

@inline function start_flag(
            self::ChunkState
        )::UInt32
    if self.blocks_compressed == 0
        return CHUNK_START
    end

    return 0
end

@inline function update_buffer(
            self::ChunkState,
            input::AbstractVector{UInt8},
            offset::Int
        )::Int
    bytes  = min(BLOCK_LEN - self.block_len, length(input) - offset + 1)

    @inbounds copyto!(reinterpret(UInt8, self.block), self.block_len+1, input, offset, bytes)

    self.block_len += bytes

    return offset + bytes
end

@inline function update_buffer_and_complete(
            self::ChunkState,
            input::AbstractVector{UInt8},
            offset::Int
        )::Tuple{Int, Output}
    if self.block_len < BLOCK_LEN
        offset = update_buffer(self, input, offset)
    end

    return (offset, Output(
        self.chaining_value,
        ltoh_array(self.block),
        self.chunk_counter,
        UInt32(BLOCK_LEN),
        self.flags | start_flag(self) | CHUNK_END
    ))
end

@inline function update_buffer_and_compress(
            self::ChunkState,
            input::AbstractVector{UInt8},
            offset::Int
        )::Int
    if self.block_len < BLOCK_LEN
        offset = update_buffer(self, input, offset)
    end

    self.chaining_value = first_8_words(compress(
        self.chaining_value,
        ltoh_array(self.block),
        self.chunk_counter,
        UInt32(BLOCK_LEN),
        self.flags | start_flag(self)
    ))
    self.blocks_compressed += 1
    fill!(self.block, 0)
    self.block_len = 0

    return offset
end

@inline function update_compress(
            self::ChunkState,
            input::AbstractVector{UInt8},
            offset::Int
        )::Int
    self.chaining_value = first_8_words(compress(
        self.chaining_value,
        ltoh_array(input, offset),
        self.chunk_counter,
        UInt32(BLOCK_LEN),
        self.flags | start_flag(self)
    ))
    self.blocks_compressed += 1

    return offset + BLOCK_LEN
end

@inline function update_complete(
            self::ChunkState,
            input::AbstractVector{UInt8},
            offset::Int
        )::Tuple{Int, Output}
    return (offset + BLOCK_LEN, Output(
        self.chaining_value,
        ltoh_array(input, offset),
        self.chunk_counter,
        UInt32(BLOCK_LEN),
        self.flags | start_flag(self) | CHUNK_END
    ))
end

function update(
            self::ChunkState,
            input::AbstractVector{UInt8},
            offset::Int
        )::Tuple{Int, Union{Output, Nothing}}

    # Not enough to process, copy the bytes to our buffer and return.
    if length(input) - offset < BLOCK_LEN - self.block_len
        return (update_buffer(self, input, offset), nothing)
    end

    # If we have data in our buffer and we're on the last block complete it.
    if self.block_len > 0 && self.blocks_compressed == 15
        return update_buffer_and_complete(self, input, offset)
    end

    # If we have data in our buffer, complete that.
    if self.block_len > 0
        offset = update_buffer_and_compress(self, input, offset)
    end

    # Process while we have MORE than a full block but NOT a full chunk.
    while self.blocks_compressed < 15 && length(input) - offset >= BLOCK_LEN
        offset = update_compress(self, input, offset)
    end

    # If we have MORE data than a full block, then we can complete the current chunk.
    if length(input) - offset >= BLOCK_LEN
        return update_complete(self, input, offset)
    end

    # If there is still data remaining save it.
    if offset <= length(input)
        offset = update_buffer(self, input, offset)
    end

    return (offset, nothing)
end

function complete(self::ChunkState)::Output
    return Output(
        self.chaining_value,
        ltoh_array(self.block),
        self.chunk_counter,
        self.block_len,
        self.flags | start_flag(self) | CHUNK_END
    )
end
