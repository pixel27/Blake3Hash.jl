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
using StaticArrays

const IV = SVector(
    UInt32(0x6A09E667), UInt32(0xBB67AE85), UInt32(0x3C6EF372), UInt32(0xA54FF53A),
    UInt32(0x510E527F), UInt32(0x9B05688C), UInt32(0x1F83D9AB), UInt32(0x5BE0CD19)
)

function g_1_5_9_13(input::SVector{16, UInt32}, mx::UInt32, my::UInt32)::SVector{16, UInt32}
    local a = input[1]
    local b = input[5]
    local c = input[9]
    local d = input[13]

    a = a + b + mx
    d = bitrotate(d ⊻ a, -16)
    c = c + d
    b = bitrotate(b ⊻ c, -12)

    a = a + b + my
    d = bitrotate(d ⊻ a, -8)
    c = c + d
    b = bitrotate(b ⊻ c, -7)

    return SVector(
        a, input[2],  input[3],  input[4],
        b, input[6],  input[7],  input[8],
        c, input[10], input[11], input[12],
        d, input[14], input[15], input[16]
    )
end

function g_2_6_10_14(input::SVector{16, UInt32}, mx::UInt32, my::UInt32)::SVector{16, UInt32}
    local a = input[2]
    local b = input[6]
    local c = input[10]
    local d = input[14]

    a = a + b + mx
    d = bitrotate(d ⊻ a, -16)
    c = c + d
    b = bitrotate(b ⊻ c, -12)

    a = a + b + my
    d = bitrotate(d ⊻ a, -8)
    c = c + d
    b = bitrotate(b ⊻ c, -7)

    return SVector(
        input[1],  a,  input[3],  input[4],
        input[5],  b,  input[7],  input[8],
        input[9],  c, input[11], input[12],
        input[13], d, input[15], input[16]
    )
end

function g_3_7_11_15(input::SVector{16, UInt32}, mx::UInt32, my::UInt32)::SVector{16, UInt32}
    local a = input[3]
    local b = input[7]
    local c = input[11]
    local d = input[15]

    a = a + b + mx
    d = bitrotate(d ⊻ a, -16)
    c = c + d
    b = bitrotate(b ⊻ c, -12)

    a = a + b + my
    d = bitrotate(d ⊻ a, -8)
    c = c + d
    b = bitrotate(b ⊻ c, -7)

    return SVector(
        input[1],  input[2],  a, input[4],
        input[5],  input[6],  b, input[8],
        input[9],  input[10], c, input[12],
        input[13], input[14], d, input[16]
    )
end

function g_4_8_12_16(input::SVector{16, UInt32}, mx::UInt32, my::UInt32)::SVector{16, UInt32}
    local a = input[4]
    local b = input[8]
    local c = input[12]
    local d = input[16]

    a = a + b + mx
    d = bitrotate(d ⊻ a, -16)
    c = c + d
    b = bitrotate(b ⊻ c, -12)

    a = a + b + my
    d = bitrotate(d ⊻ a, -8)
    c = c + d
    b = bitrotate(b ⊻ c, -7)

    return SVector(
        input[1],  input[2],  input[3],  a,
        input[5],  input[6],  input[7],  b,
        input[9],  input[10], input[11], c,
        input[13], input[14], input[15], d
    )
end

function g_1_6_11_16(input::SVector{16, UInt32}, mx::UInt32, my::UInt32)::SVector{16, UInt32}
    local a = input[1]
    local b = input[6]
    local c = input[11]
    local d = input[16]

    a = a + b + mx
    d = bitrotate(d ⊻ a, -16)
    c = c + d
    b = bitrotate(b ⊻ c, -12)

    a = a + b + my
    d = bitrotate(d ⊻ a, -8)
    c = c + d
    b = bitrotate(b ⊻ c, -7)

    return SVector(
        a,         input[2],  input[3],  input[4],
        input[5],  b,         input[7],  input[8],
        input[9],  input[10], c,         input[12],
        input[13], input[14], input[15], d
    )
end

function g_2_7_12_13(input::SVector{16, UInt32}, mx::UInt32, my::UInt32)::SVector{16, UInt32}
    local a = input[2]
    local b = input[7]
    local c = input[12]
    local d = input[13]

    a = a + b + mx
    d = bitrotate(d ⊻ a, -16)
    c = c + d
    b = bitrotate(b ⊻ c, -12)

    a = a + b + my
    d = bitrotate(d ⊻ a, -8)
    c = c + d
    b = bitrotate(b ⊻ c, -7)

    return SVector(
        input[1],  a,         input[3],  input[4],
        input[5],  input[6],  b,         input[8],
        input[9],  input[10], input[11], c,
        d,         input[14], input[15], input[16]
    )
