#
# University of Utah, Computer Design Laboratory ECE 3710, FSSPrototype
#
# Create Date: 12/04/2021
# Name: fss
# Description: This is the main program for the FSS prototype written in our custom assembly code,
# compiled with our custom assembler, and running our custom CompactRISC16 processor. This code
# will load onto an FPGA to drive the I2C protocol communication with the device hardware via GPIO
# pins. Data is read from various buttons and rotary encoders on the FSS, and processed data is
# written to a series of SMD LEDs that are driven with daisy-chained shift register LED drivers.
# Authors: Nate Hansen, Jacob Peterson, Brady Hartog, Isabella Gilman
#

#
# BEGIN: Program init and main function
#

`define STACK_PTR_LOWER 0xFF
`define STACK_PTR_UPPER 0x0F

##
# The program initialization routine.
#
# @return void
##
.init
    # Initialize stack pointer
    MOVIL   rsp STACK_PTR_LOWER
    MOVIU   rsp STACK_PTR_UPPER

##
# The main function.
#
# @return void
##
.main
    CALL    .animation_sequence_startup
    JUC     .run

#
# END: Program init and main function
#








#
# BEGIN: Program run functions
#

#
# BEGIN: Static memory definitions
#

# The following is an array of length 8 with the following index mapping:
# | Index | Description                                       |
# | 0     | 1st ring display value (must be 0 - 19, 0 is off) |
# | 1     | 2nd ring display value (must be 0 - 19, 0 is off) |
# | 2     | 3rd ring display value (must be 0 - 19, 0 is off) |
# | 3     | Save indicator value (must be 0 or 1)             |
# | 4     | Program1 indicator value (must be 0 or 1)         |
# | 5     | Program2 indicator value (must be 0 or 1)         |
# | 6     | Program3 indicator value (must be 0 or 1)         |
# | 7     | Play/Pause indicator value (must be 0 or 1)       |
.display_values_active
0
0
0
0
0
0
0
0

# The following are arrays of length 3 with the following index mapping:
# | Index | Description                                       |
# | 0     | 1st ring display value (must be 0 - 19, 0 is off) |
# | 1     | 2nd ring display value (must be 0 - 19, 0 is off) |
# | 2     | 3rd ring display value (must be 0 - 19, 0 is off) |
.display_values_program_1
9
9
9
.display_values_program_2
2
17
8
.display_values_program_3
11
15
19

# Define a memory location for the current "Play/Pause" button sequence index
.button_playpause_pressed_sequence_index
0x0001

# Define a memory location for the '.rotary_encoder_decode' function for the rotary encoders
.rotary_encoder_1
0x0000
.rotary_encoder_2
0x0000
.rotary_encoder_3
0x0000

#
# END: Static memory definitions
#

##
# Runs the FSS prototype program. This function runs indefinitely.
#
# @return void
##
.run
    # Copy program 1 display values into active values
    MOV     r11 .display_values_program_1
    MOV     r12 .display_values_active
    MOVIL   r13 3
    MOVIU   r13 0x00
    CALL    .array_copy

    # Indicate program 1 is active
    MOVIL   r11 0b0000_0010
    MOVIU   r11 0x00
    CALL    .set_display_values_active_indicators

    # Display active values
    MOV     r11 .display_values_active
    CALL    .set_ring_display_and_indicator_values

    .run:loop

    CALL    .handle_buttons
    CALL    .handle_rotary_encoders

    JUC     .run:loop

    # Handle button press events

##
# Polls and processes the buttons on the FSS prototype.
#
# @return void
##
.handle_buttons
    CALL    .button_get_values

    PUSH    r10 # Push caller-saved registers
    # Check if "Save" button is pressed
    MOV     r11 r10
    CALL    .button_is_save_pressed
    CMPI    r10 1
    JNE     .handle_buttons:skip_button_save_pressed
    CALL    .button_save_pressed
    .handle_buttons:skip_button_save_pressed
    POP     r10 # Pop caller-saved registers

    PUSH    r10 # Push caller-saved registers
    # Check if "Program" button is pressed
    MOV     r11 r10
    CALL    .button_is_program_pressed
    CMPI    r10 0
    JEQ     .handle_buttons:skip_button_program_pressed
    MOV     r11 r10
    CALL    .button_program_pressed
    .handle_buttons:skip_button_program_pressed
    POP     r10 # Pop caller-saved registers

    PUSH    r10 # Push caller-saved registers
    # Check if "Play/Pause" button is pressed
    MOV     r11 r10
    CALL    .button_is_playpause_pressed
    CMPI    r10 1
    JNE     .handle_buttons:button_playpause_pressed
    CALL    .button_playpause_pressed
    .handle_buttons:button_playpause_pressed
    POP     r10 # Pop caller-saved registers

    RET

##
# Polls and processes the rotary encoders on the FSS prototype.
#
# @return void
##
.handle_rotary_encoders
    CALL    .rotary_encoder_get_values

    # Push caller-saved registers
    PUSH    r10
    # Process rotary encoder 1
    MOV     r11 .rotary_encoder_1
    MOV     r12 r10
    ANDI    r12 0b0000_00011
    MOV     r13 .display_values_active
    CALL    .process_rotary_encoder
    # Pop caller-saved registers
    POP     r10

    # Push caller-saved registers
    PUSH    r10
    # Process rotary encoder 2
    MOV     r11 .rotary_encoder_2
    MOV     r12 r10
    RSHI    r12 2
    ANDI    r12 0b0000_00011
    MOV     r13 .display_values_active
    ADDI    r13 1
    CALL    .process_rotary_encoder
    # Pop caller-saved registers
    POP     r10

    # Push caller-saved registers
    PUSH    r10
    # Process rotary encoder 3
    MOV     r11 .rotary_encoder_3
    MOV     r12 r10
    RSHI    r12 4
    ANDI    r12 0b0000_00011
    MOV     r13 .display_values_active
    ADDI    r13 2
    CALL    .process_rotary_encoder
    # Pop caller-saved registers
    POP     r10

    RET

