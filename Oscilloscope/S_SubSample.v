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

module S_SubSample(
 input nReset,
 input Clk,
  
 input      [23:0]Input,
 output reg [23:0]Output); // /2^24

 reg  [47:0] sum;
 reg  [23:0] Count;
 wire [47:0] e;

 assign e = {{24{Input[23]}}, Input};
 
 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   sum   <= 0;
   Count <= 0;
  end else begin
   if(~|Count) begin
    if(&sum[47:24]) begin
     Output <= 24'hFFFFFF;
    end else begin
     Output <= sum[47:24] + sum[23];
    end
    sum <= e;
   end else begin
    sum <= sum + e;
   end
   Count <= Count + 1'b1;
  end
 end
endmodule
