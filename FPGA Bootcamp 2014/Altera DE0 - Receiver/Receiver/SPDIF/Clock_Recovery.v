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

module Clock_Recovery(
  input Reset,
  input Clk,

  output Rec_Reset,
  output Rec_180_000_000,
  output Rec_1_406_250,

  output Ena_703_125
);
//------------------------------------------------------------------------------

Clock_Recovery_PLL Clock_Recovery_PLL1(
  .inclk0(Clk),
  .c0    (Rec_180_000_000),
  .c1    (Rec_1_406_250)
);
//------------------------------------------------------------------------------

Powerup_Timer Powerup_Timer2(
  ~Reset,
  Clk,
  Rec_180_000_000,
  Rec_Reset
);
//------------------------------------------------------------------------------

reg Ena_Counter;

always @(posedge Rec_1_406_250) Ena_Counter <= Ena_Counter + 1'b1;

assign Ena_703_125 = Ena_Counter;
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

