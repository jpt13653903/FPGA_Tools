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

// Abstract for the EPCS16 configuration flash device:

// To read:
//  - Setup Sector
//  - Setup Page
//  - Set ReadPage
//  - Wait for Busy to set
//  - Clear ReadPage
//  - Wait for Busy to clear
//  - Setup the Address
//  - Read DataOut

// To write:
//  - Setup Sector
//  - Set EraseSector
//  - Wait for Busy to set
//  - Clear EraseSector
//  - Wait for Busy to clear
//  - Setup Page
//
//  - Setup Address
//  - Setup DataIn
//  - Pulse WriteAddress
//  - Repeat above 3 steps for all data in page
//
//  - Set WritePage
//  - Wait for Busy to set
//  - Clear WritePage
//  - Wait for Busy to clear
//------------------------------------------------------------------------------

module EPCS16(
 input nReset,
 input Clk, // max 40 MHz
 
 input           ReadID,
 output reg [7:0]ID,
 
 input      [4:0]Sector,
 input           EraseSector,
 input      [7:0]Page,
 input           WritePage,
 input           ReadPage,
 output reg      Busy,

 input      [7:0]Address,
 input      [7:0]DataIn,
 output     [7:0]DataOut,
 input           WriteAddress,
 
 output reg nCS,
 output reg DClk,
 output     ADSI,
 input      Data);
//------------------------------------------------------------------------------

 reg  [4:0] state;
 reg  [4:0] retstate;
 reg  [7:0] data;
 reg  [4:0] count; 
 
 reg  [4:0]tSector;
 reg  [7:0]tPage;
 reg  [7:0]tAddress;
 reg  [7:0]tDataIn;
 wire [7:0]tDataOut;
 reg       tWrite;
//------------------------------------------------------------------------------

 wire [7:0]Buffer_DataIn;
 wire [7:0]Buffer_DataOut;
 wire [7:0]Buffer_Address;
 wire      Buffer_Write;
 
 assign Buffer_Address = Busy ? tAddress : Address;
 assign Buffer_DataIn  = Busy ? tDataIn  : DataIn;
 assign Buffer_Write   = Busy ? tWrite   : WriteAddress;
 
 assign  DataOut       = Busy ? 7'd0     : Buffer_DataOut;
 assign tDataOut       =                   Buffer_DataOut;

 EPCS16_Buffer Buffer1(
  .wrclock  (!Clk),
  .data     (Buffer_DataIn),
  .wraddress(Buffer_Address),
  .wren     (Buffer_Write),
  
  .rdclock  (!Clk),
  .rdaddress(Buffer_Address),
  .q        (Buffer_DataOut)
 );
//------------------------------------------------------------------------------

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   Busy <= 1'b1;
   ID   <= 0;

   nCS  <= 1'bZ;
   DClk <= 1'bZ;
   
   state    <= 0;
   retstate <= 0;
   data     <= 0;
   count    <= 0;
   
   tSector  <= 0;
   tPage    <= 0;
   tAddress <= 0;
   tDataIn  <= 0;
   tWrite   <= 0;
//------------------------------------------------------------------------------
   
  end else begin
   case(state)
    5'd0: begin
     DClk <= 1'b0;
     
     if(Busy          && 
        !EraseSector  && 
        !WritePage    && 
        !ReadPage     && 
        !WriteAddress && 
        !ReadID) begin
      Busy <= 1'b0;
      nCS  <= 1'b1;
    
     end else if(EraseSector) begin
      tSector  <= Sector;
      Busy     <= 1'b1;
      data     <= 8'b0000_0110; // Write Enable
      count    <= 5'd7;
      nCS      <= 1'b0;
      retstate <= 5'd9;
      state    <= 5'd30;
     
     end else if(WritePage) begin
      tSector  <= Sector;
      tPage    <= Page;
      tAddress <= 7'd0;
      Busy     <= 1'b1;
      data     <= 8'b0000_0110; // Write Enable
      count    <= 5'd7;
      nCS      <= 1'b0;
      retstate <= 5'd13;
      state    <= 5'd30;
     
     end else if(ReadPage) begin
      tSector  <= Sector;
      tPage    <= Page;
      tAddress <= 7'd0;
      tWrite   <= 1'b0;
      Busy     <= 1'b1;
      data     <= 8'b0000_0011;
      count    <= 5'd7;
      nCS      <= 1'b0;
      retstate <= 5'd3;
      state    <= 5'd30;
     
     end else if(ReadID) begin
      Busy     <= 1'b1;
      data     <= 8'b1010_1011;
      count    <= 5'd31;
      nCS      <= 1'b0;
      retstate <= 5'd1;
      state    <= 5'd30;
      
     end else begin
      nCS <= 1'b1;
     end
    end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

    // Do the rest of ReadID
    5'd1: begin
     count    <= 5'd7;
     retstate <= 5'd2;
     state    <= 5'd28;
    end
