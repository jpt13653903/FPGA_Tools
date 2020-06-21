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

entity USB_Rx is
 port(
  nReset : in std_logic;
  Clk    : in std_logic; -- 40 MHz

  DataReady : out std_logic;
  RxData    : out std_logic_vector(7 downto 0);
  Ack       : in  std_logic;

  Rx : in  std_logic
 );
end entity USB_Rx;
--------------------------------------------------------------------------------

architecture a1 of USB_Rx is
 signal tRx  : std_logic;

 signal state    : std_logic_vector(1 downto 0);
 signal count    : std_logic_vector(4 downto 0); -- 3 Mbaud
 signal tdata    : std_logic_vector(7 downto 0);
 signal count2   : std_logic_vector(2 downto 0);

 signal set        : std_logic;
 signal tDataReady : std_logic;
begin
 process(Clk, nReset) is
 begin
  if nReset = '0' then
   tRx  <= '1';

   state  <= "00";
   count2 <= "111";
   RxData <= "00000000";
   set    <= '0';
  elsif rising_edge(Clk) then
   case state is
    when "00" =>
     if tRx = '0' then
      count    <= "10100"; -- 20
      state    <= "01";
     end if;
    when "01" =>
     if count = "0000010" then
      state <= "10";
     end if;
     count <= count - '1';
    when "10" =>
     count  <= "01101"; -- 13
     if count2 = "000" then
      if (Ack = '0') and (tDataReady = '0') then
       RxData(7) <= tRx;
       RxData(6 downto 0) <= tdata(7 downto 1);
       set <= '1';
      end if;
      state <= "11";
     else
      tdata(7) <= tRx;
      tdata(6 downto 0) <= tdata(7 downto 1);
      state    <= "01";
     end if;
     count2 <= count2 - '1';
    when "11" =>
     set <= '0';
     if tRx = '1' then
      state <= "00";
     end if;
    when others =>
   end case;
  elsif falling_edge(Clk) then
   tRx <= Rx;
  end if;
 end process;
--------------------------------------------------------------------------------

 process(Clk, set, Ack, nReset) is
 begin
  if (Ack or (not nReset)) = '1' then
   tDataReady <= '0';
  elsif falling_edge(Clk) then
   if set = '1' then
    tDataReady <= '1';
   end if;
  end if;
 end process;
 DataReady <= tDataReady;
end architecture a1;
--------------------------------------------------------------------------------
