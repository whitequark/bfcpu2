`timescale 1ns / 1ps
`include "Common.tf"
`include "Constants.v"

module BrainfuckCore(
	clk,
	reset,

	ice,
	ia,
	id,

	drce,
	dra,
	drd,

	dwce,
	dwa,
	dwq
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

	wire [ID_WIDTH - 1:0] idecode_opcode;
	wire                  idecode_ack;
	wire                  idecode_drdy_in;

	wire [`OPCODE_MSB:0]  dfetch_operation;
	wire                  dfetch_ack;
	wire                  dfetch_drdy_in;
	wire [DD_WIDTH - 1:0] dfetch_a;

	wire [`OPCODE_MSB:0]  modify_operation;
	wire                  modify_ack;
	wire                  modify_drdy_in;
	wire [DD_WIDTH - 1:0] modify_a;

	wire [`OPCODE_MSB:0]  dwriteback_operation;
	wire                  dwriteback_ack;
	wire                  dwriteback_drdy_in;

	/*
	 * Fetch instruction, taking memory delays into
	 * account.
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
		.ack_in(idecode_ack),
		.drdy(idecode_drdy_in)
	);

	/*
	 * Decode instruction. IDecode has fixed 8 bit width.
	 */
	StageIDecode idecode (
		.clk(clk),
		.reset(reset),

		.opcode_in(idecode_opcode),
		.ack(idecode_ack),
		.drdy_in(idecode_drdy_in),

		.operation(dfetch_operation),
		.ack_in(dfetch_ack),
		.drdy(dfetch_drdy_in)
	);

	/*
	 * Fetch data byte from DRAM or I/O module or manipulate data pointer.
	 * Data pointer manipulation is done at this stage because
	 * at the next one it may be too late.
	 *
	 *             v
	 * IF   |>|+|...
	 * ID     |>|+|...
	 * DF       |>(+)...
	 *  M         [>]+|...
	 * DWB          |>|+|...
	 *
	 * At the figure above (a theoretical case where DP is manipulated
	 * by M stage), the DP is going to be incremented (point [>]), but
	 * at the exact same time current value will be read to accumulator
	 * (point (+)), and the old DP value will be latched into the RAM.
	 * Thus, the value will be read from cell DP-1 instead of DP.
	 */
	StageDFetch #(
		.A_WIDTH(DA_WIDTH),
		.D_WIDTH(DD_WIDTH)
	) dfetch (
		.clk(clk),
		.reset(reset),

		/* DP register value, to get a datum */
		.dp(dp),

		/* DP register increment and decrement control lines */
		.dp_ce(dp_ce),
		.dp_down(dp_down),

		/* DRAM read port interface */
		.dce(drce),
		.da(dra),
		.dd(drd),

		/* Accumulator output */
		.a(dfetch_a),

		.operation_in(dfetch_operation),
		.ack(dfetch_ack),
		.drdy_in(dfetch_drdy_in),

		.operation(modify_operation),
		.ack_in(modify_ack),
		.drdy(modify_drdy_in)
	);

	/*
	 * Perform arithmetic processing on accumulator
	 * or pass the value as is.
	 */
	StageModify modify (
		.clk(clk),
		.reset(reset),

		/* Accumulator input and output */
		.a_in(dfetch_a),
		.a(modify_a),

		.operation_in(modify_operation),
		.ack(modify_ack),
		.drdy_in(modify_drdy_in),

		.operation(dwriteback_operation),
		.ack_in(dwriteback_ack),
		.drdy(dwriteback_drdy_in)
	);

	/*
	 * Write accumulator back to DRAM or to I/O module.
	 */
	StageDWriteBack #(
		.A_WIDTH(DA_WIDTH),
		.D_WIDTH(DD_WIDTH)
	) dwriteback (
		.clk(clk),
		.reset(reset),

		/* DP register value, to write a datum */
		.dp(dp),

		/* DRAM write port interface */
		.dce(dwce),
		.da(dwa),
		.dq(dwq),

		/* Accumulator input */
		.a_in(modify_a),

		.operation_in(dwriteback_operation),
		.ack(dwriteback_ack),
		.drdy_in(dwriteback_drdy_in),

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
		.dwq(dwq)
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

		`reset
	end

	always begin
		`step
	end
endmodule
