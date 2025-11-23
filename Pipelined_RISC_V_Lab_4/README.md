# 🧠 RVX10-P: 5-Stage Pipelined RISC-V Processor

A compact and efficient **5-stage pipelined RISC-V core** implementing the standard **RV32I** instruction set, extended with a **custom RVX10** instruction set for enhanced bitwise and arithmetic computation.

---

## ⚙️ System Overview

### 🧩 Processor Pipeline
The processor follows a **classic 5-stage pipeline**, designed for high-throughput and modular extensibility:

IF → ID → EX → MEM → WB

markdown
Copy code

| Stage | Description |
|:------|:-------------|
| **IF** | Instruction Fetch — Retrieves instruction from program memory |
| **ID** | Instruction Decode — Generates control signals and reads register file |
| **EX** | Execute — Performs ALU and branch operations |
| **MEM** | Memory Access — Handles load/store operations |
| **WB** | Write Back — Updates destination register |

### 💾 Core Features
- **ISA:** RISC-V RV32I (32-bit integer)
- **Registers:** 32 general-purpose registers (x0–x31, x0 fixed to 0)
- **Architecture:** Harvard (independent instruction and data memories)
- **Custom Extension:** RVX10 instruction set (under CUSTOM-0 opcode)

---

## ⚡ Pipeline Control & Hazard Management

The design includes **complete hazard handling** for smooth pipeline operation:

✅ **Data Forwarding:**  
 EX → EX, MEM → EX, and WB → EX paths supported  

✅ **Load-Use Stall:**  
 Automatic one-cycle stall when a dependent instruction follows a load  

✅ **Store Forwarding:**  
 Ensures correct data consistency in memory stores  

✅ **Branch Control:**  
 Predict-not-taken scheme with a single-cycle penalty on taken branches  

✅ **Flush Mechanism:**  
 Pipeline flushed on jumps and taken branches  

---

## 🧮 RVX10 Custom ALU Extensions

Ten custom instructions are integrated under the **RISC-V CUSTOM-0** opcode, divided into three main categories:

| Category | Instructions | Description |
|-----------|---------------|-------------|
| **Bitwise** | `andn`, `orn`, `xnor` | Advanced boolean operations |
| **Comparison** | `min`, `max`, `minu`, `maxu` | Signed and unsigned comparison |
| **Rotation** | `rol`, `ror` | Bit rotation left/right |
| **Arithmetic** | `abs` | Absolute value operation |

---

## 🚀 Performance Summary

| Metric | Typical Value |
|:-------|:---------------|
| **CPI (avg)** | 1.2 – 1.3 |
| **Pipeline Utilization** | 77% – 83% |
| **Target Frequency** | ~500 MHz (≈ 2 ns period) |
| **Throughput** | ~400 MIPS |

---

## 🗂️ Project Structure

rvx10_P/
├── src/
│ ├── datapath.sv # Core datapath & pipeline registers
│ ├── riscvpipeline.sv # Top-level processor integration
│ ├── controller.sv # Instruction decoder and control unit
│ ├── forwarding_unit.sv # Forwarding logic
│ └── hazard_unit.sv # Stall and hazard detection
│
├── tb/
│ ├── tb_pipeline.sv # Functional testbench
│ └── tb_pipeline_hazard.sv# Extended hazard verification
│
├── tests/
│ ├── rvx10_pipeline.hex # Functional test program
│ └── rvx10_hazard_test.hex# Hazard validation suite
│
├── docs/
│ └── REPORT.md # Detailed design documentation
│
└── README.md # This file

yaml
Copy code

---

## 🔧 Setup & Requirements

### 🖥️ Required Tools
- **Icarus Verilog (`iverilog`)** — for simulation  
- **GTKWave** — for waveform analysis (optional)  
- **Make** — for build automation (optional)

### 🧱 Installation

**Ubuntu / Debian:**
```bash
sudo apt update
sudo apt install iverilog gtkwave
macOS (Homebrew):

bash
Copy code
brew install icarus-verilog gtkwave
▶️ Getting Started
1. Clone the Repository
bash
Copy code
git clone https://github.com/yourusername/rvx10_P.git
cd rvx10_P
2. Build the Design
bash
Copy code
iverilog -g2012 -o pipeline_tb src/*.sv tb/tb_pipeline.sv
3. Run Simulation
bash
Copy code
vvp pipeline_tb
🧾 Sample Simulation Output
css
Copy code
STORE @ 96 = 0x00000000 (t=55000)
WB stage: Writing 5 to x10     t=75000
WB stage: Writing 3 to x11     t=85000
RVX10 EX stage: ALU result = 4 → x5   t=105000
FORWARDING: EX-to-EX detected for x5  t=120000
STORE @ 100 = 0x00000019 (t=325000)

========== PIPELINE PERFORMANCE SUMMARY ==========
Total cycles:        30
Instructions retired: 25
Stall cycles:          0
Flush cycles:          0
Average CPI:        1.20
Pipeline efficiency: 83.3%
🧩 Functional Verification
🧪 Basic Pipeline Test
Tests the pipeline operation along with all RVX10 custom instructions.

bash
Copy code
iverilog -g2012 -o pipeline_tb src/*.sv tb/tb_pipeline.sv
vvp pipeline_tb
Program: tests/rvx10_pipeline.hex

Expected Results:

Event	Count
Load-use stalls	3
Forwarding events	18
Total stores	8
Average CPI	1.35

📈 Waveform Visualization
To view signal waveforms using GTKWave:

bash
Copy code
iverilog -g2012 -o pipeline_tb src/*.sv tb/tb_pipeline.sv
vvp pipeline_tb -vcd
gtkwave dump.vcd
🧠 Summary
The RVX10-P core demonstrates how a lightweight RV32I processor can achieve near single-cycle performance with proper forwarding, hazard handling, and carefully integrated custom ALU extensions — all while maintaining modular and synthesizable SystemVerilog design.

Author: Saurav Kumar[206101009]
Project: RVX10-P Pipelined RISC-V Core
Date: November 2025
