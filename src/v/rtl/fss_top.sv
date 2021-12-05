//
// University of Utah, Computer Design Laboratory ECE 3710, FSSPrototype
//
// Create Date: 11/23/2021
// Module Name: fss_top
// Description: This is the top-level module of the Fully-Synchronized Synthesizer (FSS) prototype
// processor running on an FPGA board. This module instantiates the CR16 processor, BRAM memory,
// and external/peripheral memory, which allows for the execution of machine code files assembled
// from source files written in assembly in accordance with our custom ISA.
// Authors: Jacob Peterson, Brady Hartog, Isabella Gilman, Nate Hansen
//

// @param I_CLK                     the clock signal
// @param I_NRESET                  the active-low asynchronous reset signal
// @param I_MEM_ADDRESS_B_BITS      slide switch inputs used to address the upper 8 or the lower 8 bits
//                                  of port B of BRAM
// @param I_MEM_ADDRESS_B_SET_LOWER active-low button input to set the lower 8 bits of port B of BRAM
//                                  using 'I_MEM_ADDRESS_B_BITS'
// @param I_MEM_ADDRESS_B_SET_UPPER active-low button input to set the upper 8 bits of port B of BRAM
//                                  using 'I_MEM_ADDRESS_B_BITS'
// @param IO_SCL                    the I2C SCL (clock) line inout which outputs to the FPGA GPIO
//                                  which is then connected to the FSS prototype
// @param IO_SDA                    the I2C SDA (data) line inout which outputs to the FPGA GPIO
//                                  which is then connected to the FSS prototype
// @param O_7_SEGMENT_DISPLAY       output to 4 7-segment displays
module fss_top
       (input I_CLK,
        input I_NRESET,
        input [7:0] I_MEM_ADDRESS_B_BITS,
        input I_MEM_ADDRESS_B_SET_LOWER,
        input I_MEM_ADDRESS_B_SET_UPPER,
        inout IO_SCL,
        inout IO_SDA,
        output wire [6:0] O_7_SEGMENT_DISPLAY [3:0]);

// This value specified the number of clock cycles that should elapse before passing on
// 'I_CLK' to 'i_cr16'. This is used to "warm up" BRAM to prepare its outputs for the
// 'i_cr16' inputs.
localparam [15:0] P_COLD_CLK_CYCLES = 16'd1;

reg [15:0] clk_count = 16'b0;

wire [15:0] i_mem_data_a;
wire [15:0] i_mem_address_a;
reg [15:0] i_mem_address_b;
wire i_mem_write_enable_a;
wire [15:0] o_mem_data_a;
wire [15:0] o_mem_data_b;

wire [15:0] i_ext_mem_data;
wire [15:0] i_ext_mem_address;
wire i_ext_mem_write_enable;
wire [15:0] o_ext_mem_data;

// Instantiate BRAM module with given init file
bram #(.P_BRAM_INIT_FILE("resources/bram_init/fss.dat"),
       .P_BRAM_INIT_FILE_START_ADDRESS('d0),
       .P_DATA_WIDTH('d16),
       .P_ADDRESS_WIDTH('d12)) // Synthesis takes a long time with 16 bits, use less for testing
     i_bram
     (.I_CLK(I_CLK),
      .I_DATA_A(i_mem_data_a),
      .I_DATA_B(16'd0),
      .I_ADDRESS_A(i_mem_address_a[11:0]),
      .I_ADDRESS_B(i_mem_address_b[11:0]),
      .I_WRITE_ENABLE_A(i_mem_write_enable_a),
      .I_WRITE_ENABLE_B(1'b0),
      .O_DATA_A(o_mem_data_a),
      .O_DATA_B(o_mem_data_b));

// Instantiate External Memory interface module
ext_mem i_ext_mem
       (.I_CLK(I_CLK),
        .I_NRESET(I_NRESET),
        .I_EXT_MEM_DATA(i_ext_mem_data),
        .I_EXT_MEM_ADDRESS(i_ext_mem_address[2:0]),
        .I_EXT_MEM_WRITE_ENABLE(i_ext_mem_write_enable),
        .O_EXT_MEM_DATA(o_ext_mem_data),
        .O_SCL(IO_SCL),
        .O_SDA(IO_SDA));

// Instantiate CR16 module
cr16 i_cr16
     (.I_CLK(clk_count > P_COLD_CLK_CYCLES ? I_CLK : 1'b0),
      .I_ENABLE(1'b1),
      .I_NRESET(I_NRESET),
      .I_MEM_DATA(o_mem_data_a),
      .I_EXT_MEM_DATA(o_ext_mem_data),
      .O_MEM_DATA(i_mem_data_a),
      .O_MEM_ADDRESS(i_mem_address_a),
      .O_MEM_WRITE_ENABLE(i_mem_write_enable_a),
      .O_EXT_MEM_DATA(i_ext_mem_data),
      .O_EXT_MEM_ADDRESS(i_ext_mem_address),
      .O_EXT_MEM_WRITE_ENABLE(i_ext_mem_write_enable));

// Instantiate 7-segment hex mappings to display 'o_mem_data_b'
seven_segment_hex_mapping i_display_0
                          (.I_VALUE(o_mem_data_b[3:0]),
                           .O_7_SEGMENT(O_7_SEGMENT_DISPLAY[0]));
seven_segment_hex_mapping i_display_1
                          (.I_VALUE(o_mem_data_b[7:4]),
                           .O_7_SEGMENT(O_7_SEGMENT_DISPLAY[1]));
seven_segment_hex_mapping i_display_2
                          (.I_VALUE(o_mem_data_b[11:8]),
                           .O_7_SEGMENT(O_7_SEGMENT_DISPLAY[2]));
seven_segment_hex_mapping i_display_3
                          (.I_VALUE(o_mem_data_b[15:12]),
                           .O_7_SEGMENT(O_7_SEGMENT_DISPLAY[3]));

// Increment 'clk_count' when it's less than 'P_COLD_CLK_CYCLES' and
// set 'i_mem_address_b' according to push buttons
always @(posedge I_CLK or negedge I_NRESET) begin
    if (!I_NRESET) begin
        clk_count       <= 'd0;
        i_mem_address_b <= 'd0;
    end
    else begin
        if (clk_count <= P_COLD_CLK_CYCLES)
            clk_count <= clk_count + 1'b1;
        else
            clk_count <= clk_count;


        if (!I_MEM_ADDRESS_B_SET_LOWER && I_MEM_ADDRESS_B_SET_UPPER)
            i_mem_address_b <= {i_mem_address_b[15:8], I_MEM_ADDRESS_B_BITS};
        else if (!I_MEM_ADDRESS_B_SET_UPPER && I_MEM_ADDRESS_B_SET_LOWER)
            i_mem_address_b <= {I_MEM_ADDRESS_B_BITS, i_mem_address_b[7:0]};
    end
end
endmodule
