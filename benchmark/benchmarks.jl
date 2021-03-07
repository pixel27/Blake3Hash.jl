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
using BenchmarkTools

using SHA
using Blake3Hash

const SUITE     = BenchmarkGroup()
const DATA_SIZE = 2*8192

SUITE["blake3"] = BenchmarkGroup()

SUITE["blake3"]["RefImpl"] = @benchmarkable begin
    Blake3Hash.RefImpl.update!(h, d)
    Blake3Hash.RefImpl.digest(h)
end setup = begin
    h = Blake3Hash.RefImpl.Hasher()
    d = rand(UInt8, DATA_SIZE)
end

SUITE["blake3"]["SAImpl"] = @benchmarkable begin
    Blake3Hash.SAImpl.update!(h, d)
    Blake3Hash.SAImpl.digest(h)
end setup = begin
    h = Blake3Hash.SAImpl.Hasher()
    d = rand(UInt8, DATA_SIZE)
end

SUITE["ref"] = BenchmarkGroup()
SUITE["ref"]["sha2_256"] = @benchmarkable begin
    SHA.update!(c, d)
    SHA.digest!(c)
end setup = begin
    c = SHA2_256_CTX()
    d = rand(UInt8, DATA_SIZE)
end

SUITE["ref"]["sha3_256"] = @benchmarkable begin
    SHA.update!(c, d)
    SHA.digest!(c)
end setup = begin
    c = SHA3_256_CTX()
    d = rand(UInt8, DATA_SIZE)
end
