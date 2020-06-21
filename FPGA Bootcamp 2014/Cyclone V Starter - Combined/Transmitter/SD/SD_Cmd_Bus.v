//==============================================================================
// Copyright (C) John-Philip Taylor
// jpt13653903@gmail.com
//
// This file is part of S/PDIF Radio
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

module SD_Cmd_Bus(
  input Reset,
  input Clk,    // Controller clock
  input SD_Clk, // The SD-Card clock, generated by the controller.  The real
                // clock (output to the SD-card) is delayed by one Clk cycle.

  input [ 5:0]Command,
  input [31:0]Argument,
  input [ 1:0]Response_Type, // 0, 1, 2, 3 => none, R1/6/7, R2, R3
  input       Execute,       // Make high to send command and get response

  output reg [127:8]Response,

  output reg Busy,  // High while execution busy
  output reg Error, // CRC or response time-out error, reset on next execute

  inout  reg SD_Cmd
);
//------------------------------------------------------------------------------

// States:
reg   [2:0]State;
localparam Idle         = 3'b000;
localparam Sending      = 3'b001;
localparam SendingCRC   = 3'b011;
localparam Waiting      = 3'b010;
localparam Receiving    = 3'b110;
localparam ReceivingCRC = 3'b111;
localparam Done         = 3'b101;

reg pSD_Clk;

reg tSD_Cmd;

reg [  6:0]Count;
reg [  6:0]CRC;
reg [127:0]Temp;
//------------------------------------------------------------------------------

reg tReset;

always @(posedge Clk) begin
  tReset <= Reset;

  if(tReset) begin
    State   <= Idle;
    pSD_Clk <= 0;

    Response <= 0;
    Busy     <= 0;
    Error    <= 0;
    SD_Cmd   <= 1'bZ;
    tSD_Cmd  <= 1'b1;

    Count <= 0;
    CRC   <= 0;
    Temp  <= 0;
//------------------------------------------------------------------------------
  
  end else begin
    pSD_Clk <= SD_Clk;
//------------------------------------------------------------------------------

    if(pSD_Clk & ~SD_Clk) begin // Falling edge (host to card)
      tSD_Cmd <= SD_Cmd;

      case(State)
        Idle: begin
          if(Execute) begin
            Count[5:0] <= 6'd39;
            {SD_Cmd, Temp[127:89]} <= {2'b01, Command, Argument};
            CRC   <= 7'd0;
            Busy  <= 1'b1;
            Error <= 1'b0;
            State <= Sending;
          end
        end
//------------------------------------------------------------------------------

        Sending: begin
          if(~|Count[5:0]) begin
            Count[2:0] <= 3'd7;
            {SD_Cmd, Temp[127:121]} <= {CRC, 1'b1};
            State <= SendingCRC;

          end else begin
            {SD_Cmd, Temp[127:90]} <= Temp[127:89];
            CRC <= {
              CRC[5:3], 
              CRC[  2]^ (Temp[127] ^ CRC[6]), 
              CRC[1:0], (Temp[127] ^ CRC[6])
            };
            Count[5:0] <= Count[5:0] - 1'b1;
          end
        end
//------------------------------------------------------------------------------

        SendingCRC: begin
          if(~|Count[2:0]) begin
            SD_Cmd <= 1'bZ;
            if(|Response_Type) begin
              Count <= 7'h7F; // Receive time-out
              State <= Waiting;

            end else begin
              Count[2:0] <= 3'd7;
              State      <= Done;
            end

          end else begin
            {SD_Cmd, Temp[127:122]} <= Temp[127:121];
            Count[2:0] <= Count[2:0] - 1'b1;
          end
        end
//------------------------------------------------------------------------------

        default:;
      endcase;
//------------------------------------------------------------------------------

    end else if(~pSD_Clk & SD_Clk) begin // Rising edge (card to host)
      case(State)
        Waiting: begin
          if(~|Count) begin // Time-out error
            Error <= 1'b1;
            State <= Done;
      
          end else begin
            if(~tSD_Cmd) begin
              case(Response_Type)
                2'd1,
                2'd3: Count <= 7'd38;
                2'd2: Count <= 7'd126;
                default:;
              endcase;
              CRC   <= 7'd0;
              State <= Receiving;

            end else begin
              Count <= Count - 1'b1;
            end
          end
        end
//------------------------------------------------------------------------------

        Receiving: begin
          Temp <= {Temp[126:0], tSD_Cmd};

          if(Count == 7'd120) CRC <= 0; // R2 response CRC is internal
          else                CRC <= {
            CRC[5:3], 
            CRC[  2]^ (tSD_Cmd ^ CRC[6]), 
            CRC[1:0], (tSD_Cmd ^ CRC[6])
          };

          if(~|Count) begin
            Count[2:0] <= 3'd7;
            State <= ReceivingCRC;
          end else begin
            Count <= Count - 1'b1;
          end
        end
//------------------------------------------------------------------------------

        ReceivingCRC: begin
          Temp <= {Temp[126:0], tSD_Cmd};

          if(~|Count[2:0]) begin
            Response <= Temp[126:7];

            Count[2:0] <= 3'd7;
            case(Response_Type)
              2'd1,
              2'd2: Error <= Temp[6:0] != CRC;
              default:;
            endcase
            State <= Done;
          end else begin
            Count[2:0] <= Count[2:0] - 1'b1;
          end
        end
//------------------------------------------------------------------------------
    
        Done: begin
          if(~|Count[2:0]) begin
            if(~Execute) begin
              Busy  <= 1'b0;
              State <= Idle;
            end
          end else begin
            Count[2:0] <= Count[2:0] - 1'b1;
          end
        end
//------------------------------------------------------------------------------

        default:;
      endcase
    end  
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

