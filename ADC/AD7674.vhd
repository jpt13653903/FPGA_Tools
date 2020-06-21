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

entity AD7674 is
  port(
    nReset : in std_logic;
    Clk    : in std_logic; -- 45 MHz
    Sync   : in std_logic; -- 351.563 kHz
  
    Reset  : out std_logic;
    nCnvSt : out std_logic;
    Busy   : in  std_logic_vector(2 downto 1);
    SClk   : out std_logic;
    Data   : in  std_logic_vector(2 downto 1);
  
    Clip   : out std_logic;
    Level3 : out std_logic;
    Level2 : out std_logic;
    Level1 : out std_logic;
    Level0 : out std_logic;

    DataOut : out std_logic_vector(35 downto 0) -- 2x 18-bit
  );
end entity AD7674;

architecture a1 of AD7674 is
  signal state   : std_logic_vector( 1 downto 0);
  signal count   : std_logic_vector( 4 downto 0);
  signal tData1  : std_logic_vector(16 downto 0);
  signal tData2  : std_logic_vector(16 downto 0);
  signal pSync   : std_logic;
--------------------------------------------------------------------------------
 
  signal DataOut1   : std_logic_vector(17 downto 0);
  signal DataOut2   : std_logic_vector(17 downto 0);
  signal DataOut1_DC: std_logic_vector(17 downto 0);
  signal DataOut2_DC: std_logic_vector(17 downto 0);
  signal DataOut1_AC: std_logic_vector(18 downto 0);
  signal DataOut2_AC: std_logic_vector(18 downto 0);
--------------------------------------------------------------------------------

  signal ClipCount   : std_logic_vector(18 downto 0);
  signal AbsDataOut1 : std_logic_vector(18 downto 0);
  signal AbsDataOut2 : std_logic_vector(18 downto 0);
--------------------------------------------------------------------------------

  component SubSample18 is
    port(
      nReset : in std_logic;
      Clk    : in std_logic;
  
      Input  : in  std_logic_vector(17 downto 0);
      Output : out std_logic_vector(17 downto 0) -- /2^18
    );
  end component SubSample18;
--------------------------------------------------------------------------------

begin
  Reset  <= not nReset;

  process(Clk, nReset) is
  begin
    if nReset = '0' then
      state   <= "00";
      nCnvSt  <= '1';
      SClk    <= '0';
      tData1  <= (others => '0');
      tData2  <= (others => '0');
      DataOut <= (others => '0');
      pSync   <= '1';
      Clip    <= '0';
      Level3  <= '0';
      Level2  <= '0';
      Level1  <= '0';
      Level0  <= '0';
    elsif rising_edge(Clk) then
      pSync <= Sync;
  
      case state is
        when "00" =>
          if (pSync = '0') and (Sync = '1') then
            case DataOut1_AC(18 downto 17) is
              when "00" =>
                DataOut(35 downto 18) <= DataOut1_AC(17 downto 0);
              when "01" =>
                DataOut(35 downto 18) <= "011111111111111111";
              when "10" =>
                DataOut(35 downto 18) <= "100000000000000000";
              when "11" =>
                DataOut(35 downto 18) <= DataOut1_AC(17 downto 0);
            end case;

            case DataOut2_AC(18 downto 17) is
              when "00" =>
                DataOut(17 downto 0) <= DataOut2_AC(17 downto 0);
              when "01" =>
                DataOut(17 downto 0) <= "011111111111111111";
              when "10" =>
                DataOut(17 downto 0) <= "100000000000000000";
              when "11" =>
                DataOut(17 downto 0) <= DataOut2_AC(17 downto 0);
            end case;
      
            if (AbsDataOut1 > X"3D7") or -- -40 dB
               (AbsDataOut2 > X"3D7") then
              Level0 <= '1';
            else
              Level0 <= '0';
            end if;

            if (AbsDataOut1 > X"C25") or -- -30 dB
               (AbsDataOut2 > X"C25") then
              Level1 <= '1';
            else
              Level1 <= '0';
            end if;

            if (AbsDataOut1 > X"2666") or -- -20 dB
               (AbsDataOut2 > X"2666") then
              Level2 <= '1';
            else
              Level2 <= '0';
            end if;

            if (AbsDataOut1 > X"796E") or -- -10 dB
               (AbsDataOut2 > X"796E") then
              Level3 <= '1';
            else
              Level3 <= '0';
            end if;

            if (AbsDataOut1 > X"18000") or -- 0 dB (Op-Amp buffer clips)
               (AbsDataOut2 > X"18000") then
              ClipCount <= "1010101110101001011"; -- 351563 (1s)
              Clip <= '1';
            else
              if ClipCount = "0000000000000000000" then
                Clip <= '0';
              else
                ClipCount <= ClipCount - '1';
              end if;
            end if;

            nCnvSt <= '0';
          end if;
          if Busy = "11" then
            state <= "01";
          end if;

        when "01" =>
          nCnvSt <= '1';
          count   <= "10010"; -- 18
          if Busy = "00" then
            state <= "11";
          end if;
    
        when "11" =>
          SClk  <= '1';
          count <= count - '1';
          state <= "10";

        when "10" => 
          SClk <= '0';
          if count = "00000" then
            DataOut1 <= tData1 & Data(1);
            DataOut2 <= tData2 & Data(2);
            state   <= "00";
          else
            state <= "11";
          end if;
          tData1 <= tData1(15 downto 0) & Data(1);
          tData2 <= tData2(15 downto 0) & Data(2);
    
        when others =>
      end case;
    end if;
  end process;
--------------------------------------------------------------------------------
 
  SubSample1 : SubSample18 port map(
    nReset,
    Sync,
    DataOut1,
    DataOut1_DC
  );
--------------------------------------------------------------------------------
 
  SubSample2 : SubSample18 port map(
    nReset,
    Sync,
    DataOut2,
    DataOut2_DC
  );
--------------------------------------------------------------------------------

  DataOut1_AC <= (DataOut1(17) & DataOut1) - (DataOut1_DC(17) & DataOut1_DC);
  DataOut2_AC <= (DataOut2(17) & DataOut2) - (DataOut2_DC(17) & DataOut2_DC);
--------------------------------------------------------------------------------

  AbsDataOut1 <= DataOut1_AC when DataOut1_AC(18) = '0' else 
                 ((not DataOut1_AC) + '1');
  AbsDataOut2 <= DataOut2_AC when DataOut2_AC(18) = '0' else 
                 ((not DataOut2_AC) + '1');
end architecture a1;
