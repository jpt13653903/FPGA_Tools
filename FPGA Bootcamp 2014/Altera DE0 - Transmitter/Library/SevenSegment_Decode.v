//==============================================================================
// Copyright (C) John-Philip Taylor
// jpt13653903@gmail.com
//
// This file is part of S/PDIF Radio
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

//   a
// f   b
//   g
// e   c
//   d

module SevenSegment_Decode(
  input      [3:0]Hex,
  output reg [6:0]Output // 0 to 6 => a b c d e f g
);
//------------------------------------------------------------------------------

  always @(Hex) begin
    case(Hex)       
      4'h0: Output <= 7'b0111111;
      4'h1: Output <= 7'b0000110;
      4'h2: Output <= 7'b1011011;
      4'h3: Output <= 7'b1001111;
      4'h4: Output <= 7'b1100110;
      4'h5: Output <= 7'b1101101;
      4'h6: Output <= 7'b1111101;
      4'h7: Output <= 7'b0000111;
      4'h8: Output <= 7'b1111111;
      4'h9: Output <= 7'b1101111;
      4'hA: Output <= 7'b1110111;
      4'hB: Output <= 7'b1111100;
      4'hC: Output <= 7'b0111001;
      4'hD: Output <= 7'b1011110;
      4'hE: Output <= 7'b1111001;
      4'hF: Output <= 7'b1110001;
      default:;
    endcase
  end
//------------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------

