// Testbench for 4-bit Equality Comparator
`timescale 1ns/1ps

module tb_equality_comparator;

    reg [3:0] A, B;        // Test inputs
    wire equal;            // Output from DUT

    // Instantiate the comparator
    equality_comparator uut (
        .A(A),
        .B(B),
        .equal(equal)
    );

    initial begin
        $display("Time\tA\tB\tEqual");
        $monitor("%g\t%b\t%b\t%b", $time, A, B, equal);

        A = 4'b0000; B = 4'b0000; #10;
        A = 4'b1010; B = 4'b1010; #10;
        A = 4'b1100; B = 4'b1111; #10;
        A = 4'b1111; B = 4'b1111; #10;
        A = 4'b0011; B = 4'b0110; #10;
        $finish;
    end

    initial begin
        $dumpfile("equality_comparator.vcd");
        $dumpvars(0, tb_equality_comparator);
    end

endmodule