##
# Processes the data polled from a given rotary encoder on the FSS prototype.
#
# @param r11 - a pointer to a boolean value in memory containing whether or not this decode
#              function observed the following pattern: Channel A = 0 && Channel B = 0
# @param r12 - the current encoder channel binary values with the following mapping:
#              | Bit Index | Channel Mapping                         |
#              | 0         | Channel A binary value (must be 0 or 1) |
#              | 1         | Channel B binary value (must be 0 or 1) |
# @param r13 - a pointer to the ring display value in the display value array
#
# @return void
##
.process_rotary_encoder
    # Push caller-saved registers
    PUSH    r13
    # Decode the given rotary encoder input
    CALL    .rotary_encoder_decode
    # Pop caller-saved registers
    POP     r13

    CMPI    r10 1
    JEQ     .process_rotary_encoder:handle_cw
    CMPI    r10 -1
    JEQ     .process_rotary_encoder:handle_ccw
    # If neither 1 or -1 was returned by 'rotary_encoder_decode', then return
    RET

    .process_rotary_encoder:handle_cw
    # Increment if value is not greater than 19
    LOAD    r1  r13
    ADDI    r1  1
    CMPI    r1  19
    JGT     .process_rotary_encoder:unchanged_ret
    STORE   r13 r1
    JUC     .process_rotary_encoder:changed_ret

    .process_rotary_encoder:handle_ccw
    # Decrement if value is not less than to 0
    LOAD    r1  r13
    SUBI    r1  1
    CMPI    r1  0
    JLT     .process_rotary_encoder:unchanged_ret
    STORE   r13 r1
    JUC     .process_rotary_encoder:changed_ret

    .process_rotary_encoder:changed_ret

    # Turn on the "Save" indicator
    MOV     r1  .display_values_active
    ADDI    r1  3
    MOVIL   r0  1
    MOVIU   r0  0x00
    STORE   r1  r0

    # Display active values
    MOV     r11 .display_values_active
    CALL    .set_ring_display_and_indicator_values

    RET

    .process_rotary_encoder:unchanged_ret

    RET

##
# Sets the indicator values in the '.display_values_active'.
#
# @param r11 - the one-hot encoded indicator display values with the following bit mapping:
#              | Bit Index | Mapping                                     |
#              | 0         | Save indicator value (must be 0 or 1)       |
#              | 1         | Program1 indicator value (must be 0 or 1)   |
#              | 2         | Program2 indicator value (must be 0 or 1)   |
#              | 3         | Program3 indicator value (must be 0 or 1)   |
#              | 4         | Play/Pause indicator value (must be 0 or 1) |
#
# @return void
##
.set_display_values_active_indicators
    MOV     r2  .display_values_active
    ADDI    r2  3

    MOVIL   r0  0x00
    MOVIU   r0  0x00

    .set_display_values_active_indicators:loop

    MOV     r1  r11
    RSH     r1  r0
    ANDI    r1  0x01
    STORE   r2  r1
    ADDI    r2  1

    ADDI    r0  1
    CMPI    r0  5
    JLO     .set_display_values_active_indicators:loop

    RET

##
# Gets a pointer to the currently selected program display values.
#
# @return r10 - a pointer to the currently selected program display values
##
.get_pointer_to_current_program_display_values
    MOV     r1  .display_values_active

    ADDI    r1  4
    LOAD    r0  r1
    CMPI    r0  1
    JNE     .get_pointer_to_current_program_display_values:after_program_1
    MOV     r10 .display_values_program_1
    RET
    .get_pointer_to_current_program_display_values:after_program_1
    ADDI    r1  1 # Go to next "indicator" address in '.display_values_active'
    LOAD    r0  r1
    CMPI    r0  1
    JNE     .get_pointer_to_current_program_display_values:after_program_2
    MOV     r10 .display_values_program_2
    RET
    .get_pointer_to_current_program_display_values:after_program_2
    ADDI    r1  1 # Go to next "indicator" address in '.display_values_active'
    LOAD    r0  r1
    CMPI    r0  1
    JNE     .get_pointer_to_current_program_display_values:after_program_3
    MOV     r10 .display_values_program_3
    RET
    .get_pointer_to_current_program_display_values:after_program_3

    # If this line is ever reached, then there is no active program selected, which should never
    # happen...
    RET

##
# Handles the "Save" button press.
#
# @return void
##
.button_save_pressed
    CALL    .get_pointer_to_current_program_display_values
    MOV     r2  r10

    # Copy from active values to desired program
    MOV     r11 .display_values_active
    MOV     r12 r2
    MOVIL   r13 3
    MOVIU   r13 0x00
    CALL    .array_copy

    # Turn off the "Save" indicator
    MOV     r1  .display_values_active
    ADDI    r1  3
    MOVIL   r0  0
    MOVIU   r0  0x00
    STORE   r1  r0

    # Display active values
    MOV     r11 .display_values_active
    CALL    .set_ring_display_and_indicator_values

    # Busy-wait while the "Save" button is being pressed
    .button_save_pressed:busy_wait
    CALL    .button_get_values
    MOV     r11 r10
    CALL    .button_is_save_pressed
    CMPI    r10 1
    JEQ     .button_save_pressed:busy_wait

    # Display active values
    MOV     r11 .display_values_active
    CALL    .set_ring_display_and_indicator_values

    RET

