interface instruction_format;
    logic [31:0] encoded;
    logic [6:0]  opcode;
    logic [6:0]  funct7;
    logic [4:0]  rs2;
    logic [4:0]  rs1;
    logic [4:0]  rd;
    logic [2:0]  funct3;

    logic [31:0] i_immediate;
    logic [31:0] s_immediate;
    logic [31:0] b_immediate;
    logic [31:0] u_immediate;
    logic [31:0] j_immediate;

    modport back (
        input encoded,
        output 
            opcode, funct7, rs2, rs1, rd, funct3, 
            i_immediate, 
            s_immediate, 
            b_immediate, 
            u_immediate, 
            j_immediate
    );
endinterface

module Splitter(instruction_format.back fmt);
    assign fmt.opcode    = fmt.encoded[6:0]; 
    assign fmt.funct7    = fmt.encoded[31:25];
    assign fmt.rs2       = fmt.encoded[24:20];
    assign fmt.rs1       = fmt.encoded[19:15];
    assign fmt.funct3    = fmt.encoded[14:12];
    assign fmt.rd        = fmt.encoded[11:7];

    assign fmt.i_immediate[31:11] = {21{fmt.encoded[31]}};
    assign fmt.i_immediate[10:0]  = fmt.encoded[30:20];

    assign fmt.s_immediate[31:11] = {21{fmt.encoded[31]}};
    assign fmt.s_immediate[10:5]  = fmt.encoded[30:25];
    assign fmt.s_immediate[4:0]   = fmt.encoded[11:7];

    assign fmt.b_immediate[31:12] = {20{fmt.encoded[31]}};
    assign fmt.b_immediate[11]    = fmt.encoded[7];
    assign fmt.b_immediate[10:5]  = fmt.encoded[30:25];
    assign fmt.b_immediate[4:1]   = fmt.encoded[11:8];
    assign fmt.b_immediate[0]     = 0;

    assign fmt.u_immediate[31:12] = fmt.encoded[31:12];
    assign fmt.u_immediate[11:0]  = 0;

    assign fmt.j_immediate[31:20] = {12{fmt.encoded[31]}};
    assign fmt.j_immediate[19:12] = fmt.encoded[19:12];
    assign fmt.j_immediate[11]    = fmt.encoded[20];
    assign fmt.j_immediate[10:1]  = fmt.encoded[30:21];
    assign fmt.j_immediate[0]     = 0;
endmodule

typedef enum [6:0] {
    OPCODE_LUI           = 'b0110111,
    OPCODE_AUIPC         = 'b0010111,
    OPCODE_JAL           = 'b1101111,
    OPCODE_JALR          = 'b1100111,
    OPCODE_SOME_OP_IMM   = 'b0010011,
    OPCODE_SOME_OP_REG   = 'b0110011,
    OPCODE_SOME_BRANCH   = 'b1100011,
    OPCODE_SOME_LOAD     = 'b0000011,
    OPCODE_SOME_STORE    = 'b0100011,
    OPCODE_SOME_MISC_MEM = 'b0001111,
    OPCODE_SOME_SYSTEM   = 'b1110011
} opcode;

typedef enum [2:0] {
    OP_IMM_ADDI  = 'b000,
    OP_IMM_SLTI  = 'b010,
    OP_IMM_SLTIU = 'b011,
    OP_IMM_XORI  = 'b100,
    OP_IMM_ORI   = 'b110,
    OP_IMM_ANDI  = 'b111,
    OP_IMM_SLLI  = 'b001,
    OP_IMM_SOME_SHIFT_R = 'b101,
} funct3_op_imm;

typedef enum [6:0] {
    SHIFT_R_IMM_SRL = 'b0000000,
    SHIFT_R_IMM_SRA = 'b0100000
} funct7_imm_r_shift;

typedef enum [2:0] {
    OP_REG_SOME_ARITH   = 'b000,
    OP_REG_SLL          = 'b001,
    OP_REG_SLT          = 'b010,
    OP_REG_SLTU         = 'b011,
    OP_REG_XOR          = 'b100,
    OP_REG_SOME_SHIFT_R = 'b101,
    OP_REG_OR           = 'b110,
    OP_REG_AND          = 'b111,
} funct3_op_reg;

typedef enum [6:0] {
    SHIFT_R_LOGIC = 'b0000000,
    SHIFT_R_ARITH = 'b0100000
} funct7_r_shift_kind;

typedef enum [6:0] {
    ARITH_REG_ADD = 'b0000000,
    ARITH_REG_SUB = 'b0100000
} funct7_reg_arith;

typedef enum [2:0] {
    BRANCH_EQ                     = 'b000,
    BRANCH_NOT_EQ                 = 'b001,
    BRANCH_LESS_THAN_SIGNED       = 'b100,
    BRANCH_GREATER_OR_EQ_SIGNED   = 'b101,
    BRANCH_LESS_THAN_UNSIGNED     = 'b110,
    BRANCH_GREATER_OR_EQ_UNSIGNED = 'b111
} funct3_branch_kind;

typedef enum [2:0] {
    LOAD_BYTE           = 'b000,
    LOAD_HALFWORD       = 'b001,
    LOAD_WORD           = 'b010,
    LOAD_BYTE_UPPER     = 'b100,
    LOAD_HALFWORD_UPPER = 'b101,
} funct3_load;

typedef enum [2:0] {
    STORE_BYTE     = 'b000,
    STORE_HALFWORD = 'b001,
    STORE_WORD     = 'b010,
} funct3_store;

module Decoder();
    instruction_format format();
    Splitter splitter(.fmt(format));
endmodule

