//
// University of Utah, Computer Design Laboratory ECE 3710, FSSPrototype
//
// Create Date: 11/29/2021
// Module Name: clock
// Description: This module is meant to give authors of the fss_top more control over the 
// clock speed provided to the fss module. 
// Authors: Jacob Peterson, Brady Hartog, Isabella Gilman, Nate Hansen
//
// @PARAM P_CYCLES_PER_DIVISION the number of cycles from the input clock in 1 microsecond
// @PARAM P_COUNTER_WIDTH       the bit width of the output microsecond counter
// @PARAM I_INPUT_CLK           the input clock signal to be divided to a microsecond clock
// @PARAM I_NRESET              reset signal for the clock divider. Should be triggered on each restart.
// @PARAM O_MICROSEC_CLK        the output clock signal, 1 microsecond per cycle

module microsecond_counter
       #(parameter integer P_CYCLES_PER_DIVISION = 50,
		   parameter integer P_COUNTER_WIDTH = 32)
        (input I_INPUT_CLK,
	      input I_NRESET,
	      output reg [P_COUNTER_WIDTH - 1 : 0] O_MICROSEC_COUNT);

	reg [P_COUNTER_WIDTH - 1 : 0] count;
	
	always @ (posedge I_INPUT_CLK or negedge I_NRESET)
	begin
		// If the clock should be reset, reset the count to 0.
		if (I_NRESET == 1'b0) begin
			count <= {P_COUNTER_WIDTH{1'b0}};
			O_MICROSEC_COUNT <= {P_COUNTER_WIDTH{1'b0}};
		end
	
		else begin
			// Flip seconds clock every half microsecond cycle, i. e. 25 for the 50MhZ clock on the board.
			if (count == P_CYCLES_PER_DIVISION - 1) begin
				O_MICROSEC_COUNT <= O_MICROSEC_COUNT + 1;
				count <= {P_COUNTER_WIDTH{1'b0}};
			end
			else
				count <= count + 1'b1;
		end
	end	


endmodule
