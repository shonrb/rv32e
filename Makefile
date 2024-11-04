BUILD = Build
BUILD_BINS = $(BUILD)/Bin
BUILD_CODE = $(BUILD)/Code

VC = verilator
AS = riscv64-unknown-elf-as
LD = riscv64-unknown-elf-ld
OC = riscv64-unknown-elf-objcopy

ASM_SRC = $(wildcard Code/*.asm)
ASM_INC = $(addprefix $(BUILD_CODE)/, $(notdir $(ASM_SRC:.asm=.inc)))

SV_SRC = $(wildcard Hardware/*.sv)
SV_LIB = $(wildcard Hardware/*.svh)
SV_FLAGS = --cc --exe --build --Mdir Build 
SV_FLAGS += --top-module Top -IHardware

CXX_SRC = $(wildcard Simulation/*.cpp)
CXX_BIN = $(addprefix $(BUILD_BINS)/, $(notdir $(CXX_SRC:.cpp=)))
CXX_LIB = $(wildcard Simulation/*.hpp) $(ASM_INC)
CXX_FLAGS = --std=c++23

# Program include files
$(BUILD_CODE)/%.inc: Code/%.asm
	$(eval TMP := Build/$(notdir $<))
	mkdir -p ./Build/Code
	riscv64-unknown-elf-as -march=rv32e -mno-relax -mno-arch-attr $< -o $(TMP).o
	riscv64-unknown-elf-ld -melf32lriscv $(TMP).o -o $(TMP).elf
	riscv64-unknown-elf-objcopy -O binary $(TMP).elf $(TMP).bin
	hexdump -v -e '1/4 "0x%08xu, "' $(TMP).bin > $@

# Verilated models
$(BUILD_BINS)/%: Simulation/%.cpp $(CXX_LIB) $(SV_SRC) $(SV_LIB)	
	mkdir -p ./Build/Bin
	verilator $(SV_FLAGS) -CFLAGS $(CXX_FLAGS) $(SV_SRC) $< -o Bin/$(notdir $@)

all: $(CXX_BIN)

simulate: $(BUILD_BINS)/Main
	./$<

test: $(BUILD_BINS)/Test
	./$<


