# WIP: RISC-V CPU

## Toolchain setup

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
