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
    MOVIL   r11 0x38
    MOVIU   r11 0
    CALL    .i2c_read_byte

    MOVIL   r11 0x38
    MOVIU   r11 0
    MOVIL   r12 0b1000
    MOVIU   r12 0b1111
    CALL    .i2c_write_byte

    MOVIL   r11 0x38
    MOVIU   r11 0
    CALL    .i2c_read_byte

    MOVIL   r11 0x38
    MOVIU   r11 0
    MOVIL   r12 0b1000
    MOVIU   r12 0b1111
    CALL    .i2c_write_byte

#    MOVIL   r11 0x38
#    MOVIU   r11 0
#    MOVIL   r12 0b1001
#    MOVIU   r12 0b1111
#    CALL    .i2c_write_byte
#
#    MOVIL   r11 0x38
#    MOVIU   r11 0
#    MOVIL   r12 0b1111
#    MOVIU   r12 0b1111
#    CALL    .i2c_write_byte
#
#    MOVIL   r11 0x38
#    MOVIU   r11 0
#    MOVIL   r12 0b1101
#    MOVIU   r12 0b1111
#    CALL    .i2c_write_byte

    CALL    .spin_indefinitely

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
#.set_leds
#    PUSH    r11
#    PUSH    r12
#    PUSH    r13
#    PUSH    r14
#
#    #TODO: Implement
#
#    MOVIL   r0  15
#    MOVIU   r0  0
#
#    MOVIL   r11 0x38
#    CALL    .write_byte_i2c
#
#    CALL    .set_latch_enable
#    RET

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
    0x0000
    0x0000
    0x0000

#
# BEGIN: I2C interfacing functions
#

##
# Requests to read a byte from a slave on the I2C bus.
#
# @param r11 - the 7-bit address of the I2C slave
#
# @return r10 - the byte read from the I2C bus or '0x0100' if a byte could not be read
##
.i2c_read_byte
    # Push caller-saved registers
    PUSH    r11
    # Generate I2C start condition
    CALL    .i2c_generate_start_condition
    # Pop caller-saved registers
    POP     r11

    # Write I2C slave address
    LSHI    r11 1 # Shift address to left once
    ORI     r11 1 # Indicate read operation in LSB
    CALL    .i2c_write_arbitrary_byte

    # Check if a slave acknowledged and return if it didn't
    CALL    .i2c_did_ack
    CMPI    r10 1
    JEQ     .i2c_read_byte:skip_address_nack_return
    CALL    .i2c_generate_stop_condition    # Generate stop condition if no slave acknowledgement
    MOVIL   r10 0x00    # Return error
    MOVIU   r10 0x01
    RET
    .i2c_read_byte:skip_address_nack_return

    # Read a byte from I2C slave
    CALL    .i2c_read_arbitrary_byte

    # Push caller-saved registers
    PUSH    r10
    # Send acknowledgement to slave
    CALL    .i2c_do_ack
    # Pop caller-saved registers
    POP     r10

    # Push caller-saved registers
    PUSH    r10
    # Generate I2C stop condition
    CALL    .i2c_generate_stop_condition
    # Pop caller-saved registers
    POP     r10

    RET

