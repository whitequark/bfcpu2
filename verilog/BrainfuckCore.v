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

	wire [ID_WIDTH - 1:0] ifetch_opcode;
	wire                  ifetch_ack_in;
	wire                  ifetch_drdy;

	wire [`OPCODE_MSB:0]  idecode_operation;
	wire 						 idecode_ack_in;
	wire 						 idecode_drdy;

	wire [`OPCODE_MSB:0]  dfetch_operation;
	wire                  dfetch_ack_in;
	wire                  dfetch_drdy;
	
	wire [`OPCODE_MSB:0]  modify_operation;
	wire                  modify_ack_in;
	wire                  modify_drdy;
	
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
		
		.opcode(ifetch_opcode), 
		.ack_in(ifetch_ack_in),
		.drdy(ifetch_drdy)
	);
	
	/* IDecode has fixed 8 bit width */
	StageIDecode idecode (
		.clk(clk), 
		.reset(reset), 
		
		.opcode_in(ifetch_opcode), 
		.ack(ifetch_ack_in), 
		.drdy_in(ifetch_drdy), 
		
		.operation(idecode_operation), 
		.ack_in(idecode_ack_in), 
		.drdy(idecode_drdy)
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
		
		.operation_in(idecode_operation),
		.ack(idecode_ack_in),
		.drdy_in(idecode_drdy),
		
		.operation(dfetch_operation),
		.ack_in(dfetch_ack_in),
		.drdy(dfetch_drdy)
	);
	
	StageModify modify (
		.clk(clk),
		.reset(reset),
		
		.operation_in(dfetch_operation),
		.ack(dfetch_ack_in),
		.drdy_in(dfetch_drdy),
		
		.operation(modify_operation),
		.ack_in(modify_ack_in),
		.drdy(modify_drdy)
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
		
		.operation_in(modify_operation),
		.ack(modify_ack_in),
		.drdy_in(modify_drdy),
		
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
