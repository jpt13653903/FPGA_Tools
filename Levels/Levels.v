//==============================================================================
// Copyright (C) John-Philip Taylor
// jpt13653903@gmail.com
//
// This file is part of a library
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

module Levels(
  input nReset,
  input Clk, // 390.625 kHz
  
  input [47:0]Input,
  
  output reg      Clip,
  output reg [3:0]Level);
//------------------------------------------------------------------------------

  parameter Level0 = 24'h0C_CC_CD; // -20   dB
  parameter Level1 = 24'h16_C3_11; // -15   dB
  parameter Level2 = 24'h28_7A_26; // -10   dB
  parameter Level3 = 24'h47_FA_CC; // - 5   dB
  parameter ClipTh = 24'h7D_16_1C; // - 0.2 dB
 
  parameter ClipLength = 19'd_390_625; // 1 Second
//------------------------------------------------------------------------------

  reg [18:0]ClipCount;
  reg [23:0]AbsData[1:0];
//------------------------------------------------------------------------------

  always @* begin
    if(Input[23]) AbsData[0] <= -Input[23: 0];
    else          AbsData[0] <=  Input[23: 0];
  
    if(Input[47]) AbsData[1] <= -Input[47:24];
    else          AbsData[1] <=  Input[47:24];
  end
//------------------------------------------------------------------------------

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      Clip      <= 0;
      Level     <= 0;
      ClipCount <= 0;
//------------------------------------------------------------------------------
  
    end else begin
      if((AbsData[0] > Level0) ||
         (AbsData[1] > Level0)) begin
        Level[0] <= 1'b1;
      end else begin
        Level[0] <= 1'b0;
      end
//------------------------------------------------------------------------------

      if((AbsData[0] > Level1) ||
         (AbsData[1] > Level1)) begin
        Level[1] <= 1'b1;
      end else begin
        Level[1] <= 1'b0;
      end
//------------------------------------------------------------------------------

      if((AbsData[0] > Level2) ||
         (AbsData[1] > Level2)) begin
        Level[2] <= 1'b1;
      end else begin
        Level[2] <= 1'b0;
      end
//------------------------------------------------------------------------------

      if((AbsData[0] > Level3) ||
         (AbsData[1] > Level3)) begin
        Level[3] <= 1'b1;
      end else begin
        Level[3] <= 1'b0;
      end
//------------------------------------------------------------------------------

      if((AbsData[0] >= ClipTh) ||
         (AbsData[1] >= ClipTh)) begin
        ClipCount <= ClipLength;
        Clip      <= 1'b1;
      end else begin
        if(~|ClipCount) begin
          Clip <= 1'b0;
        end else begin
          ClipCount <= ClipCount - 1'b1;
        end
      end
    end
  end
endmodule
//------------------------------------------------------------------------------
