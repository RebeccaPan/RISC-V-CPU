`timescale 1ns / 1ps
`include "config.vh"

module ex(
    input wire rst,

    // from ID/EX
    input wire [`AddrLen - 1 : 0] pc,
    input wire [`RegLen - 1 : 0] reg1,
    input wire [`RegLen - 1 : 0] reg2,
    // notice that reg2 = imm if imm is used
    input wire [`RegLen - 1 : 0] br_offset,
    input wire [`RegLen - 1 : 0] rd,
    input wire rd_enable,
    input wire [`OpCodeLen - 1 : 0] aluop,
    input wire [`OpSelLen - 1 : 0] alusel,

    // to EX/MEM
    output reg [`RegLen - 1 : 0] rd_data_o,
    output reg [`RegAddrLen - 1 : 0] rd_addr,
    output reg rd_enable_o,
    output reg load_enable,
    output reg store_enable,
    output reg [`AddrLen - 1 : 0] mem_addr, // 32
    output wire [`OpCodeLen - 1 : 0] load_store_type, // 4

    // to PC_REG, IF/ID, ID/EX
    output reg jump_enable,
    output reg [`AddrLen - 1 : 0] jump_addr, // 32

    // to ID for forwarding
    output reg ex_fw,
    output reg [`RegLen - 1 : 0] ex_fw_data,
    output reg [`RegAddrLen - 1 : 0] ex_fw_addr,
    output reg is_load
);

reg [`RegLen - 1 : 0] res;

// for load or stores
assign load_store_type = (alusel == `LOAD_OP || alusel == `STORE_OP) ? aluop : 0;

//Do the calculation
always @ (*) begin
    if (rst == `ResetEnable) begin
        res = `ZERO_WORD;
        load_enable = 1'b0;
        store_enable = 1'b0;
        jump_enable = `JumpDisable;
        jump_addr = `ZERO_WORD;
    end
    else begin
        load_enable = 1'b0;
        store_enable = 1'b0;
        jump_enable = `JumpDisable;
        // alusel work here just to simplify the code
        if (alusel == `LOAD_OP) begin
            load_enable = 1'b1;
            mem_addr = reg1 + reg2;
            res = `ZERO_WORD;
        end else if (alusel == `STORE_OP) begin
            store_enable = 1'b1;
            mem_addr = reg1 + br_offset; // reg1 + Imm
            res = reg2;
        end else if (alusel == `BRANCH_OP) begin
            jump_enable = `JumpDisable;
            jump_addr = pc + br_offset;
            case (aluop)
                `EXE_BEQ:  if (reg1 == reg2) jump_enable = `JumpEnable;
                `EXE_BNE:  if (reg1 != reg2) jump_enable = `JumpEnable;
                `EXE_BLT:  if ($signed(reg1) <  $signed(reg2)) jump_enable = `JumpEnable;
                `EXE_BGE:  if ($signed(reg1) >= $signed(reg2)) jump_enable = `JumpEnable;
                `EXE_BLTU: if (reg1 <  reg2) jump_enable = `JumpEnable;
                `EXE_BGEU: if (reg1 >= reg2) jump_enable = `JumpEnable;
            endcase
        end else begin
            case (aluop)
                `EXE_ADD: res = reg1 +  reg2;
                `EXE_SUB: res = reg1 -  reg2;
                `EXE_SLL: res = reg1 << reg2[4:0]; // only the last 5 bits of reg2
                `EXE_SLT: res = ($signed(reg1) < $signed(reg2))?32'b1:32'b0;
                `EXE_SLTU:res = (reg1 < reg2)?32'b1:32'b0;
                `EXE_XOR: res = reg1 ^  reg2;
                `EXE_SRL: res = reg1 >> reg2[4:0];
                `EXE_SRA: res = $signed(reg1) >> reg2[4:0];
                `EXE_OR:  res = reg1 |  reg2; 
                `EXE_AND: res = reg1 &  reg2;

                `EXE_AUIPC: begin
                    res = pc + reg2;
                    jump_enable = `JumpEnable;
                    jump_addr = pc + reg2; // pc + Imm
                end
                `EXE_JALR: begin
                    res = pc + 4;
                    jump_enable = `JumpEnable;
                    jump_addr = reg1 + reg2; // rs1 + Imm
                end
                `EXE_JAL: begin
                    res = pc + 4;
                    jump_enable = `JumpEnable;
                    jump_addr = pc + reg2; // pc + Imm
                end

                `EXE_LUI: res = reg2;
                // Load and Store
                /*`EXE_LB:  
                `EXE_LH:  
                `EXE_LW:  
                `EXE_LBU: 
                `EXE_LHU: 
                `EXE_SB:  
                `EXE_SH:  
                `EXE_SW:  */
                default: res = `ZERO_WORD;
            endcase 
        end
    end
end

//Determine the output
always @ (*) begin
    if (rst == `ResetEnable) begin
        rd_data_o = `RegLen'h0;
        rd_addr = `RegAddrLen'h0;
        rd_enable_o = `WriteDisable;
        // load_enable = 1'b0;
        // store_enable = 1'b0;
        mem_addr = `AddrLen'b0;
        // jump_enable = `JumpDisable;
        // jump_addr = `AddrLen'h0;
        
        ex_fw = 1'b0;
        ex_fw_addr = `RegLen'b0;
        ex_fw_data = `ZERO_WORD;
        is_load = 1'b0;
    end else begin 
        rd_data_o = res;
        rd_addr = rd;
        rd_enable_o = rd_enable;

        ex_fw = rd_enable;
        ex_fw_addr = rd;
        ex_fw_data = res;
        is_load = (alusel == `LOAD_OP) ? 1'b1 : 1'b0;
        // case (alusel)
        //     `LOGIC_OP:  rd_data_o = res;
        //     `LOAD_OP:   // do nothing
        //     `STORE_OP:  // do nothing
        //     `JUMP_OP || BRANCH_OP: rd_data_o = res;
        //     default: rd_data_o = `ZERO_WORD;
        // endcase
    end
end
endmodule
