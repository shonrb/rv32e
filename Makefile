HERE := $(abspath $(lastword $(MAKEFILE_LIST)))

# All

ASM_BIN = Build/Asm
SIM_BIN = Build/Sim
TEST_BIN = Build/Test

all: $(ASM_BIN) $(SIM_BIN) $(TEST_BIN)

# Assembler

ASM_SRC  = $(filter-out Asm/Main.c, $(wildcard Asm/*.c))
ASM_INC  = $(wildcard Asm/*.h)
ASM_MAIN = Asm/Main.c
ASM_OBJ  = $(wildcard Build/Lib/Asm/*.o)

asm_objects: $(ASM_SRC) $(ASM_INC)
	mkdir -p Build/Lib/Asm
	gcc $(ASM_SRC) -lm -g -c 
	mv *.o Build/Lib/Asm

$(ASM_BIN): asm_objects $(ASM_MAIN)
	gcc $(ASM_OBJ) $(ASM_MAIN) -lm -o $(ASM_BIN)

# Verilated Model

MODEL_SRC   =  $(wildcard Hardware/*.sv)
MODEL_INC   =  $(wildcard Hardware/*.svh)
MODEL_FLAGS =  --cc --build --Mdir Build/Lib/Verilated 
MODEL_FLAGS += --top-module Top -IHardware -I$(CURDIR)

verilated_model: $(MODEL_SRC) $(MODEL_INC)
	mkdir -p Build/Lib/Verilated
	verilator $(MODEL_FLAGS) $(MODEL_SRC)

# Simulations

VERILATOR_LIB  = -I/usr/local/share/verilator/include 
VERILATOR_LIB += -I/usr/local/share/verilator/include/vltstd

VERILATED =  $(wildcard Build/Lib/Verilated/*.o) 
VERILATED += $(wildcard Build/Lib/Verilated/*.a)
VERILATED += -IBuild/Lib/Verilated/

CPP_FLAGS =  -std=c++23 -I. -MMD -DVM_COVERAGE=0 -DVM_SC=0 
CPP_FLAGS += -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 
CPP_FLAGS += -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none
CPP_FLAGS += -pthread -lpthread -latomic -Os 

SIM_SRC = Simulation/Main.cpp
TB_SRC  = Simulation/Test.cpp

$(SIM_BIN): verilated_model $(MODEL_SRC) $(MODEL_INC) $(ASM_SRC) $(ASM_INC) $(SIM_SRC)
	g++ $(VERILATED) $(VERILATOR_LIB) $(CPP_FLAGS) $(SIM_SRC) -o $(SIM_BIN)

$(TEST_BIN): verilated_model $(MODEL_SRC) $(MODEL_INC) $(ASM_SRC) $(ASM_INC) $(TB_SRC)
	g++ $(ASM_OBJ) $(VERILATED) $(VERILATOR_LIB) $(CPP_FLAGS) $(TB_SRC) -o $(TEST_BIN)

# Running
test: $(TEST_BIN)
	./$(TEST_BIN)

simulate: $(SIM_BIN)
	./$(SIM_BIN)

assemble: $(ASM_BIN)
	./$(ASM_BIN)

