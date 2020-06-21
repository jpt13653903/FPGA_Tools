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

module ADS1274(
  input nReset,
  input Clk, // -- max 50 MHz
  input Sync,
  
  output reg aClk,
  input      nDRdy,
  output reg SClk,
  input      Data,
  
  output reg [95:0]DataOut); //  4x 24-bit, 2's Compliment
//------------------------------------------------------------------------------

  reg [ 1:0]state;
  reg [ 6:0]count;
  reg [94:0]tData;
  reg [95:0]tDataOut;
  reg [ 1:0]pSync;
//------------------------------------------------------------------------------
 
  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      state    <= 0;
      aClk     <= 0;
      SClk     <= 0;
      tData    <= 0;
      DataOut  <= 0;
      tDataOut <= 0;
      pSync    <= 0;
//------------------------------------------------------------------------------

    end else begin
      aClk <= ~aClk;
//------------------------------------------------------------------------------

      pSync <= {pSync[0], Sync};
   
      if(pSync == 2'b01) begin
        DataOut <= tDataOut;
      end
//------------------------------------------------------------------------------

      case(state)
        2'b00: begin
          count[1:0] <= 2'd3;
          if(!nDRdy) begin
            state <= 2'b01;
          end
        end
//------------------------------------------------------------------------------

        2'b01: begin
          if(~|count[1:0]) begin
            count <= 7'd96;
            state <= 2'b11;
          end else begin
            count[1:0] <= count[1:0] - 1'b1;
          end
        end
//------------------------------------------------------------------------------

        2'b11: begin
          SClk  <= 1'b1;
          count <= count - 1'b1;
          state <= 2'b10;
        end
//------------------------------------------------------------------------------

        2'b10: begin
          SClk  <= 1'b0;
          if(~|count) begin
            {tDataOut[23: 0], tDataOut[47:24],
              tDataOut[71:48], tDataOut[95:72]} <= {tData, Data};
            state <= 2'b00;
          end else begin
            state <= 2'b11;
          end
          tData <= {tData[93:0], Data};
        end
//------------------------------------------------------------------------------

        default:;
      endcase
    end
  end
endmodule
//------------------------------------------------------------------------------
