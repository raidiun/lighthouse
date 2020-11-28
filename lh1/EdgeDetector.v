module EdgeDetector(
		input sig,
		input clk,
		output rise,
		output fall
		);
	
	/*
	Detects rising and falling edges and asserts on rise / fall outputs
	*/
	
	initial begin
		prev <= sig;
		end

	reg prev; // Store previous state

	always @(posedge clk) begin
		prev <= sig;
		end
	
	assign rise = sig > prev;
	assign fall = sig < prev;
	
	endmodule	
