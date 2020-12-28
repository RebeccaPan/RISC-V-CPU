`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2019 08:31:41 PM
// Design Name: 
// Module Name: mem
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


module mem(
    input rst,

    // from EX_MEM
    input wire [`RegLen - 1 : 0] rd_data_i,
    input wire [`RegAddrLen - 1 : 0] rd_addr_i,
    input wire rd_enable_i,

    input wire load_enable_i,
    input wire store_enable_i,
    input wire [`RegAddrLen - 1 : 0] mem_addr_i, // length = 5?? TODO
    input wire [`OpCodeLen - 1 : 0] load_store_type_i, // 4

    // to MEM/WB
    output reg [`RegLen - 1 : 0] rd_data_o,
    output reg [`RegAddrLen - 1 : 0] rd_addr_o,
    output reg rd_enable_o,

    // to stall_ctrl
    output reg stall,

    // from mem_ctrl
    input wire mem_rdy,
    input wire mem_busy,
    input wire [`RegLen] mem_ldata,

    // to mem_ctrl
    output reg mem_needed,
    output reg [`RegLen] mem_sdata,
    output reg [`RegAddrLen] mem_addr,
    output reg [2 : 0] mem_width, // at most 8
    output reg mem_read_write // 1 for read and 0 for write
);

always @ (*) begin
    if (rst == `ResetEnable) begin
        rd_data_o <= `ZERO_WORD;
        rd_addr_o <= `RegAddrLen'h0;
        rd_enable_o <= `WriteDisable;

        mem_needed <= 1'b0;
        mem_sdata <= `RegLen'b0;
        mem_addr <= `RegAddrLen'b0;
        mem_width <= 3'b0;
        mem_read_write <= 1'b0; 
        stall <= 1'b0;
    end else begin
        mem_needed <= 1'b0;
        mem_sdata <= `RegLen'b0;
        stall <= 1'b0;
        if (load_enable_i == 1'b1) begin
            if (mem_rdy == 1'b1) begin
                case (load_store_type_i)
                    `EXE_LB:  rd_data_o <= {{24{mem_ldata[7]}}, mem_ldata[7:0]};
                    `EXE_LBU: rd_data_o <= {24'b0, mem_ldata[7:0]};
                    `EXE_LH:  rd_data_o <= {{16{mem_ldata[15]}}, mem_ldata[15:0]};
                    `EXE_LHU: rd_data_o <= {16'b0, mem_ldata[15:0]};
                    `EXE_LW:  rd_data_o <= mem_ldata;
                endcase
            end else begin
                stall <= 1'b1;
                if (mem_busy == 1'b0) begin
                    mem_needed <= 1'b1;
                    mem_addr <= mem_addr_i;
                    mem_read_write <= 1'b1;
                    case (load_store_type_i)
                        `EXE_LB:  mem_width <= 3'b001;
                        `EXE_LBU: mem_width <= 3'b001;
                        `EXE_LH:  mem_width <= 3'b010;
                        `EXE_LHU: mem_width <= 3'b010;
                        `EXE_LW:  mem_width <= 3'b100;
                    endcase
                end
            end
        end else if (store_enable_i == 1'b1) begin
            if (mem_rdy == 1'b0) begin
                stall <= 1'b1;
                if (mem_busy == 1'b0) begin
                    mem_needed <= 1'b1;
                    mem_addr <= mem_addr_i;
                    mem_read_write <= 1'b0;
                    case (load_store_type_i)
                        `EXE_SW: begin
                            memsdata <= rd_data_i;
                            mem_width <= 3'b100;
                        end
                        `EXE_SH: begin
                            memsdata <= rd_data_i[15:0];
                            mem_width <= 3'b010;
                        end
                        `EXE_SB: begin
                            memsdata <= rd_data_i[7:0];
                            mem_width <= 3'b001;
                        end
                    endcase
                end
            end
        end else begin
            rd_data_o <= rd_data_i;
            rd_addr_o <= rd_addr_i;
            rd_enable_o <= rd_enable_i;
        end
    end
end

endmodule
