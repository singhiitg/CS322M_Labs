// hazard_unit.sv
// Detects load-use data hazards.
// (EX stage has a load whose Rd matches ID's Rs1 or Rs2).
module hazard_unit(input  logic MemReadE, // 'lw' instruction is in EX stage
                   input  logic [4:0] RdE,    // Destination register of the 'lw'
                   input  logic [4:0] Rs1D, Rs2D, // Source registers of instr in ID
                   output logic stallF, stallD, flushE); // Control signals
  always_comb begin
    // Defaults
    stallF = 0; 
    stallD = 0; 
    flushE = 0;
    
    // Load-use hazard condition
    if (MemReadE && ( (RdE == Rs1D) || (RdE == Rs2D) )) begin
      stallF = 1; // Freeze PC
      stallD = 1; // Freeze IF/ID register
      flushE = 1; // Insert bubble into ID/EX register
    end
  end
endmodule