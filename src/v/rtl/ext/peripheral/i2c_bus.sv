//
//
//

module i2c_bus(input I_SDA_T,
               input I_SCL_T,
					output O_SDA,
					output O_SCL);

assign O_SCL = I_SCL_T ? 1'bz : 1'b0;
assign O_SDA = I_SDA_T ? 1'bz : 1'b0;


endmodule

