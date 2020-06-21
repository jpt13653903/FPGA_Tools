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

module Reset(
 input  nReset,
 input  Clk,

 output reg Output);
//------------------------------------------------------------------------------

 // Default values for a 48.828 kHz clock
 parameter n = 13;       // Length of the counter
 parameter c = 13'd4883; // 100 ms * f_Clk
//------------------------------------------------------------------------------

 reg [n-1:0]count; // 100 ms
//------------------------------------------------------------------------------

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   Output <= 0;
   count  <= c;
//------------------------------------------------------------------------------
   
  end else begin
   if(~|count) Output <= 1'b1;
   count <= count - 1'b1;
  end
 end
endmodule
//------------------------------------------------------------------------------
