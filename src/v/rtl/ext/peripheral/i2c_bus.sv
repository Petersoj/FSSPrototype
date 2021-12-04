//
// University of Utah, Computer Design Laboratory ECE 3710, FSSPrototype
//
// Create Date: 12/4/2021
// Module Name: i2c_bus
// Description: A wrapper for a pair of open-drain configured busses to be used with i2c.
// Authors: Jacob Peterson, Brady Hartog, Isabella Gilman, Nate Hansen
//

// @param I_SDA_T     tri-state signal for the SDA line.
// @param I_SCL_T     tri-state signal for the SCL line.
// @param O_SDA       data line for the SDA signal.
// @param O_SCL       data line for the SCL signal.

module i2c_bus(input I_SDA_T,
               input I_SCL_T,
					output O_SDA,
					output O_SCL);

assign O_SCL = I_SCL_T ? 1'bz : 1'b0;
assign O_SDA = I_SDA_T ? 1'bz : 1'b0;


endmodule

