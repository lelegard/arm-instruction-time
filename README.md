# Instruction execution time on Arm64

## Principles

Measurements were made over loops of 32 instructions. The number of iterations
has an order of magnitude of 100 million (more or less depending on instructions).
An empty loop is then executed with the same number of iterations. The time of the
empty loop is substracted from the main loop time. The result is divided by the
total number of executed instructions in the main loops.

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

## Results

| Mean instruction time (nanoseconds) | Cortex A72 | Neoverse N1 | Neoverse V1 | Apple M1 |
| ----------------------------------- | :--------: | :---------: | :---------: | :------: |
| NOP                                 |            |             |             | 0.033    |
| ADD                                 |            |             |             | 0.061    |
| ADC                                 |            |             |             | 0.098    |
| ADDS                                |            |             |             | 0.098    |
| ADCS                                |            |             |             | 0.303    |
| MUL                                 |            |             |             | 0.147    |
| UDIV                                |            |             |             | 0.616    |
| MUL UMULH                           |            |             |             | 0.147    |
| MUL ADCS UMULH ADCS                 |            |             |             | 0.147    |
| MUL ADCS                            |            |             |             | 0.147    |
| MUL ADD UMULH ADD                   |            |             |             | 0.095    |
| PACIA                               |            |             |             | 0.033    |
| AUTIA                               |            |             |             | 0.033    |
| PACIA AUTIA ...                     |            |             |             | 0.033    |
| PACIA ... AUTIA ...                 |            |             |             | 0.033    |
