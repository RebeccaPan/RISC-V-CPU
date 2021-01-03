`timescale 1ns / 1ps
`include "config.vh"

module ex_mem(
    input wire clk,
    input wire rst,

    // from EX
    input wire [`RegLen - 1 : 0] ex_rd_data,
    input wire [`RegAddrLen - 1 : 0] ex_rd_addr,
    input wire ex_rd_enable,
    input wire load_enable_i,
    input wire store_enable_i,
    input wire [`AddrLen - 1 : 0] mem_addr_i, // 32
    input wire [`OpCodeLen - 1 : 0] load_store_type_i, // 4

    // to MEM
    output reg [`RegLen - 1 : 0] mem_rd_data,
    output reg [`RegAddrLen - 1 : 0] mem_rd_addr,
    output reg mem_rd_enable,
    output reg load_enable_o,
    output reg store_enable_o,
    output reg [`AddrLen - 1 : 0] mem_addr_o,
    output reg [`OpCodeLen - 1 : 0] load_store_type_o, // 4

    // from stall_ctrl
    input wire [`PipelineNum - 1 : 0] stall_i
);

always @ (posedge clk) begin
    if (rst == `ResetEnable) begin
        mem_rd_data <= `ZERO_WORD;
        mem_rd_addr <= `RegAddrLen'h0;
        mem_rd_enable <= `ReadDisable;
        load_enable_o <= 1'b0;
        store_enable_o <= 1'b0;
        mem_addr_o <= `AddrLen'b0;
        load_store_type_o <= `OpCodeLen'b0;
    end
    else if (stall_i[3] == 1'b0) begin
        mem_rd_data <= ex_rd_data;
        mem_rd_addr <= ex_rd_addr;
        mem_rd_enable <= ex_rd_enable;
        load_enable_o <= load_enable_i;
        store_enable_o <= store_enable_i;
        mem_addr_o <= mem_addr_i;
        load_store_type_o <= load_store_type_i;
    end
end

endmodule
