//
// University of Utah, Computer Design Laboratory ECE 3710, CompactRISC16
//
// Create Date: 11/30/2021
// Module Name: clock_divided_counter_tb
// Description: In this testbench, the 'clock_divided_counter' module is used to count elapsed
// microseconds given a 50 MHz input clock.
// Authors: Jacob Peterson, Brady Hartog, Isabella Gilman, Nate Hansen
//

`timescale 1ns / 1ns

module clock_divided_counter_tb();

// With a 50 MHz clock, divide by 50 to get a microsecond counter
localparam integer P_CLK_CYCLES_PER_DIVISION = 50;
localparam integer P_WIDTH = 32; // Test as a 32-bit counter

reg clk;
reg nreset;
wire [P_WIDTH - 1 : 0] count;

integer expected_count;

always #1000 expected_count = expected_count + 1;
always #10 clk = ~clk; // Every 20 nanosecond period, 1 cycle of the 50 MHz clock has passed

clock_divided_counter
        #(.P_CLK_CYCLES_PER_DIVISION(P_CLK_CYCLES_PER_DIVISION),
          .P_WIDTH(P_WIDTH))
        uut
        (.I_CLK(clk),
         .I_NRESET(nreset),
         .O_COUNT(count));

initial begin
    // Set initial values
    clk = 1'b0;
    nreset = 1'b0;
    expected_count = 0;

    #1000;

    // Disable 'nreset' and reset 'expected_count'
    nreset = 1'b1;
    expected_count = 0;

    // Use Modelsim's "run for 100ps" feature to advance the simulation
    $stop;
end
endmodule
