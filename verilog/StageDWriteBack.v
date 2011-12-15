`include "Constants.v"

module StageDWriteBack (
	clk,
	reset,

	dp,

	dce,
	da,
	dq,

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
	output reg [D_WIDTH - 1:0] dq;

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
		end else begin
			operation <= operation_in;
			drdy      <= drdy_in;
			ack       <= ack_in;
		end
	end

endmodule
