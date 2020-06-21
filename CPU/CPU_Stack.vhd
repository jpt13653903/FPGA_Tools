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

-- J Taylor
-- Last modified 2009-11-23
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--------------------------------------------------------------------------------

entity CPU_Stack is
 port(
  nReset  : in  std_logic;
  Clk     : in  std_logic;

  Address : in  std_logic_vector(2 downto 0);
  Input   : in  std_logic_vector(7 downto 0);
  Out0    : out std_logic_vector(7 downto 0);
  Out1    : out std_logic_vector(7 downto 0);
  OutA    : out std_logic_vector(7 downto 0);

  Latch   : in  std_logic;
  Task    : in  std_logic_vector(1 downto 0) 
            --"00" = Store in s0
            --"01" = Push onto stack
            --"10" = Store is s1, then Pop Stack
            --"11" = Swop s0 and sA
 );
end entity CPU_Stack;
--------------------------------------------------------------------------------

architecture a1 of CPU_Stack is
 signal s0 : std_logic_vector(7 downto 0);
 signal s1 : std_logic_vector(7 downto 0);
 signal s2 : std_logic_vector(7 downto 0);
 signal s3 : std_logic_vector(7 downto 0);
 signal s4 : std_logic_vector(7 downto 0);
 signal s5 : std_logic_vector(7 downto 0);
 signal s6 : std_logic_vector(7 downto 0);
 signal s7 : std_logic_vector(7 downto 0);
 signal sA : std_logic_vector(7 downto 0);

 signal LPrev : std_logic;
--------------------------------------------------------------------------------

begin
 Out0 <= s0;
 Out1 <= s1;
 with Address select
  sA <= s0 when "000",
        s1 when "001",
        s2 when "010",
        s3 when "011",
        s4 when "100",
        s5 when "101",
        s6 when "110",
        s7 when "111",
        "XXXXXXXX" when others;
 OutA <= sA;

 process(Clk, nReset) is
 begin
  if nReset = '0' then
   s0 <= "00000000";
   s1 <= "00000000";
   s2 <= "00000000";
   s3 <= "00000000";
   s4 <= "00000000";
   s5 <= "00000000";
   s6 <= "00000000";
   s7 <= "00000000";

   LPrev <= '0';
  elsif falling_edge(Clk) then
   if (LPrev = '0') and (Latch = '1') then
    case Task is
     when "00" =>
      s0 <= Input;
     when "01" =>
      s1 <= s0;
      s2 <= s1;
      s3 <= s2;
      s4 <= s3;
      s5 <= s4;
      s6 <= s5;
      s7 <= s6;
      s0 <= Input;
     when "10" =>
      s0 <= Input;
      s1 <= s2; 
      s2 <= s3;
      s3 <= s4;
      s4 <= s5;
      s5 <= s6;
      s6 <= s7;
     when "11" =>
      case Address is
       when "001" =>
        s1 <= s0;
       when "010" =>
        s2 <= s0;
       when "011" =>
        s3 <= s0;
       when "100" =>
        s4 <= s0;
       when "101" =>
        s5 <= s0;
       when "110" =>
        s6 <= s0;
       when "111" =>
        s7 <= s0;
       when others =>
      end case;
      s0 <= sA;
     when others =>
    end case;
   end if;
   LPrev <= Latch;
  end if;
 end process;
end architecture a1;
--------------------------------------------------------------------------------
