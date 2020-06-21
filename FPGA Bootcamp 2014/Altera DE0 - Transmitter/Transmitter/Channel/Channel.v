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

module Channel #(
  parameter Channel_Number = 3'd0
)(
  input Reset,
  input SD_Clk,
  input Decoder_Clk,
  input Decoder_Clk_Ena,

  output SD_Request,
  input  SD_Grant,

  output [31:0]SD_Block,
  output       SD_Read,
  input        SD_Busy,

  input [8:0]SD_Address,
  input [7:0]SD_Data,
  input      SD_Write_Enable,

  output      Text_Request,
  input       Text_Grant,
  output [9:0]Text_Address,
  output [7:0]Text_Data,
  output      Text_Write_Enable,

  input        Skip,
  output [15:0]Audio,
  output       Data_Valid
);
//------------------------------------------------------------------------------

wire [40:0]Address;
wire [ 7:0]Data;

FIFO FIFO1(
  Reset,
  SD_Clk,

  Address,
  Data,
  Data_Valid,

  SD_Request,
  SD_Grant,

  SD_Block,
  SD_Read,

  SD_Busy         &    SD_Grant,
  SD_Address      & {9{SD_Grant}},
  SD_Data         & {8{SD_Grant}},
  SD_Write_Enable &    SD_Grant
);
//------------------------------------------------------------------------------

Channel_Decoder #(Channel_Number) Decoder(
  Reset, 
  Decoder_Clk, 
  Decoder_Clk_Ena,

  Address,
  Data,
  Data_Valid,

  Text_Request,
  Text_Grant,
  Text_Address[6:0],
  Text_Data,
  Text_Write_Enable,

  Skip,
  Audio
);

assign Text_Address[9:7] = Channel_Number;
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