##
# Handles the "Program" button press.
#
# @param r11 - the program button index (1 - 3)
#
# @return void
##
.button_program_pressed
    # Set 'r0' to address of desired program display values
    CMPI    r11 1
    JNE     .button_program_pressed:after_program_1
    MOV     r0  .display_values_program_1
    .button_program_pressed:after_program_1
    CMPI    r11 2
    JNE     .button_program_pressed:after_program_2
    MOV     r0  .display_values_program_2
    .button_program_pressed:after_program_2
    CMPI    r11 3
    JNE     .button_program_pressed:after_program_3
    MOV     r0  .display_values_program_3
    .button_program_pressed:after_program_3

    # Push caller-saved registers
    PUSH    r11

    # Copy given program display values into active values
    MOV     r11 r0
    MOV     r12 .display_values_active
    MOVIL   r13 3
    MOVIU   r13 0x00
    CALL    .array_copy

    # Pop caller-saved registers
    POP     r0

    # Indicate given program is active
    MOVIL   r11 0b0000_0001
    MOVIU   r11 0x00
    LSH     r11 r0
    CALL    .set_display_values_active_indicators

    # Display active values
    MOV     r11 .display_values_active
    CALL    .set_ring_display_and_indicator_values

    RET

##
# Handles the "Play/Pause" button press. This function runs until the "Play/Pause" button is toggled off.
#
# @return void
##
.button_playpause_pressed
    # Set all indicator values to 0 and all ring display values to 0
    MOVIL   r1  0x00
    MOVIU   r1  0x00
    PUSH    r1
    PUSH    r1
    PUSH    r1
    PUSH    r1
    PUSH    r1
    PUSH    r1
    PUSH    r1
    PUSH    r1

    MOV     r11 rsp
    ADDI    r11 1
    CALL    .set_ring_display_and_indicator_values

    # Pop all display values off the stack
    POP     r0
    POP     r0
    POP     r0
    POP     r0
    POP     r0
    POP     r0
    POP     r0
    POP     r0

    # Busy-wait while the "Play/Pause" button is being pressed
    .button_playpause_pressed:busy_wait_pressed_before
    CALL    .button_get_values
    MOV     r11 r10
    CALL    .button_is_playpause_pressed
    CMPI    r10 1
    JEQ     .button_playpause_pressed:busy_wait_pressed_before

    .button_playpause_pressed:loop

    MOV     r0  .button_playpause_pressed_sequence_index
    LOAD    r0  r0
    CMPI    r0  1
    BNE     1
    CALL    .animation_sequence_idle_1
    CMPI    r0  2
    BNE     1
    CALL    .animation_sequence_idle_2
    CMPI    r0  3
    BNE     1
    CALL    .animation_sequence_idle_3
    CMPI    r0  4
    BNE     1
    CALL    .animation_sequence_idle_4

    # Check if "Play/Pause" button is pressed to toggle idle animation off
    CALL    .button_get_values
    MOV     r11 r10
    CALL    .button_is_playpause_pressed
    CMPI    r10 1
    JNE     .button_playpause_pressed:loop

    # Set '.button_playpause_pressed_sequence_number' to next sequence number
    MOV     r0  .button_playpause_pressed_sequence_index
    LOAD    r1  r0
    ADDI    r1  1
    STORE   r0  r1

    CMPI    r1  4
    JLE     .button_playpause_pressed:skip_sequence_reset
    # Reset animation sequence to '1'
    MOVIL   r1  1
    MOVIU   r1  0x00
    STORE   r0  r1
    .button_playpause_pressed:skip_sequence_reset

    # Display active values
    MOV     r11 .display_values_active
    CALL    .set_ring_display_and_indicator_values

    # Busy-wait while the "Play/Pause" button is being pressed
    .button_playpause_pressed:busy_wait_pressed_after
    CALL    .button_get_values
    MOV     r11 r10
    CALL    .button_is_playpause_pressed
    CMPI    r10 1
    JEQ     .button_playpause_pressed:busy_wait_pressed_after

    RET

#
# END: Program run functions
#








#
# BEGIN: Animation sequence functions
#

##
# Executes a given animation sequence.
#
# An animation sequence uses a compressed frame structure stored in a static place in memory.
# The compressed frame structure is  mapped as follows:
#
#                    | Bit Range | Mapping                |
#                    | [4:0]     | 1st ring display value |
#                    | [9:5]     | 2nd ring display value |
#                    | [14:10]   | 3rd ring display value |
#
# Note that LED indicators (for push buttons) are not a part of the frame structure and are
# programmed in the below "frame loop" (and by default are always on during the animation
# playback).
#
# @return r11 - the number of frames in the animation sequence
# @return r12 - a pointer to a sequence of frames for the animation
#
# @return void
##
.execute_animation_sequence
    # The following 'r1' register assignment sets number of frames in the animation sequence
    MOV     r1  r11

    # 'r0' is the current frame address of the animation sequency
    MOV     r0  r12

    # 'r1' will now contain the stop address of the animation sequence frames
    ADD     r1  r0

    .execute_animation_sequence:frame_loop

    # Push caller-saved registers
    PUSH    r0
    PUSH    r1

    # Set LED indicator button lights to always be on
    MOVIL   r1  0x01
    MOVIU   r1  0x00
    PUSH    r1
    PUSH    r1
    PUSH    r1
    PUSH    r1
    PUSH    r1

    # Load the compressed frame data
    LOAD    r0  r0

    # Decode 3rd ring display value and push onto stack
    MOV     r1  r0
    RSHI    r1  10
    ANDI    r1  0b11111
    PUSH    r1

    # Decode 2nd ring display value and push onto stack
    MOV     r1  r0
    RSHI    r1  5
    ANDI    r1  0b11111
    PUSH    r1

    # Decode 1st ring display value and push onto stack
    MOV     r1  r0
    ANDI    r1  0b11111
    PUSH    r1

    MOV     r11 rsp
    ADDI    r11 1
    CALL    .set_ring_display_and_indicator_values

    # Pop all display values off the stack
    POP     r0
    POP     r0
    POP     r0
    POP     r0
    POP     r0
    POP     r0
    POP     r0
    POP     r0

    # Delay 2 milliseconds for next frame
    MOVIL   r11 0xD0
    MOVIU   r11 0x07
    MOVIL   r12 0x00
    MOVIU   r12 0x00
    MOVIL   r13 0x00
    MOVIU   r13 0x00
    CALL    .sleep_48bit

    # Pop caller-saved registers
    POP     r1
    POP     r0

    ADDI    r0  1
    CMP     r0  r1
    JLO     .execute_animation_sequence:frame_loop

    RET

