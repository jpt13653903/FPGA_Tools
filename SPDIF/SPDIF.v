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

module SPDIF(
  input nReset,
  input Clk,  // 100 MHz
  input Sync, // 390 625 kHz
  
  output reg [ 23:0]ChannelA, // Left
  output reg [ 23:0]ChannelB, // Right
  output reg        Valid,
  output reg        UserData,
  output reg [191:0]Status,   // The Channel Status Information Bits
 
  output reg        SPDIF_Clock, // ~48 kHz
  input             SPDIF_In);
//------------------------------------------------------------------------------

  parameter Glitch = 8'd10; // 100 ns for 100 MHz clock

  reg  [  1:0]pSPDIF;
  reg         state;

  reg  [  7:0]count;
  reg  [  7:0]single;
  reg  [  7:0]temp;
  reg  [  7:0]Count_1_5;
  reg  [  7:0]Count_2_5;
 
  reg  [  7:0]DR_Count; // Data Recovery
  reg  [ 63:0]data;
  wire [ 27:0]decode;
  wire [ 27:0]valid;

  reg  [191:0]tStatus;
  reg  [  7:0]FrameCount;
 
  reg  [ 23:0] tChannelA;
  reg  [ 23:0] tChannelB;
  reg  [ 23:0]ttChannelA;
  reg  [  1:0]  pSync;
//------------------------------------------------------------------------------

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      state       <= 0;
   
      count       <= 0;
      single      <= 0;
      temp        <= 0;
      Count_1_5   <= 0;
      Count_2_5   <= 0;
      pSPDIF      <= 0;
      Valid       <= 0;
   
      UserData    <= 0;   
      Status      <= 0;
      tStatus     <= 0;
      FrameCount  <= 0;

      DR_Count    <= 0;

      SPDIF_Clock <= 0;
   
      data        <= 0;
      ChannelA    <= 0;
      ChannelB    <= 0;
    tChannelA    <= 0;
    tChannelB    <= 0;
  ttChannelA    <= 0;
      pSync       <= 0;
//------------------------------------------------------------------------------
   
    end else begin
      pSPDIF <= {pSPDIF[0], SPDIF_In};
//------------------------------------------------------------------------------
// Pulse Width measurement
//------------------------------------------------------------------------------
   
      case(state)
        1'b0: begin
          if(^pSPDIF) begin
            count  <= 0;
            temp   <= 0;
            single <= {8{1'b1}};
            state  <= 1'b1;
          end
        end
//------------------------------------------------------------------------------

        1'b1: begin
          if((^pSPDIF) && (count > Glitch)) begin
            if(count < single) single <= count;

            if(&temp) begin
              Count_1_5 <= 8'd24; // single             + single[7:1] + single[0];
              Count_2_5 <= 8'd41; //{single[6:0], 1'b0} + single[7:1] + single[0];
              Valid     <= 1'b1;
              single    <= {8{1'b1}};
            end
      
            count <= 0;
            temp  <= temp + 1'b1;
      
          end else begin
            if(&count) begin
              Valid <= 1'b0;
              state <= 1'b0;
            end
            count <= count + 1'b1;
          end
        end
//------------------------------------------------------------------------------
     
        default:;
      endcase
//------------------------------------------------------------------------------
// Clock and Data Recovery
//------------------------------------------------------------------------------
     
      pSync <= {pSync[0], Sync};
//------------------------------------------------------------------------------

      if(Valid) begin
        if(pSync == 2'b01) begin
          ChannelA <= tChannelA;
          ChannelB <= tChannelB;
        end

        if((^pSPDIF) && (DR_Count > Glitch)) begin
          if     (DR_Count < Count_1_5) data <= {data[62:0],    pSPDIF[1]  };
          else if(DR_Count < Count_2_5) data <= {data[61:0], {2{pSPDIF[1]}}};
          else                          data <= {data[60:0], {3{pSPDIF[1]}}};
     
          if((  &valid     ) &&      // Valid Biphase Mark Coding
                (  ~decode[24]) &&      // Valid Sample
                (~(^decode)   ) ) begin // Even parity
            case(data[63:56])
              8'b11101000,       // Start of frame; Channel A
              8'b00010111: begin // Start of frame; Channel A
                if(FrameCount == 8'd191) begin
                  Status     <= tStatus;
                end
                FrameCount  <= 0;
                tStatus     <= {decode[26], tStatus[191:1]};
                ttChannelA  <= decode[23:0];
                UserData    <= decode[25];
                SPDIF_Clock <= 1'b1;
              end
      
              8'b11100010,       // Channel A
              8'b00011101: begin // Channel A
                FrameCount  <= FrameCount + 1'b1;
                tStatus     <= {decode[26], tStatus[191:1]};
                ttChannelA  <= decode[23:0];
                UserData    <= decode[25];
                SPDIF_Clock <= 1'b1;
              end
      
              8'b11100100,       // Channel B
              8'b00011011: begin // Channel B
                tChannelA   <= ttChannelA;
                tChannelB   <= decode[23:0];
                UserData    <= decode[25];
                SPDIF_Clock <= 1'b0;
              end
      
              default:;
            endcase
          end

          DR_Count <= 0;
     
        end else begin
          DR_Count <= DR_Count + 1'b1;
        end
    
      end else begin
        ChannelA <= 0;
        ChannelB <= 0;
        DR_Count <= 0;
      end
    end
  end
//------------------------------------------------------------------------------

  generate
    genvar i;
    for(i = 0; i < 28; i = i + 1) begin: G_Decode
      assign decode[27-i] = data[i*2+1] ^ data[i*2  ];
      assign valid [27-i] = data[i*2+2] ^ data[i*2+1];
    end
  endgenerate
endmodule
//------------------------------------------------------------------------------
