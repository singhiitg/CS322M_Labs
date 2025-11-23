# RISC‑V Single‑Cycle (RV32I) — Icarus Verilog Quick Start

This repo contains a **single‑cycle RISC‑V (RV32I) CPU** and a tiny test program.
Follow these steps to build and run the simulation with **Icarus Verilog**.

---

## Files

- `riscvsingle.sv` — SystemVerilog source with the **CPU + testbench**. The testbench top module is `testbench` and instantiates `top` (the CPU).
- `riscvtest.txt` — **Instruction memory image** loaded by `$readmemh` (one 32‑bit hex word per line).
- `riscvtest.s` — (optional) **Assembly** source corresponding to `riscvtest.txt` (for reference).

> ✅ The test prints **“Simulation succeeded”** when the CPU writes the value **25 (0x19)** to **address 100 (0x64)**.

---

## Requirements

- **Icarus Verilog** (iverilog / vvp)
  - Ubuntu/Debian: `sudo apt-get install iverilog`
  - macOS (Homebrew): `brew install icarus-verilog`
  - Windows: install from the official site or MSYS2; ensure `iverilog` and `vvp` are on **PATH**.
- (Optional) **GTKWave** for viewing waveforms: `sudo apt-get install gtkwave` / `brew install gtkwave`

---

## Directory Layout

Put the three files in one folder (example):
```
riscv_single/
├── riscvsingle.sv
├── riscvtest.txt
└── riscvtest.s   
```

> **Important:** The simulation reads `riscvtest.txt` using a **relative path**. Run the simulator **from the folder** that contains the file (or edit the path inside `riscvsingle.sv`).

---

## Build & Run (Terminal)

### Linux / macOS
```bash
cd /path/to/riscv_single

# Compile (enable SystemVerilog-2012 support)
iverilog -g2012 -o cpu_tb riscvsingle.sv

# Run
vvp cpu_tb
```

### Windows (PowerShell or CMD)
```bat
cd C:\path\to\riscv_single
iverilog -g2012 -o cpu_tb riscvsingle.sv
vvp cpu_tb
```

**Expected console output**
```
Simulation succeeded
```

---

## Makefile

You can also use the included `Makefile`:

```bash
make run        # build + run
make waves      # build + run + open wave.vcd in GTKWave
make clean      # remove generated files
```

If you prefer not to use Make, just run the iverilog/vvp commands shown above.

---

## Waveforms (Optional, with GTKWave)

The testbench is set up to dump `wave.vcd`. To open it:

```bash
# after running the simulation:
gtkwave wave.vcd
```

If you don’t see a VCD file, ensure the following block exists inside `module testbench;` in `riscvsingle.sv`:
```systemverilog
initial begin
  $dumpfile("wave.vcd");
  $dumpvars(0, testbench);
end
```

Rebuild and run again to regenerate the VCD.

---

## Notes for Students

- This is a **single‑cycle** RV32I subset implementation aimed at instructional use.
- The provided program image exercises **ALU ops**, **load/store**, and **branches**.
- Success criterion: a store of value **25** to memory address **100**, which triggers the **“Simulation succeeded”** message from the testbench.

---

## License / Credits

This teaching setup is adapted for course use. Original single‑cycle RISC‑V example design is based on standard educational resources for RV32I.