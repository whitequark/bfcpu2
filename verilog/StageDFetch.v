`include "Constants.v"

module StageDFetch (
	clk,
	reset,

	dp,

	dce,
	da,
	dd,

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

	output                     dce;
	output     [A_WIDTH - 1:0] da;
	input      [D_WIDTH - 1:0] dd;

	input      [`OPCODE_MSB:0] operation_in;
	input      drdy_in;
	output reg ack;

	output reg [`OPCODE_MSB:0] operation;
	output reg drdy;
	input      ack_in;

	assign da  = dp;
	assign dce = !reset;

	always @(posedge clk) begin
		if (reset) begin
			operation <= 0;
			drdy      <= 0;
			ack       <= 0;
		end else begin
			operation <= operation_in;
			drdy      <= drdy_in;
			ack       <= ack_in;
		end
	end

endmodule
