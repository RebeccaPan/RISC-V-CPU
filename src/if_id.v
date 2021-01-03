`timescale 1ns / 1ps
`include "config.vh"

module if_id(
    input wire clk, 
    input wire rst,

    // from IF
    input wire [`AddrLen - 1 : 0] if_pc_i,
    input wire [`InstLen - 1 : 0] if_inst_i,

    // to ID
    output reg [`AddrLen - 1 : 0] id_pc_o,
    output reg [`InstLen - 1 : 0] id_inst_o,

    // from stall_ctrl
    input wire [`PipelineNum - 1 : 0] stall_i,

    // from EX
    input wire jump_i
);

// to check
always @ (posedge clk) begin
    if (rst == `ResetEnable || jump_i == 1'b1 || (stall_i[1] == 1'b1 && stall_i[2] == 1'b0)) begin
        id_pc_o <= `ZERO_WORD;
        id_inst_o <= `ZERO_WORD;
    end
    else if (stall_i[1] == 1'b0) begin
        id_pc_o <= if_pc_i;
        id_inst_o <= if_inst_i;
    end
end
endmodule
