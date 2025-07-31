// 4-bit Equality Comparator
module equality_comparator (
    input [3:0] A,    // 4-bit input A
    input [3:0] B,    // 4-bit input B
    output equal      // Output is 1 if A == B
);
    assign equal = (A == B);
endmodule
