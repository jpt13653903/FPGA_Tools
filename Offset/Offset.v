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

module Offset #(
  parameter N = 8)(
 
  input      [N-1:0]Data,   // 2's Compliment
  input      [N-1:0]Offset, // 2's Compliment
 
  output reg [N-1:0]Output);
//------------------------------------------------------------------------------
 
  wire [N:0]sum;
 
  assign sum = {Data[N-1], Data} + {Offset[N-1], Offset};
//------------------------------------------------------------------------------

  always @(*) begin
    case(sum[N:N-1])
      2'b00,
      2'b11: Output <= sum[N-1:0];
      2'b01: Output <= {1'b0, {(N-1){1'b1}}};
      2'b10: Output <= {1'b1, {(N-1){1'b0}}};
      default:;
    endcase
  end
endmodule
//------------------------------------------------------------------------------
