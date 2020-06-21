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

module RS232_FIFO(
  input  nReset,
  input  RS232_Clk,
  input  FIFO_Clk,

  input      [7:0]TxData,
  input           Send,
  output reg      Busy,
  output reg [9:0]TxCount,

  output reg [9:0]RxCount,
  output     [7:0]RxData,
  input           Ack,
  output reg      AckBusy,
  
  output Tx,
  input  Rx);
//------------------------------------------------------------------------------
 
  parameter CountBits = 5; // Default parameters for 50 MHz clock and 3 Mbaud
  parameter Count0_5  = 5'd_8; // f_Clk / BAUD / 2
  parameter Count1    = 5'd17; // f_Clk / BAUD
  parameter Count1_5  = 5'd25; // f_Clk / BAUD * 1.5
//------------------------------------------------------------------------------

  wire [7:0]tTxData;
  reg       tSend;
  wire      tBusy;
  
  wire      tDataReady;
  wire [7:0]tRxData;
  reg       tAck;
 
  RS232 #(CountBits, Count0_5, Count1, Count1_5) Transceiver(
    nReset,
    RS232_Clk,

    tTxData,
    tSend,
    tBusy,
  
    tDataReady,
    tRxData,
    tAck,

    Tx,
    Rx
  );
//------------------------------------------------------------------------------

  reg [9:0]TxReadAddress;
  reg [9:0]TxWriteAddress;

  RS232_FIFO_RAM TxQueue(
    .clock    (!FIFO_Clk),
    .data     (TxData),
    .rdaddress(TxReadAddress),
    .wraddress(TxWriteAddress),
    .wren     (1'b1),
    .q        (tTxData)
  );
//------------------------------------------------------------------------------

  reg [9:0]RxReadAddress;
  reg [9:0]RxWriteAddress;

  RS232_FIFO_RAM RxQueue(
    .clock    (!FIFO_Clk),
    .data     (tRxData),
    .rdaddress(RxReadAddress),
    .wraddress(RxWriteAddress),
    .wren     (1'b1),
    .q        (RxData)
  );
//------------------------------------------------------------------------------

  reg [1:0]TxReadState;
  reg [1:0]TxWriteState;
  reg [1:0]RxReadState;
  reg [1:0]RxWriteState;

  always @(negedge nReset, posedge FIFO_Clk) begin
    if(!nReset) begin
      tSend <= 0;
      tAck  <= 0;
  
      TxReadAddress  <= 0;
      TxWriteAddress <= 0;
      TxCount        <= 0;
   
      RxReadAddress  <= 0;
      RxWriteAddress <= 0;
      RxCount        <= 0;
      AckBusy        <= 0;
   
      TxReadState  <= 0;
      TxWriteState <= 0;
      RxReadState  <= 0;
      RxWriteState <= 0;
//------------------------------------------------------------------------------

    end else begin
      TxCount <= TxWriteAddress - TxReadAddress;
      RxCount <= RxWriteAddress - RxReadAddress;
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
  
      case(TxReadState)
        2'd0: begin
          if(|TxCount) begin
            tSend       <= 1'b1;
            TxReadState <= 2'd1;
          end
        end
//------------------------------------------------------------------------------
    
        2'd1: begin
          if(tBusy) begin
            tSend         <= 1'b0;
            TxReadAddress <= TxReadAddress + 1'b1;
            TxReadState   <= 2'd2;
          end
        end
//------------------------------------------------------------------------------
    
        2'd2: begin // Also required to update TxCount
          if(!tBusy) begin
            TxReadState <= 2'd0;
          end
        end
//------------------------------------------------------------------------------
    
        default:;
      endcase
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
    
      case(TxWriteState)
        2'd0: begin
          if(Send) begin
            Busy          <= 1'b1;
            TxWriteState  <= 2'd1;
          end
        end
//------------------------------------------------------------------------------
    
        2'd1: begin
          TxWriteAddress <= TxWriteAddress + 1'b1;
          TxWriteState   <= 2'd2;
        end
//------------------------------------------------------------------------------
    
        2'd2: begin
          if(!Send) begin
            Busy         <= 1'b0;
            TxWriteState <= 2'd0;
          end
        end
//------------------------------------------------------------------------------
    
        default:;
      endcase
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
    
      case(RxReadState)
        2'd0: begin
          if(Ack) begin
            AckBusy       <= 1'b1;
            RxReadAddress <= RxReadAddress + 1'b1;
            RxReadState   <= 2'd1;
          end
        end
//------------------------------------------------------------------------------
    
        2'd1: begin
          if(!Ack) begin
            RxReadState <= 2'd2;
          end
        end
//------------------------------------------------------------------------------
    
        2'd2: begin // Required to update RxCount
          AckBusy     <= 1'b0;
          RxReadState <= 2'd0;
        end
//------------------------------------------------------------------------------
    
        default:;
      endcase
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
    
      case(RxWriteState)
        2'd0: begin
          if(tDataReady) begin
            RxWriteState  <= 4'd1;
          end
        end
//------------------------------------------------------------------------------
    
        2'd1: begin
          RxWriteAddress <= RxWriteAddress + 1'b1;
          tAck           <= 1'b1;
          RxWriteState   <= 4'd2;
        end
//------------------------------------------------------------------------------
    
        2'd2: begin
          tAck         <= 1'b0;
          RxWriteState <= 4'd0;
        end
//------------------------------------------------------------------------------
    
        default:;
      endcase
    end
  end
endmodule
//------------------------------------------------------------------------------
