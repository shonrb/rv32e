default:
	mkdir -p Build
	riscv64-unknown-elf-as -march=rv32e -mno-relax -mno-arch-attr All.S -o Build/All.o
	riscv64-unknown-elf-ld Build/All.o -melf32lriscv -o Build/All.elf
	riscv64-unknown-elf-objcopy -O binary Build/All.elf Build/All.bin
