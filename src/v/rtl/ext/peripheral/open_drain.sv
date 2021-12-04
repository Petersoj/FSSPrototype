
module open_drain ( input I_T,
                    output O_DATA);
						  
    assign O_DATA = I_T ? 1'bz : 1'b0;
	 
endmodule