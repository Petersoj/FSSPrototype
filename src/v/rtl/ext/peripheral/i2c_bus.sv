//
//
//

module i2c_bus(inout SDA,
               inout SCL,
               input I_SDA_T,
               input I_SCL_T);

assign SCL = I_SCL_T ? 1'bz : SCL;
assign SDA = I_SDA_T ? 1'bz : SDA;


endmodule

