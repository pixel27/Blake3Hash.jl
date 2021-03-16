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

mutable struct ChunkState
    chaining::CHAINING
    chunks::UInt64
    block::Buffer{MVector{64, UInt8}}
    blocks::Int
    flags::UInt32
end

function ChunkState(
            key::CHAINING,
            chunks::UInt64,
            flags::UInt32
        )::ChunkState
    return ChunkState(key, chunks, Buffer(), 0, flags)
end

function clear(
            cs::ChunkState,
            key::CHAINING,
            chunks::UInt64,
            flags::UInt32
        )::Nothing
    cs.chaining = key
    cs.chunks   = chunks
    cs.blocks   = 0
    cs.flags    = flags
    clear(cs.block)
    nothing
end

function Base.length(
            cs::ChunkState
        )::UInt
    return BLOCK_LEN * cs.blocks + length(cs.block)
end

function flags(
            cs::ChunkState
        )::UInt32
    return cs.blocks == 0 ? (CHUNK_START | cs.flags) : (cs.flags)
end

function fill(
            cs::ChunkState,
            input::Buffer
        )::Nothing
    bytes = min(remaining(cs.block), remaining(input))
    @inbounds copyto!(
        view(cs.block, bytes), 1,
        view(input, bytes), 1,
        bytes
    )
    nothing
end

function fill_and_complete(
            cs::ChunkState,
            input::Buffer
        )::Output

    if remaining(cs.block) > 0
        offset = fill(cs, input)
    end

    return Output(
        cs.chaining,
        as_block(cs.block),
        UInt32(BLOCK_LEN),
        cs.chunks,
        flags(cs) | CHUNK_END
    )
end

function fill_and_compress(
            cs::ChunkState,
            input::Buffer
        )::Nothing
    if remaining(cs.block) > 0
        offset = fill(cs, input)
    end

    cs.chaining = compress(
        cs.chaining,
        as_block(cs.block),
        UInt32(BLOCK_LEN),
        cs.chunks,
        flags(cs)
    )
    cs.blocks += 1
    clear(cs.block)
    nothing
end

function compress(
            cs::ChunkState,
            input::Buffer
        )::Nothing
    cs.chaining = compress(
        cs.chaining,
        block_view(input),
        UInt32(BLOCK_LEN),
        cs.chunks,
        flags(cs)
    )
    cs.blocks += 1
    nothing
end

function complete(
            cs::ChunkState,
            input::Buffer
        )::Output
    return Output(
        cs.chaining,
        block_view(input),
        UInt32(BLOCK_LEN),
        cs.chunks,
        flags(cs) | CHUNK_END
    )
end

function complete(
            cs::ChunkState
        )::Output
    return Output(
        cs.chaining,
        as_block(cs.block),
        length(cs.block),
        cs.chunks,
        flags(cs) | CHUNK_END
    )
end

function update(
            cs::ChunkState,
            input::Buffer
        )::Union{Output, Nothing}

    # Not enough to process, copy the bytes to our buffer and return.
    if remaining(input) <= remaining(cs.block)
        fill(cs, input)
        return nothing
    end

    # If we have data in our buffer and we're on the last block complete it.
    if length(cs.block) > 0 && cs.blocks == 15
        return fill_and_complete(cs, input)
    end

    # If we have data in our buffer, compress that.
    if length(cs.block) > 0
        fill_and_compress(cs, input)
    end

    # Process while we have MORE than a full block but NOT a full chunk.
    while cs.blocks < 15 && remaining(input) > BLOCK_LEN
        compress(cs, input)
    end

    # If we have MORE data than a full block, then we can complete the current chunk.
    if remaining(input) > BLOCK_LEN
        return complete(cs, input)
    end

    # If there is still data remaining save it.
    if remaining(input) > 0
        fill(cs, input)
    end

    return nothing
end
