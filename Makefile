VSRC   = $(wildcard Design/*.sv)
CSRC   = Simulation/Main.cpp
CLIB   = $(wildcard Simulation/*.hpp)
VFLAGS = --x-assign 1 --cc --exe --build --Mdir Build --top-module Top 
CFLAGS = --std=c++20 
BIN    = sim

Build/$(BIN): $(VSRC) $(CSRC) $(CLIB)
	verilator $(VFLAGS) -CFLAGS $(CFLAGS) $(VSRC) $(CSRC) -o $(BIN)

simulate:
	make && ./Build/sim

