# Benchmark Report for */home/josh/me/public/blake3/Blake3.jl*

## Job Properties
* Time of benchmark: 7 Mar 2021 - 18:39
* Package commit: dirty
* Julia commit: 788b2c
* Julia command flags: `-O3`
* Environment variables: None

## Results
These tests were run hashing 16k of data.  The performance of the SHA package's sha2_256 and sha3_256 algorithms are included for comparison.

| ID                      | time            | GC time | memory          | allocations |
|-------------------------|----------------:|--------:|----------------:|------------:|
| `["blake3", "RefImpl"]` | 281.533 μs (5%) |         | 415.33 KiB (1%) |        3003 |
| `["blake3", "SAImpl"]`  |  53.899 μs (5%) |         |  640 bytes (1%) |           9 |
| `["ref", "sha2_256"]`   | 123.331 μs (5%) |         |  128 bytes (1%) |           1 |
| `["ref", "sha3_256"]`   | 255.247 μs (5%) |         |  128 bytes (1%) |           1 |

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
  uname: Linux 5.4.100-1-MANJARO #1 SMP PREEMPT Tue Feb 23 15:31:04 UTC 2021 x86_64 unknown
  CPU: Intel(R) Core(TM) i7-3820 CPU @ 3.60GHz:
              speed         user         nice          sys         idle          irq
       #1  1945 MHz     488196 s       5839 s     325607 s   18633334 s      14051 s
       #2  2933 MHz     512229 s       5216 s     329289 s   18639486 s      11686 s
       #3  1972 MHz     507380 s       9392 s     379966 s   18608999 s      12000 s
       #4  1469 MHz     513366 s       4796 s     359626 s   18582965 s      23625 s
       #5  1929 MHz     399603 s       3221 s     317081 s   18763119 s      18061 s
       #6  1573 MHz     485029 s       6069 s     324804 s   18675599 s      10420 s
       #7  1592 MHz     519305 s       9205 s     339175 s   18636346 s      10278 s
       #8  1577 MHz     514638 s       6391 s     355379 s   18544474 s      28053 s

  Memory: 62.76103210449219 GB (24084.328125 MB free)
  Uptime: 196327.0 sec
  Load Avg:  0.8935546875  0.65576171875  0.4833984375
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-9.0.1 (ORCJIT, sandybridge)
```