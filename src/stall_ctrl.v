`timescale 1ns / 1ps
`include "config.vh"

module stall_ctrl(
    input wire clk,
    input wire rst,

    input wire stall_if_i,
    input wire stall_id_i,
    input wire stall_mem_i,

    output reg [`PipelineNum - 1 : 0] stall_o // len = 5
    );

always @ (*) begin
    if (rst == `ResetEnable) begin
        stall_o <= `PipelineNum'b00000;
    end
    else begin
        stall_o <= `PipelineNum'b00000;
        if (stall_mem_i == 1) begin
            stall_o <= `PipelineNum'b11111;
        end else if (stall_id_i == 1) begin
            stall_o <= `PipelineNum'b00111;
        end else if (stall_if_i == 1) begin
            stall_o <= `PipelineNum'b00011;
        end
    end
end

endmodule
