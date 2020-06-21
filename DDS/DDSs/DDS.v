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

module DDS(
 input  nReset,
 input  Clk,
 
 input  [23:0]Frequency,
 input  [15:0]Phase,
 input  [17:0]Skew0,
 input  [17:0]Skew1,
 input  [17:0]Skew2,
 input  [15:0]Amplitude,
 input  [15:0]Offset,
 input        Waveform, //  0 = sin; 1 = triangle
 input        Sync,     // Clears the phase counter on clock rising edge

 output reg [15:0]Output,

 input  [15:0]RAM_Data,
 input  [ 9:0]RAM_Address,
 input        RAM_Write,
 input        RAM_Clk);

 reg  [23:0]f;
 reg  [15:0]p;
 reg  [17:0]s0;
 reg  [17:0]s1;
 reg  [17:0]s2;
 reg  [15:0]a;
 reg  [16:0]o;
 reg        t;

 wire [23:0]p1;
 reg  [23:0]p2;
 wire [23:0]p3;

 wire [18:0]y1;
 wire [18:0]y2;
 wire [18:0]y3;
 reg  [18:0]y4;
 wire [16:0]y5;
 wire [16:0]y6;
 reg  [15:0]y7;

 wire [17:0]abs_y4;
 wire [33:0]abs_y5;
 wire [16:0]round_abs_y5;

 assign p1 = p2 + f;

 assign p3 = {(p1[23:8] + p), p1[7:0]};

 assign y1[2:0] = 0;
 
 DDS_Buffer BufferX1(
  .data     (RAM_Data),
  .wraddress(RAM_Address),
  .wrclock  (RAM_Clk),
  .wren     (RAM_Write),
  
  .rdaddress(p3[23:14] + p3[13]),
  .rdclock  (Clk),
  .q        (y1[18:3])
 );

 DDS_Triangle Triangle1(
  nReset,
  Clk,
  p3[23:6] + p3[5],
  s0,
  s1,
  s2,
  y2
 );

 assign y3 = (!t) ? y1 : y2;

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   y4 <= 0;
  end else begin
   y4 <= {~y3[18], y3[17:0]};
  end
 end

 assign abs_y4 = y4[18] ? (-y4[17:0]) : y4[17:0];

 assign abs_y5 = abs_y4 * a;

 assign round_abs_y5 = {2'b00, abs_y5[33:19]} + abs_y5[18];

 assign y5 = y4[18] ? -round_abs_y5 : round_abs_y5;
 
 assign y6 = y5 + o;

 always @* begin
  y7[15] <= y6[16];
  
  case(y6[16:15])
   2'b00,
   2'b11  : y7[14:0] <= y6[14:0];
   2'b01  : y7[14:0] <= 15'h7FFF;
   default: y7[14:0] <= 0;
  endcase
 end
 
 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   f  <= 0;
   p  <= 0;
   s0 <= 0;
   s1 <= 0;
   s2 <= 0;
   a  <= 0;
   o  <= 0;
   t  <= 0;

   p2 <= 0;
   
  end else begin
   f  <= Frequency;
   p  <= Phase;
   s0 <= Skew0;
   s1 <= Skew1;
   s2 <= Skew2;
   a  <= Amplitude;
   t  <= Waveform;

   o <= {Offset[15], Offset};

   if(Sync) begin
    p2 <= 0;
   end else begin
    p2 <= p1;
   end

   Output <= y7;
  end
 end
endmodule
