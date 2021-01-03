`timescale 1ns / 1ps
`include "config.vh"

module pc_reg(
    input wire clk,
    input wire rst,
    
    // to IF
    output reg [`AddrLen - 1 : 0] pc,
    output reg chip_enable,

    // from stall_ctrl
    input wire [`PipelineNum - 1 : 0] stall_i,
    
    // from EX
    input wire jump_i,
    input wire [`AddrLen - 1 : 0] jump_addr_i
);

always @ (posedge clk) begin
    if (rst == `ResetEnable)
        chip_enable <= `ChipDisable;
    else
        chip_enable <= `ChipEnable;
end

always @ (posedge clk) begin
    if (chip_enable == `ChipDisable)
        pc <= `ZERO_WORD;
    else if (jump_i  == 1'b1)
        pc <= jump_addr_i;
    else if (stall_i[0] == 1'b1)
        pc <= pc;
    else
        pc <= pc + 4;
end

endmodule
