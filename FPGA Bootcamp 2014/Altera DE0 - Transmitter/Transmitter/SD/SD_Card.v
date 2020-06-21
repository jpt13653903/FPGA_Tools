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

module SD_Card #(
  parameter Bus_Width = 4 // Either 1 or 4
)(
  input Reset,
  input Clk,

  // Control interface
  input [31:0]Block, // Block to be read into the RAM provided
  input       Read,
  output reg  Busy,
 
  // User-provided buffer
  output reg [8:0]Address,
  output reg [7:0]Data,
  output reg      Write_Enable,

  output reg Card_Error, // Reset module to clear

  // The SD-Card
  output reg SD_CLK,
  inout      SD_CMD,
  inout [3:0]SD_DAT
);
//------------------------------------------------------------------------------

`include "SD_Commands.vh"
`include "SD_Registers.vh"
//------------------------------------------------------------------------------

reg [ 5:0]Command;
reg [31:0]Argument;
reg [ 1:0]Response_Type;
reg       Execute;

wire [127:8]Response;
wire        Cmd_Busy;
wire        Cmd_Error;

SD_Cmd_Bus SD_Cmd_Bus1(
  Reset,
  Clk,
  SD_Clk,

  Command,
  Argument,
  Response_Type,
  Execute,

  Response,
  Cmd_Busy,
  Cmd_Error,

  SD_CMD
);
//------------------------------------------------------------------------------

reg [11:0]Block_Length;

reg      pData_Clk;
wire      Data_Clk;
wire [7:0]Receive_Data;
wire      Data_Busy;
wire [3:0]Data_Error;
wire      SD_Busy;

SD_Data_Bus #(Bus_Width) SD_Data_Bus1(
  Reset,
  Clk,
  SD_Clk,

  Block_Length,
  1'b0, // Send

  Data_Clk,
  Receive_Data,
  8'd0, // Send_Data

  Data_Busy,
  Data_Error,
 
  SD_DAT, 
  SD_Busy
);
//------------------------------------------------------------------------------

reg   [3:0]State;
localparam Start_Init       = 4'b0000;
localparam Send_IF          = 4'b0001;
localparam Get_Version      = 4'b0011;
localparam Get_OP1          = 4'b0010;
localparam Get_OP2          = 4'b0110;
localparam Get_CID          = 4'b0111;
localparam Set_Address      = 4'b0101;
localparam Get_CSD          = 4'b0100;
localparam Process_CSD      = 4'b1100;
localparam Set_Block_Length = 4'b1101;
localparam Set_Bus_Width1   = 4'b1111;
localparam Set_Bus_Width2   = 4'b1110;
localparam Idle             = 4'b1010;
localparam Reading          = 4'b1011;
localparam Done             = 4'b1001;
localparam Stall            = 4'b1000;

reg      SD_Clk;
reg [6:0]Count;
reg [6:0]ClkCount;

reg [7:0]StartupCount;

reg [15:0]RCA;
reg [ 1:0]CardVersion;
reg [ 1:0]SCD_Structure;
//------------------------------------------------------------------------------

reg tReset;

always @(posedge Clk) begin
  tReset <= Reset;

  if(tReset) begin
    SD_Clk    <= 0;
    SD_CLK    <= 0;
    Count     <= 7'h7F;
    ClkCount  <= 7'h7F;
    pData_Clk <= 0;

    StartupCount <= 0;

    Busy         <= 0;
    Address      <= 0;
    Data         <= 0;
    Write_Enable <= 0;
    Card_Error   <= 0;

    Command       <= 0;
    Argument      <= 0;
    Response_Type <= 0;
    Execute       <= 0;

    Block_Length  <= 0;

    RCA           <= 0;
    CardVersion   <= 0;
    SCD_Structure <= 0;

    State <= Start_Init;
//------------------------------------------------------------------------------

  end else begin
    if(~|Count) begin
      Count  <= ClkCount;
      SD_Clk <= ~SD_Clk;

      if(~&StartupCount) StartupCount <= StartupCount + 1'b1;

    end else begin
      Count  <= Count - 1'b1;
    end
    SD_CLK <= SD_Clk;
//------------------------------------------------------------------------------

    if(Execute) begin
      if(Cmd_Busy) Execute <= 1'b0;

    end else if(~Cmd_Busy) begin
      case(State)
        Start_Init: begin
          if(&StartupCount) begin
            Command       <= GO_IDLE_STATE;
            Argument      <= 0;
            Response_Type <= 0;
            Execute       <= 1'b1;  
            State         <= Send_IF;
          end
        end     
//------------------------------------------------------------------------------

        Send_IF: begin
          Command       <= SEND_IF_COND;
          Argument      <= 32'h00_00_01_AA;
          Response_Type <= R7;
          Execute       <= 1'b1;
          State         <= Get_Version;
        end     
//------------------------------------------------------------------------------

        Get_Version: begin
          if(Cmd_Error) begin // Card version 1
            CardVersion   <= 2'd1;
            Command       <= GO_IDLE_STATE;
            Argument      <= 0;
            Response_Type <= 0;
            Execute       <= 1'b1;
 
          end else begin // Card version 2
            CardVersion <= 2'd2;
          end
 
          State <= Get_OP1;
        end     
