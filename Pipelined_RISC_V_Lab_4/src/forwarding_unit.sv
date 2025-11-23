// forwarding_unit.sv
// Detects RAW data hazards and determines forwarding paths for ALU inputs.
module forwarding_unit(input logic [4:0] Rs1E, Rs2E,    // Source regs in EX
                       input logic [4:0] RdM, RdW,      // Destination regs in MEM/WB
                       input logic RegWriteM, RegWriteW, // Write enables from MEM/WB
                       output logic [1:0] ForwardA, ForwardB);

  // Forwarding codes:
  // 2'b00: No forward (use value from ID/EX register)
  // 2'b01: Forward from MEM stage (EX/MEM register)
  // 2'b10: Forward from WB stage (MEM/WB register)

  always_comb begin
    // Defaults
    ForwardA = 2'b00; 
    ForwardB = 2'b00;
    
    // --- Forwarding for Operand A (Rs1E) ---
    // Priority: MEM stage has newer data than WB stage.
    if (RegWriteM && (RdM != 5'd0) && (RdM == Rs1E))
      ForwardA = 2'b01; // MEM -> EX
    else if (RegWriteW && (RdW != 5'd0) && (RdW == Rs1E))
      ForwardA = 2'b10; // WB -> EX
      
    // --- Forwarding for Operand B (Rs2E) ---
    if (RegWriteM && (RdM != 5'd0) && (RdM == Rs2E))
      ForwardB = 2'b01; // MEM -> EX
    else if (RegWriteW && (RdW != 5'd0) && (RdW == Rs2E))
      ForwardB = 2'b10; // WB -> EX
  end
endmodule