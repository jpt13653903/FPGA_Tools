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

// Usage:
// 1. Make Sample (or Force) high
// 2. Wait for BufferReady to go high
// 3. Make Sample and Force low
// 4. Read data by repeatedly setting BufferAddress and reading BufferData
//------------------------------------------------------------------------------

module Scope #(
  parameter f_Clk = 18'd50_000 // [kHz]
)(
  input nReset,
  input Clk,            // 50 MHz (change the perameter otherwise)

  input [23:0]Input00,  // 2's Compliment
  input [23:0]Input01,  // 2's Compliment
  input [23:0]Input02,  // 2's Compliment
  input [23:0]Input03,  // 2's Compliment
  input [23:0]Input04,  // 2's Compliment
  input [23:0]Input05,  // 2's Compliment
  input [23:0]Input06,  // 2's Compliment
  input [23:0]Input07,  // 2's Compliment
  input [23:0]Input08,  // 2's Compliment
  input [23:0]Input09,  // 2's Compliment
  input [23:0]Input10,  // 2's Compliment
  input [23:0]Input11,  // 2's Compliment
  input [23:0]Input12,  // 2's Compliment
  input [23:0]Input13,  // 2's Compliment
  input [23:0]Input14,  // 2's Compliment
  input [23:0]Input15,  // 2's Compliment
  input [23:0]Input16,  // 2's Compliment
  input [23:0]Input17,  // 2's Compliment
  input [23:0]Input18,  // 2's Compliment
  input [23:0]Input19,  // 2's Compliment
  input [23:0]Input20,  // 2's Compliment
  input [23:0]Input21,  // 2's Compliment
  input [23:0]Input22,  // 2's Compliment
  input [23:0]Input23,  // 2's Compliment
  input [23:0]Input24,  // 2's Compliment
  input [23:0]Input25,  // 2's Compliment
  input [23:0]Input26,  // 2's Compliment
  input [23:0]Input27,  // 2's Compliment
  input [23:0]Input28,  // 2's Compliment
  input [23:0]Input29,  // 2's Compliment
  input [23:0]Input30,  // 2's Compliment
  input [23:0]Input31,  // 2's Compliment
 
  // 2 channel scope - the 3rd channel is the trigger
  input [14:0]ChannelMux,   // 3 channels by 5-bit
  input [ 2:0]Coupling,     // 1 = AC (1 Hz), 0 = DC
  input [15:0]Bandwidth,    // [kHz]
  input [ 4:0]SampleRate,   // log2(f_Clk/x)
  input [ 2:0]Average,      // log2(x)

  input [15:0]TriggerLevel,      // Level
  input [15:0]TriggerHyst,       // Hysteresis
  input       TriggerSlope,      // 1 = Positive  , 0 = Negative
  input [ 7:0]TriggerHorizontal, // units of 4 samples
 
  input        Sample,        // Make high to sample on next trigger
  input        Force,         // Make high to force a trigger
  output       BufferReady,   // Made high when finished sampling
  input  [11:0]BufferAddress, // MSB is the channel address
  output [31:0]BufferData);   // 24-bit, more with averaging
//------------------------------------------------------------------------------

  wire TriggerOut;
  reg  pTriggerOut;
//------------------------------------------------------------------------------

  wire [17:0]Filter_a;
//------------------------------------------------------------------------------

  wire [23:0]Ch0 [2:0];
  wire [23:0]Ch1 [2:0];
  wire [23:0]Ch2 [2:0];
  wire [31:0]Ch2e[1:0];
  wire [31:0]Ch3 [1:0];
  wire [31:0]Ch4 [1:0];
  wire [31:0]Ch5 [1:0];
//------------------------------------------------------------------------------

  reg  [30:0]CountStart;
  reg  [30:0]Counter;
//------------------------------------------------------------------------------

  reg       Averaging;
  reg  [6:0]AverageStart;
  reg  [6:0]AverageCount;
//------------------------------------------------------------------------------

  reg  [1:0]state;
//------------------------------------------------------------------------------

  genvar g;
//------------------------------------------------------------------------------

  S_Const #(.fs(f_Clk), .fs_2(f_Clk[16:1])) Const(
    nReset,
    Clk,

    Bandwidth,

    Filter_a
  );
