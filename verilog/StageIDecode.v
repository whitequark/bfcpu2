`include "Constants.v"

module StageIDecode(
	clk,
	reset,
	
	opcode_in,
	ack,
	drdy_in,
	
	operation,
	ack_in,
	drdy
);

	input clk;
	input reset;

	input      [7:0] opcode_in;
	output reg       ack;
	input            drdy_in;
	
	output reg [`OPCODE_MSB:0] operation;
	input            ack_in;
	output reg       drdy;
	
	always @(posedge clk) begin
		if (reset) begin
			operation <= 0;
			drdy      <= 0;
			ack       <= 0;
		end else begin
			ack       <= ack_in;

			if (drdy_in) begin
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
		
				drdy      <= 1'b1;
			end else begin
				operation <= 8'b0000_0000;
				drdy      <= 1'b0;
			end
		end
	end

endmodule
