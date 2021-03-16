include("src/Blake3Hash.jl")

using BenchmarkTools
using .Blake3Hash

@benchmark begin
    Blake3Hash.Simd128.update!(h, d)
    Blake3Hash.Simd128.digest(h, o)
end setup=begin
    h = Blake3Hash.Simd128.Blake3Ctx()
    d = rand(UInt8, 2*8192)
    o = Vector{UInt8}(undef, 32)
end
