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

// Abstraction of 8x AT25640 EEPROM ICs, connected in parallel and selected
// by means of the nCS lines.
//------------------------------------------------------------------------------

// To read:
// 1 Set up the address
// 2 Wait for not Busy
// 3 Make RdLatch high
// 4 Wait for Busy
// 5 Make RdLatch low
// 6 Wait for Busy to clear
// 7 RdData valid

// To Write:
// 1 Set up the address and data
// 2 Wait for not Busy
// 3 Make WrLatch high
// 4 Wait for Busy
// 5 Make WrLatch low
//------------------------------------------------------------------------------

module EEPROM(
  input nReset,
  input Clk, // 10 MHz max

  input [15:0]Address,

  output reg [7:0]RdData,
  input           RdLatch,

  input  [7:0]WrData,
  input       WrLatch,

  output reg Busy,

  output reg [7:0]NCS,
  output reg      SCK,
  output          SI,
  input           SO);

  reg [ 4:0]state;
  reg [ 4:0]WaitReturn;
  reg [ 4:0]StatusReturn;
  reg [ 4:0]RWReturn;
  reg [ 7:0]tNCS;
  reg [15:0]tAddress;
  reg [ 7:0]tData;
  reg [ 7:0]lData;
  reg [ 2:0]Count;
//------------------------------------------------------------------------------

  always @(*) begin
    case(tAddress[2:0])
      3'b000 : tNCS <= 8'b11111110;
      3'b001 : tNCS <= 8'b11111101;
      3'b010 : tNCS <= 8'b11111011;
      3'b011 : tNCS <= 8'b11110111;
      3'b100 : tNCS <= 8'b11101111;
      3'b101 : tNCS <= 8'b11011111;
      3'b110 : tNCS <= 8'b10111111;
      3'b111 : tNCS <= 8'b01111111;
      default: tNCS <= 8'b11111111;
    endcase
  end
//------------------------------------------------------------------------------

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      state      <= 0;
      WaitReturn <= 0;
      Count      <= 0;
      NCS        <= 8'hFF;
      tData      <= 0;
      lData      <= 0;
      tAddress   <= 0;
      SCK        <= 0;
      tData      <= 8'h01;
      Busy       <= 1'b1;
//------------------------------------------------------------------------------

    end else begin
      case(state)
        5'b00000: begin // Check status register and fix if necessary
          NCS <= 8'b11111111;
          if(tData[0]) begin
            StatusReturn <= 5'b00000; // Check Status
            state        <= 5'b00111; // Read SR
          end else if(tData[7] || tData[3] || tData[2]) begin
            StatusReturn <= 5'b00001;
            state        <= 5'b01100; // Write enable
          end else begin
            state <= 5'b00010;
          end
        end
//------------------------------------------------------------------------------

        5'b00001: begin
          NCS      <= tNCS;
          tData    <= 8'h01;   // Write Status Register
          RWReturn <= 5'b00011;
          state    <= 5'b11100; // Write tData
        end
//------------------------------------------------------------------------------

        5'b00011: begin
          tData    <= 8'h02;   // No write protection
          RWReturn <= 5'b00010;
          state    <= 5'b11100; // Write tData
        end
//------------------------------------------------------------------------------

        5'b00010: begin
          if(&tAddress[2:0]) begin
            state <= 5'b00110; // Wait for operation
          end else begin
            tData <= 8'h01;
            state <= 5'b00000;
          end
          tAddress[2:0] <= tAddress[2:0] + 1'b1;
        end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

        5'b00110: begin // Wait for operation
          if(!Busy && RdLatch) begin // Read
            tAddress   <= Address;
            WaitReturn <= 5'b01111; // Read from address
            tData      <= 8'h01;
            state      <= 5'b00100; // Wait for ready
            Busy       <= 1'b1;
          end else if(!Busy && WrLatch) begin // Write
            tAddress   <= Address;
            lData      <= WrData;
            WaitReturn <= 5'b01000; // Write to address
            tData      <= 8'h01;
            state      <= 5'b00100; // Wait for ready
            Busy       <= 1'b1;
          end else if(!RdLatch && !WrLatch) begin
            Busy <= 1'b0;
          end
        end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

        5'b00111: begin // Read SR
          NCS      <= tNCS;
          tData    <= 8'b00000101;
          RWReturn <= 5'b00101;
          state    <= 5'b11100; // Write tData
        end
