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

module AD7674(
  input nReset,
  input Clk,  // 50 MHz
  input Sync, // 390.625 kHz
  
  output       Reset,
  output reg   nCnvSt,
  input  [ 1:0]Busy,
  output reg   SClk,
  input  [ 1:0]Data,
  
  output reg [35:0]DataOut); // 2x 18-bit, 2's Compliment

  reg [ 1:0]tBusy;
  reg [ 1:0]state;
  reg [ 4:0]count;
  reg [16:0]tData[1:0];
  reg [ 1:0]tSync;
  reg [35:0]tDataOut;
//------------------------------------------------------------------------------
 
  assign Reset = ~nReset;

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      tBusy    <= 0;
      state    <= 0;
      nCnvSt   <= 1'b1;
      SClk     <= 0;
      tData[0] <= 0;
      tData[1] <= 0;
      tDataOut <= 0;
      DataOut  <= 0;
      tSync    <= 0;
  
    end else begin
      tSync <= {tSync[0], Sync};
      tBusy <= Busy;
  
      case(state)
        2'b00: begin
          if(tSync == 2'b01) begin
            DataOut <= tDataOut;
            nCnvSt  <= 1'b0;
          end
          if(&tBusy) begin
            state <= 2'b01;
          end
        end

        2'b01: begin
          nCnvSt <= 1'b1;
          count  <= 5'd18;
          if(~|tBusy) begin
            state <= 2'b11;
          end
        end
    
        2'b11: begin
          SClk  <= 1'b1;
          count <= count - 1'b1;
          state <= 2'b10;
        end

        2'b10: begin
          SClk <= 1'b0;
          if(~|count) begin
            tDataOut <= {tData[0], Data[0], tData[1], Data[1]};
            state    <= 2'b00;
          end else begin
            state <= 2'b11;
          end
          tData[0] <= {tData[0][15:0], Data[0]};
          tData[1] <= {tData[1][15:0], Data[1]};
        end
    
        default:;
      endcase
    end
  end
endmodule
//------------------------------------------------------------------------------
