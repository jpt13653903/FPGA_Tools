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

module RS232_Tx(
 input       nReset,
 input       Clk,

 input  [7:0]TxData,
 input       Send,
 output reg  Busy,

 output reg  Tx);
 
 parameter CountBits = 5; // Default parameters for 40 MHz clock
 parameter Count0_5  = 5'b01001; // f_Clk / BAUD / 2
 parameter Count1    = 5'b01101; // f_Clk / BAUD

 reg [          1:0] state;
 reg [          1:0] retstate;
 reg [CountBits-1:0] count;
 reg [          7:0] tData;
 reg [          2:0] count2;

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   state    <= 2'b11;
   count2   <= 3'b000;
   tData    <= 8'h00;
   Tx       <= 1'b1;
   Busy     <= 1'b1;
  
  end else begin
   case(state)
    2'b00: begin
     if(Send) begin
      Tx       <= 1'b0;
      tData    <= TxData;
      count    <= Count1;
      retstate <= 2'b10;
      state    <= 2'b01;
      Busy     <= 1'b1;
     end
    end
    
    2'b01: begin
     if(count == 2) begin
      state <= retstate;
     end
     count <= count - 1'b1;
    end
    
    2'b10: begin
     Tx     <= tData[0];
     tData  <= {1'b0, tData[7:1]};
     count  <= Count1;
     state  <= 2'b01;
     if(&count2) begin
      retstate <= 2'b11;
     end else begin
      retstate <= 2'b10;
     end
     count2 <= count2 + 1'b1;
    end
    
    2'b11: begin
     Tx <= 1'b1;
     if(!Send) begin
      Busy     <= 1'b0;
      count    <= Count0_5;
      retstate <= 2'b00;
      state    <= 2'b01;
     end
    end
     
    default:;
   endcase
  end
 end
endmodule
