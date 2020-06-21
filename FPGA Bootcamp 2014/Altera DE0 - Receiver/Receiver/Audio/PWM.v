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

module PWM #(
  parameter InputN  = 24,
  parameter OutputN =  8,
  parameter N       =  4 // Order of the noise shaper; 0 => no noise shaper
)(
  input             Reset,
  input             PWM_Clk,
  input             Sound_Clk,
  input             Sound_Clk_Ena,

  input [InputN-1:0]Duty,

  output reg PWM
);
//------------------------------------------------------------------------------

generate
  if(N) begin
    wire [OutputN-1:0]D;

    NoiseShaper #(InputN, OutputN, N) NoiseShaper1(
      Reset, 
      Sound_Clk, 
      Sound_Clk_Ena, 
   
      Duty, 
      D
    );

  end else begin
    reg [OutputN-1:0]D;

    always @(posedge Sound_Clk) begin
      if     (tReset       ) D <= 0;
      else if(Sound_Clk_Ena) D <= Duty[InputN-1:InputN-OutputN];
    end
  end
endgenerate
//------------------------------------------------------------------------------

reg tReset;

reg [OutputN-1:0]Width;
reg [OutputN-1:0]Count;

always @(posedge PWM_Clk) begin
  tReset <= Reset;

  if(tReset) begin
    PWM   <= 0;
    Width <= 0;
    Count <= 0;
   
  end else begin
    if(&Count) Width <= D;

    PWM   <= Width > Count;
    Count <= Count + 1'b1;
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

