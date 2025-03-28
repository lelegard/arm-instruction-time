# Instruction execution time on Arm64

## Principles

Measurements were made over loops of 32 instructions. The number of iterations
has an order of magnitude of 100 million (more or less depending on instructions).
The global execution time is divided by the total number of executed instructions
in the main loops, giving a mean instruction execution time in nanoseconds.

The problem is the overhead of the loop instructions (three instuctions: decrement
counter, test counter, branch back). Two types of tests are made, removing or
ignoring the loop overhead.

- To remove the loop overhead, an empty loop is executed with the same number of
  iterations. The time of the empty loop is substracted from the main loop time.
- However, it may be safe to ignore the overhead because the three loop instructions
  are probably executed in parallel of the body of the loop and the branch is probably
  correctly speculated. Therefore, removing the time of the empty loop may be misleading.

The time measurement is based on the virtual counter register (CNTVCT_EL0) and
its corresponding frequency register (CNTFRQ_EL0).

As a general rule, inside a loop, all input registers are identical and at least
16 distinct output registers are used.

## Tested systems

| System                      | CPU chip               | CPU core                 |
| --------------------------- | ---------------------- | ------------------------ |
| Raspberry Pi 4 Model B      | Broadcom BCM2711       | Arm Cortex A72           |
| Ampere Mt.Jade Server       | Ampere Altra           | Arm Neoverse N1          |
| AWS EC2 instance c7g.xlarge | AWS Graviton 3         | Arm Neoverse V1          |
| Supermicro ARS-221GL-NR     | Nvidia Grace Superchip | Arm Neoverse V2          |
| Apple MacBook M1            | Apple M1               | Apple Firestorm/Icestorm |
| Apple iMac M3               | Apple M3               | Apple (unknown core)     |
| Apple MacBook M4            | Apple M4               | Apple (unknown core)     |

The Apple Mx CPU were tested using macOS. All other CPU's were tested on Linux.

## Results

Depending on the CPU, consecutive executions of the test program produce slightly different results.
However, the difference remains on the third decimal, meaning a few picoseconds.
This difference can be considered as negligible.

The PAC instructions can be evaluated on Armv8.3-A onwards only. On older CPU cores,
the PAC tests are automatically skipped.

