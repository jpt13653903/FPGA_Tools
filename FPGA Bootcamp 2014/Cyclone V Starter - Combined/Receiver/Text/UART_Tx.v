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

module UART_Tx #(
  parameter N    = 5,
  parameter Full = 5'd29 // Clk / BAUD - 1
)(
  input Reset,
  input Clk,

  input [7:0]Data,
  input      Send,
  output reg Busy,

  output reg Tx
);
//------------------------------------------------------------------------------

reg        tSend;
reg [  7:0]Temp;
reg [N-1:0]Count;
reg [  2:0]BitCount;
//------------------------------------------------------------------------------

reg   [1:0]State;
localparam Idle    = 2'b00;
localparam Sending = 2'b01;
localparam StopBit = 2'b11;
localparam Done    = 2'b10;
//------------------------------------------------------------------------------

reg tReset;

always @(posedge Clk) begin
  tReset <= Reset;

  if(tReset) begin
    Busy <= 1'b0;
    Tx   <= 1'b1;

    tSend    <= 0;
    Count    <= 0;
    BitCount <= 0;
    State    <= Idle;
//------------------------------------------------------------------------------

  end else begin
    tSend <= Send;

    if(~|Count) begin
      case(State)
        Idle: begin
          if(tSend) begin
            Count      <= Full;
            BitCount   <= 3'd7;
            {Temp, Tx} <= {Data, 1'b0};
            Busy       <= 1'b1;
            State      <= Sending;
          end
        end
//------------------------------------------------------------------------------

        Sending: begin
          Count           <= Full;
          {Temp[6:0], Tx} <= Temp;
      
          if(~|BitCount) State <= StopBit;
          BitCount <= BitCount - 1'b1;
        end
//------------------------------------------------------------------------------ 

        StopBit: begin
          Tx    <= 1'b1;
          Count <= Full;
          State <= Done;
        end
//------------------------------------------------------------------------------

        Done: begin
          if(~tSend) begin
            Busy  <= 1'b0;
            State <= Idle;
          end
        end
//------------------------------------------------------------------------------

        default:;
      endcase
    end else begin
      Count <= Count - 1'b1;
    end
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

