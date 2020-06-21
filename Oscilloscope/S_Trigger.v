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

module S_Trigger(
  input  nReset,
  input  Clk, // 45 MHz

  input  [15:0]Input,
  output       Output,

  input [15:0]Level,
  input [15:0]Hyst,
  input       Slope); // 1 = Positive  , 0 = Negative

  reg  tOutput;

  wire [17:0]x2;
  wire [17:0]x3;
  wire [18:0]x4;
  wire [17:0]x5;
  wire [17:0]x6;
  wire [17:0]x7;
  wire [17:0]x8;
  wire [17:0]x9;
  wire [17:0]x10;

  wire Top;
  wire Bottom;

  assign x2 = {Input[15], Input[15], Input};
  assign x3 = {Level[15], Level[15], Level};

  assign x4 = {3'b000, Hyst};

  assign x5 = x3 + x4[18:1] + x4[0];

  assign x6 = -x5;

  assign x7 = x3 - x4[18:1];

  assign x8 = -x7;

  assign x9 = x2 + x6;

  assign x10 = x2 + x8;

  assign Top = x9[17];

  assign Bottom = x10[17];

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      tOutput <= 1'b1;
    end else begin
      if(tOutput) begin
        tOutput <= Top;
      end else begin
        tOutput <= Bottom;
      end
    end
  end

  assign Output = tOutput ^ Slope;
endmodule
