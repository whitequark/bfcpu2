`include "Constants.v"

module StageIDecode (
	clk,
	reset,

	opcode_in,
	ack,

	operation,
	ack_in
);

	input clk;
	input reset;

	input                [7:0] opcode_in;
	output                     ack;

	output reg [`OPCODE_MSB:0] operation;
	input                      ack_in;

	assign ack = ack_in;

	always @(posedge clk) begin
		if (reset) begin
			operation <= 0;
		end else begin
			if (ack_in) begin
				case (opcode_in)
					8'h3E:   operation <= 8'b0000_0001;
					8'h3C:   operation <= 8'b0000_0010;
					8'h2B:   operation <= 8'b0000_0100;
					8'h2D:   operation <= 8'b0000_1000;
					8'h2E:   operation <= 8'b0001_0000;
					8'h2C:   operation <= 8'b0010_0000;
					8'h5B:   operation <= 8'b0100_0000;
					8'h5D:   operation <= 8'b1000_0000;

					default: operation <= 8'b0000_0000;
				endcase
			end
		end
	end

endmodule
