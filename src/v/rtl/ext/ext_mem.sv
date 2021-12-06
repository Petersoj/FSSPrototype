//
// University of Utah, Computer Design Laboratory ECE 3710, FSSPrototype
//
// Create Date: 11/29/2021
// Module Name: ext_mem
// Description: This module maps addresses from the CR16 external memory port to the
// various external peripheral instantiations.
// Authors: Jacob Peterson, Brady Hartog, Isabella Gilman, Nate Hansen
//

// @param P_DATA_WIDTH           the width of the data (do not change)
// @param P_ADDRESS_WIDTH        the width of the address line (do not change)
// @param I_CLK                  the clock signal
// @param I_NRESET               the active-low asynchronous reset signal
// @param I_EXT_MEM_DATA         the external input data
// @param I_EXT_MEM_ADDRESS      the external address line
// @param I_EXT_MEM_WRITE_ENABLE the external write/read enable signal
// @param O_EXT_MEM_DATA         the external output data
// @param O_SCL                  the I2C SCL (clock) line inout which outputs to the FPGA GPIO
//                               which is then connected to the FSS prototype
// @param O_SDA                  the I2C SDA (data) line inout which outputs to the FPGA GPIO
//                               which is then connected to the FSS prototype
module ext_mem
       #(parameter integer P_DATA_WIDTH = 16,
         parameter integer P_ADDRESS_WIDTH = 3)
       (input I_CLK,
        input I_NRESET,
        input [P_DATA_WIDTH - 1 : 0] I_EXT_MEM_DATA,
        input [P_ADDRESS_WIDTH - 1 : 0] I_EXT_MEM_ADDRESS,
        input I_EXT_MEM_WRITE_ENABLE,
        output reg [P_DATA_WIDTH - 1 : 0] O_EXT_MEM_DATA,
        inout O_SCL,
        inout O_SDA);

// Parameterized memory read addresses
localparam [P_ADDRESS_WIDTH - 1 : 0]
           P_R_ADDRESS_SCL           = 'h0,
           P_R_ADDRESS_SDA           = 'h1,
           P_R_ADDRESS_MICROSECOND_0 = 'h2, // 'microsecond_counter' is little-endian
           P_R_ADDRESS_MICROSECOND_1 = 'h3,
           P_R_ADDRESS_MICROSECOND_2 = 'h4;

// Parameterized memory write addresses
localparam [P_ADDRESS_WIDTH - 1 : 0]
           P_W_ADDRESS_SCL = 'h0,
           P_W_ADDRESS_SDA = 'h1;

// This parameter defines the cycles per division for the 'microsecond_counter' to
// acquire a microsecond counter given a 50 MHz 'I_CLK' input
localparam integer P_COUNTER_DIVISION_FOR_MICROSECONDS = 50;
localparam integer P_COUNTER_WIDTH                     = 48;

wire [P_COUNTER_WIDTH - 1 : 0] clock_divided_count;
// Declare SCL and SDA I2C registers with an initial value of 1 (high impedance)
reg scl_t = 1'b1;
reg sda_t = 1'b1;

clock_divided_counter
    #(.P_CLK_CYCLES_PER_DIVISION(P_COUNTER_DIVISION_FOR_MICROSECONDS),
      .P_WIDTH(P_COUNTER_WIDTH))
    microsecond_counter
    (.I_CLK(I_CLK),
     .I_NRESET(I_NRESET),
     .O_COUNT(clock_divided_count));

i2c_bus i_i2c_bus
        (.I_SCL_T(scl_t),
         .I_SDA_T(sda_t),
         .O_SCL(O_SCL),
         .O_SDA(O_SDA));

// Clock block with read/write address mapping logic
always @(posedge I_CLK) begin
    if (!I_NRESET) begin
        // Write high impedance to I2C bus instead of zeros which pull low
        scl_t <= 1'b1;
        sda_t <= 1'b1;
    end
    else begin
        if (I_EXT_MEM_WRITE_ENABLE) begin
            case (I_EXT_MEM_ADDRESS)
                P_W_ADDRESS_SCL:
                    scl_t <= I_EXT_MEM_DATA[0];
                P_W_ADDRESS_SDA:
                    sda_t <= I_EXT_MEM_DATA[0];
            endcase
        end
        else begin
            case (I_EXT_MEM_ADDRESS)
                P_R_ADDRESS_SCL:
                    O_EXT_MEM_DATA <= O_SCL;
                P_R_ADDRESS_SDA:
                    O_EXT_MEM_DATA <= O_SDA;
                P_R_ADDRESS_MICROSECOND_0:
                    O_EXT_MEM_DATA <= clock_divided_count[15:0]; // 'clock_divided_count' is 48-bit
                P_R_ADDRESS_MICROSECOND_1:
                    O_EXT_MEM_DATA <= clock_divided_count[31:16];
                P_R_ADDRESS_MICROSECOND_2:
                    O_EXT_MEM_DATA <= clock_divided_count[47:32];
                default:
                    O_EXT_MEM_DATA <= {P_DATA_WIDTH{1'b0}};
            endcase
        end
    end
end
endmodule
