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
using Blake3Hash

@testset "Hash - normal" begin
    @testset "Length: ($(test["input_len"]))" for test in CASES
        local case = Case(test)

        local hasher = Blake3Hash.Blake3Ref.Hasher()
        local result = Vector{UInt8}(undef, length(case.hash))

        Blake3Hash.Blake3Ref.update!(hasher, case.input)
        Blake3Hash.Blake3Ref.digest(hasher, result)

        @test case.hash == result
    end
end

@testset "Hash - keyed" begin
    @testset "Length: ($(test["input_len"]))" for test in CASES
        local case = Case(test)

        local hasher = Blake3Hash.Blake3Ref.Hasher(KEY)
        local result = Vector{UInt8}(undef, length(case.hash))

        Blake3Hash.Blake3Ref.update!(hasher, case.input)
        Blake3Hash.Blake3Ref.digest(hasher, result)

        @test case.keyed == result
    end
end


@testset "Hash - derive" begin
    @testset "Length: ($(test["input_len"]))" for test in CASES
        local case = Case(test)

        local hasher = Blake3Hash.Blake3Ref.Hasher(CONTEXT)
        local result = Vector{UInt8}(undef, length(case.hash))

        Blake3Hash.Blake3Ref.update!(hasher, case.input)
        Blake3Hash.Blake3Ref.digest(hasher, result)

        @test case.derive == result
    end
end

@testset "Hash - 256" begin
    @testset "Length: ($(test["input_len"]))" for test in CASES
        local case = Case(test)

        local hasher = Blake3Hash.Blake3Ref.Hasher()

        Blake3Hash.Blake3Ref.update!(hasher, case.input)

        local result = Blake3Hash.Blake3Ref.digest(hasher)

        @test case.hash[1:32] == result
    end
end
