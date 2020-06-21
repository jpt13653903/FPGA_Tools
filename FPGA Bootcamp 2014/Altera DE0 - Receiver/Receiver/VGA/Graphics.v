//==============================================================================
// Copyright (C) John-Philip Taylor
// jpt13653903@gmail.com
//
// This file is part of S/PDIF Radio
//
// This file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>
//==============================================================================

module Graphics(
  input Reset,
  input Clk,
  input FIR_Clk,
  input VGA_Clk,

  input  [ 3:0]Channel,
  input        Sound_Clk,
  input  [ 7:0]Text_Stream,
  input  [15:0]Sound,

  output [3:0]Red,
  output [3:0]Green,
  output [3:0]Blue,
  output      HSync,
  output      VSync
);
//------------------------------------------------------------------------------

reg [ 4:0]Line;
reg [ 6:0]Character;
reg [ 7:0]Glyph;
reg [11:0]Foreground;
reg [11:0]Background;
reg       Latch;

VGA_Text VGA(
  Reset,
  Clk,
  VGA_Clk,

  Line,
  Character,
  Glyph,
  Foreground,
  Background,
  Latch,

  Red,
  Green,
  Blue,
  HSync,
  VSync
);
//------------------------------------------------------------------------------

reg [15:0]tSound;
always @(posedge Clk) tSound <= Sound;
wire [15:0]SoundAbsolute = tSound[15] ? ~tSound + 1'b1 : tSound;

wire [3:0] SoundLevel[19:0];
reg  [3:0]lSoundLevel[19:0];

reg [8:0]Level_Sync_Count; // 43 fps on 22.050 kHz clock
wire     Level_Sync = &Level_Sync_Count;

always @(posedge Clk) begin
  if(Sound_Sync) Level_Sync_Count <= Level_Sync_Count + 1'b1;
end

LevelFilter #(16'd_26_029) Filter19(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[19]);
LevelFilter #(16'd_20_675) Filter18(Reset, Clk, Sound_Sync, Level_Sync,
                                    SoundAbsolute, SoundLevel[18]);
LevelFilter #(16'd_16_423) Filter17(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[17]);
LevelFilter #(16'd_13_045) Filter16(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[16]);
LevelFilter #(16'd_10_362) Filter15(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[15]);
LevelFilter #(16'd__8_231) Filter14(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[14]);
LevelFilter #(16'd__6_538) Filter13(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[13]);
LevelFilter #(16'd__5_193) Filter12(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[12]);
LevelFilter #(16'd__4_125) Filter11(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[11]);
LevelFilter #(16'd__3_277) Filter10(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[10]);
LevelFilter #(16'd__2_603) Filter09(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[ 9]);
LevelFilter #(16'd__2_068) Filter08(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[ 8]);
LevelFilter #(16'd__1_642) Filter07(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[ 7]);
LevelFilter #(16'd__1_305) Filter06(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[ 6]);
LevelFilter #(16'd__1_036) Filter05(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[ 5]);
LevelFilter #(16'd____823) Filter04(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[ 4]);
LevelFilter #(16'd____654) Filter03(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[ 3]);
LevelFilter #(16'd____519) Filter02(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[ 2]);
LevelFilter #(16'd____413) Filter01(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[ 1]);
LevelFilter #(16'd____328) Filter00(Reset, Clk, Sound_Sync, Level_Sync, 
                                    SoundAbsolute, SoundLevel[ 0]);
//------------------------------------------------------------------------------

reg       SpectrumType;
reg  [6:0]SpectrumOffset;

wire [3:0] Spectrum[7:0][4:0];
reg  [3:0]lSpectrum[7:0][4:0];

SpectrumFilter #(
  24'd______2_594, 25'd__________0, 25'd__________0,
  26'd_33_260_436, 27'd_16_485_752, 26'd__________0, 24'd__________0
) SpectrumFilter0(
  Reset, Clk, Sound_Sync, Level_Sync, tSound, Spectrum[0]
);

SpectrumFilter #(
  24'd_____16_307, 25'd_____32_614, 25'd_____16_307,
  26'd_66_175_906, 27'd_97_889_879, 26'd_64_360_603, 24'd_15_869_415
) SpectrumFilter1(
  Reset, Clk, Sound_Sync, Level_Sync, tSound, Spectrum[1]
);

