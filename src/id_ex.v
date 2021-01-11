`timescale 1ns / 1ps
`include "config.vh"

module id_ex(
    input wire clk,
    input wire rst,

    // from ID
    input wire [`AddrLen - 1 : 0] pc_i,
    input wire [`RegLen - 1 : 0] id_reg1,
    input wire [`RegLen - 1 : 0] id_reg2,
    input wire [`RegLen - 1 : 0] id_br_offset,
    input wire [`RegLen - 1 : 0] id_rd,
    input wire id_rd_enable,
    input wire [`OpCodeLen - 1 : 0] id_aluop,
    input wire [`OpSelLen - 1 : 0] id_alusel,

    // to EX
    output reg [`AddrLen - 1 : 0] pc_o,
    output reg [`RegLen - 1 : 0] ex_reg1,
    output reg [`RegLen - 1 : 0] ex_reg2,
    output reg [`RegLen - 1 : 0] ex_br_offset,
    output reg [`RegLen - 1 : 0] ex_rd,
    output reg ex_rd_enable,
    output reg [`OpCodeLen - 1 : 0] ex_aluop,
    output reg [`OpSelLen - 1 : 0] ex_alusel,

    // from stall_ctrl
    input wire [`PipelineNum - 1 : 0] stall_i,
    
    // from EX
    input wire jump_i
);

always @ (posedge clk) begin
    if (rst == `ResetEnable || jump_i == 1'b1 || (stall_i[2] == 1'b1 && stall_i[3] == 1'b0)) begin
        pc_o <= `ZERO_WORD;
        ex_reg1 <= `ZERO_WORD;
        ex_reg2 <= `ZERO_WORD;
        ex_br_offset  <= `ZERO_WORD;
        ex_rd   <= `ZERO_WORD;
        ex_rd_enable <= `ReadDisable;
        ex_aluop <= `OpCodeLen'h0;
        ex_alusel <= `OpSelLen'h0;
    end
    else if (stall_i[2] == 1'b0) begin
        pc_o <= pc_i;
        ex_reg1 <= id_reg1;
        ex_reg2 <= id_reg2;
        ex_br_offset <= id_br_offset;
        ex_rd <= id_rd;
        ex_rd_enable <= id_rd_enable;
        ex_aluop <= id_aluop;
        ex_alusel <= id_alusel;
    end
end

endmodule
