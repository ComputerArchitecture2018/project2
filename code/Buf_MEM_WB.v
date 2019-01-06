module Buf_MEM_WB(
	clk_i,
	rst_i,
	all_stall_i,
	alu_result_i,
	memory_data_i,
	rsd_i,
	Op_i,
	valid_i,
	alu_result_o,
	memory_data_o,
	rsd_o,
	Op_o,
	valid_o,
);
input clk_i,rst_i,all_stall_i;
input[31:0]alu_result_i,memory_data_i;
output[31:0]alu_result_o,memory_data_o;
input[4:0]rsd_i;
output[4:0]rsd_o;
input[2:0] Op_i;
output[2:0] Op_o;
input valid_i;
output valid_o;

reg[31:0]alu_result_reg_i,memory_data_reg_i;
reg[31:0]alu_result_reg_o,memory_data_reg_o;
reg[4:0]rsd_reg_i,rsd_reg_o;
reg[2:0]Op_reg_i;
reg[2:0]Op_reg_o;
reg valid_reg_i;
reg valid_reg_o;
assign alu_result_o=alu_result_reg_o;
assign memory_data_o=memory_data_reg_o;
assign rsd_o=rsd_reg_o;
assign Op_o=Op_reg_o;
assign valid_o=valid_reg_o;
always @(posedge clk_i or negedge rst_i) begin
	if(~all_stall_i)begin
		alu_result_reg_i<=rst_i==0?0:alu_result_i;
		memory_data_reg_i<=rst_i==0?0:memory_data_i;
		rsd_reg_i<=rst_i==0?0:rsd_i;
		Op_reg_i<=rst_i==0?0:Op_i;
		valid_reg_i<=rst_i==0?0:valid_i;
	end
end
always @(negedge clk_i or negedge rst_i) begin
	alu_result_reg_o<=rst_i==0?0:alu_result_reg_i;
	memory_data_reg_o<=rst_i==0?0:memory_data_reg_i;
	rsd_reg_o<=rst_i==0?0:rsd_reg_i;
	Op_reg_o<=rst_i==0?0:Op_reg_i;
	valid_reg_o<=rst_i==0?0:valid_reg_i;
end
endmodule
