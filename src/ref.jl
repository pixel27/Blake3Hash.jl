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

"""
This is the reference implmentation of the BLAKE3 algorithm done in Julia.  No attempt has
been made to improve the performance it's primarly purpose is to be easy to read and used
to debug/verify faster implmentations.
"""
module RefImpl

using Base.Iterators

const OUT_LEN = UInt(32)
const KEY_LEN = UInt(32)
const BLOCK_LEN = UInt(64)
const CHUNK_LEN = UInt(1024)

const CHUNK_START = UInt32(1) << 0
const CHUNK_END   = UInt32(1) << 1
const PARENT      = UInt32(1) << 2
const ROOT        = UInt32(1) << 3
const KEYED_HASH  = UInt32(1) << 4
const DERIVE_KEY_CONTEXT  = UInt32(1) << 5
const DERIVE_KEY_MATERIAL = UInt32(1) << 6

const IV = [
    UInt32(0x6A09E667), UInt32(0xBB67AE85), UInt32(0x3C6EF372), UInt32(0xA54FF53A),
    UInt32(0x510E527F), UInt32(0x9B05688C), UInt32(0x1F83D9AB), UInt32(0x5BE0CD19)
]

const MSG_PERMUTATION = [ 2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8 ]


function g(state::AbstractVector{UInt32}, a::Int, b::Int, c::Int, d::Int, mx::UInt32, my::UInt32)::Nothing
    state[a] = state[a] + state[b] + mx;
    state[d] = bitrotate(state[d] ⊻ state[a], -16)
    state[c] = state[c] + state[d]
    state[b] = bitrotate(state[b] ⊻ state[c], -12)
    state[a] = state[a] + state[b] + my
    state[d] = bitrotate(state[d] ⊻ state[a], -8)
    state[c] = state[c] + state[d]
    state[b] = bitrotate(state[b] ⊻ state[c], -7)
    nothing
end

function round(state::AbstractVector{UInt32}, m::AbstractVector{UInt32})::Nothing
    # Mix the columns
    g(state, 1, 5,  9, 13, m[1], m[2])
    g(state, 2, 6, 10, 14, m[3], m[4])
    g(state, 3, 7, 11, 15, m[5], m[6])
    g(state, 4, 8, 12, 16, m[7], m[8])
    # Mix the diagonals
    g(state, 1, 6, 11, 16, m[9],  m[10])
    g(state, 2, 7, 12, 13, m[11], m[12])
    g(state, 3, 8,  9, 14, m[13], m[14])
    g(state, 4, 5, 10, 15, m[15], m[16])
    nothing
end

function permute(m::AbstractVector{UInt32})::Nothing
    local permuted = Vector{UInt32}(undef, 16)

    for i in 1:16
        permuted[i] = m[MSG_PERMUTATION[i]+1]
    end
    copyto!(m, permuted)
    nothing
end

function compress(
            chaining_value::AbstractVector{UInt32},
            block_words::AbstractVector{UInt32},
            counter::UInt64,
            block_len::UInt32,
            flags::UInt32
        )::AbstractVector{UInt32}
    local state = [
        chaining_value[1], chaining_value[2], chaining_value[3], chaining_value[4],
        chaining_value[5], chaining_value[6], chaining_value[7], chaining_value[8],
        IV[1], IV[2], IV[3], IV[4],
        UInt32(counter & 0xffffffff), UInt32(counter >> 32),
        block_len, flags
    ]
    local block = copy(block_words)

    round(state, block) # round 1
    permute(block)
    round(state, block) # round 2
    permute(block)
    round(state, block) # round 3
    permute(block)
    round(state, block) # round 4
    permute(block)
    round(state, block) # round 5
    permute(block)
    round(state, block) # round 6
    permute(block)
    round(state, block) # round 7

    for i in 1:8
        state[i] ⊻= state[i + 8]
        state[i + 8] ⊻= chaining_value[i]
    end

    return state
end

function first_8_words(compression_output::AbstractVector{UInt32})::Vector{UInt32}
    return [
        compression_output[1], compression_output[2],
        compression_output[3], compression_output[4],
        compression_output[5], compression_output[6],
        compression_output[7], compression_output[8]
    ]
end

