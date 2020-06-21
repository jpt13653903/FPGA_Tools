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
 parameter N       =  4)( // Order of the noise shaper; 0 => no noise shaper

 input             nReset,
 input             Clk,
 input             Sync, // fClk / 2^OutputN
 input [InputN-1:0]Duty,

 output reg PWM);
//------------------------------------------------------------------------------

 reg  CounterSync;

 wire [OutputN-1:0]tD;
 reg  [OutputN-1:0]D;
 wire [OutputN-1:0]Count;
 wire              greater;
 reg               pSync;
//------------------------------------------------------------------------------

 Counter #(OutputN) Counter1(CounterSync, Clk, Count);
 
 generate
  if(N) begin
   NS #(InputN, OutputN, N) NS1(nReset, Sync, Duty, tD);
  end else begin
   assign tD = Duty[InputN-1:InputN-OutputN] + Duty[InputN-OutputN-1];
  end
 endgenerate

 assign greater = (D > Count);
//------------------------------------------------------------------------------

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   CounterSync <= 0;

   PWM   <= 0;
   D     <= 0;
   pSync <= 1'b1;
//------------------------------------------------------------------------------
   
  end else begin
   PWM <= greater;

   if({pSync, Sync} == 2'b01) begin
    CounterSync <= 1'b1;
    D           <= tD;
   end
   
   pSync <= Sync;
  end
 end
endmodule
//------------------------------------------------------------------------------
