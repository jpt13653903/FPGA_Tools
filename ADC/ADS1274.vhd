--==============================================================================
-- Copyright (C) John-Philip Taylor
-- jpt13653903@gmail.com
--
-- This file is part of a library
--
-- This file is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ADS1274 is
 port(
  nReset : in std_logic;
  Clk    : in std_logic; -- 45 MHz
  
  aClk  : out std_logic;
  nDRdy : in  std_logic;
  SClk  : out std_logic;
  Data  : in  std_logic;
  
  Offset : in std_logic_vector(63 downto 0); -- 4x 16-bit

  DataOut : out std_logic_vector(95 downto 0) -- 4x 24-bit
 );
end entity ADS1274;

architecture a1 of ADS1274 is
 signal state : std_logic_vector( 1 downto 0);
 signal count : std_logic_vector( 6 downto 0);
 signal tData : std_logic_vector(94 downto 0);
 signal Data1 : std_logic_vector(24 downto 0);
 signal Data2 : std_logic_vector(24 downto 0);
 signal Data3 : std_logic_vector(24 downto 0);
 signal Data4 : std_logic_vector(24 downto 0);
 signal tClk  : std_logic;
begin
 process(Clk, nReset) is
 begin
  if nReset = '0' then
   state   <= "00";
   tClk    <= '0';
   SClk    <= '0';
   tData   <= (others => '0');
   Dataout <= (others => '0');
  elsif rising_edge(Clk) then
   tClk <= not tClk;
  
   case state is
    when "00" =>
     count(1 downto 0) <= "11"; -- 3
     if nDRdy = '0' then
      state <= "01";
     end if;

    when "01" =>
     if count(1 downto 0) = "00" then
      count <= "1100000"; -- 96
      state <= "11";
     else
      count(1 downto 0) <= count(1 downto 0) - '1';
     end if;

    when "11" =>
     SClk  <= '1';
     count <= count - '1';
     state <= "10";

    when "10" =>
     SClk  <= '0';
     if count = "0000000" then
      case Data1(24 downto 23) is
       when "00" =>
        DataOut(23 downto 0) <= Data1(23 downto 0);
       when "01" =>
        DataOut(23 downto 0) <= X"7FFFFF";
       when "10" =>
        DataOut(23 downto 0) <= X"800000";
       when "11" =>
        DataOut(23 downto 0) <= Data1(23 downto 0);
       when others =>
      end case;

      case Data2(24 downto 23) is
       when "00" =>
        DataOut(47 downto 24) <= Data2(23 downto 0);
       when "01" =>
        DataOut(47 downto 24) <= X"7FFFFF";
       when "10" =>
        DataOut(47 downto 24) <= X"800000";
       when "11" =>
        DataOut(47 downto 24) <= Data2(23 downto 0);
       when others =>
      end case;

      case Data3(24 downto 23) is
       when "00" =>
        DataOut(71 downto 48) <= Data3(23 downto 0);
       when "01" =>
        DataOut(71 downto 48) <= X"7FFFFF";
       when "10" =>
        DataOut(71 downto 48) <= X"800000";
       when "11" =>
        DataOut(71 downto 48) <= Data3(23 downto 0);
       when others =>
      end case;

      case Data4(24 downto 23) is
       when "00" =>
        DataOut(95 downto 72) <= Data4(23 downto 0);
       when "01" =>
        DataOut(95 downto 72) <= X"7FFFFF";
       when "10" =>
        DataOut(95 downto 72) <= X"800000";
       when "11" =>
        DataOut(95 downto 72) <= Data4(23 downto 0);
       when others =>
      end case;

      state <= "00";
     else
      state <= "11";
     end if;
     tData <= tData(93 downto 0) & Data;

    when others =>
   end case;
  end if;
 end process;
 
 Data1 <= (tData (94) & tData (94 downto 71)        ) + 
          (Offset(15) & Offset(15 downto  0) & X"00");
 Data2 <= (tData (70) & tData (70 downto 47)        ) + 
          (Offset(31) & Offset(31 downto 16) & X"00");
 Data3 <= (tData (46) & tData (46 downto 23)        ) + 
          (Offset(47) & Offset(47 downto 32) & X"00");
 Data4 <= (tData (22) & tData (22 downto  0) & Data ) + 
          (Offset(63) & Offset(63 downto 48) & X"00");

 aClk <= tClk;
end architecture a1;