##
# Executes the startup animation sequence.
#
# @return void
##
.animation_sequence_startup
    MOVIL   r11 87
    MOVIU   r11 0x00
    MOV     r12 .startup_animation_sequence_frames
    CALL    .execute_animation_sequence

    RET

##
# Executes the idle animation sequence 1.
#
# @return void
##
.animation_sequence_idle_1
    # Shift in several 1s into the LED driver shift register

    MOVIL   r0  0x00
    MOVIU   r0  0x00

    .animation_sequence_idle_1:shift_1s

    # Push caller-saved registers
    PUSH    r0

    MOVIL   r11 0x01
    MOVIU   r11 0x00
    CALL    .led_shift_value
    CALL    .led_latch_enable

    # Delay 35 milliseconds for next frame
    MOVIL   r11 0xB8
    MOVIU   r11 0x88
    MOVIL   r12 0x00
    MOVIU   r12 0x00
    MOVIL   r13 0x00
    MOVIU   r13 0x00
    CALL    .sleep_48bit

    # Pop caller-saved registers
    POP     r0

    ADDI    r0  1
    CMPI    r0  5
    JLO     .animation_sequence_idle_1:shift_1s

    # Shift in several 0s into the LED driver shift register

    MOVIL   r0  0x00
    MOVIU   r0  0x00

    .animation_sequence_idle_1:shift_0s

    # Push caller-saved registers
    PUSH    r0

    MOVIL   r11 0x00
    MOVIU   r11 0x00
    CALL    .led_shift_value
    CALL    .led_latch_enable

    # Delay 35 milliseconds for next frame
    MOVIL   r11 0xB8
    MOVIU   r11 0x88
    MOVIL   r12 0x00
    MOVIU   r12 0x00
    MOVIL   r13 0x00
    MOVIU   r13 0x00
    CALL    .sleep_48bit

    # Pop caller-saved registers
    POP     r0

    ADDI    r0  1
    CMPI    r0  5
    JLO     .animation_sequence_idle_1:shift_0s

    RET

##
# Executes the idle animation sequence 2.
#
# @return void
##
.animation_sequence_idle_2
    # Shift in and latch a 1 into the LED driver shift register
    MOVIL   r11 0x01
    MOVIU   r11 0x00
    CALL    .led_shift_value
    CALL    .led_latch_enable

    # Delay 200 milliseconds for next frame
    MOVIL   r11 0x40
    MOVIU   r11 0x0D
    MOVIL   r12 0x03
    MOVIU   r12 0x00
    MOVIL   r13 0x00
    MOVIU   r13 0x00
    CALL    .sleep_48bit

    # Shift in and latch a 0 into the LED driver shift register
    MOVIL   r11 0x00
    MOVIU   r11 0x00
    CALL    .led_shift_value
    CALL    .led_latch_enable

    # Delay 200 milliseconds for next frame
    MOVIL   r11 0x40
    MOVIU   r11 0x0D
    MOVIL   r12 0x03
    MOVIU   r12 0x00
    MOVIL   r13 0x00
    MOVIU   r13 0x00
    CALL    .sleep_48bit

    RET

##
# Executes the idle animation sequence 3.
#
# @return void
##
.animation_sequence_idle_3
    # Shift and latch a 1 into the LED driver shift register
    MOVIL   r11 0x01
    MOVIU   r11 0x00
    CALL    .led_shift_value
    CALL    .led_latch_enable

    # Incrementally shift in and latch 0s into the LED driver shift register

    MOVIL   r0  0x00
    MOVIU   r0  0x00

    .animation_sequence_idle_3:shift_0s_loop

    # Push caller-saved registers
    PUSH    r0

    MOVIL   r11 0x00
    MOVIU   r11 0x00
    CALL    .led_shift_value
    CALL    .led_latch_enable

    # Delay 11 milliseconds for next frame
    MOVIL   r11 0xF8
    MOVIU   r11 0x2A
    MOVIL   r12 0x00
    MOVIU   r12 0x00
    MOVIL   r13 0x00
    MOVIU   r13 0x00
    CALL    .sleep_48bit

    # Pop caller-saved registers
    POP     r0

    ADDI    r0  1
    CMPI    r0  56
    JLO     .animation_sequence_idle_3:shift_0s_loop

    # Finally, set all indicator values to 0 and all ring display values to 0
    MOVIL   r1  0x00
    MOVIU   r1  0x00
    PUSH    r1
    PUSH    r1
    PUSH    r1
    PUSH    r1
    PUSH    r1
    PUSH    r1
    PUSH    r1
    PUSH    r1

    MOV     r11 rsp
    ADDI    r11 1
    CALL    .set_ring_display_and_indicator_values

    # Pop all display values off the stack
    POP     r0
    POP     r0
    POP     r0
    POP     r0
    POP     r0
    POP     r0
    POP     r0
    POP     r0

    RET

##
# Executes the idle animation sequence 4.
#
# @return void
##
.animation_sequence_idle_4
    MOVIL   r11 40
    MOVIU   r11 0x00
    MOV     r12 .animation_sequence_idle_4_frames
    CALL    .execute_animation_sequence

    RET

#
# END: Animation sequence functions
#








#
# BEGIN: Hardware interfacing functions
#

# TODO: The functions in this section do not account for when reading or writing to the I2C
#       chips return an error. Implement a fallback to handle errors later if there is time.

