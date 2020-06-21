module FIR_Multiply(
  input Clk,

  input [15:0]A,
  input [17:0]B,

  output reg [33:0]Y // 4-clock latency
);
//------------------------------------------------------------------------------

reg [15:0]tA;
reg [17:0]tB;

reg [ 1:0]Sign;
reg [15:0]Abs_A;
reg [17:0]Abs_B;
reg [33:0]Abs_Y;

always @(posedge Clk) begin
  tA <= A;
  tB <= B;

  Abs_A   <= tA[15] ? ~tA + 1'b1 : tA;
  Abs_B   <= tB[17] ? ~tB + 1'b1 : tB;
  Sign[0] <= tA[15] ^  tB[17];

  Sign[1] <= Sign[0];
  Abs_Y   <= Abs_A * Abs_B;
 
  Y <= (Sign[1]) ? ~Abs_Y + 1'b1 : Abs_Y;
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

