`timescale 1ns/1ps
// Top-level datapath module for the 5-stage pipeline.
// Integrates forwarding, stalling (hazard detection), and branch/jump flushing.

module datapath(input logic clk, reset,
                  output logic [31:0] PC,
                  input  logic [31:0] InstrIF,
                  output logic MemWrite_out,
                  output logic [31:0] DataAdr_out, WriteData_out,
                  input  logic [31:0] ReadData);

  // Optional: Performance monitoring counters
  logic [31:0] cycle_count, instr_retired, stall_count, flush_count, branch_count;
  
  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      cycle_count <= 32'd0;
      instr_retired <= 32'd0;
      stall_count <= 32'd0;
      flush_count <= 32'd0;
      branch_count <= 32'd0;
    end else begin
      cycle_count <= cycle_count + 32'd1;
      if (stallF || stallD) stall_count <= stall_count + 32'd1;
      if (flushE) flush_count <= flush_count + 32'd1;
    end
  end

  // ------------------------------------
  // --- Stage 1: Instruction Fetch (IF) ---
  // ------------------------------------
  logic [31:0] PC_reg, PC_next, PC_plus4;
  assign PC = PC_reg;
  assign PC_plus4 = PC_reg + 32'd4;

  // Pipeline Register: IF/ID
  logic [31:0] IFID_PC, IFID_Instr;

  // Hazard control signals
  logic stallF, stallD, flushE, flushD;
  
  // PC selection logic
  logic PCSrc;  // 1 = take branch/jump, 0 = PC+4
  logic [31:0] PCTarget;
  
  // PC selection mux
  assign PC_next = PCSrc ? PCTarget : PC_plus4;
  
  // PC register
  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      PC_reg <= 32'd0;
    end else if (!stallF) begin // Freeze PC on load-use stall
      PC_reg <= PC_next;
    end
  end

  // IF/ID pipeline register
  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      IFID_PC    <= 32'd0;
      IFID_Instr <= 32'h00000013; // NOP: addi x0, x0, 0
    end else begin
      if (flushD) begin // Flush on branch/jump taken
        IFID_PC    <= 32'd0;
        IFID_Instr <= 32'h00000013; // NOP
      end else if (!stallD) begin // Freeze IF/ID on load-use stall
        IFID_PC    <= PC_reg;
        IFID_Instr <= InstrIF;
      end
      // If stallD is high (and flushD is low), the register is not updated, freezing the stage.
    end
  end

  // ------------------------------------
  // --- Stage 2: Instruction Decode (ID) ---
  // ------------------------------------
  logic [31:0] RegFile [0:31];
  integer i;
  initial for (i=0;i<32;i=i+1) RegFile[i]=32'd0;

  logic [4:0] Rs1D, Rs2D, RdD;
  logic [31:0] ReadData1D, ReadData2D;
  logic [31:0] InstrD;
  assign InstrD = IFID_Instr;
  assign Rs1D = InstrD[19:15];
  assign Rs2D = InstrD[24:20];
  assign RdD  = InstrD[11:7];

  // Combinational read from Register File
  // x0 is hardwired to zero
  assign ReadData1D = (Rs1D != 5'd0) ? RegFile[Rs1D] : 32'd0;
  assign ReadData2D = (Rs2D != 5'd0) ? RegFile[Rs2D] : 32'd0;

  // Instantiate controller
  logic RegWriteD, MemWriteD, MemToRegD, ALUSrcD, BranchD, JumpD;
  logic [1:0] ALUOpD, ImmSrcD, ResultSrcD;
  controller ctrl(.opcode(InstrD[6:0]),
                  .RegWrite(RegWriteD), .MemWrite(MemWriteD),
                  .MemToReg(MemToRegD), .ALUSrc(ALUSrcD),
                  .ALUOp(ALUOpD), .ImmSrc(ImmSrcD), .ResultSrc(ResultSrcD),
                  .Branch(BranchD), .Jump(JumpD));

  // Immediate generation logic
  logic [11:0] immI;
  logic [11:0] immS;
  logic [12:0] immB;
  logic [20:0] immJ;
  assign immI = InstrD[31:20];
  assign immS = {InstrD[31:25], InstrD[11:7]};
  assign immB = {InstrD[31], InstrD[7], InstrD[30:25], InstrD[11:8], 1'b0};
  assign immJ = {InstrD[31], InstrD[19:12], InstrD[20], InstrD[30:21], 1'b0};

  logic [31:0] ImmExtD;
  always_comb begin
    case (ImmSrcD)
      2'b00: ImmExtD = {{20{immI[11]}}, immI}; // I-type
      2'b01: ImmExtD = {{20{immS[11]}}, immS}; // S-type
      2'b10: ImmExtD = {{19{immB[12]}}, immB}; // B-type
      2'b11: ImmExtD = {{11{immJ[20]}}, immJ}; // J-type
      default: ImmExtD = 32'd0;
    endcase
  end

  // Pipeline Register: ID/EX
  logic [31:0] IDEX_ReadData1, IDEX_ReadData2, IDEX_Imm, IDEX_PC;
  logic [4:0]  IDEX_Rs1, IDEX_Rs2, IDEX_Rd;
  logic IDEX_RegWrite, IDEX_MemWrite, IDEX_MemToReg, IDEX_ALUSrc, IDEX_Branch, IDEX_Jump;
  logic [1:0] IDEX_ALUOp, IDEX_ResultSrc;
  logic [2:0] IDEX_funct3;
  logic [6:0] IDEX_funct7, IDEX_opcode;

  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      IDEX_ReadData1 <= 32'd0; IDEX_ReadData2 <= 32'd0; IDEX_Imm <= 32'd0; IDEX_PC <= 32'd0;
      IDEX_Rs1 <= 5'd0; IDEX_Rs2 <= 5'd0; IDEX_Rd <= 5'd0;
      IDEX_RegWrite <= 1'b0; IDEX_MemWrite <= 1'b0; IDEX_MemToReg <= 1'b0;
      IDEX_ALUSrc <= 1'b0; IDEX_Branch <= 1'b0; IDEX_Jump <= 1'b0;
      IDEX_ALUOp <= 2'd0; IDEX_ResultSrc <= 2'd0;
      IDEX_funct3 <= 3'd0; IDEX_funct7 <= 7'd0; IDEX_opcode <= 7'd0;
    end else begin
      // Stall/Flush logic for ID/EX register. Flush (bubble insertion) has priority.
      if (flushE) begin
        // Insert bubble/NOP in EX stage (for load-use stall)
        IDEX_ReadData1 <= 32'd0; IDEX_ReadData2 <= 32'd0; IDEX_Imm <= 32'd0; IDEX_PC <= 32'd0;
        IDEX_Rs1 <= 5'd0; IDEX_Rs2 <= 5'd0; IDEX_Rd <= 5'd0;
        IDEX_RegWrite <= 1'b0; IDEX_MemWrite <= 1'b0; IDEX_MemToReg <= 1'b0;
        IDEX_ALUSrc <= 1'b0; IDEX_Branch <= 1'b0; IDEX_Jump <= 1'b0;
        IDEX_ALUOp <= 2'd0; IDEX_ResultSrc <= 2'd0;
        IDEX_funct3 <= 3'd0; IDEX_funct7 <= 7'd0; IDEX_opcode <= 7'b0010011; // NOP-like opcode
      end else if (!stallD) begin
        // Normal pipeline advancement
        IDEX_ReadData1 <= ReadData1D;
        IDEX_ReadData2 <= ReadData2D;
        IDEX_Imm <= ImmExtD;
        IDEX_PC <= IFID_PC;
        IDEX_Rs1 <= Rs1D; IDEX_Rs2 <= Rs2D; IDEX_Rd <= RdD;
        IDEX_RegWrite <= RegWriteD; IDEX_MemWrite <= MemWriteD; 
        IDEX_MemToReg <= MemToRegD; IDEX_ALUSrc <= ALUSrcD;
        IDEX_Branch <= BranchD; IDEX_Jump <= JumpD;
        IDEX_ALUOp <= ALUOpD; IDEX_ResultSrc <= ResultSrcD;
        IDEX_funct3 <= InstrD[14:12];
        IDEX_funct7 <= InstrD[31:25];
        IDEX_opcode <= InstrD[6:0];
      end
      // If stallD is high (and flushE is low), hold the register values.
    end
  end
  
  // ------------------------------------
  // --- Stage 3: Execute (EX) ---
  // ------------------------------------
  
  // ALU control logic (decodes ALUOp, funct3, funct7)
  // Local parameters for ALU operations
  localparam [4:0] ALU_ADD  = 5'b00000;
  localparam [4:0] ALU_SUB  = 5'b00001;
  localparam [4:0] ALU_AND  = 5'b00010;
  localparam [4:0] ALU_OR   = 5'b00011;
  localparam [4:0] ALU_XOR  = 5'b00100;
  localparam [4:0] ALU_SLT  = 5'b00101;
  localparam [4:0] ALU_SLL  = 5'b00110;
  localparam [4:0] ALU_SRL  = 5'b00111;
  localparam [4:0] ALU_ANDN = 5'b01000;
  localparam [4:0] ALU_ORN  = 5'b01001;
  localparam [4:0] ALU_XNOR = 5'b01010;
  localparam [4:0] ALU_MIN  = 5'b01011;
  localparam [4:0] ALU_MAX  = 5'b01100;
  localparam [4:0] ALU_MINU = 5'b01101;
  localparam [4:0] ALU_MAXU = 5'b01110;
  localparam [4:0] ALU_ROL  = 5'b01111;
  localparam [4:0] ALU_ROR  = 5'b10000;
  localparam [4:0] ALU_ABS  = 5'b10001;

  function automatic [4:0] aluctrl(input logic [1:0] ALUOp, input logic [2:0] f3, input logic [6:0] f7, input logic [6:0] opcode);
    aluctrl = ALU_ADD; // default
    if (opcode == 7'b0001011) begin
      // CUSTOM-0 RVX10
      unique case ({f7,f3})
        {7'b0000000,3'b000}: aluctrl = ALU_ANDN;
        {7'b0000000,3'b001}: aluctrl = ALU_ORN;
        {7'b0000000,3'b010}: aluctrl = ALU_XNOR;
        {7'b0000001,3'b000}: aluctrl = ALU_MIN;
        {7'b0000001,3'b001}: aluctrl = ALU_MAX;
        {7'b0000001,3'b010}: aluctrl = ALU_MINU;
        {7'b0000001,3'b011}: aluctrl = ALU_MAXU;
        {7'b0000010,3'b000}: aluctrl = ALU_ROL;
        {7'b0000010,3'b001}: aluctrl = ALU_ROR;
        {7'b0000011,3'b000}: aluctrl = ALU_ABS;
        default: aluctrl = ALU_ADD;
      endcase
    end else begin // Standard RISC-V
      if (ALUOp == 2'b00) aluctrl = ALU_ADD; // Load/Store/JALR
      else if (ALUOp == 2'b01) aluctrl = ALU_SUB; // Branch
      else begin // R-type or I-type ALU (ALUOp=2'b10)
        // **CORRECTNESS FIX:** Added full decode for ops in alu_core
        unique case (f3)
          3'b000: aluctrl = (f7[5] && (opcode == 7'b0110011)) ? ALU_SUB : ALU_ADD; // ADD/ADDI/SUB
          3'b001: aluctrl = ALU_SLL;  // SLL/SLLI
          3'b010: aluctrl = ALU_SLT;  // SLT/SLTI
          // 3'b011 (SLTU/SLTIU) not implemented in alu_core
          3'b100: aluctrl = ALU_XOR;  // XOR/XORI
          3'b101: aluctrl = ALU_SRL;  // SRL/SRLI (SRA not implemented in alu_core)
          3'b110: aluctrl = ALU_OR;   // OR/ORI
          3'b111: aluctrl = ALU_AND;  // AND/ANDI
          default: aluctrl = ALU_ADD;
        endcase
      end
    end
  endfunction

  // Define wires for forwarding paths from later stages (EX/MEM, MEM/WB)
  logic [31:0] EXMEM_aluOut, EXMEM_writeData;
  logic [4:0] EXMEM_rd;
  logic EXMEM_RegWrite_local, EXMEM_MemWrite_local, EXMEM_MemToReg_local;

  logic [31:0] MEMWB_aluOut, MEMWB_readData;
  logic [4:0] MEMWB_rd;
  logic MEMWB_RegWrite_local, MEMWB_MemToReg_local;

  // Forwarding unit inputs/outputs
  logic [1:0] ForwardA, ForwardB;
  logic [4:0] EX_Rs1, EX_Rs2;
  assign EX_Rs1 = IDEX_Rs1; assign EX_Rs2 = IDEX_Rs2;

  // Signals connecting to the forwarding_unit
  logic [4:0] EXMEM_Rd, MEMWB_Rd;
  logic EXMEM_RegWrite, MEMWB_RegWrite;
  logic [31:0] EXMEM_ALUOut, MEMWB_Result;

  assign EXMEM_ALUOut = EXMEM_aluOut;
  assign EXMEM_Rd = EXMEM_rd;
  assign EXMEM_RegWrite = EXMEM_RegWrite_local;
  assign MEMWB_Rd = MEMWB_rd;
  assign MEMWB_RegWrite = MEMWB_RegWrite_local;
  // MEMWB_Result is assigned in WB stage

  // Default ALU input sources
  logic [31:0] ALU_input_A, ALU_input_B;
  logic [31:0] ALU_srcA, ALU_srcB;

  assign ALU_srcA = IDEX_ReadData1;
  assign ALU_srcB = (IDEX_ALUSrc) ? IDEX_Imm : IDEX_ReadData2;

  // Forwarding MUX logic
  always_comb begin
    ALU_input_A = ALU_srcA;
    ALU_input_B = ALU_srcB;
    // Forwarding logic for Operand A
    if (IDEX_Rs1 != 5'd0) begin
      if (ForwardA == 2'b01) ALU_input_A = EXMEM_ALUOut;   // MEM -> EX
      else if (ForwardA == 2'b10) ALU_input_A = MEMWB_Result; // WB -> EX
    end
    // Forwarding logic for Operand B (if not using immediate)
    if (IDEX_Rs2 != 5'd0 && !IDEX_ALUSrc) begin
      if (ForwardB == 2'b01) ALU_input_B = EXMEM_ALUOut;   // MEM -> EX
      else if (ForwardB == 2'b10) ALU_input_B = MEMWB_Result; // WB -> EX
    end
  end

  // Combinational ALU core function
  function automatic [31:0] alu_core(input logic [31:0] a, input logic [31:0] b, input logic [4:0] ctrl);
    logic [31:0] add_res, sub_res;
    add_res = a + b; sub_res = a - b;
    case (ctrl)
      ALU_ADD:  alu_core = add_res;
      ALU_SUB:  alu_core = sub_res;
      ALU_AND:  alu_core = a & b;
      ALU_OR:   alu_core = a | b;
      ALU_XOR:  alu_core = a ^ b;
      ALU_SLT:  alu_core = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
      ALU_SLL:  alu_core = a << b[4:0];
      ALU_SRL:  alu_core = a >> b[4:0];
      ALU_ANDN: alu_core = a & ~b;
      ALU_ORN:  alu_core = a | ~b;
      ALU_XNOR: alu_core = ~(a ^ b);
      ALU_MIN:  alu_core = ($signed(a) < $signed(b)) ? a : b;
      ALU_MAX:  alu_core = ($signed(a) > $signed(b)) ? a : b;
      ALU_MINU: alu_core = (a < b) ? a : b;
      ALU_MAXU: alu_core = (a > b) ? a : b;
      ALU_ROL:  alu_core = (b[4:0] == 5'd0) ? a
                          : ((a << b[4:0]) | (a >> (6'd32 - b[4:0])));
      ALU_ROR:  alu_core = (b[4:0] == 5'd0) ? a
                          : ((a >> b[4:0]) | (a << (6'd32 - b[4:0])));
      ALU_ABS:  alu_core = ($signed(a) >= 0) ? a : (32'b0 - a);
      default:  alu_core = 32'd0;
    endcase
  endfunction
  
  // Generate the 5-bit ALU control signal
  logic [4:0] ALUControlE;
  always_comb begin
    ALUControlE = aluctrl(IDEX_ALUOp, IDEX_funct3, IDEX_funct7, IDEX_opcode);
  end

  // ALU result and Zero flag
  logic [31:0] ALU_resultE;
  assign ALU_resultE = alu_core(ALU_input_A, ALU_input_B, ALUControlE);
  logic ZeroE; assign ZeroE = (ALU_resultE == 32'd0);
  
  // Branch condition evaluation
  logic BranchTaken;
  always_comb begin
    BranchTaken = 1'b0;
    if (IDEX_Branch) begin
      case (IDEX_funct3)
        3'b000: BranchTaken = ZeroE;       // beq: branch if equal (zero)
        3'b001: BranchTaken = ~ZeroE;      // bne: branch if not equal
        3'b100: BranchTaken = ALU_resultE[0];  // blt: branch if less than (signed)
        3'b101: BranchTaken = ~ALU_resultE[0]; // bge: branch if greater/equal (signed)
        3'b110: BranchTaken = ALU_resultE[0];  // bltu: branch if less than (unsigned)
        3'b111: BranchTaken = ~ALU_resultE[0]; // bgeu: branch if greater/equal (unsigned)
        default: BranchTaken = 1'b0;
      endcase
    end
  end
  
  // PC update logic (determines next PC)
  assign PCTarget = IDEX_PC + IDEX_Imm;
  assign PCSrc = (BranchTaken && IDEX_Branch) || IDEX_Jump;
  
  // Control hazard: Flush IF/ID on taken branch/jump
  assign flushD = PCSrc;

  // Special forwarding for store (sw) data (from Rs2)
  logic [31:0] ForwardedStoreData;
  always_comb begin
    // For stores, Rs2 is the data source
    ForwardedStoreData = IDEX_ReadData2;
    
    // Only forward if Rs2 is not x0
    if (IDEX_Rs2 != 5'd0) begin
      // Forward from MEM stage
      if (EXMEM_RegWrite_local && (EXMEM_rd != 5'd0) && (EXMEM_rd == IDEX_Rs2)) 
        ForwardedStoreData = EXMEM_aluOut;
      // Forward from WB stage (lower priority)
      else if (MEMWB_RegWrite_local && (MEMWB_rd != 5'd0) && (MEMWB_rd == IDEX_Rs2))
        ForwardedStoreData = MEMWB_Result;
    end
  end

  // Pipeline Register: EX/MEM
  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      EXMEM_aluOut <= 32'd0; EXMEM_writeData <= 32'd0;
      EXMEM_rd <= 5'd0; EXMEM_RegWrite_local <= 1'b0; 
      EXMEM_MemWrite_local <= 1'b0; EXMEM_MemToReg_local <= 1'b0;
    end else begin
      EXMEM_aluOut <= ALU_resultE;
      EXMEM_writeData <= ForwardedStoreData;  // Use forwarded data for stores
      EXMEM_rd <= IDEX_Rd;
      EXMEM_RegWrite_local <= IDEX_RegWrite;
      EXMEM_MemWrite_local <= IDEX_MemWrite;
      EXMEM_MemToReg_local <= IDEX_MemToReg;
    end
  end

  // Pipeline Register: MEM/WB
  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      MEMWB_aluOut <= 32'd0; MEMWB_readData <= 32'd0; MEMWB_rd <= 5'd0;
      MEMWB_RegWrite_local <= 1'b0; MEMWB_MemToReg_local <= 1'b0;
    end else begin
      MEMWB_aluOut <= EXMEM_aluOut;
      MEMWB_readData <= ReadData; // Comes from dmem
      MEMWB_rd <= EXMEM_rd;
      MEMWB_RegWrite_local <= EXMEM_RegWrite_local;
      MEMWB_MemToReg_local <= EXMEM_MemToReg_local;
    end
  end

  // Instantiate Forwarding Unit
  forwarding_unit fwd(.Rs1E(EX_Rs1), .Rs2E(EX_Rs2),
                       .RdM(EXMEM_Rd), .RdW(MEMWB_Rd),
                       .RegWriteM(EXMEM_RegWrite), .RegWriteW(MEMWB_RegWrite),
                       .ForwardA(ForwardA), .ForwardB(ForwardB));

  // ------------------------------------
  // --- Stage 4: Memory Access (MEM) ---
  // ------------------------------------
  assign MemWrite_out = EXMEM_MemWrite_local;
  assign DataAdr_out = EXMEM_aluOut;
  assign WriteData_out = EXMEM_writeData;

  // ------------------------------------
  // --- Stage 5: Write Back (WB) ---
  // ------------------------------------
  logic [31:0] WB_value;
  // Result MUX: select memory data or ALU result
  assign WB_value = (MEMWB_MemToReg_local) ? MEMWB_readData : MEMWB_aluOut;
  assign MEMWB_Result = WB_value; // Wire for forwarding from WB

  // Register File write port (synchronous)
  always_ff @(posedge clk) begin
    if (MEMWB_RegWrite_local && (MEMWB_rd != 5'd0)) begin
      RegFile[MEMWB_rd] <= WB_value;
      instr_retired <= instr_retired + 32'd1;  // Count retired instructions
    end
  end
  
  // ------------------------------------
  // --- Verification and Debug Displays ---
  // ------------------------------------
  always @(posedge clk) begin
    if (!reset) begin
      // Check x0 is always zero
      if (RegFile[0] !== 32'd0) begin
        $display("ERROR: x0 = 0x%08h (should be 0) at t=%0t", RegFile[0], $time);
      end
      
      // Check load-use hazard stall
      if (stallF && stallD && flushE) begin
        $display("LOAD-USE STALL: Inserted bubble at t=%0t (RdE=x%0d, Rs1D=x%d, Rs2D=x%d)", 
                 $time, IDEX_Rd, Rs1D, Rs2D);
      end
      
      // Check branch taken
      if (PCSrc && IDEX_Branch) begin
        branch_count <= branch_count + 32'd1;
        $display("BRANCH TAKEN: PC=%0d -> PC=%0d (target=%0d) at t=%0t", 
                 IDEX_PC, PCTarget, PCTarget, $time);
        $display("  Flushing IF/ID stage");
      end
      
      // Check jump
      if (PCSrc && IDEX_Jump) begin
        $display("JUMP: PC=%0d -> PC=%0d (target=%0d) at t=%0t", 
                 IDEX_PC, PCTarget, PCTarget, $time);
        $display("  Flushing IF/ID stage");
      end
    end
  end
  
  // Instantiate Hazard Detection Unit
  logic MemReadE;
  assign MemReadE = (IDEX_opcode == 7'b0000011) ? 1'b1 : 1'b0; // Is 'lw'

  hazard_unit hunit(.MemReadE(MemReadE), .RdE(IDEX_Rd),
                    .Rs1D(Rs1D), .Rs2D(Rs2D),
                    .stallF(stallF), .stallD(stallD), .flushE(flushE));
                    
  // Final simulation performance summary
  final begin
    $display("\n========== PIPELINE PERFORMANCE SUMMARY ==========");
    $display("Total cycles:         %0d", cycle_count);
    $display("Instructions retired: %0d", instr_retired);
    $display("Stall cycles:         %0d", stall_count);
    $display("Flush cycles:         %0d", flush_count);
    $display("Branches taken:       %0d", branch_count);
    if (instr_retired > 0) begin
      $display("Average CPI:          %.2f", real'(cycle_count) / real'(instr_retired));
      $display("Pipeline efficiency:  %.1f%%", 100.0 * real'(instr_retired) / real'(cycle_count));
    end
    $display("==================================================\n");
  end

endmodule
