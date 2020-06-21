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

module S_MUX(
 input nReset,
 input Clk,
  
 input [23:0]Input00,  // 2's Compliment
 input [23:0]Input01,  // 2's Compliment
 input [23:0]Input02,  // 2's Compliment
 input [23:0]Input03,  // 2's Compliment
 input [23:0]Input04,  // 2's Compliment
 input [23:0]Input05,  // 2's Compliment
 input [23:0]Input06,  // 2's Compliment
 input [23:0]Input07,  // 2's Compliment
 input [23:0]Input08,  // 2's Compliment
 input [23:0]Input09,  // 2's Compliment
 input [23:0]Input10,  // 2's Compliment
 input [23:0]Input11,  // 2's Compliment
 input [23:0]Input12,  // 2's Compliment
 input [23:0]Input13,  // 2's Compliment
 input [23:0]Input14,  // 2's Compliment
 input [23:0]Input15,  // 2's Compliment
 input [23:0]Input16,  // 2's Compliment
 input [23:0]Input17,  // 2's Compliment
 input [23:0]Input18,  // 2's Compliment
 input [23:0]Input19,  // 2's Compliment
 input [23:0]Input20,  // 2's Compliment
 input [23:0]Input21,  // 2's Compliment
 input [23:0]Input22,  // 2's Compliment
 input [23:0]Input23,  // 2's Compliment
 input [23:0]Input24,  // 2's Compliment
 input [23:0]Input25,  // 2's Compliment
 input [23:0]Input26,  // 2's Compliment
 input [23:0]Input27,  // 2's Compliment
 input [23:0]Input28,  // 2's Compliment
 input [23:0]Input29,  // 2's Compliment
 input [23:0]Input30,  // 2's Compliment
 input [23:0]Input31,  // 2's Compliment

 input      [ 4:0]MUX,
 output reg [23:0]Output);

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   Output <= 0;
  
  end else begin
   case(MUX)
    5'b00000: Output <= Input00;
    5'b00001: Output <= Input01;
    5'b00010: Output <= Input02;
    5'b00011: Output <= Input03;
    5'b00100: Output <= Input04;
    5'b00101: Output <= Input05;
    5'b00110: Output <= Input06;
    5'b00111: Output <= Input07;
    5'b01000: Output <= Input08;
    5'b01001: Output <= Input09;
    5'b01010: Output <= Input10;
    5'b01011: Output <= Input11;
    5'b01100: Output <= Input12;
    5'b01101: Output <= Input13;
    5'b01110: Output <= Input14;
    5'b01111: Output <= Input15;
    5'b10000: Output <= Input16;
    5'b10001: Output <= Input17;
    5'b10010: Output <= Input18;
    5'b10011: Output <= Input19;
    5'b10100: Output <= Input20;
    5'b10101: Output <= Input21;
    5'b10110: Output <= Input22;
    5'b10111: Output <= Input23;
    5'b11000: Output <= Input24;
    5'b11001: Output <= Input25;
    5'b11010: Output <= Input26;
    5'b11011: Output <= Input27;
    5'b11100: Output <= Input28;
    5'b11101: Output <= Input29;
    5'b11110: Output <= Input30;
    5'b11111: Output <= Input31;
    default : Output <= 0;
   endcase
  end
 end
endmodule
