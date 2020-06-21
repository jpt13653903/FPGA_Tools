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

module DDS(
  input Reset,
  input Clk,

  input      [23:0]Frequency,
  output reg [15:0]Output
);
//------------------------------------------------------------------------------

reg  [23:0]Phase;
wire [ 8:0]Address;

assign Address = Phase[23] ? ~Phase[22:14] + 1'b1 : Phase[22:14];
//------------------------------------------------------------------------------

wire [15:0]Cos;

DDS_Cos DDS_Cos1(
  .address(Address),
  .clock  (~Clk),
  .q      (Cos)
);
//------------------------------------------------------------------------------

reg tReset;

always @(posedge Clk) begin
  tReset <= Reset;

  if(tReset) begin
    Phase  <= 0;
    Output <= 0;

  end else begin
    Phase <= Phase + Frequency;

    if(Phase[23:14] == 10'h200) Output <= 0;
    else                        Output <= Cos;
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

