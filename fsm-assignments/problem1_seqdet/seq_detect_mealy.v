// Mealy overlapping sequence detector: pattern 1101
module seq_detect_mealy(
  input  wire clk,
  input  wire rst,  // sync, active-high
  input  wire din,  // serial bit (sampled each clk)
  output reg  y     // 1-cycle pulse on 1101
);
  typedef enum logic [1:0] {S0, S1, S2, S3} state_t;
  state_t s, ns;

  always @(posedge clk) begin
    if (rst) s <= S0; else s <= ns;
  end

  always @* begin
    y  = 1'b0;
    ns = s;
    unique case (s)
      S0: ns = din ? S1 : S0;          // seen ""
      S1: ns = din ? S2 : S0;          // seen "1"
      S2: ns = din ? S2 : S3;          // seen "11"
      S3: begin                        // seen "110"
        if (din) begin                 // ... + '1' => 1101
          y  = 1'b1;
          ns = S1;                     // overlap suffix "1"
        end else ns = S0;
      end
    endcase
  end
endmodule

