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

module RS232_Rx(
 input  nReset,
 input  Clk,

 output reg      DataReady,
 output reg [7:0]RxData,
 input           Ack,

 input Rx);

 parameter CountBits = 5; // Default parameters for 40 MHz clock
 parameter Count1    = 5'b01101; // f_Clk / BAUD
 parameter Count1_5  = 5'b10100; // f_Clk / BAUD * 1.5
 
 reg tRx;

 reg [          1:0] state;
 reg [CountBits-1:0] count;
 reg [          7:0] tdata;
 reg [          2:0] count2;

 reg set;

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   tRx    <= 1'b1;
   
   state  <= 2'b00;
   count2 <= 3'b000;
   RxData <= 8'h00;
   set    <= 1'b0;
   
  end else begin
   tRx <= Rx;

   case(state)
    2'b00: begin
     if(!tRx) begin
      count <= Count1_5;
      state <= 2'b01;
     end
    end
    
    2'b01: begin
     if(count == 2) begin
      state <= 2'b10;
     end
     count <= count - 1'b1;
    end
    
    2'b10: begin
     count <= Count1;
     if(&count2) begin
      if((!Ack) && (!DataReady)) begin
       RxData <= {tRx, tdata[7:1]};
       set    <= 1'b1;
      end
      state <= 2'b11;
     end else begin
      tdata <= {tRx, tdata[7:1]};
      state <= 2'b01;
     end
     count2 <= count2 + 1'b1;
    end
    
    2'b11: begin
     set <= 1'b0;
     if(tRx) begin
      state <= 2'b00;
     end
    end
    
    default:;
   endcase
  end
 end
//------------------------------------------------------------------------------

 always @(negedge Clk, posedge Ack, negedge nReset) begin
  if(Ack || (!nReset)) begin
   DataReady <= 1'b0;
  end else begin
   if(set) begin
    DataReady <= 1'b1;
   end
  end
 end
endmodule
