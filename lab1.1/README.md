# CS322M – HDL Lab Assignment 1.1  
### Roll Number: 206101009 (Saurav Kumar) 

## Title: Design and Simulation of a 1-Bit Comparator using Verilog

## Objective
The objective of this lab assignment is to design a 1-bit comparator circuit using Verilog Hardware Description Language (HDL). The circuit accepts two 1-bit binary inputs, `A` and `B`, and produces the following outputs:

- `o1 = 1` if `A > B`
- `o2 = 1` if `A == B`
- `o3 = 1` if `A < B`

## Description
This 1-bit comparator checks the relationship between two single-bit inputs and activates the corresponding output based on the comparison result. The design is implemented in Verilog and verified using a testbench simulation.

## Files Included
- `comparator.v` – Verilog module for the 1-bit comparator.
- `tb_comparator.v` – Verilog testbench for simulating the comparator behavior.
- `comparator.vvp` – Compiled simulation file (generated via Icarus Verilog).
- `comparator.vcd` – Waveform dump file for GTKWave visualization.
- `README.md` – Documentation for the lab assignment.

## Tools Used
- **Icarus Verilog** for simulation
- **GTKWave** for waveform viewing
- **Visual Studio Code** as code editor

## Compilation and Simulation Steps

1. **Open terminal in the project directory**:
   ```bash
   cd path/to/CS322M_Labs/lab1.1
2. **Compile**:
    iverilog -o comparator.vvp comparator.v tb_comparator.v
3. **Run**
    vvp comparator.vvp
4. **View waveform**
    gtkwave comparator.vcd

