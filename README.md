# My first attempt at a CPU core

This repo is an archive of the first serious system of RTL I designed, a 32-bit RISC-V processor. It
is _not_ pipelined, and takes ~5 cycles per instruction. It targets the DE1-SoC development board
with an Altera Cyclone V. It is written in SystemVerilog.

I built this core as a final project in University of Washington's introductory digital logic class.
The class does not teach computer architecture; typical final projects are small games and
novelties. I opted for a more interesting, yet difficult, alternative. This core was built with no
prior experience in computer architecture, minimal external reference, and plenty of
trial-and-error. There are many major flaws in its design, some of which I even recognized at the
time. All-up, it's a rather ugly bit of Verilog.

Note that this repository has been substantially doctored relative to the one it was originally
developed in. In particular, I have removed all Quartus project and generated files (chiefly, the
block RAM IPs). It is not runnable in its current form. However, I hope it is of interest as a
curiosity. I did my best to preserve its history.

The core is rooted in `hart.sv`. `hart_demo.sv` is the true top-level module for FPGA synthesis.

A few months later, I built another core targeting the same featureset, learning from my experience
in this design. You can find that (much better) design [here](https://github.com/WasabiFan/pipelined-rv32i-core).

## Details and features

If coupled with appropriate project files and target configurations, this core implements the RV32I
ISA with shared instruction and data memories, synthesized as block RAMs. The demo program in the
`firmware` directory implements a "snake" game, in software, for an LED matrix display. It
exercises much of the RV32I instruction set, including advanced control flow and bit manipulation.

Programs are loaded into ROM statically at configuration time on the FPGA. They are specified via
Quartus "MIF" files, which the provided build scripts can generate.

## License

Not licensed for reuse. All rights reserved. This is for your own protection. If you seriously wish
to use this despite looking at the sources, I recommend seeing a doctor :)

This should go without saying, but: **if you are a student, you may not use anything in this repo
for your own assignments.**

## Toolchain setup

Original development of this 

```
wget https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-linux-ubuntu14.tar.gz
tar -xzf riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-linux-ubuntu14.tar.gz
```

Then add `bin/` to PATH.

## Building firmware images

Edit `firmware.c`. Then:
```
make
make copy-firmware-to-rom
```

In Quartus, click "Processing -> Update Memory Initialization File" and wait for it to complete.
