#
# University of Utah, Computer Design Laboratory ECE 3710, FSSPrototype
#
# Create Date: 12/04/2021
# Name: fss
# Description: An assembly code file containing the source code for the operation of the
# FSS Prototype. This code will load onto a De1-SoC FPGA to drive I2C protocol communication
# with the device hardware. Data is read from various buttons and rotary encoders, and
# correspoding data is written to a series of SMD LEDs that are driven with LED driver
# shift registers.
# Authors: Nate Hansen, Jacob Peterson, Brady Hartog, Isabella Gilman
#
# Notes:
#
# I/O Port Expander I2C Addresses:
#   U10: 0x38
#   U11: 0x39
#
# Bit-Encoding for I/O Port Expander U10:
#   P0      P1      P2     P3     P4      P5      P6      P7
#   SDI     CLK     LE     Save   Prog1   Prog2   Prog3   Play/Pause
#
# Bit-Encoding for I/O Port Expander U11:
#   P0      P1      P2     P3     P4      P5      P6      P7
#   SW1A    SW1B    SW2A   SW2B   SW3A    SW3B    unused  unused




#`define ROTARY_ENCODER_1A
#`define ROTARY_ENCODER_1B
#`define ROTARY_ENCODER_2A
#`define ROTARY_ENCODER_2B
#`define ROTARY_ENCODER_3A
#`define ROTARY_ENCODER_3B
#
#`define U10_BYTE
#`define U11_BYTE

#`define R_ADDRESS_MICROSECOND_0 2
#`define R_ADDRESS_MICROSECOND_1 3
#`define R_ADDRESS_MICROSECOND_2 4

`define STACK_PTR_LOWER 0xFF
`define STACK_PTR_UPPER 0x03

##
# The program initialization routine.
#
# @return void
##
.init
    # Initialize stack pointer
    MOVIL   rsp STACK_PTR_LOWER
    MOVIU   rsp STACK_PTR_UPPER

# TODO Remove test
.test
    MOVIL   r11 0x00
    MOVIU   r11 0x00
    MOVIL   r12 0x01
    MOVIU   r12 0x00
    MOVIL   r13 0x00
    MOVIU   r13 0x00
    CALL    .sleep

    MOV     r0  .data
    LOAD    r1  r0
    ADDI    r1  1
    STORE   r0  r1

    JUC     .test
.data
0x0000

.main
  # initialize ring LEDs to
  # load LED for program 1.
  CALL .initialize_fss

  #TODO: Implement

  # main loop, infinite.

  # poll input from sensors
    # if there was a change, set necessary LEDs.


##
# Initializes the state of the FSS to the desired LED display.
##
.initialize_fss
  #TODO: Implement
  RET

#
# BEGIN: LED Subroutines
#

# A quick routine to set the latch enable signal for all LED drivers.
.set_latch_enable
  RET

##
# Sets the LEDs to match a pattern given in the first 4 argument registers.
# This is done by sending each bit sequentially on the SDI bit through i2c
# at address 0x38. After each single bit write, we must control the CLK signal
# for the LED drivers. After all bits have been shifted in, we reset the
# latch enable signal to allow the new LED pattern to appear. We set latch
# again before returning to prepare for the next pattern change.
#
# @param    r14 - 00 + P/P + P3 + P2 + P1 + PS + ring3[15:9]
# @param    r13 - ring3[ 8:0] + ring2[19:13]
# @param    r12 - ring2[12:0] + ring1[19:16]
# @param    r11 - ring1[15:0]
#
# @return   void
##
.set_leds
    PUSH    r11
    PUSH    r12
    PUSH    r13
    PUSH    r14

    #TODO: Implement

    MOVIL   r0  15
    MOVIU   r0  0

    MOVIL   r11 0x38
    CALL    .write_byte_i2c

    CALL    .set_latch_enable
    RET

#
# END: LED Subroutines
#

#
# BEGIN: Subroutines to poll data from controls
#

##
# Poll for the state of the buttons on the FSS over i2c.
##
.get_button_states
    #TODO: Implement
    RET

##
# Polls for the state of the FSS quadrature-encoded rotary enocoders
# over i2c.
#
##
.get_rotary_quadrature
    #TODO: Implement
    RET

#
# END: Subroutines to poll data from controls
#






