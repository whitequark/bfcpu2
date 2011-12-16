`include "Constants.v"

module StageWriteback (
	clk,
	reset,

	dp,

	dce,
	da,
	dq,

	cq,
	cwre,
	cbsy,

	a_in,

	operation_in,
	ack_in,

	operation,
	ack
);

	parameter A_WIDTH = 12;
	parameter D_WIDTH = 8;

	input clk;
	input reset;

	input      [A_WIDTH - 1:0] dp;

	output                     dce;
	output     [A_WIDTH - 1:0] da;
	output     [D_WIDTH - 1:0] dq;

	output               [7:0] cq;
	output                     cwre;
	input                      cbsy;

	input      [D_WIDTH - 1:0] a_in;

	input      [`OPCODE_MSB:0] operation_in;
	output                     ack;

	output reg [`OPCODE_MSB:0] operation;
	input                      ack_in;

	/*
	 * Writing to DRAM
	 */
	wire need_write_mem;
	assign need_write_mem = (operation_in[`OP_INC] || operation_in[`OP_DEC] ||
					operation_in[`OP_IN]);

	assign da  = dp;
	assign dce = need_write_mem;
	assign dq  = a_in;

	/*
	 * Writing to EXT
	 */
	wire need_write_ext;
	assign need_write_ext = operation_in[`OP_OUT];

	assign cq   = a_in;
	assign cwre = !cbsy && need_write_ext;

	wire ext_wait;
	assign ext_wait = need_write_ext && cbsy;

	/*
	 * ACKing the previous stage
	 */
	assign ack = ack_in && !ext_wait;

	always @(posedge clk) begin
		if (reset) begin
			operation <= 0;
		end else begin
			if (ack_in && !ext_wait)
				operation <= operation_in;
			else if (ack_in)
				operation <= 0; /* Bubble */
		end
	end

endmodule
