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

// J Taylor
// Last modified 2012-12-07
//------------------------------------------------------------------------------

// This is an abstraction of the SD-Card physical interface.

// "Busy" remains high until "Execute" goes low.
// CRC checks are performed on both read and write.
//   Data is re-read or re-written on a CRC fault
// Set DataLength to zero when no data is to be transferred.
// Leave "DataRnW" high unless data is to be written.

// The data is double-buffered. Buffers are swaped:
// > on the rising edge of "Busy" when executing a command with "DataRnW" low.
// > when reading from the card is finished and "Execute" is low.
//------------------------------------------------------------------------------

// Todo:
// > Rewrite so that the command and data lines run separately:
//   Two different modules, one called ttSD_DataBus,
//   Other called SD_CMDBus
//------------------------------------------------------------------------------

module SD_Bus(
 input             nReset,
 input             Clk,          // max 50 MHz
 input             Buffer_Clock, // >= Clk
 
 input      [  6:0]ClockDiv,     // the card clock is Clk / 
                                 // 2xClockDiv + 2
 
 input      [  5:0]Command,
 input      [ 31:0]Argument,
 input      [  1:0]ResponseType, // 0 = none,
                                 // 1 = short,
                                 // 2 = long,
                                 // 3 = only data: used for multi read / write
 output reg        ResponseCRC,
  
 input             DataRnW,
 input             SwapOnWrite,
 input      [  8:0]DataLength,    // No of bytes - 1
 output reg        DataCRC,
 
 input             Execute,
 output reg        Busy,
 
 output reg [127:0]Response,     // use [39:0] for short
 
 input      [  8:0]DataAddress,
 input      [  7:0]DataIn,
 input             DataLatch,
 output     [  7:0]DataOut,
 
 inout      [  3:0]SD_Data,
 inout             SD_CMD,
 inout             SD_Clk);
//------------------------------------------------------------------------------

 reg          tSD_CMD;
 reg         ttSD_CMD;

 reg  [  3:0] tSD_Data;
 reg  [  3:0]ttSD_Data;

 reg  [  4:0]state;
 reg  [  7:0]count;
 reg  [  6:0]clkcount;
 
 reg  [ 39:0]cmd;
 reg         cmdRnW;
 
 reg  [127:0]tResponse;
 reg  [ 23:0]TimeOut;
 
 reg  [  2:0]datastate;
 reg  [  8:0]DataRdCount;
 reg  [  8:0]DataWrCount;

 reg         RamSelect;

 reg  [  7:0]tDataIn;
 reg  [  8:0]tDataRdAddress;
 reg  [  8:0]tDataWrAddress;
 reg         tDataLatch;
 wire [  7:0]tDataOut;

 wire [  7:0]DataIn0;
 wire [  8:0]DataRdAddress0;
 wire [  8:0]DataWrAddress0;
 wire        DataLatch0;
 wire [  7:0]DataOut0;

 wire [  7:0]DataIn1;
 wire [  8:0]DataRdAddress1;
 wire [  8:0]DataWrAddress1;
 wire        DataLatch1;
 wire [  7:0]DataOut1;

 reg         DataBusy;
 reg         DataWaiting;
 
 reg  [  3:0]tData;
 reg         tDataRnW;
 
 reg  [  6:0]crc7;
 reg  [ 15:0]crc16_0;
 reg  [ 15:0]crc16_1;
 reg  [ 15:0]crc16_2;
 reg  [ 15:0]crc16_3;
 reg  [ 31:0]crc16_4;
 reg  [ 31:0]crc16_5;
 reg  [ 31:0]crc16_6;
 reg  [ 31:0]crc16_7;
 
 reg        tSD_Clk;
//------------------------------------------------------------------------------

 SD_RAM SD_RAM0(
  .data     (DataIn0),
  .rdaddress(DataRdAddress0),
  .rdclock  (!Buffer_Clock),
  .wraddress(DataWrAddress0),
  .wrclock  (!Buffer_Clock),
  .wren     (DataLatch0),
  .q        (DataOut0)
 );
