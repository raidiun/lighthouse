module Counter(
		input enable,
		input reset,
		input clk,
		output reg[WIDTH-1:0] result
		);
	
	/*
	Counts up on clk while enable is asserted. Goes to 0 on reset assertion
	*/
	
	parameter WIDTH = 16;
	
	always @(posedge clk) begin
		if (reset) begin
			result <= {WIDTH{1'b0}};
			end
		else if (enable) begin
			result <= result + 1;
			end
		end
	
	endmodule
