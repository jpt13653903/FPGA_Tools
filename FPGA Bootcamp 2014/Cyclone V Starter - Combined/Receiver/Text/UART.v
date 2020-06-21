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

module UART #(
  parameter N    = 5,
  parameter Full = 5'd29 // Clk / BAUD - 1
)(
  input Reset,
  input Clk,

  output [7:0]Rx_Data,
  output      Rx_Ready,
  input       Rx_Ack,

  input  [7:0]Tx_Data,
  input       Tx_Send,
  output      Tx_Busy,

  input       Rx,
  output      Tx
);
//------------------------------------------------------------------------------

UART_Rx #(N, Full) UART_Rx1(
  Reset,
  Clk,

  Rx_Data,
  Rx_Ready,
  Rx_Ack,

  Rx
);
//------------------------------------------------------------------------------

UART_Tx #(N, Full) UART_Tx1(
  Reset,
  Clk,

  Tx_Data,
  Tx_Send,
  Tx_Busy,

  Tx
);
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

