`timescale 1ns/1ps
module tb_vending_mealy;
  reg clk=0, rst=1;
  reg [1:0] coin=2'b00;
  wire dispense, chg5;

  vending_mealy dut(.clk(clk),.rst(rst),.coin(coin),.dispense(dispense),.chg5(chg5));
  always #5 clk=~clk;

  task put5;  begin coin=2'b01; @(posedge clk); coin=2'b00; @(posedge clk); end endtask
  task put10; begin coin=2'b10; @(posedge clk); coin=2'b00; @(posedge clk); end endtask

  initial begin
    $dumpfile("dump.vcd"); $dumpvars(0, tb_vending_mealy);
    repeat(2) @(posedge clk); rst=0;

    $display("Seq: 10+10  -> vend");
    put10(); put10();

    $display("Seq: 5+5+10 -> vend");
    put5(); put5(); put10();

    $display("Seq: 10+5+10 -> vend+chg5");
    put10(); put5(); put10();

    repeat(5) @(posedge clk);
    $finish;
  end

  always @(posedge clk)
    $display("%4t coin=%b  disp=%0b chg5=%0b", $time, coin, dispense, chg5);
endmodule

