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
} opcode_field /* verilator public */;

typedef enum [2:0] {
    OP_IMM_ADDI         = 'b000,
    OP_IMM_SLTI         = 'b010,
    OP_IMM_SLTIU        = 'b011,
    OP_IMM_XORI         = 'b100,
    OP_IMM_ORI          = 'b110,
    OP_IMM_ANDI         = 'b111,
    OP_IMM_SLLI         = 'b001,
    OP_IMM_SOME_SHIFT_R = 'b101
} funct3_op_imm /* verilator public */;

typedef enum [2:0] {
    OP_REG_SOME_ARITH   = 'b000,
    OP_REG_SLL          = 'b001,
    OP_REG_SLT          = 'b010,
    OP_REG_SLTU         = 'b011,
    OP_REG_XOR          = 'b100,
    OP_REG_SOME_SHIFT_R = 'b101,
    OP_REG_OR           = 'b110,
    OP_REG_AND          = 'b111
} funct3_op_reg /* verilator public */;

typedef enum [6:0] {
    SHIFT_R_LOGIC = 'b0000000,
    SHIFT_R_ARITH = 'b0100000
} funct7_r_shift_kind /* verilator public */;

typedef enum [6:0] {
    ARITH_REG_ADD = 'b0000000,
    ARITH_REG_SUB = 'b0100000
} funct7_reg_arith /* verilator public */;

typedef enum [2:0] {
    BRANCH_EQ                     = 'b000,
    BRANCH_NOT_EQ                 = 'b001,
    BRANCH_LESS_THAN_SIGNED       = 'b100,
    BRANCH_GREATER_OR_EQ_SIGNED   = 'b101,
    BRANCH_LESS_THAN_UNSIGNED     = 'b110,
    BRANCH_GREATER_OR_EQ_UNSIGNED = 'b111
} funct3_branch /* verilator public */;

typedef enum [2:0] {
    LOAD_BYTE           = 'b000,
    LOAD_HALFWORD       = 'b001,
    LOAD_WORD           = 'b010,
    LOAD_BYTE_UPPER     = 'b100,
    LOAD_HALFWORD_UPPER = 'b101
} funct3_load /* verilator public */;

typedef enum [2:0] {
    STORE_BYTE     = 'b000,
    STORE_HALFWORD = 'b001,
    STORE_WORD     = 'b010
} funct3_store /* verilator public */;

