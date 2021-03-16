include("src/Blake3Hash.jl")

using .Blake3Hash

data = rand(UInt8, 2 * 8192)

sa     = Blake3Hash.SAImpl.Blake3Ctx()
sa_out = Vector{UInt8}(undef, 64)

Blake3Hash.SAImpl.update!(sa, data)
Blake3Hash.SAImpl.digest(sa, sa_out)

t     = Blake3Hash.Simd128.Blake3Ctx()
t_out = Vector{UInt8}(undef, 64)

Blake3Hash.Simd128.update!(t, data)
Blake3Hash.Simd128.digest(t, t_out)

println("E: $sa_out")
println("R: $t_out")

