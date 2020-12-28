`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/25/2019 06:19:09 PM
// Design Name: 
// Module Name: id
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module id(
    input wire rst,
    
    // from PC_REG
    // input prediction-related

    // from EX
    // input forwarding-related

    // from IF/ID
    input wire [`AddrLen - 1 : 0] pc,
    input wire [`InstLen - 1 : 0] inst,

    // from REG_FILE
    input wire [`RegLen - 1 : 0] reg1_data_i, // 32
    input wire [`RegLen - 1 : 0] reg2_data_i,
    
    // to REG_FILE: rs1 and rs2
    output reg [`RegAddrLen - 1 : 0] reg1_addr_o, // 5
    output reg [`RegLen - 1 : 0] reg1_read_enable, // 32
    output reg [`RegAddrLen - 1 : 0] reg2_addr_o,
    output reg [`RegLen - 1 : 0] reg2_read_enable,

    // to ID/EX
    output wire [`AddrLen - 1 : 0] pc_o,
    output reg [`RegLen - 1 : 0] reg1,
    output reg [`RegLen - 1 : 0] reg2,
    // output reg [`RegLen - 1 : 0] Imm, // not used as output?
    output reg [`RegLen - 1 : 0] rd,
    output reg rd_enable,
    output reg [`OpCodeLen - 1 : 0] aluop, // 4, customized
    output reg [`OpSelLen - 1 : 0] alusel, // 3
    
    // to stall_ctrl
    output reg stall_id_o
    );

assign pc_o = pc;
wire [`OpLen - 1 : 0] opcode = inst[`OpLen - 1 : 0]; // 7
reg [`RegLen - 1 : 0] Imm;
reg useImmInstead;

