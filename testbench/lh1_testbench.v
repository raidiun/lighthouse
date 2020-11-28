`timescale 10ps/1ps

`define US2TU(t_us) (t_us * 100000)

module lh1_testbench();

	localparam SYNC_A_LENGTH = `US2TU(100);
	localparam SYNC_B_LENGTH = `US2TU(100);
	localparam SWEEP_LENGTH =   `US2TU(10);
	localparam SYNC_B_DELAY =  `US2TU(400);
	localparam SWEEP_DELAY =  `US2TU(3480);
	localparam CYCLE_LENGTH = `US2TU(8333);

	reg envelope;
	reg data;
	reg clk;

	wire [31:0] sync_A_time;
	wire [31:0] sync_B_time;
	wire [31:0] sweep_time;
	wire complete;

	LighthouseTimer lhTimer(
		.envelope(envelope),
		.data(data),
		.clk(clk),
		.sync_A_time(sync_A_time),
		.sync_B_time(sync_B_time),
		.sweep_time(sweep_time),
		.complete(complete)
		);
	
	// 16MHz = 62.5ns = 62500ps = 6250 units
	localparam CLOCK_PERIOD = 6250;

	initial clk = 0;
	always #(CLOCK_PERIOD/2) clk = ~clk;	

	initial begin
		$dumpfile("test.vcd");
		$dumpvars(0,lhTimer);
		$display("Starting LH input tests");

		$display("Starting sync single sweep");
		
		// Initial high signal
		envelope <= 1;
		repeat (10) @(posedge clk);

		// Sync A pulse
		envelope <= 0;
		#SYNC_A_LENGTH;
		envelope <= 1;
		
		// Sweep delay
		#(SWEEP_DELAY-SYNC_A_LENGTH);
		
		// Sweep pulse
		envelope <= 0;
		#(SWEEP_LENGTH);
		envelope <= 1;

		// End of cycle delay
		#(CYCLE_LENGTH-(SWEEP_DELAY+SWEEP_LENGTH));

		$display("Single sync sweep complete:");
		$display(sync_A_time);
		$display(sync_B_time);
		$display(sweep_time);

		$display("Starting double sync sweep");

		// Sync A pulse
		envelope <= 0;
		#(SYNC_A_LENGTH);
		envelope <= 1;
		
		// Inter sync delay
		#(SYNC_B_DELAY-SYNC_A_LENGTH);

		// Sync B pulse
		envelope <= 0;
		#(SYNC_B_LENGTH);
		envelope <= 1;

		// Sweep delay
		#(SWEEP_DELAY-(SYNC_B_DELAY+SYNC_B_LENGTH));
		
		// Sweep pulse
		envelope <= 0;
		#(SWEEP_LENGTH);
		envelope <= 1;

		// End of cycle delay
		#(CYCLE_LENGTH-(SWEEP_DELAY+SWEEP_LENGTH));

		$display("Double sync sweep complete:");
		$display(sync_A_time);
		$display(sync_B_time);
		$display(sweep_time);

		$display("Starting missing sweep test");

		// Sync A pulse
		envelope <= 0;
		#(SYNC_A_LENGTH);
		envelope <= 1;
		
		// Inter sync delay
		#(SYNC_B_DELAY-SYNC_A_LENGTH);

		// Sync B pulse
		envelope <= 0;
		#(SYNC_B_LENGTH);
		envelope <= 1;

		// End of cycle delay
		#(CYCLE_LENGTH-(SYNC_B_DELAY+SYNC_B_LENGTH));

		$display("Missing sweep test complete:");
		$display(sync_A_time);
		$display(sync_B_time);
		$display(sweep_time);

		$finish;
		end


endmodule