//------------------------------------------------------------------------------

        5'b00101: begin
          RWReturn <= StatusReturn;
          state    <= 5'b11111; // Read tData
        end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

        5'b00100: begin // Wait for ready
          NCS <= 8'hFF;
     
          if(tData[0]) begin
            StatusReturn <= 5'b00100; // Wait for ready
            state        <= 5'b00111; // Read SR
          end else begin
            state <= WaitReturn;
          end
        end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

        5'b01100: begin // Write enable
          NCS      <= tNCS;
          tData    <= 8'b00000110;
          RWReturn <= 5'b01101;
          state    <= 5'b11100; // Write tData
        end
//------------------------------------------------------------------------------

        5'b01101: begin
          NCS   <= 8'hFF;
          state <= StatusReturn;
        end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

        5'b01111: begin // Read from address
          NCS      <= tNCS;
          tData    <= 8'h03;    // Read data from memory array
          RWReturn <= 5'b01110;
          state    <= 5'b11100; // Write tData
        end
//------------------------------------------------------------------------------

        5'b01110: begin
          tData    <= {3'b000, tAddress[15:11]};
          RWReturn <= 5'b01010;
          state    <= 5'b11100; // Write tData
        end
//------------------------------------------------------------------------------

        5'b01010: begin
          tData    <= tAddress[10:3];
          RWReturn <= 5'b01011;
          state    <= 5'b11100; // Write tData
        end
//------------------------------------------------------------------------------

        5'b01011: begin
          RWReturn <= 5'b01001;
          state    <= 5'b11111; // Read tData
        end
//------------------------------------------------------------------------------

        5'b01001: begin
          NCS    <= 8'hFF;
          RdData <= tData;
          state  <= 5'b00110; // Wait for operation
        end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

        5'b01000: begin // Write to address
          StatusReturn <= 5'b11000;
          state        <= 5'b01100; // Write enable
        end
//------------------------------------------------------------------------------

        5'b11000: begin
          NCS      <= tNCS;
          tData    <= 8'h02;    // Write data to memory array
          RWReturn <= 5'b11001;
          state    <= 5'b11100; // Write tData
        end
//------------------------------------------------------------------------------

        5'b11001: begin
          tData    <= {3'b000, tAddress[15:11]};
          RWReturn <= 5'b11011;
          state    <= 5'b11100; // Write tData
        end
//------------------------------------------------------------------------------

        5'b11011: begin
          tData    <= tAddress[10:3];
          RWReturn <= 5'b11010;
          state    <= 5'b11100; // Write tData
        end
//------------------------------------------------------------------------------

        5'b11010: begin
          tData    <= lData;
          RWReturn <= 5'b11110;
          state    <= 5'b11100; // Write tData
        end
//------------------------------------------------------------------------------

        5'b11110: begin
          NCS   <= 8'hFF;
          state <= 5'b00110; // Wait for operation
        end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

        5'b11111: begin // Read tData
          SCK      <= 1'b1;
          tData    <= {tData[6:0], SO};
          state    <= 5'b11101;
        end
//------------------------------------------------------------------------------

        5'b11101: begin
          SCK <= 1'b0;
          if(&Count) begin
            state <= RWReturn;
          end else begin
            state <= 5'b11111; // Read tData
          end
          Count <= Count + 1'b1;
        end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

        5'b11100: begin // Write tData
          SCK   <= 1'b1;
          state <= 5'b10100;
        end
//------------------------------------------------------------------------------

        5'b10100: begin
          SCK   <= 1'b0;
          tData <= {tData[6:0], 1'b0};
     
          if(&Count) begin
            state <= RWReturn;
          end else begin
            state <= 5'b11100; // Write tData
          end
     
          Count <= Count + 1'b1;
        end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

        default:;
      endcase
    end
  end
//------------------------------------------------------------------------------

  assign SI = tData[7];
endmodule
//------------------------------------------------------------------------------
