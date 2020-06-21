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

entity PWM is
 port( 
  nReset : in  std_logic; 
  Clk    : in  std_logic; -- 90 MHz
  Sync   : in  std_logic; -- 351.563 kHz
  Duty   : in  std_logic_vector(23 downto 0);

  PWM    : out std_logic
 );
end entity PWM;

architecture a1 of PWM is
 component Counter8 is
  port(
   nReset : in  std_logic;
   Clk    : in  std_logic;
   Q      : out std_logic_vector(7 downto 0)
  );
 end component Counter8;

 component NS is
  port( 
   nReset : in  std_logic; 
   Clk    : in  std_logic;

   Input    : in  std_logic_vector(17 downto 0);
   OutNS    : out std_logic_vector( 7 downto 0)
  );
 end component NS;

 signal CounterSync : std_logic;

 signal tD      : std_logic_vector(7 downto 0);
 signal D       : std_logic_vector(7 downto 0);
 signal Count   : std_logic_vector(7 downto 0);
 signal greater : std_logic;
 signal pSync   : std_logic;
 signal tPWM    : std_logic;
begin
 Counter : Counter8 port map(CounterSync, Clk, Count);
 
 NS1 : NS port map(nReset, Sync, Duty(23 downto 6), tD);

 greater <= '1' when (D >= Count) else '0';

 process(Clk, nReset) is
 begin
  if nReset = '0' then
   CounterSync <= '0';

   tPWM  <= '0';
   D     <= "00000000";
   pSync <= '1';
  elsif rising_edge(Clk) then
   tPWM <= greater;

   if (pSync = '0') and (Sync = '1') then
    CounterSync <= '1';
    D <= tD;
   end if;
   pSync <= Sync;
  end if;
 end process;

 PWM <= tPWM;
end architecture a1;
