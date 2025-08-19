// Vending machine (Mealy): price=20, coins=5/10
module vending_mealy(
  input  wire       clk,
  input  wire       rst,     // sync, active-high
  input  wire [1:0] coin,    // 01=5, 10=10, 00=idle
  output reg        dispense,// 1-cycle pulse
  output reg        chg5     // 1-cycle pulse when 25 paid
);
  typedef enum logic [1:0] {S0, S5, S10, S15} state_t;
  state_t s, ns;

  wire [4:0] val = (coin==2'b01)?5 : (coin==2'b10)?10 : 0;

  always @(posedge clk) begin
    if (rst) s <= S0; else s <= ns;
  end

  always @* begin
    dispense=1'b0; chg5=1'b0; ns=s;
    case (s)
      S0:  if (val==5) ns=S5; else if (val==10) ns=S10;
      S5:  if (val==5) ns=S10; else if (val==10) ns=S15;
      S10: if (val==5) ns=S15;
           else if (val==10) begin dispense=1; ns=S0; end // 10+10
      S15: if (val==5) begin dispense=1;        ns=S0; end // 15+5
           else if (val==10) begin dispense=1; chg5=1; ns=S0; end // 15+10
    endcase
    // Ignore 00/11 => stay put
  end
endmodule