//Decode: Get opcode, imm, rd, and the addr of rs1&rs2
// reg_addr_o
always @ (*) begin
    if (rst == `ResetEnable) begin
        reg1_addr_o = `RegAddrLen'b0;
        reg2_addr_o = `RegAddrLen'b0;
    end
    else begin
        reg1_addr_o = inst[19:15];
        reg2_addr_o = inst[24:20];
    end
end
always @ (*) begin
    // init val
    Imm = `ZERO_WORD;
    rd_enable = `WriteDisable;
    reg1_read_enable = `ReadDisable;
    reg2_read_enable = `ReadDisable;
    rd = `RegAddrLen'b0;
    aluop = `OpCodeLen'b0;
    alusel = `OpSelLen'b0;
    useImmInstead = 1'b0;
    
    // case analysis on last 7 bits
    case (opcode)
        `R_OP: begin
            useImmInstead = 1'b0;
            rd_enable = `WriteEnable;
            reg1_read_enable = `ReadEnable;
            reg2_read_enable = `ReadEnable;
            rd = inst[11:7];
            case (inst[12:10])
                `ADD_SUB: aluop = (inst[30] == 1'b0)? `EXE_ADD : `EXE_SUB;
                `SLL:     aluop = `EXE_SLL;
                `SLT:     aluop = `EXE_SLT;
                `SLTU:    aluop = `EXE_SLTU;
                `XOR:     aluop = `EXE_XOR;
                `SRL_SRA: aluop = (inst[30] == 1'b0)? `EXE_SRL : `EXE_SRA;
                `OR:      aluop = `EXE_OR;
                `AND:     aluop = `EXE_AND;
            endcase
            alusel = `LOGIC_OP;
        end
        `I_OP_JALR: begin
            Imm = {{21{inst[31]}}, inst[30:20]};
            useImmInstead = 1'b1;
            rd_enable = `WriteEnable;
            reg1_read_enable = `ReadEnable;
            reg2_read_enable = `ReadDisable;
            rd = inst[11:7];
            aluop = `EXE_JALR;
            alusel = `JUMP_OP;
        end
        `I_OP_L: begin
            Imm = {{21{inst[31]}}, inst[30:20]};
            useImmInstead = 1'b1;
            rd_enable = `WriteEnable;
            reg1_read_enable = `ReadEnable;
            reg2_read_enable = `ReadDisable;
            rd = inst[11:7];
            case (inst[12:10])
                `LB:  aluop = `EXE_LB;
                `LH:  aluop = `EXE_LH;
                `LW:  aluop = `EXE_LW;
                `LBU: aluop = `EXE_LBU;
                `LHU: aluop = `EXE_LHU;
            endcase
            alusel = `LOAD_OP;
        end
        `I_OP_Other: begin
            Imm = {{21{inst[31]}}, inst[30:20]};
            useImmInstead = 1'b1;
            rd_enable = `WriteEnable;
            reg1_read_enable = `ReadEnable;
            reg2_read_enable = `ReadDisable;
            rd = inst[11:7];
            case (inst[12:10])
                `ADD_SUB: aluop = `EXE_ADD; // ADDI; There's no SUBI
                `SLT:     aluop = `EXE_SLT; // SLTI
                `SLTU:    aluop = `EXE_SLTU;// SLTIU
                `XOR:     aluop = `EXE_XOR; // XORI
                `OR:      aluop = `EXE_OR;  // ORI
                `AND:     aluop = `EXE_AND; // ANDI
                `SLL:     aluop = `EXE_SLL; // SLLI
                `SRL_SRA: aluop = (inst[30] == 1'b0)? `EXE_SRL : `EXE_SRA; // SRLI, SRAI
            endcase
            alusel = `LOGIC_OP;
        end
        `S_OP: begin
            Imm = {{21{inst[31]}}, inst[30:25], inst[11:7]};
            useImmInstead = 1'b1;
            rd_enable = `WriteDisable;
            reg1_read_enable = `ReadEnable;
            reg2_read_enable = `ReadEnable;
            case (inst[12:10])
                `SB: aluop = `EXE_SB;
                `SH: aluop = `EXE_SH;
                `SW: aluop = `EXE_SW;
            endcase
            alusel = `STORE_OP;
        end
        `B_OP: begin
            Imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b1};
            useImmInstead = 1'b1;
            rd_enable = `WriteDisable;
            reg1_read_enable = `ReadEnable;
            reg2_read_enable = `ReadEnable;
            case (inst[12:10])
                `BEQ:  aluop = `EXE_BEQ;
                `BNE:  aluop = `EXE_BNE;
                `BLT:  aluop = `EXE_BLT;
                `BGE:  aluop = `EXE_BGE;
                `BLTU: aluop = `EXE_BLTU;
                `BGEU: aluop = `EXE_BGEU;
            endcase
            alusel = `BRANCH_OP;
        end
        `U_OP_LUI: begin
            Imm = {inst[31:12], 12'b0};
            useImmInstead = 1'b1;
            rd_enable = `WriteEnable;
            reg1_read_enable = `ReadDisable;
            reg2_read_enable = `ReadDisable;
            aluop = `EXE_LUI;
            alusel = `LOAD_OP;
        end
        `U_OP_AUIPC: begin
            Imm = {inst[31:12], 12'b0};
            useImmInstead = 1'b1;
            rd_enable = `WriteEnable;
            reg1_read_enable = `ReadDisable;
            reg2_read_enable = `ReadDisable;
            aluop = `EXE_AUIPC;
            alusel = `JUMP_OP;
        end
        `J_OP: begin // JAL
            Imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0};
            useImmInstead = 1'b1;
            rd_enable = `WriteEnable;
            reg1_read_enable = `ReadDisable;
            reg2_read_enable = `ReadDisable;
            aluop = `EXE_JAL;
            alusel = `JUMP_OP;
        end
    endcase
end

//Get rs1
always @ (*) begin
    if (rst == `ResetEnable) begin
        reg1 = `ZERO_WORD;
    end
    else if (reg1_read_enable == `ReadDisable) begin
        reg1 = `ZERO_WORD;
    end
    else begin
        reg1 = reg1_data_i;
    end
end

//Get rs2
always @ (*) begin
    if (rst == `ResetEnable) begin
        reg2 = `ZERO_WORD;
    end
    else if (reg2_read_enable == `ReadDisable) begin
        if (useImmInstead == 1'b0) reg2 = `ZERO_WORD;
        else reg2 = Imm;
    end
    else begin
        reg2 = reg2_data_i;
    end
end

endmodule
