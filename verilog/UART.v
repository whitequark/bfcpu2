module UART(
	clk,
	reset,
	tx,
	rx,
	d,
	q,
	rda,
	ack,
	bsy,
	wre
);

	input  clk;
	input  reset;

	output tx;
	input  rx;

	input       [7:0] d;
   output reg        rda;
	input             ack;

	output      [7:0] q;
   output            bsy;
	input             wre;

	parameter SYS_CLOCK = 50000000;
	parameter BAUD = 9600;

	wire received;

	osdvu #(
		.CLOCK_DIVIDE(SYS_CLOCK / (BAUD * 4))
	) uart (
		.clk(clk),
		.rst(reste),
		.rx(rx),
		.tx(tx),
		.transmit(wre),
		.tx_byte(d),
		.received(received),
		.rx_byte(q),
		.is_receiving(),
		.is_transmitting(bsy),
		.recv_error()
	);

	always @(posedge clk) begin
		if(reset || ack)
			rda <= 1'b0;
		else if(received)
			rda <= 1'b1;
	end

endmodule
