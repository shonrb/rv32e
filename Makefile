VSRC   = $(wildcard Hardware/*.sv)
VLIB   = $(wildcard Hardware/*.svh)
CSRC   = Simulation/Main.cpp
CTST   = Simulation/Test.cpp
CLIB   = $(wildcard Simulation/*.hpp)
VFLAGS = --x-assign 1 --cc --exe --build --Mdir Build --top-module Top -IHardware
CFLAGS = --std=c++23
BIN    = sim
TST    = test

Build/$(BIN): $(VSRC) $(VLIB) $(CSRC) $(CLIB)
	verilator $(VFLAGS) -CFLAGS $(CFLAGS) $(VSRC) $(CSRC) -o $(BIN)

Build/$(TST): $(VSRC) $(VLIB) $(CTST) $(CLIB)
	verilator $(VFLAGS) -CFLAGS $(CFLAGS) $(VSRC) $(CTST) -o $(TST)

simulate: Build/$(BIN)
	make && ./Build/$(BIN)

test: Build/$(TST)
	make && ./Build/$(TST)

