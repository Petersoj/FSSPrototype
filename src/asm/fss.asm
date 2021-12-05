#
# University of Utah, Computer Design Laboratory ECE 3710, FSSPrototype
#
# Create Date: 12/04/2021
# Name: fss
# Description: An assembly code file containing the source code for the 
# operation of the FSS Prototype. This code will load onto a De1-SoC FPGA 
# to drive I2C protocol communication with the device hardware. Data is 
# read from various buttons and rotary encoders, and correspoding data is 
# written to a series of SMD LEDs. 
# Authors: Nate Hansen, Jacob Peterson
#
# Notes:
#  GPIO Addresses:
#    U10: 0x38
#    U11: 0x39
#
#  Bit-Encoding for U10:
#    P0      P1      P2     P3     P4      P5      P6      P7
#    SDI     CLK     LE     Save   Prog1   Prog2   Prog3   Play/Pause
#  
#  Bit-Encoding for U11:
#    P0      P1      P2     P3     P4      P5      P6      P7
#    SW1A    SW1B    SW2A   SW2B   SW3A    SW3B    unused  unused

`define ROTARY_ENCODER_1A
`define ROTARY_ENCODER_1B
`define ROTARY_ENCODER_2A
`define ROTARY_ENCODER_2B
`define ROTARY_ENCODER_3A
`define ROTARY_ENCODER_3B

`define U10_BYTE
`define U11_BYTE

`define R_ADDRESS_MICROSECOND_0 2
`define R_ADDRESS_MICROSECOND_1 3
`define R_ADDRESS_MICROSECOND_2 4



.main
  # initialize ring LEDs to 
  # load LED for program 1.
  .initialize_fss
  
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
# BEGIN: I2C interfacing subroutines
#

##
# Reads a byte over i2c from the given address
#
# @param r11 - i2c address from which to read a byte
#
# @return r10 - data read at address r11
##
.read_byte_i2c
  #TODO: Implement
  RET

##
# Writes a user-specified byte over i2c to the given address
#
# @param r11 - i2c address to write a byte
# @param r12 - data to write at address r11
##
.write_byte_i2c
  #TODO: Implement
  RET

#
# END: I2C interfacing subroutines
#

##
# Sleeps execution for a specified number of microseconds. Maximized at 
# 65,535 microseconds due to 16-bit register argument's limit.
#
# @param r11 - number of microseconds to sleep
##
.sleep
  MOVIL   r0  R_ADDRESS_MICROSECOND_2
  MOVIU   r0  0
  LOADEX  r1  r0

  #TODO: Implement

  RET

##
# Subtracts two 48-bit numbers. This subroutine is special and expects 
# the caller to have pushed the numbers onto the stack in the order:
# 
#  A0
#  A1
#  A2
#  B0
#  B1
#  B2
#
# where A0 are the least-significant 16 bits of A. The method performs 
# B - A and returns the least-significant 16 bits of the result.
##
.sub_48bit
    #TODO: Implement
    RET






