include("src/Blake3Hash.jl")

using Profile
using .Blake3Hash

DATA_SIZE = 2*8192

function run()
    h = Blake3Hash.Simd128.Blake3Ctx()
    d = rand(UInt8, 2*8192)
    o = Vector{UInt8}(undef, 32)

    Blake3Hash.Simd128.update!(h, d)
    Blake3Hash.Simd128.digest(h, o)
end

run()
Profile.clear_malloc_data()
run()
