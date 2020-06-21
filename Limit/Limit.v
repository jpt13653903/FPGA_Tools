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

module Limit #(
  parameter N     =     8,
  parameter Lower = 8'h7F,
  parameter Upper = 8'h80)(

  input nReset,
  input Clk,
  
  input  [N-1:0]Input,   // Unsigned
  output [N-1:0]Output); // Unsigned
//------------------------------------------------------------------------------

  wire [N-1:0]tInput;
  wire [N-1:0]tLower;
  wire [N-1:0]tUpper;
  reg  [N-1:0]tOutput;
 
  assign tInput = {~Input  [N-1], Input  [N-2:0]};
  assign tLower = {~Lower  [N-1], Lower  [N-2:0]};
  assign tUpper = {~Upper  [N-1], Upper  [N-2:0]};
  assign Output = {~tOutput[N-1], tOutput[N-2:0]};
//------------------------------------------------------------------------------

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      tOutput = 0;
//------------------------------------------------------------------------------

    end else begin
      if(tInput < tLower) tOutput <= tLower; else
      if(tInput > tUpper) tOutput <= tUpper; else
                          tOutput <= tInput;
    end
  end
endmodule
//------------------------------------------------------------------------------
