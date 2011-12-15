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

	/* Writing to DRAM. */
	function should_write_d;
	input [7:0] operation;
	begin
		should_write_d = (operation[`OP_INC] || operation[`OP_DEC] ||
					operation[`OP_IN]);
	end
	endfunction

	assign da  = dp;
	assign dce = should_write_d(operation_in);
	assign dq  = a_in;

	/* Writing to EXT. */
	function should_write_x;
	input [7:0] operation;
	begin
		should_write_x = operation[`OP_OUT];
	end
	endfunction

	assign cq   = a_in;
	assign cwre = !cbsy && should_write_x(operation_in);

	wire ext_wait;
	assign ext_wait = (should_write_x(operation_in) && cbsy);

	/* ACKing the previous stage */
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
