// tb_pipeline.sv

`timescale 1ns/1ps
module tb_pipeline();
  logic clk, reset;
  logic [31:0] WriteData, DataAdr;
  logic MemWrite;
  
  top_pipeline dut(.clk(clk), .reset(reset), .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite));
  
initial begin
  $dumpfile("pipeline_tb.vcd");
  $dumpvars(0, tb_pipeline);
  reset = 1; #22; reset = 0;
end
  always begin 
    clk = 1; #5; clk = 0; #5; 
  end
  
  always @(negedge clk) begin
    if (MemWrite) $display("STORE @ %0d = 0x%08h (t=%0t)", DataAdr, WriteData, $time);
    if (MemWrite) begin
      if ((DataAdr === 100) && (WriteData === 25)) begin
        $display("Simulation succeeded");
        // Print checksum x28 if accessible
        $display("CHECKSUM (x28) = %0d (0x%08h)", dut.cpu.dp.RegFile[28], dut.cpu.dp.RegFile[28]);
        $finish;
      end else if (DataAdr !== 96) begin
        $display("Simulation failed");
        $finish;
      end
    end
  end

endmodule
