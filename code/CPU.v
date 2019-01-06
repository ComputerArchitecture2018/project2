module CPU
(
    clk_i, 
    rst_i,
    start_i
);

// Ports
input               clk_i;
input               rst_i;
input               start_i;

wire[31:0]inst_addr;
wire[31:0]next_inst_addr;
wire PC_Mux_select;
wire IF_stall_signal,IF_flush_signal;
wire ID_beq_result;
wire[31:0]pc_input;
wire[11:0]immgen_12bit_ID;
wire[2:0]alu_control_EX;
wire[1:0]alu_op_EX;
wire alu_src_EX;

wire[31:0]inst_IF,inst_ID,inst_EX;
wire[31:0]pc_ID;
wire[31:0]rs1_data_ID,rs1_data_EX;
wire[31:0]rs2_data_ID,rs2_data_EX,rs2_data_MEM;
wire[31:0]imm_ID,imm_EX,imm_shifted_ID;
wire[31:0]alu_result_EX,alu_result_MEM,alu_result_WB;
wire[4:0]rs1_ID,rs1_EX;
wire[4:0]rs2_ID,rs2_EX,rs2_MEM;
wire[4:0]rsd_ID,rsd_EX,rsd_MEM,rsd_WB;
wire[2:0]opcode_ID,opcode_EX,opcode_MEM,opcode_WB;
wire valid_ID,valid_EX,valid_MEM,valid_WB;
wire[31:0]memory_data_MEM,memory_data_WB;
wire[31:0]add_result_Ah_Jia;
wire reg_src_WB;//0:alu, 1:memory
wire[31:0]register_input_WB;
wire pc_write;
wire Hazard_Detect_Valid,Control_Valid;
wire Control_IF_flush_signal,Hazard_IF_flush_signal;
wire all_stall_signal;

