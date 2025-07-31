// 1-bit comparator
module comparator (
    input wire A,    // Input A
    input wire B,    // Input B
    output wire o1,  // A > B
    output wire o2,  // A == B
    output wire o3   // A < B
);

    assign o1 = A & ~B;    // A > B
    assign o2 = ~(A ^ B);  // A == B (XNOR)
    assign o3 = ~A & B;    // A < B

endmodule
