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
// Last modified 2010-08-03
//------------------------------------------------------------------------------

// This is an abstracion of the SD-Card. It sopports:
// > Version 1.X up to 2 GB
// > Version 2.0 Standard Capacity up to 2 GB
// > Version 2.0 High Capacity up to 8 GB

// "Busy" remains high until both "BlockRead" and "BlockWrite" are low.
// Use "BlockRead" and "BlockWrite" one at a time.
// A block is 512 Bytes.
// When a card becomes unresponsive (or is replaced), 
//   "CardError" goes high and process goes into reset.
//   To recover, make "CardPresent" low and then high.

// The data is double-buffered. Buffers are swaped:
// > on the rising edge of "Busy" when writing.
// > when reading from the card is finished and "BlockRead" is low.

// When writing multiple blocks, pull BlockMultiWrite high and wait
// for BlockMultiWriting to go high.  Keep the Busy in mind as well.
//------------------------------------------------------------------------------

module SD_Card_Multi_Write(
 input            nReset,
 input            Clk,          // max 50 MHz
 input            Buffer_Clock, // >= Clk
  
 input            CardPresent,
 output reg       CardError,
 
 output reg [17:0]Allocation_Unit, // Allocation unit size, in 512 byte blocks
 input      [31:0]BlockEraseStart,
 input      [31:0]BlockEraseEnd,
 input            BlockErase,
 
 output reg [31:0]BlockMaxAddress,
 input      [31:0]BlockAddress,
 input            BlockRead,
 input            BlockWrite,
 output           Busy,

 input            BlockMultiWrite,
 output reg       BlockMultiWriting,
 
 input      [ 8:0]DataAddress,
 input      [ 7:0]DataIn,
 input            DataLatch,
 output     [ 7:0]DataOut,
  
 inout      [ 3:0]SD_Data,
 inout            SD_CMD,
 output           SD_Clk);
//------------------------------------------------------------------------------

 reg  [  4:0]state;
 reg  [  4:0]retstate;
 reg  [ 25:0]TimeOut;
 
 reg         tBusy;

 reg  [  6:0]ClockDiv;
 reg  [  5:0]Command;
 reg  [ 31:0]Argument;
 reg  [  1:0]ResponseType;
 wire        ResponseCRC;

 reg         DataRnW;
 reg         SwapOnWrite;
 reg  [  8:0]DataLength;
 wire        DataCRC;
 
 reg         Execute;
 wire        BusBusy;
 wire [127:0]Response;
 
 reg  [  8:0]tDataAddress;
 reg         InternalRead;
 
 reg  [  1:0]CardVersion;
 reg  [ 31:0]OCR;
 reg  [ 15:0]RCA;

 reg  [  1:0]CSD_STRUCTURE;
 reg  [  3:0]CSD_READ_BL_LEN;
 reg  [  7:0]CSD_TRAN_SPEED;
 reg  [  8:0]CSD_SECTOR_SIZE;
 reg  [ 21:0]CSD_C_SIZE;
 reg  [  2:0]CSD_C_SIZE_MULT;
 
 reg  [  3:0]AU_SIZE;
 
 reg  [ 31:0]BLOCK_NR;
 reg  [ 19:0]MAX_CLOCK; // kHz
 
 reg  [ 13:0]A;
 reg  [  6:0]B;
 wire [ 20:0]Y;
//------------------------------------------------------------------------------

 assign Y    = A * B;
 assign Busy = BusBusy | tBusy;
//------------------------------------------------------------------------------
 
 always @(*) begin
  case(AU_SIZE)
   4'h0: Allocation_Unit <= CSD_SECTOR_SIZE;
   4'h1: Allocation_Unit <= 18'd_____32; //  16 kB
   4'h2: Allocation_Unit <= 18'd_____64; //  32 kB
   4'h3: Allocation_Unit <= 18'd____128; //  64 kB
   4'h4: Allocation_Unit <= 18'd____256; // 128 kB
   4'h5: Allocation_Unit <= 18'd____512; // 256 kB
   4'h6: Allocation_Unit <= 18'd__1_024; // 512 kB
   4'h7: Allocation_Unit <= 18'd__2_048; //   1 MB
   4'h8: Allocation_Unit <= 18'd__4_096; //   2 MB
   4'h9: Allocation_Unit <= 18'd__8_192; //   4 MB
   4'hA: Allocation_Unit <= 18'd_16_384; //   8 MB
   4'hB: Allocation_Unit <= 18'd_24_576; //  12 MB
   4'hC: Allocation_Unit <= 18'd_32_768; //  16 MB
   4'hD: Allocation_Unit <= 18'd_49_152; //  24 MB
   4'hE: Allocation_Unit <= 18'd_65_536; //  32 MB
   4'hF: Allocation_Unit <= 18'd131_072; //  64 MB
  endcase
 end
