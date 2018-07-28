# AVX2 cuboid checker

Checks which 16-bit x,y,z coordinates are inside a cuboid.

1677721600 iterations:

```
 Performance counter stats for './a.out':

    52.035.368.791      idq.dsb_uops:u                                                (33,32%)
    17.502.474.772      cycles:u                                                      (33,32%)
     3.883.939.960      resource_stalls.any:u                                         (33,31%)
     9.932.498.285      uops_dispatched_port.port_0:u                                     (33,31%)
    10.333.148.579      uops_dispatched_port.port_1:u                                     (33,31%)
     3.384.674.885      uops_dispatched_port.port_2:u                                     (33,37%)
     3.464.957.069      uops_dispatched_port.port_3:u                                     (33,38%)
     1.782.546.703      uops_dispatched_port.port_4:u                                     (33,38%)
    16.801.836.406      uops_dispatched_port.port_5:u                                     (33,38%)
     7.015.962.326      uops_dispatched_port.port_6:u                                     (33,31%)
     1.006.659.126      uops_dispatched_port.port_7:u                                     (33,31%)
    52.114.098.076      uops_issued.any:u                                             (33,31%)

       4,215384119 seconds time elapsed
```

```
Throughput Analysis Report
--------------------------
Block Throughput: 10.05 Cycles       Throughput Bottleneck: Backend
Loop Count:  22
Port Binding In Cycles Per Iteration:
--------------------------------------------------------------------------------------------------
|  Port  |   0   -  DV   |   1   |   2   -  D    |   3   -  D    |   4   |   5   |   6   |   7   |
--------------------------------------------------------------------------------------------------
| Cycles |  6.0     0.0  |  6.0  |  1.5     1.5  |  1.5     1.5  |  1.0  | 10.0  |  3.0  |  1.0  |
--------------------------------------------------------------------------------------------------

DV - Divider pipe (on port 0)
D - Data fetch pipe (on ports 2 and 3)
F - Macro Fusion with the previous instruction occurred
* - instruction micro-ops not bound to a port
^ - Micro Fusion occurred
# - ESP Tracking sync uop was issued
@ - SSE instruction followed an AVX256/AVX512 instruction, dozens of cycles penalty is expected
X - instruction not supported, was not accounted in Analysis

| Num Of   |                    Ports pressure in cycles                         |      |
|  Uops    |  0  - DV    |  1   |  2  -  D    |  3  -  D    |  4   |  5   |  6   |  7   |
-----------------------------------------------------------------------------------------
|   1      |             |      | 0.5     0.5 | 0.5     0.5 |      |      |      |      | vmovdqa ymm0, ymmword ptr [rdi+rcx*1]
|   1      |             |      | 0.5     0.5 | 0.5     0.5 |      |      |      |      | vmovdqa ymm1, ymmword ptr [rdi+rcx*1+0x20]
|   1      |             |      | 0.5     0.5 | 0.5     0.5 |      |      |      |      | vmovdqa ymm2, ymmword ptr [rdi+rcx*1+0x40]
|   1      |             | 1.0  |             |             |      |      |      |      | vpblendd ymm13, ymm2, ymm0, 0xf0
|   1      |             | 1.0  |             |             |      |      |      |      | vpblendd ymm12, ymm0, ymm1, 0xf0
|   1      |             |      |             |             |      | 1.0  |      |      | vperm2i128 ymm13, ymm13, ymm13, 0x1
|   1      | 1.0         |      |             |             |      |      |      |      | vpblendd ymm14, ymm1, ymm2, 0xf0
|   1      |             |      |             |             |      | 1.0  |      |      | vpblendw ymm0, ymm12, ymm13, 0x92
|   1      |             |      |             |             |      | 1.0  |      |      | vpblendw ymm0, ymm0, ymm14, 0x24
|   1      |             |      |             |             |      | 1.0  |      |      | vpblendw ymm1, ymm14, ymm12, 0x92
|   1      |             |      |             |             |      | 1.0  |      |      | vpblendw ymm1, ymm1, ymm13, 0x24
|   1      |             |      |             |             |      | 1.0  |      |      | vpblendw ymm2, ymm13, ymm14, 0x92
|   1      |             |      |             |             |      | 1.0  |      |      | vpblendw ymm2, ymm2, ymm12, 0x24
|   1      |             | 1.0  |             |             |      |      |      |      | vpaddw ymm0, ymm0, ymm6
|   1      | 1.0         |      |             |             |      |      |      |      | vpcmpgtw ymm0, ymm0, ymm7
|   1      |             | 1.0  |             |             |      |      |      |      | vpaddw ymm1, ymm1, ymm8
|   1      | 1.0         |      |             |             |      |      |      |      | vpcmpgtw ymm1, ymm1, ymm9
|   1      |             | 1.0  |             |             |      |      |      |      | vpaddw ymm2, ymm2, ymm10
|   1      | 1.0         |      |             |             |      |      |      |      | vpcmpgtw ymm2, ymm2, ymm11
|   1      |             |      |             |             |      | 1.0  |      |      | vpshufb ymm0, ymm0, ymm3
|   1      |             |      |             |             |      | 1.0  |      |      | vpshufb ymm1, ymm1, ymm4
|   1      |             |      |             |             |      | 1.0  |      |      | vpshufb ymm2, ymm2, ymm5
|   1      |             | 1.0  |             |             |      |      |      |      | vpand ymm0, ymm0, ymm1
|   1      | 1.0         |      |             |             |      |      |      |      | vpand ymm0, ymm0, ymm2
|   1      | 1.0         |      |             |             |      |      |      |      | vpmovmskb eax, ymm0
|   1      |             |      |             |             |      |      | 1.0  |      | shr eax, 0x8
|   2^     |             |      |             |             | 1.0  |      |      | 1.0  | mov word ptr [rsi], ax
|   1      |             |      |             |             |      |      | 1.0  |      | add rsi, 0x2
|   1      |             |      |             |             |      |      | 1.0  |      | add rcx, 0x60
|   1*     |             |      |             |             |      |      |      |      | cmp rcx, 0x600
|   0*F    |             |      |             |             |      |      |      |      | jnz 0xffffffffffffff5f
Total Num Of Uops: 31
```