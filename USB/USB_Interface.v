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

// The interface works on two words:
//   The first is "R_nW : 7-bit address"
//   The second is the data.

// Within a page, addresses 0x00 and 0x7F -> 0xFF is not accesable
// through the USB interface

// Address "0x00" is the current page, or MSB of the final 16-bit address
// Address "0x7F" has the value of ID, "0xAB" by default
//------------------------------------------------------------------------------

module USB_Interface(
  input  nReset,
  input  RS232_Clk,
  input  Handle_Clk,
  
  output reg Mutex_Request,
  input      Mutex_Grant,

  output     [15:0]Address,
  output reg       Latch,
  output reg [ 7:0]DataIn,
  input      [ 7:0]DataOut,

  output Tx,
  input  Rx);
//------------------------------------------------------------------------------

  parameter ID        = 8'hAB; // Returned on 0xFF
  parameter CountBits = 5;     // Default parameters for 50 MHz clock and 3 Mbaud
  parameter Count0_5  = 5'd_8; // f_Clk / BAUD / 2
  parameter Count1    = 5'd17; // f_Clk / BAUD
  parameter Count1_5  = 5'd25; // f_Clk / BAUD * 1.5
//------------------------------------------------------------------------------

  reg  [7:0]USB_TxData;
  reg       USB_Send;
  wire      USB_Busy;
  wire [9:0]USB_TxCount;

  wire      USB_DataReady;
  wire [9:0]USB_RxCount;
  wire [7:0]USB_RxData;
  reg       USB_Ack;
  wire      USB_AckBusy;
//------------------------------------------------------------------------------

  reg  [2:0]state;
  reg       R_nW;
//------------------------------------------------------------------------------

  reg  [ 7:0]Page;
  reg  [ 6:0]tAddress;
//------------------------------------------------------------------------------

  RS232_FIFO #(
    CountBits,
    Count0_5,
    Count1 ,
    Count1_5
  )USB(
    nReset,
    RS232_Clk,
    RS232_Clk,

    USB_TxData,
    USB_Send,
    USB_Busy,
    USB_TxCount,

    USB_RxCount,
    USB_RxData,
    USB_Ack,
    USB_AckBusy,
 
    Tx,
    Rx
  );
 
  assign USB_DataReady = |USB_RxCount;
//------------------------------------------------------------------------------

  always @(negedge nReset, posedge Handle_Clk) begin
    if(!nReset) begin
      state         <= 0;
      Mutex_Request <= 0;
      USB_TxData    <= 0;
      USB_Send      <= 0;
      USB_Ack       <= 0;
      R_nW          <= 1'b1;
//------------------------------------------------------------------------------

      Page     <= 0;
      tAddress <= 0;
      Latch    <= 0;
      DataIn   <= 0;
//------------------------------------------------------------------------------

    end else begin
      case(state)
        3'd0: begin
          USB_Send <= 1'b0;
          Latch    <= 1'b0;
          if((!USB_AckBusy) && USB_DataReady) begin
            {R_nW, tAddress} <= USB_RxData;
            if((~|USB_RxData[6:0]) || (&USB_RxData[6:0])) begin
              USB_Ack <= 1'b1;
              state   <= 3'd1;
            end else begin
              Mutex_Request <= 1'b1;
              if(Mutex_Grant) begin
                USB_Ack <= 1'b1;
                state   <= 3'd1;
              end
            end
          end else begin
            Mutex_Request <= 1'b0;
          end
        end
//------------------------------------------------------------------------------

        3'd1: begin
          if(USB_AckBusy) begin
            USB_Ack <= 1'b0;
            state   <= 3'd2;
          end
        end
//------------------------------------------------------------------------------
     
        3'd2: begin     
          if(R_nW) begin
            if(!USB_Busy) begin
              if(&tAddress) begin
                USB_TxData <= ID;
              end else if(~|tAddress) begin
                USB_TxData <= Page;
              end else begin
                USB_TxData <= DataOut;
              end
              Mutex_Request <= 1'b0;
              state         <= 3'd4;
            end
      
          end else begin
            if((!USB_AckBusy) && USB_DataReady) begin
              DataIn  <= USB_RxData;
              USB_Ack <= 1'b1;
              if(&tAddress) begin
                state <= 3'd3;
              end else if(~|tAddress) begin
                Page  <= USB_RxData;
                state <= 3'd3;
              end else begin
                state <= 3'd5;
              end
            end
          end
        end
//------------------------------------------------------------------------------

        3'd3: begin
          if(USB_AckBusy) begin
            USB_Ack <= 1'b0;
            state   <= 3'd0;
          end
        end
//------------------------------------------------------------------------------

        3'd4: begin
          USB_Send <= 1'b1;
          if(USB_Busy) begin
            state <= 3'd0;
          end
        end
//------------------------------------------------------------------------------

        3'd5: begin
          Latch <= 1'b1;
          if(USB_AckBusy) begin
            USB_Ack <= 1'b0;
            state   <= 3'd0;
          end
        end
//------------------------------------------------------------------------------

        default:;
      endcase
    end
  end
//------------------------------------------------------------------------------

  assign Address = {Page, 1'b0, tAddress};
endmodule
//------------------------------------------------------------------------------
