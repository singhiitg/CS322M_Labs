


// tb_comparator.v
// Testbench for 1-bit comparator module

`timescale 1ns / 1ns  

module tb_comparator;
    // Declare input variables as registers
    reg A, B;

    // Declare output wires
    wire o1, o2, o3;

    // Instantiate the Unit Under Test (UUT)
    comparator uut (
        .A(A),    // Connect input A
        .B(B),    // Connect input B
        .o1(o1),  // A > B
        .o2(o2),  // A == B
        .o3(o3)   // A < B
    );

    // Initial block: executes once at time 0
    initial begin
        // Dump waveform data to file (for GTKWave)
        $dumpfile("comparator.vcd");       // Create VCD file
        $dumpvars(0, tb_comparator);       // Dump all variables in this module

        // Print header for better readability in terminal
        $display("A B | A>B A=B A<B");
        $display("------------------");

        // Test Case 1: A = 0, B = 0 → A == B
        A = 0; B = 0; #10;                  // Wait 10 ns
        $display("%b %b |  %b   %b   %b", A, B, o1, o2, o3);

        // Test Case 2: A = 0, B = 1 → A < B
        A = 0; B = 1; #10;
        $display("%b %b |  %b   %b   %b", A, B, o1, o2, o3);

        // Test Case 3: A = 1, B = 0 → A > B
        A = 1; B = 0; #10;
        $display("%b %b |  %b   %b   %b", A, B, o1, o2, o3);

        // Test Case 4: A = 1, B = 1 → A == B
        A = 1; B = 1; #10;
        $display("%b %b |  %b   %b   %b", A, B, o1, o2, o3);

        $finish;                           // End simulation
    end
endmodule
