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

module SPDIF_Encoder(
  input Reset,
  input Clk,

  input [95:0]Sound, // 6x 16-bit channels
  input [ 7:0]Text,
 
  output reg SPDIF
);
//------------------------------------------------------------------------------

reg   [1:0]State;
localparam Start    = 2'b00;
localparam SendHead = 2'b01;
localparam SendBody = 2'b11;

reg [5:0]Count;

reg [6:0]Head_Buffer;

reg [95:0]Sound_Buffer;
reg [ 7:0]Text_Buffer;

reg [ 8:0]Frame_Count; // Counts frames
reg [27:0]Frame_Buffer;
//------------------------------------------------------------------------------

reg tReset;

always @(posedge Clk) begin
  tReset <= Reset;

  if(tReset) begin
    Count       <= 0;
    Head_Buffer <= 0;

    Sound_Buffer <= 0;
    Text_Buffer  <= 0;

    Frame_Count  <= 0;
    Frame_Buffer <= 0;

    SPDIF <= 0;
    State <= Start;

  end else begin
    case(State)
      Start: begin
        if(~|Frame_Count) begin
          if(SPDIF) {Head_Buffer, SPDIF} <= 8'b11101000;
          else      {Head_Buffer, SPDIF} <= 8'b00010111;

        end else if(Frame_Count[0]) begin
          if(SPDIF) {Head_Buffer, SPDIF} <= 8'b11011000;
          else      {Head_Buffer, SPDIF} <= 8'b00100111;

        end else begin
          if(SPDIF) {Head_Buffer, SPDIF} <= 8'b10111000;
          else      {Head_Buffer, SPDIF} <= 8'b01000111;
        end
        Count[2:0] <= 3'd6;

        if(~|Frame_Count[1:0]) Sound_Buffer <= Sound;
        if(~|Frame_Count[2:0]) Text_Buffer  <= Text;

        if(Frame_Count == 9'd383) Frame_Count <= 0;
        else                      Frame_Count <= Frame_Count + 1'b1;

        State <= SendHead;
      end
//------------------------------------------------------------------------------

      SendHead: begin
        {Head_Buffer[5:0], SPDIF} <= Head_Buffer;

        if(~|Count[2:0]) begin
          Frame_Buffer <= {
            ^{Text_Buffer[0], Sound_Buffer[23:0]}, // Even parity
            1'b0,              // Status Information
            Text_Buffer[0],    // Subcode data
            1'b0,              // Validity
            Sound_Buffer[23:0] // 24-bit sample
          };
          Sound_Buffer[71:0] <= Sound_Buffer[95:24];
          Text_Buffer [ 6:0] <= Text_Buffer [ 7: 1];
     
          Count <= 6'd55;
          State <= SendBody;

        end else begin 
          Count[2:0] <= Count[2:0] - 1'b1;
        end
      end
//------------------------------------------------------------------------------

      SendBody: begin
        if(Count[0]) begin
          SPDIF <= ~SPDIF;
        end else begin
          if(Frame_Buffer[0]) SPDIF <= ~SPDIF;
          Frame_Buffer[26:0] <= Frame_Buffer[27:1];
        end

        if(~|Count) State <= Start;

        Count <= Count - 1'b1;
      end
//------------------------------------------------------------------------------

      default:;
    endcase
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

