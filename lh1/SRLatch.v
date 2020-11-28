module SRLatch(
		input set,
		input reset,
		input clk,
		output reg q,
		output reg q_n
		);
	
	/*
	On set assertion, q -> 1. Resets to 0 on reset assertion
	q_n is the inverted output
	*/
	
	initial q = 0;
	initial q_n = 1;

	always @(posedge clk) begin
		if (reset) begin
			q = 0;
			end
		else if (set) begin
			q = 1;
			end
		end
	
	always @(q) begin
		q_n = ~q;
		end
	
	endmodule