# Notes on FSS prototype Main PCB hardware interfacing:
#
# I/O Port Expander I2C Addresses:
#   U10: 0x38
#   U11: 0x39
#
# Port mapping for I/O Port Expander U10 (used for LED driver shift register and push buttons):
#   P7         P6         P5         P4         P3         P2         P1         P0
#   Play/Pause Program3   Program2   Program1   Save       LE         CLK        SDI
#
# Port mapping for I/O Port Expander U11 (used for reading quadrature-encoded rotary encoders):
#   P7         P6         P5         P4         P3         P2         P1         P0
#   N/A        N/A        SW3B       SW3A       SW2B       SW2A       SW1B       SW1A
#
# U10 MUST have upper 5 bits driven high always as they are used as inputs for the push buttons.
# Similarly, U11 MUST have all bits driven high always as they are used as inputs for the rotary
# encoders. The I2C Port Expander Chip ports will be driven low via the pull-down push buttons
# and rotary encoder configurations on the Main PCB.
#

#
# BEGIN: Hardware I2C address defines
#

`define U10_I2C_ADDRESS_LOWER 0x38
`define U10_I2C_ADDRESS_UPPER 0x00

`define U11_I2C_ADDRESS_LOWER 0x39
`define U11_I2C_ADDRESS_UPPER 0x00

#
# END: Hardware I2C address defines
#

#
# BEGIN: LED driver interfacing functions
#

##
# Sets the ring display values and the button indicator values on the FSS prototype.
#
# @param r11 - a pointer to an array of length 8 with the following index mapping:
#              | Index | Description                                       |
#              | 0     | 1st ring display value (must be 0 - 19, 0 is off) |
#              | 1     | 2nd ring display value (must be 0 - 19, 0 is off) |
#              | 2     | 3rd ring display value (must be 0 - 19, 0 is off) |
#              | 3     | Save indicator value (must be 0 or 1)             |
#              | 4     | Program1 indicator value (must be 0 or 1)         |
#              | 5     | Program2 indicator value (must be 0 or 1)         |
#              | 6     | Program3 indicator value (must be 0 or 1)         |
#              | 7     | Play/Pause indicator value (must be 0 or 1)       |
#
# @return void
##
.set_ring_display_and_indicator_values
    # Index pointer to last value in given array
    ADDI    r11 7

    #
    # BEGIN: Write indicator values from array into LED shift register
    #

    MOVIL   r0  0x00
    MOVIU   r0  0x00

    # Loop through all LED indicators in array
    .set_ring_display_and_indicator_values:indicator_loop

    # Push caller-saved registers
    PUSH    r0
    PUSH    r11
    # Call '.led_shift_value' with loaded value from array
    LOAD    r11 r11
    CALL    .led_shift_value
    # Pop caller-saved registers
    POP     r11
    POP     r0

    # Move index pointer to next value
    SUBI    r11 1

    ADDI    r0  1
    CMPI    r0  5
    JLO     .set_ring_display_and_indicator_values:indicator_loop

    #
    # END: Write indicator values from array into LED shift register
    #

    #
    # BEGIN: Write ring display values from array into LED shift register
    #

    MOVIL   r0  0x00
    MOVIU   r0  0x00

    # Loop through each LED ring in array
    .set_ring_display_and_indicator_values:ring_loop

    # Push caller-saved registers
    PUSH    r0
    PUSH    r11

    MOVIL   r0  19
    MOVIU   r0  0x00

    # Load the LED ring value
    LOAD    r1  r11

    # Shift 'r1' number of ones into LED shift register as indicated by the loaded LED ring value,
    # then shift the remaining number of zeros into LED shift register so that 19 values are
    # shifted in.
    .set_ring_display_and_indicator_values:ring_value_loop

    # Push caller-saved registers
    PUSH    r0
    PUSH    r1
    # Call '.led_shift_value' with a binary 1 if the loop index ('r0') is less than 'r1', 0 otherwise
    MOVIL   r11 0x00
    MOVIU   r11 0x00
    CMP     r0  r1
    BHI     1
    ORI     r11 1
    CALL    .led_shift_value
    # Pop caller-saved registers
    POP     r1
    POP     r0

    SUBI    r0  1
    CMPI    r0  0
    JGT     .set_ring_display_and_indicator_values:ring_value_loop

    # Pop caller-saved registers
    POP     r11
    POP     r0

    # Move index pointer to next value
    SUBI    r11 1

    ADDI    r0  1
    CMPI    r0  3
    JLO     .set_ring_display_and_indicator_values:ring_loop

    #
    # END: Write ring display values from array into LED shift register
    #

    # Set latch enable
    CALL    .led_latch_enable

    RET

##
# Shifts a binary value into the LED driver shift register.
#
# @param r11 - the binary value to shift in (must be either a 0 or a 1)
#
# @return void
##
.led_shift_value
    MOV     r0  r11

    MOVIL   r11 U10_I2C_ADDRESS_LOWER
    MOVIU   r11 U10_I2C_ADDRESS_UPPER
    # Set LE = 0, CLK = 0, SDI = 'r11' value, keep other ports high
    MOVIL   r12 0b1111_1000
    MOVIU   r12 0x00
    OR      r12 r0       # Sets LSB (SDI) of byte to write to 'r11' binary value
    # Push caller-saved registers
    PUSH    r0
    # Write the byte
    CALL    .i2c_write_byte
    # Pop caller-saved registers
    POP     r0

    MOVIL   r11 U10_I2C_ADDRESS_LOWER
    MOVIU   r11 U10_I2C_ADDRESS_UPPER
    # Set LE = 0, CLK = 1, SDI = 'r11' value, keep other ports high
    MOVIL   r12 0b1111_1010
    MOVIU   r12 0x00
    OR      r12 r0       # Sets LSB (SDI) of byte to write to 'r11' binary value
    # Write the byte
    CALL    .i2c_write_byte

    RET

