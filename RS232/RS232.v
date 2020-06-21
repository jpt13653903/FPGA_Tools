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

module RS232(
  input  nReset,
  input  Clk,

  input  [7:0]TxData,
  input       Send,
  output      Busy,

  output      DataReady,
  output [7:0]RxData,
  input       Ack,
  
  output Tx,
  input  Rx);
 
  parameter CountBits = 5; // Default parameters for 50 MHz clock
  parameter Count0_5  = 5'd_8; // f_Clk / BAUD / 2
  parameter Count1    = 5'd17; // f_Clk / BAUD
  parameter Count1_5  = 5'd25; // f_Clk / BAUD * 1.5
 
  RS232_Tx #(CountBits, Count0_5, Count1) Sender(
    nReset,
    Clk,

    TxData,
    Send,
    Busy,
  
    Tx
  );

  RS232_Rx #(CountBits, Count1, Count1_5) Receiver(
    nReset,
    Clk,

    DataReady,
    RxData,
    Ack,

    Rx
  );
endmodule
