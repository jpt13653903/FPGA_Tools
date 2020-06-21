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

// Power-up timer

module Powerup_Timer(
  input nReset,
  input Clk,
  input System_Clk,

  output reg Reset
);
//------------------------------------------------------------------------------

reg      tReset;
reg     tnReset;
reg [21:0]Counter;

always @(posedge Clk) begin
  tnReset <= nReset;

  if(~tnReset) begin
    tReset  <= 1'b1;
    Counter <= 0;

  end else if(&Counter) begin
    tReset  <= 1'b0;

  end else begin
    tReset  <= 1'b1;
    Counter <= Counter + 1'b1;
  end
end

always @(posedge System_Clk) Reset <= tReset;
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