##
# Requests to write a byte to a slave on the I2C bus.
#
# @param r11 - the 7-bit address of the I2C slave
# @param r12 - the byte to write to the I2C slave
#
# @return r10 - 1 if successful, 0 if byte could not be written
##
.i2c_write_byte
    # Push caller-saved registers
    PUSH    r11
    PUSH    r12
    # Generate I2C start condition
    CALL    .i2c_generate_start_condition
    # Pop caller-saved registers
    POP     r12
    POP     r11

    # Push caller-saved registers
    PUSH    r12
    # Write I2C slave address
    LSHI    r11 1    # Shift address to left once
    ANDI    r11 0xFE # Indicate write operation in LSB
    CALL    .i2c_write_arbitrary_byte
    # Pop caller-saved registers
    POP     r12

    # Push caller-saved registers
    PUSH    r12
    # Get if slave acknowledged
    CALL    .i2c_did_ack
    # Pop caller-saved registers
    POP     r12

    # Check if a slave acknowledged and return if it didn't
    CMPI    r10 1
    JEQ     .i2c_write_byte:skip_address_nack_return
    CALL    .i2c_generate_stop_condition    # Generate stop condition if no slave acknowledgement
    MOVIL   r10 0x00    # Return error
    MOVIU   r10 0x00
    RET
    .i2c_write_byte:skip_address_nack_return

    # Write given byte to I2C slave
    MOV     r11 r12
    CALL    .i2c_write_arbitrary_byte

    # Get and check if a slave acknowledged and return if it didn't
    CALL    .i2c_did_ack
    CMPI    r10 1
    JEQ     .i2c_write_byte:skip_write_nack_return
    CALL    .i2c_generate_stop_condition    # Generate stop condition if no slave acknowledgement
    MOVIL   r10 0x00    # Return error
    MOVIU   r10 0x00
    RET
    .i2c_write_byte:skip_write_nack_return

    # Generate I2C stop condition
    CALL    .i2c_generate_stop_condition

    MOVIL   r10 0x01    # Return success
    MOVIU   r10 0x00
    RET

##
# Generates the master START condition on the I2C bus.
#
# @return void
##
.i2c_generate_start_condition
    CALL    .i2c_set_scl_1
    CALL    .i2c_set_sda_1

    MOVIL   r11 3
    MOVIU   r11 0
    CALL    .sleep

    CALL    .i2c_set_sda_0

    MOVIL   r11 3
    MOVIU   r11 0
    CALL    .sleep

    CALL    .i2c_set_scl_0

    MOVIL   r11 1
    MOVIU   r11 0
    CALL    .sleep

    RET

##
# Generates the master STOP condition on the I2C bus.
#
# @return void
##
.i2c_generate_stop_condition
    CALL    .i2c_set_scl_0
    CALL    .i2c_set_sda_0

    MOVIL   r11 3
    MOVIU   r11 0
    CALL    .sleep

    CALL    .i2c_set_scl_1

    MOVIL   r11 3
    MOVIU   r11 0
    CALL    .sleep

    CALL    .i2c_set_sda_1

    MOVIL   r11 1
    MOVIU   r11 0
    CALL    .sleep

    RET

##
# Reads an arbitrary byte on the I2C bus.
#
# @return r10 - the arbitrary byte read (only least 8 bits are used)
##
.i2c_read_arbitrary_byte
    CALL    .i2c_set_scl_0
    CALL    .i2c_set_sda_1 # Release the SDA line (set to high-impedance)

    MOVIL   r10 0
    MOVIU   r10 0

    MOVIL   r0  0
    MOVIU   r0  0

    .i2c_read_arbitrary_byte:loop

    CMPI    r0  8
    JHS     .i2c_read_arbitrary_byte:ret

    # Push caller-saved registers
    PUSH    r0
    PUSH    r10
    # Sleep a few microseconds, then set I2C SCL high, then sleep another few microseconds
    MOVIL   r11 1
    MOVIU   r11 0
    CALL    .sleep
    CALL    .i2c_set_scl_1
    MOVIL   r11 1
    MOVIU   r11 0
    CALL    .sleep
    # Pop caller-saved registers
    POP     r10

    # Push caller-saved registers
    PUSH    r10
    # Get SDA line value
    CALL    .i2c_get_sda
    MOV     r1  r10
    # Pop caller-saved registers
    POP     r10

    # Shift SDA line value bit into 'r10'
    LSHI    r10 1
    OR      r10 r1

    # Push caller-saved registers
    PUSH    r10
    # Set I2C SCL low
    CALL    .i2c_set_scl_0
    # Pop caller-saved registers
    POP     r10
    POP     r0

    ADDI    r0  1
    JUC     .i2c_read_arbitrary_byte:loop

    .i2c_read_arbitrary_byte:ret
    RET

