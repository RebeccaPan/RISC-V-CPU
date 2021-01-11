`timescale 1ns / 1ps
`include "config.vh"

module mem(
    input rst,

    // from EX_MEM
    input wire [`RegLen - 1 : 0] rd_data_i,
    input wire [`RegAddrLen - 1 : 0] rd_addr_i,
    input wire rd_enable_i,

    input wire load_enable_i,
    input wire store_enable_i,
    input wire [`AddrLen - 1 : 0] mem_addr_i, // 32
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
    input wire [`RegLen - 1 : 0] mem_ldata,

    // to mem_ctrl
    output reg mem_needed,
    output reg [`RegLen - 1 : 0] mem_sdata,
    output reg [`AddrLen - 1 : 0] mem_addr,
    output reg [2 : 0] mem_width, // at most 8
    output reg mem_read_write, // 1 for read and 0 for write

    output reg mem_fw,
    output reg [`RegLen - 1 : 0] mem_fw_data,
    output reg [`RegAddrLen - 1 : 0] mem_fw_addr
);

always @ (*) begin
    if (rst == `ResetEnable) begin
        mem_fw <= 1'b0;
        mem_fw_data <= `ZERO_WORD;
        mem_fw_addr <= `RegAddrLen'b0;
    end else begin
        mem_fw <= 1'b1;
        mem_fw_addr <= rd_addr_i;
        mem_fw_data <= (load_enable_i == 1'b1) ? rd_data_o : rd_data_i;
    end
end

always @ (*) begin
    if (rst == `ResetEnable) begin
        rd_data_o <= `ZERO_WORD;
        rd_addr_o <= `RegAddrLen'h0;
        rd_enable_o <= `WriteDisable;

        mem_needed <= 1'b0;
        mem_sdata <= `RegLen'b0;
        mem_addr <= `AddrLen'b0;
        mem_width <= 3'b0;
        mem_read_write <= 1'b0; 
        stall <= 1'b0;
    end else begin
        rd_addr_o <= rd_addr_i;
        rd_enable_o <= rd_enable_i;
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
                            mem_sdata <= rd_data_i;
                            mem_width <= 3'b100;
                        end
                        `EXE_SH: begin
                            mem_sdata <= rd_data_i[15:0];
                            mem_width <= 3'b010;
                        end
                        `EXE_SB: begin
                            mem_sdata <= rd_data_i[7:0];
                            mem_width <= 3'b001;
                        end
                    endcase
                end
            end
        end else begin
            rd_data_o <= rd_data_i;
        end
    end
end

endmodule