//------------------------------------------------------------------------------

 SD_RAM SD_RAM1(
  .data     (DataIn1),
  .rdaddress(DataRdAddress1),
  .rdclock  (!Buffer_Clock),
  .wraddress(DataWrAddress1),
  .wrclock  (!Buffer_Clock),
  .wren     (DataLatch1),
  .q        (DataOut1)
 );
//------------------------------------------------------------------------------

 assign DataIn0        = (!RamSelect) ? DataIn      : tDataIn;
 assign DataRdAddress0 = (!RamSelect) ? DataAddress : tDataRdAddress;
 assign DataWrAddress0 = (!RamSelect) ? DataAddress : tDataWrAddress;
 assign DataLatch0     = (!RamSelect) ? DataLatch   : tDataLatch;

 assign DataIn1        = ( RamSelect) ? DataIn      : tDataIn;
 assign DataRdAddress1 = ( RamSelect) ? DataAddress : tDataRdAddress;
 assign DataWrAddress1 = ( RamSelect) ? DataAddress : tDataWrAddress;
 assign DataLatch1     = ( RamSelect) ? DataLatch   : tDataLatch;

 assign DataOut        = (!RamSelect) ? DataOut0    : DataOut1;
 assign tDataOut       = ( RamSelect) ? DataOut0    : DataOut1;
//------------------------------------------------------------------------------

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   state          <= 5'h1F;
   count          <= 0;
   clkcount       <= 7'h7F;
   
   cmd            <= 0;
   cmdRnW         <= 1'b1;
   
   tResponse      <= 0;
   TimeOut        <= 24'h_00_00_FF;
   ResponseCRC    <= 0;
   
   datastate      <= 0;
   DataWaiting    <= 0;
   DataRdCount    <= 0;
   DataWrCount    <= 0;
   DataCRC        <= 0;
   
   RamSelect      <= 0;
   
   tDataIn        <= 0;
   tDataRdAddress <= 0;
   tDataWrAddress <= 0;
   tDataLatch     <= 0;
   DataBusy       <= 0;
   
   tData          <= 4'hF;
   tDataRnW       <= 1'b1;
   
   crc7           <= 0;
   crc16_0        <= 0;
   crc16_1        <= 0;
   crc16_2        <= 0;
   crc16_3        <= 0;
   crc16_4        <= 0;
   crc16_5        <= 0;
   crc16_6        <= 0;
   crc16_7        <= 0;
   
   Busy           <= 1'b1;
   Response       <= 0;
   
   tSD_Clk        <= 0;
//------------------------------------------------------------------------------

  end else begin
   if((~|clkcount) && (~&ClockDiv)) begin
    tSD_Clk   <= ~tSD_Clk;
    clkcount  <= ClockDiv;
    
    // Delay incoming communication lines for signal integrity during clock edge
     tSD_CMD  <=  SD_CMD;
    ttSD_CMD  <= tSD_CMD;
     tSD_Data <=  SD_Data;
    ttSD_Data <= tSD_Data;

    case(state)
     5'h00: begin
      if(!Execute) begin
       Busy        <= 1'b0;
       tDataRnW    <= 1'b1;
       DataWaiting <= 1'b0;
       state       <= 5'h01;
      end
     end
