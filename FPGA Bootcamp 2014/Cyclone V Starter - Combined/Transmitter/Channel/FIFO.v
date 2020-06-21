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

module FIFO(
  input Reset,
  input Clk, // Run this on the SD_Card clock

  input  [40:0]Address,
  output [ 7:0]Data,
  output       Data_Valid,

  output reg Mutex_Request,
  input      Mutex_Grant,

  output reg [31:0]SD_Block,
  output reg       SD_Read,
  input            SD_Busy,

  input [8:0]SD_Address,
  input [7:0]SD_Data,
  input      SD_Write_Enable
);
//------------------------------------------------------------------------------

FIFO_RAM RAM(
  .clock    (Clk),

  .wraddress({SD_Block[0], SD_Address}),
  .data     (SD_Data),
  .wren     (SD_Write_Enable),

  .rdaddress(Address[9:0]),
  .q        (Data)
);
//------------------------------------------------------------------------------

reg [31:1]Block[0:1]; // The currently loaded blocks

assign Data_Valid = Address[9] ? 
                    Address[40:10] == Block[1] : 
                    Address[40:10] == Block[0] ;

wire [31:0]Next_Block;
wire       Next_Valid;

assign Next_Block = Address[40:9] + 1'b1;
assign Next_Valid = Next_Block[0] ? 
                    Next_Block[31:1] == Block[1] : 
                    Next_Block[31:1] == Block[0] ;
//------------------------------------------------------------------------------

reg   [1:0]State;
localparam Idle    = 2'b00;
localparam Waiting = 2'b01;
localparam Reading = 2'b11;
//------------------------------------------------------------------------------

reg tReset;

always @(posedge Clk) begin
  tReset <= Reset;

  if(tReset) begin
    State <= Idle;

    Block[0] <= {31{1'b1}}; // Choose a block unlikely to be real
    Block[1] <= {31{1'b1}}; // Choose a block unlikely to be real

    SD_Block <= 0;
    SD_Read  <= 0;

    Mutex_Request <= 0;
//------------------------------------------------------------------------------

  end else begin
    case(State)
      Idle: begin
        if(~SD_Busy) begin
          if(~Data_Valid) begin
            SD_Block      <= Address[40:9];
            SD_Read       <= 1'b1;
            Mutex_Request <= 1'b1;
            State         <= Waiting;

          end else if(~Next_Valid) begin
            SD_Block      <= Next_Block;
            SD_Read       <= 1'b1;
            Mutex_Request <= 1'b1;
            State         <= Waiting;

          end else begin
            Mutex_Request <= 1'b0;
          end
        end
      end

      Waiting: begin
        if(Mutex_Grant & SD_Busy) begin
          SD_Read <= 1'b0;
          State   <= Reading;
        end
      end

      Reading: begin
        if(~SD_Busy) begin
          if(SD_Block[0]) Block[1] <= SD_Block[31:1];
          else            Block[0] <= SD_Block[31:1];

          State <= Idle;
        end
      end

      default:;
    endcase
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

