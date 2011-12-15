module DRAM (
	clk,
	rce,
	ra,
	rq,
	wce,
	wa,
	wd
);

	parameter D_WIDTH =  8;
	parameter A_WIDTH =  12;
	parameter A_DEPTH = (1 << A_WIDTH);

	input  clk;

	input                      rce;
	input      [A_WIDTH - 1:0] ra;
	output reg [D_WIDTH - 1:0] rq;

	input                      wce;
	input      [A_WIDTH - 1:0] wa;
	input      [D_WIDTH - 1:0] wd;

	reg        [D_WIDTH - 1:0] memory[0:A_DEPTH - 1];

	always @(posedge clk) begin
		if (rce)
			rq <= memory[ra];

		if (wce)
			memory[wa] <= wd;
	end

	integer i;
	initial
	begin
		for(i = 0; i < A_DEPTH; i = i + 1)
			memory[i] = 0;
	end

endmodule