SpectrumFilter #(
  24'd_____64_948, 25'd____129_895, 25'd_____64_948,
  26'd_65_083_865, 27'd_94_705_855, 26'd_61_265_990, 24'd_14_866_821
) SpectrumFilter2(
  Reset, Clk, Sound_Sync, Level_Sync, tSound, Spectrum[2]
);

SpectrumFilter #(
  24'd____279_826, 25'd____559_653, 25'd____279_826,
  26'd_62_740_288, 27'd_88_084_724, 26'd_55_029_207, 24'd_12_908_274
) SpectrumFilter3(
  Reset, Clk, Sound_Sync, Level_Sync, tSound, Spectrum[3]
);

SpectrumFilter #(
  24'd__1_084_432, 25'd__2_168_865, 25'd__1_084_432,
  26'd_57_895_153, 27'd_75_234_828, 26'd_43_652_540, 24'd__9_547_556
) SpectrumFilter4(
  Reset, Clk, Sound_Sync, Level_Sync, tSound, Spectrum[4]
);

SpectrumFilter #(
  24'd__3_384_047, 25'd__6_768_092, 25'd__3_384_047,
  26'd_48_923_670, 27'd_54_174_772, 26'd_27_040_987, 24'd__5_156_457
) SpectrumFilter5(
  Reset, Clk, Sound_Sync, Level_Sync, tSound, Spectrum[5]
);

SpectrumFilter #(
  24'd__7_237_093, 25'd_14_474_186, 25'd__7_237_093,
  26'd_35_745_136, 27'd_29_455_285, 26'd_11_111_198, 24'd__1_657_059
) SpectrumFilter6(
  Reset, Clk, Sound_Sync, Level_Sync, tSound, Spectrum[6]
);

SpectrumFilter #(
  24'd__8_648_219, 25'd_17_296_437, 25'd__8_648_219,
  26'd_14_144_725, 27'd__3_670_933, 26'd__________0, 24'd__________0
) SpectrumFilter7(
  Reset, Clk, Sound_Sync, Level_Sync, tSound, Spectrum[7]
);
//------------------------------------------------------------------------------

wire [3:0]FIR_Spectrum[7:0][4:0];

genvar x, y;
generate
  for(x = 0; x < 8; x++) begin: G1
    for(y = 0; y < 5; y++) begin: G2
      assign FIR_Spectrum[x][y] = 0;
    end
  end
endgenerate
//FIR_Filters FIR_Filters1(
// Reset,
// Clk,
// FIR_Clk,
// Sound_Clk,
//
// Sound,
//
// Sound_Sync,
// Level_Sync,
// FIR_Spectrum
//);
//------------------------------------------------------------------------------

reg   [3:0]State;
reg   [3:0]RetState;
localparam Init            = 4'h0;
localparam Headers         = 4'h1;
localparam Sync            = 4'h2;
localparam WriteArtist     = 4'h3;
localparam WriteTitle      = 4'h4;
localparam ClearLine       = 4'h5;
localparam LatchSoundLevel = 4'h6;
localparam WriteSoundLevel = 4'h7;
localparam LatchSpectrum   = 4'h8;
localparam LatchFIR        = 4'h9;
localparam WriteSpectrum   = 4'hA;
//------------------------------------------------------------------------------

reg [3:0]tChannel;
reg      tSound_Clk;
reg       Sound_Sync;

integer i, j;
//------------------------------------------------------------------------------

reg tReset;

always @(posedge Clk) begin
  tReset     <= Reset;
  tSound_Clk <= Sound_Clk;
  Sound_Sync <= Sound_Clk ^ tSound_Clk;

  if(tReset) begin
    Line       <= 0;
    Character  <= 0;
    Glyph      <= 0;
    Foreground <= 0;
    Background <= 12'hCCC;
    Latch      <= 1'b1;

    State     <= Init;
    RetState  <= 0;
    tChannel  <= 0;
    tSound_Clk <= 0;

    SpectrumType   <= 0;
    SpectrumOffset <= 0;

    for(i = 0; i < 20; i++) lSoundLevel[i] <= 0;
