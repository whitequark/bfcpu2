module StageIFetch (
	clk,
	reset,

	pc,

	ice,
	ia,
	id,

	step_pc,

	opcode,
	ack_in,
	drdy
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

	output reg drdy;
	input      ack_in;

	reg queued;

	wire should_fetch = (!drdy || ack_in);

	assign ia  = pc;
	assign ice = !reset && should_fetch;

	/*
	 * step_pc=1 means that at the _next_ cycle PC will be
	 * increased. Thus, if we will do a successful fetch
	 * _now_, we should increase it _then_.
	 */
	assign step_pc = !reset && should_fetch;

	always @(posedge clk) begin
		if (reset) begin
			opcode  <= 0;
			drdy    <= 0;
			queued  <= 0;
		end else begin
			if (queued)
				opcode <= id;
			else
				opcode <= 0;

			drdy    <= queued;
			queued  <= should_fetch;
		end
	end

endmodule
