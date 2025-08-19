# Problem_4: Master/Slave Handshake FSM

## Objective
Design and verify a **4-phase handshake protocol** between a Master and a Slave using FSMs.  
- **Master FSM** transmits 4 bytes, using `req`/`ack` signals for handshaking.  
- **Slave FSM** acknowledges requests, latches data, and asserts `ack` for 2 cycles.  
- The Master generates a `done` pulse after successful transmission of all 4 bytes.  
- A **top-level module** (`link_top.v`) connects the Master and Slave for integration and testing.  

---

## Files
Ensure the following files are in the project directory (all with `.v` extension but written in **SystemVerilog**):  
- `master_fsm.v` – Master FSM module  
- `slave_fsm.v` – Slave FSM module  
- `link_top.v` – Top-level module integrating Master and Slave  
- `tb_link_top.v` – Testbench for simulation  

---

## How to Run in Vivado

### 1. Create a New Vivado Project
- Launch Vivado  
- Create a new RTL project (e.g., `handshake_fsm`)  
- Skip adding sources during project setup  

### 2. Add Source and Simulation Files
- Go to **Add Sources**  
- Add `master_fsm.v`, `slave_fsm.v`, and `link_top.v` as **Design Sources**  
- Add `tb_link_top.v` as a **Simulation Source**  

⚠️ By default Vivado treats `.v` as Verilog. To enable **SystemVerilog parsing**:  
- In the **Sources** pane, right-click each `.v` file  
- Select **Set File Type...**  
- Change to **SystemVerilog**  
- Apply to all files  

---

## 3. Run Simulation
- Go to **Simulation > Run Simulation > Run Behavioral Simulation**  
- Wait for Vivado to compile and launch the simulator  

---

## 4. Expected Behavior

### Master FSM
- **IDLE → DRIVE → WAIT_ACK → DROP_REQ → WAIT_ACK_LOW → NEXT → DONE → IDLE**  
- Asserts `req=1` when data is valid  
- Waits for `ack=1` from Slave before clearing `req`  
- After 4 bytes transmitted, asserts `done=1` for 1 cycle  

### Slave FSM
- **WAIT_REQ → ASSERT_ACK → HOLD_ACK → DROP_ACK → WAIT_REQ**  
- On seeing `req=1`, latches data and asserts `ack=1` for 2 cycles  
- Drops `ack` once Master deasserts `req`  
- Returns to waiting for next `req`  

---

## 5. Verification
- **Waveform shows**:  
  - `req` asserted by Master → `ack` asserted by Slave  
  - Data is latched by Slave during `req=1` phase  
  - Handshake repeats for each of the 4 bytes  
  - After last byte, Master asserts `done=1` and returns to IDLE  

---

## Notes
- `link_top.v` is essential for integration of Master and Slave FSMs.  
- Simulation confirmed correct **4-phase handshake**: `req↑ → ack↑ → req↓ → ack↓`.  
- The design is synthesizable for FPGA hardware communication.  

