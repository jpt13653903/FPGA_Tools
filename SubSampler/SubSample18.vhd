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

entity SubSample18 is
 port(
  nReset : in std_logic;
  Clk    : in std_logic;
  
  Input  : in  std_logic_vector(17 downto 0);
  Output : out std_logic_vector(17 downto 0) -- /2^20
 );
end entity SubSample18;

architecture a1 of SubSample18 is
 signal sum   : std_logic_vector(37 downto 0);
 signal Count : std_logic_vector(19 downto 0);
 signal e     : std_logic_vector(37 downto 0);
begin
 e(37 downto 18) <= (others => Input(17));
 e(17 downto  0) <= Input;
 
 process(Clk, nReset) is
 begin
  if nReset = '0' then
   sum   <= (others => '0');
   Count <= (others => '0');
  elsif rising_edge(Clk) then
   if Count = "00000000000000000000" then
    if sum(36 downto 20) = "11111111111111111" then
     Output <= sum(37 downto 20);
    else
     Output <= sum(37 downto 20) + sum(19);
    end if;
    sum <= e;
   else
    sum <= sum + e;
   end if;
   Count <= Count + '1';
  end if;
 end process;
end architecture a1;
