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

// Splits a signal into AC and DC components

// Subsamples the signal to find the DC, 
// then uses an IIR filter to smooth the resulting DC.

// If the error is too small for the IIR filter to function,
// the error is integrated out.

module ACDC(nReset, Clk, Input, AC, DC);
  parameter n   = 18;
  parameter div = 20; // Used for Subsample: > 10
  parameter iir =  8; // Bit accuracy of the IIR filter:              1
                      //                            H(z) = ----------------------
                      //                                   (2^iir) (1 - z^-1) + 1
                      // Running at a sample rate of f_Clk / 2^div * 2^iir
 
  input nReset;
  input Clk;
 
  input      [n-1:0]Input; // 2's Compliment
  output reg [n-1:0]AC;    // 2's Compliment
  output reg [n-1:0]DC;    // 2's Compliment
  
  wire [      n  :0]ac;
  wire [      n-1:0]dc;
  reg  [div-iir-1:0]count;
  wire [      n  :0]inc;
  
  SubSample #(n, div) SubSample1(nReset, Clk, Input, dc);
  
  assign ac = {Input[n-1], Input} - {DC[n-1], DC};
  
  always @* begin
    case(ac[n:n-1])
      2'b00,
      2'b11  : AC <= ac[n-1:0];
      2'b01  : AC <= {n{1'b1}};
      default: AC <= 0;
    endcase
  end
  
  assign inc = {dc[n-1], dc} - {DC[n-1], DC};
  
  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      DC    <= 0;
      count <= 0;
    
    end else begin
      if(~|count) begin
        if(|inc) begin
          DC <= DC + {{(iir-1){inc[n]}}, inc[n:iir]} + inc[iir-1];
        end else if(dc > DC) begin
          DC <= DC + 1'b1;
        end else if(dc < DC) begin
          DC <= DC - 1'b1;
        end
      end
      count <= count - 1'b1;
    end
  end
endmodule
