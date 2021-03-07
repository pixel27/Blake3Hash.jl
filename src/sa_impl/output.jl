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

function first_8_words(
            compression_output::SVector{16, UInt32}
        )::SVector{8, UInt32}
    return SVector(
        compression_output[1], compression_output[2],
        compression_output[3], compression_output[4],
        compression_output[5], compression_output[6],
        compression_output[7], compression_output[8]
    )
end

struct Output
    input_chaining_value::SVector{8, UInt32}
    block_words::SVector{16, UInt32}
    counter::UInt64
    block_len::UInt32
    flags::UInt32
end

function chaining_value(self::Output)::SVector{8, UInt32}
    return first_8_words(compress(
        self.input_chaining_value,
        self.block_words,
        self.counter,
        self.block_len,
        self.flags
    ))
end

function root_output_bytes(
            self::Output,
            out_slice::AbstractVector{UInt8}
        )::Nothing
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
