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

module UART_Rx #(
  parameter N    = 5,
  parameter Full = 5'd29 // Clk / BAUD - 1
)(
  input Reset,
  input Clk,

  output reg [7:0]Data,
  output reg      Ready,
  input           Ack,

  input Rx
);
//------------------------------------------------------------------------------

reg       tRx;
reg       tAck;
reg [  7:0]Temp;
reg [N-1:0]Count;
reg [  2:0]BitCount;
reg        NewData;
//------------------------------------------------------------------------------

reg   [1:0]State;
localparam Idle      = 2'b00;
localparam StartBit  = 2'b01;
localparam Receiving = 2'b11;
localparam Done      = 2'b10;
//------------------------------------------------------------------------------

reg tReset;

always @(posedge Clk) begin
  tRx    <= Rx;
  tAck   <= Ack;
  tReset <= Reset;

  if(tReset) begin
    Data    <= 0;
    Ready   <= 0;
    NewData <= 0;

    Count <= 0;

    State <= Idle;
//------------------------------------------------------------------------------

  end else begin
    if(Ready & tAck) Ready <= 1'b0;

    case(State)
      Idle: begin
        if(~tRx) begin
          Count <= {1'b0, Full[N-1:1]};
          State <= StartBit;
        end

        if(NewData & ~tAck && ~Ready) begin 
          Data    <= Temp;
          Ready   <= 1'b1;
          NewData <= 1'b0;
        end
      end
//------------------------------------------------------------------------------

      Done: begin
        if(tRx) State <= Idle;
      end
      default:;
    endcase
//------------------------------------------------------------------------------

    if(~|Count) begin
      case(State)
        StartBit: begin
          if(Rx) begin
            State <= Idle;
          end else begin
            BitCount <= 0;
            Count    <= Full;
            State    <= Receiving;
          end 
        end
//------------------------------------------------------------------------------ 

        Receiving: begin
          Temp  <= {tRx, Temp[7:1]};
          Count <= Full;
     
          if(&BitCount) begin
            NewData <= 1'b1;
            State   <= Done;
          end

          BitCount <= BitCount + 1'b1;
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