##
# Asserts the LE (Latch Enable) signal on the LED driver.
#
# @return void
##
.led_latch_enable
    MOVIL   r11 U10_I2C_ADDRESS_LOWER
    MOVIU   r11 U10_I2C_ADDRESS_UPPER
    # Set LE = 1, CLK = 0, SDI = 0, keep other ports high
    MOVIL   r12 0b1111_1100
    MOVIU   r12 0x00
    CALL    .i2c_write_byte

    RET

#
# END: LED driver interfacing functions
#

#
# BEGIN: Push button interfacing functions
#

##
# Gets whether or not the "Save" button is pressed.
#
# @param r11 - the return value of '.button_get_values'
#
# @return r10 - 1 if the button is pressed, 0 if not
##
.button_is_save_pressed
    ANDI    r11 0x01
    MOV     r10 r11

    RET

##
# Gets whether or not a "Program" button is pressed.
#
# @param r11 - the return value of '.button_get_values'
#
# @return r10 - the program button that is pressed (1 - 3) or 0 for no button pressed
##
.button_is_program_pressed
    # Check "Program1" button
    MOV     r0  r11
    RSHI    r0  1
    ANDI    r0  0x01
    CMPI    r0  1
    JNE     .button_is_program_pressed:after_1
    MOVIL   r10 1
    MOVIU   r10 0x00
    RET
    .button_is_program_pressed:after_1

    # Check "Program2" button
    MOV     r0  r11
    RSHI    r0  2
    ANDI    r0  0x01
    CMPI    r0  1
    JNE     .button_is_program_pressed:after_2
    MOVIL   r10 2
    MOVIU   r10 0x00
    RET
    .button_is_program_pressed:after_2

    # Check "Program3" button
    MOV     r0  r11
    RSHI    r0  3
    ANDI    r0  0x01
    CMPI    r0  1
    JNE     .button_is_program_pressed:after_3
    MOVIL   r10 3
    MOVIU   r10 0x00
    RET
    .button_is_program_pressed:after_3

    MOVIL   r10 0
    MOVIU   r10 0x00
    RET

##
# Gets whether or not the "Play/Pause" button is pressed.
#
# @param r11 - the return value of '.button_get_values'
#
# @return r10 - 1 if the button is pressed, 0 if not
##
.button_is_playpause_pressed
    RSHI    r11 4
    ANDI    r11 0x01

    MOV     r10 r11

    RET

##
# Gets the binary values of the push buttons by reading the input values of the push button ports
# on the I/O Port Expander U10.
#
# @return r10 - an active-high one-hot encoded value of the push buttons with the following mapping:
#               | Bit Index | Button Mapping |
#               | 0         | Save           |
#               | 1         | Program1       |
#               | 2         | Program2       |
#               | 3         | Program3       |
#               | 4         | Play/Pause     |
##
.button_get_values
    MOVIL   r11 U10_I2C_ADDRESS_LOWER
    MOVIU   r11 U10_I2C_ADDRESS_UPPER
    CALL    .i2c_read_byte

    # Shift right 3 times to acquire bits of push buttons values
    RSHI    r10 3

    # Invert return value of '.i2c_read_byte' since push buttons on Main PCB have a pull-up
    # (active low) configuration
    NOT     r10 r10

    # Zero out everything except 5 LSBs
    ANDI    r10 0b0001_1111
    MOVIU   r10 0x00

    RET

#
# END: Push button interfacing functions
#

#
# BEGIN: Rotary encoder interfacing functions
#

##
# Decodes a quadrature-encoded rotary encoder signal (channel A and channel B). This following
# current-state-next-state lookup table can be used to decode quadrature encoded signals:
#  | Previous A | Previous B | Current A  | Current B  | Direction     |
#  | 0          | 0          | 0          | 0          | N/A           |
#  | 0          | 0          | 0          | 1          | CCW (posedge) |
#  | 0          | 0          | 1          | 0          | CW  (posedge) |
#  | 0          | 0          | 1          | 1          | N/A           |
#  | 0          | 1          | 0          | 0          | CW  (negedge) |
#  | 0          | 1          | 0          | 1          | N/A           |
#  | 0          | 1          | 1          | 0          | N/A           |
#  | 0          | 1          | 1          | 1          | CCW (posedge) |
#  | 1          | 0          | 0          | 0          | CCW (negedge) |
#  | 1          | 0          | 0          | 1          | N/A           |
#  | 1          | 0          | 1          | 0          | N/A           |
#  | 1          | 0          | 1          | 1          | CW  (posedge) |
#  | 1          | 1          | 0          | 0          | N/A           |
#  | 1          | 1          | 0          | 1          | CW  (negedge) |
#  | 1          | 1          | 1          | 0          | CCW (negedge) |
#  | 1          | 1          | 1          | 1          | N/A           |
#
# @param r11 - a pointer to a boolean value in memory containing whether or not this decode
#              function observed the following pattern: Channel A = 0 && Channel B = 0
# @param r12 - the current encoder channel binary values with the following mapping:
#              | Bit Index | Channel Mapping                         |
#              | 0         | Channel A binary value (must be 0 or 1) |
#              | 1         | Channel B binary value (must be 0 or 1) |
#
# @return r10 - +1 a clockwise rotation was decoded, -1 if a counter-clockwise rotation was
#               decoded, 0 if there was no change or decoding was indeterminate
##
.rotary_encoder_decode
    ANDI    r12 0b0000_00011
    CMPI    r12 0
    JNE     .rotary_encoder_decode:a_b_not_zeros

    MOVIL   r0  0x01
    MOVIU   r0  0x00
    STORE   r11 r0

    MOVIL   r10 0x00
    MOVIU   r10 0x00
    RET

    .rotary_encoder_decode:a_b_not_zeros

    LOAD    r0  r11
    CMPI    r0  0x01
    JNE     .rotary_encoder_decode:ret_ignore
    CMPI    r12 0b0000_0001
    JEQ     .rotary_encoder_decode:ret_cw
    CMPI    r12 0b0000_0010
    JEQ     .rotary_encoder_decode:ret_ccw

    # If no posedge CW or CCW pattern was observed, return 0
    .rotary_encoder_decode:ret_ignore
    MOVIL   r10 0
    MOVIU   r10 0x00    # Zero extension
    RET

    .rotary_encoder_decode:ret_cw
    MOVIL   r0  0x00
    MOVIU   r0  0x00
    STORE   r11 r0

    MOVIL   r10 1
    MOVIU   r10 0x00    # Zero extension
    RET

    .rotary_encoder_decode:ret_ccw
    MOVIL   r0  0x00
    MOVIU   r0  0x00
    STORE   r11 r0

    MOVIL   r10 -1
    MOVIU   r10 0xFF    # Sign extension
    RET

