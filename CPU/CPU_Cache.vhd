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

-- This is a 4-page cache for the CPU.
-- Each page is 1 kB and loaded on request.
-- The least recently accessed page is overwritten if required.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--------------------------------------------------------------------------------

entity CPU_Cache is
 port(
  nReset     : in std_logic;
  Clk        : in std_logic;

  RdAddress : in  std_logic_vector(15 downto 0);
  RdData    : out std_logic_vector( 7 downto 0);
  RdValid   : out std_logic;

  WrAddress : in  std_logic_vector(15 downto 0);
  WrData    : in  std_logic_vector( 7 downto 0);
  WrEnable  : in  std_logic;
  WrBusy    : out std_logic;

  EEPROM_Address : out std_logic_vector(15 downto 0);
  EEPROM_RdData  : in  std_logic_vector(7 downto 0);
  EEPROM_RdLatch : out std_logic;
  EEPROM_WrData  : out std_logic_vector(7 downto 0);
  EEPROM_WrLatch : out std_logic;
  EEPROM_Busy    : in  std_logic
 );
end entity CPU_Cache;
--------------------------------------------------------------------------------

architecture a1 of CPU_Cache is
 component CPU_Page is
  port(
   clock     : in  std_logic;
   data      : in  std_logic_vector(7 downto 0);
   rdaddress : in  std_logic_vector(9 downto 0);
   wraddress : in  std_logic_vector(9 downto 0);
   wren      : in  std_logic;
   q         : out std_logic_vector(7 downto 0)
  );
 end component CPU_Page;
--------------------------------------------------------------------------------

 signal state     : std_logic_vector(2 downto 0);
 signal retstate  : std_logic_vector(2 downto 0);
 
 signal tAddress : std_logic_vector(15 downto 0);

 signal Page_Mask : std_logic_vector(3 downto 0);
 signal Page_Page : std_logic_vector(5 downto 0);

 signal Page_RdAddress : std_logic_vector(9 downto 0);
 signal Page_WrAddress : std_logic_vector(9 downto 0);
 signal Page_WrData    : std_logic_vector(7 downto 0);
 signal Page_WrEn      : std_logic_vector(3 downto 0);

 signal Page0_Page      : std_logic_vector(5 downto 0);
 signal Page0_RdData    : std_logic_vector(7 downto 0);

 signal Page1_Page      : std_logic_vector(5 downto 0);
 signal Page1_RdData    : std_logic_vector(7 downto 0);

 signal Page2_Page      : std_logic_vector(5 downto 0);
 signal Page2_RdData    : std_logic_vector(7 downto 0);

 signal Page3_Page      : std_logic_vector(5 downto 0);
 signal Page3_RdData    : std_logic_vector(7 downto 0);

 signal reading : std_logic_vector(15 downto 0);
 signal tValid  : std_logic;
 signal order   : std_logic_vector( 7 downto 0);

 signal tBusy : std_logic;
--------------------------------------------------------------------------------

begin
 EEPROM_Address <= tAddress;
--------------------------------------------------------------------------------

 Page0 : CPU_Page port map(
   not Clk,
   Page_WrData,
   Page_RdAddress,
   Page_WrAddress,
   Page_WrEn(0),
   Page0_RdData
 );
--------------------------------------------------------------------------------

 Page1 : CPU_Page port map(
   not Clk,
   Page_WrData,
   Page_RdAddress,
   Page_WrAddress,
   Page_WrEn(1),
   Page1_RdData
 );
--------------------------------------------------------------------------------

 Page2 : CPU_Page port map(
   not Clk,
   Page_WrData,
   Page_RdAddress,
   Page_WrAddress,
   Page_WrEn(2),
   Page2_RdData
 );
--------------------------------------------------------------------------------

 Page3 : CPU_Page port map(
   not Clk,
   Page_WrData,
   Page_RdAddress,
   Page_WrAddress,
   Page_WrEn(3),
   Page3_RdData
 );
--------------------------------------------------------------------------------

 tValid  <= '1' when RdAddress = reading else '0';
 RdValid <= tValid;
--------------------------------------------------------------------------------

 process(Clk, nReset) is
 begin
  if nReset = '0' then
   state     <= "000";
   retstate  <= "100";

   tAddress       <= (others => '0');
   EEPROM_WrData  <= (others => '0');
   EEPROM_RdLatch <= '0';
   EEPROM_WrLatch <= '0';

   Page_Mask      <= (others => '1');
   Page_Page      <= (others => '0');

   Page_RdAddress <= (others => '0');
   Page_WrAddress <= (others => '0');
   Page_WrData    <= (others => '0');
   Page_WrEn      <= (others => '0');

   Page0_Page <= (others => '0');
   Page1_Page <= (others => '0');
   Page2_Page <= (others => '0');
   Page3_Page <= (others => '0');

   reading <= (others => '1');
   order   <= "11100100";

   tBusy <= '1';
--------------------------------------------------------------------------------

  elsif rising_edge(Clk) then
   case state is

-- Reads the desired page from EEPROM
    -- Page_Page must = tAddress(15 downto 0)
    -- Page_Mask must = Correct page WrEn mask
    -- tAddress must = 0
    when "000" =>
     Page_WrEn      <= "0000";
     Page_WrAddress <= tAddress(9 downto 0);
     
     if Page_Page = tAddress(15 downto 10) then
      if EEPROM_Busy = '0' then
       EEPROM_RdLatch <= '1';
       state          <= "001";
      end if;
      
     else
      state <= retstate;
     end if;