//------------------------------------------------------------------------------

     5'h01: begin
      if((Execute) && (tSD_Clk)) begin
       Busy        <= 1'b1;
       count       <= 8'd39;
       tDataRnW    <= DataRnW;
       DataCRC     <= 1'b0;
       DataWaiting <= 1'b1;

       if((!DataRnW) && (SwapOnWrite)) begin
        RamSelect <= ~RamSelect;
       end

       if(ResponseType == 2'd3) begin // pure data, no command
        ResponseCRC <= 1'b1;
        if(DataRnW) begin
         TimeOut <= 24'hFFFFFF; // 420 ms
         state   <= 5'h09;
        end else begin
         TimeOut <= 24'hFFFFFF; // 420 ms
         state   <= 5'h0B;
        end
       end else begin // A command

        cmd         <= {2'b01, Command, Argument};
        cmdRnW      <= 1'b0;
        crc7        <= 0;
        ResponseCRC <= 1'b0;
        state       <= 5'h02;
       end
      end
     end
//------------------------------------------------------------------------------

     // Rising Edge
     5'h02: begin
      crc7 <= {crc7[5:3], 
              (crc7[  2]^ (cmd[39] ^ crc7[6])),
               crc7[1:0], (cmd[39] ^ crc7[6])};
      state <= 5'h03;
     end
//------------------------------------------------------------------------------

     // Falling Edge
     5'h03: begin
      if(~|count) begin
       count      <= 8'h07;
       cmd[39:32] <= {crc7, 1'b1};
       state      <= 5'h04;
      
      end else begin
       count <= count - 1'b1;
       cmd   <= {cmd[38:0], 1'b0};
       state <= 5'h02;
      end
     end
//------------------------------------------------------------------------------

     // Rising Edge
     5'h04: begin
      state <= 5'h05;
     end
//------------------------------------------------------------------------------

     // Falling Edge
     5'h05: begin
      Response <= 0;

      if(~|count) begin
       cmdRnW <= 1'b1;
       case(ResponseType)
        2'd1: begin // Short
         count   <= 8'd47;
         TimeOut <= 24'd255;
         state   <= 5'h06;
        end
        
        2'd2: begin // Long
         count   <= 8'd135;
         TimeOut <= 24'd255;
         state   <= 5'h06;
        end
        
        default: begin // No response
         ResponseCRC <= 1'b1;
         state       <= 5'h1E;
        end
       endcase

      end else begin
       count <= count - 1'b1;
       cmd   <= {cmd[38:0], 1'b0};
       state <= 5'h04;
      end
     end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

     // Rising Edge
     5'h06: begin // Get Response
      tResponse <= 0;
      crc7      <= 0;
       
      if((!tSD_Clk) && (!ttSD_CMD)) begin
       state <= 5'h07;
      end else if(~|TimeOut) begin
       state <= 5'h00;
      end
       
      TimeOut <= TimeOut - 1'b1;
     end
//------------------------------------------------------------------------------

     // Falling Edge
     5'h07: begin
      count <= count - 1'b1;
      state <= 5'h08;
     end
//------------------------------------------------------------------------------

     // Rising Edge
     5'h08: begin
      if((count > 8'h07) && (count < 8'h80)) begin
       crc7 <= {crc7[5:3], 
               (crc7[  2]^ (ttSD_CMD ^ crc7[6])),
                crc7[1:0], (ttSD_CMD ^ crc7[6])};
      end

      if(~|count) begin
       Response <= {tResponse[126:0], ttSD_CMD};
       
       if({tResponse[6:0], ttSD_CMD} == {crc7, 1'b1}) begin
        ResponseCRC <= 1'b1;
       end
       
       if(~|DataLength) begin
        state <= 5'h1E;
       end else if(tDataRnW) begin
        TimeOut <= 24'hFFFFFF; // 420 ms
        state   <= 5'h09;
       end else begin
        TimeOut <= 24'hFFFFFF; // 420 ms
        state   <= 5'h0B;
       end
       
      end else begin
       tResponse <= {tResponse[126:0], ttSD_CMD};
       state     <= 5'h07;
      end
     end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

     5'h09: begin // Wait for read to start
      if(DataBusy) begin
       DataWaiting <= 1'b0;
       state       <= 5'h0A;
      end else if(~|TimeOut) begin
       ResponseCRC <= 1'b0;
       DataCRC     <= 1'b0;
       state       <= 5'h00;
      end
      TimeOut <= TimeOut - 1'b1;
     end
//------------------------------------------------------------------------------

     5'h0A: begin // Wait for read to finish
      if((!DataBusy) && (!Execute)) begin
       if((crc16_4[31:16] == crc16_4[15:0]) &&
          (crc16_5[31:16] == crc16_5[15:0]) &&
          (crc16_6[31:16] == crc16_6[15:0]) &&
          (crc16_7[31:16] == crc16_7[15:0]) ) begin
        DataCRC <= 1'b1;
       end
       RamSelect <= ~RamSelect;
       state     <= 5'h00;
      end
     end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

     // Falling Edge
     5'h0B: begin // Write buffer to card
      if(tSD_Clk) begin
       DataWrCount    <= DataLength;
       tDataRdAddress <= 0;
       crc16_0        <= 0;
       crc16_1        <= 0;
       crc16_2        <= 0;
       crc16_3        <= 0;
       count          <= 8'h06;
       state          <= 5'h0C;
      end
     end
//------------------------------------------------------------------------------

     // Rising Edge
     5'h0C: begin // wait 3 clock rising edges
      if(~|count) begin
       state <= 5'h0D;
      end
      count <= count - 1'b1;
     end
//------------------------------------------------------------------------------

     // Falling Edge, then Rising Edge
     5'h0D: begin // transmit "0000"
      tData <= 4'h0;
      if(!tSD_Clk) begin
       state <= 5'h0F;
      end
     end
//------------------------------------------------------------------------------

     // Rising Edge
     5'h0E: begin // transmit data
      crc16_0 <= {crc16_0[14:12], 
                 (crc16_0[   11]^ (tData[0] ^ crc16_0[15])),
                  crc16_0[10: 5],
                 (crc16_0[    4]^ (tData[0] ^ crc16_0[15])),
                  crc16_0[ 3: 0], (tData[0] ^ crc16_0[15])};
      crc16_1 <= {crc16_1[14:12], 
                 (crc16_1[   11]^ (tData[1] ^ crc16_1[15])),
                  crc16_1[10: 5],
                 (crc16_1[    4]^ (tData[1] ^ crc16_1[15])),
                  crc16_1[ 3: 0], (tData[1] ^ crc16_1[15])};
      crc16_2 <= {crc16_2[14:12], 
                 (crc16_2[   11]^ (tData[2] ^ crc16_2[15])),
                  crc16_2[10: 5],
                 (crc16_2[    4]^ (tData[2] ^ crc16_2[15])),
                  crc16_2[ 3: 0], (tData[2] ^ crc16_2[15])};
      crc16_3 <= {crc16_3[14:12], 
                 (crc16_3[   11]^ (tData[3] ^ crc16_3[15])),
                  crc16_3[10: 5],
                 (crc16_3[    4]^ (tData[3] ^ crc16_3[15])),
                  crc16_3[ 3: 0], (tData[3] ^ crc16_3[15])};

      if(~|DataWrCount) begin
       DataWrCount <= 9'd16;
       state <= 5'h12;
      end else begin
       DataWrCount <= DataWrCount - 1'b1;
       state       <= 5'h0F;
      end
     end
//------------------------------------------------------------------------------

     // Falling Edge
     5'h0F: begin // transmit data
      tData <= tDataOut[7:4];
      state <= 5'h10;
     end
//------------------------------------------------------------------------------

     //  Rising Edge
     5'h10: begin // transmit data
      crc16_0 <= {crc16_0[14:12], 
                 (crc16_0[   11]^ (tData[0] ^ crc16_0[15])),
                  crc16_0[10: 5],
                 (crc16_0[    4]^ (tData[0] ^ crc16_0[15])),
                  crc16_0[ 3: 0], (tData[0] ^ crc16_0[15])};
      crc16_1 <= {crc16_1[14:12], 
                 (crc16_1[   11]^ (tData[1] ^ crc16_1[15])),
                  crc16_1[10: 5],
                 (crc16_1[    4]^ (tData[1] ^ crc16_1[15])),
                  crc16_1[ 3: 0], (tData[1] ^ crc16_1[15])};
      crc16_2 <= {crc16_2[14:12], 
                 (crc16_2[   11]^ (tData[2] ^ crc16_2[15])),
                  crc16_2[10: 5],
                 (crc16_2[    4]^ (tData[2] ^ crc16_2[15])),
                  crc16_2[ 3: 0], (tData[2] ^ crc16_2[15])};
      crc16_3 <= {crc16_3[14:12], 
                 (crc16_3[   11]^ (tData[3] ^ crc16_3[15])),
                  crc16_3[10: 5],
                 (crc16_3[    4]^ (tData[3] ^ crc16_3[15])),
                  crc16_3[ 3: 0], (tData[3] ^ crc16_3[15])};
      state <= 5'h11;
     end
//------------------------------------------------------------------------------

     // Falling Edge
     5'h11: begin // transmit data
      tData          <= tDataOut[3:0];
      tDataRdAddress <= tDataRdAddress + 1'b1;
      state          <= 5'h0E;
     end
//------------------------------------------------------------------------------

     // Falling Edge
     5'h12: begin // transmit crc16
      if(~|DataWrCount[4:0]) begin
       tData <= 4'hF;
       state <= 5'h14;
      end else begin
       tData <= {crc16_3[15], crc16_2[15], crc16_1[15], crc16_0[15]};
       state <= 5'h13;
      end
     end
//------------------------------------------------------------------------------

     // Rising Edge
     5'h13: begin // transmit crc16
      crc16_0     <= {crc16_0[14:0], 1'b0};
      crc16_1     <= {crc16_1[14:0], 1'b0};
      crc16_2     <= {crc16_2[14:0], 1'b0};
      crc16_3     <= {crc16_3[14:0], 1'b0};
      DataWrCount <= DataWrCount - 1'b1;
      state       <= 5'h12;
     end
//------------------------------------------------------------------------------

     // Rising Edge
     5'h14: begin // transmit "1111"
      state <= 5'h15;
     end
//------------------------------------------------------------------------------

     5'h15: begin // set output to high Z
      tDataRnW <= 1'b1;
      if((!tSD_Clk) && (!ttSD_Data[0])) begin
       count       <= 8'h00;
       DataWrCount <= 9'd4;
       state       <= 5'h16;
      end else if(~|TimeOut) begin
       ResponseCRC <= 1'b0;
       DataCRC     <= 1'b0;
       state       <= 5'h00;
      end
      TimeOut <= TimeOut - 1'b1;
     end
//------------------------------------------------------------------------------

     // Falling Edge
     5'h16: begin // Read CRC Status
      if(~|DataWrCount[2:0]) begin
       if(count[3:0] == 4'b0101) begin // CRC Correct
        DataCRC <= 1'b1;
       end
       state <= 5'h1E;
       
      end else begin
       state <= 5'h17;
      end
      
      DataWrCount <= DataWrCount - 1'b1;
     end
//------------------------------------------------------------------------------

     // Rising Edge
     5'h17: begin // Read CRC Status
      count <= {count[6:0], ttSD_Data[0]};
      state <= 5'h16;
     end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

     5'h1E: begin // wait while busy
      TimeOut <= 24'd16;
      
      if((!tSD_Clk) && (ttSD_Data[0])) begin
       state <= 5'h1F;
      end
     end
//------------------------------------------------------------------------------

     5'h1F: begin // Must wait 8 clock cycles between commands
      if(~|TimeOut) begin
       state <= 5'h00;
      end
      
      TimeOut <= TimeOut - 1'b1;
     end
//------------------------------------------------------------------------------

     default:;
    endcase
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

    case(datastate)
     3'd0: begin
      if(( !tSD_Clk) && ( tDataRnW ) &&
         (~|ttSD_Data) && (|DataLength) ) begin
       DataRdCount    <= DataLength;
       tDataWrAddress <= 9'h1FF;
       DataBusy       <= 1'b1;
       crc16_4        <= 0;
       crc16_5        <= 0;
       crc16_6        <= 0;
       crc16_7        <= 0;
       datastate      <= 3'd1;
      end
     end
//------------------------------------------------------------------------------

     // Falling Edge
     3'd1: begin
      datastate <= 3'd2;
     end
//------------------------------------------------------------------------------

     // Rising Edge
     3'd2: begin
      tDataLatch   <= 1'b0;
      tDataIn[7:4] <= ttSD_Data;
      crc16_4 <={crc16_4[30:12],
                (crc16_4[   11]^ (ttSD_Data[0] ^ crc16_4[15])),
                 crc16_4[10: 5],
                (crc16_4[    4]^ (ttSD_Data[0] ^ crc16_4[15])),
                 crc16_4[ 3: 0], (ttSD_Data[0] ^ crc16_4[15])};
      crc16_5 <={crc16_5[30:12],
                (crc16_5[   11]^ (ttSD_Data[1] ^ crc16_5[15])),
                 crc16_5[10: 5],
                (crc16_5[    4]^ (ttSD_Data[1] ^ crc16_5[15])),
                 crc16_5[ 3: 0], (ttSD_Data[1] ^ crc16_5[15])};
      crc16_6 <={crc16_6[30:12],
                (crc16_6[   11]^ (ttSD_Data[2] ^ crc16_6[15])),
                 crc16_6[10: 5],
                (crc16_6[    4]^ (ttSD_Data[2] ^ crc16_6[15])),
                 crc16_6[ 3: 0], (ttSD_Data[2] ^ crc16_6[15])};
      crc16_7 <={crc16_7[30:12],
                (crc16_7[   11]^ (ttSD_Data[3] ^ crc16_7[15])),
                 crc16_7[10: 5],
                (crc16_7[    4]^ (ttSD_Data[3] ^ crc16_7[15])),
                 crc16_7[ 3: 0], (ttSD_Data[3] ^ crc16_7[15])};
      datastate <= 3'd3;
     end
//------------------------------------------------------------------------------

     // Falling Edge
     3'd3: begin
      tDataWrAddress <= tDataWrAddress + 1'b1;
      datastate      <= 3'd4;
     end
//------------------------------------------------------------------------------

     // Rising Edge
     3'd4: begin
      tDataIn[3:0] <= ttSD_Data;
      crc16_4 <={crc16_4[30:12],
                (crc16_4[   11]^ (ttSD_Data[0] ^ crc16_4[15])),
                 crc16_4[10: 5],
                (crc16_4[    4]^ (ttSD_Data[0] ^ crc16_4[15])),
                 crc16_4[ 3: 0], (ttSD_Data[0] ^ crc16_4[15])};
      crc16_5 <={crc16_5[30:12],
                (crc16_5[   11]^ (ttSD_Data[1] ^ crc16_5[15])),
                 crc16_5[10: 5],
                (crc16_5[    4]^ (ttSD_Data[1] ^ crc16_5[15])),
                 crc16_5[ 3: 0], (ttSD_Data[1] ^ crc16_5[15])};
      crc16_6 <={crc16_6[30:12],
                (crc16_6[   11]^ (ttSD_Data[2] ^ crc16_6[15])),
                 crc16_6[10: 5],
                (crc16_6[    4]^ (ttSD_Data[2] ^ crc16_6[15])),
                 crc16_6[ 3: 0], (ttSD_Data[2] ^ crc16_6[15])};
      crc16_7 <={crc16_7[30:12],
                (crc16_7[   11]^ (ttSD_Data[3] ^ crc16_7[15])),
                 crc16_7[10: 5],
                (crc16_7[    4]^ (ttSD_Data[3] ^ crc16_7[15])),
                 crc16_7[ 3: 0], (ttSD_Data[3] ^ crc16_7[15])};
      datastate <= 3'd5;
     end
//------------------------------------------------------------------------------

     // Falling Edge
     3'd5: begin
      tDataLatch <= 1'b1;

      if(~|DataRdCount) begin
       DataRdCount <= 9'd15;
       datastate   <= 3'd6;
      end else begin
       DataRdCount <= DataRdCount - 1'b1;
       datastate   <= 3'd2;
      end
     end
//------------------------------------------------------------------------------

     // Rising Edge
     3'd6: begin // Read CRC
      tDataLatch <= 1'b0;
      
      if(!tSD_Clk) begin

       if(~|DataRdCount[3:0]) begin
        datastate <= 3'd7;
       end
       
       crc16_4 <= {crc16_4[30:0], ttSD_Data[0]};
       crc16_5 <= {crc16_5[30:0], ttSD_Data[1]};
       crc16_6 <= {crc16_6[30:0], ttSD_Data[2]};
       crc16_7 <= {crc16_7[30:0], ttSD_Data[3]};

       DataRdCount <= DataRdCount - 1'b1;
      end
     end
//------------------------------------------------------------------------------

     3'd7: begin // Wait for the command to finish
      if(!DataWaiting) begin
       DataBusy  <= 1'b0;
       datastate <= 3'd0;
      end
     end
//------------------------------------------------------------------------------

     default:;
    endcase
//------------------------------------------------------------------------------

   end else begin
    clkcount <= clkcount - 1'b1;
   end
  end
 end
//------------------------------------------------------------------------------

 assign SD_Clk  = tSD_Clk;
 assign SD_CMD  = (!cmdRnW  ) ? cmd[39] : 1'bZ;
 assign SD_Data = (!tDataRnW) ? tData   : 4'bZZZZ;
endmodule
//------------------------------------------------------------------------------
