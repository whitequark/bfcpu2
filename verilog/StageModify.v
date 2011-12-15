`include "Constants.v"

module StageModify(
	clk,
	reset,
	
	operation_in,
	ack_in,
	drdy,
	
	operation,
	ack,
	drdy_in
);

	input clk;
	input reset;

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
