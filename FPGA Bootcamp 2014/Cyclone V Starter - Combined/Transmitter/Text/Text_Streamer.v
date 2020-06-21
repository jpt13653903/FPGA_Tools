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

module Text_Streamer(
  input Reset,
  input Clk,
  input Clk_Ena,

  output reg [9:0]Address,
  input      [7:0]Data,

  output reg [7:0]Output
);
//------------------------------------------------------------------------------

reg       tReset;

reg   [1:0]State;
localparam SendChannel = 2'b00;
localparam SendArtist  = 2'b01;
localparam SendTitle   = 2'b11;

always @(posedge Clk) begin
  tReset <= Reset;

  if(tReset) begin
    Address <= 0;
    Output  <= 0;
    State   <= SendChannel;
//------------------------------------------------------------------------------

  end else if(Clk_Ena) begin
    case(State)
      SendChannel: begin
        Output <= {5'd0, Address[9:7] + 1'b1};
        State  <= SendArtist;
      end
//------------------------------------------------------------------------------

      SendArtist: begin
        Output  <= Data;
        Address <= Address + 1'b1;
        if(~|Data) State <= SendTitle;
      end
//------------------------------------------------------------------------------

      SendTitle: begin
        Output <= Data;
    
        if(|Data) begin
          Address <= Address + 1'b1;

        end else begin
          Address[6:0] <= 0;

          if(Address[9:7] < 3'd5) begin
            Address[9:7] <= Address[9:7] + 1'b1;
          end else begin
            Address[9:7] <= 0;
          end
          State <= SendChannel;
        end
      end
//------------------------------------------------------------------------------

      default:;
    endcase
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

