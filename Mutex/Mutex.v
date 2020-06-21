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

module Mutex #(
  parameter n = 2
)(
  input             nReset,
  input             Clk,
 
  input      [n-1:0]Request, // index 0 has highest priority
  output reg [n-1:0]Grant
);
//------------------------------------------------------------------------------

  integer j;
  integer q;
//------------------------------------------------------------------------------

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      Grant <= 0;
//------------------------------------------------------------------------------

    end else begin
      if(|Grant) begin
        Grant <= Grant & Request;
//------------------------------------------------------------------------------
    
      end else begin
        for(j = 0; j < n; j = j + 1) begin
          Grant[j] = Request[j];
          for(q = 0; q < j; q = q + 1) begin
            Grant[j] = Grant[j] & (~Request[q]);
          end
        end
      end
    end
  end
endmodule
//------------------------------------------------------------------------------
