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

@inline function build_rows(
            input::CHAINING,
            counter::UInt64,
            block_len::UInt32,
            flags::UInt32
        )::MVector{4, VECTOR}
    return MVector{4, VECTOR}((
        input[1], input[2],
        VECTOR((IV[1], IV[2], IV[3], IV[4])),
        VECTOR((UInt32(counter & 0xffffffff), UInt32(counter >> 32),  block_len, flags))
    ))
end

@inline function build_m(
            input::AbstractArray{UInt32}
        )::MVector{4, VECTOR}
    @inbounds return MVector{4, VECTOR}((
        vload(VECTOR, input, 1),
        vload(VECTOR, input, 5),
        vload(VECTOR, input, 9),
        vload(VECTOR, input, 13)
    ))
end

@inline function build_m(
            input::BLOCK
        )::MVector{4, VECTOR}
    return MVector{4, VECTOR}((input[1], input[2], input[3], input[4]))
end

@inline function g1(
            rows::MVector{4, VECTOR},
            m::VECTOR
        )::Nothing
    rows[1] = rows[1] + m + rows[2]
    rows[4] = rows[4] ⊻ rows[1]
    rows[4] = rot16(rows[4])
    rows[3] = rows[3] + rows[4]
    rows[2] = rows[2] ⊻ rows[3]
    rows[2] = rot12(rows[2])
    nothing
end

@inline function g2(
            rows::MVector{4, VECTOR},
            m::VECTOR
        )::Nothing
    rows[1] = rows[1] + m + rows[2]
    rows[4] = rows[4] ⊻ rows[1]
    rows[4] = rot8(rows[4])
    rows[3] = rows[3]  + rows[4]
    rows[2] = rows[2] ⊻ rows[3]
    rows[2] = rot7(rows[2])
    nothing
end

@inline function diagonalize(
            rows::MVector{4, VECTOR}
        )::Nothing
    rows[1] = shuffle(rows[1], (2, 1, 0, 3))
    rows[4] = shuffle(rows[4], (1, 0, 3, 2))
    rows[3] = shuffle(rows[3], (0, 3, 2, 1))
    nothing
end

@inline function undiagonalize(
            rows::MVector{4, VECTOR}
        )::Nothing
    rows[1] = shuffle(rows[1], (0, 3, 2, 1))
    rows[4] = shuffle(rows[4], (1, 0, 3, 2))
    rows[3] = shuffle(rows[3], (2, 1, 0, 3))
    nothing
end

