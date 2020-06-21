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

// Read cache for the EPCS16 flash device.

// Has four 256 Byte blocks, of which the least recently used one is
// replaced upon a cache miss.

// To read data
// - Set 'Address'
// - Wait till 'Data_Valid' = 0
// - Read 'Data'

//------------------------------------------------------------------------------

module EPCS16_Read_Cache(
  input nReset,
  input Clk, // max 40 MHz

  input      [20:0]Address,
  output     [ 7:0]Data,
  output           Data_Valid,
 
  output reg       Mutex_Request,
  input            Mutex_Grant,
 
  output reg [ 4:0]EPCS16_Sector,
  output reg [ 7:0]EPCS16_Page,
  output reg       EPCS16_ReadPage,
  input            EPCS16_Busy,

  output reg [ 7:0]EPCS16_Address,
  input      [ 7:0]EPCS16_DataOut);
//------------------------------------------------------------------------------

  reg [ 2:0]state;
  reg       busy;
 
  reg [12:0]Real [3:0]; // Real page address
  reg [ 1:0]Cache[3:0]; // Cache page address
 
  reg       RAM_WrEn;
//------------------------------------------------------------------------------

  EPCS16_Cache_Buffer Buffer1(
    .clock  (!Clk),

    .rdaddress({Cache[0], Address[7:0]}),
    .q        (Data),

    .wraddress({Cache[0], EPCS16_Address}),
    .data     (EPCS16_DataOut),
    .wren     (RAM_WrEn)
  );
//------------------------------------------------------------------------------

  assign Data_Valid = (Real[0] == Address[20:8]) && !busy;
//------------------------------------------------------------------------------

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      busy          <= 1'b1;   
      Mutex_Request <= 0;

      EPCS16_Sector   <= 0;
      EPCS16_Page     <= 0;
      EPCS16_ReadPage <= 0;
      EPCS16_Address  <= 0;
   
      state <= 0;
   
      Real [0] <= 0;
      Real [1] <= 0;
      Real [2] <= 0;
      Real [3] <= 0;
   
      Cache[0] <= 2'd0;
      Cache[1] <= 2'd1;
      Cache[2] <= 2'd2;
      Cache[3] <= 2'd3;
   
      RAM_WrEn <= 0;
//------------------------------------------------------------------------------
   
    end else begin
      case(state)
        // Loads the desired page into cache
        3'd0: begin
          EPCS16_Sector         <= Real[0][12:8];
          EPCS16_Page           <= Real[0][ 7:0];
          EPCS16_ReadPage       <= 0;
          EPCS16_Address        <= 0;
          Mutex_Request         <= 1'b1;
          if(Mutex_Grant) state <= 3'd1;
        end
    
        3'd1: begin
          EPCS16_ReadPage       <= 1'b1;
          if(EPCS16_Busy) state <= 3'd2;
        end
    
        3'd2: begin
          EPCS16_ReadPage        <= 1'b0;
          if(!EPCS16_Busy) state <= 3'd3;
        end
    
        3'd3: begin
          RAM_WrEn <= 1'b1;
          state    <= 3'd4;
        end
    
        3'd4: begin
          RAM_WrEn <= 1'b0;
          if(&EPCS16_Address) begin
            state <= 3'd5;
          end else begin
            state <= 3'd3;
          end
          EPCS16_Address <= EPCS16_Address + 1'b1;
        end
//------------------------------------------------------------------------------
    
        // Manage the cache
        3'd5: begin
          Mutex_Request <= 1'b0;
     
          if         (Real[0] == Address[20:8]) begin
            busy <= 1'b0;
     
          end else if(Real[1] == Address[20:8]) begin
            busy     <= 1'b1;
            Real [0] <= Real [1];
            Real [1] <= Real [0];
            Cache[0] <= Cache[1];
            Cache[1] <= Cache[0];
       
          end else if(Real[2] == Address[20:8]) begin
            busy     <= 1'b1;
            Real [0] <= Real [2];
            Real [1] <= Real [0];
            Real [2] <= Real [1];
            Cache[0] <= Cache[2];
            Cache[1] <= Cache[0];
            Cache[2] <= Cache[1];
       
          end else if(Real[3] == Address[20:8]) begin
            busy     <= 1'b1;
            Real [0] <= Real [3];
            Real [1] <= Real [0];
            Real [2] <= Real [1];
            Real [3] <= Real [2];
            Cache[0] <= Cache[3];
            Cache[1] <= Cache[0];
            Cache[2] <= Cache[1];
            Cache[3] <= Cache[2];
       
          end else begin
            busy     <= 1'b1;
            Real [0] <= Address[20:8];
            Real [1] <= Real [0];
            Real [2] <= Real [1];
            Real [3] <= Real [2];
            Cache[0] <= Cache[3];
            Cache[1] <= Cache[0];
            Cache[2] <= Cache[1];
            Cache[3] <= Cache[2];
            state    <= 0;
          end
        end
    
        default:;
      endcase
    end
  end
endmodule
//------------------------------------------------------------------------------
