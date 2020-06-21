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

module Channel_Decoder #(
  parameter Channel = 3'd0
)(
  input Reset,
  input Clk,
  input Clk_Ena,

  output reg [40:0]Address,
  input      [ 7:0]Data,
  input            Data_Valid,

  output reg      Text_Mutex_Request,
  input           Text_Mutex_Grant,
  output reg [6:0]Text_Address,
  output reg [7:0]Text_Data,
  output reg      Text_Enable,

  input            Skip,
  output reg [15:0]Output
);
//------------------------------------------------------------------------------

reg [31:0]Start_Block;

reg   [2:0]State;
localparam Start           = 3'b000;
localparam ReadTrackLength = 3'b001;
localparam ReadArtist      = 3'b011;
localparam ReadTitle       = 3'b010;
localparam ReadSound       = 3'b110;

reg [ 1:0]Count;
reg [40:0]Track_End;
reg [23:0]Temp;
//------------------------------------------------------------------------------

reg tReset;

always @(posedge Clk) begin
  tReset <= Reset;

  if(tReset) begin
    Start_Block <= 0;

    Address   <= {36'd0, Channel, 2'd0};
    Output    <= 0;

    Text_Mutex_Request <= 0;
    Text_Address       <= 0;
    Text_Data          <= 0;
    Text_Enable        <= 0;

    Count     <= 0;
    Track_End <= 0;
    Temp      <= 0;

    State     <= Start;
//------------------------------------------------------------------------------

  end else if(Skip) begin
    if(State != Start) begin
      Count   <= 0;
      Address <= Track_End + 1'b1;
      Output  <= 0;
      State   <= ReadTrackLength;
    end
//------------------------------------------------------------------------------

  end else if(Clk_Ena & Data_Valid) begin
    case(State)
      Start: begin
        if(&Count) begin
          Start_Block <= {Data, Temp};
          Address     <= {Data, Temp, 9'd0};
          Track_End   <= {Data, Temp, 9'd0} - 1'b1;
          State       <= ReadTrackLength; 
 
        end else begin
          Temp    <= {Data, Temp[23:8]};
          Address <= Address + 1'b1;
        end
        Count <= Count + 1'b1;
      end
//------------------------------------------------------------------------------

      ReadTrackLength: begin
        if(&Count) begin
          if(|{Data, Temp}) begin
            Track_End <= Address + {Data, Temp};
            Address   <= Address + 1'b1;
            State     <= ReadArtist; 
      
            Text_Address       <= {7{1'b1}};
            Text_Mutex_Request <= 1'b1;
 
          end else begin
            Address <= {Start_Block, 9'd0};
          end   

        end else begin
          Temp    <= {Data, Temp[23:8]};
          Address <= Address + 1'b1;
        end
        Count <= Count + 1'b1;
      end
//------------------------------------------------------------------------------

      ReadArtist: begin
        if(Text_Mutex_Grant) begin
          Text_Data    <= Data;
          Text_Enable  <= 1'b1;
          Text_Address <= Text_Address + 1'b1;
          Address      <= Address      + 1'b1;

          if(~|Data) State <= ReadTitle;
        end
      end
//------------------------------------------------------------------------------

      ReadTitle: begin
        Text_Data    <= Data;
        Text_Address <= Text_Address + 1'b1;
        Address      <= Address      + 1'b1;

        if(~|Data) State <= ReadSound;
      end
//------------------------------------------------------------------------------

      ReadSound: begin
        Text_Enable        <= 1'b0;
        Text_Mutex_Request <= 1'b0;

        if(Address == Track_End) begin
          Count  <= 0;
          Output <= 0;
          State  <= ReadTrackLength;

        end else begin
          if(~Count[0]) Temp[7:0] <=  Data;
          else          Output    <= {Data, Temp[7:0]};
          Count[0] <= ~Count[0];
        end
        Address <= Address + 1'b1;
      end
//------------------------------------------------------------------------------

      default:;
    endcase
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

