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

| System                      | CPU chip         | CPU core                 |
| --------------------------- | ---------------- | ------------------------ |
| Raspberry Pi 4 Model B      | Broadcom BCM2711 | Arm Cortex A72           |
| Ampere Mt.Jade Server       | Ampere Altra     | Arm Neoverse N1          |
| AWS EC2 instance c7g.xlarge | AWS Graviton 3   | Arm Neoverse V1          |
| Apple MacBook M1            | Apple M1         | Apple Firestorm/Icestorm |

The Apple M1 CPU was tested using macOS. All other CPU's were tested on Linux.

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

| Mean instruction time (nanoseconds) | Cortex A72 | Neoverse N1 | Neoverse V1 | Apple M1 |
| ----------------------------------- | :--------: | :---------: | :---------: | :------: |
| NOP                                 | 0.560      | 0.093       | 0.036       | 0.045    |
| ADD                                 | 0.298      | 0.115       | 0.099       | 0.070    |
| ADC                                 | 0.296      | 0.115       | 0.099       | 0.108    |
| ADDS                                | 0.315      | 0.120       | 0.132       | 0.108    |
| ADCS                                | 0.558      | 0.334       | 0.387       | 0.313    |
| MUL                                 | 1.671      | 1.001       | 0.193       | 0.156    |
| UMULH                               | 2.228      | 1.335       | 0.193       | 0.156    |
| DIV                                 | 5.571      | 3.003       | 3.851       | 0.628    |
| MUL UMULH                           | 1.950      | 1.168       | 0.193       | 0.156    |
| MUL ADCS UMULH ADCS                 | 0.975      | 0.584       | 0.294       | 0.156    |
| MUL ADD                             | 0.836      | 0.501       | 0.105       | 0.105    |
| MUL ADC                             | 0.836      | 0.501       | 0.105       | 0.104    |
| MUL ADDS                            | 0.836      | 0.501       | 0.103       | 0.104    |
| MUL ADCS                            | 0.836      | 0.501       | 0.196       | 0.156    |
| MUL ADCS (alt)                      | 0.836      | 0.501       | 0.195       | 0.156    |
| UMULH ADD                           | 1.114      | 0.667       | 0.131       | 0.105    |
| UMULH ADC                           | 1.114      | 0.667       | 0.131       | 0.104    |
| UMULH ADDS                          | 1.114      | 0.667       | 0.146       | 0.104    |
| UMULH ADCS                          | 1.114      | 0.667       | 0.340       | 0.157    |
| UMULH ADCS (alt)                    | 1.114      | 0.667       | 0.339       | 0.156    |
| MUL ADD UMULH ADD                   | 0.975      | 0.584       | 0.123       | 0.105    |
| PACIA                               |            |             | 0.385       | 0.313    |
| AUTIA                               |            |             | 0.385       | 0.313    |
| PACIA AUTIA                         |            |             | 0.385       | 0.313    |
| PACIA ... AUTIA ...                 |            |             | 0.385       | 0.313    |

### After substracting the empty loop time

| Mean instruction time (nanoseconds) | Cortex A72 | Neoverse N1 | Neoverse V1 | Apple M1 |
| ----------------------------------- | :--------: | :---------: | :---------: | :------: |
| NOP                                 | 0.522      | 0.070       | 0.024       | 0.033    |
| ADD                                 | 0.261      | 0.094       | 0.087       | 0.060    |
| ADC                                 | 0.261      | 0.094       | 0.087       | 0.098    |
| ADDS                                | 0.279      | 0.099       | 0.119       | 0.098    |
| ADCS                                | 0.522      | 0.313       | 0.376       | 0.303    |
| MUL                                 | 1.636      | 0.980       | 0.180       | 0.147    |
| UMULH                               | 2.194      | 1.314       | 0.181       | 0.146    |
| DIV                                 | 5.536      | 2.982       | 3.839       | 0.616    |
| MUL UMULH                           | 1.915      | 1.147       | 0.181       | 0.147    |
| MUL ADCS UMULH ADCS                 | 0.940      | 0.563       | 0.282       | 0.147    |
| MUL ADD                             | 0.801      | 0.480       | 0.093       | 0.095    |
| MUL ADC                             | 0.801      | 0.480       | 0.093       | 0.095    |
| MUL ADDS                            | 0.801      | 0.480       | 0.091       | 0.095    |
| MUL ADCS                            | 0.801      | 0.480       | 0.184       | 0.147    |
| MUL ADCS (alt)                      | 0.801      | 0.480       | 0.183       | 0.147    |
| UMULH ADD                           | 1.079      | 0.647       | 0.119       | 0.095    |
| UMULH ADC                           | 1.079      | 0.647       | 0.119       | 0.095    |
| UMULH ADDS                          | 1.079      | 0.647       | 0.133       | 0.095    |
| UMULH ADCS                          | 1.079      | 0.647       | 0.328       | 0.147    |
| UMULH ADCS (alt)                    | 1.079      | 0.647       | 0.327       | 0.147    |
| MUL ADD UMULH ADD                   | 0.940      | 0.563       | 0.111       | 0.095    |
| PACIA                               |            |             | 0.373       | 0.303    |
| AUTIA                               |            |             | 0.373       | 0.303    |
| PACIA AUTIA                         |            |             | 0.373       | 0.303    |
| PACIA ... AUTIA ...                 |            |             | 0.373       | 0.303    |

### Reference public documents

- [Arm Cortex A72 Core Software Optimization Guide](https://developer.arm.com/documentation/uan0016/latest/)
- [Arm Neoverse N1 Core Software Optimization Guide](https://developer.arm.com/documentation/pjdoc466751330-9707/latest/)
- [Arm Neoverse V1 Software Optimization Guide](https://developer.arm.com/documentation/pjdoc466751330-9685/latest/)
- [Apple M1 Microarchitecture Research by Dougall Johnson](https://dougallj.github.io/applecpu/firestorm.html) (unofficial reverse engineering works)
