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

entity CPU_Arith is
  port(
    A        : in  std_logic_vector(7 downto 0);
    B        : in  std_logic_vector(7 downto 0);
    Task     : in  std_logic_vector(3 downto 0);
    Carry_In : in  std_logic;
    Zero_In  : in  std_logic;
    Y        : out std_logic_vector(7 downto 0);
    Carry    : out std_logic;
    Zero     : out std_logic
  );
end entity CPU_Arith;
--------------------------------------------------------------------------------

architecture a1 of CPU_Arith is
  component CPU_Adder is
    port(
      A        : in  std_logic_vector(7 downto 0);
      B        : in  std_logic_vector(8 downto 0);
      Carry_In : in  std_logic;
      Y        : out std_logic_vector(7 downto 0);
      Carry    : out std_logic
    );
  end component CPU_Adder;
--------------------------------------------------------------------------------

  signal A_B    : std_logic_vector(8 downto 0);
  signal A_C_In : std_logic;
  signal A_Y    : std_logic_vector(7 downto 0);
  signal A_C    : std_logic;

  signal tY  : std_logic_vector(7 downto 0);
  signal Y3  : std_logic_vector(7 downto 0);
  signal Y4  : std_logic_vector(7 downto 0);
  signal Y5  : std_logic_vector(7 downto 0);
  signal Y6  : std_logic_vector(7 downto 0);
  signal Y9  : std_logic_vector(7 downto 0);
  signal Y10 : std_logic_vector(7 downto 0);
  signal Y11 : std_logic_vector(7 downto 0);
  signal Y12 : std_logic_vector(7 downto 0);
  signal Y13 : std_logic_vector(7 downto 0);
  signal Y14 : std_logic_vector(7 downto 0);
  signal Y15 : std_logic_vector(7 downto 0);

  signal tC  : std_logic;
  signal tZ  : std_logic;
 
  signal C10 : std_logic;
  signal C11 : std_logic;
--------------------------------------------------------------------------------

begin
  Add1 : CPU_Adder port map(A, A_B, A_C_In, A_Y, A_C);
  with Task select
    A_B(8) <= '1' when "0111" | "1000",
              '0' when others;

  A_B(7 downto 0) <= (not B) when A_B(8) = '1' else B;

  with Task select
    tC <= Carry_In when "0001" | "0111",
          '0'      when others;

  A_C_In <= (not tC) when A_B(8) = '1' else tC;

  Y3 <= A and B;
  Y4 <= Y5 + '1';
  Y5 <= not A;
  Y6 <= A or B;
  Y9 <= A xor B;
  C10 <= A(7); Y10(7 downto 1) <= A(6 downto 0); Y10(0) <= Carry_In;
  C11 <= A(0); Y11(6 downto 0) <= A(7 downto 1); Y11(7) <= Carry_In;
  Y12(7 downto 1) <= A(6 downto 0); Y12(0) <= A(7);
  Y13(6 downto 0) <= A(7 downto 1); Y13(7) <= A(0);
  Y14(7 downto 1) <= A(6 downto 0); Y14(0) <= Carry_In;
  Y15(6 downto 0) <= A(7 downto 1); Y15(7) <= Carry_In;

  with Task select
    tY <= A_Y when "0001" | "0010" | "0111" | "1000",
          Y3  when "0011",
          Y4  when "0100",
          Y5  when "0101",
          Y6  when "0110",
          Y9  when "1001",
          Y10 when "1010",
          Y11 when "1011",
          Y12 when "1100",
          Y13 when "1101",
          Y14 when "1110",
          Y15 when "1111",
          A   when others;
  Y <= tY;

  tZ   <= '1'     when tY   = "00000000" else '0';
  Zero <= Zero_In when Task = "0000"     else tZ ;

  with Task select
    Carry <= A_C      when "0001" | "0010" | "0111" | "1000", 
             C10      when "1010", 
             C11      when "1011", 
             Carry_In when others;
end architecture a1;
--------------------------------------------------------------------------------
