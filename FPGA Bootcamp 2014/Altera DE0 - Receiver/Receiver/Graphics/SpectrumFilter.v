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

module SpectrumFilter #(
  // All these assume that 2^24 represents unity
  parameter a = 24'd0,
  parameter b = 25'd0,
  parameter c = 24'd0,
  parameter e = 26'd0,
  parameter f = 27'd0,
  parameter g = 26'd0,
  parameter h = 24'd0
)(
  input Reset,
  input Clk,
  input Sound_Sync,
  input Level_Sync,

  input  [15:0]Sound,
  output [ 3:0]Spectrum[4:0]
);
//------------------------------------------------------------------------------

// The minimum bit length for stable operation is 28.  Make it 32 to be safe...
localparam N = 32; // Length of y to represent unity
localparam H =  4; // Headroom to store overshoot above unity (2 minimum)

reg [H+N-1:0]A;
reg [   26:0]B;

wire [H+N- 1:0]Abs_A = A[H+N-1] ? ~A + 1'b1 : A;
wire [H+N+26:0]Abs_Y = Abs_A * B;
wire [H+N+26:0]    Y = A[H+N-1] ? ~Abs_Y + 1'b1 : Abs_Y;
//------------------------------------------------------------------------------

reg [H+N- 1:0]y[4:0];
reg [    15:0]x[2:0];
reg [H+N+29:0]Sum;

reg   [2:0]State;
localparam Idle  = 3'd0;
localparam Mul_A = 3'd1;
localparam Mul_B = 3'd2;
localparam Mul_C = 3'd3;
localparam Mul_E = 3'd4;
localparam Mul_F = 3'd5;
localparam Mul_G = 3'd6;
localparam Mul_H = 3'd7;

reg tReset;

always @(posedge Clk) begin
  tReset <= Reset;

  if(tReset) begin
    A <= 0;
    B <= 0;

    x[2] <= 0;
    x[1] <= 0;
    x[0] <= 0;

    y[4] <= 0;
    y[3] <= 0;
    y[2] <= 0;
    y[1] <= 0;
    y[0] <= 0;

    Sum   <= 0;
    State <= Idle;
//------------------------------------------------------------------------------

  end else begin
    case(State)
      Idle: begin
        if(Sound_Sync) begin
          x[2] <= x[1];
          x[1] <= x[0];
          x[0] <= Sound;

          y[4] <= y[3];
          y[3] <= y[2];
          y[2] <= y[1];
          y[1] <= y[0];

          A     <= {{H{Sound[15]}}, Sound, {(N-16){Sound[0]}}};
          B     <= a;
          State <= Mul_A;

        end else begin
          if(Sum[H+N+29]) begin
            if(&Sum[H+N+28:H+N+23]) y[0] <= Sum[H+N+23:24];
            else                    y[0] <= {1'b1, {(H+N-1){1'b0}}};
          end else begin
            if(|Sum[H+N+28:H+N+23]) y[0] <= {1'b0, {(H+N-1){1'b1}}};
            else                    y[0] <= Sum[H+N+23:24];
          end
        end
      end
//------------------------------------------------------------------------------

      Mul_A: begin
        Sum   <= {{3{Y[H+N+26]}}, Y};
        A     <= {{H{x[1][15]}}, x[1], {(N-16){x[1][0]}}};
        B     <= b;
        State <= Mul_B;
      end
//------------------------------------------------------------------------------

      Mul_B: begin
        Sum   <= Sum - {{3{Y[H+N+26]}}, Y};
        A     <= {{H{x[2][15]}}, x[2], {(N-16){x[2][0]}}};
        B     <= c;
        State <= Mul_C;
      end
//------------------------------------------------------------------------------

      Mul_C: begin
        Sum   <= Sum + {{3{Y[H+N+26]}}, Y};
        A     <= y[1];
        B     <= e;
        State <= Mul_E;
      end
//------------------------------------------------------------------------------

      Mul_E: begin
        Sum   <= Sum + {{3{Y[H+N+26]}}, Y};
        A     <= y[2];
        B     <= f;
        State <= Mul_F;
      end
//------------------------------------------------------------------------------

      Mul_F: begin
        Sum   <= Sum - {{3{Y[H+N+26]}}, Y};
        A     <= y[3];
        B     <= g;
        State <= Mul_G;
      end
//------------------------------------------------------------------------------

      Mul_G: begin
        Sum   <= Sum + {{3{Y[H+N+26]}}, Y};
        A     <= y[4];
        B     <= h;
        State <= Mul_H;
      end
//------------------------------------------------------------------------------

      Mul_H: begin
        Sum   <= Sum - {{3{Y[H+N+26]}}, Y};
        State <= Idle;
      end
//------------------------------------------------------------------------------

      default:;
    endcase
  end
end
//------------------------------------------------------------------------------

reg [15:0]Filtered;

always @(*) begin
  if(y[0][H+N-1]) begin
    if(&y[0][H+N-2:N-1]) Filtered <= y[0][N-1:N-16];
    else                 Filtered <= 16'h8000;
  end else begin
    if(|y[0][H+N-2:N-1]) Filtered <= 16'h7FFF;
    else                 Filtered <= y[0][N-1:N-16];
  end
end
//------------------------------------------------------------------------------

wire [15:0]Abs = Filtered[15] ? ~Filtered + 1'b1 : Filtered;

LevelFilter #(16'd_13_045) Filter_4(Reset, Clk, Sound_Sync, Level_Sync, 
                                    Abs, Spectrum[4]);
LevelFilter #(16'd__5_193) Filter_3(Reset, Clk, Sound_Sync, Level_Sync, 
                                    Abs, Spectrum[3]);
LevelFilter #(16'd__2_068) Filter_2(Reset, Clk, Sound_Sync, Level_Sync, 
                                    Abs, Spectrum[2]);
LevelFilter #(16'd____823) Filter_1(Reset, Clk, Sound_Sync, Level_Sync, 
                                    Abs, Spectrum[1]);
LevelFilter #(16'd____328) Filter_0(Reset, Clk, Sound_Sync, Level_Sync, 
                                    Abs, Spectrum[0]);
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

