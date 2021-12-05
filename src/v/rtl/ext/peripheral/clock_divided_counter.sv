//
// University of Utah, Computer Design Laboratory ECE 3710, FSSPrototype
//
// Create Date: 11/29/2021
// Module Name: clock_divided_counter
// Description: A clock-divided counter peripheral.
// Authors: Jacob Peterson, Brady Hartog, Isabella Gilman, Nate Hansen
//

// @param P_CLK_CYCLES_PER_DIVISION the number of 'I_CLK' cycles to count to before incrementing
//                                  'O_COUNTER' by 1
// @param P_WIDTH                   the bit width of the output counter
// @param I_CLK                     the input clock signal to be divided
// @param I_NRESET                  the active-low asynchronous reset signal
// @param O_COUNT                   the clock-divided counter output
module clock_divided_counter
       #(parameter integer P_CLK_CYCLES_PER_DIVISION = 50,
         parameter integer P_WIDTH = 32)
       (input I_CLK,
        input I_NRESET,
        output reg [P_WIDTH - 1 : 0] O_COUNT = {P_WIDTH{1'b0}});

localparam integer P_CLK_DIVIDER_COUNT_WIDTH = $clog2(P_CLK_CYCLES_PER_DIVISION);

reg [P_CLK_DIVIDER_COUNT_WIDTH - 1 : 0] clk_divider_count = {P_CLK_DIVIDER_COUNT_WIDTH{1'b0}};

// Clocked always block
always @(posedge I_CLK or negedge I_NRESET) begin
    if (!I_NRESET) begin
        clk_divider_count <= {P_CLK_DIVIDER_COUNT_WIDTH{1'b0}};
        O_COUNT           <= {P_WIDTH{1'b0}};
    end
    else begin
        if (clk_divider_count == P_CLK_CYCLES_PER_DIVISION - 1) begin
            clk_divider_count <= {P_CLK_DIVIDER_COUNT_WIDTH{1'b0}};
            O_COUNT           <= O_COUNT + 1'b1;
        end
        else
            clk_divider_count <= clk_divider_count + 1'b1;
    end
end
endmodule
