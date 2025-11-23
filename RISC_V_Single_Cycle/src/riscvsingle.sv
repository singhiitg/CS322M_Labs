// RISC-V single-cycle processor with Custom Extension

// Base single-cycle implementation of RISC-V (RV32I)
// from Digital Design & Computer Architecture.

// This version is extended with a custom instruction set:
//   - New Instructions: ANDN, ORN, XNOR, MIN, MAX, MINU, MAXU, ROL, ROR, ABS
//   - Custom opcode: 7'b0101011 (custom-1)
//   - Exceptions, traps, and interrupts not implemented
//   - Little-endian memory

// 31 32-bit registers x1-x31, x0 hardwired to 0
// Instruction formats are standard RISC-V.
// Custom instructions are R-Type.

module testbench();

  logic        clk;
  logic        reset;

  logic [31:0] WriteData, DataAdr;
  logic        MemWrite;

  // instantiate device to be tested
  top dut(clk, reset, WriteData, DataAdr, MemWrite);
  
  // initialize test
  initial
    begin
      reset <= 1; # 22; reset <= 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  // check results - this testbench is for the original program
  // and will pass if riscvtest.txt is used.
  always @(negedge clk)
    begin
      if(MemWrite) begin
        if(DataAdr === 100 & WriteData === 25) begin
          $display("Simulation succeeded");
          $stop;
        end else if (DataAdr !== 96) begin
          $display("Simulation failed");
          $stop;
        end
      end
    end
endmodule

module top(input  logic        clk, reset, 
           output logic [31:0] WriteData, DataAdr, 
           output logic        MemWrite);

  logic [31:0] PC, Instr, ReadData;
  
  // instantiate processor and memories
  riscvsingle rvsingle(clk, reset, PC, Instr, MemWrite, DataAdr, 
                      WriteData, ReadData);
  imem imem(PC, Instr);
  dmem dmem(clk, MemWrite, DataAdr, WriteData, ReadData);
endmodule

module riscvsingle(input  logic        clk, reset,
                   output logic [31:0] PC,
                   input  logic [31:0] Instr,
                   output logic        MemWrite,
                   output logic [31:0] ALUResult, WriteData,
                   input  logic [31:0] ReadData);

  logic        ALUSrc, RegWrite, Jump, Zero, PCSrc;
  logic [1:0]  ResultSrc, ImmSrc;
  logic [3:0]  ALUControl; // Extended to 4 bits for new instructions

  controller c(Instr[6:0], Instr[14:12], Instr[31:25], Zero,
               ResultSrc, MemWrite, PCSrc,
               ALUSrc, RegWrite, Jump,
               ImmSrc, ALUControl);
  datapath dp(clk, reset, ResultSrc, PCSrc,
               ALUSrc, RegWrite,
               ImmSrc, ALUControl,
               Zero, PC, Instr,
               ALUResult, WriteData, ReadData);
endmodule

module controller(input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic [6:0] funct7, // Use full funct7 for decoding
                  input  logic       Zero,
                  output logic [1:0] ResultSrc,
                  output logic       MemWrite,
                  output logic       PCSrc, ALUSrc,
                  output logic       RegWrite, Jump,
                  output logic [1:0] ImmSrc,
                  output logic [3:0] ALUControl); // Extended to 4 bits

  logic [1:0] ALUOp;
  logic       Branch;

  maindec md(op, ResultSrc, MemWrite, Branch,
             ALUSrc, RegWrite, Jump, ImmSrc, ALUOp);
  aludec  ad(op[5], funct3, funct7, ALUOp, ALUControl); // Pass full funct7

  assign PCSrc = Branch & Zero | Jump;
endmodule

module maindec(input  logic [6:0] op,
               output logic [1:0] ResultSrc,
               output logic       MemWrite,
               output logic       Branch, ALUSrc,
               output logic       RegWrite, Jump,
               output logic [1:0] ImmSrc,
               output logic [1:0] ALUOp);

  logic [10:0] controls;

  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, Branch, ALUOp, Jump} = controls;

  always_comb
    case(op)
    // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump
      7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; // lw
      7'b0100011: controls = 11'b0_01_1_1_00_0_00_0; // sw
      7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0; // R-type 
      7'b1100011: controls = 11'b0_10_0_0_00_1_01_0; // beq
      7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; // I-type ALU
      7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; // jal
      7'b0101011: controls = 11'b1_xx_0_0_00_0_11_0; // Custom R-Type Extension
      default:    controls = 11'bx_xx_x_x_xx_x_xx_x; // non-implemented instruction
    endcase
