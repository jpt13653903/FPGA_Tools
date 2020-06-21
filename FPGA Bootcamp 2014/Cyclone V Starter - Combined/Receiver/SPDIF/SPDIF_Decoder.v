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

module SPDIF_Decoder(
  input Reset,
  input Clk,

  input       SPDIF,
  output reg nSPDIF,

  output           Sound_Clk, // About 5.625 MHz
  output reg       Data_Clk,  // Edge on Sound update; falling on Text update
  output reg [95:0]Sound,
  output reg [ 7:0]Text
);
//------------------------------------------------------------------------------

reg      pSPDIF;
reg [7:0]Period_Counter;
reg [8:0]Frame_Counter;

reg [63:0]Raw;
reg [71:0]Sound_Buffer;
reg [ 6:0]Text_Buffer;
//------------------------------------------------------------------------------

reg [4:0]Sound_Clk_Counter;

assign Sound_Clk = Sound_Clk_Counter[4];
//------------------------------------------------------------------------------

reg tReset;

always @(posedge Clk) begin
  tReset <= Reset;

  if(tReset) begin
    Data_Clk  <= 0;
    Sound     <= 0;
    Text      <= 0;

    pSPDIF         <= 0;
    nSPDIF         <= 0;
    Period_Counter <= 0;
    Frame_Counter  <= 9'h1FF;

    Raw          <= 0;
    Sound_Buffer <= 0;
    Text_Buffer  <= 0;

    Sound_Clk_Counter <= 0;
//------------------------------------------------------------------------------

  end else begin
    pSPDIF <= SPDIF;

    if((Period_Counter > 8'd18) && (nSPDIF == pSPDIF)) begin // No glitch and edge
      nSPDIF <= ~pSPDIF;

      if(&Valid && ~(^Decoded)) begin // All valid edges and even parity
        case(Raw[7:0])
          8'b00010111, // Start of block (and channel A)
          8'b11101000: begin
            Data_Clk      <= 0;
            Sound_Buffer  <= {Decoded[27:4], Sound_Buffer[71:24]};
            Text_Buffer   <= {Decoded[29  ], Text_Buffer [ 6: 1]};
            Frame_Counter <= 0;
          end

          8'b01000111, // Start of channel A
          8'b10111000: begin
            if(~&Frame_Counter) begin
              Sound_Buffer  <= {Decoded[27:4], Sound_Buffer[71:24]};
              Text_Buffer   <= {Decoded[29  ], Text_Buffer [ 6: 1]};
              Frame_Counter <= Frame_Counter + 1'b1;
            end
          end

          8'b00100111, // Start of channel B
          8'b11011000: begin
            if(~&Frame_Counter) begin
              if(Frame_Counter[1:0] == 2'd2) begin
                Sound    <= {Decoded[27:4], Sound_Buffer};
                Data_Clk <= ~Data_Clk;
              end
              if(Frame_Counter[2:0] == 3'd6) begin
                 Text <= {Decoded[29], Text_Buffer};
              end

              Sound_Buffer  <= {Decoded[27:4], Sound_Buffer[71:24]};
              Text_Buffer   <= {Decoded[29  ], Text_Buffer [ 6: 1]};
              Frame_Counter <= Frame_Counter + 1'b1;
            end
          end

          default:;
        endcase
      end

      if     (Period_Counter < 8'd_48) Raw <= {   pSPDIF  , Raw[63:1]};
      else if(Period_Counter < 8'd_80) Raw <= {{2{pSPDIF}}, Raw[63:2]};
      else if(Period_Counter < 8'd112) Raw <= {{3{pSPDIF}}, Raw[63:3]};
      else                             Raw <= 0;
      Period_Counter <= 0;

      // Synchronise only on one edge to have a clean clock when the 
      // positive and negative pulses are not equal.
      if(pSPDIF) Sound_Clk_Counter <= 0; 
      else       Sound_Clk_Counter <= Sound_Clk_Counter + 1'b1;

    end else begin
      Period_Counter    <= Period_Counter    + 1'b1;
      Sound_Clk_Counter <= Sound_Clk_Counter + 1'b1;
    end
  end
end
//------------------------------------------------------------------------------

wire [31:4]Valid;
wire [31:4]Decoded;

genvar j;
generate
  for(j = 0; j < 28; j = j + 1) begin: Gen_Decoder
    assign Valid  [j+4] = Raw[2*j+8] ^ Raw[2*j+7];
    assign Decoded[j+4] = Raw[2*j+8] ^ Raw[2*j+9];
  end
endgenerate
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------


