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

module uLimit #(
  parameter N     =     8,
  parameter Lower = 8'h00,
  parameter Upper = 8'hFF)(

  input nReset,
  input Clk,
  
  input      [N-1:0]Input,   // Unsigned
  output reg [N-1:0]Output); // Unsigned
//------------------------------------------------------------------------------

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      Output = 0;
//------------------------------------------------------------------------------

    end else begin
      if(Input < Lower) Output <= Lower; else
      if(Input > Upper) Output <= Upper; else
                        Output <= Input;
    end
  end
endmodule
//------------------------------------------------------------------------------