//------------------------------------------------------------------------------

  generate
    for(g = 0; g < 3; g = g + 1) begin: G_S_MUX
      S_MUX MUX(
        nReset,
        Clk,
    
        Input00,
        Input01,
        Input02,
        Input03,
        Input04,
        Input05,
        Input06,
        Input07,
        Input08,
        Input09,
        Input10,
        Input11,
        Input12,
        Input13,
        Input14,
        Input15,
        Input16,
        Input17,
        Input18,
        Input19,
        Input20,
        Input21,
        Input22,
        Input23,
        Input24,
        Input25,
        Input26,
        Input27,
        Input28,
        Input29,
        Input30,
        Input31,
 
        ChannelMux[5*g+4:g*5],
        Ch0[g]
      );
    end
  endgenerate
//------------------------------------------------------------------------------

  generate
    for(g = 0; g < 3; g = g + 1) begin: G_S_Coupling
      S_Coupling Coupling1(
        nReset,
        Clk,
        Ch0[g],
        Ch1[g],
        Coupling[g]
      );
    end
  endgenerate
//------------------------------------------------------------------------------

  generate
    for(g = 0; g < 3; g = g + 1) begin: G_S_Filter
      S_Filter Filter(
        nReset,
        Clk,
        Ch1[g],
        Ch2[g],
        Filter_a
      );
    end
  endgenerate
//------------------------------------------------------------------------------

  reg  [ 9:0]Delay_Address;
  reg        Delay_WrEn;
  wire [47:0]Delay_Temp;
  reg  [47:0]Delay_Out;
  reg  [30:0]Delay_Counter;

  S_Delay Delay1(
    .clock    (!Clk),
    .data     ({Ch2[1], Ch2[0]}),
    .rdaddress(Delay_Address),
    .wraddress(Delay_Address),
    .wren     (Delay_WrEn),
    .q        (Delay_Temp)
  );
//------------------------------------------------------------------------------

  generate
    for(g = 0; g < 2; g = g + 1) begin: G1
      assign Ch2e[g] = {{8{Delay_Out[24*g+23]}}, Delay_Out[24*g+23:24*g]};
    end
  endgenerate
//------------------------------------------------------------------------------

  S_Trigger Trigger0(
    nReset,
    Clk,
    Ch2[2][23:8],
    TriggerOut,
    TriggerLevel,
    TriggerHyst,
    TriggerSlope
  );
//------------------------------------------------------------------------------

  generate
    for(g = 0; g < 2; g = g + 1) begin: G2
      assign Ch3[g] = (Averaging) ? (Ch2e[g] + Ch4[g]) : Ch2e[g];
    end
  endgenerate
//------------------------------------------------------------------------------

  wire [10:0]RdAddress;
  wire [10:0]WrAddress;
  reg  [10:0]Address;
  reg        WrEn;
  wire [31:0]BufferOut;
  reg        done;

  assign RdAddress = (!done) ? Address : BufferAddress[10:0];
  assign WrAddress = Address - 1'b1;

  generate
    for(g = 0; g < 2; g = g + 1) begin: G3
      S_Buffer Buffer(
        .clock    (Clk),
        .data     (Ch3[g]),
        .rdaddress(RdAddress),
        .wraddress(WrAddress),
        .wren     (WrEn),
        .q        (Ch4[g])
      );
    end
  endgenerate
//------------------------------------------------------------------------------

  generate
    for(g = 0; g < 2; g = g + 1) begin: G4
      assign Ch5[g] = done ? Ch4[g] : Ch2e[g];
    end
  endgenerate
//------------------------------------------------------------------------------

  assign BufferData = BufferAddress[11] ? Ch5[1] : Ch5[0];
