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

// Takes a signed Input and averages 2^div samples for every one signed Output

module SubSample(nReset, Clk, Input, Output);
 parameter n   = 18; // Length of data
 parameter div = 20; // Sample rate divided by 2^div
 
 input  nReset;
 input  Clk;
  
 input      [n-1:0]Input;  // 2's Compliment
 output reg [n-1:0]Output; // 2's Compliment
 
 reg  [n+div-1:0] sum;
 reg  [  div-1:0] count;
 wire [n+div-1:0] e;
 
 assign e = {{div{Input[n-1]}}, Input};
 
 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   sum   <= 0;
   count <= 0;
  end else begin
   if(~|count) begin
    if(&sum[n+div-2:div]) begin
     Output <= sum[n+div-1:div];
    end else begin
     Output <= sum[n+div-1:div] + sum[div-1];
    end
    sum <= e;
   end else begin
    sum <= sum + e;
   end
   count <= count + 1'b1;
  end
 end
endmodule
