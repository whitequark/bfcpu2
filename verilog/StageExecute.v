`include "Constants.v"

module StageExecute (
	clk,
	reset,

	dp,
	dp_ce,
	dp_down,

	dp_cache,

	dce,
	da,
	dd,

	cd,
	crda,
	cack,

	a,

	operation_in,
	ack_in,

	operation,
	ack
);

	parameter A_WIDTH = 12;
	parameter D_WIDTH = 8;

	input clk;
	input reset;

	input      [A_WIDTH - 1:0] dp;
	output                     dp_ce;
	output                     dp_down;

	output                     dce;
	output     [A_WIDTH - 1:0] da;
	input      [D_WIDTH - 1:0] dd;

	input                [7:0] cd;
	input                      crda;
	output                     cack;

	output reg [D_WIDTH - 1:0] a;

	input      [`OPCODE_MSB:0] operation_in;
	output     ack;

	output reg [`OPCODE_MSB:0] operation;
	input      ack_in;

	reg prefetched;

	/*
	 * Data pointer manipulation
	 */
	assign dp_ce   = ack_in && (operation_in[`OP_INCDP] || operation_in[`OP_DECDP]);
	assign dp_down = ack_in &&  operation_in[`OP_DECDP];

	output reg [A_WIDTH - 1:0] dp_cache;

	/*
	 * RAW hazard handling: register forwarding
	 */
	wire dirty_datum;
	assign dirty_datum = operation[`OP_INC] || operation[`OP_DEC] ||
				operation[`OP_IN];

	wire do_mem_fetch, do_reg_forward;

	assign do_mem_fetch   = need_fetch_mem && !dirty_datum;
	assign do_reg_forward = need_fetch_mem && dirty_datum;

	/*
	 * Reading from DRAM
	 */
	wire need_fetch_mem;
	assign need_fetch_mem = (operation_in[`OP_INC] || operation_in[`OP_DEC] ||
					operation_in[`OP_OUT] || operation_in[`OP_LOOPBEGIN] ||
					operation_in[`OP_LOOPEND]);

	assign da  = dp;
	assign dce = do_mem_fetch;

	wire   [D_WIDTH - 1:0] data_input;
	assign                 data_input = do_reg_forward ? a : dd;

	assign datum_ready = (do_mem_fetch && prefetched) || do_reg_forward;

	/*
	 * Reading from EXT
	 */
	wire need_fetch_ext;
	assign need_fetch_ext = operation_in[`OP_IN];

	assign cack = crda && need_fetch_ext;

	/*
	 * Wait states
	 */
	wire ext_wait;
	assign ext_wait = (need_fetch_ext && !crda) || (do_mem_fetch && !prefetched);

	/*
	 * ACKing the previous stage
	 */
	assign ack = ack_in && !ext_wait;

	always @(posedge clk) begin
		if (reset)
			prefetched <= 0;
		else
			prefetched <= do_mem_fetch;
	end

	always @(posedge clk) begin
		if (reset) begin
			operation  <= 0;

			dp_cache   <= 0;
			a          <= 0;
		end else begin
			dp_cache   <= dp;

			if (ack_in && ext_wait) begin
				operation <= 0; /* Bubble */
				a         <= 0;
			end else if(ack_in) begin
				operation <= operation_in;

				if (datum_ready)
					if (operation_in[`OP_INC])
						a   <= data_input + 1;
					else if (operation_in[`OP_DEC])
						a   <= data_input - 1;
					else
						a   <= data_input;
				else if (need_fetch_ext && crda)
					a      <= cd;
				else
					a      <= 0;
			end
		end
	end

endmodule
