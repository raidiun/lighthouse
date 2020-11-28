build/lh1/lh1_testbench: testbench/lh1_testbench.v lh1/LighthouseTimer.v lh1/Counter.v lh1/EdgeDetector.v | build/lh1
	iverilog -o $@ $^

build/lh2/lh2_testbench: testbench/lh2_testbench.v testbench/LaserGen.v lh1/LighthouseTimer.v lh1/Counter.v lh1/EdgeDetector.v | build/lh2
	iverilog -o $@ $^

show: build/lh1/lh1_testbench
	cd build/lh1 && ./lh1_testbench
	gtkwave build/lh1/test.vcd
.PHONY: show

show2: build/lh2/lh2_testbench
	cd build/lh2 && ./lh2_testbench
	gtkwave build/lh2/test.vcd
.PHONY: show

build/lh1: | build
	mkdir $@

build/lh2: | build
	mkdir $@

build:
	mkdir $@

clean:
	rm -rf build