# Problem_1: Sequence Detector FSM (Mealy Model)

## Objective
Design a Mealy FSM to detect the overlapping sequence `1101` on a serial input.  
The output `y = 1` when the sequence is detected; otherwise `y = 0`.

---

## Files
- `seq_detect_mealy.v` – FSM module  
- `tb_seq_detect_mealy.v` – Testbench  

---

## State Diagram
![Sequence Detector State Diagram](sequence_detector.png)

States:
- **S0**: No match  
- **S1**: Detected `1`  
- **S2**: Detected `11`  
- **S3**: Detected `110`  

Output `y=1` occurs on `S3 --(x=1)--> S1`.

---

## Clock Setup
- **System Clock (f_clk):** 100 MHz (default Vivado simulation clock)  
- FSM transitions on every **posedge clk**.  
- Input `x` is applied one bit per clock cycle.

---

## Verification in Vivado
1. Created project `seq_detector_fsm` in Vivado.  
2. Added sources:
   - `seq_detect_mealy.v` as Design Source  
   - `tb_seq_detect_mealy.v` as Simulation Source  
   - Set File Type to SystemVerilog
3. Ran **Behavioral Simulation**.  
4. Verified that:
   - For input stream `1101101`, output `y` pulses high twice.  
   - Overlapping sequences are detected correctly.

---

## Notes
- Simulation waveform shows exact correspondence between bitstream input and FSM state transitions.  
- No external tick divider required.  

