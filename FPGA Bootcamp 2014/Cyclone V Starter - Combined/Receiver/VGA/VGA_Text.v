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

module VGA_Text(
  input Reset,
  input Clk,       // The interface clock
  input Pixel_Clk, // The pixel clock (25.152 MHz for 640 x 480 x 60 Hz)

  input [ 4:0]Line,
  input [ 6:0]Character,
  input [ 7:0]Glyph,      // Glyph index
  input [11:0]Foreground, // RGB, 4-bit each
  input [11:0]Background, // RGB, 4-bit each
  input       Latch,

  output reg [3:0]Red,
  output reg [3:0]Green,
  output reg [3:0]Blue,
  output reg      HSync,
  output reg      VSync
);
//------------------------------------------------------------------------------

wire [ 4:0]Text_Line;
wire [ 6:0]Text_Character;
wire [ 7:0]Text_Glyph;
wire [11:0]Text_Foreground;
wire [11:0]Text_Background;

assign Text_Line      = VCounter[8:4];
assign Text_Character = HCounter[9:3];

VGA_Text_Buffer Text_Buffer(
  .wrclock  ( Clk),
  .wraddress({Line, Character}),
  .data     ({Background, Foreground, Glyph}),
  .wren     ( Latch),

  .rdclock  ( Pixel_Clk),
  .rdaddress({Text_Line, Text_Character}),
  .q        ({Text_Background, Text_Foreground, Text_Glyph})
);

reg [11:0]tText_Foreground;
reg [11:0]tText_Background;

always @(posedge Pixel_Clk) begin
  tText_Foreground <= Text_Foreground;
  tText_Background <= Text_Background;
end
//------------------------------------------------------------------------------

wire [3:0]Glyph_Row_Index;
wire [2:0]Glyph_Column_Index;

assign Glyph_Row_Index    = VCounter[3:0];
assign Glyph_Column_Index = HCounter[2:0];

wire [7:0]Glyph_Row;

VGA_Font Font(
  .clock  ( Pixel_Clk),
  .address({Text_Glyph, Glyph_Row_Index}),
  .q      ( Glyph_Row)
);

reg Glyph_Pixel;

always @(*) begin
  case(Glyph_Column_Index)
    3'd2: Glyph_Pixel <= Glyph_Row[7];
    3'd3: Glyph_Pixel <= Glyph_Row[6];
    3'd4: Glyph_Pixel <= Glyph_Row[5];
    3'd5: Glyph_Pixel <= Glyph_Row[4];
    3'd6: Glyph_Pixel <= Glyph_Row[3];
    3'd7: Glyph_Pixel <= Glyph_Row[2];
    3'd0: Glyph_Pixel <= Glyph_Row[1];
    3'd1: Glyph_Pixel <= Glyph_Row[0];
    default:;
  endcase
end
//------------------------------------------------------------------------------

reg [9:0]HCounter;
reg [9:0]VCounter;
//------------------------------------------------------------------------------

reg tReset;

always @(posedge Pixel_Clk) begin
  tReset <= Reset;

  if(tReset) begin
    HCounter <= 0;
    VCounter <= 0;

    HSync <= 1'b1;
    VSync <= 1'b1;

    Red   <= 0;
    Green <= 0;
    Blue  <= 0;
//------------------------------------------------------------------------------

  end else begin
    if(HCounter == 10'd799) begin
      HCounter <= 0;

      if(VCounter == 10'd524) VCounter <= 0;
      else                    VCounter <= VCounter + 1'b1;

    end else begin
      HCounter <= HCounter + 1'b1;
    end
//------------------------------------------------------------------------------

    // Added 2 due to RAM latency
    if     (HCounter == 10'd657) HSync <= 1'b0;
    else if(HCounter == 10'd753) HSync <= 1'b1;

    if     (VCounter == 10'd489) VSync <= 1'b0;
    else if(VCounter == 10'd491) VSync <= 1'b1;

    if((HCounter > 10'd001) && (HCounter < 10'd642) && (VCounter < 10'd480)) begin
      if(Glyph_Pixel) begin
        Red   <= tText_Foreground[11:8];
        Green <= tText_Foreground[ 7:4];
        Blue  <= tText_Foreground[ 3:0];
      end else begin
        Red   <= tText_Background[11:8];
        Green <= tText_Background[ 7:4];
        Blue  <= tText_Background[ 3:0];
      end
    end else begin
      Red   <= 0;
      Green <= 0;
      Blue  <= 0;
    end
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