#
# BEGIN: External/peripheral memory interface functions
#

#
# BEGIN: External/peripheral memory interface address defines
#

`define EXT_R_ADDRESS_SCL_LOWER 0x00
`define EXT_R_ADDRESS_SCL_UPPER 0x00
`define EXT_R_ADDRESS_SDA_LOWER 0x01
`define EXT_R_ADDRESS_SDA_UPPER 0x00
`define EXT_R_ADDRESS_MICROSECOND_0_LOWER 0x02
`define EXT_R_ADDRESS_MICROSECOND_0_UPPER 0x00
`define EXT_R_ADDRESS_MICROSECOND_1_LOWER 0x03
`define EXT_R_ADDRESS_MICROSECOND_1_UPPER 0x00
`define EXT_R_ADDRESS_MICROSECOND_2_LOWER 0x04
`define EXT_R_ADDRESS_MICROSECOND_2_UPPER 0x00

`define EXT_W_ADDRESS_SCL_LOWER 0x00
`define EXT_W_ADDRESS_SCL_UPPER 0x00
`define EXT_W_ADDRESS_SDA_LOWER 0x01
`define EXT_W_ADDRESS_SDA_UPPER 0x00

#
# END: External/peripheral memory interface address defines
#

##
# Returns a bit array containing the value of the microsecond counter external peripheral.
#
# @return r10 - a pointer to the result bit array with a length of 3 and the following
#               mapping: | Index | Bits    |
#                        | 0     | [15:0]  |
#                        | 1     | [31:16] |
#                        | 2     | [47:32] |
##
.get_microseconds
    MOVIL   r0  EXT_R_ADDRESS_MICROSECOND_0_LOWER
    MOVIU   r0  EXT_R_ADDRESS_MICROSECOND_0_UPPER
    MOVIL   r1  EXT_R_ADDRESS_MICROSECOND_1_LOWER
    MOVIU   r1  EXT_R_ADDRESS_MICROSECOND_1_UPPER
    MOVIL   r2  EXT_R_ADDRESS_MICROSECOND_2_LOWER
    MOVIU   r2  EXT_R_ADDRESS_MICROSECOND_2_UPPER

    MOV     r3  .get_microseconds:return_array_pointer

    LOADX   r4  r0
    STORE   r3  r4
    ADDI    r3  1

    LOADX   r4  r1
    STORE   r3  r4
    ADDI    r3  1

    LOADX   r4  r2
    STORE   r3  r4

    MOV     r10 .get_microseconds:return_array_pointer
    RET
    .get_microseconds:return_array_pointer
    0x000
    0x000
    0x000

#
# BEGIN: I2C interfacing functions
#

##
# Reads a byte over i2c from the given address
#
# @param r11 - i2c address from which to read a byte
#
# @return r10 - data read at address r11
##
.read_byte_i2c
  # TODO: Implement
  RET

##
# Writes a user-specified byte over i2c to the given address
#
# @param r11 - i2c address to write a byte
# @param r12 - data to write at address r11
##
.write_byte_i2c
  # TODO: Implement
  RET

#
# END: I2C interfacing functions
#

#
# END: External/peripheral memory interface functions
#






#
# BEGIN: Utility functions
#

