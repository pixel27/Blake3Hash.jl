# Blake3

A Julia implmentation of the BLAKE3 cryptographic hash function.  You can visit
https://github.com/BLAKE3-team/BLAKE3 for more information.


## Versions

* 0.1.0 - Pretty much a straight copy of the BLAKE3 reference implmentation.  There has been no attempt to optimze the code.  This implementation is complete and passes the tests provide by the BLAKE3 team, so it is usable.
* 0.2.0 - Extensive use of SVector objects have been utilized to make the memory allocations constant.  Performance is now reasonable but can still be improved.

## Next Steps

The code needs to be updated to better utilizate of the various SIMD instructions.  Multi-threading can also be implmented for better throughput when hashing large amounts of data.

## Usage

Generate a 256 bit hash:

```julia
using Blake3

hasher = Hasher()

update!(hasher, rand(UInt8, 4096))
hash = digest(hasher)
bytes2hex(hash)
```

Generate more bits:

```julia
using Blake3

hasher = Hasher()

update!(hasher, rand(UInt8, 4096))

output = Vector{UInt8}(undef, 64)
digest(hasher, output)
bytes2hex(output)
```
