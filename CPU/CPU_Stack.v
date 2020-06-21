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

module CPU_Stack(
  input nReset,
  input Clk,

  input  [2:0]Address,
  input  [7:0]Input,
  output [7:0]Out0,
  output [7:0]Out1,
  output [7:0]OutA,

  input       Latch,
  input  [1:0]Task); // "00" = Store in s0
                     // "01" = Push onto stack
                     // "10" = Store is s1, then Pop Stack
                     // "11" = Swop s0 and sA

  reg [7:0]s[7:0];

  reg LPrev;
//------------------------------------------------------------------------------

  assign Out0 = s[0];
  assign Out1 = s[1];
  assign OutA = s[Address];

  always @(negedge nReset, negedge Clk) begin
    if(!nReset) begin
      s[0] <= 0;
      s[1] <= 0;
      s[2] <= 0;
      s[3] <= 0;
      s[4] <= 0;
      s[5] <= 0;
      s[6] <= 0;
      s[7] <= 0;

      LPrev <= 0;
   
    end else begin
      LPrev <= Latch;

      if({LPrev, Latch} == 2'b01) begin
        case(Task)
          2'b00: begin
            s[0] <= Input;
          end
     
          2'b01: begin
            s[1] <= s[0];
            s[2] <= s[1];
            s[3] <= s[2];
            s[4] <= s[3];
            s[5] <= s[4];
            s[6] <= s[5];
            s[7] <= s[6];
            s[0] <= Input;
          end
     
          2'b10: begin
            s[0] <= Input;
            s[1] <= s[2]; 
            s[2] <= s[3];
            s[3] <= s[4];
            s[4] <= s[5];
            s[5] <= s[6];
            s[6] <= s[7];
          end
     
          2'b11: begin
            s[Address] <= s[0];
            s[      0] <= s[Address];
          end
     
          default:;
        endcase
      end
    end
  end
endmodule
