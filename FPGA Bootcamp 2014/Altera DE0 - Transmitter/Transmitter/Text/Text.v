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

module Text(
  input Reset,
  input Clk,
  input Clk_Ena,

  input  [5:0]Request,
  output [5:0]Grant,

  input  [9:0]Address     [5:0],
  input  [7:0]Data        [5:0],
  input       Write_Enable[5:0],

  output [7:0]Stream
);
//------------------------------------------------------------------------------

Mutex #(6) Text_Mutex(
  Reset,
  Clk,

  Request,
  Grant
);
//------------------------------------------------------------------------------

wire [9:0]Write_Address;
wire [7:0]Write_Data;
wire      Write_Enable_1;

wire [9:0]Read_Address;
wire [7:0]Read_Data;

FIFO_RAM Text_Buffer( 
  .clock    (Clk),

  .wraddress(Write_Address),
  .data     (Write_Data),
  .wren     (Write_Enable_1),

  .rdaddress(Read_Address),
  .q        (Read_Data)
);
//------------------------------------------------------------------------------

Text_Streamer Text_Streamer1(
  Reset,
  Clk,
  Clk_Ena,

  Read_Address,
  Read_Data,

  Stream
);
//------------------------------------------------------------------------------

assign Write_Address = (Address[0] & {10{Grant[0]}}) |
                       (Address[1] & {10{Grant[1]}}) |
                       (Address[2] & {10{Grant[2]}}) |
                       (Address[3] & {10{Grant[3]}}) |
                       (Address[4] & {10{Grant[4]}}) |
                       (Address[5] & {10{Grant[5]}}) ;

assign Write_Data = (Data[0] & {8{Grant[0]}}) |
                    (Data[1] & {8{Grant[1]}}) |
                    (Data[2] & {8{Grant[2]}}) |
                    (Data[3] & {8{Grant[3]}}) |
                    (Data[4] & {8{Grant[4]}}) |
                    (Data[5] & {8{Grant[5]}}) ;

assign Write_Enable_1 = (Write_Enable[0] & Grant[0]) |
                        (Write_Enable[1] & Grant[1]) |
                        (Write_Enable[2] & Grant[2]) |
                        (Write_Enable[3] & Grant[3]) |
                        (Write_Enable[4] & Grant[4]) |
                        (Write_Enable[5] & Grant[5]) ;
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

