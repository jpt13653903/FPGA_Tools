module Timer0(
  input nReset,
  input Clk,
  input Sync,

  input [8:0]Address,
  input [7:0]Data,
  input      Latch,

  input      T0CKI,

  output reg [7:0]TMR0,
 
  output reg      T0IE,
  output reg      T0IF,

  output reg      T0CS,
  output reg      T0SE,
  output reg      PSA,
  output reg [2:0]PS 
);
//------------------------------------------------------------------------------

reg       PrevTMR0;
wire      ClkIn;
reg       PrevClkIn;
wire      ClkSelect;
reg       PrevClkSelect;
reg  [7:0]Prescaler;
reg       PrescalerOut;

assign ClkSelect = T0CS ? T0CKI ^ T0SE : Sync;
assign ClkIn     = PSA  ? ClkSelect    : PrescalerOut;

always @(*) begin
  case(PS)
    3'h0: PrescalerOut <= Prescaler[0];
    3'h1: PrescalerOut <= Prescaler[1]; 
    3'h2: PrescalerOut <= Prescaler[2];
    3'h3: PrescalerOut <= Prescaler[3];
    3'h4: PrescalerOut <= Prescaler[4];
    3'h5: PrescalerOut <= Prescaler[5];
    3'h6: PrescalerOut <= Prescaler[6];
    3'h7: PrescalerOut <= Prescaler[7];
    default:;
  endcase
end
//------------------------------------------------------------------------------

always @(posedge Clk) begin
  if(!nReset) begin
    TMR0 <= 0;
    T0IE <= 0;
    T0IF <= 0;
    T0CS <= 1'b1;
    T0SE <= 1'b1;
    PSA  <= 1'b1;
    PS   <= 3'b111;

    PrevTMR0      <= 0;
    PrevClkIn     <= 0;
    PrevClkSelect <= 0;
    Prescaler     <= 0;
//------------------------------------------------------------------------------

  end else begin
    if(~PrevClkSelect & ClkSelect) begin
      Prescaler <= Prescaler + 1'b1;
    end
    PrevClkSelect <= ClkSelect;

    if(Latch && Address[7:0] == 8'h01) begin
      TMR0 <= Data;
    end else begin
      if(~PrevClkIn & ClkIn) begin
        TMR0 <= TMR0 + 1'b1;
      end
      PrevClkIn <= ClkIn;
    end

    if(Latch && Address[7:0] == 8'h81) begin
      T0CS <= Data[5];
      T0SE <= Data[4];
      PSA  <= Data[3];
      PS   <= Data[2:0];
    end

    if(Latch && Address[6:0] == 7'h0B) begin
      T0IE <= Data[5];
      T0IF <= Data[2];
    end else begin
      if(PrevTMR0 && ~|TMR0) T0IF <= 1'b1;
      PrevTMR0 <= &TMR0;
    end
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

