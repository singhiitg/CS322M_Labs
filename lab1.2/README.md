# Lab 1.2 — 4-bit Equality Comparator
### Roll Number: 206101009 (Saurav Kumar) 
## Description
This project implements a 4-bit digital equality comparator using Verilog. The module compares two 4-bit binary inputs (A and B) and produces an output `equal = 1` only if both inputs are exactly equal.

## Files
- `equality_comparator.v`: Design file containing the comparator logic.
- `tb_equality_comparator.v`: Testbench to simulate and validate the design.
- `equality_comparator.vcd` – Waveform dump file for GTKWave visualization.
- `README.md` – Documentation for the lab assignment.

## Tools Used
- **Icarus Verilog** for simulation
- **GTKWave** for waveform viewing
- **Visual Studio Code** as code editor

## Compilation and Simulation Steps

1. **Open terminal in the project directory**:
   ```bash
   cd path/to/CS322M_Labs/lab1.2
2. **Compile**:
    iverilog -o equality_comparator.vvp equality_comparator.v tb_equality_comparator.v
3. **Run**
    vvp equality_comparator.vvp
4. **View waveform**
    gtkwave equality_comparator.vcd

