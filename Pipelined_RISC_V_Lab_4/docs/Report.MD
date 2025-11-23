# **RVX10-P: 5-Stage Pipelined RISC-V Processor **

**Design Report**  
**Date:** November 2025  
**Architecture:** RISC-V RV32I + RVX10 Custom Extension  
**Implementation:** 5-Stage Pipeline with Full Hazard Management  

---

## **Table of Contents**

1. [Executive Summary](#executive-summary)  
2. [Architecture Overview](#architecture-overview)  
3. [Pipeline Stages](#pipeline-stages)  
4. [Hazard Detection and Resolution](#hazard-detection-and-resolution)  
5. [RVX10 Custom Instruction Set](#rvx10-custom-instruction-set)  
6. [Module Descriptions](#module-descriptions)  
7. [Control Signals](#control-signals)  
8. [Performance Analysis](#performance-analysis)  
9. [Verification and Testing](#verification-and-testing)  
10. [Design Decisions and Tradeoffs](#design-decisions-and-tradeoffs)

---

## **Executive Summary**

This document describes the design and implementation of **RVX10-P**, a 5-stage pipelined RISC-V processor implementing the **RV32I** base instruction set augmented with **RVX10 custom bitwise and arithmetic operations**.  
The processor incorporates comprehensive hazard management including **data forwarding**, **load-use stall detection**, and **branch prediction with flush mechanisms**.

### **Key Features**
- **5-stage classic RISC pipeline** (IF, ID, EX, MEM, WB)  
- **Full data hazard resolution** via forwarding and stalling  
- **Control hazard handling** with predict-not-taken branch strategy  
- **RVX10 custom instruction set** (10 additional ALU operations)  
- **Performance monitoring** with cycle counters and CPI calculation  
- **Efficient operation**, achieving ~1.2–1.3 CPI on typical workloads  

---

## **Architecture Overview**

### **Block Diagram**

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│   IF    │───▶│   ID    │───▶│   EX    │───▶│   MEM   │───▶│   WB    │
│ Fetch   │    │ Decode  │    │ Execute │    │ Memory  │    │ Write   │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
     ▲              │              │              │              │
     │              │              ▼              │              │
     │         ┌────┴────┐    ┌────────┐         │              │
     │         │ Hazard  │    │ Forward│         │              │
     └─────────│  Unit   │◀───│  Unit  │◀────────┴──────────────┘
               └─────────┘    └────────┘
                    │
                    ▼
              Stall/Flush Control
```

### **Pipeline Register Chain**

```
PC_reg → IFID → IDEX → EXMEM → MEMWB → RegFile
```

Each pipeline register captures control signals, data, and metadata required for subsequent stages.

---

## **Pipeline Stages**

### **1. Instruction Fetch (IF)**

**Purpose:** Fetch instruction from instruction memory based on the PC value.

**Components:**
- **PC Register (`PC_reg`)** – Holds current program counter  
- **Instruction Memory (`imem`)** – Provides instruction word  
- **PC Incrementer** – Computes `PC + 4` for sequential execution  
- **PC Multiplexer** – Selects next PC (sequential or branch target)

**Operations:**
```systemverilog
PC_next = PCSrc ? PCTarget : PC_plus4;

always_ff @(posedge clk, posedge reset) begin
  if (reset) PC_reg <= 32'd0;
  else if (!stallF) PC_reg <= PC_next;
end
```

**Pipeline Register (IF/ID):**
- `IFID_PC`: Program counter value (for branch target calculation)  
- `IFID_Instr`: 32-bit instruction word  

**Stall/Flush Control:**
- **Stall (`stallF`)** – Freezes PC on load-use hazard  
- **Flush (`flushD`)** – Inserts NOP on taken branch/jump  

---

### **2. Instruction Decode (ID)**

**Purpose:** Decode the instruction, read register file, generate control signals, and compute immediate values.

**Components:**
- **Register File (32×32-bit)** – General-purpose registers x0–x31  
- **Controller** – Combinational logic generating control signals  
- **Immediate Extender** – Sign-extends immediates based on instruction type  

**Register File Implementation:**
```systemverilog
logic [31:0] RegFile [0:31];

// Read ports (combinational)
ReadData1D = (Rs1D != 5'd0) ? RegFile[Rs1D] : 32'd0;
ReadData2D = (Rs2D != 5'd0) ? RegFile[Rs2D] : 32'd0;

// Write port (from WB stage)
always_ff @(posedge clk) begin
  if (MEMWB_RegWrite_local && MEMWB_rd != 5'd0)
    RegFile[MEMWB_rd] <= WB_value;
end
```

**Note:** Register x0 is hardwired to zero via read logic.

**Immediate Formats:**

| Type | Encoding | Usage |
|------|-----------|-------|
| I-type | `inst[31:20]` | ALU immediate, loads |
| S-type | `{inst[31:25], inst[11:7]}` | Store offset |
| B-type | `{inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}` | Branch offset |
| J-type | `{inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}` | Jump offset |

**Controller Outputs:**
- `RegWrite`, `MemWrite`, `MemToReg`, `ALUSrc`, `Branch`, `Jump`  
- `ALUOp[1:0]`, `ImmSrc[1:0]`, `ResultSrc[1:0]`

**Pipeline Register (ID/EX):**
```systemverilog
IDEX_ReadData1, IDEX_ReadData2   // Register values
IDEX_Imm, IDEX_PC                // Immediate and PC
IDEX_Rs1, IDEX_Rs2, IDEX_Rd      // Register indices
IDEX_RegWrite, IDEX_MemWrite, ... // Control signals
IDEX_funct3, IDEX_funct7, IDEX_opcode // Instruction fields
```

**Hazard Interaction:**
- **Stall (`stallD`)** – Holds ID/EX register on load-use hazard  
- **Flush (`flushE`)** – Inserts NOP bubble into ID/EX on load-use stall  
