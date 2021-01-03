`timescale 1ns / 1ps

`define ZERO_WORD 32'h00000000
//`define ZERO_ADDR  5'h00000000

`define InstLen 32
`define AddrLen 32
`define RegAddrLen 5
`define RegLen 32
`define RegNum 32

`define PipelineNum 5

`define ResetEnable 1'b1
`define ResetDisable 1'b0
`define ChipEnable 1'b1
`define ChipDisable 1'b0
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0
`define JumpEnable 1'b1
`define JumpDisable 1'b0
`define StallEnable 1'b1
`define StallDisable 1'b0

`define RAM_SIZE 100
`define RAM_SIZELOG2 17

//OPCODE
`define OpLen 7
// `define INTCOM_ORI 7'b0010011

// ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
`define R_OP 7'b0110011
`define I_OP_JALR 7'b1100111
// LB, LH, LW, LBU, LHU
`define I_OP_L 7'b0000011
// ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
`define I_OP_Other 7'b0010011
// SB, SH, SW
`define S_OP 7'b0100011
// BEQ, BNE, BLT, BGE, BLTU, BGEU
`define B_OP 7'b1100011
`define U_OP_LUI 7'b0110111
`define U_OP_AUIPC 7'b0010111
// JAL
`define J_OP 7'b1101111

//AluOP, customized
`define OpCodeLen 4
`define EXE_ADD  4'b0000
`define EXE_SUB  4'b1000
`define EXE_SLL  4'b0001
`define EXE_SLT  4'b0010
`define EXE_SLTU 4'b0011
`define EXE_XOR  4'b0100
`define EXE_SRL  4'b0101
`define EXE_SRA  4'b1101
`define EXE_OR   4'b0110
`define EXE_AND  4'b0111

`define EXE_JAL   4'b1001 // JUMP_OP
`define EXE_JALR  4'b1010 // JUMP_OP
`define EXE_LUI   4'b0110 // LOGIC_OP
`define EXE_AUIPC 4'b0111 // JUMP_OP

//`LOAD_OP or `STORE_OP checked in ex.v
`define EXE_LB   4'b0001
`define EXE_LH   4'b0010
`define EXE_LW   4'b0011
`define EXE_LBU  4'b0100
`define EXE_LHU  4'b0101

`define EXE_SB   4'b1001
`define EXE_SH   4'b1010
`define EXE_SW   4'b1011

//`BRANCH_OP checked in ex.v
`define EXE_BEQ  4'b0000
`define EXE_BNE  4'b0001
`define EXE_BLT  4'b0010
`define EXE_BGE  4'b0011
`define EXE_BLTU 4'b0100
`define EXE_BGEU 4'b0101

//AluSelect
`define OpSelLen  3
`define LOGIC_OP  3'b001
`define LOAD_OP   3'b010
`define STORE_OP  3'b011
`define BRANCH_OP 3'b100
`define JUMP_OP   3'b101

//Sub_Op: R-Type
`define ADD_SUB 3'b000
`define SLL     3'b001
`define SLT     3'b010
`define SLTU    3'b011
`define XOR     3'b100
`define SRL_SRA 3'b101
`define OR      3'b110
`define AND     3'b111
//Sub_Op: I_Type
// JALR not needed
`define LB  3'b000
`define LH  3'b001
`define LW  3'b010
`define LBU 3'b100
`define LHU 3'b101
//Sub_Op: S_Type
`define SB 3'b000
`define SH 3'b001
`define SW 3'b010
//Sub_Op: B_Type
`define BEQ  3'b000
`define BNE  3'b001
`define BLT  3'b100
`define BGE  3'b101
`define BLTU 3'b110
`define BGEU 3'b111

// icache
`define IcacheNum 128
`define IcacheTagLen 10