assign valid_ID=Hazard_Detect_Valid&Control_Valid;
assign pc_write=~IF_stall_signal&&~all_stall_signal;
assign IF_flush_signal=Control_IF_flush_signal;
assign IF_stall_signal=Hazard_IF_flush_signal;
assign reg_src_WB=(opcode_WB==3'b011||opcode_WB==3'b001)? 1'b0:
				  (opcode_WB==3'b000)? 1'b1:
				  1'bX;

Control Control(
	.inst       (inst_ID),
	.Beq        (ID_beq_result),
	.flush_op   (Control_IF_flush_signal),
	.Opcode     (opcode_ID),
	.Valid      (Control_Valid),
	.PC_MUX_op   (PC_Mux_select)
);

Hazard_Detect Hazard_Detect(
	.valid_i(valid_EX),
	.ID_EX_M	(opcode_EX),
	.reg1_addr	(inst_ID[19:15]),
	.reg2_addr	(inst_ID[24:20]),
	.regd_addr	(rsd_EX),
	.IF_Op	(Hazard_IF_flush_signal),
	.Valid	(Hazard_Detect_Valid)
);

Buf_IF_ID Buffer_IF_ID(
	.clk_i(clk_i),
	.rst_i(rst_i),
	.pc_i(inst_addr),
	.inst_i(inst_IF),
	.IF_stall_i(IF_stall_signal||all_stall_signal),
	.IF_flush_i(IF_flush_signal),
	.pc_o(pc_ID),
	.inst_o(inst_ID)
);

wire[31:0]rs1_data_raw_EX,rs2_data_raw_EX;

Buf_ID_EX Buffer_ID_EX(
	.clk_i(clk_i),
	.rst_i(rst_i),
	.all_stall_i(all_stall_signal),
	.inst_i(inst_ID),
	.rs1_data_i(rs1_data_ID),
	.rs2_data_i(rs2_data_ID),
	.imm_i(imm_ID),
	.rs1_i(rs1_ID),
	.rs2_i(rs2_ID),
	.rsd_i(rsd_ID),
	.Op_i(opcode_ID),
	.valid_i(valid_ID),
	.inst_o(inst_EX),
	.rs1_data_o(rs1_data_raw_EX),
	.rs2_data_o(rs2_data_raw_EX),
	.imm_o(imm_EX),
	.rs1_o(rs1_EX),
	.rs2_o(rs2_EX),
	.rsd_o(rsd_EX),
	.Op_o(opcode_EX),
	.valid_o(valid_EX)
);

Buf_EX_MEM Buffer_EX_MEM(
	.clk_i(clk_i),
	.rst_i(rst_i),
	.all_stall_i(all_stall_signal),
	.alu_result_i(alu_result_EX),
	.rs2_data_i(rs2_data_EX),
	.rs2_i(rs2_EX),
	.rsd_i(rsd_EX),
	.Op_i(opcode_EX),
	.valid_i(valid_EX),
	.alu_result_o(alu_result_MEM),
	.rs2_data_o(rs2_data_MEM),
	.rs2_o(rs2_MEM),
	.rsd_o(rsd_MEM),
	.Op_o(opcode_MEM),
	.valid_o(valid_MEM)
);

Buf_MEM_WB Buffer_MEM_WB(
	.clk_i(clk_i),
	.rst_i(rst_i),
	.all_stall_i(all_stall_signal),
	.alu_result_i(alu_result_MEM),
	.memory_data_i(memory_data_MEM),
	.rsd_i(rsd_MEM),
	.Op_i(opcode_MEM),
	.valid_i(valid_MEM),
	.alu_result_o(alu_result_WB),
	.memory_data_o(memory_data_WB),
	.rsd_o(rsd_WB),
	.Op_o(opcode_WB),
	.valid_o(valid_WB)
);

Beq ID_Beq(
	.data1_i(rs1_data_ID),
	.data2_i(rs2_data_ID),
	.Beq_Op(opcode_ID==3'b110 ? 1'b1:1'b0),
	.Beq(ID_beq_result)
);

Shift_Left Imm_Shift_Left(
	.data_in(imm_ID),
	.data_o(imm_shifted_ID)
);

Adder Add_Ah_Jia(//our 阿加 <3
	.data1_in(pc_ID),
	.data2_in(imm_shifted_ID),
	.data_o(add_result_Ah_Jia)
);

Adder Add_PC(
    .data1_in   (inst_addr),
    .data2_in   (32'd4),
    .data_o     (next_inst_addr)
);


PC PC
(
	.clk_i(clk_i),
	.rst_i(rst_i),
	.start_i(start_i),
	.stall_i(1'b0),
	.pcEnable_i(pc_write),
    .pc_i       (pc_input),
    .pc_o       (inst_addr)
);

MUX32 PC_Mux(
	.data1_i(next_inst_addr),
	.data2_i(add_result_Ah_Jia),
	.select_i(PC_Mux_select),
	.data_o(pc_input)
);

Instruction_Memory Instruction_Memory(
    .addr_i     (inst_addr), 
    .instr_o    (inst_IF)
);

wire[31:0] mem_addr_o,mem_addr_i;
wire[255:0] mem_data_o,mem_data_i;
wire mem_enable_o,mem_ack_i,mem_write_o;

Data_Memory Data_Memory
(
	.clk_i(clk_i),
	.rst_i(rst_i),
	.addr_i(mem_addr_o),
	.data_i(mem_data_o),
	.enable_i(mem_enable_o),
	.write_i(mem_write_o),
	.ack_o(mem_ack_i),
	.data_o(mem_data_i)
);

wire foo;
assign all_stall_signal=foo;

//data cache
dcache_top dcache
(
    // System clock, reset and stall
	.clk_i(clk_i), 
	.rst_i(rst_i),
	
	// to Data Memory interface		
	.mem_data_i(mem_data_i), 
	.mem_ack_i(mem_ack_i), 	
	.mem_data_o(mem_data_o), 
	.mem_addr_o(mem_addr_o), 	
	.mem_enable_o(mem_enable_o), 
	.mem_write_o(mem_write_o), 
	
	// to CPU interface	
	.p1_data_i(rs2_data_MEM), 
	.p1_addr_i(alu_result_MEM), 	
	.p1_MemRead_i(1'b1), 
	.p1_MemWrite_i((valid_MEM&&opcode_MEM==3'b010)? 1'b1:1'b0), 
	.p1_data_o(memory_data_MEM), 
	.p1_stall_o(foo)
);

MUX32 RegWriteSrc_Mux(
	.data1_i(alu_result_WB),
	.data2_i(memory_data_WB),
	.select_i(reg_src_WB),
	.data_o(register_input_WB)
);

wire regwrite_MEM,regwrite_WB;
assign regwrite_MEM=valid_MEM&&
					(opcode_MEM==3'b011||
					 opcode_MEM==3'b001||
					 opcode_MEM==3'b000)? 1'b1:1'b0;
assign regwrite_WB =valid_WB&&
					(opcode_WB==3'b011||
					 opcode_WB==3'b001||
					 opcode_WB==3'b000)? 1'b1:1'b0;

assign rs1_ID=inst_ID[19:15];
assign rs2_ID=inst_ID[24:20];
assign rsd_ID=inst_ID[11:7];

Registers Registers(
    .clk_i      (clk_i),
    .RSaddr_i   (rs1_ID),
    .RTaddr_i   (rs2_ID),
    .RDaddr_i   (rsd_WB), 
    .RDdata_i   (register_input_WB),
    .RegWrite_i (regwrite_WB),
    .RSdata_o   (rs1_data_ID), 
    .RTdata_o   (rs2_data_ID) 
);

ImmGen ID_ImmGen(
	.inst_i(inst_ID),
	.imm_o(immgen_12bit_ID)
);

Sign_Extend Sign_Extend(
    .data_i     (immgen_12bit_ID),
    .data_o     (imm_ID)
);

wire[31:0]alu_data2_EX;
wire[1:0]forward_A,forward_B;

Forwarding_Unit Forwarding_Unit(//TODO
	.Rs1_i(rs1_EX),
	.Rs2_i(rs2_EX),
	.RegWrite_p_i(regwrite_MEM),
	.Rd_p_i(rsd_MEM),
	.RegWrite_pp_i(regwrite_WB),
	.Rd_pp_i(rsd_WB),
	.ForwardA_o(forward_A),
	.ForwardB_o(forward_B)
);

MUX32_3i MUX_ALU_data1(
	.data1_i(rs1_data_raw_EX),
	.data2_i(alu_result_MEM),
	.data3_i(register_input_WB),//might be memory data
	.select_i(forward_A),
	.data_o(rs1_data_EX)
);

MUX32_3i MUX_ALU_data2(
	.data1_i(rs2_data_raw_EX),
	.data2_i(alu_result_MEM),
	.data3_i(register_input_WB),
	.select_i(forward_B),
	.data_o(rs2_data_EX)
);

ALUSrc_Gen EX_ALUSrc_Gen(
	.opcode_i(opcode_EX),
	.ALUSrc_o(alu_src_EX)
);

MUX32 MUX_ALUSrc(
    .data1_i    (rs2_data_EX),
    .data2_i    (imm_EX),
    .select_i   (alu_src_EX),
    .data_o     (alu_data2_EX)
);

ALU ALU(
    .data1_i    (rs1_data_EX),
    .data2_i    (alu_data2_EX),
    .ALUCtrl_i  (alu_control_EX),
    .data_o     (alu_result_EX)
);

ALUOp_Gen EX_ALUOp_Gen(
	.opcode_i(opcode_EX),
	.ALU_Op_o(alu_op_EX)
);

ALU_Control ALU_Control(
    .funct_i    ({{inst_EX[30]},{inst_EX[25]},{inst_EX[14:12]}}),
    .ALUOp_i    (alu_op_EX),
    .ALUCtrl_o  (alu_control_EX)
);


endmodule