//------------------------------------------------------------------------------

        Get_OP1: begin
          Command       <= APP_CMD;
          Argument      <= 0;
          Response_Type <= R1;
          Execute       <= 1'b1;
          State         <= Get_OP2;
        end     
//------------------------------------------------------------------------------

        Get_OP2: begin
          Command       <= SD_SEND_OP_COND;
          Response_Type <= R3;
          Execute       <= 1'b1;
          Argument      <= {1'b0, CardVersion != 2'd1, 6'd0, 24'h30_00_00};
          State         <= Get_CID;
        end
//------------------------------------------------------------------------------

        Stall: begin
        end
//------------------------------------------------------------------------------

        // All these states stall on error
        default: begin
          if(Cmd_Error) begin
            Card_Error <= 1'b1;
            State      <= Stall;

          end else begin
            case(State)
              Get_CID: begin
                if(`OCR_Powerup) begin // Card powered up
                  Command       <= ALL_SEND_CID;
                  Argument      <= 0;
                  Response_Type <= R2; 
                  Execute       <= 1'b1;
                  State         <= Set_Address;
   
                end else begin // Card not powered up yet
                  Command       <= APP_CMD;
                  Argument      <= 0;
                  Response_Type <= R1; 
                  Execute       <= 1'b1;
                  State         <= Get_OP2;
                end
              end     
//------------------------------------------------------------------------------

              Set_Address: begin
                Command       <= SEND_RELATIVE_ADDR;
                Argument      <= 0;
                Response_Type <= R6;
                Execute       <= 1'b1;
                State         <= Get_CSD;
              end     
//------------------------------------------------------------------------------

              Get_CSD: begin
                RCA <= Response[39:24];
   
                Command       <= SEND_CSD;
                Argument      <= {Response[39:24], 16'd0};
                Response_Type <= R2;
                Execute       <= 1'b1;
                State         <= Process_CSD;
              end     
//------------------------------------------------------------------------------

              Process_CSD: begin
                SCD_Structure <= `CSD_STRUCTURE;
   
                Command       <= SELECT_CARD;
                Argument      <= {RCA, 16'd0};
                Response_Type <= R1b;
                Execute       <= 1'b1;
                State         <= Set_Block_Length;
              end     
//------------------------------------------------------------------------------

              Set_Block_Length: begin
                if(~SD_Busy) begin // Wait while busy
                  Command       <= SET_BLOCKLEN;
                  Argument      <= 32'd512;
                  Response_Type <= R1;
                  Execute       <= 1'b1;
                  State         <= Set_Bus_Width1;
                end
              end     
//------------------------------------------------------------------------------

              Set_Bus_Width1: begin
                Command       <= APP_CMD;
                Argument      <= {RCA, 16'd0};
                Response_Type <= R1;
                Execute       <= 1'b1;
                State         <= Set_Bus_Width2;
              end     
//------------------------------------------------------------------------------

              Set_Bus_Width2: begin
                ClkCount <= 0; // Fast clock

                if(Bus_Width == 4) begin // 4 lines
                  Argument     <= 32'd2;
                  Block_Length <= 12'd1023;

                end else begin // 1 line
                  Argument     <= 32'd0;
                  Block_Length <= 12'd4095;
                end  

                Command       <= SET_BUS_WIDTH;
                Response_Type <= R1;
                Execute       <= 1'b1;
                State         <= Idle;
              end     
//------------------------------------------------------------------------------

              Idle: begin
                if(Read) begin
                  Busy      <= 1'b1;
                  Address   <= 9'h1FF;
                  pData_Clk <= Data_Clk;
  
                  if(|SCD_Structure) Argument <=  Block;
                  else               Argument <= {Block[22:0], 9'd0};
  
                  Command       <= READ_SINGLE_BLOCK;
                  Response_Type <= R1;
                  Execute       <= 1'b1;
                  State         <= Reading;
                end
              end     
//------------------------------------------------------------------------------

              Done: begin
                Write_Enable <= 1'b0;
  
                if(~Data_Busy) begin
                  if(|Data_Error) begin // If data CRC failed, retry
                    Execute <= 1'b1; 
                    State   <= Reading;
  
                  end else begin
                    if(~Read) begin
                      Busy  <= 1'b0; 
                      State <= Idle;
                    end
                  end
                end
              end
//------------------------------------------------------------------------------

              default:;
            endcase
          end
        end
      endcase
    end
//------------------------------------------------------------------------------

    // These states are independent of the command bus
    case(State)
      Reading: begin
        pData_Clk <= Data_Clk;

        if(pData_Clk ^ Data_Clk) begin
          Address      <= Address + 1'b1;
          Data         <= Receive_Data;
          Write_Enable <= 1'b1;  

          if(Address == 9'h1FE) State <= Done;
        end
      end
//------------------------------------------------------------------------------

      default:;
    endcase  
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

