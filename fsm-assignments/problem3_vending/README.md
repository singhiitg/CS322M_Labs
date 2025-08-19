# Proble_3: Vending Machine FSM (Mealy Model)

## Objective
Design a vending machine FSM that accepts coins of 5 and 10 units.  
- Price = 20 units  
- Output `dispense = 1` when an item is delivered  
- Output `chg5 = 1` when change of 5 is returned  

---

## Files
- `vending_mealy.v` – FSM module  
- `tb_vending_mealy.v` – Testbench  

---

## State Diagram
![Vending Machine FSM](vending_machine.png)

States represent current credit:  
- **S0**: 0  
- **S5**: 5  
- **S10**: 10  
- **S15**: 15  

Outputs:
- `dispense=1` when total ≥ 20  
- `chg5=1` if overpayment of 5 occurs  

---

## Clock Setup
- **System Clock (f_clk):** 100 MHz (Vivado default simulation clock)  
- FSM transitions on every **posedge clk**.  
- Inputs `p5` and `p10` are applied as pulses aligned with the clock.

---

## Verification in Vivado
1. Created project `vending_machine_fsm` in Vivado.  
2. Added sources:
   - `vending_mealy.v` as Design Source  
   - `tb_vending_mealy.v` as Simulation Source  
   - Change to **SystemVerilog**  
	- Apply to all files  
3. Ran **Behavioral Simulation**.  
4. Verified test sequences:
   - Input: `p5, p5, p10` → `dispense=1`  
   - Input: `p10, p10` → `dispense=1`  
   - Input: `p10, p5, p10` → `dispense=1, chg5=1`  

---

## Notes
- FSM verified in simulation waveforms.  
- FSM resets automatically to state `S0` after dispense.  