##
# Sleeps for the given number of microseconds.
#
# @param r11 - bits [15:0] of the (unsigned) number of microseconds to sleep for
# @param r12 - bits [31:16] of the (unsigned) number of microseconds to sleep for
# @param r13 - bits [47:32] of the (unsigned) number of microseconds to sleep for
#
# @return void
##
.sleep
    # Push given arguments before subroutine calls
    PUSH    r13
    PUSH    r12
    PUSH    r11
    MOV     r9  rsp
    ADDI    r9  1

    # Push caller-saved argument registers
    PUSH r9
    # Get 'entry' microsecond count
    CALL    .get_microseconds
    # Pop caller-saved argument registers
    POP  r9

    # Load in the returned bits array
    LOAD    r0  r10
    ADDI    r10 1
    LOAD    r1  r10
    ADDI    r10 1
    LOAD    r2  r10
    # Push 'entry' microsecond count onto the stack and setup first arg for '.subtract_48bit'
    PUSH    r2
    PUSH    r1
    PUSH    r0
    MOV     r11 rsp
    ADDI    r11 1

    .sleep:loop

    # Push caller-saved argument registers
    PUSH    r9
    PUSH    r11
    # Get 'latest' microsecond count
    CALL    .get_microseconds
    # Pop caller-saved argument registers
    POP     r11
    POP     r9

    # Load in the returned bits array
    LOAD    r0  r10
    ADDI    r10 1
    LOAD    r1  r10
    ADDI    r10 1
    LOAD    r2  r10
    # Push 'latest' microsecond count onto the stack and setup second arg for '.subtract_48bit'
    PUSH    r2
    PUSH    r1
    PUSH    r0
    MOV     r12 rsp
    ADDI    r12 1

    # Push caller-saved argument registers
    PUSH    r9
    PUSH    r11
    PUSH    r12
    # Get microsecond difference between 'entry' and 'latest' microsecond timestamps
    CALL    .subtract_48bit
    # Pop caller-saved argument registers
    POP     r12
    POP     r11
    POP     r9

    # Load in the returned bits array
    LOAD    r0  r10
    ADDI    r10 1
    LOAD    r1  r10
    ADDI    r10 1
    LOAD    r2  r10

    # Pop the no-longer-needed 'latest' microsecound count
    POP     r8
    POP     r8
    POP     r8

    # Load in given arguments by peeking them on the stack
    MOV     r8  r9
    LOAD    r3  r8
    ADDI    r8  1
    LOAD    r4  r8
    ADDI    r8  1
    LOAD    r5  r8

    # Compare elapsed microseconds with given arguments and loop as needed
    CMP     r2  r5
    JLO     .sleep:loop
    CMP     r1  r4
    JLO     .sleep:loop
    CMP     r0  r3
    JLO     .sleep:loop

    # Pop 'entry' microseconds
    POP     r0
    POP     r0
    POP     r0

    # Pop given arguments
    POP     r0
    POP     r0
    POP     r0

    RET


##
# Subtracts two unsigned 48-bit numbers and sets the ALU status flags accordingly. The two
# operands of this function call are 'a' (the first operand) and 'b' (the second operand).
# The order of subtraction is: 'b - a'.
#
# @param r11 - a pointer to the first operand bit array with a length of 3 and the following
#              mapping: | Name | Index | Bits    |
#                       | a0   | 0     | [15:0]  |
#                       | a1   | 1     | [31:16] |
#                       | a2   | 2     | [47:32] |
# @param r12 - a pointer to the second operand bit array with the same structure as 'r11'
#
# @return r10 - a pointer to the result bit array with the same structure as 'r11'
##
.subtract_48bit
    # Load 'a' from MSB to LSB: r2 r1 r0
    LOAD    r0  r11
    ADDI    r11 1
    LOAD    r1  r11
    ADDI    r11 1
    LOAD    r2  r11

    # Load 'b' from MSB to LSB: r5 r4 r3
    LOAD    r3  r12
    ADDI    r12 1
    LOAD    r4  r12
    ADDI    r12 1
    LOAD    r5  r12

    MOV     r6  .subtract_48bit:return_array_pointer

    # The 'LSF r7' in the following lines will save the ALU status flags if the subtracted numbers
    # are different. This is because we want to store the status flags only for those bits
    # that are different in the operands 16-bit segments.

    # Subtract lower 16-bits
    SUB     r3  r0
    BHS     1
    SUBI    r4  1       # Borrow occured

    LSF     r7          # Always load status flags for least-significant bits

    STORE   r6  r3
    ADDI    r6  1

    # Subtract middle 16-bits
    SUB     r4  r1
    BHS     1
    SUBI    r5  1       # Borrow occured

    BEQ     1           # Skip loading status flags if numbers are the same for these bits
    LSF     r7

    STORE   r6  r4
    ADDI    r6  1

    # Subtract upper 16-bits
    SUB     r5  r2

    BEQ     1           # Skip loading status flags if numbers are the same for these bits
    LSF     r7

    STORE   r6  r5

    # Store the incrementally-saved status flags
    SSF     r7

    MOV     r10 .subtract_48bit:return_array_pointer
    RET
    .subtract_48bit:return_array_pointer
    0x000
    0x000
    0x000

#
# END: Utility functions
#

