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

module LevelFilter #(
  parameter Level = 16'd0
)(
  input Reset,
  input Clk,
  input Sound_Sync,
  input Level_Sync,

  input      [15:0]SoundAbsolute,
  output reg [ 3:0]SoundLevel
);
//------------------------------------------------------------------------------

reg [8:0]tSoundLevel;

reg tReset;

always @(posedge Clk) begin
  tReset <= Reset;

  if(tReset) begin
   SoundLevel <= 0;
  tSoundLevel <= 0;

  end else if(Sound_Sync) begin
    if(Level_Sync) begin
      case(tSoundLevel[8:5])
        4'd_0: SoundLevel <= 4'd_0;
        4'd_1: SoundLevel <= 4'd_4;
        4'd_2: SoundLevel <= 4'd_6;
        4'd_3: SoundLevel <= 4'd_8;
        4'd_4: SoundLevel <= 4'd_9;
        4'd_5: SoundLevel <= 4'd10;
        4'd_6: SoundLevel <= 4'd11;
        4'd_7: SoundLevel <= 4'd11;
        4'd_8: SoundLevel <= 4'd12;
        4'd_9: SoundLevel <= 4'd12;
        4'd10: SoundLevel <= 4'd13;
        4'd11: SoundLevel <= 4'd13;
        4'd12: SoundLevel <= 4'd14;
        4'd13: SoundLevel <= 4'd14;
        4'd14: SoundLevel <= 4'd15;
        4'd15: SoundLevel <= 4'd15;
        default:;
      endcase
      tSoundLevel <= 0;

    end else begin
      if(SoundAbsolute > Level) tSoundLevel <= tSoundLevel + 1'b1;
    end
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

