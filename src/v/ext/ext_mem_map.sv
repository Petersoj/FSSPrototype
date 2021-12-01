//
// University of Utah, Computer Design Laboratory ECE 3710, FSSPrototype
//
// Create Date: 11/29/2021
// Module Name: ext_mem_map
// Description: This module maps a second write port from the cr16 processor to the 
// I2C communication registers of the FPGA. This will allow the code given to fss_top to
// access external registers from instructions and free the full BRAM space for other 
// memory.
// Authors: Jacob Peterson, Brady Hartog, Isabella Gilman, Nate Hansen
//
// @param P_DATA_WIDTH       the width of the data
// @param P_ADDRESS_WIDTH    the width of the address line
// @param I_CLK              the clock signal
// @param I_DATA_EXT         the input data for External Port
// @param I_ADDRESS_EXT      the address line for External Port
// @param I_WRITE_ENABLE_EXT the write/read enable signal for External Port
// @param O_DATA_EXT         the output data for External Port

module ext_mem_map
               #( parameter integer P_DATA_WIDTH = 16,
					   parameter integer P_ADDRESS_WIDTH = 2)
                ( input I_CLK,
					   input I_NRESET,
                  input [P_DATA_WIDTH - 1 : 0] I_DATA_EXT,
                  input [P_ADDRESS_WIDTH - 1 : 0] I_ADDRESS_EXT,
                  input I_WRITE_ENABLE_EXT,	
	               inout IO_SDA,
						output O_SCL,
                  output reg [P_DATA_WIDTH - 1 : 0] O_DATA_EXT,
						output O_BUFF_READ);
			
  wire [15:0]lower_micro_count;
  wire [15:0]upper_micro_count;
				
  localparam [1:0]
             SCL               = 0, // One bit should transmit to GPIO on this line
			    SDA               = 1, // One bit should transmit to GPIO on this line
			    LOWER_MICRO_COUNT = 2, // The lower 16 bits of the microsecond counter.
			    UPPER_MICRO_COUNT = 3; // The upper 16 bits of the microsecond counter.
  
  
  
  // Instantiate the microsecond counter
  microsecond_counter  #(.P_CYCLES_PER_DIVISION('d50),
		                   .P_COUNTER_WIDTH('d32))
                        (.I_INPUT_CLK(I_CLK),
	                      .I_NRESET(I_NRESET),
	                      .O_MICROSEC_COUNT({upper_micro_count, lower_micro_count}));
   
  // Follow address logic to read/write the correct values
  always @(posedge I_CLK) begin
    if (I_WRITE_ENABLE_EXT) begin
        case(I_ADDRESS_EXT)
		      SDA:
				    IO_SDA <= I_DATA_EXT[0];
				
				SCL:
				    O_SCL <= I_DATA_EXT[0];
				
				default:
				;
		  endcase
        O_DATA_EXT <= O_DATA_EXT;
		  O_BUFF_READ = 1'b1;
    end
	 
    else
	     case(I_ADDRESS_EXT)
		      LOWER_MICRO_COUNT: 
				    O_DATA_EXT <= lower_micro_count;
					 
				UPPER_MICRO_COUNT: 
				    O_DATA_EXT <= upper_micro_count;
					 
				SDA:
				    O_DATA_EXT <= IO_SDA;
					 
				default: 
				    O_DATA_EXT <= 0;
		  endcase 
        O_BUFF_READ = 1'b0;	  
  end

endmodule
