module StageIFetch (
	clk,
	reset,

	pc,

	ice,
	ia,
	id,

	step_pc,

	opcode,
	ack_in
);

	parameter A_WIDTH = 12;
	parameter D_WIDTH = 8;

	input clk;
	input reset;

	input      [A_WIDTH - 1:0] pc;

	output                     ice;
	output     [A_WIDTH - 1:0] ia;
	input      [D_WIDTH - 1:0] id;

	output                     step_pc;

	output reg [D_WIDTH - 1:0] opcode;

	input                      ack_in;

	assign ia  = pc;
	assign ice = !reset && ack_in;

	/*
	 * step_pc=1 means that at the _next_ cycle PC will be
	 * increased. Thus, if we will do a successful fetch
	 * _now_, we should increase it _then_.
	 */
	assign step_pc = !reset && ack_in;

	reg prefetched;

	always @(posedge clk) begin
		if (reset) begin
			prefetched <= 0;

			opcode     <= 0;
		end else begin
			prefetched <= 1'b1;

			if (ack_in && prefetched)
				opcode <= id;
		end
	end

endmodule