##
# Gets the binary values of the quadrature-encoded rotary encoder signals (channel A and channel B)
# by reading the input values of the rotary encoder "switch" ports on the I/O Port Expander U11.
#
# @return r10 - an encoding of the rotary encoder channels with the following mapping:
#               | Bit Index | Channel Mapping     |
#               | 0         | Encoder 1 Channel A |
#               | 1         | Encoder 1 Channel B |
#               | 2         | Encoder 2 Channel A |
#               | 3         | Encoder 2 Channel B |
#               | 4         | Encoder 3 Channel A |
#               | 5         | Encoder 3 Channel B |
##
.rotary_encoder_get_values
    MOVIL   r11 U11_I2C_ADDRESS_LOWER
    MOVIU   r11 U11_I2C_ADDRESS_UPPER
    CALL    .i2c_read_byte

    # Zero out everything except 6 LSBs
    ANDI    r10 0b0011_1111

    RET

#
# END: Rotary encoder interfacing functions
#

#
# END: Hardware interfacing functions
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
    # Send not-acknowledgement to slave so that it will no longer transmit its data
    CALL    .i2c_do_nack
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

    MOVIL   r11 2
    MOVIU   r11 0
    CALL    .sleep_n_microseconds

    CALL    .i2c_set_sda_0

    MOVIL   r11 2
    MOVIU   r11 0
    CALL    .sleep_n_microseconds

    CALL    .i2c_set_scl_0

    MOVIL   r11 2
    MOVIU   r11 0
    CALL    .sleep_n_microseconds

    RET

##
# Generates the master STOP condition on the I2C bus.
#
# @return void
##
.i2c_generate_stop_condition
    CALL    .i2c_set_scl_0
    CALL    .i2c_set_sda_0

    MOVIL   r11 2
    MOVIU   r11 0
    CALL    .sleep_n_microseconds

    CALL    .i2c_set_scl_1

    MOVIL   r11 2
    MOVIU   r11 0
    CALL    .sleep_n_microseconds

    CALL    .i2c_set_sda_1

    MOVIL   r11 2
    MOVIU   r11 0
    CALL    .sleep_n_microseconds

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
    MOVIL   r11 2
    MOVIU   r11 0
    CALL    .sleep_n_microseconds
    CALL    .i2c_set_scl_1
    MOVIL   r11 2
    MOVIU   r11 0
    CALL    .sleep_n_microseconds
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
    MOVIL   r11 2
    MOVIU   r11 0
    CALL    .sleep_n_microseconds
    CALL    .i2c_set_scl_1
    MOVIL   r11 2
    MOVIU   r11 0
    CALL    .sleep_n_microseconds
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

    MOVIL   r11 2
    MOVIU   r11 0
    CALL    .sleep_n_microseconds

    CALL    .i2c_set_scl_1

    MOVIL   r11 2
    MOVIU   r11 0
    CALL    .sleep_n_microseconds

    CALL    .i2c_get_sda

    # Invert return value of '.i2c_get_sda' since ACK means slave is pulling the line low
    # and NACK is no slave is pulling the line low (so it stays pulled high)
    NOT     r10 r10

    # Only concered with LSB of return value so zero out everything else
    ANDI    r10 0x01

    # Push caller-saved registers
    PUSH    r10
    # Set SCL back low
    MOVIL   r11 3
    MOVIU   r11 0
    CALL    .sleep_n_microseconds
    CALL    .i2c_set_scl_0
    # Pop caller-saved registers
    POP     r10

    RET

##
# Sends the NACK bit by: Pulls SCL low, sets SDA high, pulses the SCL line.
#
# @return void
##
.i2c_do_nack
    CALL    .i2c_set_scl_0
    CALL    .i2c_set_sda_1

    MOVIL   r11 2
    MOVIU   r11 0
    CALL    .sleep_n_microseconds

    CALL    .i2c_set_scl_1

    MOVIL   r11 2
    MOVIU   r11 0
    CALL    .sleep_n_microseconds

    CALL    .i2c_set_scl_0

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
    ANDI    r11 0xFF

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

##
# Copies the array at 'r11' to 'r12' with length 'r13'.
#
# @param r11 - a pointer to the array to copy from
# @param r12 - a pointer to the array to copy to
# @param r13 - the number of words to copy
#
# @return void
##
.array_copy
    MOVIL   r0  0x00
    MOVIU   r0  0x00

    .array_copy:loop

    LOAD    r5  r11
    STORE   r12  r5

    ADDI    r11 1
    ADDI    r12 1

    ADDI    r0  1
    CMP     r0  r13
    JLO     .array_copy:loop

    RET

