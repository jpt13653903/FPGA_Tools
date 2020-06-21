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

entity USB_Tx is
  port(
    nReset : in std_logic;
    Clk    : in std_logic; -- 40 MHz

    TxData : in  std_logic_vector(7 downto 0);
    Send   : in  std_logic;
    Busy   : out std_logic;

    Tx : out std_logic
  );
end entity USB_Tx;
--------------------------------------------------------------------------------

architecture a1 of USB_Tx is
  signal state    : std_logic_vector(1 downto 0);
  signal retstate : std_logic_vector(1 downto 0);
  signal count    : std_logic_vector(3 downto 0); -- 3 Mbaud
  signal tdata    : std_logic_vector(7 downto 0);
  signal count2   : std_logic_vector(2 downto 0);
begin
  process(Clk, nReset) is
  begin
    if nReset = '0' then
      state    <= "11";
      count2   <= "111";
      tdata    <= "00000000";
      Tx       <= '1';
      Busy     <= '1';
    elsif rising_edge(Clk) then
      case state is
        when "00" =>
          if Send = '1' then
            Tx       <= '0';
            tData    <= TxData;
            count    <= "1101"; -- 13
            retstate <= "10";
            state    <= "01";
            Busy     <= '1';
          end if;
        when "01" =>
          if count = "000010" then
            state <= retstate;
          end if;
          count <= count - '1';
        when "10" =>
          Tx <= tdata(0);
          tdata(6 downto 0) <= tdata(7 downto 1);
          count2 <= count2 - '1';
          count  <= "1101"; -- 13
          state  <= "01";
          if count2 = "000" then
            retstate <= "11";
          else
            retstate <= "10";
          end if;
        when "11" =>
          Tx <= '1';
          if Send = '0' then
            Busy     <= '0';
            count    <= "1001"; -- 9
            retstate <= "00";
            state    <= "01";
          end if;
        when others =>
      end case;
    end if;
  end process;
end architecture a1;
--------------------------------------------------------------------------------
