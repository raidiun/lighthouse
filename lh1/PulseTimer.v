module PulseTimer #(
		parameter WIDTH = 16
	) (
		input envelope,
		input reset,
		input clk,
		output [WIDTH-1:0] result
		);

	/*
	Times the length of a pulse in a 16-bit counter incremented on clk
	*/
	
	wire rise_detect;
	wire fall_detect;
	
	wire in_pulse;
	
	EdgeDetector edgeDetector(
		.sig(),
		.clk(clk),
		.rise(rise_detect),
		.fall(fall_detect)
		);

	// Is this needed? Can't a register be used?
	SRLatch srLatch(
		.set(rise_detect),
		.reset(fall_detect | reset),
		.clk(clk),
		.q(in_pulse),
		.q_n()
		);

	Counter #(.WIDTH(WIDTH)) counter(
		.enable(in_pulse),
		.reset(reset),
		.clk(clk),
		.result(result)
		);

	endmodule