##
# This function will call '.sleep_exactly_1040_nanoseconds' 'r11' number of times. Note that
# the '.sleep_48bit' function should be called instead of this one for a large number of
# microseconds OR when the processor frequency isn't exactly 50 MHz.
#
# @param r11 - the number of microseconds to sleep for
#
# @return void
##
.sleep_n_microseconds
    # Use 'r1' and don't push on the stack since that takes time and the
    # '.sleep_exactly_1040_nanoseconds' function doesn't modify it 'r1'
    MOVIL   r1  0
    MOVIU   r1  0

    .sleep_n_microseconds:loop
    CALL    .sleep_exactly_1040_nanoseconds
    ADDI    r1  1
    CMP     r1  r11
    JLO     .sleep_n_microseconds:loop

    RET

##
# This function sleeps for exactly 1,040 nanoseconds (approximately 1 microsecond) when the
# processor frequency is 50 MHz. It simply consists of a busy-wait loop.
#
# @return void
##
.sleep_exactly_1040_nanoseconds
    MOVIL   r0  0
    MOVIU   r0  0

    .sleep_exactly_1040_nanoseconds:loop
    ADDI    r0  1
    CMPI    r0  0x05
    JLS     .sleep_exactly_1040_nanoseconds:loop

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
# function is a few microseconds.
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
.spin
    BUC     -1

#
# END: Utility functions
#








#
# BEGIN: Startup animation sequence frames
#

.startup_animation_sequence_frames
# Start 1st ring display value gradual increment
0b0_00000_00000_00000
0b0_00000_00000_00001
0b0_00000_00000_00010
0b0_00000_00000_00011
0b0_00000_00000_00100
0b0_00000_00000_00101
0b0_00000_00000_00110
0b0_00000_00000_00111
0b0_00000_00000_01000
0b0_00000_00000_01001
0b0_00000_00000_01010
0b0_00000_00000_01011
0b0_00000_00000_01100
0b0_00000_00000_01101
0b0_00000_00000_01110
0b0_00000_00000_01111
0b0_00000_00000_10000
0b0_00000_00000_10001
0b0_00000_00000_10010
0b0_00000_00000_10011

# Start 2nd ring display value gradual increment
0b0_00000_00001_10011
0b0_00000_00010_10011
0b0_00000_00011_10011
0b0_00000_00100_10011
0b0_00000_00101_10011
0b0_00000_00110_10011
0b0_00000_00111_10011
0b0_00000_01000_10011
0b0_00000_01001_10011
0b0_00000_01010_10011
0b0_00000_01011_10011
0b0_00000_01100_10011
0b0_00000_01101_10011
0b0_00000_01110_10011
0b0_00000_01111_10011
0b0_00000_10000_10011
0b0_00000_10001_10011
0b0_00000_10010_10011
0b0_00000_10011_10011

# Start 3rd ring display value gradual increment
0b0_00001_10011_10011
0b0_00010_10011_10011
0b0_00011_10011_10011
0b0_00100_10011_10011
0b0_00101_10011_10011
0b0_00110_10011_10011
0b0_00111_10011_10011
0b0_01000_10011_10011
0b0_01001_10011_10011
0b0_01010_10011_10011
0b0_01011_10011_10011
0b0_01100_10011_10011
0b0_01101_10011_10011
0b0_01110_10011_10011
0b0_01111_10011_10011
0b0_10000_10011_10011
0b0_10001_10011_10011
0b0_10010_10011_10011
0b0_10011_10011_10011

# Start gradual decrement of all ring display values
0b0_10011_10011_10011
0b0_10010_10010_10010
0b0_10001_10001_10001
0b0_10000_10000_10000
0b0_01111_01111_01111
0b0_01110_01110_01110
0b0_01101_01101_01101
0b0_01100_01100_01100
0b0_01011_01011_01011
0b0_01010_01010_01010
0b0_01001_01001_01001
0b0_01000_01000_01000
0b0_00111_00111_00111
0b0_00110_00110_00110
0b0_00101_00101_00101
0b0_00100_00100_00100
0b0_00011_00011_00011
0b0_00010_00010_00010
0b0_00001_00001_00001
0b0_00000_00000_00000

# Start gradual increment of all ring display values to half-way point
0b0_00001_00001_00001
0b0_00010_00010_00010
0b0_00011_00011_00011
0b0_00100_00100_00100
0b0_00101_00101_00101
0b0_00110_00110_00110
0b0_00111_00111_00111
0b0_01000_01000_01000
0b0_01001_01001_01001

#
# END: Startup animation sequence frames
#








#
# BEGIN: Idle 4 animation sequence frames
#
.animation_sequence_idle_4_frames
# Start ring display value gradual increment
0b0_00000_00000_00000
0b0_00001_00001_00001
0b0_00010_00010_00010
0b0_00011_00011_00011
0b0_00100_00100_00100
0b0_00101_00101_00101
0b0_00110_00110_00110
0b0_00111_00111_00111
0b0_01000_01000_01000
0b0_01001_01001_01001
0b0_01010_01010_01010
0b0_01011_01011_01011
0b0_01100_01100_01100
0b0_01101_01101_01101
0b0_01110_01110_01110
0b0_01111_01111_01111
0b0_10000_10000_10000
0b0_10001_10001_10001
0b0_10010_10010_10010
0b0_10011_10011_10011

# Start ring display value gradual decrement
0b0_10011_10011_10011
0b0_10010_10010_10010
0b0_10001_10001_10001
0b0_10000_10000_10000
0b0_01111_01111_01111
0b0_01110_01110_01110
0b0_01101_01101_01101
0b0_01100_01100_01100
0b0_01011_01011_01011
0b0_01010_01010_01010
0b0_01001_01001_01001
0b0_01000_01000_01000
0b0_00111_00111_00111
0b0_00110_00110_00110
0b0_00101_00101_00101
0b0_00100_00100_00100
0b0_00011_00011_00011
0b0_00010_00010_00010
0b0_00001_00001_00001
0b0_00000_00000_00000

#
# END: Idle 4 animation sequence frames
#

