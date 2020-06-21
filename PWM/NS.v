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

module NS(nReset, Clk, Input, Output);
 parameter InputN  = 24;
 parameter OutputN =  8;
 parameter N       =  4; // Order of the noise shaper
//------------------------------------------------------------------------------

 input  nReset;
 input  Clk;

 input  [InputN -1:0]Input;
 output [OutputN-1:0]Output;
//------------------------------------------------------------------------------

 wire [(InputN+1)        :0]t1;
 reg  [(InputN-1)        :0]t2;
 reg  [(InputN-OutputN+N):0]t3[2*N+1:0];
 wire [(InputN+1)        :0]t4;
//------------------------------------------------------------------------------
 
 assign t1 = t4 + Input;
//------------------------------------------------------------------------------

 always @(negedge nReset, negedge Clk) begin
  if(!nReset) begin
   t2  <= 0;
   
  end else begin
   if     (t1[InputN+1]) t2 <= 0;
   else if(t1[InputN  ]) t2 <= {InputN{1'b1}};
   else                  t2 <= t1[InputN-1:0];
  end
 end
//------------------------------------------------------------------------------

 assign Output = t2[InputN-1:InputN-OutputN];
//------------------------------------------------------------------------------
 
 always @* begin 
  t3[0] <= {{(N+1){1'b0}}, t2[InputN-OutputN-1:0]};
 end
//------------------------------------------------------------------------------

 generate
 genvar g;
  for(g = 0; g < N; g = g + 1) begin: NS_Blocks
   always @* begin
    t3[2*g+2] <= t3[2*g] - t3[2*g+1];
   end
   
   always @(negedge nReset, negedge Clk) begin
    if(!nReset) begin
     t3[2*g+1] <= 0;
    end else begin
     t3[2*g+1] <= t3[2*g];
    end
   end
  end 
 endgenerate
//------------------------------------------------------------------------------

 always @* begin
  t3[2*N+1] <= t3[0] - t3[2*N];
 end
//------------------------------------------------------------------------------
 
 assign t4 = {{(OutputN-N+1){t3[2*N+1][InputN-OutputN+N]}}, t3[2*N+1]};
endmodule
//------------------------------------------------------------------------------
