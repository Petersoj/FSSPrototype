//
// University of Utah, Computer Design Laboratory ECE 3710, FSSPrototype
//
// Create Date: 12/05/2021
// Module Name: fss_top_tb
// Description: A testbench for the 'fss_top' module.
// Authors: Jacob Peterson, Brady Hartog, Isabella Gilman, Nate Hansen
//

`timescale 1ns / 1ns

module fss_top_tb();

// Inputs
reg clk = 1'b0;

// Outputs
wire [6:0] display [3:0];
wire io_scl;
wire io_sda;

// Establish clock period of 20 nanoseconds (50 MHz)
always #10 clk = ~clk;

// Note: if you're running this tb from Modelsim via Quartus Prime, the 'P_BRAM_INIT_FILE'
// directory structure used in the 'fss_top' module must exist in the 'simulation/modelsim'
// directory, so simply copy the 'resources' folder at the root of this Git project into the
// 'simulation/modelsim' directory.
fss_top uut
        (.I_CLK(clk),
         .I_NRESET(1'b1),
         .IO_SCL(io_scl),
         .IO_SDA(io_sda),
         .O_7_SEGMENT_DISPLAY(display));

// Use Modelsim's "run for 100ps" feature to advance the simulation of 'fss_top'
initial begin
    $stop;
end

endmodule
