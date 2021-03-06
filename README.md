# Blake3

A Julia implmentation of the BLAKE3 cryptographic hash function.  You can visit
https://github.com/BLAKE3-team/BLAKE3 for more information.


## Versions

* 0.0.1 - Pretty much a straight copy of the BLAKE3 reference implmentation.  There has been no attempt to optimze the code.  This implementation is complete and passes the tests provide by the BLAKE3 team, so it is usable.

## Next Steps

Memory allocations must be reduced, the number of allocations are pretty high at the moment.

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