function words_from_little_endian_bytes(bytes::AbstractVector{UInt8}, words::Vector{UInt32})
    for (byte_block, i) in zip(partition(bytes, 4), eachindex(words))
        words[i] = ltoh(reinterpret(UInt32, byte_block)[1])
    end
end

struct Output
    input_chaining_value::Vector{UInt32}
    block_words::Vector{UInt32}
    counter::UInt64
    block_len::UInt32
    flags::UInt32
end

function chaining_value(self::Output)::Vector{UInt32}
    return first_8_words(compress(
        self.input_chaining_value,
        self.block_words,
        self.counter,
        self.block_len,
        self.flags
    ))
end

function root_output_bytes(self::Output, out_slice::AbstractVector{UInt8})::Nothing
    local output_block_counter = UInt64(0)

    for out_block in partition(out_slice, 2 * OUT_LEN)
        local words = compress(
            self.input_chaining_value,
            self.block_words,
            output_block_counter,
            self.block_len,
            self.flags | ROOT
        )
        for (word, out_word) in zip(words, partition(out_block, 4))
            out_word[1] = UInt8(word & 0xff)
            if length(out_word) >= 2
                out_word[2] = UInt8((word >> 8) & 0xff)
            end
            if length(out_word) >= 3
                 out_word[3] = UInt8((word >> 16) & 0xff)
            end
            if length(out_word) >= 4
                out_word[4] = UInt8((word >> 24) & 0xff)
            end
        end
        output_block_counter += 1
    end
    nothing
end

mutable struct ChunkState
    chaining_value::Vector{UInt32}
    chunk_counter::UInt64
    block::Vector{UInt8}
    block_len::UInt8
    blocks_compressed::UInt8
    flags::UInt32
end

function ChunkState(key::AbstractVector{UInt32}, chunk_counter::UInt64, flags::UInt32)::ChunkState
    return ChunkState(key, chunk_counter, zeros(UInt8, BLOCK_LEN), 0, 0, flags)
end

function len(self::ChunkState)::UInt
    return BLOCK_LEN * UInt(self.blocks_compressed) + UInt(self.block_len)
end

function start_flag(self::ChunkState)::UInt32
    if self.blocks_compressed == 0
        return CHUNK_START
    end

    return 0
end

function update(self::ChunkState, input::AbstractVector{UInt8})::Nothing
    local data = view(input, 1:length(input))

    while isempty(data) == false
        # If the block buffer is full, compress it and clear it. More
        # input is coming, so this compression is not CHUNK_END.

        if UInt(self.block_len) == BLOCK_LEN
            local block_words = zeros(UInt32, 16)
            words_from_little_endian_bytes(self.block, block_words)
            self.chaining_value = first_8_words(compress(
                self.chaining_value,
                block_words,
                self.chunk_counter,
                UInt32(BLOCK_LEN),
                self.flags | start_flag(self)
            ))
            self.blocks_compressed += UInt8(1)
            self.block = zeros(UInt8, BLOCK_LEN)
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
    local block_words = zeros(UInt32, 16)

    words_from_little_endian_bytes(self.block, block_words)

    return Output(
        self.chaining_value,
        block_words,
        self.chunk_counter,
        self.block_len,
        self.flags | start_flag(self) | CHUNK_END
    )
end

function parent_output(
            left_child_cv::AbstractVector{UInt32},
            right_child_cv::AbstractVector{UInt32},
            key::AbstractVector{UInt32},
            flags::UInt32
        )::Output
    local block_words = vcat(left_child_cv, right_child_cv)

    return Output(key, block_words, 0, UInt32(BLOCK_LEN), PARENT | flags)
end

function parent_cv(
            left_child_cv::AbstractVector{UInt32},
            right_child_cv::AbstractVector{UInt32},
            key::AbstractVector{UInt32},
            flags::UInt32
        )::Vector{UInt32}
    return chaining_value(parent_output(left_child_cv, right_child_cv, key, flags))
end

