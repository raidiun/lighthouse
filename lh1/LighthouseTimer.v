module LighthouseTimer(
		input envelope,
		input data,
		input clk,
		output reg [COUNTER_WIDTH-1:0] sync_A_time,
		output reg [COUNTER_WIDTH-1:0] sync_B_time,
		output reg [COUNTER_WIDTH-1:0] sweep_time,
		output reg complete
		);

	parameter COUNTER_WIDTH = 32;

	parameter CLOCKS_PER_US = 16;

	localparam TIMEOUT_SYNC_B = 32'd600*CLOCKS_PER_US;
	localparam TIMEOUT_SWEEP = 32'd7000*CLOCKS_PER_US;


	localparam PULSE_SYNC_A = 2'b01;
	localparam PULSE_SYNC_B = 2'b10;
	localparam PULSE_SWEEP = 2'b11;
	
	localparam PHASE_WAIT = 2'b00;
	localparam PHASE_TIME_PULSE = 2'b01;
	localparam PHASE_PULSE_COMPLETE = 2'b10;
	localparam PHASE_TIMEOUT = 2'b11;

	reg [1:0] pulse;
	reg [1:0] phase;

	reg [COUNTER_WIDTH-1:0] timeout;

	wire riseDetected;
	wire fallDetected;

	EdgeDetector envelopeEdge(
		.sig(envelope),
		.clk(clk),
		.rise(riseDetected),
		.fall(fallDetected)
		);
	
	// Pulse delay timer
	reg delayTimerEnable;
	reg delayTimerReset;
	wire [COUNTER_WIDTH-1:0] delayTimerResult;

	Counter #(.WIDTH(COUNTER_WIDTH)) delayTimer(
		.enable(delayTimerEnable),
		.reset(delayTimerReset),
		.clk(clk),
		.result(delayTimerResult)
		);

	// Pulse width timer
	reg pulseTimerEnable;
	reg pulseTimerReset;
	wire [COUNTER_WIDTH-1:0] pulseTimerResult;

	Counter #(.WIDTH(COUNTER_WIDTH)) pulseTimer(
		.enable(pulseTimerEnable),
		.reset(pulseTimerReset),
		.clk(clk),
		.result(pulseTimerResult)
		);

	initial sync_A_time = 32'd0;
	initial sync_B_time = 32'd0;
	initial sweep_time = 32'd0;
	initial complete = 0;

	initial phase = PHASE_WAIT;
	initial pulse = PULSE_SYNC_A;

	initial timeout = TIMEOUT_SYNC_B;

	initial complete = 0;

	initial delayTimerEnable = 0;
	initial delayTimerReset = 1;
	initial pulseTimerEnable = 0;
	initial pulseTimerReset = 1;
	
	always @(posedge clk) begin
		case (phase)

			PHASE_WAIT: begin
				if( delayTimerReset == 1 ) begin
					// Start delay timer
					delayTimerReset <= 0;
					delayTimerEnable <= 1;
					end
				if( fallDetected ) begin
					if (pulse == PULSE_SYNC_A) begin
						complete <= 0;
						resetTask();
						delayTimerReset <= 1;
						end
					// Start pulse timer
					pulseTimerReset <= 0;
					pulseTimerEnable <= 1;
					// Go to next phase
					phase <= PHASE_TIME_PULSE;
					end
				if( delayTimerResult > timeout ) begin
					phase <= PHASE_TIMEOUT;
					end
				end

			PHASE_TIME_PULSE: begin
				if ( delayTimerReset == 1) begin
					delayTimerReset <= 0;
					end
				if( riseDetected ) begin
					pulseTimerEnable <= 0;
					phase <= PHASE_PULSE_COMPLETE;
					end
				end

			PHASE_PULSE_COMPLETE: begin
				case (pulse)
					PULSE_SYNC_A: begin
						sync_A_time <= pulseTimerResult;
						pulse <= PULSE_SYNC_B;
						end
					PULSE_SYNC_B: begin
						sync_B_time <= pulseTimerResult;
						pulse <= PULSE_SWEEP;
						end
					PULSE_SWEEP: begin
						sweep_time <= delayTimerResult - (pulseTimerResult >> 1);
						complete <= 1;
						delayTimerReset <= 1;
						pulse <= PULSE_SYNC_A;
						end
					endcase
				pulseTimerReset <= 1;
				phase <= PHASE_WAIT;
				end

			PHASE_TIMEOUT: begin
				case (pulse)
					PULSE_SYNC_A: begin
						// No sync, maybe occluded, reset all and try again
						delayTimerEnable <= 0;
						delayTimerReset <= 1;
						pulseTimerEnable <= 0;
						pulseTimerReset <= 1;
						phase <= PHASE_WAIT;
						end
					PULSE_SYNC_B: begin
						// This is OK, we may not have a B sync, attempt to detect pulse
						sync_B_time <= 0;
						timeout = TIMEOUT_SWEEP;
						pulse <= PULSE_SWEEP;
						phase <= PHASE_WAIT;
						end
					PULSE_SWEEP: begin
						// No pulse, may be occluded, reset all and try again
						delayTimerEnable <= 0;
						delayTimerReset <= 1;
						pulseTimerEnable <= 0;
						pulseTimerReset <= 1;
						phase <= PHASE_WAIT;
						pulse <= PULSE_SYNC_A;
						end
					endcase
				end

			endcase
		end

	task resetTask;
		begin
			sync_A_time <= 0;
			sync_B_time <= 0;
			sweep_time <= 0;
			end
		endtask

endmodule