//------------------------------------------------------------------------------

    5'd2: begin
     nCS   <= 1'b1;
     ID    <= data;
     state <= 5'd0;
    end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

    // Do the rest of ReadData
    5'd3: begin
     data     <= {3'd0, tSector};
     count    <= 5'd7;
     retstate <= 5'd4;
     state    <= 5'd30;
    end
//------------------------------------------------------------------------------

    5'd4: begin
     data     <= tPage;
     count    <= 5'd15; // Page plus 8 zeros
     retstate <= 5'd5;
     state    <= 5'd30;
    end
//------------------------------------------------------------------------------

    5'd5: begin
     count    <= 5'd7;
     retstate <= 5'd6;
     state    <= 5'd28;
    end
//------------------------------------------------------------------------------

    5'd6: begin
     tDataIn <= data;
     state   <= 5'd7;
    end
//------------------------------------------------------------------------------

    5'd7: begin
     tWrite  <= 1'b1;
     state   <= 5'd8;
    end
//------------------------------------------------------------------------------

    5'd8: begin
     tWrite <= 1'b0;
     
     if(&tAddress) begin
      nCS   <= 1'b1;
      state <= 5'd0;
      
     end else begin
      count    <= 5'd7;
      retstate <= 5'd6;
      state    <= 5'd28;
     end
     
     tAddress <= tAddress + 1'b1;
    end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

    // Do the rest of Erase Sector
    5'd9: begin
     nCS      <= 1'b1;
     state    <= 5'd10;
    end
//------------------------------------------------------------------------------

    5'd10: begin
     nCS      <= 1'b0;
     data     <= 8'b1101_1000;
     count    <= 5'd7;
     retstate <= 5'd11;
     state    <= 5'd30;
    end
//------------------------------------------------------------------------------

    5'd11: begin
     data     <= tSector;
     count    <= 5'd23;
     retstate <= 5'd12;
     state    <= 5'd30;
    end
//------------------------------------------------------------------------------

    5'd12: begin
     nCS   <= 1'b1;
     state <= 5'd25;
    end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

    // Do the rest of WritePage
    5'd13: begin
     nCS   <= 1'b1;
     state <= 5'd14;
    end
//------------------------------------------------------------------------------

    5'd14: begin
     nCS      <= 1'b0;
     data     <= 8'b0000_0010;
     count    <= 5'd7;
     retstate <= 5'd15;
     state    <= 5'd30;
    end
//------------------------------------------------------------------------------

    5'd15: begin
     data     <= {3'd0, tSector};
     count    <= 5'd7;
     retstate <= 5'd16;
     state    <= 5'd30;
    end
//------------------------------------------------------------------------------

    5'd16: begin
     data     <= tPage;
     count    <= 5'd15;
     retstate <= 5'd17;
     state    <= 5'd30;
    end
//------------------------------------------------------------------------------

    5'd17: begin
     data     <= tDataOut;
     count    <= 5'd7;
     state    <= 5'd30;

     if(&tAddress) retstate <= 5'd12;
     else          retstate <= 5'd17;

     tAddress <= tAddress + 1'b1;
    end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

    // Wait while busy
    5'd25: begin
     nCS      <= 1'b0;
     data     <= 8'b0000_0101;
     count    <= 5'd7;
     retstate <= 5'd26;
     state    <= 5'd30;
    end
//------------------------------------------------------------------------------

    5'd26: begin
     count    <= 5'd7;
     retstate <= 5'd27;
     state    <= 5'd28;
    end
//------------------------------------------------------------------------------

    5'd27: begin
     if(data[0]) begin
      count    <= 5'd7;
      retstate <= 5'd27;
      state    <= 5'd28;
     end else begin
      nCS   <= 1'b1;
      state <= 5'd0;
     end
    end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

    // Read "data"
    5'd28: begin
     DClk  <= 1'b1;
     data  <= {data[6:0], Data};
     state <= 5'd29;
    end
//------------------------------------------------------------------------------
    
    5'd29: begin
     DClk  <= 1'b0;
     
     if(~|count) begin
      state <= retstate;
     end else begin
      state <= 5'd28;
     end
     
     count <= count - 1'b1;
    end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

    // Write "data"
    5'd30: begin
     DClk  <= 1'b1;
     state <= 5'd31;
    end
//------------------------------------------------------------------------------
    
    5'd31: begin
     DClk  <= 1'b0;
     
     if(~|count) begin
      state <= retstate;
     end else begin
      state <= 5'd30;
     end
     
     data  <= {data[6:0], 1'b0};
     count <= count - 1'b1;
    end
//------------------------------------------------------------------------------
   
    default:;   
   endcase  
  end
 end
//------------------------------------------------------------------------------

 assign ADSI = nReset ? data[7] : 1'bZ; 
endmodule
//------------------------------------------------------------------------------
