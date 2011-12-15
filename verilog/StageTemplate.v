`include "Constants.v"

module StageX (
	clk,
	reset,

	operation_in,
	ack_in,

	operation,
	ack,
);

	input clk;
	input reset;

	input      [`OPCODE_MSB:0] operation_in;
	output reg ack;

	output reg [`OPCODE_MSB:0] operation;
	input      ack_in;

	assign ack = ack_in;

	always @(posedge clk) begin
		if (reset) begin
			operation <= 0;
		end else begin
			if (ack_in) begin
				operation <= operation_in;
			end
		end
	end

endmodule
