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
  parameter N = 2 // Minimum of 2 lines
)(
  input Reset,
  input Clk,
 
  input      [N-1:0]Request, // index 0 has highest priority
  output reg [N-1:0]Grant
);
//------------------------------------------------------------------------------

wire [N-1:0]No_Higher_Request;

generate
  genvar j;

  assign No_Higher_Request[0] = 1'b1;
  assign No_Higher_Request[1] = ~Request[0];

  for(j = 2; j < N; j = j + 1) begin: Gen_Mutex
    assign No_Higher_Request[j] = ~|Request[j-1:0];
  end
endgenerate
//------------------------------------------------------------------------------

reg tReset;

always @(posedge Clk) begin
  tReset <= Reset;

  if(tReset) begin
    Grant <= 0;

  end else if(~|(Grant & Request)) begin
    Grant <= Request & No_Higher_Request;
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

