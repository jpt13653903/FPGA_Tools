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

module Receiver(
  input  nReset,
  input  Clk,
  input  SPDIF_Clk,
  output Sound_Clk,

  // 9 to 0 => left to right
  input [9:0]Switch,
  input [2:0]Button,

  // 0 to 7 => a b c d e f g dp
  output [7:0]SevenSegment0,
  output [7:0]SevenSegment1,
  output [7:0]SevenSegment2,
  output [7:0]SevenSegment3,

  // 9 to 0 => left to right
  output reg [9:0]LED,

  input  UART_RX,
  output UART_TX,

  input   SPDIF,
  output nSPDIF,

  output [1:0]PWM,

  output [3:0]VGA_Red,
  output [3:0]VGA_Green,
  output [3:0]VGA_Blue,
  output      VGA_HSync,
  output      VGA_VSync,

  output [5:1]Test_Point
);
//------------------------------------------------------------------------------

wire PLL_Locked;
wire Clk_180_555_520;
wire  Clk_90_277_760;
wire   Clk_1_410_590;

Rx_PLL PLL1(
  .inclk0(Clk),
  .c0    (Clk_180_555_520),
  .c1    (Clk_90_277_760),
  .c2    (Clk_1_410_590),
  .locked(PLL_Locked)
);

wire Ena_86;

reg [14:1]Ena_Counter;

always @(posedge Clk_1_410_590) Ena_Counter <= Ena_Counter + 1'b1;

assign Ena_86 = &Ena_Counter[14:1];
//------------------------------------------------------------------------------

wire Reset;

Powerup_Timer Powerup_Timer1(
  nReset & PLL_Locked,
  Clk,
  Clk_180_555_520,
  Reset
);
//------------------------------------------------------------------------------

wire [2:0]Button_Debounced;

genvar j;
generate
  for(j = 0; j < 3; j = j + 1) begin: Gen_Buttons
    Buttons Buttons1(
      Reset,
      Clk_1_410_590,
      Ena_86,
  
      Button[j],
      Button_Debounced[j]
    );
  end
endgenerate
//------------------------------------------------------------------------------

wire [6:0]SevenSegment;

SevenSegment_Decode SevenSegment_Decode0(Channel+1'b1, SevenSegment);

assign SevenSegment0 = {1'b1, ~SevenSegment};
assign SevenSegment1 = 8'hFF;
assign SevenSegment2 = 8'hFF;
assign SevenSegment3 = 8'hFF;
//------------------------------------------------------------------------------

wire [3:0]Channel;

Control Control1(
  Reset,
  Clk_1_410_590,

  ~Button_Debounced[2:1],

  Channel
);
//------------------------------------------------------------------------------

wire [15:0]Audio[5:0];
wire [ 7:0]Text_Stream;
//wire       Sound_Clk;
//wire       Data_Clk;

SPDIF_Decoder SPDIF_Decoder1(
  Reset,
  Clk_180_555_520,

   SPDIF,
  nSPDIF,

  Sound_Clk,
  Data_Clk,
  {Audio[5], Audio[4], Audio[3], Audio[2], Audio[1], Audio[0]},
  Text_Stream
);
//------------------------------------------------------------------------------

//wire UART_Busy;
//
//UART_Tx UART_Tx1(
// Reset,
// Clk_90_277_760,
//
// Text_Stream,
// Data_Clk,
// UART_Busy,
//
// UART_TX
//);
//------------------------------------------------------------------------------

wire Rec_Reset;
wire Rec_180_000_000;
//wire   Rec_1_406_250;
wire Ena_703_125;

Clock_Recovery Clock_Recovery1(
  Reset,
  SPDIF_Clk,//Sound_Clk,

  Rec_Reset,
  Rec_180_000_000,
  Rec_1_406_250,
  Ena_703_125
);
//------------------------------------------------------------------------------

wire [15:0]Sound;

Audio_Player Audio_Player1(
  Rec_Reset,
  Rec_180_000_000,
  Rec_1_406_250,
  Ena_703_125,

  Data_Clk,
  Audio,

  Channel,
  Switch,

  Sound,

  PWM,
  LED
);
//------------------------------------------------------------------------------

wire [7:0]Rx_Data;
wire      Rx_Ready;
reg       Rx_Ack;

reg [7:0]Tx_Data;
reg      Tx_Send;
wire     Tx_Busy;

UART #(8, 8'd146) UART1( // 9600 BAUD
  Reset,
  Clk_1_410_590,

  Rx_Data,
  Rx_Ready,
  Rx_Ack,

  Tx_Data,
  Tx_Send,
  Tx_Busy,

  UART_RX,
  UART_TX 
);

always @(posedge Clk_1_410_590) begin
  if(Reset) begin
    Rx_Ack  <= 0;
    Tx_Data <= 0;
    Tx_Send <= 0;

  end else begin
    if(Rx_Ready & ~Tx_Busy) begin
      Tx_Data <= Rx_Data;
      Tx_Send <= 1'b1;
      Rx_Ack  <= 1'b1;

    end else if(~Rx_Ready & Tx_Busy) begin
      Rx_Ack  <= 1'b0;
      Tx_Send <= 1'b0;
    end
  end
end
//------------------------------------------------------------------------------

wire VGA_Clk;
wire VGA_PLL_Locked;

VGA_PLL VGA_PLL1(
  .inclk0(Clk),
  .c0    (VGA_Clk),
  .locked(VGA_PLL_Locked)
);

Graphics Graphics1(
  Reset | (~VGA_PLL_Locked),
  Clk_1_410_590,
  Clk_180_555_520,
  VGA_Clk,

  Channel,
  Data_Clk,
  Text_Stream,
  Sound,

  VGA_Red,
  VGA_Green,
  VGA_Blue,
  VGA_HSync,
  VGA_VSync
);
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