//------------------------------------------------------------------------------

  always @* begin
    case(SampleRate)
      5'b00000: CountStart <= 31'b0000000000000000000000000000000;
      5'b00001: CountStart <= 31'b0000000000000000000000000000001;
      5'b00010: CountStart <= 31'b0000000000000000000000000000011;
      5'b00011: CountStart <= 31'b0000000000000000000000000000111;
      5'b00100: CountStart <= 31'b0000000000000000000000000001111;
      5'b00101: CountStart <= 31'b0000000000000000000000000011111;
      5'b00110: CountStart <= 31'b0000000000000000000000000111111;
      5'b00111: CountStart <= 31'b0000000000000000000000001111111;
      5'b01000: CountStart <= 31'b0000000000000000000000011111111;
      5'b01001: CountStart <= 31'b0000000000000000000000111111111;
      5'b01010: CountStart <= 31'b0000000000000000000001111111111;
      5'b01011: CountStart <= 31'b0000000000000000000011111111111;
      5'b01100: CountStart <= 31'b0000000000000000000111111111111;
      5'b01101: CountStart <= 31'b0000000000000000001111111111111;
      5'b01110: CountStart <= 31'b0000000000000000011111111111111;
      5'b01111: CountStart <= 31'b0000000000000000111111111111111;
      5'b10000: CountStart <= 31'b0000000000000001111111111111111;
      5'b10001: CountStart <= 31'b0000000000000011111111111111111;
      5'b10010: CountStart <= 31'b0000000000000111111111111111111;
      5'b10011: CountStart <= 31'b0000000000001111111111111111111;
      5'b10100: CountStart <= 31'b0000000000011111111111111111111;
      5'b10101: CountStart <= 31'b0000000000111111111111111111111;
      5'b10110: CountStart <= 31'b0000000001111111111111111111111;
      5'b10111: CountStart <= 31'b0000000011111111111111111111111;
      5'b11000: CountStart <= 31'b0000000111111111111111111111111;
      5'b11001: CountStart <= 31'b0000001111111111111111111111111;
      5'b11010: CountStart <= 31'b0000011111111111111111111111111;
      5'b11011: CountStart <= 31'b0000111111111111111111111111111;
      5'b11100: CountStart <= 31'b0001111111111111111111111111111;
      5'b11101: CountStart <= 31'b0011111111111111111111111111111;
      5'b11110: CountStart <= 31'b0111111111111111111111111111111;
      5'b11111: CountStart <= 31'b1111111111111111111111111111111;
      default : CountStart <= 0;
    endcase
//------------------------------------------------------------------------------

    case(Average)
      3'b000 : AverageStart <= 7'b0000000;
      3'b001 : AverageStart <= 7'b0000001;
      3'b010 : AverageStart <= 7'b0000011;
      3'b011 : AverageStart <= 7'b0000111;
      3'b100 : AverageStart <= 7'b0001111;
      3'b101 : AverageStart <= 7'b0011111;
      3'b110 : AverageStart <= 7'b0111111;
      3'b111 : AverageStart <= 7'b1111111;
      default: AverageStart <= 0;
    endcase
  end
//------------------------------------------------------------------------------

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      state        <= 0;

      pTriggerOut  <= 1'b1;

      Address      <= 0;
      WrEn         <= 0;
      done         <= 0;

      Counter      <= 0;

      Averaging    <= 0;
      AverageCount <= 0;
//------------------------------------------------------------------------------

      Delay_Address <= 0;
      Delay_WrEn    <= 1'b1;
      Delay_Out     <= 0;
      Delay_Counter <= 0;
//------------------------------------------------------------------------------

    end else begin
      if(~|Delay_Counter) begin
        Delay_Out     <= Delay_Temp;
        Delay_WrEn    <= 1'b1;
        Delay_Counter <= CountStart;
      end else begin
        Delay_WrEn    <= 1'b0;
        Delay_Counter <= Delay_Counter - 1'b1;
      end
      if(Delay_WrEn) begin
        if((Delay_Address + 1'b1) >= {TriggerHorizontal, 2'b00}) begin
          Delay_Address <= 0;
        end else begin
          Delay_Address <= Delay_Address + 1'b1;
        end
      end
//------------------------------------------------------------------------------

      case(state)
        2'b00: begin
          WrEn <= 1'b0;
          if(!done) begin
            if(Force || (Sample && !pTriggerOut && TriggerOut)) begin
              Counter      <= 0;
              Averaging    <= 1'b0;
              AverageCount <= AverageStart;
              Address      <= 0;
              state        <= 2'b01;
            end
          end else if(!Sample && !Force) begin
            done <= 1'b0;
          end
        end
//------------------------------------------------------------------------------

        2'b01: begin
          if(~|Counter) begin
            WrEn <= 1'b1;

            if(&Address) begin
              if(~|AverageCount) begin
                done  <= 1'b1;
                state <= 2'b00;
              end else begin
                state <= 2'b10;
              end
            end
            Address <= Address + 1'b1;
            Counter <= CountStart;
          end else begin
            WrEn    <= 1'b0;
            Counter <= Counter - 1'b1;
          end
        end
//------------------------------------------------------------------------------

        2'b10: begin
          WrEn <= 1'b0;
          if(Force || (Sample && !pTriggerOut && TriggerOut)) begin
            Counter      <= 0;
            Averaging    <= 1'b1;
            AverageCount <= AverageCount - 1'b1;
            Address      <= 0;
            state        <= 2'b01;
          end
        end
//------------------------------------------------------------------------------

        default:;
      endcase

      pTriggerOut <= TriggerOut;
    end
  end

  assign BufferReady = done;
endmodule
//------------------------------------------------------------------------------