mutable struct Hasher
    chunk_state::ChunkState
    key::Vector{UInt32}
    cv_stack::Array{UInt32, 2}
    cv_stack_len::UInt8
    flags::UInt32
    Hasher(key::Vector{UInt32}=IV, flags::UInt32=UInt32(0)) = new(
        ChunkState(key, UInt64(0), flags), key, Array{UInt32}(undef, 8, 54), 0, flags
    )
    Hasher(key::Vector{UInt8}) = begin
        local key_words = zeros(UInt32, 8)
        words_from_little_endian_bytes(key, key_words)
        return Hasher(key_words, KEYED_HASH)
    end
    Hasher(content::AbstractString) = begin
        local context_hasher = Hasher(IV, DERIVE_KEY_CONTEXT)
        update!(context_hasher, Vector{UInt8}(content))
        local context_key = zeros(UInt8, KEY_LEN)
        digest(context_hasher, context_key)
        local context_key_words = zeros(UInt32, 8)
        words_from_little_endian_bytes(context_key, context_key_words)
        return Hasher(context_key_words, DERIVE_KEY_MATERIAL)
    end
end

function push_stack(self::Hasher, cv::AbstractVector{UInt32})::Nothing
    self.cv_stack_len += 1
    self.cv_stack[:, self.cv_stack_len] .= cv
    nothing
end

function pop_stack(self::Hasher)::Vector{UInt32}
    self.cv_stack_len -= 1
    return self.cv_stack[:, self.cv_stack_len+1]
end

# Section 5.1.2 of the BLAKE3 spec explains this algorithm in more detail.
function add_chunk_chaining_value(
            self::Hasher,
            new_cv::AbstractVector{UInt32},
            total_chunks::UInt64
        )::Nothing
    # This chunk might complete some subtrees. For each completed subtree,
    # its left child will be the current top entry in the CV stack, and
    # its right child will be the current value of `new_cv`. Pop each left
    # child off the stack, merge it with `new_cv`, and overwrite `new_cv`
    # with the result. After all these merges, push the final value of
    # `new_cv` onto the stack. The number of completed subtrees is given
    # by the number of trailing 0-bits in the new total number of chunks.
    while total_chunks & 1 == 0
        new_cv = parent_cv(pop_stack(self), new_cv, self.key, self.flags)
        total_chunks = total_chunks >> 1;
    end
    push_stack(self, new_cv)
    nothing
end

"""
    update!(self::Hasher, input::AbstractVector{UInt8}, datalen=length(input))::Nothing

Hash more data.  This method can be called multiple times until all the data has been
hashed.
"""
function update!(self::Hasher, input::AbstractVector{UInt8}, datalen=length(input))::Nothing
    local data = view(input, 1:datalen)

    while isempty(data) == false
        # If the current chunk is complete, finalize it and reset the
        # chunk state. More input is coming, so this chunk is not ROOT.
        if len(self.chunk_state) == CHUNK_LEN
            local chunk_cv     = chaining_value(output(self.chunk_state))
            local total_chunks = self.chunk_state.chunk_counter + 1
            add_chunk_chaining_value(self, chunk_cv, total_chunks)
            self.chunk_state = ChunkState(self.key, total_chunks, self.flags)
        end

        # Compress input bytes into the current chunk state.
        local want = CHUNK_LEN - len(self.chunk_state)
        local take = min(want, length(data))
        update(self.chunk_state, view(data, 1:take))
        data = view(data, (take+1):length(data))
    end
end

"""
    digest(self::Hasher, out_slice::AbstractArray{UInt8})::Nothing

Generate the hash and write it to the provided array.  The contents of out_slice will be
overwritten.

__Details:__

Normally you would pass in an array of 32 bytes which the method will fill with the hash.
However if you want more (or less) bytes you can pass in a an array of a different size.
"""
function digest(self::Hasher, out_slice::AbstractArray{UInt8})::Nothing
    # Starting with the Output from the current chunk, compute all the
    # parent chaining values along the right edge of the tree, until we
    # have the root Output.
    local out                    = output(self.chunk_state)
    local parent_nodes_remaining = UInt(self.cv_stack_len)

    while parent_nodes_remaining > 0
        parent_nodes_remaining -= 1
        out = parent_output(
            self.cv_stack[:, parent_nodes_remaining+1],
            chaining_value(out),
            self.key,
            self.flags
        )
    end
    root_output_bytes(out, out_slice)
end

"""
    digest(self::Hasher, bytes=32)::Vector{UInt8}

Generate the hash and return it.

__Details:__

Normally you would want 32 bytes back (256bits) but you can have it return more or less
bytes based on your need.
"""
function digest(self::Hasher, bytes=32)::Vector{UInt8}
    local output = Vector{UInt8}(undef, bytes)
    digest(self, output)
    return output
end

end