@inline function compress_pre(
            rows::MVector{4, VECTOR},
            m::MVector{4, VECTOR},
        )::Nothing
    # Round 1
    t0 = shuffle(m[1], m[2], (2, 0, 2, 0))
    g1(rows, t0)
    t1 = shuffle(m[1], m[2], (3, 1, 3, 1))
    g2(rows, t1)
    diagonalize(rows)
    t2 = shuffle(m[3], m[4], (2, 0, 2, 0))
    t2 = shuffle(t2, (2, 1, 0, 3))
    g1(rows, t2)
    t3 = shuffle(m[3], m[4], (3, 1, 3, 1))
    t3 = shuffle(t3, (2, 1, 0, 3))
    g2(rows, t3)
    undiagonalize(rows)
    m[1], m[2], m[3], m[4] = t0, t1, t2, t3

    # Round 2
    t0 = shuffle(m[1], m[2], (3, 1, 1, 2))
    t0 = shuffle(t0, (0, 3, 2, 1))
    g1(rows, t0)
    t1 = shuffle(m[3], m[4], (3, 3, 2, 2))
    tt = shuffle(m[1], (0, 0, 3, 3))
    t1 = blend(tt, t1, 0xcc)
    g2(rows, t1)
    diagonalize(rows)
    t2 = unpacklo_64(m[4], m[2])
    tt = blend(t2, m[3], 0xc0)
    t2 = shuffle(tt, (1, 3, 2, 0))
    g1(rows, t2)
    t3 = unpackhi_32(m[2], m[4])
    tt = unpacklo_32(m[3], t3)
    t3 = shuffle(tt, (0, 1, 3, 2))
    g2(rows, t3)
    undiagonalize(rows)
    m[1], m[2], m[3], m[4] = t0, t1, t2, t3

    # Round 3
    t0 = shuffle(m[1], m[2], (3, 1, 1, 2))
    t0 = shuffle(t0, (0, 3, 2, 1))
    g1(rows, t0)
    t1 = shuffle(m[3], m[4], (3, 3, 2, 2))
    tt = shuffle(m[1], (0, 0, 3, 3))
    t1 = blend(tt, t1, 0xcc)
    g2(rows, t1)
    diagonalize(rows)
    t2 = unpacklo_64(m[4], m[2])
    tt = blend(t2, m[3], 0xc0)
    t2 = shuffle(tt, (1, 3, 2, 0))
    g1(rows, t2)
    t3 = unpackhi_32(m[2], m[4])
    tt = unpacklo_32(m[3], t3)
    t3 = shuffle(tt, (0, 1, 3, 2))
    g2(rows, t3)
    undiagonalize(rows)
    m[1], m[2], m[3], m[4] = t0, t1, t2, t3

    # Round 4
    t0 = shuffle(m[1], m[2], (3, 1, 1, 2))
    t0 = shuffle(t0, (0, 3, 2, 1))
    g1(rows, t0)
    t1 = shuffle(m[3], m[4], (3, 3, 2, 2))
    tt = shuffle(m[1], (0, 0, 3, 3))
    t1 = blend(tt, t1, 0xcc)
    g2(rows, t1)
    diagonalize(rows)
    t2 = unpacklo_64(m[4], m[2])
    tt = blend(t2, m[3], 0xc0)
    t2 = shuffle(tt, (1, 3, 2, 0))
    g1(rows, t2)
    t3 = unpackhi_32(m[2], m[4])
    tt = unpacklo_32(m[3], t3)
    t3 = shuffle(tt, (0, 1, 3, 2))
    g2(rows, t3)
    undiagonalize(rows)
    m[1], m[2], m[3], m[4] = t0, t1, t2, t3

    # Round 5
    t0 = shuffle(m[1], m[2], (3, 1, 1, 2))
    t0 = shuffle(t0, (0, 3, 2, 1))
    g1(rows, t0)
    t1 = shuffle(m[3], m[4], (3, 3, 2, 2))
    tt = shuffle(m[1], (0, 0, 3, 3))
    t1 = blend(tt, t1, 0xcc)
    g2(rows, t1)
    diagonalize(rows)
    t2 = unpacklo_64(m[4], m[2])
    tt = blend(t2, m[3], 0xc0)
    t2 = shuffle(tt, (1, 3, 2, 0))
    g1(rows, t2)
    t3 = unpackhi_32(m[2], m[4])
    tt = unpacklo_32(m[3], t3)
    t3 = shuffle(tt, (0, 1, 3, 2))
    g2(rows, t3)
    undiagonalize(rows)
    m[1], m[2], m[3], m[4] = t0, t1, t2, t3

    # Round 6
    t0 = shuffle(m[1], m[2], (3, 1, 1, 2))
    t0 = shuffle(t0, (0, 3, 2, 1))
    g1(rows, t0)
    t1 = shuffle(m[3], m[4], (3, 3, 2, 2))
    tt = shuffle(m[1], (0, 0, 3, 3))
    t1 = blend(tt, t1, 0xcc)
    g2(rows, t1)
    diagonalize(rows)
    t2 = unpacklo_64(m[4], m[2])
    tt = blend(t2, m[3], 0xc0)
    t2 = shuffle(tt, (1, 3, 2, 0))
    g1(rows, t2)
    t3 = unpackhi_32(m[2], m[4])
    tt = unpacklo_32(m[3], t3)
    t3 = shuffle(tt, (0, 1, 3, 2))
    g2(rows, t3)
    undiagonalize(rows)
    m[1], m[2], m[3], m[4] = t0, t1, t2, t3

    # Round 7
    t0 = shuffle(m[1], m[2], (3, 1, 1, 2))
    t0 = shuffle(t0, (0, 3, 2, 1))
    g1(rows, t0)
    t1 = shuffle(m[3], m[4], (3, 3, 2, 2))
    tt = shuffle(m[1], (0, 0, 3, 3))
    t1 = blend(tt, t1, 0xcc)
    g2(rows, t1)
    diagonalize(rows)
    t2 = unpacklo_64(m[4], m[2])
    tt = blend(t2, m[3], 0xc0)
    t2 = shuffle(tt, (1, 3, 2, 0))
    g1(rows, t2)
    t3 = unpackhi_32(m[2], m[4])
    tt = unpacklo_32(m[3], t3)
    t3 = shuffle(tt, (0, 1, 3, 2))
    g2(rows, t3)
    undiagonalize(rows)
    nothing
end

function compress(
            chaining::CHAINING,
            block::Union{AbstractVector{UInt32}, BLOCK},
            block_len::UInt32,
            counter::UInt64,
            flags::UInt32
        )::CHAINING
    # @printf("CV1: 0x%08x 0x%08x 0x%08x 0x%08x\n", chaining_value[1][1], chaining_value[1][2], chaining_value[1][3], chaining_value[1][4])
    # @printf("CV2: 0x%08x 0x%08x 0x%08x 0x%08x\n", chaining_value[2][1], chaining_value[2][2], chaining_value[2][3], chaining_value[2][4])
    # @printf("BL1: 0x%08x 0x%08x 0x%08x 0x%08x\n", block[1], block[2], block[3], block[4])
    # @printf("BL2: 0x%08x 0x%08x 0x%08x 0x%08x\n", block[5], block[6], block[7], block[8])
    # @printf("BL3: 0x%08x 0x%08x 0x%08x 0x%08x\n", block[9], block[10], block[11], block[12])
    # @printf("BL4: 0x%08x 0x%08x 0x%08x 0x%08x\n", block[13], block[14], block[15], block[16])
    # @printf("block_len: %d counter: %d flags: %d\n", block_len, counter, flags)
    rows = build_rows(chaining, counter, block_len, flags)
    m    = build_m(block)

    compress_pre(rows, m)

    return CHAINING((rows[1] ⊻ rows[3], rows[2] ⊻ rows[4]))
end

function compress_xof(
            chaining::CHAINING,
            block::BLOCK,
            block_len::UInt32,
            counter::UInt64,
            flags::UInt32,
            out::Vector{UInt8},
            offset::Int = 1
        )::Nothing
    rows = build_rows(chaining, counter, block_len, flags)
    m    = build_m(block)
    compress_pre(rows, m)

    out = reinterpret(UInt32, view(out, offset:offset+64-1))
    vstore(rows[1] ⊻ rows[3], out, 1)
    vstore(rows[2] ⊻ rows[4], out, 5)
    vstore(rows[3] ⊻ chaining[1], out, 9)
    vstore(rows[4] ⊻ chaining[2], out, 13)

    nothing
end
