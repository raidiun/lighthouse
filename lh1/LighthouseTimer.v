module LighthouseTimer #(
		parameter COUNTER_WIDTH = 32,
		parameter CLOCKS_PER_US = 16
	) (
		input envelope,
		input data,
		input clk,
		input reset,
		output reg [COUNTER_WIDTH-1:0] sync_A_time,
		output reg [COUNTER_WIDTH-1:0] sync_B_time,
		output reg [COUNTER_WIDTH-1:0] sweep_time,
		output reg complete
		);

	localparam TIMEOUT_SYNC_A = 32'd4300*CLOCKS_PER_US;
	localparam TIMEOUT_SYNC_B = 32'd600*CLOCKS_PER_US;
	localparam TIMEOUT_SWEEP = 32'd7000*CLOCKS_PER_US;

	localparam SYNC_PULSE_MIN = 32'd62*CLOCKS_PER_US;

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
	
	always @(posedge clk) begin
		if( reset ) begin
			resetTask();
		end
		else begin
			runTask();
		end
	end

	task runTask; begin
		case (phase)

			PHASE_WAIT: begin
				if( delayTimerReset == 1 ) begin
					// Start delay timer
					delayTimerReset <= 0;
					delayTimerEnable <= 1;
					end
				if( fallDetected ) begin
					if (pulse == PULSE_SYNC_A) begin
						resetTask();
						delayTimerEnable <= 1;
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
						if( pulseTimerResult < SYNC_PULSE_MIN ) begin
							// Unsynchronised
							resetTask();
							end
						else begin
							sync_A_time <= pulseTimerResult;
							timeout <= TIMEOUT_SYNC_B;
							pulse <= PULSE_SYNC_B;
							end
						end
					PULSE_SYNC_B: begin
						if( pulseTimerResult < SYNC_PULSE_MIN ) begin
							// Unsynchronised
							resetTask();
							end
						else begin
							sync_B_time <= pulseTimerResult;
							pulse <= PULSE_SWEEP;
							timeout <= TIMEOUT_SWEEP;
							end
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
						resetTask();
						end
					PULSE_SYNC_B: begin
						// This is OK, we may not have a B sync, attempt to detect pulse
						sync_B_time <= 0;
						timeout <= TIMEOUT_SWEEP;
						pulse <= PULSE_SWEEP;
						phase <= PHASE_WAIT;
						end
					PULSE_SWEEP: begin
						// No pulse, may be occluded, reset all and try again
						resetTask();
						end
					endcase
				end

			endcase
		end
	endtask

	task resetTask; begin
		complete <= 0;
		sync_A_time <= 0;
		sync_B_time <= 0;
		sweep_time <= 0;
		delayTimerEnable <= 0;
		delayTimerReset <= 1;
		pulseTimerEnable <= 0;
		pulseTimerReset <= 1;
		phase <= PHASE_WAIT;
		pulse <= PULSE_SYNC_A;
		timeout <= TIMEOUT_SYNC_A;
		end
	endtask

endmodule