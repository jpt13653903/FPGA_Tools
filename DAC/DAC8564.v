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

module DAC8564(
 input nReset,
 input Clk, // max 50 MHz
 input Sync,

 output reg nSync,
 output reg SClk,
 output     Data,

 input [63:0]Current);
//------------------------------------------------------------------------------

 reg  [ 2:0]state;
 reg  [ 4:0]count;
 reg  [23:0]tdata;

 reg        pSync;

 reg  [ 1:0]address;

 reg  [63:0]tCurrent;
 wire [15:0]tData[3:0];
//------------------------------------------------------------------------------

 genvar g;
 generate
  for(g = 0; g < 4; g = g+1) begin: G_Data
   assign tData[g] = tCurrent[16*g+15:16*g];
  end
 endgenerate
//------------------------------------------------------------------------------

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   state <= 0;
   count <= 0;

   tdata <= 24'hFFFFFF;

   address <= 0;

   tCurrent <= 0;

   nSync <= 1'b1;
   SClk  <= 1'b1;
   
   pSync <= 1'b0;
//------------------------------------------------------------------------------

  end else begin
   case(state)
    3'b000: begin
     tdata[23] <= 1'b1;
     nSync     <= 1'b1;
     SClk      <= 1'b1;
     if(({pSync, Sync} == 2'b10) && 
        (tCurrent != Current)) begin
      tCurrent <= Current;
      address  <= 2'b00;
      state    <= 3'b001;
     end
    end
//------------------------------------------------------------------------------

    3'b001: begin
     nSync <= 1'b0;
     tdata[23:16] <= {2'b00, (address[1] & address[0]), 2'b00, address, 1'b0};
     case(address)
      2'b00: tdata[15:0] <= {~tData[3][15], tData[3][14:0]};
      2'b01: tdata[15:0] <= {~tData[2][15], tData[2][14:0]};
      2'b10: tdata[15:0] <= {~tData[1][15], tData[1][14:0]};
      2'b11: tdata[15:0] <= {~tData[0][15], tData[0][14:0]};
      default:;
     endcase
     count <= 5'd23;
     state <= 3'b101;
    end
//------------------------------------------------------------------------------

    3'b101: begin
     SClk <= 1'b0;
     if(~|count) state <= 3'b111;
     else        state <= 3'b110;
    end
//------------------------------------------------------------------------------

    3'b110: begin
     SClk  <= 1'b1;
     tdata <= {tdata[22:0], 1'b0};
     count <= count - 1'b1;
     state <= 3'b101;
    end
//------------------------------------------------------------------------------

    3'b111: begin
     tdata[23] <= 1'b1;
     nSync     <= 1'b1;
     SClk      <= 1'b1;
     if(&address) begin
      state <= 3'b000;
     end else begin
      address <= address + 1'b1;
      state   <= 3'b001;
     end
    end
//------------------------------------------------------------------------------

    default:;
   endcase
//------------------------------------------------------------------------------

   pSync <= Sync;
  end
 end
//------------------------------------------------------------------------------

 assign Data = tdata[23];
endmodule
//------------------------------------------------------------------------------
