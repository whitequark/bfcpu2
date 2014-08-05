module IROM (
	clk,
	ce,
	a,
	q
);

	parameter D_WIDTH =  8;
	parameter A_WIDTH =  12;
	parameter A_DEPTH = (1 << A_WIDTH);

	input  clk;
	input  ce;

	input      [A_WIDTH - 1:0] a;
	output reg [D_WIDTH - 1:0] q;

	reg        [D_WIDTH - 1:0] memory[0:A_DEPTH - 1];

	always @(posedge clk) begin
		if(ce)
			q <= memory[a];
	end

	integer i;
	initial
	begin
		for(i = 0; i < A_DEPTH; i = i + 1)
			memory[i] = 0;

		// $readmemh("irom.h", memory);
	end

endmodule
