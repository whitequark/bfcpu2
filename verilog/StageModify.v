`include "Constants.v"

module StageModify (
	clk,
	reset,

	a_in,
	a,

	operation_in,
	ack_in,
	drdy,

	operation,
	ack,
	drdy_in
);

	parameter D_WIDTH = 8;

	input clk;
	input reset;

	input      [D_WIDTH - 1:0] a_in;
	output reg [D_WIDTH - 1:0] a;

	input      [`OPCODE_MSB:0] operation_in;
	input      drdy_in;
	output reg ack;

	output reg [`OPCODE_MSB:0] operation;
	output reg drdy;
	input      ack_in;

	always @(posedge clk) begin
		if (reset) begin
			operation <= 0;
			drdy      <= 0;
			ack       <= 0;

			a         <= 0;
		end else begin
			operation <= operation_in;
			drdy      <= drdy_in;
			ack       <= ack_in;

			if (operation_in[`OP_INC])
				a      <= a_in + 1;
			else if (operation_in[`OP_DEC])
				a      <= a_in - 1;
			else if (operation_in[`OP_IN] || operation_in[`OP_OUT])
				a      <= a_in;
			else
				a      <= 0;
		end
	end

endmodule