//------------------------------------------------------------------------------

  end else begin
    case(State)
      Init: begin
        tChannel <= Channel;

        if(Character == 7'd79) begin
          if(Line == 5'd29) begin
            Line  <= 0;
            State <= Headers;
          end else begin
            Line <= Line + 1'b1;
          end
          Character <= 0;

        end else begin
          Character <= Character + 1'b1;
        end
      end
//------------------------------------------------------------------------------

      Headers: begin
        if(Character == 7'd10) begin
          if(Line == 5'd23) begin
            Line      <= 0;
            tSound_Clk <= Sound_Clk;
            State     <= Sync;
          end else begin
            Line <= Line + 1'b1;
          end
          Character <= 0;

        end else begin
          Character <= Character + 1'b1;
        end

        if(Line[4:2] == tChannel[2:0]) Foreground <= 12'h0E0;
        else                           Foreground <= 12'h00F;

        case(Line)
          5'd_1,
          5'd_5,
          5'd_9,
          5'd13,
          5'd17,
          5'd21: begin
            case(Character)
              7'd_0  : Glyph <= "C";
              7'd_1  : Glyph <= "h";
              7'd_2  : Glyph <= "a";
              7'd_3  : Glyph <= "n";
              7'd_4  : Glyph <= "n";
              7'd_5  : Glyph <= "e";
              7'd_6  : Glyph <= "l";
              7'd_8  : Glyph <= Line[4:2] + "1";
              7'd_9  : Glyph <= ":";
              default: Glyph <=  0 ;
            endcase
          end
     
          5'd_2,
          5'd_6,
          5'd10,
          5'd14,
          5'd18,
          5'd22: begin
            case(Character)
              7'd_1  : Glyph <= "A";
              7'd_2  : Glyph <= "r";
              7'd_3  : Glyph <= "t";
              7'd_4  : Glyph <= "i";
              7'd_5  : Glyph <= "s";
              7'd_6  : Glyph <= "t";
              7'd_7  : Glyph <= ":";
              default: Glyph <=  0 ;
            endcase
          end
     
          5'd_3,
          5'd_7,
          5'd11,
          5'd15,
          5'd19,
          5'd23: begin
            case(Character)
              7'd_1  : Glyph <= "T";
              7'd_2  : Glyph <= "i";
              7'd_3  : Glyph <= "t";
              7'd_4  : Glyph <= "l";
              7'd_5  : Glyph <= "e";
              7'd_6  : Glyph <= ":";
              default: Glyph <=  0 ;
            endcase
          end

          default: Glyph <= 0;
        endcase
      end
//------------------------------------------------------------------------------

      Sync: begin
        Line      <= 0;
        Glyph     <= 0;
        Character <= 0;

        if(tChannel != Channel) begin
          tChannel <= Channel;
          State    <= Headers;
        end

        if(tSound_Clk & ~Sound_Clk) begin
          if(|Text_Stream && Text_Stream <= 8'd6) begin
            Line       <= {Text_Stream[2:0] - 1'b1, 2'd2};
            Character  <= 7'd9;
            State      <= WriteArtist;
            if(Text_Stream[3:0] - 1'b1 == tChannel) Foreground <= 12'hF00;
            else                                    Foreground <= 12'h00F;
          end
        end
      end
//------------------------------------------------------------------------------

      WriteArtist: begin
        if(tSound_Clk & ~Sound_Clk) begin
          if(|Text_Stream) begin
            Glyph <= Text_Stream;
          end else begin
            Glyph    <= 0;
            State    <= ClearLine;
            RetState <= WriteTitle;
          end
          Character <= Character + 1'b1;
        end
      end
//------------------------------------------------------------------------------

      WriteTitle: begin
        if(tSound_Clk & ~Sound_Clk) begin
          if(|Text_Stream) begin
            Glyph <= Text_Stream;
          end else begin
            Glyph    <= 0;
            State    <= ClearLine;
            RetState <= LatchSoundLevel;
          end
          Character <= Character + 1'b1;
        end
      end
//------------------------------------------------------------------------------

      ClearLine: begin
        if(Character == 7'd77) begin
          Line      <= Line + 1'b1;
          Character <= 7'd9;
          State     <= RetState;
        end else begin
          Character <= Character + 1'b1;
        end
      end
//------------------------------------------------------------------------------

      LatchSoundLevel: begin
        for(i = 0; i < 20; i++) lSoundLevel[i] <= SoundLevel[i];
        Line      <= 5'd24;
        Character <= 7'd78;
        State     <= WriteSoundLevel;
      end
//------------------------------------------------------------------------------

      WriteSoundLevel: begin
        Glyph <= 8'hDB;

        case(Line)
          5'd24: Foreground <= {4'h0, lSoundLevel[ 0]  , 4'h0};
          5'd23: Foreground <= {4'h0, lSoundLevel[ 1]  , 4'h0};
          5'd22: Foreground <= {4'h0, lSoundLevel[ 2]  , 4'h0};
          5'd21: Foreground <= {4'h0, lSoundLevel[ 3]  , 4'h0};
          5'd20: Foreground <= {4'h0, lSoundLevel[ 4]  , 4'h0};
          5'd19: Foreground <= {4'h0, lSoundLevel[ 5]  , 4'h0};
          5'd18: Foreground <= {4'h0, lSoundLevel[ 6]  , 4'h0};
          5'd17: Foreground <= {4'h0, lSoundLevel[ 7]  , 4'h0};
          5'd16: Foreground <= {4'h0, lSoundLevel[ 8]  , 4'h0};
          5'd15: Foreground <= {4'h0, lSoundLevel[ 9]  , 4'h0};
          5'd14: Foreground <= {4'h0, lSoundLevel[10]  , 4'h0};
          5'd13: Foreground <= {4'h0, lSoundLevel[11]  , 4'h0};
          5'd12: Foreground <= {4'h0, lSoundLevel[12]  , 4'h0};
          5'd11: Foreground <= {{2{   lSoundLevel[13]}}, 4'h0};
          5'd10: Foreground <= {{2{   lSoundLevel[14]}}, 4'h0};
          5'd_9: Foreground <= {{2{   lSoundLevel[15]}}, 4'h0};
          5'd_8: Foreground <= {{2{   lSoundLevel[16]}}, 4'h0};
          5'd_7: Foreground <= {{2{   lSoundLevel[17]}}, 4'h0};
          5'd_6: Foreground <= {      lSoundLevel[18]  , 8'h0};
          5'd_5: Foreground <= {      lSoundLevel[19]  , 8'h0};
          default:;
        endcase

        if(Line == 5'd5) begin
          // Doing both takes too long, so have to do one at a time...
          if(SpectrumType) State <= LatchSpectrum;
          else             State <= LatchFIR;
          SpectrumType <= ~SpectrumType;
        end

        Line <= Line - 1'b1;
      end
//------------------------------------------------------------------------------

      LatchSpectrum: begin
        for(i = 0; i < 8; i++) begin
          for(j = 0; j < 5; j++) begin
            lSpectrum[i][j] <= Spectrum[i][j];
          end
        end
        Line           <= 5'd29;
        Glyph          <= 0;
        Character      <= 7'd10;
        SpectrumOffset <= 7'd10;
        State          <= WriteSpectrum;
      end
//------------------------------------------------------------------------------

      LatchFIR: begin
        for(i = 0; i < 8; i++) begin
          for(j = 0; j < 5; j++) begin
            lSpectrum[i][j] <= FIR_Spectrum[i][j];
          end
        end
        Line           <= 5'd29;
        Glyph          <= 0;
        Character      <= 7'd50;
        SpectrumOffset <= 7'd50;
        State          <= WriteSpectrum;
      end
//------------------------------------------------------------------------------

      WriteSpectrum: begin
        Glyph <= 8'hDB;

        if(Line == 5'd29) begin
          Line      <= 5'd25;
          Character <= Character + 2'd2;
        end else begin
          Line <= Line + 1'b1;
        end

        case({Line, Character - SpectrumOffset})
          {5'd29, 7'd_0}: Foreground <= {      lSpectrum[0][4]  , 8'h0};
          {5'd25, 7'd_2}: Foreground <= {{2{   lSpectrum[0][3]}}, 4'h0};
          {5'd26, 7'd_2}: Foreground <= {4'h0, lSpectrum[0][2]  , 4'h0};
          {5'd27, 7'd_2}: Foreground <= {4'h0, lSpectrum[0][1]  , 4'h0};
          {5'd28, 7'd_2}: Foreground <= {4'h0, lSpectrum[0][0]  , 4'h0};

          {5'd29, 7'd_2}: Foreground <= {      lSpectrum[1][4]  , 8'h0};
          {5'd25, 7'd_4}: Foreground <= {{2{   lSpectrum[1][3]}}, 4'h0};
          {5'd26, 7'd_4}: Foreground <= {4'h0, lSpectrum[1][2]  , 4'h0};
          {5'd27, 7'd_4}: Foreground <= {4'h0, lSpectrum[1][1]  , 4'h0};
          {5'd28, 7'd_4}: Foreground <= {4'h0, lSpectrum[1][0]  , 4'h0};

          {5'd29, 7'd_4}: Foreground <= {      lSpectrum[2][4]  , 8'h0};
          {5'd25, 7'd_6}: Foreground <= {{2{   lSpectrum[2][3]}}, 4'h0};
          {5'd26, 7'd_6}: Foreground <= {4'h0, lSpectrum[2][2]  , 4'h0};
          {5'd27, 7'd_6}: Foreground <= {4'h0, lSpectrum[2][1]  , 4'h0};
          {5'd28, 7'd_6}: Foreground <= {4'h0, lSpectrum[2][0]  , 4'h0};

          {5'd29, 7'd_6}: Foreground <= {      lSpectrum[3][4]  , 8'h0};
          {5'd25, 7'd_8}: Foreground <= {{2{   lSpectrum[3][3]}}, 4'h0};
          {5'd26, 7'd_8}: Foreground <= {4'h0, lSpectrum[3][2]  , 4'h0};
          {5'd27, 7'd_8}: Foreground <= {4'h0, lSpectrum[3][1]  , 4'h0};
          {5'd28, 7'd_8}: Foreground <= {4'h0, lSpectrum[3][0]  , 4'h0};

          {5'd29, 7'd_8}: Foreground <= {      lSpectrum[4][4]  , 8'h0};
          {5'd25, 7'd10}: Foreground <= {{2{   lSpectrum[4][3]}}, 4'h0};
          {5'd26, 7'd10}: Foreground <= {4'h0, lSpectrum[4][2]  , 4'h0};
          {5'd27, 7'd10}: Foreground <= {4'h0, lSpectrum[4][1]  , 4'h0};
          {5'd28, 7'd10}: Foreground <= {4'h0, lSpectrum[4][0]  , 4'h0};

          {5'd29, 7'd10}: Foreground <= {      lSpectrum[5][4]  , 8'h0};
          {5'd25, 7'd12}: Foreground <= {{2{   lSpectrum[5][3]}}, 4'h0};
          {5'd26, 7'd12}: Foreground <= {4'h0, lSpectrum[5][2]  , 4'h0};
          {5'd27, 7'd12}: Foreground <= {4'h0, lSpectrum[5][1]  , 4'h0};
          {5'd28, 7'd12}: Foreground <= {4'h0, lSpectrum[5][0]  , 4'h0};

          {5'd29, 7'd12}: Foreground <= {      lSpectrum[6][4]  , 8'h0};
          {5'd25, 7'd14}: Foreground <= {{2{   lSpectrum[6][3]}}, 4'h0};
          {5'd26, 7'd14}: Foreground <= {4'h0, lSpectrum[6][2]  , 4'h0};
          {5'd27, 7'd14}: Foreground <= {4'h0, lSpectrum[6][1]  , 4'h0};
          {5'd28, 7'd14}: Foreground <= {4'h0, lSpectrum[6][0]  , 4'h0};

          {5'd29, 7'd14}: Foreground <= {      lSpectrum[7][4]  , 8'h0};
          {5'd25, 7'd16}: Foreground <= {{2{   lSpectrum[7][3]}}, 4'h0};
          {5'd26, 7'd16}: Foreground <= {4'h0, lSpectrum[7][2]  , 4'h0};
          {5'd27, 7'd16}: Foreground <= {4'h0, lSpectrum[7][1]  , 4'h0};
          {5'd28, 7'd16}: Foreground <= {4'h0, lSpectrum[7][0]  , 4'h0};

          default:;
        endcase

        if((Line == 5'd28) && ((Character - SpectrumOffset) == 7'd16)) begin
          State <= Sync;
        end
      end
//------------------------------------------------------------------------------

      default:;
    endcase
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

