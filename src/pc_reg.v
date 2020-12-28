`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Gabriel
// 
// Create Date: 10/24/2019 11:39:52 PM
// Design Name: 
// Module Name: pc_reg
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


module pc_reg(
    input wire clk,
    input wire rst,
    
    // to IF
    output reg [`AddrLen - 1 : 0] pc,
    output reg chip_enable,

    // from stall_ctrl
    input wire stall_i,
    
    // from EX
    input wire jump_i,
    input reg [`AddrLen - 1 : 0] jump_addr_i
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
    else if (stall_i[0] == 1'b1)
        pc <= pc;
    else if (jump_i  == 1'b1)
        pc <= jump_addr_i;
    else
        pc <= pc + 32'h4;
end

endmodule