endmodule

// ALU Decoder: Generates the 4-bit ALUControl signal
module aludec(input  logic       opb5,
              input  logic [2:0] funct3,
              input  logic [6:0] funct7,
              input  logic [1:0] ALUOp,
              output logic [3:0] ALUControl);

  logic is_sub_instr;
  // This signal is true only for the R-Type SUB instruction
  assign is_sub_instr = funct7[5] & opb5;

  always_comb
    case(ALUOp)
      2'b00:      ALUControl = 4'b0000; // lw/sw -> add
      2'b01:      ALUControl = 4'b0001; // beq -> subtract
      
      // R-type or I-type ALU instructions
      2'b10: case(funct3)
               3'b000:  ALUControl = is_sub_instr ? 4'b0001 : 4'b0000; // sub : add/addi
               3'b010:  ALUControl = 4'b0101; // slt, slti
               3'b110:  ALUControl = 4'b0011; // or, ori
               3'b111:  ALUControl = 4'b0010; // and, andi
               default: ALUControl = 4'bxxxx;
             endcase
      
      // Custom Extension Instructions (decoded using funct7 and funct3)
      2'b11: case({funct7, funct3})
               // funct7=0000000
               10'b0000000_000: ALUControl = 4'b1000; // ANDN
               10'b0000000_001: ALUControl = 4'b1001; // ORN
               10'b0000000_010: ALUControl = 4'b1010; // XNOR
               // funct7=0000001
               10'b0000001_000: ALUControl = 4'b1011; // MIN
               10'b0000001_001: ALUControl = 4'b1100; // MAX
               10'b0000001_010: ALUControl = 4'b1101; // MINU
               10'b0000001_011: ALUControl = 4'b1110; // MAXU
               // funct7=0000010
               10'b0000010_000: ALUControl = 4'b0110; // ROL
               10'b0000010_001: ALUControl = 4'b0111; // ROR
               // funct7=0000011
               10'b0000011_000: ALUControl = 4'b1111; // ABS
               default:         ALUControl = 4'bxxxx;
             endcase

      default: ALUControl = 4'bxxxx;
    endcase
endmodule

