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

module S_Filter(
  input  nReset,
  input  Clk, // 45 MHz

  input      [23:0]Input,
  output reg [23:0]Output,

  input  [17:0]a); //         2^18 - a
                   // H(z) = --------------
                   //         2^18 - a*z^-1

  reg  [23:0]xn;
  reg  [43:0]yn_1;
  wire [44:0]yn;

  wire [17:0]b;

  wire [41:0]bx;
  wire [61:0]ay;

  assign b = -a;

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      xn   <= 0;
      yn_1 <= 0;

      Output <= 0;
   
    end else begin
      if(~|a) begin
        Output <= Input;
      end else begin
        xn <= {(~Input[23]), Input[22:0]};

        if(!yn[44]) begin
          yn_1   <= yn[43:0];
          Output <= {~yn[43], yn[42:20]};
        end else begin
          yn_1   <= {44{1'b1}};
          Output <= 24'h7FFFFF;
        end
      end
    end
  end

  assign bx = b * xn;
  assign ay = a * yn_1;

  assign yn = {1'b0, ay[61:18]} + ay[17] + {1'b0, bx, 2'b00};
endmodule
