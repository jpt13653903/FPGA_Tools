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

entity AD9858 is
  port(
    nReset  : in  std_logic;
    Clk     : in  std_logic; -- 10 MHz

    CFR         : in std_logic_vector(31 downto 0);
    DFTW        : in std_logic_vector(31 downto 0);
    DFRRW       : in std_logic_vector(15 downto 0);
    FTW0        : in std_logic_vector(31 downto 0);
    POW0        : in std_logic_vector(13 downto 0);
    FTW1        : in std_logic_vector(31 downto 0);
    POW1        : in std_logic_vector(13 downto 0);
    FTW2        : in std_logic_vector(31 downto 0);
    POW2        : in std_logic_vector(13 downto 0);
    FTW3        : in std_logic_vector(31 downto 0);
    POW3        : in std_logic_vector(13 downto 0);
    Profile     : in std_logic_vector( 1 downto 0);
    FUD_Period  : in std_logic_vector(31 downto 0); -- T = x * 200 ns; off when 0
      
    DDS_IOReset : out   std_logic;
    DDS_SDIO    : inout std_logic;
    DDS_SClk    : out   std_logic;
    DDS_nCS     : out   std_logic;
    DDS_Reset   : out   std_logic;
    DDS_PS      : out   std_logic_vector(1 downto 0);
    DDS_FUD     : out   std_logic
  );
end entity AD9858;
--------------------------------------------------------------------------------

architecture a1 of AD9858 is
  signal state     : std_logic_vector( 3 downto 0);
  signal retstate  : std_logic_vector( 3 downto 0);
  signal count     : std_logic_vector( 5 downto 0);
 
  signal Data      : std_logic_vector(39 downto 0);
 
  signal tCFR      : std_logic_vector(31 downto 0);
  signal tDFTW     : std_logic_vector(31 downto 0);
  signal tDFRRW    : std_logic_vector(15 downto 0);
  signal tFTW0     : std_logic_vector(31 downto 0);
  signal tPOW0     : std_logic_vector(13 downto 0);
  signal tFTW1     : std_logic_vector(31 downto 0);
  signal tPOW1     : std_logic_vector(13 downto 0);
  signal tFTW2     : std_logic_vector(31 downto 0);
  signal tPOW2     : std_logic_vector(13 downto 0);
  signal tFTW3     : std_logic_vector(31 downto 0);
  signal tPOW3     : std_logic_vector(13 downto 0);
 
  signal tFUD1     : std_logic;
  signal tFUD2     : std_logic;
  signal FUD_Count : std_logic_vector(31 downto 0);
--------------------------------------------------------------------------------

begin
  process(Clk, nReset) is
  begin
    if nReset = '0' then
      state       <= (others => '0');
      count       <= (others => '0');
      Data        <= (others => '0');

      tCFR        <= (others => '0');
      tDFTW       <= (others => '0');
      tDFRRW      <= (others => '0');
      tFTW0       <= (others => '0');
      tPOW0       <= (others => '0');
      tFTW1       <= (others => '0');
      tPOW1       <= (others => '0');
      tFTW2       <= (others => '0');
      tPOW2       <= (others => '0');
      tFTW3       <= (others => '0');
      tPOW3       <= (others => '0');
   
      tFUD1       <= '0';
      tFUD2       <= '0';
      FUD_Count   <= (others => '0');

      DDS_IOReset <= '1';
      DDS_SClk    <= '0';
      DDS_nCS     <= '1';
      DDS_Reset   <= '1';
--------------------------------------------------------------------------------

    elsif rising_edge(Clk) then
      case state is
        when "0000" =>
          DDS_Reset   <= '0';
          DDS_IOReset <= '0';
          DDS_nCS     <= '0';
          state       <= "0001";
--------------------------------------------------------------------------------

        when "0001" =>
          if CFR /= tCFR then
            tCFR     <= CFR;
            Data     <= X"00" & CFR;
            count    <= "100111"; -- 39
            retstate <= "0010";
            state    <= "1110";
          else
            state    <= "0010";
          end if;
--------------------------------------------------------------------------------

        when "0010" =>
          if DFTW /= tDFTW then
            tDFTW    <= DFTW;
            Data     <= X"01" & DFTW;
            count    <= "100111"; -- 39
            retstate <= "0011";
            state    <= "1110";
          else
            state    <= "0011";
          end if;
