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

module RealTimeClock #(
  parameter inc = 5'd20 // 1/f_Clk * 1e9
)(
  input        nReset,
  input        Clk,
 
  output [71:0]Time, // century|year|month|day|hour|min|sec|ms|us|ns
                     //     9     7    4    5    5   6   6  10 10 10

  input  [71:0]SetTime,
  input        LatchTime
);
//------------------------------------------------------------------------------

  reg  [8:0]century;
  reg  [6:0]year;
  reg  [3:0]month;
  reg  [4:0]day;
  reg  [4:0]hour;
  reg  [5:0]minute;
  reg  [5:0]second;
  reg  [9:0]ms;
  reg  [9:0]us;
  reg  [9:0]ns;
//------------------------------------------------------------------------------

  wire [ 9:0]ns1;
 
  assign ns1 = ns + inc;
//------------------------------------------------------------------------------

  reg [4:0]DaysPerMonth;
 
  always @(month, year, century) begin
    case(month)
      4'd01,
      4'd03,
      4'd05,
      4'd07,
      4'd08,
      4'd10,
      4'd12: DaysPerMonth <= 5'd31;
   
      4'd04,
      4'd06,
      4'd09,
      4'd11: DaysPerMonth <= 5'd30;
   
      4'd02: begin
        if(|year[1:0]) begin // not divisible by 4
          DaysPerMonth <= 5'd28;
     
        end else if(|year) begin // not divisible by 100
          DaysPerMonth <= 5'd29;
    
        end else if(|century[1:0]) begin // not divisible by 400
          DaysPerMonth <= 5'd28;

        end else begin // divisible by 400
          DaysPerMonth <= 5'd29;
        end
      end
   
      default: DaysPerMonth <= 0;
    endcase
  end
//------------------------------------------------------------------------------

  always @(negedge nReset, posedge Clk) begin
    if(!nReset) begin
      century <= 9'd16;
      year    <= 0;
      month   <= 4'd1;
      day     <= 5'd1;
      hour    <= 0;
      minute  <= 0;
      second  <= 0;
      ms      <= 0;
      us      <= 0;
      ns      <= 0;
//------------------------------------------------------------------------------

    end else begin
      if(LatchTime) begin
        century <= SetTime[71:63];
        year    <= SetTime[62:56];
        month   <= SetTime[55:52];
        day     <= SetTime[51:47];
        hour    <= SetTime[46:42];
        minute  <= SetTime[41:36];
        second  <= SetTime[35:30];
        ms      <= SetTime[29:20];
        us      <= SetTime[19:10];
        ns      <= SetTime[ 9: 0];
//------------------------------------------------------------------------------
   
      end else begin
        if(ns1 > 10'd999) begin
          ns <= ns1 - 10'd1000;
          if(us == 10'd999) begin
            us <= 0;
            if(ms == 10'd999) begin
              ms <= 0;
              if(second == 6'd59) begin
                second <= 0;
                if(minute == 6'd59) begin
                  minute <= 0;
                  if(hour == 5'd23) begin
                    hour <= 0;
                    if(day == DaysPerMonth) begin
                      day <= 5'd1;
                      if(month == 4'd12) begin
                        month <= 4'd1;
                        if(year == 7'd99) begin
                          year    <= 0;
                          century <= century + 1'd1;
                        end else begin
                          year <= year + 1'd1;
                        end
                      end else begin
                        month <= month + 1'd1;
                      end
                    end else begin
                      day <= day + 1'd1;
                    end
                  end else begin
                    hour <= hour + 1'd1;
                  end
                end else begin
                  minute <= minute + 1'd1;
                end
              end else begin
                second <= second + 1'd1;
              end
            end else begin
              ms <= ms + 1'd1;
            end
          end else begin
            us <= us + 1'd1;
          end
        end else begin
          ns <= ns1;
        end
      end
    end
  end
//------------------------------------------------------------------------------
 
  assign Time = {century, year, month, day, hour, minute, second, ms, us, ns};
endmodule
//------------------------------------------------------------------------------
