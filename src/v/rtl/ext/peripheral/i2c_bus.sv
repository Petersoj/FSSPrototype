//
// University of Utah, Computer Design Laboratory ECE 3710, FSSPrototype
//
// Create Date: 12/4/2021
// Module Name: i2c_bus
// Description: A wrapper for the open-drain SCL and SDA bus lines for I2C.
// Authors: Jacob Peterson, Brady Hartog, Isabella Gilman, Nate Hansen
//

// @param I_SCL_T tri-state input signal for the SCL line. Assert for high impedance output on
//                'O_SCL', reset for pull-down on 'O_SCL'.
// @param I_SDA_T tri-state input signal for the SDA line. Assert for high impedance output on
//                'O_SDA', reset for pull-down on 'O_SDA'.
// @param O_SCL   inout data line for the SCL signal
// @param O_SDA   inout data line for the SDA signal
module i2c_bus
       (input I_SCL_T,
        input I_SDA_T,
        inout O_SCL,
        inout O_SDA);

assign O_SCL = I_SCL_T ? 1'bZ : 1'b0;
assign O_SDA = I_SDA_T ? 1'bZ : 1'b0;

endmodule
