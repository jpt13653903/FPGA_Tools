module Audio_Player(
  input Reset,
  input Clk,
  input Sound_Clk,
  input Sound_Clk_Ena,

  input       Data_Clk,
  input [15:0]Audio[5:0],

  input  [3:0]Channel,
  input  [9:0]Volume,

  output reg[15:0]DemuxSound,

  output [1:0]PWM,
  output [9:0]Level
);
//------------------------------------------------------------------------------

reg tReset;

reg [1:0]pData_Clk;

always @(posedge Sound_Clk) begin
  tReset <= Reset;

  if(tReset) begin
    pData_Clk  <= 0;
    DemuxSound <= 0;
 
  end else begin
    pData_Clk <= {pData_Clk[0], Data_Clk};

    if(^pData_Clk) begin
      case(Channel)
        4'd0   : DemuxSound <= Audio[0];
        4'd1   : DemuxSound <= Audio[1];
        4'd2   : DemuxSound <= Audio[2];
        4'd3   : DemuxSound <= Audio[3];
        4'd4   : DemuxSound <= Audio[4];
        4'd5   : DemuxSound <= Audio[5];
        default: DemuxSound <= 0;
      endcase
    end  
  end
end
//------------------------------------------------------------------------------

wire [15:0]SoundAbsolute = DemuxSound[15] ? 
                          ~DemuxSound[15:0] + 1'b1 :
                           DemuxSound[15:0] ;

wire [25:0]SoundScaled = SoundAbsolute * Volume;

wire [23:0]SoundOut = DemuxSound [15  ] ?
                     ~SoundScaled[25:2] + 1'b1 :
                      SoundScaled[25:2] ;

wire Sound;
//------------------------------------------------------------------------------

PWM #(24, 8, 4) PWM1(
  Reset,
  Clk,
  Sound_Clk,
  Sound_Clk_Ena,

  {~SoundOut[23], SoundOut[22:0]},
  Sound
);

assign PWM = {2{Sound & (~Reset)}};
//------------------------------------------------------------------------------

always @(posedge Sound_Clk) begin
  Level[0] <= SoundAbsolute > 16'd_20_675; // -4 dB
  Level[1] <= SoundAbsolute > 16'd_13_045;
  Level[2] <= SoundAbsolute > 16'd__8_231;
  Level[3] <= SoundAbsolute > 16'd__5_193;
  Level[4] <= SoundAbsolute > 16'd__3_277;
  Level[5] <= SoundAbsolute > 16'd__2_068;
  Level[6] <= SoundAbsolute > 16'd__1_305;
  Level[7] <= SoundAbsolute > 16'd____823;
  Level[8] <= SoundAbsolute > 16'd____519;
  Level[9] <= SoundAbsolute > 16'd____328; // -40 dB
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