//------------------------------------------------------------------------------

 SD_Bus SD_Bus1(
  nReset,
  Clk,
  Buffer_Clock,
 
  ClockDiv,
 
  Command,
  Argument,
  ResponseType,
  ResponseCRC,
   
  DataRnW,
  SwapOnWrite,
  DataLength,
  DataCRC,
 
  Execute,
  BusBusy,
 
  Response,
 
  InternalRead ? tDataAddress : DataAddress,
  DataIn,
  DataLatch,
  DataOut,
 
  SD_Data,
  SD_CMD,
  SD_Clk
 );
//------------------------------------------------------------------------------

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   state           <= 0;
   retstate        <= 0;
   
   CardError       <= 1'b0;
   
   tBusy           <= 1'b1;
   BlockMaxAddress <= 0;
   TimeOut         <= 26'd39_999; // 40e6 => 1 ms
   
   BlockMultiWriting <= 0;
   
   ClockDiv        <= 7'h7F; // Disabled
   Command         <= 0;
   Argument        <= 0;
   ResponseType    <= 0;
   DataRnW         <= 1'b1;
   SwapOnWrite     <= 1'b1;
   DataLength      <= 0;
   Execute         <= 1'b0;
   
   tDataAddress    <= 0;
   InternalRead    <= 0;
   
   CardVersion     <= 0;
   OCR             <= 0;
   RCA             <= 0;
   CSD_STRUCTURE   <= 0;
   CSD_READ_BL_LEN <= 0;
   CSD_TRAN_SPEED  <= 0;
   CSD_SECTOR_SIZE <= 0;
   CSD_C_SIZE      <= 0;
   CSD_C_SIZE_MULT <= 0;
   
   AU_SIZE         <= 0;
   
   BLOCK_NR        <= 0;
   MAX_CLOCK       <= 0;
   
   A               <= 0;
   B               <= 0;
//------------------------------------------------------------------------------
// Initialisation
//------------------------------------------------------------------------------

  end else begin
   case(state)
    5'h00: begin
     Command      <= 0;      // Soft Reset
     Argument     <= 0;
     ResponseType <= 0;      // None
     retstate     <= 5'h01;
     if(CardPresent) begin
      ClockDiv <= 7'd124;    // 200 kHz
      if(~|TimeOut) begin
       state <= 5'h1C;
      end
      TimeOut <= TimeOut - 1'b1;
     end else begin
      TimeOut <= 26'd39_999; // 40e6 => 1 ms
     end
    end
//------------------------------------------------------------------------------

    5'h01: begin
     Command      <= 6'd8;
     Argument     <= 32'h00_00_01_AA;
     ResponseType <= 2'd1;     // R7
     retstate     <= 5'h02;
     state        <= 5'h1C;
    end
//------------------------------------------------------------------------------

    5'h02: begin
     if(ResponseCRC) begin   // Version 2.00 or later
      CardVersion  <= 2'd2;
      state        <= 5'h03;

     end else begin          // Standard Card
      CardVersion  <= 2'd1;
      Command      <= 6'd0;  // Soft Reset
      Argument     <= 0;
      ResponseType <= 2'd0;  // None
      retstate     <= 5'h03;
      state        <= 5'h1C;
     end
    end
//------------------------------------------------------------------------------

    5'h03: begin
     if(!OCR[31]) begin
      Command      <= 6'd55;  // Next Command is Application Specific
      Argument     <= 0;
      ResponseType <= 2'd1;   // R1
      retstate     <= 5'h04;
      state        <= 5'h1C;
     end else begin
      Command      <= 6'd2;   // Read Card Identification Register
      Argument     <= 0;
      ResponseType <= 2'd2;   // R2
      retstate     <= 5'h06;
      state        <= 5'h1C;
     end
    end
