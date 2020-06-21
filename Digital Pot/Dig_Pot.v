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

module Dig_Pot #(
  parameter       Default = 8'h0
)(
  input           nReset,
  input           Clk,
 
  input     [ 1:0]Pot,
  input           Limit, // If not set the position may roll over
 
  output reg[ 7:0]Position,
 
  input     [ 7:0]Set,
  input           Latch);
//------------------------------------------------------------------------------

  reg [10:0]count;
  reg [ 1:0]tPot[1:0];
//------------------------------------------------------------------------------

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      Position <= Default;
      count    <= 0;
      tPot[0]  <= 0;
      tPot[1]  <= 0;
//------------------------------------------------------------------------------

    end else if(Latch) begin
      Position <= Set;
      count    <= 0;
//------------------------------------------------------------------------------

    end else begin
      tPot[0] <= Pot;
//------------------------------------------------------------------------------
  
      if(count == 11'd_1_171) begin // 3 ms for a 390.625 kHz clock
        case({tPot[1], tPot[0]})
          4'b00_01,
          4'b01_11,
          4'b11_10,
          4'b10_00: begin
            if(!Limit || ~&Position) Position <= Position + 1'b1;
            tPot[1] <= tPot[0];
            count   <= 0;
          end
      
          4'b00_10,
          4'b01_00,
          4'b11_01,
          4'b10_11: begin
            if(!Limit || |Position) Position <= Position - 1'b1;
            tPot[1] <= tPot[0];
            count   <= 0;
          end

          default:;
        endcase
      end else begin
        count <= count + 1'b1;
      end
    end
  end
endmodule
//------------------------------------------------------------------------------
