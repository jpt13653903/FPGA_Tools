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

entity AD7760 is
  port(
    nReset  : in  std_logic;
    Clk     : in  std_logic;

    Decimation : in  std_logic_vector( 2 downto 0);
    Output     : out std_logic_vector(23 downto 0);
    Status     : out std_logic_vector( 7 downto 0);

    ADC_nReset : out   std_logic;
    ADC_MClk   : out   std_logic;
    ADC_nSync  : out   std_logic;
    ADC_nCS    : out   std_logic;
    ADC_WnR    : out   std_logic;
    ADC_nDRdy  : in    std_logic;
    ADC_D      : inout std_logic_vector(15 downto 0)
  );
end entity AD7760;
--------------------------------------------------------------------------------

architecture a1 of AD7760 is
  signal state     : std_logic_vector( 4 downto 0);
  signal retstate  : std_logic_vector( 4 downto 0);
  signal retstate2 : std_logic_vector( 4 downto 0);
  signal count     : std_logic_vector(25 downto 0);
 
  signal Address : std_logic_vector(15 downto 0);
  signal Data    : std_logic_vector(15 downto 0);

  signal MClk        : std_logic;
  signal tOutput     : std_logic_vector(15 downto 0);
  signal tDecimation : std_logic_vector( 2 downto 0);
--------------------------------------------------------------------------------

begin
  ADC_MClk  <= MClk;
--------------------------------------------------------------------------------

  process(Clk, nReset) is
  begin
    if nReset = '0' then
      state       <= (others => '1');
      retstate    <= (others => '0');
      retstate2   <= (others => '0');
      count       <= "00000000000000000000011111";

      tOutput     <= (others => '0');
      Status      <= (others => '0');
      tDecimation <= (others => '0');

      ADC_nReset  <= '0';
              MClk    <= '0';
      ADC_nSync   <= '1';
      ADC_nCS     <= '1';
      ADC_WnR     <= '1';
      ADC_D       <= (others => 'Z');
      Output      <= (others => '0');
--------------------------------------------------------------------------------

    elsif rising_edge(Clk) then
      MClk <= not MClk;
--------------------------------------------------------------------------------
   
      case state is
        when "00000" =>
          ADC_nReset <= '1';
          count      <= "10011000100101100111111111"; -- 500 ms
          -- This long wait is due to the reset delay on the development board,
          -- when not using the delay, make count <= "11111";
          retstate   <= "00001";
          state      <= "11111";
--------------------------------------------------------------------------------

        when "00001" =>
          Address   <= X"0002";
          Data      <= X"0002";
          retstate2 <= "00010";
          state     <= "10000";
--------------------------------------------------------------------------------

        when "00010" =>
          Address     <= X"0001";
          tDecimation <= Decimation;
          Data        <= X"00" & "00011" & Decimation;
          retstate2   <= "00011";
          state       <= "10000";
--------------------------------------------------------------------------------

        when "00011" =>
          ADC_nSync <= '0';
          count     <= "00000000000000000000011111";
          retstate  <= "00100";
          state     <= "11111";
--------------------------------------------------------------------------------

        when "00100" =>
          ADC_nSync <= '1';
          count     <= "00000000000000000000011111";
          retstate  <= "00101";
          state     <= "11111";
--------------------------------------------------------------------------------

        when "00101" =>
          if ADC_nDRdy = '0' then
            state <= "00110";
          elsif tDecimation /= Decimation then
            state <= "00010";
          end if;
--------------------------------------------------------------------------------

        when "00110" =>
          ADC_WnR <= '0';
          state <= "00111";
--------------------------------------------------------------------------------

        when "00111" =>
          ADC_nCS  <= '0';
          count    <= "00000000000000000000000011";
          retstate <= "01000";
          state    <= "11111";
--------------------------------------------------------------------------------

        when "01000" =>
          tOutput <= ADC_D;
          state   <= "01001";
--------------------------------------------------------------------------------

        when "01001" =>
          ADC_nCS <= '1';
          state   <= "01010";
--------------------------------------------------------------------------------

        when "01010" =>
          ADC_WnR  <= '1';
          count    <= "00000000000000000000000011";
          retstate <= "01011";
          state    <= "11111";
--------------------------------------------------------------------------------

        when "01011" =>
          ADC_WnR <= '0';
          state   <= "01100";
--------------------------------------------------------------------------------

        when "01100" =>
          ADC_nCS  <= '0';
          count    <= "00000000000000000000000011";
          retstate <= "01101";
          state    <= "11111";
--------------------------------------------------------------------------------

        when "01101" =>
          Output <= tOutput & ADC_D(15 downto 8);
          status <=           ADC_D( 7 downto 0);
          state  <= "01110";
--------------------------------------------------------------------------------

        when "01110" =>
          ADC_nCS <= '1';
          state   <= "01111";
--------------------------------------------------------------------------------

        when "01111" =>
          ADC_WnR <= '1';
          state   <= "00101";
--------------------------------------------------------------------------------

        when "10000" =>
          ADC_D <= Address;
          state <= "10001";
--------------------------------------------------------------------------------

        when "10001" =>
          ADC_nCS  <= '0';
          count    <= "00000000000000000000011111";
          retstate <= "10010";
          state    <= "11111";
--------------------------------------------------------------------------------

        when "10010" =>
          ADC_nCS  <= '1';
          ADC_D    <= Data;
          count    <= "00000000000000000000011111";
          retstate <= "10011";
          state    <= "11111";
--------------------------------------------------------------------------------

        when "10011" =>
          ADC_nCS <= '0';
          count    <= "00000000000000000000011111";
          retstate <= "10100";
          state    <= "11111";
--------------------------------------------------------------------------------

        when "10100" =>
          ADC_nCS  <= '1';
          ADC_D    <= (others => 'Z');
          count    <= "00000000000000000000011111";
          retstate <= retstate2;
          state    <= "11111";
--------------------------------------------------------------------------------

        when "11111" =>
          if count = "00000000000000000000000000" then
            state <= retstate;
          end if;
          count <= count - '1';
--------------------------------------------------------------------------------

        when others =>
      end case;
    end if;
  end process;
end architecture a1;
