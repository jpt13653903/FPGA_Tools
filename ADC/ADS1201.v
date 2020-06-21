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

// Utilises a FIR filter with f0 = f_Clk / 4000;
// Sample rate f_Clk / 512

module ADS1201(
 input            nReset,
 input            Clk, // max 8 MHz
 input            Sync,

 output reg [23:0]Output,

 output           ADC_Clk,
 input            ADC_Data);
//----------------------------------------------------------------------------

 reg        Data;
 reg  [23:0]Sum[7:0];
 reg  [ 2:0]Part;
 reg  [ 2:0]pPart;
 
 reg  [ 8:0]Address;
 reg  [ 8:0]FIR_Address;
 wire [15:0]FIR_Data;
 
 reg  [23:0]Result;
 
 reg  [23:0]tOutput;
 reg  [ 1:0]pSync;
//----------------------------------------------------------------------------

 integer j;
//----------------------------------------------------------------------------

 ADS1201_FIR FIR(
  .clock  (!Clk),
  .address(FIR_Address),
  .q      (FIR_Data)
 );
//----------------------------------------------------------------------------

 always @* begin
  if(Data) begin
   Result <= Sum[pPart] + {{8{FIR_Data[15]}}, FIR_Data};
  end else begin
   Result <= Sum[pPart] - {{8{FIR_Data[15]}}, FIR_Data};
  end
 end
//----------------------------------------------------------------------------

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   Data        <= 0;
   Part        <= 0;
   Address     <= 0;
   FIR_Address <= 0;
   tOutput     <= 0;
   Output      <= 0;
   pSync       <= 0;
   
   for(j = 0; j < 8; j = j + 1) begin
    Sum[j] <= 0;
   end
//----------------------------------------------------------------------------

  end else begin
   pSync <= {pSync[0], Sync};
   
   if(pSync == 2'b01) begin
    Output <= tOutput;
   end
//------------------------------------------------------------------------------

   if(~|Part) begin
    Data        <= ADC_Data;
    Address     <= Address + 1'b1;
    FIR_Address <= Address + 1'b1;
   end else begin
    FIR_Address <= Address + {Part, 6'b0};
   end
   pPart <= Part;
   Part  <= Part + 1'b1;
//----------------------------------------------------------------------------

   if(&FIR_Address) begin
    tOutput    <= Result;
    Sum[pPart] <= 0;
   end else begin
    Sum[pPart] <= Result;
   end
  end
 end
//----------------------------------------------------------------------------

 assign ADC_Clk = Part[2];
endmodule
//----------------------------------------------------------------------------
