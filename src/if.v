`timescale 1ns / 1ps
`include "config.vh"

// With i-cache

module If (
    input wire clk,
    input wire rst,

    // if: from PC_REG
    input wire [`AddrLen - 1 : 0] pc,
    input wire chip_enable,

    // if: to IF/ID
    output reg [`AddrLen - 1 : 0] pc_to_IFID, // len=32
    output reg [`InstLen - 1 : 0] inst_to_IFID, // len=32

    // if: to stall_ctrl
    output wire stall_to_StallCtrl, // 1 or 0

    // icache: from mem_ctrl
    input wire [`InstLen - 1 : 0] inst_data_from_MemCtrl,
    input wire inst_rdy_from_MemCtrl, // the process is finished
    input wire inst_busy_from_MemCtrl, // amidst the process

    // icache: to mem_ctrl
    output reg inst_needed_to_MemCtrl,
    output wire [`InstLen - 1 : 0] inst_addr_to_MemCtrl
);

// if -> icache
reg icache_needed_to;
reg [`AddrLen - 1 : 0] icache_addr_to;

assign stall_to_StallCtrl = chip_enable && !icache_found_from;
assign inst_addr_to_MemCtrl = icache_addr_to;

// icache -> if
reg icache_found_from;
reg [`InstLen - 1 : 0] icache_data_from;

// icache
// TODO: size not sure
reg [31 : 0] cache_data [`IcacheNum - 1 : 0];
reg [`IcacheTagLen : 0] cache_tag [`IcacheNum - 1 : 0];
reg cache_valid [`IcacheNum - 1 : 0];

// if
always @ (*) begin
    // init
    if (rst == `ResetEnable || chip_enable == `ChipDisable) begin
        pc_to_IFID <= `ZERO_WORD;
        inst_to_IFID <= `ZERO_WORD;
        // inst_needed_to_MemCtrl <= 1'b0;
        // inst_addr_to_MemCtrl <= `ZERO_WORD;
        icache_needed_to <= 1'b0;
        icache_addr_to <= `ZERO_WORD;
    end else begin
        pc_to_IFID <= pc;
        inst_to_IFID <= (icache_found_from == 1'b1) ? icache_data_from : `ZERO_WORD;
        icache_needed_to <= 1'b1;
        // icache_needed_to <= (icache_found_from == 1'b1) ? 0 : 1;
        icache_addr_to <= pc;
    end
    // inst_to_IFID <= (rst == `ResetDisable && icache_found_from == 1'b1) ? icache_data_from : `ZERO_WORD;
end

// icache
integer i;

// init
initial begin
    for (i = 0; i < `IcacheNum; i = i + 1) begin
            cache_data [i] <= `ZERO_WORD;
            cache_tag  [i] <= `IcacheTagLen'b0;
            cache_valid[i] <= 1'b0;
        end
end

// size can be modified
wire [6:0] index; // 7-bits
assign index = icache_addr_to[6:0];
wire [9:0] tag; // 10-bits
assign tag = icache_addr_to[16:7];

// cache val set
always @ (posedge clk) begin
    if (rst == `ResetEnable) begin
        for (i = 0; i < `IcacheNum; i = i + 1) begin
            cache_data [i] <= `ZERO_WORD;
            cache_tag  [i] <= `IcacheTagLen'b0;
            cache_valid[i] <= 1'b0;
        end
    end else if (inst_rdy_from_MemCtrl) begin
            cache_data [index] <= inst_data_from_MemCtrl;
            cache_tag  [index] <= tag;
            cache_valid[index] <= 1'b1;
        end
end

// cache function
always @ (*) begin
    if (rst == `ResetEnable || icache_needed_to == 1'b0) begin
        icache_found_from <= 1'b0;
        icache_data_from <= `ZERO_WORD;
        inst_needed_to_MemCtrl <= 1'b0;
    end else begin
        if (cache_tag[index] == tag && cache_valid[index] == 1'b1) begin
            // cache hit
            icache_found_from <= 1'b1;
            icache_data_from <= cache_data[index];
            inst_needed_to_MemCtrl <= 1'b0;
        end else if (inst_rdy_from_MemCtrl == 1'b1) begin
            // ready from mem_ctrl
            icache_found_from <= 1'b1;
            icache_data_from <= inst_data_from_MemCtrl;
            inst_needed_to_MemCtrl <= 1'b0;
        end else begin
            // asking/waiting data from mem_ctrl
            icache_found_from <= 1'b0;
            icache_data_from <= `ZERO_WORD;
            if (inst_busy_from_MemCtrl == 1'b1) begin
                inst_needed_to_MemCtrl <= 1'b0;
            end else begin
                inst_needed_to_MemCtrl <= 1'b1;
            end
            // inst_needed_to_MemCtrl <= (inst_busy_from_MemCtrl == 1'b1) ? 1'b0 : 1'b1;
        end
    end
end

endmodule
