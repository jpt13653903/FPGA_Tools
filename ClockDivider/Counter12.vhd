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
--------------------------------------------------------------------------------

entity Counter12 is
 port(
  nReset: in  std_logic;
  Clk   : in  std_logic;
  Q     : out std_logic_vector(11 downto 0)
 );
end entity Counter12;
--------------------------------------------------------------------------------

architecture a1 of Counter12 is
 signal count: std_logic_vector(11 downto 0);
 signal D    : std_logic_vector(11 downto 0);
 signal ands : std_logic_vector(11 downto 1);
--------------------------------------------------------------------------------

begin
 ands(         1) <= count(0);
 ands(11 downto 2) <= ands(10 downto 1) and count(10 downto 1);

 D(         0) <= not count(0);
 D(11 downto 1) <= count(11 downto 1) xor ands(11 downto 1);
--------------------------------------------------------------------------------

 process(Clk, nReset) is
 begin
  if nReset = '0' then
   count <= "000000000000";
  elsif falling_edge(Clk) then
   count <= D;
  end if;
 end process;

 Q <= count;
end architecture a1;
--------------------------------------------------------------------------------
