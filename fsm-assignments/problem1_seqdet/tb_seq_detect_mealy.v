`timescale 1ns/1ps
module tb_seq_detect_mealy;
  reg clk=0, rst=1, din=0;
  wire y;
  seq_detect_mealy dut(.clk(clk), .rst(rst), .din(din), .y(y));

  always #5 clk = ~clk;  // 100 MHz

  task send(input bit b);
    begin din=b; @(posedge clk); end
  endtask

  initial begin
    $dumpfile("dump.vcd"); $dumpvars(0, tb_seq_detect_mealy);
    repeat(2) @(posedge clk);
    rst = 0;

    // Stream with overlaps: 11011011101
    send(1); send(1); send(0); send(1);
    send(1); send(0); send(1);
    send(1); send(1); send(1); send(0); send(1);

    // Print as we go
    $display(" time  din  y");
    repeat(5) @(posedge clk); // already sent; show last clocks
    $finish;
  end

  always @(posedge clk) $display("%4t   %0b    %0b", $time, din, y);
endmodule

