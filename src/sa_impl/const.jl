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

const OUT_LEN = 32
const KEY_LEN = 32
const BLOCK_LEN = 64
const CHUNK_LEN = 1024

const CHUNK_START = UInt32(1) << 0
const CHUNK_END   = UInt32(1) << 1
const PARENT      = UInt32(1) << 2
const ROOT        = UInt32(1) << 3
const KEYED_HASH  = UInt32(1) << 4
const DERIVE_KEY_CONTEXT  = UInt32(1) << 5
const DERIVE_KEY_MATERIAL = UInt32(1) << 6

const IV = SVector{8, UInt32}(
    UInt32(0x6A09E667), UInt32(0xBB67AE85), UInt32(0x3C6EF372), UInt32(0xA54FF53A),
    UInt32(0x510E527F), UInt32(0x9B05688C), UInt32(0x1F83D9AB), UInt32(0x5BE0CD19)
)
