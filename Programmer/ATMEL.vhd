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

entity ATMEL is
  port(
    nReset : in std_logic;
    Clk    : in std_logic; -- 43.945 kHz
  
    DataIn  : in  std_logic_vector(31 downto 0);
    DataOut : out std_logic_vector(31 downto 0);
  
    Send    : in  std_logic; -- Put high until busy high to start
    Busy    : out std_logic; -- Wait till busy low to read
    ResetIn : in  std_logic;

    Reset : out std_logic;
    MOSI  : out std_logic;
    MISO  : in  std_logic;
    SCK   : out std_logic
  );
end entity ATMEL;

architecture a1 of ATMEL is
  signal state : std_logic_vector( 1 downto 0);
  signal count : std_logic_vector( 4 downto 0);
  signal Temp  : std_logic_vector(31 downto 0);
  signal tBusy : std_logic; 
begin
  Reset <= ResetIn;
  Busy  <= tBusy;
 
  process(Clk, nReset) is
  begin
    if nReset = '0' then
      state   <= (others => '0');
      count   <= (others => '0');
      DataOut <= (others => '0');
      tBusy   <= '1';
      MOSI    <= '0';
      SCK     <= '0';
    elsif rising_edge(Clk) then
      case state is
        when "00" =>
          SCK <= '0';
          if Send = '0' then
            DataOut <= Temp;
            tBusy   <= '0';
          else
            if tBusy = '0' then
              Temp  <= DataIn;
              Count <= "11111"; -- 31
              state <= "01";
            end if;
          end if;

        when "01" =>
          tBusy <= '1';
          SCK   <= '0';
          MOSI  <= Temp(31);
          state <= "11";

        when "11" =>
          SCK <= '1';
          Temp <= Temp(30 downto 0) & MISO;
          if count = "00000" then
            state <= "00";
          else
            state <= "01";
          end if;
          count <= count - '1';

        when others =>
      end case;
    end if;
  end process;
end architecture a1;
