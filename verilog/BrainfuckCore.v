`timescale 1ns / 1ps
`include "Common.tf"
`include "Constants.v"

module BrainfuckCore(
	clk,
	reset
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

	wire ice;
	wire [IA_WIDTH - 1:0] ia;
	wire [ID_WIDTH - 1:0] iq;

	IROM #(
		.A_WIDTH(IA_WIDTH),
		.D_WIDTH(ID_WIDTH)
	) irom (
		.clk(clk),
		.ce(ice),
		.a(ia),
		.q(iq)
	);

	wire drce, dwce;
	wire [DA_WIDTH - 1:0] dra;
	wire [DA_WIDTH - 1:0] dwa;
	wire [DD_WIDTH - 1:0] drq;
	wire [DD_WIDTH - 1:0] dwd;

	DRAM #(
		.A_WIDTH(DA_WIDTH),
		.D_WIDTH(DD_WIDTH)
	) dram (
		.clk(clk),
		.rce(drce),
		.ra(dra),
		.rq(drq),
		.wce(dwce),
		.wa(dwa),
		.wd(dwd)
	);

	wire [ID_WIDTH - 1:0] idecode_opcode;
	wire                  idecode_ack;
	wire                  idecode_drdy_in;

	wire [`OPCODE_MSB:0]  dfetch_operation;
	wire                  dfetch_ack;
	wire                  dfetch_drdy_in;

	wire [`OPCODE_MSB:0]  modify_operation;
	wire                  modify_ack;
	wire                  modify_drdy_in;

	wire [`OPCODE_MSB:0]  dwriteback_operation;
	wire                  dwriteback_ack;
	wire                  dwriteback_drdy_in;

	StageIFetch #(
		.A_WIDTH(IA_WIDTH),
		.D_WIDTH(ID_WIDTH)
	) ifetch (
		.clk(clk),
		.reset(reset),

		.pc(pc),
		.ice(ice),
		.ia(ia),
		.id(iq),
		.step_pc(pc_ce),

		.opcode(idecode_opcode),
		.ack_in(idecode_ack),
		.drdy(idecode_drdy_in)
	);

	/* IDecode has fixed 8 bit width */
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

	StageDFetch #(
		.A_WIDTH(DA_WIDTH),
		.D_WIDTH(DD_WIDTH)
	) dfetch (
		.clk(clk),
		.reset(reset),

		.dp(dp),
		.dce(drce),
		.da(dra),
		.dd(drq),

		.operation_in(dfetch_operation),
		.ack(dfetch_ack),
		.drdy_in(dfetch_drdy_in),

		.operation(modify_operation),
		.ack_in(modify_ack),
		.drdy(modify_drdy_in)
	);

	StageModify modify (
		.clk(clk),
		.reset(reset),

		.dp_ce(dp_ce),
		.dp_down(dp_down),

		.operation_in(modify_operation),
		.ack(modify_ack),
		.drdy_in(modify_drdy_in),

		.operation(dwriteback_operation),
		.ack_in(dwriteback_ack),
		.drdy(dwriteback_drdy_in)
	);

	StageDWriteBack #(
		.A_WIDTH(DA_WIDTH),
		.D_WIDTH(DD_WIDTH)
	) dwriteback (
		.clk(clk),
		.reset(reset),

		.dp(dp),
		.dce(dwce),
		.da(dwa),
		.dq(dwd),

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

	BrainfuckCore uut (
		.clk(clk),
		.reset(reset)
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
