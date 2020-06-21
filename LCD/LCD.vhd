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

entity LCD is
 port(
  nReset  : in  std_logic;
  Clk     : in  std_logic;

  Line    : in  std_logic_vector(1 downto 0);
  Address : in  std_logic_vector(4 downto 0);
  Data    : in  std_logic_vector(7 downto 0);
  Latch   : in  std_logic;

  RS      : out std_logic;
  E       : out std_logic;
  D       : out std_logic_vector(3 downto 0)
 );
end entity LCD;
--------------------------------------------------------------------------------

architecture a1 of LCD is
 component LCD_RAM is
  port(
   data      : in  std_logic_vector(7 downto 0);
   wraddress : in  std_logic_vector(6 downto 0); 
   rdaddress : in  std_logic_vector(6 downto 0);
   wrclock   : in  std_logic;
   rdclock   : in  std_logic;
   q         : out std_logic_vector(7 downto 0)
  );
 end component LCD_RAM;
--------------------------------------------------------------------------------

 signal state      : std_logic_vector( 3 downto 0);
 signal retstate   : std_logic_vector( 3 downto 0);
 signal retstate2  : std_logic_vector( 3 downto 0);
 signal count      : std_logic_vector(17 downto 0);
 
 signal tdata      : std_logic_vector( 7 downto 0);

 signal WrAddress1 : std_logic_vector(6 downto 0);
 signal RdAddress1 : std_logic_vector(6 downto 0);

 signal RdLine     : std_logic_vector(1 downto 0);
 signal RdAddress  : std_logic_vector(4 downto 0);
 signal RdLatch    : std_logic;
 signal RdData     : std_logic_vector(7 downto 0);
--------------------------------------------------------------------------------

begin
 WrAddress1 <=   Line &   Address;
 RdAddress1 <= RdLine & RdAddress;
 
 RAM : LCD_RAM port map(
  Data, 
  WrAddress1, 
  RdAddress1, 
  Latch,
  RdLatch,
  RdData
 );
--------------------------------------------------------------------------------

 process(Clk, nReset) is
 begin
  if nReset = '0' then
   state     <= (others => '0');
   retstate  <= (others => '0');
   retstate2 <= (others => '0');
   count     <= (others => '0');
   tdata     <= (others => '0');

   RdLine    <= (others => '0');
   RdAddress <= (others => '0');
   RdLatch   <= '0';
   
   RS        <= '0';
   E         <= '0';
   D         <= (others => '0');
--------------------------------------------------------------------------------

  elsif rising_edge(Clk) then
   case state is
    when "0000" =>
     count     <= "11" & X"D08F"; -- 100ms
     retstate  <= "1100";
     state     <= "1111";
--------------------------------------------------------------------------------

    when "0001" =>
     tdata     <= X"02";
     retstate2 <= "0010";
     state     <= "1010";
--------------------------------------------------------------------------------

    when "0010" =>
     tdata     <= X"2F";
     retstate2 <= "0011";
     state     <= "1000";
--------------------------------------------------------------------------------

    when "0011" =>
     tdata     <= X"0C";
     retstate2 <= "0100";
     state     <= "1000";
--------------------------------------------------------------------------------

    when "0100" =>
     tdata     <= X"01";
     retstate2 <= "0101";
     state     <= "1000";
--------------------------------------------------------------------------------

    when "0101" =>
     count    <= "00" & X"61A8"; -- 10ms
     retstate <= "0110";
     state    <= "1111";
--------------------------------------------------------------------------------

    when "0110" =>
     RS <= '0';

     case RdLine is
      when "00" =>
       tdata <= X"80";
      when "01" =>
       tdata <= X"C0";
      when "10" =>
       tdata <= X"94";
      when "11" =>
       tdata <= X"D4";
      when others =>
     end case;

     retstate2 <= "0111";
     state     <= "1000";
--------------------------------------------------------------------------------

    when "0111" =>
     RS    <= '1';
     tdata <= RdData;
     
     if RdAddress = "10011" then
      RdLine    <= RdLine + '1';
      RdAddress <= "00000";
      retstate2 <= "0110";
     else
      RdAddress <= RdAddress + '1';
      retstate2 <= "0111";
     end if;

     state <= "1000";
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

    when "1000" =>
     RdLatch <= '1';
     E       <= '1';
     D       <= tdata(7 downto 4);
     state   <= "1001";
     
--------------------------------------------------------------------------------

    when "1001" =>
     RdLatch <= '0';
     E       <= '0';
     state   <= "1010";
--------------------------------------------------------------------------------

    when "1010" =>
     E     <= '1';
     D     <= tdata(3 downto 0);
     state <= "1011";
--------------------------------------------------------------------------------

    when "1011" =>
     E        <= '0';
     count    <= "00" & X"007C"; -- 50 us
     retstate <= retstate2;
     state    <= "1111";
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

    when "1100" =>
     tdata     <= X"03";
     retstate2 <= "1101";
     state     <= "1010";
--------------------------------------------------------------------------------

    when "1101" =>
     tdata     <= X"03";
     retstate2 <= "1110";
     state     <= "1010";
--------------------------------------------------------------------------------

    when "1110" =>
     tdata     <= X"03";
     retstate2 <= "0001";
     state     <= "1010";
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

    when "1111" =>
     if count = "00" & X"0000" then
      state <= retstate;
     end if;
     
     count <= count - '1';
--------------------------------------------------------------------------------

    when others =>
   end case; 
  end if;
 end process;
end architecture a1;
--------------------------------------------------------------------------------