module datapath(input  logic       clk, reset,
                input  logic [1:0] ResultSrc, 
                input  logic       PCSrc, ALUSrc,
                input  logic       RegWrite,
                input  logic [1:0] ImmSrc,
                input  logic [3:0] ALUControl, // Extended to 4 bits
                output logic       Zero,
                output logic [31:0] PC,
                input  logic [31:0] Instr,
                output logic [31:0] ALUResult, WriteData,
                input  logic [31:0] ReadData);

  logic [31:0] PCNext, PCPlus4, PCTarget;
  logic [31:0] ImmExt;
  logic [31:0] SrcA, SrcB;
  logic [31:0] Result;

  // next PC logic
  flopr #(32) pcreg(clk, reset, PCNext, PC); 
  adder       pcadd4(PC, 32'd4, PCPlus4);
  adder       pcaddbranch(PC, ImmExt, PCTarget);
  mux2 #(32)  pcmux(PCPlus4, PCTarget, PCSrc, PCNext);
 
  // register file logic
  regfile     rf(clk, RegWrite, Instr[19:15], Instr[24:20], 
                 Instr[11:7], Result, SrcA, WriteData);
  extend      ext(Instr[31:7], ImmSrc, ImmExt);

  // ALU logic
  mux2 #(32)  srcbmux(WriteData, ImmExt, ALUSrc, SrcB);
  alu         alu(SrcA, SrcB, ALUControl, ALUResult, Zero);
  mux3 #(32)  resultmux(ALUResult, ReadData, PCPlus4, ResultSrc, Result);
endmodule

module regfile(input  logic       clk, 
               input  logic       we3, 
               input  logic [4:0] a1, a2, a3, 
               input  logic [31:0] wd3, 
               output logic [31:0] rd1, rd2);

  logic [31:0] rf[31:0];

  // three ported register file
  // read two ports combinationally (A1/RD1, A2/RD2)
  // write third port on rising edge of clock (A3/WD3/WE3)
  // register 0 hardwired to 0

  always_ff @(posedge clk)
    if (we3 && (a3 != 5'b0)) rf[a3] <= wd3; // Prevent writing to x0

  assign rd1 = (a1 != 5'b0) ? rf[a1] : 32'b0;
  assign rd2 = (a2 != 5'b0) ? rf[a2] : 32'b0;
endmodule

module adder(input  [31:0] a, b,
             output [31:0] y);

  assign y = a + b;
endmodule

module extend(input  logic [31:7] instr,
              input  logic [1:0]  immsrc,
              output logic [31:0] immext);
 
  always_comb
    case(immsrc) 
              // I-type 
      2'b00:  immext = {{20{instr[31]}}, instr[31:20]};  
              // S-type (stores)
      2'b01:  immext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; 
              // B-type (branches)
      2'b10:  immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; 
              // J-type (jal)
      2'b11:  immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; 
      default: immext = 32'bx; // undefined
    endcase          
endmodule

module flopr #(parameter WIDTH = 8)
             (input  logic             clk, reset,
              input  logic [WIDTH-1:0] d, 
              output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else       q <= d;
endmodule

module mux2 #(parameter WIDTH = 8)
            (input  logic [WIDTH-1:0] d0, d1, 
             input  logic             s, 
             output logic [WIDTH-1:0] y);

  assign y = s ? d1 : d0; 
endmodule

module mux3 #(parameter WIDTH = 8)
            (input  logic [WIDTH-1:0] d0, d1, d2,
             input  logic [1:0]       s, 
             output logic [WIDTH-1:0] y);

  assign y = s[1] ? d2 : (s[0] ? d1 : d0); 
endmodule

module imem(input  logic [31:0] a,
            output logic [31:0] rd);

  logic [31:0] RAM[63:0];

  initial
      $readmemh("riscvtest.txt",RAM);

  assign rd = RAM[a[31:2]]; // word aligned
endmodule

module dmem(input  logic       clk, we,
            input  logic [31:0] a, wd,
            output logic [31:0] rd);

  logic [31:0] RAM[63:0];

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= wd;
endmodule

// ALU with Custom Instruction Extensions
module alu(input  logic [31:0] a, b,
           input  logic [3:0]  alucontrol, // Extended to 4 bits
           output logic [31:0] result,
           output logic        zero);

  logic [31:0] sum;
  logic        v_overflow;
  logic        is_add_sub;
  logic signed [31:0] signed_a, signed_b;
  
  assign signed_a = a;
  assign signed_b = b;

  // Determine if the current operation is an addition or subtraction for overflow calculation
  assign is_add_sub = (alucontrol == 4'b0000) || (alucontrol == 4'b0001);
  assign sum = a + (alucontrol[0] ? ~b : b) + alucontrol[0];

  always_comb
    case (alucontrol)
      4'b0000: result = sum;                         // ADD
      4'b0001: result = sum;                         // SUB
      4'b0010: result = a & b;                       // AND
      4'b0011: result = a | b;                       // OR
      4'b0100: result = a ^ b;                       // XOR (Not in base ISA but good to have)
      4'b0101: result = {31'b0, signed_a < signed_b}; // SLT
      // --- Custom Instructions ---
      4'b0110: result = (a << b[4:0]) | (a >> (32 - b[4:0])); // ROL
      4'b0111: result = (a >> b[4:0]) | (a << (32 - b[4:0])); // ROR
      4'b1000: result = a & ~b;                      // ANDN
      4'b1001: result = a | ~b;                      // ORN
      4'b1010: result = ~(a ^ b);                    // XNOR
      4'b1011: result = (signed_a < signed_b) ? a : b; // MIN (signed)
      4'b1100: result = (signed_a > signed_b) ? a : b; // MAX (signed)
      4'b1101: result = (a < b) ? a : b;             // MINU (unsigned)
      4'b1110: result = (a > b) ? a : b;             // MAXU (unsigned)
      4'b1111: result = (signed_a[31]) ? -signed_a : signed_a; // ABS
      default: result = 32'bx;
    endcase

  assign zero = (result == 32'b0);
  // Note: The original 'v' overflow logic was simplified as it's not used by the processor's control path.
  // A full implementation would be:
  // assign v_overflow = (a[31] == b[31]) && (sum[31] != a[31]) && is_add_sub;
  
endmodule