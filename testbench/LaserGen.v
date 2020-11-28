module LaserGen(
	input [31:0] data,
	input clk,
	output reg laser
	);

	initial laser = 0;

	reg [4:0] bitNum;
	initial bitNum = 0;

	always @(posedge clk) begin
		bitNum <= bitNum + 1;
		laser <= ~laser;
		end
	
	wire dataBit;
	assign dataBit = data[bitNum];

	always @(negedge clk) begin
		if (data[bitNum] == 1) begin
			laser <= ~laser;
			end
		end

endmodule