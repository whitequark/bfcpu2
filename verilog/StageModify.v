`include "Constants.v"

module StageModify (
	clk,
	reset,

	a_in,
	a,

	operation_in,
	ack_in,

	operation,
	ack
);

	parameter D_WIDTH = 8;

	input clk;
	input reset;

	input      [D_WIDTH - 1:0] a_in;
	output reg [D_WIDTH - 1:0] a;

	input      [`OPCODE_MSB:0] operation_in;
	output     ack;

	output reg [`OPCODE_MSB:0] operation;
	input      ack_in;

	assign ack = ack_in;

	always @(posedge clk) begin
		if (reset) begin
			operation <= 0;

			a         <= 0;
		end else begin
			if (ack_in) begin
				operation <= operation_in;

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
	end

endmodule