##
# Writes an arbitrary byte to the I2C bus.
#
# @param r11 - the arbitrary byte (only least 8 bits are used)
#
# @return void
##
.i2c_write_arbitrary_byte
    CALL    .reverse_byte
    MOV     r11 r10

    MOVIL   r0  0
    MOVIU   r0  0

    .i2c_write_arbitrary_byte:loop

    CMPI    r0  8
    JHS     .i2c_write_arbitrary_byte:ret

    # Push caller-saved registers
    PUSH    r0
    PUSH    r11
    # Set I2C SDA line according to LSB of 'r11'
    CALL    .i2c_set_sda
    # Pop caller-saved registers
    POP     r11

    # Push caller-saved registers
    PUSH    r11
    # Sleep a few microseconds, set I2C SCL high, sleep a few microseconds, then set it low
    MOVIL   r11 1
    MOVIU   r11 0
    CALL    .sleep
    CALL    .i2c_set_scl_1
    MOVIL   r11 1
    MOVIU   r11 0
    CALL    .sleep
    CALL    .i2c_set_scl_0
    # Pop caller-saved registers
    POP     r11
    POP     r0

    # Logic right shift SDA ('r11') data by 1
    RSHI    r11 1

    ADDI    r0  1
    JUC     .i2c_write_arbitrary_byte:loop

    .i2c_write_arbitrary_byte:ret
    RET

##
# Gets the acknowledge bit by: releasing the SDA line (sets it to high-impedance), pulsing the
# SCL line, waiting a few microseconds, and returning if ACK was observed or not.
#
# @return r10 - 1 if ACK was observed, 0 if NACK was observed
##
.i2c_did_ack
    CALL    .i2c_set_scl_0
    CALL    .i2c_set_sda_1

    MOVIL   r11 1
    MOVIU   r11 0
    CALL    .sleep

    CALL    .i2c_set_scl_1

    MOVIL   r11 1
    MOVIU   r11 0
    CALL    .sleep

    CALL    .i2c_get_sda

    # Invert return value of '.i2c_get_sda' since ACK means slave is pulling the line low
    # and NACK is no slave is pulling the line low (so it stays pulled high)
    NOT     r10 r10

    # Only concered with LSB of return value so zero out everything else
    MOVIL   r0  0x01
    MOVIU   r0  0x00
    AND     r10 r0

    # Push caller-saved registers
    PUSH    r10
    # Set SCL back low
    MOVIL   r11 1
    MOVIU   r11 0
    CALL    .sleep
    CALL    .i2c_set_scl_0
    # Pop caller-saved registers
    POP     r10

    RET

##
# Pulls the SDA and SCL lines lows, waits a few microseconds, pulls the SDA line
# low, pulses the SCL line.
##
.i2c_do_ack
    CALL    .i2c_set_scl_0
    CALL    .i2c_set_sda_0

    MOVIL   r11 1
    MOVIU   r11 0
    CALL    .sleep

    CALL    .i2c_set_scl_1

    MOVIL   r11 1
    MOVIU   r11 0
    CALL    .sleep

    CALL    .i2c_set_scl_0
    CALL    .i2c_set_sda_1

    MOVIL   r11 1
    MOVIU   r11 0
    CALL    .sleep

    RET

##
# Gets the binary value of the SCL line on the I2C bus.
#
# @return r10 - the SCL bit value
##
.i2c_get_scl
    MOVIL   r10 EXT_R_ADDRESS_SCL_LOWER
    MOVIU   r10 EXT_R_ADDRESS_SCL_UPPER

    LOADX   r10 r10

    RET

##
# Calls '.i2c_set_scl' with 0 as 'r11' to set SCL line low
#
# @return void
##
.i2c_set_scl_0
    MOVIL   r11 0
    MOVIU   r11 0
    CALL    .i2c_set_scl

    RET

##
# Calls '.i2c_set_scl' with 1 as 'r11' to set SCL line high
#
# @return void
##
.i2c_set_scl_1
    MOVIL   r11 1
    MOVIU   r11 0
    CALL    .i2c_set_scl

    RET

##
# Sets the binary value of the SCL line on the I2C bus.
#
# @param r11 - the bit value to set SCL to (only the LSB is used)
#
# @return void
##
.i2c_set_scl
    MOVIL   r0  EXT_W_ADDRESS_SCL_LOWER
    MOVIU   r0  EXT_W_ADDRESS_SCL_UPPER

    STOREX  r0  r11

    RET

