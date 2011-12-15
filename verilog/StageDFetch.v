`include "Constants.v"

module StageDFetch (
	clk,
	reset,

	dp,
	dp_ce,
	dp_down,

	dce,
	da,
	dd,

	a,

	operation_in,
	ack_in,
	drdy,

	operation,
	ack,
	drdy_in
);

	parameter A_WIDTH = 12;
	parameter D_WIDTH = 8;

	input clk;
	input reset;

	input      [A_WIDTH - 1:0] dp;
	output                     dp_ce;
	output                     dp_down;

	output                     dce;
	output     [A_WIDTH - 1:0] da;
	input      [D_WIDTH - 1:0] dd;

	output reg [D_WIDTH - 1:0] a;

	input      [`OPCODE_MSB:0] operation_in;
	input      drdy_in;
	output reg ack;

	output reg [`OPCODE_MSB:0] operation;
	output reg drdy;
	input      ack_in;

	/*
	 * Data pointer manipulation.
	 * This can be done with assign`s because dfetch never stalls the
	 * pipeline.
	 */
	assign dp_ce   = (operation_in[`OP_INCDP] || operation_in[`OP_DECDP]);
	assign dp_down =  operation_in[`OP_DECDP];

	/* Reading from DRAM. */
	reg queued_d;

	function should_fetch_d;
	input [`OPCODE_MSB:0] operation;
	begin
		should_fetch_d = (operation[`OP_INC] || operation[`OP_DEC] ||
					operation[`OP_OUT] || operation[`OP_LOOPBEGIN] ||
					operation[`OP_LOOPEND]);
	end
	endfunction

	assign da  = dp;
	assign dce = !reset && should_fetch_d(operation_in);

	always @(posedge clk) begin
		if (reset) begin
			operation <= 0;
			drdy      <= 0;
			ack       <= 0;

			a         <= 0;
			queued_d  <= 0;
		end else begin
			operation <= operation_in;
			drdy      <= drdy_in;
			ack       <= ack_in;

			if (queued_d)
				a      <= dd;
			else
				a      <= 0;

			queued_d  <= should_fetch_d(operation_in);
		end
	end

endmodule
