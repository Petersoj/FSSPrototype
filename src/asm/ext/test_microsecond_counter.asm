#
# University of Utah, Computer Design Laboratory ECE 3710, FSSPrototype
#
# Create Date: 12/05/2021
# Name: test_microsecond_counter
# Description: A program to test the microsecond counter in 'fss_top'.
# Authors: Jacob Peterson
#

`define STACK_PTR_LOWER 0xFF
`define STACK_PTR_UPPER 0x03

`define EXT_R_ADDRESS_MICROSECOND_0 0x02
`define EXT_R_ADDRESS_MICROSECOND_1 0x03
`define EXT_R_ADDRESS_MICROSECOND_2 0x04

##
# The program initialization routine.
#
# @return void
##
.init
    # Initialize stack pointer to 1023
    MOVIL   rsp STACK_PTR_LOWER
    MOVIU   rsp STACK_PTR_UPPER

##
# The main function.
#
# @return void
##
.main
    # With a clock frequency of 50 MHz, using 256 (0x0100) as the number to count up to for
    # '.busy_wait' will take 256 * 13 = 3,328 clock cycles, divide that by 50 clock cycles per
    # microsecond means that approximately 66.56 microseconds will have elapsed.
    MOVIL   r11 0x00
    MOVIU   r11 0x01
    CALL    .busy_wait

    # Load lower 48-bits of microsecond counter and push them onto stack

    MOVIL   r0  EXT_R_ADDRESS_MICROSECOND_0
    MOVIU   r0  0
    MOVIL   r1  EXT_R_ADDRESS_MICROSECOND_1
    MOVIU   r1  0
    MOVIL   r2  EXT_R_ADDRESS_MICROSECOND_2
    MOVIU   r2  0

    LOADX   r0  r0
    LOADX   r1  r1
    LOADX   r2  r2

    PUSH    r0
    PUSH    r1
    PUSH    r2

    MOVIL   r11 0
    MOVIU   r11 0
    CALL    .end

##
# Used to busy-wait. Counts up to 'r11' and returns. The actual busy-wait loop is 4 instructions
# taking up a total of 13 clock cycles.
#
# @param r11 - the number to count up to
#
# @return void
##
.busy_wait
    MOVIL   r0  0
    .busy_wait:cmp
    CMP     r0  r11
    JHI    .busy_wait:ret
    ADDI    r0  1
    JUC    .busy_wait:cmp
    .busy_wait:ret
    RET

##
# Does nothing or spins the processor indefinitely.
#
# @param r11 - '0' to spin indefinitely, '1' to do nothing
#
# @return void
##
.end
    CMPI    r11 1
    JEQ     .end:nop
    .end:spin
    BUC     -1
    .end:nop
    NOP
