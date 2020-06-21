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

module Control(
  input Reset,
  input Clk,

  input [1:0]Button,

  output reg [3:0]Channel
);
//------------------------------------------------------------------------------

reg tReset;
reg State;

always @(posedge Clk) begin
  tReset <= Reset;

  if(tReset) begin
    State   <= 0;
    Channel <= 0;

  end else begin
    case(State)
      1'd0: begin
        if(Button[0]) begin
          if(Channel == 4'd5) Channel <= 0;
          else                Channel <= Channel + 1'b1;
          State <= 1'd1;

        end else if(Button[1]) begin
          if(Channel == 4'd0) Channel <= 4'd5;
          else                Channel <= Channel - 1'b1;
          State <= 1'd1;
        end
      end

      1'd1: begin
        if(~|Button) State <= 1'd0;
      end

      default:;
    endcase
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

