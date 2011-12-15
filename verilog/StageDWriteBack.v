`include "Constants.v"

module StageDWriteBack (
	clk,
	reset,

	dp,

	dce,
	da,
	dq,

	a_in,

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

	input      [D_WIDTH - 1:0] a_in;

	input      [`OPCODE_MSB:0] operation_in;
	input      drdy_in;
	output reg ack;

	output reg [`OPCODE_MSB:0] operation;
	output reg drdy;
	input      ack_in;

	reg queued_d;

	function should_write_d;
	input [7:0] operation;
	begin
		should_write_d = (operation[`OP_INC] || operation[`OP_DEC] ||
					operation[`OP_IN]);
	end
	endfunction

	assign da = dp;
	assign dce = !reset && queued_d;

	always @(posedge clk) begin
		if (reset) begin
			operation <= 0;
			drdy      <= 0;
			ack       <= 0;

			queued_d  <= 0;
		end else begin
			operation <= operation_in;
			drdy      <= drdy_in;
			ack       <= ack_in;

			if (should_write_d(operation_in)) begin
				dq       <= a_in;
				queued_d <= 1'b1;
			end else begin
				dq       <= 0;
				queued_d <= 0;
			end
		end
	end

endmodule
