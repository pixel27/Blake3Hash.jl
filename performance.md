# Benchmark Report for *Blake3Hash.jl*

## Job Properties
* Time of benchmark: 17 Mar 2021 - 20:40
* Package commit: f35bab
* Julia commit: 69fcb5
* Julia command flags: `-O3`
* Environment variables: None

## Results
These tests were run hashing 16k of data.  The performance of the SHA package's sha2_256 and sha3_256 algorithms are included for comparison.

| ID                      | time            | GC time | memory          | allocations |
|-------------------------|----------------:|--------:|----------------:|------------:|
| `["blake3", "RefImpl"]` | 282.150 μs (5%) |         | 415.33 KiB (1%) |        3003 |
| `["blake3", "SAImpl"]`  |  40.500 μs (5%) |         |  640 bytes (1%) |           9 |
| `["blake3", "Simd128"]` |  21.909 μs (5%) |         |  192 bytes (1%) |           2 |
| `["ref", "sha2_256"]`   | 122.922 μs (5%) |         |  128 bytes (1%) |           1 |
| `["ref", "sha3_256"]`   | 255.719 μs (5%) |         |  128 bytes (1%) |           1 |

## Benchmark Group List
Here's a list of all the benchmark groups executed by this job:

- `["blake3"]`
- `["ref"]`

## Julia versioninfo
```
Julia Version 1.5.4
Commit 69fcb5745b (2021-03-11 19:13 UTC)
Platform Info:
  OS: Linux (x86_64-pc-linux-gnu)
      "Manjaro Linux"
  uname: Linux 5.4.101-1-MANJARO #1 SMP PREEMPT Fri Feb 26 11:18:55 UTC 2021 x86_64 unknown
  CPU: Intel(R) Core(TM) i7-3820 CPU @ 3.60GHz: 
              speed         user         nice          sys         idle          irq
       #1  2585 MHz    1998092 s     120030 s     999691 s   47669411 s      67933 s
       #2  2525 MHz    2155047 s     117915 s    1072145 s   47469637 s      71712 s
       #3  3393 MHz    2388592 s     124368 s    1345757 s   46964626 s      68250 s
       #4  2696 MHz    2438142 s     119574 s    1357230 s   46791976 s     108371 s
       #5  2112 MHz    2050405 s     116747 s    1026348 s   47522859 s      88704 s
       #6  2967 MHz    2146869 s     121675 s    1057028 s   47484742 s      71084 s
       #7  3602 MHz    2127494 s     116568 s    1099594 s   47355288 s      99090 s
       #8  2578 MHz    2149224 s     119003 s    1107559 s   47426524 s      66747 s
       
  Memory: 62.76103210449219 GB (15546.0 MB free)
  Uptime: 510828.0 sec
  Load Avg:  1.1884765625  0.7734375  0.62890625
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-9.0.1 (ORCJIT, sandybridge)
```
