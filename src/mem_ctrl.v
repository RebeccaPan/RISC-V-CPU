`timescale 1ns / 1ps

module mem_ctrl(
    input wire clk, 
    input wire rst,

    input wire is_jump,

    // from icache
    input wire inst_needed,
    input wire [`InstLen] inst_addr,

    // to icache
    output reg [`InstLen] inst_data,
    output reg inst_rdy, // the process is finished
    output reg inst_busy, // amidst the process

    // from MEM
    input wire mem_needed,
    input wire [`RegLen] mem_sdata,
    input wire [`RegAddrLen] mem_addr,
    input wire [2 : 0] mem_width, // at most 8
    input wire mem_read_write, // 1 for read and 0 for write

    // to MEM
    output reg mem_rdy,
    output reg mem_busy,
    output reg [`RegLen] mem_ldata,

    // from RAM
    input wire[7 : 0] ram_i,

    // to RAM
    output wire [7 : 0] ram_o,
    output wire [`RegAddrLen] ram_addr,
    output wire ram_read_write, // 1 for read and 0 for write

    );

assign ram_o = (cur_stage == 3'b100) ? `ZERO_WORD : s_data[cur_stage];
assign ram_addr = (inst_needed == 1'b1) ? inst_addr[`InstLen] : mem_addr[`RegAddrLen];
assign ram_read_write = (mem_needed == 1'b1) ? (mem_read_write) : 1'b1; // To check

wire [`InstLen] addr;
assign addr = (inst_needed == 1'b1) ? inst_addr[`InstLen] : mem_addr[`RegAddrLen];

reg  [7 : 0] l_data[3 : 0];
wire [7 : 0] s_data[3 : 0];
assign s_data[0] = mem_sdata[7 :0 ];
assign s_data[1] = mem_sdata[15:8 ];
assign s_data[2] = mem_sdata[23:16];
assign s_data[3] = mem_sdata[31:24];

reg  [2 : 0] cur_stage;
wire [2 : 0] cycle_num;
assign cycle_num = (inst_needed == 1'b1) ? 4 : ((mem_needed == 1'b1) ? mem_width[2:0] : 0);

always @ (posedge clk) begin
    if (rst == `ResetEnable || (is_jump && !mem_needed)) begin // Reset
        inst_data <= `InstLen'b0;
        inst_rdy  <= 0;
        inst_busy <= 0;
        mem_rdy   <= 0;
        mem_busy  <= 0;
        cur_stage <= 0;
        l_data[0] <= 0;
        l_data[1] <= 0;
        l_data[2] <= 0;
        l_data[3] <= 0;
    end else if (cycle_num && ram_read_write == 1'b1) begin // Read
        if (cur_stage == 0) begin
            inst_rdy <= 1'b0;
            mem_rdy <= 1'b0;
            inst_busy <= !inst_needed;
            mem_busy <= !mem_needed;
            cur_stage <= cur_stage + 1;
        end else if (cur_stage < cycle_num) begin
            l_data[cur_stage - 1] <= ram_in;
            cur_stage <= cur_stage + 1;
        end else begin
            if (inst_needed == 1'b1) begin
                inst_data <= {ram_in, l_data[2], l_data[1], l_data[0]};
                inst_rdy = 1'b1;
            end else if (mem_needed == 1'b1) begin
                mem_rdy <= 1'b1;
                case (mem_width)
                    3'b001: mem_ldata <= ram_in;
                    3'b010: mem_ldata <= {ram_in, l_data[0]};
                    3'b100: mem_ldata <= {ram_in, l_data[1], l_data[0]};
                endcase
            end
            cur_stage <= 0;
        end
    end else if (cycle_num && ram_read_write == 1'b0) begin // Write by MEM
        if (cur_stage == 0) begin // starting
            inst_busy <= 1'b0; // to check
            mem_busy  <= 1'b1; // to check
            inst_rdy  <= 1'b0;
            mem_rdy   <= 1'b0;
        end else if (cur_stage + 1 == cycle_num) begin // almost finished
            mem_rdy <= 1'b1;
            cur_stage <= 0;
        end else
            cur_stage <= cur_stage + 1; // general
    end else  begin // Idle
        inst_busy <= 1'b0;
        mem_busy  <= 1'b0;
        inst_rdy  <= 1'b0;
        mem_rdy   <= 1'b0;
    end
end

endmodule
