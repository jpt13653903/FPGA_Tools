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

module Round #(
 parameter N_Integer  = 8,
 parameter N_Fraction = 8)(
 
 input      [N_Integer -1:0]Integer,  // 2's Compliment
 input      [N_Fraction-1:0]Fraction,
 
 output reg [N_Integer -1:0]Output);
//------------------------------------------------------------------------------

 wire a, b, c;

 assign a =   Integer [             0] ;
 assign b =   Fraction[N_Fraction-1  ] ;
 assign c = |(Fraction[N_Fraction-2:0]);
//------------------------------------------------------------------------------

 wire [N_Integer:0]sum;
 
 assign sum = {Integer[N_Integer-1], Integer} + b;
//------------------------------------------------------------------------------

 always @(*) begin
  if(a | c) begin
   case(sum[N_Integer:N_Integer-1])
    2'b00,
    2'b11: Output <= sum[N_Integer-1:0];
    2'b01: Output <= {1'b0, {(N_Integer-1){1'b1}}};
    2'b10: Output <= {1'b1, {(N_Integer-1){1'b0}}};
    default:;    
   endcase
  end else begin
   Output <= Integer;
  end
 end
endmodule
//------------------------------------------------------------------------------
