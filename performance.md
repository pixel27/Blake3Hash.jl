# Benchmark Report for */home/josh/me/public/blake3/Blake3.jl*

## Job Properties
* Time of benchmark: 11 Mar 2021 - 19:8
* Package commit: dirty
* Julia commit: 788b2c
* Julia command flags: `-O3`
* Environment variables: None

## Results
These tests were run hashing 16k of data.  The performance of the SHA package's sha2_256 and sha3_256 algorithms are included for comparison.

| ID                      | time            | GC time | memory          | allocations |
|-------------------------|----------------:|--------:|----------------:|------------:|
| `["blake3", "RefImpl"]` | 281.840 μs (5%) |         | 415.33 KiB (1%) |        3003 |
| `["blake3", "SAImpl"]`  |  33.907 μs (5%) |         |  640 bytes (1%) |           9 |
| `["ref", "sha2_256"]`   | 122.752 μs (5%) |         |  128 bytes (1%) |           1 |
| `["ref", "sha3_256"]`   | 256.744 μs (5%) |         |  128 bytes (1%) |           1 |

## Benchmark Group List
Here's a list of all the benchmark groups executed by this job:

- `["blake3"]`
- `["ref"]`

## Julia versioninfo
```
Julia Version 1.5.3
Commit 788b2c77c1 (2020-11-09 13:37 UTC)
Platform Info:
  OS: Linux (x86_64-pc-linux-gnu)
      "Manjaro Linux"
  uname: Linux 5.4.101-1-MANJARO #1 SMP PREEMPT Fri Feb 26 11:18:55 UTC 2021 x86_64 unknown
  CPU: Intel(R) Core(TM) i7-3820 CPU @ 3.60GHz: 
              speed         user         nice          sys         idle          irq
       #1  1477 MHz     853152 s      25039 s     770646 s   18993367 s      21973 s
       #2  1541 MHz    1883911 s      25353 s     778024 s   18006362 s      18598 s
       #3  1514 MHz    2405631 s      25307 s     783802 s   17502761 s      18168 s
       #4  1556 MHz    2699107 s      26254 s     796981 s   17152641 s      32907 s
       #5  1541 MHz     512890 s      25890 s     758747 s   19351579 s      22350 s
       #6  1534 MHz    1783390 s      24840 s     762111 s   18146770 s      17633 s
       #7  1526 MHz    1241337 s      25007 s     718433 s   18545996 s      43315 s
       #8  1541 MHz    2656958 s      26790 s     709171 s   17273828 s      17872 s
       
  Memory: 62.76103210449219 GB (25692.453125 MB free)
  Uptime: 208566.0 sec
  Load Avg:  0.65380859375  0.45263671875  0.3369140625
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-9.0.1 (ORCJIT, sandybridge)
```
