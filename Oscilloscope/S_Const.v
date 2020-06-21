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

module S_Const(
 input  nReset,
 input  Clk,

 input  [15:0]Bandwidth, // kHz

 output reg [17:0]a);
 
 parameter fs   = 18'd50_000; // f_Clk [kHz]
 parameter fs_2 = 16'd25_000; // fs / 2

 reg  [ 1:0]state;

 reg  [15:0]bw;

 reg  [17:0]mask;

 reg  [17:0]x;
 reg  [17:0]y;
 wire [35:0]z;

 assign z = x * y;

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   state    <= 0;

   bw  <= 0;

   mask <= 0;

   x <= 0;
   y <= 0;

   a <= 0;
   
  end else begin
   bw <= Bandwidth;
   
   case(state)
    2'b00: begin
     if(bw >= fs_2) begin
      a <= 0;
     end else begin
      x        <= 18'h3_24_3F; // pi;
      y[17:16] <= 2'b00;
      y[15: 0] <= bw;
      state    <= 2'b01;
     end
    end

    2'b01: begin
     y        <= fs + z[32:15];
     x        <= 18'h2_00_00;
     mask     <= 18'h2_00_00;
     state    <= 2'b10;
    end

    2'b10: begin
     if(z[35:18] > fs) begin
      x <= x & (~mask);
     end
     mask  <= {1'b0, mask[17:1]};
     state <= 2'b11;
    end

    2'b11: begin
     if(~|mask) begin
      a     <= x;
      state <= 2'b00;
     end else begin
      x     <= x | mask;
      state <= 2'b10;
     end
    end
    
    default:;
   endcase
  end
 end
endmodule
