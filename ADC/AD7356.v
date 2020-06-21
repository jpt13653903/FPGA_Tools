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

module AD7356(
 input            nReset,
 input            Clk, // max 160 MHz; min 100 kHz

 output reg [11:0]OutA,
 output reg [11:0]OutB,

 output reg       nCS,
 output reg       SClk,
 input            SDataA,
 input            SDataB);
//------------------------------------------------------------------------------

 reg [ 1:0]state;
 reg [ 3:0]count;
 reg [11:0]dataA;
 reg [11:0]dataB;
//------------------------------------------------------------------------------

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   state <= 0;
   count <= 0;
   nCS   <= 1'b1;
   SClk  <= 1'b1;
   dataA <= 0;
   dataB <= 0;
   count <= 0;
//------------------------------------------------------------------------------

  end else begin
   case(state)
    2'd0: begin
     nCS   <= 1'b0;
     count <= 4'd14;
     state <= 2'd1;
    end
//------------------------------------------------------------------------------
    
    2'd1: begin
     SClk  <= 1'b0;
     dataA <= {dataA[10:0], SDataA};
     dataB <= {dataB[10:0], SDataB};
     count <= count - 1'b1;
     state <= 2'd2;
    end
//------------------------------------------------------------------------------
   
    2'd2: begin
     SClk <= 1'b1;
     if(~|count) begin
      OutA  <= dataA;
      OutB  <= dataB;
      nCS   <= 1'b1;
      state <= 1'b0;

     end else begin
      state <= 2'd1;
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
