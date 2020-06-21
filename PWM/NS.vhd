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

entity NS is
 port( 
  nReset : in  std_logic; 
  Clk    : in  std_logic; -- 351.563 kHz

  Input    : in  std_logic_vector(17 downto 0);
  OutNS    : out std_logic_vector( 7 downto 0)
 );
end entity NS;
------------------------------------------------------------------------------

architecture a1 of NS is
 signal t1   : std_logic_vector(19 downto 0);
 signal t2   : std_logic_vector(17 downto 0); 
 signal t3   : std_logic_vector( 7 downto 0); 
 signal t4   : std_logic_vector( 9 downto 0); 
 signal t5   : std_logic_vector( 9 downto 0); 
 signal t6   : std_logic_vector(10 downto 0); 
 signal t7   : std_logic_vector(10 downto 0); 
 signal t8   : std_logic_vector(11 downto 0); 
 signal t9   : std_logic_vector(11 downto 0); 
 signal t10  : std_logic_vector(12 downto 0);
 signal t11  : std_logic_vector(12 downto 0);
 signal t12  : std_logic_vector(13 downto 0);
 signal t13  : std_logic_vector(14 downto 0); 
 signal t13e : std_logic_vector(19 downto 0); 
------------------------------------------------------------------------------

begin
 t13e(19 downto 15) <= (others => t13(14));
 t13e(14 downto  0) <=            t13     ;
 t1 <= t13e + Input;
 
 t3 <= t2(17 downto 10);
 t4 <= t2( 9 downto  0);
 
 t6  <= ('0'     & t4 ) + ((not ('0'     & t5 )) + '1');
 t8  <= (t6 (10) & t6 ) + ((not (t7 (10) & t7 )) + '1');
 t10 <= (t8 (11) & t8 ) + ((not (t9 (11) & t9 )) + '1');
 t12 <= (t10(12) & t10) + ((not (t11(12) & t11)) + '1');
 t13 <= ("00000" & t4 ) + ((not (t12(13) & t12)) + '1');
------------------------------------------------------------------------------

 process(Clk, nReset) is
 begin
  if nReset = '0' then
   t2  <= (others => '0');
   t5  <= (others => '0');
   t7  <= (others => '0');
   t9  <= (others => '0');
   t11 <= (others => '0');
------------------------------------------------------------------------------

  elsif falling_edge(Clk) then
   if t1(19) = '1' then
    t2 <= (others => '0');
   elsif t1(18) = '1' then
    t2 <= (others => '1');
   else
    t2 <= t1(17 downto 0);
   end if;
------------------------------------------------------------------------------

   t5  <= t4 ;
   t7  <= t6 ;
   t9  <= t8 ;
   t11 <= t10;
  end if;
 end process;
------------------------------------------------------------------------------

 OutNS <= t3;
end architecture a1;
