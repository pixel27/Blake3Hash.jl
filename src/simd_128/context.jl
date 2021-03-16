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

function words_from_le_bytes_8(
            bytes::AbstractVector{UInt8}
        )::SVector{8, UInt32}
    local data  = view(bytes, 1:(length(bytes) & ~0x3))
    local words = reinterpret(UInt32, data)
    return SVector{8, UInt32}(
        length(words) >= 1 ? ltoh(words[1]) : UInt32(0),
        length(words) >= 2 ? ltoh(words[2]) : UInt32(0),
        length(words) >= 3 ? ltoh(words[3]) : UInt32(0),
        length(words) >= 4 ? ltoh(words[4]) : UInt32(0),
        length(words) >= 5 ? ltoh(words[5]) : UInt32(0),
        length(words) >= 6 ? ltoh(words[6]) : UInt32(0),
        length(words) >= 7 ? ltoh(words[7]) : UInt32(0),
        length(words) >= 8 ? ltoh(words[8]) : UInt32(0)
    )
end

function parent_output(
            left::CHAINING,
            right::CHAINING,
            key::CHAINING,
            flags::UInt32
        )::Output
    return Output(
        key,
        BLOCK((left[1], left[2], right[1], right[2])),
        UInt32(BLOCK_LEN),
        0,
        PARENT | flags
    )
end

function parent_cv(
            left_child_cv::CHAINING,
            right_child_cv::CHAINING,
            key::CHAINING,
            flags::UInt32
        )::CHAINING
    return chaining_value(parent_output(left_child_cv, right_child_cv, key, flags))
end

mutable struct Blake3Ctx
    chunk_state::ChunkState
    key::CHAINING
    cv_stack::Vector{CHAINING}
    cv_stack_len::UInt8
    flags::UInt32

    """
        Blake3Ctx(key::AbstractVector{UInt32}=IV, flags::UInt32=UInt32(0))

    Create a new hasher using the specified key.  The key must be 8 values.  Normally this
    method is called with the default values.

    # Examples
    ```
    h = Blake3Ctx()
    update!(h, rand(UInt8, 1024))
    r = digest(h)
    println("Hash => \$(bytes2hex(r))")
    ```
    """
    Blake3Ctx(
                key::AbstractVector{UInt32}=IV,
                flags::UInt32=UInt32(0)
            ) = begin
        length(key) != 8 && throw("Key length must be 8.")
        local skey = CHAINING((
            VECTOR((key[1], key[2], key[3], key[4])),
            VECTOR((key[5], key[6], key[7], key[8]))
        ))

        return new(
            ChunkState(skey, UInt64(0), flags),
            skey,
            Vector{CHAINING}(undef, 54),
            0,
            flags
        )
    end

    """
        Blake3Ctx(key::AbstractVector{UInt8})

    Create a Blake3Ctx instance to perform a keyed hash on the data.  Only the first 32 bytes
    are used.

    # Examples
    ```
    h = Blake3Ctx([x for x in UInt8(1):UInt8(32)])
    update!(h, rand(UInt8, 1024))
    r = digest(h)
    println("Hash => \$(bytes2hex(r))")
    ```
    """
    Blake3Ctx(key::AbstractVector{UInt8}) = Blake3Ctx(words_from_le_bytes_8(key), KEYED_HASH)

    """
        Blake3Ctx(content::AbstractString)

    Create a Blake3Ctx instance to perform a derived hash on the data.  The string is hashed
    and the result of the string is then used as the key for the hash.

    # Examples
    ```
    h = Blake3Ctx("My hash context")
    update!(h, rand(UInt8, 1024))
    r = digest(h)
    println("Hash => \$(bytes2hex(r))")
    ```
    """
    Blake3Ctx(content::AbstractString) = begin
        local context_hasher = Blake3Ctx(IV, DERIVE_KEY_CONTEXT)
        update!(context_hasher, Vector{UInt8}(content))

        local context_key = Vector{UInt8}(undef, KEY_LEN)
        digest(context_hasher, context_key)

        local context_key_words = words_from_le_bytes_8(context_key)
        return Blake3Ctx(context_key_words, DERIVE_KEY_MATERIAL)
    end
end

function push_stack(self::Blake3Ctx, cv::CHAINING)::Nothing
    self.cv_stack_len += 1
    self.cv_stack[self.cv_stack_len] = cv
    nothing
end

function pop_stack(self::Blake3Ctx)::CHAINING
    self.cv_stack_len -= 1
    return self.cv_stack[self.cv_stack_len+1]
end

# Section 5.1.2 of the BLAKE3 spec explains this algorithm in more detail.
function add_chunk_chaining_value(
            self::Blake3Ctx,
            new_cv::CHAINING,
            total_chunks::UInt64
        )::Nothing
    # This chunk might complete some subtrees. For each completed subtree,
    # its left child will be the current top entry in the CHAINING stack, and
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
    update!(self::Blake3Ctx, input::AbstractVector{UInt8}, datalen=length(input))::Nothing

Hash more data.  This method can be called multiple times until all the data has been
hashed.
"""
function update!(
            self::Blake3Ctx,
            input::AbstractVector{UInt8},
            datalen=length(input)
        )::Nothing
    input = Buffer(view(input, 1:datalen))

    while remaining(input) > 0
        output = update(self.chunk_state, input)

        if output !== nothing
            local chunk_cv     = chaining_value(output)
            local total_chunks = self.chunk_state.chunks + 1
            add_chunk_chaining_value(self, chunk_cv, total_chunks)
            clear(self.chunk_state, self.key, total_chunks, self.flags)
        end
    end
end

"""
    digest(self::Blake3Ctx, out_slice::AbstractArray{UInt8})::Nothing

Generate the hash and write it to the provided array.  The contents of out_slice will be
overwritten.

__Details:__

Normally you would pass in an array of 32 bytes which the method will fill with the hash.
However if you want more (or less) bytes you can pass in a an array of a different size.
"""
function digest(self::Blake3Ctx, out_slice::AbstractArray{UInt8})::Nothing
    # Starting with the Output from the current chunk, compute all the
    # parent chaining values along the right edge of the tree, until we
    # have the root Output.
    local out                    = complete(self.chunk_state)
    local parent_nodes_remaining = UInt(self.cv_stack_len)

    while parent_nodes_remaining > 0
        out = parent_output(
            self.cv_stack[parent_nodes_remaining],
            chaining_value(out),
            self.key,
            self.flags
        )
        parent_nodes_remaining -= 1
    end
    hash(out, out_slice)
end

"""
    digest(self::Blake3Ctx, bytes=32)::Vector{UInt8}

Generate the hash and return it.

__Details:__

Normally you would want 32 bytes back (256bits) but you can have it return more or less
bytes based on your need.
"""
function digest(self::Blake3Ctx, bytes=32)::Vector{UInt8}
    local output = Vector{UInt8}(undef, bytes)
    digest(self, output)
    return output
end
