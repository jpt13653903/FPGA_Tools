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

module CPU_Cache(
 input nReset,
 input Clk,

 input      [15:0]RdAddress,
 output reg [ 7:0]RdData,
 output           RdValid,

 input  [15:0]WrAddress,
 input  [ 7:0]WrData,
 input        WrEnable,
 output reg   WrBusy,

 output reg [15:0]EEPROM_Address,
 input      [ 7:0]EEPROM_RdData,
 output reg       EEPROM_RdLatch,
 output reg [ 7:0]EEPROM_WrData,
 output reg       EEPROM_WrLatch,
 input            EEPROM_Busy);

 reg  [ 2:0]state;
 reg  [ 2:0]retstate;
 

 reg  [ 3:0]Page_Mask;
 reg  [ 5:0]Page_CurrentPage;

 reg  [ 9:0]Page_RdAddress;
 reg  [ 9:0]Page_WrAddress;
 reg  [ 7:0]Page_WrData;
 reg  [ 3:0]Page_WrEn;

 reg  [ 5:0]Page_Page  [3:0];
 wire [ 7:0]Page_RdData[3:0];

 reg  [15:0]reading;
 reg  [ 1:0]order[3:0];
//------------------------------------------------------------------------------

 generate
  genvar g;
  for(g = 0; g < 4; g = g + 1) begin: Pages
   CPU_Page Page(
    !Clk,
    Page_WrData,
    Page_RdAddress,
    Page_WrAddress,
    Page_WrEn[g],
    Page_RdData[g]
   );
  end
 endgenerate
//------------------------------------------------------------------------------

 assign RdValid = (RdAddress == reading);
//------------------------------------------------------------------------------

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   state     <= 3'b000;
   retstate  <= 3'b100;

   EEPROM_Address <= 0;
   EEPROM_WrData  <= 0;
   EEPROM_RdLatch <= 0;
   EEPROM_WrLatch <= 0;

   Page_Mask        <= 4'b1111;
   Page_CurrentPage <= 0;

   Page_RdAddress <= 0;
   Page_WrAddress <= 0;
   Page_WrData    <= 0;
   Page_WrEn      <= 0;

   Page_Page[0] <= 0;
   Page_Page[1] <= 0;
   Page_Page[2] <= 0;
   Page_Page[3] <= 0;

   reading  <= 16'hFFFF;
   order[0] <= 2'b00;
   order[1] <= 2'b01;
   order[2] <= 2'b10;
   order[3] <= 2'b11;

   WrBusy <= 1'b1;
//------------------------------------------------------------------------------

  end else begin
   case(state)
    // Reads the desired page from EEPROM
    // Page_CurrentPage must = EEPROM_Address(15 downto 0)
    // Page_Mask must = Correct page WrEn mask
    // EEPROM_Address must = 0
    3'b000: begin
     Page_WrEn      <= 4'b0000;
     Page_WrAddress <= EEPROM_Address[9:0];
     
     if(Page_CurrentPage == EEPROM_Address[15:10]) begin
      if(!EEPROM_Busy) begin
       EEPROM_RdLatch <= 1'b1;
       state          <= 3'b001;
      end
      
     end else begin
      state <= retstate;
     end
    end
//------------------------------------------------------------------------------

    3'b001: begin
     if(EEPROM_Busy) begin
      EEPROM_RdLatch <= 1'b0;
      state          <= 3'b010;
     end
    end
//------------------------------------------------------------------------------

    3'b010: begin
     if(!EEPROM_Busy) begin
      Page_WrData <= EEPROM_RdData;
      state       <= 3'b011;
     end
    end
//------------------------------------------------------------------------------

    3'b011: begin
     Page_WrEn      <= Page_Mask;
     EEPROM_Address <= EEPROM_Address + 1'b1;
     state          <= 3'b000;
    end
//------------------------------------------------------------------------------

