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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ADC is
 port(
  nReset : in std_logic;
  Clk    : in std_logic; -- 45 MHz

  ADC_Clk : out std_logic;
  
  DCO  : in std_logic;
  FCO  : in std_logic;
  Data : in std_logic_vector(7 downto 0);
   
  Offset : in  std_logic_vector(127 downto 0); -- 8 channels by 16-bit
  ADC    : out std_logic_vector(127 downto 0)  -- 8 channels by 16-bit
 );
end entity ADC;

architecture a1 of ADC is
 signal state : std_logic;
 
 signal count : std_logic_vector(2 downto 0);
 
 signal tData : std_logic_vector(7 downto 0);
 
 signal pFCO : std_logic;
 signal pClk : std_logic;
 
 signal Offset0 : std_logic_vector(15 downto 0);
 signal Offset1 : std_logic_vector(15 downto 0);
 signal Offset2 : std_logic_vector(15 downto 0);
 signal Offset3 : std_logic_vector(15 downto 0);
 signal Offset4 : std_logic_vector(15 downto 0);
 signal Offset5 : std_logic_vector(15 downto 0);
 signal Offset6 : std_logic_vector(15 downto 0);
 signal Offset7 : std_logic_vector(15 downto 0);

 signal ADC0 : std_logic_vector(15 downto 0);
 signal ADC1 : std_logic_vector(15 downto 0);
 signal ADC2 : std_logic_vector(15 downto 0);
 signal ADC3 : std_logic_vector(15 downto 0);
 signal ADC4 : std_logic_vector(15 downto 0);
 signal ADC5 : std_logic_vector(15 downto 0);
 signal ADC6 : std_logic_vector(15 downto 0);
 signal ADC7 : std_logic_vector(15 downto 0);

 signal tADC0 : std_logic_vector(13 downto 0);
 signal tADC1 : std_logic_vector(13 downto 0);
 signal tADC2 : std_logic_vector(13 downto 0);
 signal tADC3 : std_logic_vector(13 downto 0);
 signal tADC4 : std_logic_vector(13 downto 0);
 signal tADC5 : std_logic_vector(13 downto 0);
 signal tADC6 : std_logic_vector(13 downto 0);
 signal tADC7 : std_logic_vector(13 downto 0);

 signal ttADC0 : std_logic_vector(13 downto 0);
 signal ttADC1 : std_logic_vector(13 downto 0);
 signal ttADC2 : std_logic_vector(13 downto 0);
 signal ttADC3 : std_logic_vector(13 downto 0);
 signal ttADC4 : std_logic_vector(13 downto 0);
 signal ttADC5 : std_logic_vector(13 downto 0);
 signal ttADC6 : std_logic_vector(13 downto 0);
 signal ttADC7 : std_logic_vector(13 downto 0);

 signal tttADC0 : std_logic_vector(13 downto 0);
 signal tttADC1 : std_logic_vector(13 downto 0);
 signal tttADC2 : std_logic_vector(13 downto 0);
 signal tttADC3 : std_logic_vector(13 downto 0);
 signal tttADC4 : std_logic_vector(13 downto 0);
 signal tttADC5 : std_logic_vector(13 downto 0);
 signal tttADC6 : std_logic_vector(13 downto 0);
 signal tttADC7 : std_logic_vector(13 downto 0);

 signal ttttADC0 : std_logic_vector(14 downto 0);
 signal ttttADC1 : std_logic_vector(14 downto 0);
 signal ttttADC2 : std_logic_vector(14 downto 0);
 signal ttttADC3 : std_logic_vector(14 downto 0);
 signal ttttADC4 : std_logic_vector(14 downto 0);
 signal ttttADC5 : std_logic_vector(14 downto 0);
 signal ttttADC6 : std_logic_vector(14 downto 0);
 signal ttttADC7 : std_logic_vector(14 downto 0);