On macOS, all Apple Silicon chips support PAC. However, PAC instructions can be
disabled at system or application level (architecture `arm64` vs. `arm46e`,
[more details here](https://github.com/lelegard/arm-cpusysregs/blob/main/docs/arm64e-on-macos.md)).
When PAC instructions are disabled (architecture `arm64`), they execute at the speed of a NOP.
Therefore, the PAC tests are skipped in this configuration to avoid reporting
non-significant instruction time.

The tables below give the mean instruction time, in nanoseconds, in each loop.
The Excel file in this project adds the frequency information of each core
and the corresponding relative performance information.

### Ignoring the empty loop time

| Mean instruction time (nanoseconds) | Cortex A72 | Neoverse N1 | Neoverse V1 | Neoverse V2 | Apple M1 | Apple M3 | Apple M4 |
| ----------------------------------- | :--------: | :---------: | :---------: | :---------: | :------: | :------: | :------: |
| NOP                                 | 0.560      | 0.092       | 0.036       | 0.029       | 0.045    | 0.033    | 0.027    |
| ADD                                 | 0.297      | 0.115       | 0.099       | 0.080       | 0.070    | 0.036    | 0.034    |
| ADC                                 | 0.297      | 0.115       | 0.099       | 0.083       | 0.108    | 0.065    | 0.058    |
| ADDS                                | 0.315      | 0.120       | 0.131       | 0.124       | 0.107    | 0.066    | 0.058    |
| ADCS                                | 0.559      | 0.334       | 0.388       | 0.309       | 0.313    | 0.249    | 0.227    |
| MUL                                 | 1.677      | 1.002       | 0.193       | 0.152       | 0.156    | 0.126    | 0.075    |
| UMULH                               | 2.236      | 1.336       | 0.193       | 0.152       | 0.156    | 0.126    | 0.075    |
| DIV                                 | 3.353      | 2.005       | 2.311       | 1.824       | 0.625    | 0.498    | 0.454    |
| MUL UMULH                           | 1.957      | 1.169       | 0.193       | 0.152       | 0.156    | 0.125    | 0.075    |
| MUL ADCS UMULH ADCS                 | 0.978      | 0.584       | 0.294       | 0.238       | 0.157    | 0.125    | 0.112    |
| MUL ADD                             | 0.839      | 0.501       | 0.105       | 0.095       | 0.104    | 0.063    | 0.038    |
| MUL ADC                             | 0.838      | 0.501       | 0.105       | 0.102       | 0.105    | 0.064    | 0.037    |
| MUL ADDS                            | 0.838      | 0.501       | 0.103       | 0.099       | 0.104    | 0.063    | 0.038    |
| MUL ADCS                            | 0.839      | 0.501       | 0.196       | 0.188       | 0.156    | 0.124    | 0.112    |
| MUL ADCS (alt)                      | 0.838      | 0.501       | 0.195       | 0.156       | 0.156    | 0.125    | 0.113    |
| UMULH ADD                           | 1.118      | 0.668       | 0.131       | 0.106       | 0.105    | 0.062    | 0.038    |
| UMULH ADC                           | 1.118      | 0.668       | 0.131       | 0.113       | 0.105    | 0.062    | 0.037    |
| UMULH ADDS                          | 1.118      | 0.668       | 0.146       | 0.119       | 0.104    | 0.063    | 0.037    |
| UMULH ADCS                          | 1.118      | 0.668       | 0.340       | 0.270       | 0.156    | 0.124    | 0.112    |
| UMULH ADCS (alt)                    | 1.119      | 0.668       | 0.339       | 0.268       | 0.156    | 0.125    | 0.112    |
| UMULH NOP ADCS                      | 0.746      | 0.445       | 0.224       | 0.179       | 0.105    | 0.083    | 0.075    |
| UMULH ADD ADCS                      | 0.745      | 0.445       | 0.210       | 0.179       | 0.105    | 0.083    | 0.075    |
| UMULH ADDS ADCS                     | 0.745      | 0.445       | 0.144       | 0.129       | 0.117    | 0.046    | 0.039    |
| UMULH ADCS ADCS                     | 0.745      | 0.445       | 0.361       | 0.289       | 0.210    | 0.166    | 0.150    |
| UMULH ADC ADDS                      | 0.745      | 0.445       | 0.113       | 0.101       | 0.098    | 0.045    | 0.039    |
| UMULH ADC ADDS (dep. regs)          | 0.745      | 0.445       | 0.337       | 0.256       | 0.210    | 0.167    | 0.150    |
| MUL ADD UMULH ADD                   | 0.978      | 0.584       | 0.123       | 0.106       | 0.104    | 0.063    | 0.038    |
| PACIA                               |            |             | 0.385       |             | 0.313    | 0.248    | 0.227    |
| PACIA AUTIA                         |            |             | 0.385       |             | 0.313    | 0.250    | 0.227    |
| PACIA ... AUTIA ...                 |            |             | 0.385       |             | 0.314    | 0.251    | 0.228    |

### After substracting the empty loop time

| Mean instruction time (nanoseconds) | Cortex A72 | Neoverse N1 | Neoverse V1 | Neoverse V2 | Apple M1 | Apple M3 | Apple M4 |
| ----------------------------------- | :--------: | :---------: | :---------: | :---------: | :------: | :------: | :------: |
| NOP                                 | 0.524      | 0.073       | 0.024       | 0.019       | 0.033    | 0.022    | 0.019    |
| ADD                                 | 0.261      | 0.094       | 0.087       | 0.069       | 0.060    | 0.027    | 0.027    |
| ADC                                 | 0.261      | 0.094       | 0.087       | 0.069       | 0.098    | 0.057    | 0.052    |
| ADDS                                | 0.279      | 0.099       | 0.119       | 0.118       | 0.098    | 0.058    | 0.051    |
| ADCS                                | 0.525      | 0.313       | 0.376       | 0.300       | 0.303    | 0.242    | 0.221    |
| MUL                                 | 1.642      | 0.981       | 0.181       | 0.143       | 0.147    | 0.116    | 0.068    |
| UMULH                               | 2.201      | 1.315       | 0.181       | 0.143       | 0.147    | 0.117    | 0.068    |
| DIV                                 | 3.319      | 1.983       | 2.299       | 1.815       | 0.617    | 0.491    | 0.448    |
| MUL UMULH                           | 1.922      | 1.148       | 0.181       | 0.143       | 0.147    | 0.117    | 0.069    |
| MUL ADCS UMULH ADCS                 | 0.943      | 0.563       | 0.282       | 0.228       | 0.147    | 0.117    | 0.105    |
| MUL ADD                             | 0.804      | 0.480       | 0.093       | 0.081       | 0.095    | 0.055    | 0.032    |
| MUL ADC                             | 0.803      | 0.480       | 0.093       | 0.095       | 0.095    | 0.056    | 0.030    |
| MUL ADDS                            | 0.804      | 0.480       | 0.091       | 0.098       | 0.095    | 0.055    | 0.031    |
| MUL ADCS                            | 0.803      | 0.480       | 0.183       | 0.176       | 0.147    | 0.118    | 0.106    |
| MUL ADCS (alt)                      | 0.804      | 0.480       | 0.183       | 0.146       | 0.147    | 0.117    | 0.106    |
| UMULH ADD                           | 1.084      | 0.647       | 0.119       | 0.087       | 0.095    | 0.055    | 0.031    |
| UMULH ADC                           | 1.083      | 0.647       | 0.119       | 0.091       | 0.095    | 0.055    | 0.030    |
| UMULH ADDS                          | 1.083      | 0.647       | 0.133       | 0.124       | 0.095    | 0.055    | 0.030    |
| UMULH ADCS                          | 1.083      | 0.647       | 0.328       | 0.260       | 0.147    | 0.117    | 0.105    |
| UMULH ADCS (alt)                    | 1.084      | 0.647       | 0.327       | 0.258       | 0.147    | 0.117    | 0.105    |
| UMULH NOP ADCS                      | 0.712      | 0.425       | 0.213       | 0.170       | 0.095    | 0.076    | 0.068    |
| UMULH ADD ADCS                      | 0.712      | 0.425       | 0.199       | 0.169       | 0.095    | 0.076    | 0.068    |
| UMULH ADDS ADCS                     | 0.711      | 0.425       | 0.132       | 0.116       | 0.107    | 0.039    | 0.032    |
| UMULH ADCS ADCS                     | 0.711      | 0.425       | 0.350       | 0.279       | 0.200    | 0.158    | 0.143    |
| UMULH ADC ADDS                      | 0.712      | 0.425       | 0.101       | 0.083       | 0.089    | 0.039    | 0.032    |
| UMULH ADC ADDS (dep. regs)          | 0.711      | 0.425       | 0.326       | 0.247       | 0.200    | 0.158    | 0.143    |
| MUL ADD UMULH ADD                   | 0.944      | 0.563       | 0.111       | 0.095       | 0.095    | 0.056    | 0.031    |
| PACIA                               |            |             | 0.373       |             | 0.303    | 0.242    | 0.220    |
| PACIA AUTIA                         |            |             | 0.373       |             | 0.303    | 0.241    | 0.220    |
| PACIA ... AUTIA ...                 |            |             | 0.373       |             | 0.303    | 0.241    | 0.220    |

## Reference public documents

- [Arm Cortex A72 Core Software Optimization Guide](https://developer.arm.com/documentation/uan0016/latest/)
- [Arm Neoverse N1 Core Software Optimization Guide](https://developer.arm.com/documentation/pjdoc466751330-9707/latest/)
- [Arm Neoverse V1 Software Optimization Guide](https://developer.arm.com/documentation/pjdoc466751330-9685/latest/)
- [Apple M1 Microarchitecture Research by Dougall Johnson](https://dougallj.github.io/applecpu/firestorm.html) (unofficial reverse engineering works)