--------------------------------------------------------------------------------

        when "0011" =>
          if DFRRW /= tDFRRW then
            tDFRRW   <= DFRRW;
            Data     <= X"02" & DFRRW & X"0000";
            count    <= "010111"; -- 23
            retstate <= "0100";
            state    <= "1110";
          else
            state    <= "0100";
          end if;
--------------------------------------------------------------------------------

        when "0100" =>
          if FTW0 /= tFTW0 then
            tFTW0    <= FTW0;
            Data     <= X"03" & FTW0;
            count    <= "100111"; -- 39
            retstate <= "0101";
            state    <= "1110";
          else
            state    <= "0101";
          end if;
--------------------------------------------------------------------------------

        when "0101" =>
          if POW0 /= tPOW0 then
            tPOW0    <= POW0;
            Data     <= X"04" & "00" & POW0 & X"0000";
            count    <= "010111"; -- 23
            retstate <= "0110";
            state    <= "1110";
          else
            state    <= "0110";
          end if;
--------------------------------------------------------------------------------

        when "0110" =>
          if FTW1 /= tFTW1 then
            tFTW1    <= FTW1;
            Data     <= X"05" & FTW1;
            count    <= "100111"; -- 39
            retstate <= "0111";
            state    <= "1110";
          else
            state    <= "0111";
          end if;
--------------------------------------------------------------------------------

        when "0111" =>
          if POW1 /= tPOW1 then
            tPOW1    <= POW1;
            Data     <= X"06" & "00" & POW1 & X"0000";
            count    <= "010111"; -- 23
            retstate <= "1000";
            state    <= "1110";
          else
            state    <= "1000";
          end if;
--------------------------------------------------------------------------------

        when "1000" =>
          if FTW2 /= tFTW2 then
            tFTW2    <= FTW2;
            Data     <= X"07" & FTW2;
            count    <= "100111"; -- 39
            retstate <= "1001";
            state    <= "1110";
          else
            state    <= "1001";
          end if;
--------------------------------------------------------------------------------

        when "1001" =>
          if POW2 /= tPOW2 then
            tPOW2    <= POW2;
            Data     <= X"08" & "00" & POW2 & X"0000";
            count    <= "010111"; -- 23
            retstate <= "1010";
            state    <= "1110";
          else
            state    <= "1010";
          end if;
--------------------------------------------------------------------------------

        when "1010" =>
          if FTW3 /= tFTW3 then
            tFTW3    <= FTW3;
            Data     <= X"09" & FTW3;
            count    <= "100111"; -- 39
            retstate <= "1011";
            state    <= "1110";
          else
            state    <= "1011";
          end if;
--------------------------------------------------------------------------------

        when "1011" =>
          if POW3 /= tPOW3 then
            tPOW3    <= POW3;
            Data     <= X"0A" & "00" & POW3 & X"0000";
            count    <= "010111"; -- 23
            retstate <= "1100";
            state    <= "1110";
          else
            state    <= "1100";
          end if;
--------------------------------------------------------------------------------

        when "1100" =>
          tFUD1 <= '1';
          state <= "1101";
--------------------------------------------------------------------------------

        when "1101" =>
          tFUD1 <= '0';
          state <= "0001";
--------------------------------------------------------------------------------

        when "1110" =>
          DDS_SClk <= '1';
          state    <= "1111";
--------------------------------------------------------------------------------

        when "1111" =>
          DDS_SClk <= '0';
          Data     <= Data(38 downto 0) & '0';
     
          if count = "000000" then
            state <= retstate;
          else
            state <= "1110";
          end if;
     
          count <= count - '1';
--------------------------------------------------------------------------------

        when others =>
      end case;
--------------------------------------------------------------------------------

      if    FUD_Period = X"00000000" then
        tFUD2     <= '0';
      elsif FUD_Count  = X"00000000" then
        tFUD2     <= not tFUD2;
        FUD_Count <= FUD_Period - '1';
      else
        tFUD2     <= '0';
        FUD_Count <= FUD_Count  - '1';
      end if;   
    end if;
  end process;
--------------------------------------------------------------------------------

  DDS_SDIO <= Data(39);
  DDS_PS   <= Profile;
  DDS_FUD  <= tFUD1 or tFUD2;
end architecture a1;
--------------------------------------------------------------------------------
