TOOLPREFIX := riscv64-unknown-elf-
CC := $(TOOLPREFIX)gcc
LD := $(TOOLPREFIX)gcc
OBJCOPY := $(TOOLPREFIX)objcopy
OBJDUMP := $(TOOLPREFIX)objdump

FLAGS_ARCH := -march=rv32i -mabi=ilp32 -mcmodel=medany

CFLAGS_GENERAL := -ffreestanding -fwrapv -fno-pic -fno-stack-protector -Wall -Werror -O2
CFLAGS := $(FLAGS_ARCH) $(CFLAGS_GENERAL)

IMAGE_START_ADDRESS := 0

all: firmware.elf firmware.mif

firmware.o: firmware.c
	$(CC) -c -o $@ $< $(CFLAGS)

firmware.elf: firmware.o
	# TODO: -T linkerscript.ld
	$(LD) $(FLAGS_ARCH) -nostartfiles -entry:main -N -e main -Ttext $(IMAGE_START_ADDRESS) -o $@ $<

firmware.img: firmware.elf
	$(OBJCOPY) -O binary $< $@

firmware.d: firmware.elf
	$(OBJDUMP) -d $< > $@

firmware.mif: firmware.img img_to_mif.py
	python3 img_to_mif.py $(IMAGE_START_ADDRESS) $< $@

copy-firmware-to-rom:
	cp firmware.mif ../hart_code/rom.mif

clean:
	rm -f firmware.o firmware.elf firmware.img firmware.d firmware.mif