##
# Gets the binary value of the SDA line on the I2C bus.
#
# @return r10 - the SDA bit value
##
.i2c_get_sda
    MOVIL   r10 EXT_R_ADDRESS_SDA_LOWER
    MOVIU   r10 EXT_R_ADDRESS_SDA_UPPER

    LOADX   r10 r10

    RET

##
# Calls '.i2c_set_sda' with 0 as 'r11' to set SDA line low
#
# @return void
##
.i2c_set_sda_0
    MOVIL   r11 0
    MOVIU   r11 0
    CALL    .i2c_set_sda

    RET

##
# Calls '.i2c_set_sda' with 1 as 'r11' to set SDA line high
#
# @return void
##
.i2c_set_sda_1
    MOVIL   r11 1
    MOVIU   r11 0
    CALL    .i2c_set_sda

    RET

##
# Sets the binary value of the SDA line on the I2C bus.
#
# @param r11 - the bit value to set SDA to (only the LSB is used)
#
# @return void
##
.i2c_set_sda
    MOVIL   r0  EXT_W_ADDRESS_SDA_LOWER
    MOVIU   r0  EXT_W_ADDRESS_SDA_UPPER

    STOREX  r0  r11

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
# Reverses the order of the 8 least-significant bits in 'r11'.
#
# @param r11 - the byte to reverse
#
# @return r10 - the reversed byte
##
.reverse_byte
    # Zero out return value
    MOVIL   r10 0
    MOVIU   r10 0

    # Apply bit mask for only operating on lower 8 bits of 'r11'
    MOVIL    r0    0xFF
    MOVIU    r0    0x00
    AND      r11   r0

    # https://stackoverflow.com/a/2603254/4352701
    .reverse_byte:lut
    0x0
    0x8
    0x4
    0xC
    0x2
    0xA
    0x6
    0xE
    0x1
    0x9
    0x5
    0xD
    0x3
    0xB
    0x7
    0xF

    MOV     r9  .reverse_byte:lut

    MOV     r1  r11
    ANDI    r1  0b1111
    MOV     r0  r9
    ADD     r0  r1
    LOAD    r5  r0

    MOV     r1  r11
    RSHI    r1  4
    MOV     r0  r9
    ADD     r0  r1
    LOAD    r4  r0

    MOV     r10 r5
    LSHI    r10 4
    OR      r10 r4

    RET

##
# Calls '.sleep_48bit' with only the lower 16-bits set.
#
# @param r11 - number of microseconds to sleep for
#
# @return void
##
.sleep
    MOVIL   r12 0
    MOVIU   r12 0
    MOVIL   r13 0
    MOVIU   r13 0
    CALL    .sleep_48bit

    RET

##
# Sleeps for the given 48-bit microseconds number. Note that the minimum time to execute this
# function is around 2 microseconds.
#
# @param r11 - bits [15:0] of the (unsigned) number of microseconds to sleep for
# @param r12 - bits [31:16] of the (unsigned) number of microseconds to sleep for
# @param r13 - bits [47:32] of the (unsigned) number of microseconds to sleep for
#
# @return void
##
.sleep_48bit
    # Push given arguments before subroutine calls
    PUSH    r13
    PUSH    r12
    PUSH    r11
    MOV     r9  rsp
    ADDI    r9  1

    # Push caller-saved registers
    PUSH r9
    # Get 'entry' microsecond count
    CALL    .get_microseconds
    # Pop caller-saved registers
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

    .sleep_48bit:loop

    # Push caller-saved registers
    PUSH    r9
    PUSH    r11
    # Get 'latest' microsecond count
    CALL    .get_microseconds
    # Pop caller-saved registers
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

    # Push caller-saved registers
    PUSH    r9
    PUSH    r11
    PUSH    r12
    # Get microsecond difference between 'entry' and 'latest' microsecond timestamps
    CALL    .subtract_48bit
    # Pop caller-saved registers
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
    JLO     .sleep_48bit:loop
    CMP     r1  r4
    JLO     .sleep_48bit:loop
    CMP     r0  r3
    JLO     .sleep_48bit:loop

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
    0x0000
    0x0000
    0x0000

##
# Spins the processor indefinitely
#
# @return void
##
.spin_indefinitely
    BUC     -1

#
# END: Utility functions
#