end

function g_3_8_9_14(input::SVector{16, UInt32}, mx::UInt32, my::UInt32)::SVector{16, UInt32}
    local a = input[3]
    local b = input[8]
    local c = input[9]
    local d = input[14]

    a = a + b + mx
    d = bitrotate(d ⊻ a, -16)
    c = c + d
    b = bitrotate(b ⊻ c, -12)

    a = a + b + my
    d = bitrotate(d ⊻ a, -8)
    c = c + d
    b = bitrotate(b ⊻ c, -7)

    return SVector(
        input[1],  input[2],  a,         input[4],
        input[5],  input[6],  input[7],  b,
        c,         input[10], input[11], input[12],
        input[13], d,         input[15], input[16]
    )
end

function g_4_5_10_15(input::SVector{16, UInt32}, mx::UInt32, my::UInt32)::SVector{16, UInt32}
    local a = input[4]
    local b = input[5]
    local c = input[10]
    local d = input[15]

    a = a + b + mx
    d = bitrotate(d ⊻ a, -16)
    c = c + d
    b = bitrotate(b ⊻ c, -12)

    a = a + b + my
    d = bitrotate(d ⊻ a, -8)
    c = c + d
    b = bitrotate(b ⊻ c, -7)

    return SVector(
        input[1],  input[2],  input[3],  a,
        b,         input[6],  input[7],  input[8],
        input[9],  c,         input[11], input[12],
        input[13], input[14], d,         input[16]
    )
end


function round(state::SVector{16, UInt32}, m::SVector{16, UInt32})::SVector{16, UInt32}

    # Mix the columns
    state = g_1_5_9_13(state, m[1], m[2])
    state = g_2_6_10_14(state, m[3], m[4])
    state = g_3_7_11_15(state, m[5], m[6])
    state = g_4_8_12_16(state, m[7], m[8])
    # Mix the diagonals
    state = g_1_6_11_16(state, m[9],  m[10])
    state = g_2_7_12_13(state, m[11], m[12])
    state = g_3_8_9_14(state, m[13], m[14])
    state = g_4_5_10_15(state, m[15], m[16])

    return state
end

function permute(m::SVector{16, UInt32})::SVector{16, UInt32}
    return SVector(
        m[3],  m[7],  m[4],  m[11],
        m[8],  m[1],  m[5],  m[14],
        m[2],  m[12], m[13], m[6],
        m[10], m[15], m[16], m[9]
    )
end

function compress(
            chaining_value::SVector{8, UInt32},
            block::SVector{16, UInt32},
            counter::UInt64,
            block_len::UInt32,
            flags::UInt32
        )::SVector{16, UInt32}
    local state = SVector{16, UInt32}(
        chaining_value[1], chaining_value[2], chaining_value[3], chaining_value[4],
        chaining_value[5], chaining_value[6], chaining_value[7], chaining_value[8],
        IV[1], IV[2], IV[3], IV[4],
        UInt32(counter & 0xffffffff), UInt32(counter >> 32),
        block_len, flags
    )

    state = round(state, block) # round 1
    block = permute(block)
    state = round(state, block) # round 2
    block = permute(block)
    state = round(state, block) # round 3
    block = permute(block)
    state = round(state, block) # round 4
    block = permute(block)
    state = round(state, block) # round 5
    block = permute(block)
    state = round(state, block) # round 6
    block = permute(block)
    state = round(state, block) # round 7

    return SVector(
        state[1] ⊻ state[ 9], state[2] ⊻ state[10],
        state[3] ⊻ state[11], state[4] ⊻ state[12],
        state[5] ⊻ state[13], state[6] ⊻ state[14],
        state[7] ⊻ state[15], state[8] ⊻ state[16],
        state[ 9] ⊻ chaining_value[1], state[10] ⊻ chaining_value[2],
        state[11] ⊻ chaining_value[3], state[12] ⊻ chaining_value[4],
        state[13] ⊻ chaining_value[5], state[14] ⊻ chaining_value[6],
        state[15] ⊻ chaining_value[7], state[16] ⊻ chaining_value[8]
    )
end

