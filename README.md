# Fully-Synchronized Synthesizer (FSS) Prototype

This FSS prototype demonstrates the future of interfacing with a music synthesizer. Musicians often switch between programs on their synth as part of their creative process when experimenting with different sounds. However, the control knobs on their synth can't dynamically update to visually display the true value of that knob when switching between prorams. This FSS prototype solves this issue by providing program-synchronized ring displays surrounding control knobs flush with a top panel, along with internal components housed in a beautiful wooden chassis, and interfaced with via a single USB cable. This repository contains various source files, design files, datasheets, and documentation relevant to the development of this prototype. This prototype serves as the final project for the Computer Design Laboratory ECE 3710 class at The University of Utah for Group 2. As a requirement for this class, this final project uses the [`CompactRISC16`](https://github.com/Petersoj/CompactRISC16) CPU and assembler that our group built as well. This CPU runs on an FPGA and executes our custom assembly code which is responsible for the FSS interface logic and communication. The FPGA board interfaces with the FSS prototype via I2C using a braided USB cable with the D+/D- pins adapted to be the SCL and SDA pins.

## Authors
- Jacob Peterson
- Brady Hartog
- Isabella Gilman
- Nate Hansen

## Verilog Source Naming Conventions and Format
- File names, module names, and wire/reg assignment names should be snake case (e.g. `my_verilog_module.v`)
- Testbench modules and file names should be appended with a `_tb` (e.g. `my_verilog_module_tb.v`)
- Top level modules and file names should be appended with a `_top` (e.g. `my_verilog_module_top.v`)
- There should only be one module per source code file
- Module instantiations should use uppercase named port lists with inputs prepended with `I_` and outputs prepended with `O_` (e.g. `my_verilog_module(.I_INPUT_1(my_input_1), .O_OUTPUT_1(my_output_1));`)
- Module signatures and bodies should use parameters instead of hard-coding constants. When defining the parameters for a module instantiation or for a module signature, the parameter list should start on the next line, but if there is only one parameter, it should be defined on the same line as the module instantiation or signature (same goes for the port list of a module).
- The port list in module signatures should contain `input` and `output` port direction declarations, as opposed to those port direction declarations being placed in the body of the module.
- Consecutive single line comments should always be aligned with eachother if there are no lines between them.
- If there are 2 or more consecutive lines (including no comments between the consecutive lines) that assign a `parameter`, `localparam`, `wire`, or `reg` to a constant or to a single-line expression, then the equals signs in those lines should be aligned.
- If a single-line expression/assignment needs to be split into multiple lines, then the following lines should be further indented by 8 spaces, or if the subsequent lines can fit within the 100 character column limit, then the subsequent lines should be further indented until they are aligned to the expression/assigment on the first line.
- No line should be greater than 100 characters.
- Use non-blocking assignments (e.g. `<=`) in sequential `@always` blocks and blocking assignments (e.g. `=`) in combinational `@always` blocks.
  - An `@always` block is sequential if it is sensitive to the `posedge` or `negedge` of an input signal, whereas it is combinational if it is sensitive to signals without the `posedge` or `negedge` modifier included in the sensitivity list.
- Module sections should generally follow the following format, from top of file to bottom of file:
  - Module signature with parameter list, then input wires, then output reg/wires
  - `localparam`s that defines constants for the rest of the module
  - Internal register and wire declarations
    - Prepend reg/wire names with `q_` to represent a 'current state' register/wire and `n_` to represent a 'next state' register/wire
  - Output mapping `assign` statements which map internal wires/registers with module output wires/registers
  - RTL logic with `assign` statements for all internal wires which generally consist of ternary operators
  - Module instantiations using named port lists in the instantiation signature and a module instance name that is the same as the module name (or a name that's more concise and applicable to the instantiation), but with `i` prepended
  - Clock `@always` blocks which generally should only include `posedge I_CLK` in the sensitivty list
  - Other `@always` (such as internal finite state machines) or `task` blocks

## Verilog Source Formatting
To format verilog source code, use the [`istyle-verilog-formatter`](https://github.com/thomasrussellmurphy/istyle-verilog-formatter) tool via the `format` script:
```
.formatter/verilog/format <paths to files or directories>
```
For example, to recursively format Verilog source files in the `src` directory, use the following command:
```
.formatter/verilog/format src
```
The [`istyle-verilog-formatter`](https://github.com/thomasrussellmurphy/istyle-verilog-formatter) is used as a submodule in the [`.formatter/verilog`](.formatter/verilog) directory. Either clone this repository with `git clone --recurse-submodules` or use `git submodule init; git submodule update` to clone the `istyle-verilog-formatter` repository into the `.formatter/verilog` directory so that the `format` script can run properly. The `format` shell script will run `make` if the `iStyle` binary is not already present in the `istyle-verilog-formatter` directory. Note: you may need to make the script executable via: `chmod 755 .formatter/verilog/format`.

