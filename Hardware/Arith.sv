typedef enum {
    ALU_NONE,
    ALU_ADD,
    ALU_SUBTRACT,
    ALU_AND,
    ALU_OR,
    ALU_XOR,
    ALU_SHIFT_L_LOGIC,
    ALU_SHIFT_R_LOGIC,
    ALU_SHIFT_R_ARITH,
    ALU_LESS_THAN,
    ALU_LESS_THAN_UNSIGNED
} alu_operation;

interface executor_to_alu;
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] result;
    alu_operation operation;

    modport back  (input  a, b, operation, output result);
    modport front (output a, b, operation, input  result);
endinterface

module ArithmeticLogicUnit(executor_to_alu.back executor);
    always_comb begin
        case (executor.operation)
        ALU_NONE:               executor.result = 0;
        ALU_ADD:                executor.result = executor.a +   executor.b;
        ALU_SUBTRACT:           executor.result = executor.a -   executor.b;
        ALU_AND:                executor.result = executor.a &   executor.b;
        ALU_OR:                 executor.result = executor.a |   executor.b;
        ALU_XOR:                executor.result = executor.a ^   executor.b;
        ALU_SHIFT_L_LOGIC:      executor.result = executor.a <<  executor.b;
        ALU_SHIFT_R_LOGIC:      executor.result = executor.a >>  executor.b;
        ALU_SHIFT_R_ARITH:      executor.result = executor.a >>> executor.b;
        ALU_LESS_THAN:          executor.result = 0; //executor.a <   executor.b;
        ALU_LESS_THAN_UNSIGNED: executor.result = 0; //$signed(executor.a) < $signed(executor.b);
        endcase
    end
endmodule

