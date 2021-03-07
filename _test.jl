include("src/Blake3Hash.jl")

using BenchmarkTools
using .Blake3Hash

DATA_SIZE = 8192

perf = @benchmarkable begin
    Blake3Hash.SAImpl.update!(h, d)
    Blake3Hash.SAImpl.digest(h, o)
end setup = begin
    h = Blake3Hash.SAImpl.Hasher()
    d = rand(UInt8, DATA_SIZE)
    o = Vector{UInt8}(undef, 32)
end

tune!(perf)
run(perf)