begin
 Offset0 <= Offset( 15 downto   0);
 Offset1 <= Offset( 31 downto  16);
 Offset2 <= Offset( 47 downto  32);
 Offset3 <= Offset( 63 downto  48);
 Offset4 <= Offset( 79 downto  64);
 Offset5 <= Offset( 95 downto  80);
 Offset6 <= Offset(111 downto  96);
 Offset7 <= Offset(127 downto 112);

 ADC_Clk <= Clk;
 
 process(DCO, nReset) is
 begin
  if nReset = '0' then
   state <= '0';
   count <= "000";
   pFCO  <= '1';
   pClk  <= '0';

   tADC0 <= "00000000000000";
   tADC1 <= "00000000000000";
   tADC2 <= "00000000000000";
   tADC3 <= "00000000000000";
   tADC4 <= "00000000000000";
   tADC5 <= "00000000000000";
   tADC6 <= "00000000000000";
   tADC7 <= "00000000000000";

   ttADC0 <= "00000000000000";
   ttADC1 <= "00000000000000";
   ttADC2 <= "00000000000000";
   ttADC3 <= "00000000000000";
   ttADC4 <= "00000000000000";
   ttADC5 <= "00000000000000";
   ttADC6 <= "00000000000000";
   ttADC7 <= "00000000000000";

   tttADC0 <= "00000000000000";
   tttADC1 <= "00000000000000";
   tttADC2 <= "00000000000000";
   tttADC3 <= "00000000000000";
   tttADC4 <= "00000000000000";
   tttADC5 <= "00000000000000";
   tttADC6 <= "00000000000000";
   tttADC7 <= "00000000000000";
  elsif rising_edge(DCO) then
   tData <= Data;

  elsif falling_edge(DCO) then
   if state = '0' then
    ttADC0 <= tADC0;
    ttADC1 <= tADC1;
    ttADC2 <= tADC2;
    ttADC3 <= tADC3;
    ttADC4 <= tADC4;
    ttADC5 <= tADC5;
    ttADC6 <= tADC6;
    ttADC7 <= tADC7;
    if (pFCO = '0') and (FCO = '1') then
     tADC0(13 downto 2) <= "000000000000";
     tADC0( 1 downto 0) <= tData(0) & Data(0);
     tADC1(13 downto 2) <= "000000000000";
     tADC1( 1 downto 0) <= tData(1) & Data(1);
     tADC2(13 downto 2) <= "000000000000";
     tADC2( 1 downto 0) <= tData(2) & Data(2);
     tADC3(13 downto 2) <= "000000000000";
     tADC3( 1 downto 0) <= tData(3) & Data(3);
     tADC4(13 downto 2) <= "000000000000";
     tADC4( 1 downto 0) <= tData(4) & Data(4);
     tADC5(13 downto 2) <= "000000000000";
     tADC5( 1 downto 0) <= tData(5) & Data(5);
     tADC6(13 downto 2) <= "000000000000";
     tADC6( 1 downto 0) <= tData(6) & Data(6);
     tADC7(13 downto 2) <= "000000000000";
     tADC7( 1 downto 0) <= tData(7) & Data(7);
     count <= "010";
     state <= '1';
    end if;
   else
    tADC0(13 downto 2) <= tADC0(11 downto 0);
    tADC0( 1 downto 0) <= tData(0) & Data(0);
    tADC1(13 downto 2) <= tADC1(11 downto 0);
    tADC1( 1 downto 0) <= tData(1) & Data(1);
    tADC2(13 downto 2) <= tADC2(11 downto 0);
    tADC2( 1 downto 0) <= tData(2) & Data(2);
    tADC3(13 downto 2) <= tADC3(11 downto 0);
    tADC3( 1 downto 0) <= tData(3) & Data(3);
    tADC4(13 downto 2) <= tADC4(11 downto 0);
    tADC4( 1 downto 0) <= tData(4) & Data(4);
    tADC5(13 downto 2) <= tADC5(11 downto 0);
    tADC5( 1 downto 0) <= tData(5) & Data(5);
    tADC6(13 downto 2) <= tADC6(11 downto 0);
    tADC6( 1 downto 0) <= tData(6) & Data(6);
    tADC7(13 downto 2) <= tADC7(11 downto 0);
    tADC7( 1 downto 0) <= tData(7) & Data(7);
    if Count = "111" then
     state <= '0';
    end if;
    count <= count + '1';     
   end if;

   if (pClk = '1') and (Clk = '0') then
    tttADC0(13         ) <= not ttADC0(13         );
    tttADC0(12 downto 0) <=     ttADC0(12 downto 0);
    tttADC1(13         ) <= not ttADC1(13         );
    tttADC1(12 downto 0) <=     ttADC1(12 downto 0);
    tttADC2(13         ) <= not ttADC2(13         );
    tttADC2(12 downto 0) <=     ttADC2(12 downto 0);
    tttADC3(13         ) <= not ttADC3(13         );
    tttADC3(12 downto 0) <=     ttADC3(12 downto 0);
    tttADC4(13         ) <= not ttADC4(13         );
    tttADC4(12 downto 0) <=     ttADC4(12 downto 0);
    tttADC5(13         ) <= not ttADC5(13         );
    tttADC5(12 downto 0) <=     ttADC5(12 downto 0);
    tttADC6(13         ) <= not ttADC6(13         );
    tttADC6(12 downto 0) <=     ttADC6(12 downto 0);
    tttADC7(13         ) <= not ttADC7(13         );
    tttADC7(12 downto 0) <=     ttADC7(12 downto 0);
   end if;

   pFCO <= FCO;
   pClk <= Clk;
  end if;
 end process;

 process(Clk, nReset) is
 begin
  if nReset = '0' then
   ADC0 <= X"0000";
   ADC1 <= X"0000";
   ADC2 <= X"0000";
   ADC3 <= X"0000";
   ADC4 <= X"0000";
   ADC5 <= X"0000";
   ADC6 <= X"0000";
   ADC7 <= X"0000";
  elsif rising_edge(Clk) then
   case ttttADC0(14 downto 13) is
    when "01" =>
     ADC0 <= X"7FFF";
    when "10" =>
     ADC0 <= X"8000";
    when others =>
     ADC0(15 downto 2) <= ttttADC0(13 downto 0);
     ADC0( 1 downto 0) <= "00";
   end case;

   case ttttADC1(14 downto 13) is
    when "01" =>
     ADC1 <= X"7FFF";
    when "10" =>
     ADC1 <= X"8000";
    when others =>
     ADC1(15 downto 2) <= ttttADC1(13 downto 0);
     ADC1( 1 downto 0) <= "00";
   end case;

   case ttttADC2(14 downto 13) is
    when "01" =>
     ADC2 <= X"7FFF";
    when "10" =>
     ADC2 <= X"8000";
    when others =>
     ADC2(15 downto 2) <= ttttADC2(13 downto 0);
     ADC2( 1 downto 0) <= "00";
   end case;

   case ttttADC3(14 downto 13) is
    when "01" =>
     ADC3 <= X"7FFF";
    when "10" =>
     ADC3 <= X"8000";
    when others =>
     ADC3(15 downto 2) <= ttttADC3(13 downto 0);
     ADC3( 1 downto 0) <= "00";
   end case;

   case ttttADC4(14 downto 13) is
    when "01" =>
     ADC4 <= X"7FFF";
    when "10" =>
     ADC4 <= X"8000";
    when others =>
     ADC4(15 downto 2) <= ttttADC4(13 downto 0);
     ADC4( 1 downto 0) <= "00";
   end case;

   case ttttADC5(14 downto 13) is
    when "01" =>
     ADC5 <= X"7FFF";
    when "10" =>
     ADC5 <= X"8000";
    when others =>
     ADC5(15 downto 2) <= ttttADC5(13 downto 0);
     ADC5( 1 downto 0) <= "00";
   end case;

   case ttttADC6(14 downto 13) is
    when "01" =>
     ADC6 <= X"7FFF";
    when "10" =>
     ADC6 <= X"8000";
    when others =>
     ADC6(15 downto 2) <= ttttADC6(13 downto 0);
     ADC6( 1 downto 0) <= "00";
   end case;

   case ttttADC7(14 downto 13) is
    when "01" =>
     ADC7 <= X"7FFF";
    when "10" =>
     ADC7 <= X"8000";
    when others =>
     ADC7(15 downto 2) <= ttttADC7(13 downto 0);
     ADC7( 1 downto 0) <= "00";
   end case;

  end if;
 end process;
 
 ttttADC0 <= (tttADC0(13) & tttADC0) + (Offset0(15) & Offset0(15 downto 2));
 ttttADC1 <= (tttADC1(13) & tttADC1) + (Offset1(15) & Offset1(15 downto 2));
 ttttADC2 <= (tttADC2(13) & tttADC2) + (Offset2(15) & Offset2(15 downto 2));
 ttttADC3 <= (tttADC3(13) & tttADC3) + (Offset3(15) & Offset3(15 downto 2));
 ttttADC4 <= (tttADC4(13) & tttADC4) + (Offset4(15) & Offset4(15 downto 2));
 ttttADC5 <= (tttADC5(13) & tttADC5) + (Offset5(15) & Offset5(15 downto 2));
 ttttADC6 <= (tttADC6(13) & tttADC6) + (Offset6(15) & Offset6(15 downto 2));
 ttttADC7 <= (tttADC7(13) & tttADC7) + (Offset7(15) & Offset7(15 downto 2));
 
 ADC <= ADC7 & ADC6 & ADC5 & ADC4 & ADC3 & ADC2 & ADC1 & ADC0;
end architecture a1;
