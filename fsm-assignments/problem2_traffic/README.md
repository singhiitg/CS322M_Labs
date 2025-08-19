# Problem_2: Traffic Light FSM (Moore Model)

## Objective
Design a Moore FSM for a two-way traffic light controller.  
The controller cycles through four phases with fixed durations:  
- **NS Green** (5 ticks)  
- **NS Yellow** (2 ticks)  
- **EW Green** (5 ticks)  
- **EW Yellow** (2 ticks)  

---

## Files
Ensure the following files are in the project directory (all with `.v` extension but written in **SystemVerilog**):  
- `traffic_light.v` – Main Moore FSM for traffic lights  
- `tb_traffic_light.v` – Testbench for simulation  

---

## How to Run in Vivado

### 1. Create a New Vivado Project
- Launch Vivado  
- Create a new RTL project (e.g., `traffic_light_fsm`)  
- Skip adding sources during project setup  

### 2. Add Source and Simulation Files
- Go to **Add Sources**  
- Add `traffic_light.v` as a **Design Source**  
- Add `tb_traffic_light.v` as a **Simulation Source**  

⚠️ By default Vivado treats `.v` as Verilog. To enable **SystemVerilog parsing**:  
- In the **Sources** pane, right-click each `.v` file  
- Select **Set File Type...**  
- Change to **SystemVerilog**  
- Apply to both files  

---

## 3. Run Simulation
- Go to **Simulation > Run Simulation > Run Behavioral Simulation**  
- Wait for Vivado to compile and launch the simulator  

---

## 4. Expected Behavior
During simulation, the FSM cycles through the four phases:  

| Phase      | Duration | Outputs High |
|------------|----------|--------------|
| NS Green   | 5 ticks  | `ns_g=1, ew_r=1` |
| NS Yellow  | 2 ticks  | `ns_y=1, ew_r=1` |
| EW Green   | 5 ticks  | `ew_g=1, ns_r=1` |
| EW Yellow  | 2 ticks  | `ew_y=1, ns_r=1` |

- The waveform shows each state lasting exactly **5 or 2 ticks**, controlled by the `tick_1hz` input.

---

## 5. Tick Generation
- **Real hardware:** A clock divider generates a **1 Hz tick** from the system clock (e.g., `50 MHz ÷ 50,000,000`).  
- **Simulation:** The tick was **scaled down** so that `tick_1hz` goes high once every **10 clock cycles**, allowing faster testing.  
- **Verification:** Confirmed in waveform that:  
  - NS_G lasted 5 ticks before NS_Y  
  - NS_Y lasted 2 ticks before EW_G  
  - EW_G lasted 5 ticks before EW_Y  
  - EW_Y lasted 2 ticks before NS_G (cycle repeats)  

---