// Normal Operation
    3'b100: begin
     if(!RdValid) begin
      Page_RdAddress <= RdAddress[9:0];
      state <= 3'b101;
      
     end else if((!WrBusy) && (WrEnable)) begin
      WrBusy         <= 1'b1;
      EEPROM_Address <= WrAddress;
      EEPROM_WrData  <= WrData;
      Page_WrAddress <= WrAddress[9:0];
      Page_WrData    <= WrData;
      Page_Mask[0]   <= (Page_Page[0] == WrAddress[15:10]);
      Page_Mask[1]   <= (Page_Page[1] == WrAddress[15:10]);
      Page_Mask[2]   <= (Page_Page[2] == WrAddress[15:10]);
      Page_Mask[3]   <= (Page_Page[3] == WrAddress[15:10]);
      state          <= 3'b110;
      
     end else if(!WrEnable) begin
      WrBusy <= 1'b0;
     end
    end
//------------------------------------------------------------------------------

// Read the data
    3'b101: begin
     if(Page_Page[0] == RdAddress[15:10]) begin
      RdData  <= Page_RdData[0];
      reading <= RdAddress;
      if         (order[3] == 2'b00) begin
       order[3] <= order[2];
       order[2] <= order[1];
       order[1] <= order[0];
      end else if(order[2] == 2'b00) begin
       order[2] <= order[1];
       order[1] <= order[0];
      end else if(order[1] == 2'b00) begin
       order[1] <= order[0];
      end
      order[0] <= 2'b00;
      state <= 3'b100;
      
     end else if(Page_Page[1] == RdAddress[15:10]) begin
      RdData  <= Page_RdData[1];
      reading <= RdAddress;
      if         (order[3] == 2'b01) begin
       order[3] <= order[2];
       order[2] <= order[1];
       order[1] <= order[0];
      end else if(order[2] == 2'b01) begin
       order[2] <= order[1];
       order[1] <= order[0];
      end else if(order[1] == 2'b01) begin
       order[1] <= order[0];
      end
      order[0] <= 2'b01;
      state <= 3'b100;
      
     end else if(Page_Page[2] == RdAddress[15:10]) begin
      RdData  <= Page_RdData[2];
      reading <= RdAddress;
      if         (order[3] == 2'b10) begin
       order[3] <= order[2];
       order[2] <= order[1];
       order[1] <= order[0];
      end else if(order[2] == 2'b10) begin
       order[2] <= order[1];
       order[1] <= order[0];
      end else if(order[1] == 2'b10) begin
       order[1] <= order[0];
      end
      order[0] <= 2'b10;
      state <= 3'b100;
      
     end else if(Page_Page[3] == RdAddress[15:10]) begin
      RdData  <= Page_RdData[3];
      reading <= RdAddress;
      if         (order[3] == 2'b11) begin
       order[3] <= order[2];
       order[2] <= order[1];
       order[1] <= order[0];
      end else if(order[2] == 2'b11) begin
       order[2] <= order[1];
       order[1] <= order[0];
      end else if(order[1] == 2'b11) begin
       order[1] <= order[0];
      end
      order[0] <= 2'b11;
      state <= 3'b100;
      
     end else begin
      Page_CurrentPage    <= RdAddress[15:10];
      Page_Page[order[3]] <= RdAddress[15:10];
      Page_Mask           <= 4'b0001 << order[3];
      EEPROM_Address      <= {RdAddress[15:10], 10'd0};
      retstate            <= 3'b101;
      state               <= 3'b000;
     end
    end
//------------------------------------------------------------------------------

// Write the new data
    3'b110: begin
     if(!EEPROM_Busy) begin
      EEPROM_WrLatch <= 1'b1;
      Page_WrEn <= Page_Mask;
      state <= 3'b111;
     end
    end
//------------------------------------------------------------------------------

    3'b111: begin
     if(EEPROM_Busy) begin
      EEPROM_WrLatch <= 1'b0;
      Page_WrEn <= 4'b0000;
      state <= 3'b100;
     end
    end
//------------------------------------------------------------------------------

    default:;
   endcase
  end
 end
endmodule
//------------------------------------------------------------------------------
