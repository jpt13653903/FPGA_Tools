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

module DDS_Triangle(
 input  nReset,
 input  Clk, // 43.945 kHz
 input  [17:0]Phase,
 input  [17:0]Skew0,
 input  [17:0]Skew1,
 input  [17:0]Skew2,
 output [18:0]Output);

 reg  [17:0]x;
 wire [17:0]x1;
 wire [17:0]x2;

 wire [17:0]s3;

 wire part;

 wire [35:0]y1;
 wire [27:0]y2;

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   x <= 0;
  end else begin
   x <= Phase;
  end
 end

 assign x1 = -x;

 assign part = x > Skew0;

 assign x2 = (part == 1'b0) ? x : x1;

 assign s3 = (part == 1'b0) ? Skew1 : Skew2;

 assign y1 = x2 * s3;

 assign y2 = y1[35:8] + y1[7];

 assign Output = (~|y2[27:19]) ? y2[18:0] : {19{1'b1}};
endmodule
