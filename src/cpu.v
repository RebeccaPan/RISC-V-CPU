// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "config.vh"

module cpu(
  input  wire             clk_in,	// system clock signal
  input  wire             rst_in,	// reset signal
  input  wire             rdy_in,	// ready signal, pause cpu when low
  input  wire [ 7:0]      mem_din,	// data input bus
  output wire [ 7:0]      mem_dout,	// data output bus
  output wire [31:0]      mem_a,	// address bus (only 17:0 is used)
  output wire             mem_wr,	// write/read signal (1 for write)
  input  wire             io_buffer_full, // 1 if uart buffer is full
  output wire [31:0]	  dbgreg_dout	// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire rst_im = rst_in || !rdy_in;

// PC -> IF
wire [`AddrLen - 1 : 0] pc_pc_if;
wire chip_enable_pc_if;

// IF -> IF/ID
wire [`AddrLen - 1 : 0] pc_if_ifid;
wire [`InstLen - 1 : 0] inst_if_ifid;

// IF -> StallCtrl
wire stall_if;

// IF(Icache) -> MemCtrl
wire inst_needed;
wire [`InstLen - 1 : 0] inst_addr;

// MemCtrl -> IF(Icache)
wire [`InstLen - 1 : 0] inst_data;
wire inst_rdy;
wire inst_busy;

// IF/ID -> ID
wire [`AddrLen - 1 : 0] pc_ifid_id;
wire [`InstLen - 1 : 0] inst_ifid_id;

// Register -> ID
wire [`RegLen - 1 : 0] reg1_data;
wire [`RegLen - 1 : 0] reg2_data;

// ID -> Register
wire [`RegAddrLen - 1 : 0] reg1_addr;
wire reg1_read_enable;
wire [`RegAddrLen - 1 : 0] reg2_addr;
wire reg2_read_enable;

// ID -> ID/EX
wire [`AddrLen - 1 : 0] pc_id_idex;
wire [`RegLen - 1 : 0] reg1_id_idex, reg2_id_idex, rd_id_idex, br_offset_id_idex;
wire rd_enable_id_idex;
wire [`OpCodeLen - 1 : 0] aluop_id_idex;
wire [`OpSelLen - 1 : 0] alusel_id_idex;

// ID -> StallCtrl
wire stall_id;

// ID/EX -> EX
wire [`AddrLen - 1 : 0] pc_idex_ex;
wire [`RegLen - 1 : 0] reg1_idex_ex, reg2_idex_ex, rd_idex_ex, br_offset_idex_ex;
wire rd_enable_idex_ex;
wire [`OpCodeLen - 1 : 0] aluop_idex_ex;
wire [`OpSelLen - 1 : 0] alusel_idex_ex;

// EX -> EX/MEM
wire [`RegLen - 1 : 0] rd_data_ex_exmem;
wire [`RegAddrLen - 1 : 0] rd_addr_ex_exmem;
wire rd_enable_ex_exmem;
wire load_enable_ex_exmem;
wire store_enable_ex_exmem;
wire [`AddrLen - 1 : 0] mem_addr_ex_exmem;
wire [`OpCodeLen - 1 : 0] load_store_type_ex_exmem;

// EX -> PC_REG, IF/ID, ID/EX
wire jump_ex_multi;
wire [`AddrLen - 1 : 0] jump_addr;

// EX/MEM -> MEM
wire [`RegLen - 1 : 0] rd_data_exmem_mem;
wire [`RegAddrLen - 1 : 0] rd_addr_exmem_mem;
wire rd_enable_exmem_mem;
wire load_enable_exmem_mem;
wire store_enable_exmem_mem;
wire [`AddrLen - 1 : 0] mem_addr_exmem_mem;
wire [`OpCodeLen - 1 : 0] load_store_type_exmem_mem;

// MEM -> MEM/WB
wire [`RegLen - 1 : 0] rd_data_mem_memwb;
wire [`RegAddrLen - 1 : 0] rd_addr_mem_memwb;
wire rd_enable_mem_memwb;

// MEM -> StallCtrl
wire stall_mem;

// MEM -> MemCtrl
wire mem_needed;
wire [`RegLen - 1 : 0] mem_sdata;
wire [`AddrLen - 1 : 0] mem_addr;
wire [2 : 0] mem_width;
wire mem_read_write;

// MemCtrl -> MEM
wire mem_rdy;
wire mem_busy;
wire [`RegLen - 1 : 0] mem_ldata;

// MEM/WB -> Register
wire write_enable;
wire [`RegAddrLen - 1 : 0] write_addr;
wire [`RegLen - 1 : 0] write_data;

// StallCtrl -> PC_REG/IF_ID/ID_EX/EX_MEM/MEM_WB
wire [`PipelineNum - 1 : 0] stall_o;

// EX -> ID forwarding
wire ex_fw;
wire [`RegLen - 1 : 0] ex_fw_data;
wire [`RegAddrLen - 1 : 0] ex_fw_addr;
wire is_load_ex_id;

// MEM -> ID forwarding
wire mem_fw;
wire [`RegLen - 1 : 0] mem_fw_data;
wire [`RegAddrLen - 1 : 0] mem_fw_addr;

//Instantiation
pc_reg pc_reg0(
      .clk(clk_in),
      .rst(rst_im),
      .pc(pc_pc_if),
      .chip_enable(chip_enable_pc_if),
      .stall_i(stall_o),
      .jump_i(jump_ex_multi && !stall_o[3]),
      .jump_addr_i(jump_addr)
);

If if0(
      .clk(clk_in),
      .rst(rst_im),
      .pc(pc_pc_if),
      .chip_enable(chip_enable_pc_if),
      .pc_to_IFID(pc_if_ifid),
      .inst_to_IFID(inst_if_ifid),
      .stall_to_StallCtrl(stall_if),
      .inst_data_from_MemCtrl(inst_data),
      .inst_rdy_from_MemCtrl(inst_rdy),
      .inst_busy_from_MemCtrl(inst_busy),
      .inst_needed_to_MemCtrl(inst_needed),
      .inst_addr_to_MemCtrl(inst_addr)
);

if_id if_id0(
      .clk(clk_in),
      .rst(rst_im),
      .if_pc_i(pc_if_ifid),
      .if_inst_i(inst_if_ifid),
      .id_pc_o(pc_ifid_id),
      .id_inst_o(inst_ifid_id),
      .stall_i(stall_o),
      .jump_i(jump_ex_multi && !stall_o[3])
);

id id0(
      .rst(rst_im),
      .ex_fw(ex_fw),
      .ex_fw_data(ex_fw_data),
      .ex_fw_addr(ex_fw_addr),
      .is_load(is_load_ex_id),
      .mem_fw(mem_fw),
      .mem_fw_data(mem_fw_data),
      .mem_fw_addr(mem_fw_addr),

      .pc(pc_ifid_id),
      .inst(inst_ifid_id),
      .reg1_data_i(reg1_data),
      .reg2_data_i(reg2_data),
      .reg1_addr_o(reg1_addr),
      .reg1_read_enable(reg1_read_enable),
      .reg2_addr_o(reg2_addr),
      .reg2_read_enable(reg2_read_enable),

      .pc_o(pc_id_idex),
      .reg1(reg1_id_idex),
      .reg2(reg2_id_idex),
      .br_offset(br_offset_id_idex),
      .rd(rd_id_idex),
      .rd_enable(rd_enable_id_idex),
      .aluop(aluop_id_idex),
      .alusel(alusel_id_idex),
      .stall_id_o(stall_id)
);
      
register register0(
      .clk(clk_in),
      .rst(rst_im),
      .write_enable(write_enable),
      .write_addr(write_addr),
      .write_data(write_data),
      .read_enable1(reg1_read_enable),
      .read_addr1(reg1_addr),
      .read_data1(reg1_data),
      .read_enable2(reg2_read_enable),
      .read_addr2(reg2_addr),
      .read_data2(reg2_data)
);

id_ex id_ex0(
      .clk(clk_in),
      .rst(rst_im),
      .pc_i(pc_id_idex),
      .id_reg1(reg1_id_idex),
      .id_reg2(reg2_id_idex),
      .id_br_offset(br_offset_id_idex),
      .id_rd(rd_id_idex),
      .id_rd_enable(rd_enable_id_idex),
      .id_aluop(aluop_id_idex),
      .id_alusel(alusel_id_idex),

      .pc_o(pc_idex_ex),
      .ex_reg1(reg1_idex_ex),
      .ex_reg2(reg2_idex_ex),
      .ex_br_offset(br_offset_idex_ex),
      .ex_rd(rd_idex_ex),
      .ex_rd_enable(rd_enable_idex_ex),
      .ex_aluop(aluop_idex_ex),
      .ex_alusel(alusel_idex_ex),
      .stall_i(stall_o),
      .jump_i(jump_ex_multi && !stall_o[3])
);

ex ex0(
      .rst(rst_im),
      .pc(pc_idex_ex),
      .reg1(reg1_idex_ex),
      .reg2(reg2_idex_ex),
      .br_offset(br_offset_idex_ex),
      .rd(rd_idex_ex),
      .rd_enable(rd_enable_idex_ex),
      .aluop(aluop_idex_ex),
      .alusel(alusel_idex_ex),
      
      .rd_data_o(rd_data_ex_exmem),
      .rd_addr(rd_addr_ex_exmem),
      .rd_enable_o(rd_enable_ex_exmem),
      .load_enable(load_enable_ex_exmem),
      .store_enable(store_enable_ex_exmem),
      .mem_addr(mem_addr_ex_exmem),
      .load_store_type(load_store_type_ex_exmem),

      .jump_enable(jump_ex_multi),
      .jump_addr(jump_addr),

      .ex_fw(ex_fw),
      .ex_fw_data(ex_fw_data),
      .ex_fw_addr(ex_fw_addr),
      .is_load(is_load_ex_id)
);
      
ex_mem ex_mem0(
      .clk(clk_in),
      .rst(rst_im),
      .ex_rd_data(rd_data_ex_exmem),
      .ex_rd_addr(rd_addr_ex_exmem),
      .ex_rd_enable(rd_enable_ex_exmem),
      .load_enable_i(load_enable_ex_exmem),
      .store_enable_i(store_enable_ex_exmem),
      .mem_addr_i(mem_addr_ex_exmem),
      .load_store_type_i(load_store_type_ex_exmem),

      .mem_rd_data(rd_data_exmem_mem),
      .mem_rd_addr(rd_addr_exmem_mem),
      .mem_rd_enable(rd_enable_exmem_mem),
      .load_enable_o(load_enable_exmem_mem),
      .store_enable_o(store_enable_exmem_mem),
      .mem_addr_o(mem_addr_exmem_mem),
      .load_store_type_o(load_store_type_exmem_mem),

      .stall_i(stall_o)
);
              
mem mem0(
      .rst(rst_im),
      .rd_data_i(rd_data_exmem_mem),
      .rd_addr_i(rd_addr_exmem_mem),
      .rd_enable_i(rd_enable_exmem_mem),
      .load_enable_i(load_enable_exmem_mem),
      .store_enable_i(store_enable_exmem_mem),
      .mem_addr_i(mem_addr_exmem_mem),
      .load_store_type_i(load_store_type_exmem_mem),

      .rd_data_o(rd_data_mem_memwb),
      .rd_addr_o(rd_addr_mem_memwb),
      .rd_enable_o(rd_enable_mem_memwb),

      .stall(stall_mem),

      .mem_rdy(mem_rdy),
      .mem_busy(mem_busy),
      .mem_ldata(mem_ldata),

      .mem_needed(mem_needed),
      .mem_sdata(mem_sdata),
      .mem_addr(mem_addr),
      .mem_width(mem_width),
      .mem_read_write(mem_read_write),

      .mem_fw(mem_fw),
      .mem_fw_data(mem_fw_data),
      .mem_fw_addr(mem_fw_addr)
);

wire temp_rw_wr;
assign mem_wr = ~temp_rw_wr;

mem_ctrl mem_ctrl0(
      .clk(clk_in),
      .rst(rst_im),
      .is_jump(jump_ex_multi && !stall_o[3]),

      .inst_needed(inst_needed),
      .inst_addr(inst_addr),

      .inst_data(inst_data),
      .inst_rdy(inst_rdy),
      .inst_busy(inst_busy),

      .mem_needed(mem_needed),
      .mem_sdata(mem_sdata),
      .mem_addr(mem_addr),
      .mem_width(mem_width),
      .mem_read_write(mem_read_write),

      .mem_rdy(mem_rdy),
      .mem_busy(mem_busy),
      .mem_ldata(mem_ldata),

      .ram_i(mem_din),
      .ram_o(mem_dout),
      .ram_addr(mem_a),
      .ram_read_write(temp_rw_wr)
);

mem_wb mem_wb0(
      .clk(clk_in),
      .rst(rst_im),
      .mem_rd_data(rd_data_mem_memwb),
      .mem_rd_addr(rd_addr_mem_memwb),
      .mem_rd_enable(rd_enable_mem_memwb),
      .wb_rd_data(write_data),
      .wb_rd_addr(write_addr),
      .wb_rd_enable(write_enable),
      .stall_i(stall_o)
);

stall_ctrl stall_ctrl0(
      .clk(clk_in),
      .rst(rst_im),
      .stall_if_i(stall_if),
      .stall_id_i(stall_id),
      .stall_mem_i(stall_mem),
      .stall_o(stall_o)
);

endmodule