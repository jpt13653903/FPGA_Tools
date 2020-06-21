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

module SPDIF_Radio(
  input nReset,
  input Clk,
  input SPDIF_Clk,

  // 9 to 0 => left to right
  input [9:0]Switch,
  input [3:0]Button,

  // 0 to 7 => a b c d e f g dp
  output [6:0]SevenSegment0,
  output [6:0]SevenSegment1,

  // 9 to 0 => left to right
  output [7:0] Green,
  output [9:0] Red,

  input  UART_RX,
  output UART_TX,

  inout [35:0]GPIO,

  output [3:0]VGA_Red,
  output [3:0]VGA_Green,
  output [3:0]VGA_Blue,
  output      VGA_HSync,
  output      VGA_VSync
);

assign GPIO   = {36{1'bZ}};
//------------------------------------------------------------------------------

wire [1:0]PWM;

wire [9:0]Rx_LED;
wire      Rx_UART_RX;
wire      Rx_UART_TX;

wire [7:0]Rx_SevenSegment[3:0];

wire Rx_SPDIF;
wire   nSPDIF;

wire Data_Clk;
wire Sound_Clk;
wire Recovered_Clock;

wire [5:1]Rx_Test_Point;

Receiver Receiver1(
  nReset,
  Clk,
  SPDIF_Clk,
  Sound_Clk,

{Switch[9:1], 1'b1},
  Button[2:0],

  Rx_SevenSegment[0],
  Rx_SevenSegment[1],
  Rx_SevenSegment[2],
  Rx_SevenSegment[3],

  Rx_LED,
  Rx_UART_RX,
  Rx_UART_TX,

  Rx_SPDIF,
  nSPDIF,

  PWM,

  VGA_Red,
  VGA_Green,
  VGA_Blue,
  VGA_HSync,
  VGA_VSync,

  Test_Point
);
//------------------------------------------------------------------------------

// I/O assignment for S/PDIF Radio

wire [9:0]TransformLED;
assign TransformLED[0] = Rx_LED[9];
assign TransformLED[1] = Rx_LED[8];
assign TransformLED[2] = Rx_LED[7];
assign TransformLED[3] = Rx_LED[6];
assign TransformLED[4] = Rx_LED[5];
assign TransformLED[5] = Rx_LED[4];
assign TransformLED[6] = Rx_LED[3];
assign TransformLED[7] = Rx_LED[2];
assign TransformLED[8] = Rx_LED[1];
assign TransformLED[9] = Rx_LED[0];

assign {Red, Green} = {8'd0, TransformLED};

assign SevenSegment0 = Rx_SevenSegment[0];
assign SevenSegment1 = Rx_SevenSegment[1];

//assign UART_TX = Rx_UART;
//
//assign GPIO[0] = PWM[0];
//
//assign GPIO[11] = Tx_SPDIF;
//assign Rx_SPDIF = GPIO[7];
//assign GPIO[ 5] =   nSPDIF;
//assign GPIO[ 9] = 1'b0;
//
// assign GPIO[15] = Tx_SPDIF;
// assign GPIO[17] =   nSPDIF;
// assign GPIO[19] = Sound_Clk;
// assign GPIO[21] = Recovered_Clock;
// 
// assign GPIO[14] = PWM[0];
// assign GPIO[16] = Tx_Green[  6]; // SD_Busy
// assign GPIO[18] = |Tx_Red [8:3]; // SD_Read
// assign GPIO[20] = 1'b0;
//------------------------------------------------------------------------------

// I/O assignments for Tester board

assign UART_TX = Rx_UART_TX;
assign Rx_UART_RX = UART_RX;

assign Rx_SPDIF = GPIO[25];
assign GPIO[24] = nSPDIF;

assign GPIO[15] = PWM[0];
assign GPIO[16] = PWM[1];

assign GPIO[0] = VGA_VSync;
assign GPIO[1] = VGA_HSync;
assign {GPIO[ 4], GPIO[ 5], GPIO[ 2], GPIO[ 3]}  = VGA_Red  ;
assign {GPIO[ 8], GPIO[ 9], GPIO[ 6], GPIO[ 7]}  = VGA_Green;
assign {GPIO[12], GPIO[13], GPIO[10], GPIO[11]}  = VGA_Blue ;

wire [6:1]TP;
assign GPIO[31:26] = {TP[2], TP[1], TP[4], TP[3], TP[6], TP[5]};

assign TP[1] = PWM[0];
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

