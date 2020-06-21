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

// J Taylor 2010-09-07

// The button is latched until the next key-down event

module Keypad(
  input nReset,
  input Clk, // About 200 Hz
  
  inout [3:0]X,
  inout [3:0]Y,
  
  output reg      Down,
  output reg [3:0]Button);
//------------------------------------------------------------------------------

  reg [3:0]x;
  reg [3:0]y;
  reg [3:0]ty;
  reg [3:0]button;
  reg      valid;
  reg      state;
//------------------------------------------------------------------------------

  // Ensures that the x and y readings are stable during the rising clock edge.
  always @(negedge nReset, negedge Clk) begin
    if(!nReset) begin
      x <= 0;
      y <= 0;
    end else begin
      x <= X;
      y <= Y;
    end
  end
//------------------------------------------------------------------------------

  assign X = state ? 4'b1111 : 4'bZZZZ;
  assign Y = state ? 4'bZZZZ : 4'b1111;
//------------------------------------------------------------------------------

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      Down   <= 0;
      Button <= 0;
      ty     <= 0;
      state  <= 1'b1;
//------------------------------------------------------------------------------

    end else begin
      if(state) begin // X Energised
        if(|y) begin
          ty    <= y;
          state <= ~state;
        end
    
      end else begin // Y Energised
        if(valid) begin
          Down   <= 1'b1;
          Button <= button;
        end else begin
          Down   <= 1'b0;
          state  <= ~state;
        end
      end
    end
  end
//------------------------------------------------------------------------------

  always @(x, ty) begin
    case({x, ty})
      8'b_1000_1000: begin
        button <= 4'h1;
        valid  <= 1'b1;
      end
      8'b_0100_1000: begin
        button <= 4'h2;
        valid  <= 1'b1;
      end
      8'b_0010_1000: begin
        button <= 4'h3;
        valid  <= 1'b1;
      end
      8'b_0001_1000: begin
        button <= 4'hA;
        valid  <= 1'b1;
      end

      8'b_1000_0100: begin
        button <= 4'h4;
        valid  <= 1'b1;
      end
      8'b_0100_0100: begin
        button <= 4'h5;
        valid  <= 1'b1;
      end
      8'b_0010_0100: begin
        button <= 4'h6;
        valid  <= 1'b1;
      end
      8'b_0001_0100: begin
        button <= 4'hB;
        valid  <= 1'b1;
      end

      8'b_1000_0010: begin
        button <= 4'h7;
        valid  <= 1'b1;
      end
      8'b_0100_0010: begin
        button <= 4'h8;
        valid  <= 1'b1;
      end
      8'b_0010_0010: begin
        button <= 4'h9;
        valid  <= 1'b1;
      end
      8'b_0001_0010: begin
        button <= 4'hC;
        valid  <= 1'b1;
      end
   
      8'b_1000_0001: begin
        button <= 4'hE;
        valid  <= 1'b1;
      end
      8'b_0100_0001: begin
        button <= 4'h0;
        valid  <= 1'b1;
      end
      8'b_0010_0001: begin
        button <= 4'hF;
        valid  <= 1'b1;
      end
      8'b_0001_0001: begin
        button <= 4'hD;
        valid  <= 1'b1;
      end

      default: begin
        button <= 4'hX;
        valid  <= 1'b0;
      end
    endcase
  end
endmodule
//------------------------------------------------------------------------------