//------------------------------------------------------------------------------

    5'h04: begin
     Command      <= 6'd41; // Set Operating Voltage
     ResponseType <= 2'd1;  // R3
     if(CardVersion == 2'd1) begin
      Argument    <= 32'h00_30_00_00;
     end else begin
      Argument    <= 32'h40_30_00_00;
     end
     retstate     <= 5'h05;
     if(ResponseCRC) begin  // Valid response
      state <= 5'h1C;
     end else begin         // No response
      state <= 5'h1B;       // Reset
     end
    end
//------------------------------------------------------------------------------

    5'h05: begin
     OCR <= Response[39:8];
     if(&Response[7:0]) begin // Valid response
      state <= 5'h03;
     end else begin
      state <= 5'h1B;         // Reset
     end
    end
//------------------------------------------------------------------------------

    5'h06: begin
     // Store CID here if required
     
     Command      <= 6'd3; // Read Relative Card Address
     Argument     <= 0;
     ResponseType <= 2'd1; // R6
     retstate     <= 5'h07;
     if(ResponseCRC) begin // Valid response
      state <= 5'h1C;
     end else begin        // No response
      state <= 5'h1B;      // Reset
     end
    end
//------------------------------------------------------------------------------

    5'h07: begin
     RCA <= Response[39:24];
     
     Command      <= 6'd9; // Read Card Specific Data Register
     Argument     <= {Response[39:24], 16'h0000};
     ResponseType <= 2'd2; // R2
     retstate     <= 5'h08;
     if(ResponseCRC) begin // Valid response
      state <= 5'h1C;
     end else begin        // No response
      state <= 5'h1B;      // Reset
     end
    end
//------------------------------------------------------------------------------

    5'h08: begin
     CSD_STRUCTURE   <= Response[127:126];
     CSD_TRAN_SPEED  <= Response[103: 96];
     CSD_READ_BL_LEN <= Response[ 83: 80];
     CSD_SECTOR_SIZE <= Response[ 45: 39] + 9'd1;

     case(Response[127:126])
      2'b00: begin // Standard Capacity
       CSD_C_SIZE_MULT <=         Response[49:47];
       BLOCK_NR        <= {18'd0, Response[73:62], 2'd0} + 3'b100;
      end
      
      2'b01: begin // High Capacity
       CSD_C_SIZE_MULT <= 3'd0;
       BLOCK_NR        <= {Response[69:48], 10'd0} + 11'h400;
      end
      
      default:;
     endcase
     
     if(ResponseCRC) begin // Valid response
      state <= 5'h09;
     end else begin
      state <= 5'h1B;      // Reset
     end
    end
//------------------------------------------------------------------------------

    5'h09: begin
     if(~|CSD_C_SIZE_MULT) begin
      state           <= 5'h0A;
     end else begin
      BLOCK_NR        <= {BLOCK_NR[30:0], 1'b0};
      CSD_C_SIZE_MULT <= CSD_C_SIZE_MULT - 1'b1;
     end
    end
//------------------------------------------------------------------------------

    5'h0A: begin
     case(CSD_READ_BL_LEN)
      4'h9: begin //  512 Byte Block
       BlockMaxAddress <=  BLOCK_NR - 1'b1;
      end
      
      4'hA: begin // 1024 Byte Block
       BLOCK_NR        <= {BLOCK_NR[30:0], 1'b0};
       BlockMaxAddress <= {BLOCK_NR[30:0], 1'b0} - 1'b1;
       CSD_SECTOR_SIZE <= {1'b0, CSD_SECTOR_SIZE[6:0], 1'b0};
      end
      
      4'hB: begin // 2048 Byte Block
       BLOCK_NR        <= {BLOCK_NR[29:0], 2'd0};
       BlockMaxAddress <= {BLOCK_NR[29:0], 2'd0} - 1'b1;
       CSD_SECTOR_SIZE <= {CSD_SECTOR_SIZE[6:0], 2'b00};
      end
      
      default: begin
       BLOCK_NR        <= 0;
       BlockMaxAddress <= 0;
      end
     endcase     
     
     case(CSD_TRAN_SPEED[2:0])
      3'b000:  A <= 14'd____10;
      3'b001:  A <= 14'd___100;
      3'b010:  A <= 14'd_1_000;
      3'b011:  A <= 14'd10_000;
      default: A <= 0;
     endcase
     
     case(CSD_TRAN_SPEED[6:3])
      4'h1:    B <= 7'd10;
      4'h2:    B <= 7'd12;
      4'h3:    B <= 7'd13;
      4'h4:    B <= 7'd15;
      4'h5:    B <= 7'd20;
      4'h6:    B <= 7'd25;
      4'h7:    B <= 7'd30;
      4'h8:    B <= 7'd35;
      4'h9:    B <= 7'd40;
      4'hA:    B <= 7'd45;
      4'hB:    B <= 7'd50;
      4'hC:    B <= 7'd55;
      4'hD:    B <= 7'd60;
      4'hE:    B <= 7'd70;
      4'hF:    B <= 7'd80;
      default: B <= 0;
     endcase
     
     state <= 5'h0B;
    end
//------------------------------------------------------------------------------

    5'h0B: begin
     MAX_CLOCK <= Y[19:0];

     if(Y >= 20'd20_000) begin // 20 MHz
      ClockDiv <= 0;
     end
     
     Command      <= 6'd7; // Set to Transfer State
     Argument     <= {RCA, 16'd0};
     ResponseType <= 2'd1;     // R1b
     retstate     <= 5'h0C;
     state        <= 5'h1C;
    end
//------------------------------------------------------------------------------

    5'h0C: begin
     Command      <= 6'd16; // Set Block Length to 512 Bytes
     Argument     <= 32'h00_00_02_00;
     ResponseType <= 2'd1;  // R1
     retstate     <= 5'h0D;
     if(ResponseCRC) begin  // Valid response
      state        <= 5'h1C;
     end else begin         // No response
      state <= 5'h1B;       // Reset
     end
    end
//------------------------------------------------------------------------------

    5'h0D: begin
     Command      <= 6'd55; // Next Command is Application Specific
     Argument     <= {RCA, 16'd0};
     ResponseType <= 2'd1;  // R1
     retstate     <= 5'h0E;
     if(ResponseCRC) begin  // Valid response
      state       <= 5'h1C;
     end else begin         // No response
      state       <= 5'h1B; // Reset
     end
    end
//------------------------------------------------------------------------------

    5'h0E: begin
     Command      <= 6'd6;   // Set Data Width to 4 Lines
     Argument     <= 32'h00_00_00_02;
     ResponseType <= 2'd1;   // R1
     if(CardVersion == 1'b1) begin
      retstate     <= 5'h15;
     end else begin
      retstate     <= 5'h0F;
     end
     if(ResponseCRC) begin   // Valid response
      state        <= 5'h1C;
     end else begin          // No response
      state        <= 5'h1B; // Reset
     end
    end
//------------------------------------------------------------------------------

    5'h0F: begin
     Command      <= 6'd55; // Next Command is Application Specific
     Argument     <= {RCA, 16'd0};
     ResponseType <= 2'd1;  // R1
     
     retstate     <= 5'h10;
     if(ResponseCRC) begin  // Valid response
      state       <= 5'h1C;
     end else begin         // No response
      state       <= 5'h1B; // Reset
     end
    end
//------------------------------------------------------------------------------

    5'h10: begin
     Command      <= 6'd13; // Get SD Status
     Argument     <= 0;
     ResponseType <= 2'd1;  // R1
     DataRnW      <= 1'b1;
     DataLength    <= 9'h3F;
     InternalRead <= 1'b1;
     tDataAddress <= 9'h35; // AU_Size

     retstate     <= 5'h11;
     if(ResponseCRC) begin  // Valid response
      state       <= 5'h1C;
     end else begin         // No response
      state       <= 5'h1B; // Reset
     end
    end
//------------------------------------------------------------------------------

    5'h11: begin
     DataLength <= 0;
     AU_SIZE   <= DataOut[7:4];

     if(ResponseCRC && DataCRC) begin
      state <= 5'h15;
     end else begin
      state <= 5'h1B;
     end
    end
//------------------------------------------------------------------------------

    5'h15: begin
     InternalRead <= 0;
     
     if((!BlockRead) && (!BlockWrite)) begin
      tBusy <= 1'b0;
      state <= 5'h16;
     end
    end
//------------------------------------------------------------------------------
// Normal Operation
//------------------------------------------------------------------------------

    5'h16: begin
     if(ResponseCRC && CardPresent) begin // Valid response
      if(~|TimeOut) begin
       TimeOut      <= 26'd39_999_999; // 40e6 => 1 sec
       Command      <= 6'd13;          // Get Status
       Argument     <= {RCA, 16'd0};
       ResponseType <= 2'd1;           // R1
       DataRnW      <= 1'b1;
       DataLength   <= 0;
       retstate     <= 5'h16;
       state        <= 5'h1C;
       
      end else if((BlockEraseStart <= BlockEraseEnd) && 
                  (BlockEraseEnd   <  BLOCK_NR     ) && 
                  BlockErase                        ) begin
       TimeOut      <= 26'd39_999_999; // 40e6 => 1 sec
       Command      <= 6'd32;          // Set erase start
       ResponseType <= 2'd1;           // R1
       if(~|CSD_STRUCTURE) begin
        Argument <= {BlockEraseStart[22:0], 9'd0};
       end else begin
        Argument <= BlockEraseStart;
       end
       DataRnW      <= 1'b1;
       DataLength   <= 0;
       tBusy        <= 1'b1;
       retstate     <= 5'h18;
       state        <= 5'h1C;
       
      end else if((BlockAddress < BLOCK_NR) && 
                  BlockRead) begin
       TimeOut      <= 26'd39_999_999; // 40e6 => 1 sec
       Command      <= 6'd17;          // Read Data
       ResponseType <= 2'd1;           // R1
       if(~|CSD_STRUCTURE) begin
        Argument <= {BlockAddress[22:0], 9'd0};
       end else begin
        Argument <= BlockAddress;
       end
       DataRnW      <= 1'b1;
       DataLength   <= 9'h1FF;
       tBusy        <= 1'b1;
       retstate     <= 5'h17;
       state        <= 5'h1C;
      
      end else if((BlockAddress < BLOCK_NR) && 
                  BlockWrite) begin
       TimeOut      <= 26'd39_999_999; // 40e6 => 1 sec on 25 MHz clock
       Command      <= 6'd24;          // Write Data
       if(BlockMultiWriting)begin
        ResponseType <= 2'd3;           // No command
       end else begin
        ResponseType <= 2'd1;           // R1
       end
       if(~|CSD_STRUCTURE) begin                                                 
        Argument <= {BlockAddress[22:0], 9'd0};
       end else begin
        Argument <= BlockAddress;
       end
       DataRnW      <= 1'b0;
       DataLength   <= 9'h1FF;
       // The buffer swop depends on busy timing, so no busy set here.
       retstate     <= 5'h17;
       state        <= 5'h1C;
      
      end else if((BlockAddress < BLOCK_NR) && 
                  !BlockMultiWriting && 
                  BlockMultiWrite) begin
       TimeOut      <= 26'd39_999_999; // 40e6 => 1 sec
       Command      <= 6'd25;          // Write multiple blocks
       ResponseType <= 2'd1;           // R1
       if(~|CSD_STRUCTURE) begin
        Argument <= {BlockAddress[22:0], 9'd0};
       end else begin
        Argument <= BlockAddress;
       end
       DataRnW           <= 1'b1;
       DataLength        <= 0;
       BlockMultiWriting <= 1'b1;
       tBusy             <= 1'b1;
       retstate          <= 5'h16;
       state             <= 5'h1C;
      
      end else if(BlockMultiWriting && 
                  !BlockMultiWrite) begin
       TimeOut           <= 26'd39_999_999; // 40e6 => 1 sec
       Command           <= 6'd12;          // Stop transfer
       ResponseType      <= 2'd1;           // R1b
       DataRnW           <= 1'b1;
       DataLength        <= 0;
       BlockMultiWriting <= 1'b0;
       tBusy             <= 1'b1;
       retstate          <= 5'h16;
       state             <= 5'h1C;

      end else begin
       tBusy   <= 1'b0;
       TimeOut <= TimeOut - 1'b1;
      end
      
     end else begin   // No response
      state <= 5'h1B; // Reset
     end
    end
//------------------------------------------------------------------------------
     
    5'h17: begin // Finish block Read / Write
     if(ResponseCRC) begin
      if(DataCRC) begin
       tBusy       <= 1'b0;
       SwapOnWrite <= 1'b1;
       state       <= 5'h16;
      end else begin
       TimeOut     <= 26'd39_999_999; // 40e6 => 1 sec
       SwapOnWrite <= 1'b0;
       state       <= 5'h1C;
      end
     end else begin
      state <= 5'h1B;
     end
    end
//------------------------------------------------------------------------------
     
    5'h18: begin // Finish Erase operation
     TimeOut      <= 26'd39_999_999; // 40e6 => 1 sec
     Command      <= 6'd33;          // Set erase end
     ResponseType <= 2'd1;           // R1
     if(~|CSD_STRUCTURE) begin
      Argument <= {BlockEraseEnd[22:0], 9'd0};
     end else begin
      Argument <= BlockEraseEnd;
     end

     retstate <= 5'h19;
     if(ResponseCRC) begin
      state <= 5'h1C;
     end else begin
      state <= 5'h1B;
     end
    end
//------------------------------------------------------------------------------
     
    5'h19: begin 
     TimeOut      <= 26'd39_999_999; // 40e6 => 1 sec
     Command      <= 6'd38;          // Erase
     ResponseType <= 2'd1;           // R1b
     
     retstate <= 5'h16;
     if(!BlockErase) begin
      if(ResponseCRC) begin
       state <= 5'h1C;
      end else begin
       state <= 5'h1B;
      end
     end
    end
//------------------------------------------------------------------------------
// Reset
//------------------------------------------------------------------------------

    5'h1B: begin
     retstate        <= 0;
   
     tBusy           <= 1'b1;
     BlockMaxAddress <= 0;
     TimeOut         <= 26'd39_999; // 40e6 => 1 ms
   
     BlockMultiWriting <= 0;
   
     ClockDiv        <= 7'h7F; // Disabled
     Command         <= 0;
     Argument        <= 0;
     ResponseType    <= 0;
     DataRnW         <= 1'b1;
     SwapOnWrite     <= 1'b1;
     DataLength      <= 0;
     Execute         <= 1'b0;
   
     tDataAddress    <= 0;
     InternalRead    <= 0;

     CardVersion     <= 0;
     OCR             <= 0;
     RCA             <= 0;
     CSD_STRUCTURE   <= 0;
     CSD_READ_BL_LEN <= 0;
     CSD_TRAN_SPEED  <= 0;
     CSD_SECTOR_SIZE <= 0;
     CSD_C_SIZE      <= 0;
     CSD_C_SIZE_MULT <= 0;
     
     AU_SIZE         <= 0;
   
     BLOCK_NR        <= 0;
     MAX_CLOCK       <= 0;
   
     A               <= 0;
     B               <= 0;
     
     if(!CardPresent) begin
      CardError <= 1'b0;
      state     <= 5'h00;
     end else begin
      CardError <= 1'b1;
     end
    end
//------------------------------------------------------------------------------
// Execute Command
//------------------------------------------------------------------------------

    5'h1C: begin
     if(!BusBusy) begin
      Execute <= 1'b1;
      state   <= 5'h1D;
     end
    end
//------------------------------------------------------------------------------

    5'h1D: begin
     if(BusBusy) begin
      tBusy <= 1'b1;
      state <= 5'h1E;
     end
    end
//------------------------------------------------------------------------------

    5'h1E: begin
     if((!BlockRead) && (!BlockWrite)) begin
      Execute <= 1'b0;
      state   <= 5'h1F;
     end
    end
//------------------------------------------------------------------------------

    5'h1F: begin
     if(!BusBusy) begin
      state <= retstate;
     end
    end
//------------------------------------------------------------------------------

    default:;
   endcase
  end
 end
endmodule
//------------------------------------------------------------------------------
