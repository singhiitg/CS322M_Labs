// riscvpipeline.sv
// Wrapper module for the main datapath.
// This module encapsulates the datapath and is instantiated by top_pipeline.

module riscvpipeline(input logic clk, reset,
                       output logic [31:0] PC,
                       input  logic [31:0] InstrIF,
                       output logic MemWrite_out,
                       output logic [31:0] DataAdr_out, WriteData_out,
                       input  logic [31:0] ReadData);

  // Instantiate the main datapath
  datapath dp(.clk(clk), .reset(reset),
              .PC(PC),
              .InstrIF(InstrIF),
              .MemWrite_out(MemWrite_out),
              .DataAdr_out(DataAdr_out),
              .WriteData_out(WriteData_out),
              .ReadData(ReadData));
endmodule
