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

module CPU_Arith(
 input      [7:0]A,
 input      [7:0]B,
 input      [3:0]Task,
 input           Carry_In,
 input           Zero_In,
 output reg [7:0]Y,
 output reg      Carry,
 output          Zero);
//------------------------------------------------------------------------------

 wire [8:0]A_B;
 wire      A_C_In;
 wire [7:0]A_Y;
 wire      A_C;

 wire C10;
 wire C11;
 
 wire tC;
//------------------------------------------------------------------------------

 assign A_B[  8] = ((Task == "0111") || (Task == "1000"));
 assign A_B[7:0] = (A_B[8]) ? (~B) : B;

 assign tC     = ((Task == "0001") || (Task == "0111")) ? Carry_In : 1'b0;
 assign A_C_In = (A_B[8]) ? (~tC) : tC;

 assign {A_C, A_Y} = A + A_B + A_C_In;

 assign C10 = A[7];
 assign C11 = A[0];

 always @* begin
  case(Task)
   4'h1,
   4'h2,
   4'h7,
   4'h8   : Y <= A_Y;
   4'h3   : Y <= A & B;
   4'h4   : Y <= -A;
   4'h5   : Y <= ~A;
   4'h6   : Y <= A | B;
   4'h9   : Y <= A ^ B;
   4'hA,
   4'hE   : Y <= {A[6:0], Carry_In};
   4'hB,
   4'hF   : Y <= {Carry_In, A[7:1]};
   4'hC   : Y <= {A[6:0], A[7]};
   4'hD   : Y <= {A[0],  A[7:1]};
   default: Y <= A;
  endcase
 end
 
 assign Zero = (Task == 4'b0000) ? Zero_In : (!(|Y));

 always @* begin
  case(Task)
   4'h1,
   4'h2,
   4'h7,
   4'h8   : Carry <= A_C;
   4'hA   : Carry <= C10;
   4'hB   : Carry <= C11;
   default: Carry <= Carry_In;
  endcase
 end
endmodule
//------------------------------------------------------------------------------
