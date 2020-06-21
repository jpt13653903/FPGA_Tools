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

module LCD(
 input       nReset,
 input       Clk, // Max 4 MHz

 input       RAM_Clk,
 input  [1:0]Line,
 input  [4:0]Address,
 input  [7:0]Data,
 input       Latch,

 output reg      RS,
 output reg      E,
 output reg [7:4]D);
//------------------------------------------------------------------------------
 
 // Delay Constants at Clk = 4 MHz
 parameter d_100ms = 19'h61A7F; // 100 ms
 parameter d_10ms  = 19'h09C3F; //  10 ms
 parameter d_50us  = 19'h000C7; //  50 us
//------------------------------------------------------------------------------

 // State Constants
 parameter WriteByte   = 4'd08;
 parameter WriteNibble = 4'd10;
 parameter ResetLCD    = 4'd12;
 parameter Delay       = 4'd15;
//------------------------------------------------------------------------------

 reg  [ 3:0]state;
 reg  [ 3:0]retstate;
 reg  [18:0]count;
 
 reg  [ 7:0]tdata;

 wire [ 6:0]tWrAddress;
 wire [ 6:0]tRdAddress;

 reg  [ 1:0]RdLine;
 reg  [ 4:0]RdAddress;
 wire [ 7:0]RdData;
//------------------------------------------------------------------------------

 assign tWrAddress = {Line  ,   Address};
 assign tRdAddress = {RdLine, RdAddress};
 
 LCD_RAM RAM(
  .wrclock  (RAM_Clk),
  .data     (Data),
  .wraddress(tWrAddress),
  .wren     (Latch),

  .rdclock  (!Clk),
  .rdaddress(tRdAddress),
  .q        (RdData)
 );
//------------------------------------------------------------------------------

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   state     <= 0;
   retstate  <= 0;
   count     <= 0;
   tdata     <= 0;

   RdLine    <= 0;
   RdAddress <= 0;
   
   RS        <= 0;
   E         <= 0;
   D         <= 0;
//------------------------------------------------------------------------------

  end else begin
   case(state)
    4'd00: begin
     count    <= d_100ms;
     retstate <= ResetLCD;
     state    <= Delay;
    end
//------------------------------------------------------------------------------

    4'd01: begin
     tdata    <= 8'h02; // 4-bit Interface (From 8-bit Mode)
     retstate <= 4'd02;
     state    <= WriteNibble;
    end
//------------------------------------------------------------------------------

    4'd02: begin
     tdata    <= 8'h2F; // 4-bit Interface; 2 Lines, 5x10 Dots
     retstate <= 4'd03;
     state    <= WriteByte;
    end
//------------------------------------------------------------------------------

    4'd03: begin
     tdata    <= 8'h0C; // Display On; Cursor Off
     retstate <= 4'd04;
     state    <= WriteByte;
    end
//------------------------------------------------------------------------------

    4'd04: begin
     tdata    <= 8'h01; // Clear Display
     retstate <= 4'd05;
     state    <= WriteByte;
    end
//------------------------------------------------------------------------------

    4'd05: begin
     count    <= d_10ms; 
     retstate <= 4'd06;
     state    <= Delay;
    end
//------------------------------------------------------------------------------
// Copy RAM Data to LCD continuously
//------------------------------------------------------------------------------

    4'd06: begin
     RS <= 1'b0; // Command Mode

     case(RdLine)
      2'd0: tdata <= 8'h80; // Set LCD Address to 0x00
      2'd1: tdata <= 8'hC0; // Set LCD Address to 0x40
      2'd2: tdata <= 8'h94; // Set LCD Address to 0x14
      2'd3: tdata <= 8'hD4; // Set LCD Address to 0x54
      default:;
     endcase

     retstate <= 4'd07;
     state    <= WriteByte;
    end
//------------------------------------------------------------------------------

    4'd07: begin
     RS    <= 1'b1; // Data Mode
     tdata <= RdData;
     
     if(RdAddress == 5'h13) begin
      RdLine    <= RdLine + 1'b1;
      RdAddress <= 0;
      retstate  <= 4'd06;
     end else begin
      RdAddress <= RdAddress + 1'b1;
      retstate  <= 4'd07;
     end

     state <= WriteByte;
    end
//------------------------------------------------------------------------------
// Write to LCD and wait 50 us
//------------------------------------------------------------------------------

    WriteByte: begin
     E       <= 1'b1;
     D       <= tdata[7:4];
     state   <= 4'd09;
    end
//------------------------------------------------------------------------------

    4'd09: begin
     E       <= 1'b0;
     state   <= WriteNibble;
    end
//------------------------------------------------------------------------------

    WriteNibble: begin
     E     <= 1'b1;
     D     <= tdata[3:0];
     state <= 4'd11;
    end
//------------------------------------------------------------------------------

    4'd11: begin
     E     <= 1'b0;
     count <= d_50us;
     state <= Delay;
    end
//------------------------------------------------------------------------------
// Reset LCD
//------------------------------------------------------------------------------

    ResetLCD: begin
     tdata    <= 8'h03;
     retstate <= 4'd13;
     state    <= WriteNibble;
    end
//------------------------------------------------------------------------------

    4'd13: begin
     tdata    <= 8'h03;
     retstate <= 4'd14;
     state    <= WriteNibble;
    end
//------------------------------------------------------------------------------

    4'd14: begin
     tdata    <= 8'h03;
     retstate <= 4'd01;
     state    <= WriteNibble;
    end
//------------------------------------------------------------------------------
// Delay
//------------------------------------------------------------------------------

    Delay: begin
     if(~|count) state <= retstate;
     count <= count - 1'b1;
    end
//------------------------------------------------------------------------------

    default:;
   endcase
  end
 end
endmodule
//------------------------------------------------------------------------------
