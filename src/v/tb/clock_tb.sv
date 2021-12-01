//
// University of Utah, Computer Design Laboratory ECE 3710, CompactRISC16
//
// Create Date: 11/30/2021
// Module Name: clock_tb
// Description: A testbench for the microsecond counter for FSS_Prototype.
// Authors: Jacob Peterson, Brady Hartog, Isabella Gilman, Nate Hansen
//

`timescale 1ns/1ns

module clock_tb
       #(parameter integer P_CYCLES_PER_DIVISION = 50,
		   parameter integer P_COUNTER_WIDTH = 32)   
	     ();

reg tb_clk;
reg tb_nreset;

reg [ P_COUNTER_WIDTH - 1 : 0] tb_micro_count;

integer expected_micro_count;

always #1000 expected_micro_count = expected_micro_count + 1; 
always #10 tb_clk = ~tb_clk; // Every 20 nanosecond period 1 cycle of the 50MHz clock has passed

clock uut (.I_INPUT_CLK(tb_clk), .I_NRESET(tb_nreset), .O_MICROSEC_COUNT(tb_micro_count));

  initial begin
    tb_nreset = 1'b1;
    #1000;	 
	 tb_clk = 1'b0;
	 tb_nreset = 1'b0;
	 #1000;
	 expected_micro_count = 1'b0;
	 tb_nreset = 1'b1;
	 
	   
  
  
  end
endmodule
