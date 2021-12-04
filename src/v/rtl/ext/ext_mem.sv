//
// University of Utah, Computer Design Laboratory ECE 3710, FSSPrototype
//
// Create Date: 11/29/2021
// Module Name: ext_mem
// Description: This module maps addresses from the CR16 external memory port to the
// various external peripheral instantiations.
// Authors: Jacob Peterson, Brady Hartog, Isabella Gilman, Nate Hansen
//

// @param P_DATA_WIDTH           the width of the data
// @param P_ADDRESS_WIDTH        the width of the address line
// @param I_CLK                  the clock signal
// @param I_NRESET               the active-low asynchronous reset signal
// @param I_EXT_MEM_DATA         the external input data
// @param I_EXT_MEM_ADDRESS      the external address line
// @param I_EXT_MEM_WRITE_ENABLE the external write/read enable signal
// @param O_EXT_MEM_DATA         the external output data
module ext_mem
       #(parameter integer P_DATA_WIDTH = 16,
         parameter integer P_ADDRESS_WIDTH = 2)
       (input I_CLK,
        input I_NRESET,
        input [P_DATA_WIDTH - 1 : 0] I_EXT_MEM_DATA,
        input [P_ADDRESS_WIDTH - 1 : 0] I_EXT_MEM_ADDRESS,
        input I_EXT_MEM_WRITE_ENABLE,
        output reg [P_DATA_WIDTH - 1 : 0] O_EXT_MEM_DATA);

localparam integer P_R_ADDRESS_SCL = 'h0,
                   P_R_ADDRESS_SDA = 'h1,
                   P_R_ADDRESS_MICROSECOND_LOWER = 'h2,
                   P_R_ADDRESS_MICROSECOND_UPPER = 'h3;

localparam integer P_W_ADDRESS_SCL = 'h0,

// This parameter defines the cycles per division for the 'microsecond_counter' to
// acquire a microsecond counter given a 50 MHz 'I_CLK' input
localparam integer P_COUNTER_DIVISION_FOR_MICROSECONDS = 50;
localparam integer P_COUNTER_WIDTH = 32;

wire [P_COUNTER_WIDTH - 1 : 0] clock_divided_count;

clock_divided_counter
        #(.P_CLK_CYCLES_PER_DIVISION(P_COUNTER_DIVISION_FOR_MICROSECONDS),
          .P_WIDTH(P_COUNTER_WIDTH))
        microsecond_counter
        (.I_CLK(I_CLK),
         .I_NRESET(I_NRESET),
         .O_COUNT(clock_divided_count));

// localparam [1:0]
//            SCL               = 0, // One bit should transmit to GPIO on this line
//            SDA               = 1, // One bit should transmit to GPIO on this line
//            LOWER_MICRO_COUNT = 2, // The lower 16 bits of the microsecond counter.
//            UPPER_MICRO_COUNT = 3; // The upper 16 bits of the microsecond counter.

// Follow address logic to read/write the correct values
// always @(posedge I_CLK) begin
//     if (I_WRITE_ENABLE_EXT) begin
//         case(I_ADDRESS_EXT)
//             SDA:
//                 IO_SDA <= I_DATA_EXT[0];
//             SCL:
//                 O_SCL <= I_DATA_EXT[0];
//             default:
//                 ;
//         endcase
//         O_DATA_EXT <= O_DATA_EXT;
//         O_BUFF_READ = 1'b1;
//     end
//
//     else
//     case(I_ADDRESS_EXT)
//         LOWER_MICRO_COUNT:
//             O_DATA_EXT <= lower_micro_count;
//         UPPER_MICRO_COUNT:
//             O_DATA_EXT <= upper_micro_count;
//         SDA:
//             O_DATA_EXT <= IO_SDA;
//         default:
//             O_DATA_EXT <= 0;
//     endcase
//     O_BUFF_READ = 1'b0;
// end
// endmodule
