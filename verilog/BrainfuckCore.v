`timescale 1ns / 1ps
`include "Common.tf"
`include "Constants.v"

module BrainfuckCore(
	clk,
	reset,

	/* IROM interface */
	ice,
	ia,
	id,

	/* DRAM read port */
	drce,
	dra,
	drd,

	/* DRAM write port */
	dwce,
	dwa,
	dwq,

	/* EXT read port */
	cd,
	crda,
	cack,

	/* EXT write port */
	cq,
	cwre,
	cbsy
);

	parameter IA_WIDTH = 12;
	parameter ID_WIDTH = 8;
	parameter DA_WIDTH = 12;
	parameter DD_WIDTH = 8;

	input clk;
	input reset;

	wire [IA_WIDTH - 1:0] pc;
	wire pc_ce;

	Counter #(
		.WIDTH(IA_WIDTH)
	) reg_pc (
		.clk(clk),
		.reset(reset),
		.ce(pc_ce),
		.q(pc),
		.d(12'b0),
		.load(1'b0),
		.down(1'b0)
	);

	wire [DA_WIDTH - 1:0] dp;
	wire dp_ce, dp_down;

	Counter #(
		.WIDTH(DA_WIDTH)
	) reg_dp (
		.clk(clk),
		.reset(reset),
		.ce(dp_ce),
		.q(dp),
		.d(12'b0),
		.load(1'b0),
		.down(dp_down)
	);

	output ice;
	output [IA_WIDTH - 1:0] ia;
	input  [ID_WIDTH - 1:0] id;

	output drce, dwce;
	output [DA_WIDTH - 1:0] dra;
	output [DA_WIDTH - 1:0] dwa;
	input  [DD_WIDTH - 1:0] drd;
	output [DD_WIDTH - 1:0] dwq;

	input  [7:0] cd;
	input        crda;
	output       cack;

	output [7:0] cq;
	output       cwre;
	input        cbsy;

	wire [ID_WIDTH - 1:0] idecode_opcode;
	wire                  idecode_ack;

	wire [`OPCODE_MSB:0]  execute_operation;
	wire                  execute_ack;
	wire [DD_WIDTH - 1:0] execute_a;

	wire [`OPCODE_MSB:0]  writeback_operation;
	wire                  writeback_ack;
	wire [DA_WIDTH - 1:0] writeback_dp;

	/*
	 * Fetch instruction, taking memory delays into
	 * account.
	 * This stage prefetches one instruction.
	 */
	StageIFetch #(
		.A_WIDTH(IA_WIDTH),
		.D_WIDTH(ID_WIDTH)
	) ifetch (
		.clk(clk),
		.reset(reset),

		/* PC register value, to get instruction address */
		.pc(pc),

		/* Has ifetch got an instruction last cycle? */
		.step_pc(pc_ce),

		/* IROM interface */
		.ice(ice),
		.ia(ia),
		.id(id),

		.opcode(idecode_opcode),
		.ack_in(idecode_ack)
	);

	/*
	 * Decode instruction. IDecode has fixed 8 bit width.
	 */
	StageIDecode idecode (
		.clk(clk),
		.reset(reset),

		.opcode_in(idecode_opcode),
		.ack(idecode_ack),

		.operation(execute_operation),
		.ack_in(execute_ack)
	);

	/*
	 * Execute the instruction.
	 * This stage prefetches one datum and maintains cache consistency
	 * on data pointer updates.
	 */
	StageExecute #(
		.A_WIDTH(DA_WIDTH),
		.D_WIDTH(DD_WIDTH)
	) execute (
		.clk(clk),
		.reset(reset),

		/* DP register value, to get a datum */
		.dp(dp),

		/* DP register increment and decrement control lines */
		.dp_ce(dp_ce),
		.dp_down(dp_down),

		/* DP register cache, to avoid WAW(mem,dp) hazard */
		.dp_cache(writeback_dp),

		/* DRAM read port interface */
		.dce(drce),
		.da(dra),
		.dd(drd),

		/* EXT read port interface */
		.cd(cd),
		.crda(crda),
		.cack(cack),

		/* Accumulator output */
		.a(execute_a),

		.operation_in(execute_operation),
		.ack(execute_ack),

		.operation(writeback_operation),
		.ack_in(writeback_ack)
	);

	/*
	 * Write accumulator back to DRAM or to I/O module.
	 */
	StageWriteback #(
		.A_WIDTH(DA_WIDTH),
		.D_WIDTH(DD_WIDTH)
	) writeback (
		.clk(clk),
		.reset(reset),

		/* DP register value, to write a datum */
		.dp(writeback_dp),

		/* DRAM write port interface */
		.dce(dwce),
		.da(dwa),
		.dq(dwq),

		/* EXT write port interface */
		.cq(cq),
		.cwre(cwre),
		.cbsy(cbsy),

		/* Accumulator input */
		.a_in(execute_a),

		.operation_in(writeback_operation),
		.ack(writeback_ack),

		/* The last stage has ACK always asserted. */
		.ack_in(1'b1)
	);
endmodule

module BrainfuckCoreTest;
	reg clk;
	reg reset;

	wire ce, drce, dwce;
	wire [11:0] ia;
	wire [11:0] dra;
	wire [11:0] dwa;
	wire [7:0] id;
	wire [7:0] drd;
	wire [7:0] dwq;
	wire cack, cwre;
	reg  crda, cbsy;
	reg  [7:0] cd;
	wire [7:0] cq;

	BrainfuckCore uut (
		.clk(clk),
		.reset(reset),

		.ice(ice),
		.ia(ia),
		.id(id),

		.drce(drce),
		.dra(dra),
		.drd(drd),

		.dwce(dwce),
		.dwa(dwa),
		.dwq(dwq),

		.cd(cd),
		.crda(crda),
		.cack(cack),

		.cq(cq),
		.cwre(cwre),
		.cbsy(cbsy)
	);

	IROM irom (
		.clk(clk),
		.ce(ice),
		.a(ia),
		.q(id)
	);

	DRAM dram (
		.clk(clk),
		.rce(drce),
		.ra(dra),
		.rq(drd),
		.wce(dwce),
		.wa(dwa),
		.wd(dwq)
	);

	initial begin
		clk = 0;
		reset = 0;
		crda = 0;

		// `reset

		// #161; crda = 1; cd = 8'h42;
		// #20; cd = 8'h43;
		// #20; crda = 0; cd = 0;
	end

	// always begin
	// 	`step
	// end

	reg [1:0] uart_wait = 2'b00;
	always @(posedge clk) begin
		if (cwre) begin
			// $write("%c", cq);
			cbsy      <= 1'b1;
			uart_wait <= 2'b11;
		end else begin
			if (uart_wait)
				uart_wait <= uart_wait - 1;
			else
				cbsy   <= 1'b0;
		end
	end

endmodule
