//==============================================================================
// Copyright (C) John-Philip Taylor
// jpt13653903@gmail.com
//
// This file is part of S/PDIF Radio
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

module SD(
  input Reset,
  input Clk,

  // Mutex Access
  input  [5:0]Request,
  output [5:0]Grant,
 
  // Control interface
  input  [31:0]Block[5:0], // Block to be read into the RAM provided
  input  [ 5:0]Read,
  output       Busy,
 
  // User-provided buffer
  output [8:0]Address,
  output [7:0]Data,
  output      Write_Enable,

  output reg Card_Error, // Reset module to clear 

  // The SD-Card
  output reg CLK,
  inout      CMD,
  inout [3:0]DAT
);
//------------------------------------------------------------------------------

Mutex #(6) SD_Mutex(
  Reset,
  Clk,

  Request,
  Grant
);
//------------------------------------------------------------------------------

wire [31:0]SD_Block;
wire       SD_Read;

SD_Card #(4) SD_Card1(
  Reset,
  Clk,

  SD_Block,
  SD_Read,

  Busy,
  Address,
  Data,
  Write_Enable,

  Card_Error,

  CLK,
  CMD,
  DAT
);
//------------------------------------------------------------------------------

assign SD_Block = (Block[0] & {32{Grant[0]}}) |
                  (Block[1] & {32{Grant[1]}}) |
                  (Block[2] & {32{Grant[2]}}) |
                  (Block[3] & {32{Grant[3]}}) |
                  (Block[4] & {32{Grant[4]}}) |
                  (Block[5] & {32{Grant[5]}}) ;

assign SD_Read = (Read[0] & Grant[0]) |
                 (Read[1] & Grant[1]) |
                 (Read[2] & Grant[2]) |
                 (Read[3] & Grant[3]) |
                 (Read[4] & Grant[4]) |
                 (Read[5] & Grant[5]) ;
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

