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

module DDSs #(
 parameter n = 12)(
 
 input  nReset,
 input  Clk,

 input  [24*n-1:0]Frequency, // 2's Compliment
 input  [16*n-1:0]Phase,     // Unsigned
 input  [16*n-1:0]Skew,      // Unsigned
 input  [16*n-1:0]Amplitude, // Unsigned
 input  [16*n-1:0]Offset,    // 2's Compliment

 input  [   n-1:0]Waveform,  // 0 = sin; 1 = triangle
 input            Sync,

 output [16*n-1:0]Output,    // Signed Integer

 input  [15    :0]RAM_Data,
 input  [ 9    :0]RAM_Address,
 input  [   n-1:0]RAM_Write,
 input            RAM_Clk);
//------------------------------------------------------------------------------

 wire [18*n-1:0]Skew0;
 wire [18*n-1:0]Skew1;
 wire [18*n-1:0]Skew2;
//------------------------------------------------------------------------------

 DDS_Const Const1(
  nReset,
  RAM_Clk,
  {{(16*(12-n)){1'b0}}, Skew },
  Skew0,
  Skew1,
  Skew2
 );

 generate
  genvar i;
  for(i = 0; i < n; i = i + 1) begin: G_DDS
   DDS DDS1(
    nReset,
    Clk,   

    Frequency[24*i+23:24*i],
    Phase    [16*i+15:16*i],
    Skew0    [18*i+17:18*i],
    Skew1    [18*i+17:18*i],
    Skew2    [18*i+17:18*i],
    Amplitude[16*i+15:16*i],
    Offset   [16*i+15:16*i],
    Waveform [i],
    Sync,

    Output[16*i+15:16*i],

    RAM_Data,
    RAM_Address,
    RAM_Write[i],
    RAM_Clk
   );
  end
 endgenerate
endmodule
