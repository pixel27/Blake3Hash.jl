# Blake3

A Julia implmentation of the BLAKE3 cryptographic hash function.  You can visit
https://github.com/BLAKE3-team/BLAKE3 for more information.


## Versions

* 0.1.0 - Pretty much a straight copy of the BLAKE3 reference implmentation.  There has been no attempt to optimze the code.  This implementation is complete and passes the tests provide by the BLAKE3 team, so it is usable.
* 0.2.0 - Extensive use of SVector objects have been utilized to make the memory allocations constant.  Performance is now reasonable but can still be improved.
* 0.3.0 - Added a first pass as SIMD optimizations.

## Next Steps

First is to use SIMD to hash multiple chunks at the same time to see how that changes(improves) the performance.  Then adding multi-threading for better throughput when hashing large amounts of data.

## Usage

Generate a 256 bit hash:

```julia
using Blake3Hash

hasher = Blake3Ctx()

update!(hasher, rand(UInt8, 4096))
hash = digest(hasher)
bytes2hex(hash)
```

Generate more bits:

```julia
using Blake3

hasher = Blake3Ctx()

update!(hasher, rand(UInt8, 4096))

output = Vector{UInt8}(undef, 64)
digest(hasher, output)
bytes2hex(output)
```