--------------------------------------------------------------------------------

    when "001" =>
     if EEPROM_Busy = '1' then
      EEPROM_RdLatch <= '0';
      state          <= "010";
     end if;
--------------------------------------------------------------------------------

    when "010" =>
     if EEPROM_Busy = '0' then
      Page_WrData <= EEPROM_RdData;
      state       <= "011";
     end if;
--------------------------------------------------------------------------------

    when "011" =>
     Page_WrEn <= Page_Mask;
     tAddress  <= tAddress + '1';
     state     <= "000";
--------------------------------------------------------------------------------

-- Normal Operation
    when "100" =>
     if tValid = '0' then
      Page_RdAddress <= RdAddress(9 downto 0);
      state <= "101";
      
     elsif (tBusy = '0') and (WrEnable = '1') then
      tBusy          <= '1';
      tAddress       <= WrAddress;
      EEPROM_WrData  <= WrData;
      Page_WrAddress <= WrAddress(9 downto 0);
      Page_WrData    <= WrData;
      if Page0_Page = WrAddress(15 downto 10) then
       Page_Mask(0) <= '1';
      else
       Page_Mask(0) <= '0';
      end if;
      if Page1_Page = WrAddress(15 downto 10) then
       Page_Mask(1) <= '1';
      else
       Page_Mask(1) <= '0';
      end if;
      if Page2_Page = WrAddress(15 downto 10) then
       Page_Mask(2) <= '1';
      else
       Page_Mask(2) <= '0';
      end if;
      if Page3_Page = WrAddress(15 downto 10) then
       Page_Mask(3) <= '1';
      else
       Page_Mask(3) <= '0';
      end if;
      state <= "110";
     elsif WrEnable = '0' then
      tBusy <= '0';
     end if;
--------------------------------------------------------------------------------

-- Read the data
    when "101" =>
     if    Page0_Page = RdAddress(15 downto 10) then
      RdData  <= Page0_RdData;
      reading <= RdAddress;
      if    order(7 downto 6) = "00" then
       order(7 downto 2) <= order(5 downto 0);
      elsif order(5 downto 4) = "00" then
       order(5 downto 2) <= order(3 downto 0);
      elsif order(3 downto 2) = "00" then
       order(3 downto 2) <= order(1 downto 0);
      end if;
      order(1 downto 0) <= "00";
      state <= "100";
      
     elsif Page1_Page = RdAddress(15 downto 10) then
      RdData  <= Page1_RdData;
      reading <= RdAddress;
      if    order(7 downto 6) = "01" then
       order(7 downto 2) <= order(5 downto 0);
      elsif order(5 downto 4) = "01" then
       order(5 downto 2) <= order(3 downto 0);
      elsif order(3 downto 2) = "01" then
       order(3 downto 2) <= order(1 downto 0);
      end if;
      order(1 downto 0) <= "01";
      state <= "100";
      
     elsif Page2_Page = RdAddress(15 downto 10) then
      RdData  <= Page2_RdData;
      reading <= RdAddress;
      if    order(7 downto 6) = "10" then
       order(7 downto 2) <= order(5 downto 0);
      elsif order(5 downto 4) = "10" then
       order(5 downto 2) <= order(3 downto 0);
      elsif order(3 downto 2) = "10" then
       order(3 downto 2) <= order(1 downto 0);
      end if;
      order(1 downto 0) <= "10";
      state <= "100";
      
     elsif Page3_Page = RdAddress(15 downto 10) then
      RdData  <= Page3_RdData;
      reading <= RdAddress;
      if    order(7 downto 6) = "11" then
       order(7 downto 2) <= order(5 downto 0);
      elsif order(5 downto 4) = "11" then
       order(5 downto 2) <= order(3 downto 0);
      elsif order(3 downto 2) = "11" then
       order(3 downto 2) <= order(1 downto 0);
      end if;
      order(1 downto 0) <= "11";
      state <= "100";
      
     else
      Page_Page <= RdAddress(15 downto 10);
      case order(7 downto 6) is
       when "00" =>
        Page0_Page <= RdAddress(15 downto 10);
        Page_Mask  <= "0001";
       when "01" =>
        Page1_Page <= RdAddress(15 downto 10);
        Page_Mask  <= "0010";
       when "10" =>
        Page2_Page <= RdAddress(15 downto 10);
        Page_Mask  <= "0100";
       when "11" =>
        Page3_Page <= RdAddress(15 downto 10);
        Page_Mask  <= "1000";
       when others =>
      end case;
      tAddress(15 downto 10) <= RdAddress(15 downto 10);
      tAddress( 9 downto  0) <= "0000000000";
      retstate <= "101";
      state    <= "000";
     end if;
--------------------------------------------------------------------------------

-- Write the new data
    when "110" =>
     if EEPROM_Busy = '0' then
      EEPROM_WrLatch <= '1';
      Page_WrEn <= Page_Mask;
      state <= "111";
     end if;
--------------------------------------------------------------------------------

    when "111" =>
     if EEPROM_Busy = '1' then
      EEPROM_WrLatch <= '0';
      Page_WrEn <= "0000";
      state <= "100";
     end if;
--------------------------------------------------------------------------------

    when others =>
   end case;
  end if;
 end process;
--------------------------------------------------------------------------------

 WrBusy <= tBusy;
end architecture a1;
--------------------------------------------------------------------------------
