`timescale 1ns / 1ps
`include "config.vh"

module mem_wb(
    input clk,
    input rst,

    // from MEM
    input wire [`RegLen - 1 : 0] mem_rd_data,
    input wire [`RegAddrLen - 1 : 0] mem_rd_addr,
    input wire mem_rd_enable,

    // to WB(actually to REGFILE)
    output reg [`RegLen - 1 : 0] wb_rd_data,
    output reg [`RegAddrLen - 1 : 0] wb_rd_addr,
    output reg wb_rd_enable,

    // from stall_ctrl
    input wire [`PipelineNum - 1 : 0] stall_i
);

always @ (posedge clk) begin
    if (rst == `ResetEnable || stall_i[4] == 1'b1) begin
        wb_rd_data <= `ZERO_WORD;
        wb_rd_addr <= `RegAddrLen'h0;
        wb_rd_enable <= `WriteDisable;
    end
    else if (stall_i[4] == 1'b0) begin
        wb_rd_data <= mem_rd_data;
        wb_rd_addr <= mem_rd_addr;
        wb_rd_enable <= mem_rd_enable;
    end
end
endmodule
