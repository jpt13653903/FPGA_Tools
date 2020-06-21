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
  input Clk2,

  // 9 to 0 => left to right
  input [9:0]Switch,
  input [3:0]Button,

  // 0 to 7 => a b c d e f g dp
  output [6:0]SevenSegment0,
  output [6:0]SevenSegment1,

  // 9 to 0 => left to right
  output [7:0] Green,
  output [9:0] Red,

  output     SD_CLK,
  inout      SD_CMD,
  inout [3:0]SD_DAT,

  input  UART_RX,
  output UART_TX,

  inout [35:0]GPIO,

  inout [10:0]HSMC_A,
  inout [10:0]HSMC_B,
  inout [10:0]HSMC_C,

  inout HSMC_nSS,
  inout HSMC_MOSI,
  inout HSMC_MISO,
  inout HSMC_SCK,
  inout HSMC_Clk,
  inout HSMC_SDA,
  inout HSMC_SCL,
  inout HSMC_Rx,
  inout HSMC_Tx
);

assign GPIO   = {36{1'bZ}};
assign HSMC_A = {11{1'bZ}};
assign HSMC_B = {11{1'bZ}};
assign HSMC_C = {11{1'bZ}};

assign HSMC_nSS  = 1'bZ;
assign HSMC_MOSI = 1'bZ;
assign HSMC_MISO = 1'bZ;
assign HSMC_SCK  = 1'bZ;
assign HSMC_Clk  = 1'bZ;
assign HSMC_SDA  = 1'bZ;
assign HSMC_SCL  = 1'bZ;
assign HSMC_Rx   = 1'bZ;
assign HSMC_Tx   = 1'bZ;
//------------------------------------------------------------------------------

wire [6:0]Tx_SevenSegment[1:0];

wire [9:0]Tx_Red;
wire [7:0]Tx_Green;
wire      Tx_UART;

wire Tx_SPDIF;

Transmitter Transmitter1(
  nReset,
  Clk,

{Switch[9:1], 1'b1},
  Button,

  Tx_SevenSegment[0],
  Tx_SevenSegment[1],

  Tx_Red,
  Tx_Green,

  Tx_UART,

  SD_CLK,
  SD_CMD,
  SD_DAT,

  Tx_SPDIF
);
//------------------------------------------------------------------------------

// I/O assignment for S/PDIF Radio

assign {Red, Green} = {Tx_Red, Tx_Green};

assign SevenSegment0 = Tx_SevenSegment[0];
assign SevenSegment1 = Tx_SevenSegment[1];

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

assign UART_TX = Tx_UART;
//assign Tx_UART_RX = UART_RX;

assign GPIO[14] = Tx_SPDIF;

//assign GPIO[15] = PWM[0];
//assign GPIO[16] = PWM[1];

//assign GPIO[0] = VGA_VSync;
//assign GPIO[1] = VGA_HSync;
//assign {GPIO[ 4], GPIO[ 5], GPIO[ 2], GPIO[ 3]}  = VGA_Red  ;
//assign {GPIO[ 8], GPIO[ 9], GPIO[ 6], GPIO[ 7]}  = VGA_Green;
//assign {GPIO[12], GPIO[13], GPIO[10], GPIO[11]}  = VGA_Blue ;

wire [6:1]TP;
assign GPIO[31:26] = {TP[2], TP[1], TP[4], TP[3], TP[6], TP[5]};

assign TP[6] = Tx_SPDIF;

assign TP[3] =  Tx_Green[6]; // SD_Busy
assign TP[2] = |Tx_Red[8:3]; // SD_Read
//------------------------------------------------------------------------------

// 20-channel S/PDIF Driver

//assign GPIO = {36{Tx_SPDIF}};
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

