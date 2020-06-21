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

module Transmitter(
  input nReset,
  input Clk,

  // 9 to 0 => left to right
  input [9:0]Switch,
  input [3:0]Button,

  // 0 to 6 => a b c d e f g
  output [6:0]SevenSegment0,
  output [6:0]SevenSegment1,

  // 9 to 0 => left to right
  output [9:0]Red,
  output [7:0]Green,

  output UART_TX,

  output     SD_CLK,
  inout      SD_CMD,
  inout [3:0]SD_DAT,

  output SPDIF
);
//------------------------------------------------------------------------------

wire PLL_Locked;
wire Clk_180_633_600;
wire  Clk_90_316_800;
wire  Clk_45_158_400;
wire   Clk_5_644_800;
wire   Clk_1_411_200;

Tx_PLL PLL1(
  .rst     (~nReset),
  .refclk  (Clk),
  .outclk_0(Clk_180_633_600),
  .outclk_1(Clk_45_158_400),
  .outclk_2(Clk_5_644_800),
  .outclk_3(Clk_1_411_200),
  .locked  (PLL_Locked)
);

wire Ena_44_100;
wire Ena_11_025;
wire     Ena_86;

reg [14:1]Ena_Counter;

always @(posedge Clk_1_411_200) Ena_Counter <= Ena_Counter + 1'b1;

assign Ena_44_100 = &Ena_Counter[ 5:1];
assign Ena_11_025 = &Ena_Counter[ 7:1];
assign     Ena_86 = &Ena_Counter[14:1];
//------------------------------------------------------------------------------

wire Reset;

Powerup_Timer Powerup_Timer1(
  nReset & PLL_Locked,
  Clk,
  Clk_180_633_600,
  Reset
);
//------------------------------------------------------------------------------

wire [3:0]Button_Debounced;

genvar j;

generate
  for(j = 0; j < 4; j = j + 1) begin: Gen_Buttons
    Buttons Buttons1(
      Reset,
      Clk_1_411_200,
      Ena_86,
  
      Button[j],
      Button_Debounced[j]
    );
  end
endgenerate
//------------------------------------------------------------------------------

wire [6:0]SevenSegment;

SevenSegment_Decode SevenSegment_Decode0(Channel+1'b1, SevenSegment);

assign SevenSegment0 = ~SevenSegment;
assign SevenSegment1 = 7'h7F;
//------------------------------------------------------------------------------

wire [5:0]SD_Request;
wire [5:0]SD_Grant;

wire [31:0]SD_Block[5:0];
wire [ 5:0]SD_Read;
wire       SD_Busy;

wire [8:0]SD_Address;
wire [7:0]SD_Data;
wire      SD_Write_Enable;

wire SD_Card_Error;

SD SD_Interface(
  Reset,
  Clk_45_158_400,

  SD_Request,
  SD_Grant,

  SD_Block,
  SD_Read,
  SD_Busy,

  SD_Address,
  SD_Data,
  SD_Write_Enable,

  SD_Card_Error,

  SD_CLK,
  SD_CMD,
  SD_DAT
);
//------------------------------------------------------------------------------

wire [15:0]Audio[5:0];
wire [ 5:0]Audio_Data_Valid;

generate
  for(j = 0; j < 6; j = j + 1) begin: Gen_Channels
    Channel #(j[2:0]) Channel1(
      Reset,
      Clk_45_158_400,
      Clk_1_411_200,
      Ena_44_100,

      SD_Request[j],
      SD_Grant  [j],

      SD_Block[j],
      SD_Read [j],
      SD_Busy,

      SD_Address,
      SD_Data,
      SD_Write_Enable,

      Text_Request[j],
      Text_Grant  [j],
   
      Text_Address     [j],
      Text_Data        [j],
      Text_Write_Enable[j],

      ~Button_Debounced[0] & (Channel == j[3:0]),

      Audio           [j],
      Audio_Data_Valid[j]
    );
  end
endgenerate
//------------------------------------------------------------------------------

wire [5:0]Text_Request;
wire [5:0]Text_Grant;

wire [9:0]Text_Address     [5:0];
wire [7:0]Text_Data        [5:0];
wire      Text_Write_Enable[5:0];

wire [7:0]Text_Stream;

Text Text1(
  Reset,
  Clk_1_411_200,
  Ena_11_025,

  Text_Request,
  Text_Grant,

  Text_Address,
  Text_Data,
  Text_Write_Enable,

  Text_Stream
);
//------------------------------------------------------------------------------

SPDIF_Encoder SPDIF_Encoder1(
  Reset,
  Clk_5_644_800,

  {Audio[5], Audio[4], Audio[3], Audio[2], Audio[1], Audio[0]},
  Text_Stream,
 
  SPDIF
);
//------------------------------------------------------------------------------

wire [3:0]Channel;

Control Control1(
  Reset,
  Clk_1_411_200,

  ~Button_Debounced[2:1],

  Channel
);
//------------------------------------------------------------------------------

assign UART_TX = 1'b1;
//------------------------------------------------------------------------------

assign Red   = {Reset, SD_Read, 2'd0, SD_Card_Error};
assign Green = {~SD_Card_Error, SD_Busy, Audio_Data_Valid};
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------


