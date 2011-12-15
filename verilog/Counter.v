module Counter (
   clk,
   reset,
   ce,
   d,
   q,
   load,
   down
);

	parameter WIDTH = 8;

	input                    clk;
	input                    reset;
	input                    ce;
	input      [WIDTH - 1:0] d;
	output reg [WIDTH - 1:0] q;
	input                    load;
	input                    down;

	always @(posedge clk) begin
		if (reset)
			q <= 0;
		else begin
			if (ce) begin
				if (load)
					q <= d;
				else if(down)
					q <= q - 8'b1;
				else /* !load && !down */
					q <= q + 8'b1;
			end
		end
	end

endmodule
