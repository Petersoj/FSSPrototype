//
// University of Utah, Computer Design Laboratory ECE 3710, FSSPrototype
//
// Create Date: 12/4/2021
// Module Name: open_drain
// Description: An open-drain configured tristate bus.
// Authors: Jacob Peterson, Brady Hartog, Isabella Gilman, Nate Hansen
//

// @param I_T     tri-state signal
// @param O_DATA  data line
module open_drain ( input I_T,
                    output O_DATA);
						  
    assign O_DATA = I_T ? 1'bz : 1'b0;
	 
endmodule