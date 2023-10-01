# Instruction execution time on Arm64

## Principles

Measurements were made over loops of 32 instructions. The number of iterations
has an order of magnitude of 100 million (more or less depending on instructions).
An empty loop is then executed with the same number of iterations. The time of the
empty loop is substracted from the main loop time. The result is divided by the
total number of executed instructions in the main loops, giving a mean instruction
execution time in nanoseconds.

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

| Mean instruction time (nanoseconds) | Cortex A72 | Neoverse N1 | Neoverse V1 | Apple M1 |
| ----------------------------------- | :--------: | :---------: | :---------: | :------: |
| NOP                                 | 0.525      |             |             | 0.033    |
| ADD                                 | 0.262      |             |             | 0.061    |
| ADC                                 | 0.261      |             |             | 0.098    |
| ADDS                                | 0.279      |             |             | 0.098    |
| ADCS                                | 0.522      |             |             | 0.303    |
| MUL                                 | 1.637      |             |             | 0.147    |
| UDIV                                | 4.981      |             |             | 0.616    |
| MUL UMULH                           | 1.916      |             |             | 0.147    |
| MUL ADCS UMULH ADCS                 | 0.940      |             |             | 0.147    |
| MUL ADCS                            | 0.801      |             |             | 0.147    |
| MUL ADD UMULH ADD                   | 0.941      |             |             | 0.095    |
| PACIA                               | n/a        |             |             | 0.303    |
| AUTIA                               | n/a        |             |             | 0.303    |
| PACIA AUTIA ...                     | n/a        |             |             | 0.303    |
| PACIA ... AUTIA ...                 | n/a        |             |             | 0.303    |

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
