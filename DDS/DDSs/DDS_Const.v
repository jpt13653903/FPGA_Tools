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

module DDS_Const #(
  parameter n = 12)(
 
  input nReset,
  input Clk,
 
  input      [16*n-1:0]Skew,
  output reg [18*n-1:0]Y1,  // Skew
  output reg [18*n-1:0]Y2,  // 1/Skew
  output reg [18*n-1:0]Y3); // 1/(2^18 - Skew)
//------------------------------------------------------------------------------

  reg  [ 3:0]channel;
  reg  [15:0]tSkew;
 
  reg  [ 1:0]state;
  reg        part;

  reg  [17:0]temp;
  reg  [17:0]temp2;

  wire [17:0]den;
  reg  [17:0]q;
  wire [35:0]num;

  reg  [17:0]mask;
//------------------------------------------------------------------------------

  always @* begin
    case(channel)
      4'b0000: tSkew <= Skew[ 15:  0];
      4'b0001: tSkew <= Skew[ 31: 16];
      4'b0010: tSkew <= Skew[ 47: 32];
      4'b0011: tSkew <= Skew[ 63: 48];
      4'b0100: tSkew <= Skew[ 79: 64];
      4'b0101: tSkew <= Skew[ 95: 80];
      4'b0110: tSkew <= Skew[111: 96];
      4'b0111: tSkew <= Skew[127:112];
      4'b1000: tSkew <= Skew[143:128];
      4'b1001: tSkew <= Skew[159:144];
      4'b1010: tSkew <= Skew[175:160];
      4'b1011: tSkew <= Skew[191:176];
      default: tSkew <= 0;
    endcase
  end
//------------------------------------------------------------------------------
 
  assign den = part ? -temp : temp;
  assign num = den * q;
//------------------------------------------------------------------------------

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      channel <= 0;
   
      state <= 0;
      part  <= 1'b1;

      temp  <= 0;
      temp2 <= 0;

      Y1 <= 0;
      Y2 <= 0;
      Y3 <= 0;

      q    <= 0;
      mask <= 18'h2_0000;
//------------------------------------------------------------------------------
   
    end else begin
      case(state)
        2'b00: begin
          if(part) begin
            if(~|tSkew) begin
              temp <= 18'h0_0001;
            end else begin
              temp <= {tSkew, 2'b00};
            end
          end else begin
            temp2 <= q;
          end
          part  <= ~part;
          q     <= 18'h2_0000;
          mask  <= 18'h2_0000;
          state <= 2'b01;
        end
//------------------------------------------------------------------------------
     
        2'b01: begin
          if(|num[35:27]) begin
            q <= q & (~mask);
          end
          mask  <= {1'b0, mask[17:1]};
          state <= 2'b10;
        end
//------------------------------------------------------------------------------
     
        2'b10:begin
          if(~|mask) begin
            if(!part) begin
              state <= 2'b00;
            end else begin
              state <= 2'b11;
            end
          end else begin
            q     <= q | mask;
            state <= 2'b01;
          end
        end
//------------------------------------------------------------------------------
     
        2'b11: begin
          case(channel)
            4'b0000: begin
              Y1[17:0] <= temp;
              Y2[17:0] <= temp2;
              Y3[17:0] <= q;
              channel  <= 4'b0001;
            end
            4'b0001: begin
              Y1[35:18] <= temp;
              Y2[35:18] <= temp2;
              Y3[35:18] <= q;
              channel   <= 4'b0010;
            end
            4'b0010: begin
              Y1[53:36] <= temp;
              Y2[53:36] <= temp2;
              Y3[53:36] <= q;
              channel   <= 4'b0011;
            end
            4'b0011: begin
              Y1[71:54] <= temp;
              Y2[71:54] <= temp2;
              Y3[71:54] <= q;
              channel   <= 4'b0100;
            end
            4'b0100: begin
              Y1[89:72] <= temp;
              Y2[89:72] <= temp2;
              Y3[89:72] <= q;
              channel   <= 4'b0101;
            end
            4'b0101: begin
              Y1[107:90] <= temp;
              Y2[107:90] <= temp2;
              Y3[107:90] <= q;
              channel    <= 5'b0110;
            end
            4'b0110: begin
              Y1[125:108] <= temp;
              Y2[125:108] <= temp2;
              Y3[125:108] <= q;
              channel     <= 4'b0111;
            end
            4'b0111: begin
              Y1[143:126] <= temp;
              Y2[143:126] <= temp2;
              Y3[143:126] <= q;
              channel     <= 4'b1000;
            end
            4'b1000: begin
              Y1[161:144] <= temp;
              Y2[161:144] <= temp2;
              Y3[161:144] <= q;
              channel     <= 4'b1001;
            end
            4'b1001: begin
              Y1[179:162] <= temp;
              Y2[179:162] <= temp2;
              Y3[179:162] <= q;
              channel     <= 4'b1010;
            end
            4'b1010: begin
              Y1[197:180] <= temp;
              Y2[197:180] <= temp2;
              Y3[197:180] <= q;
              channel     <= 4'b1011;
            end
            4'b1011: begin
              Y1[215:198] <= temp;
              Y2[215:198] <= temp2;
              Y3[215:198] <= q;
              channel     <= 4'b0000;
            end
            default:;
          endcase
          state <= 2'b00;
        end
//------------------------------------------------------------------------------
    
        default:;
      endcase
    end
  end
endmodule
//------------------------------------------------------------------------------
