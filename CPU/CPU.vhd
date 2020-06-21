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

entity CPU is
 port(
  nReset     : in std_logic;
  Clk        : in std_logic; -- 10 MHz
  Clk_Cache  : in std_logic; -- 40 MHz
  
  Mutex_Request : out std_logic;
  Mutex_Grant   : in  std_logic;

  Bus_Address : out std_logic_vector(15 downto 0);
  Bus_Latch   : out std_logic;
  Bus_DataOut : out std_logic_vector( 7 downto 0);
  Bus_DataIn  : in  std_logic_vector( 7 downto 0);

  EEPROM_Address : out std_logic_vector(15 downto 0);
  EEPROM_RdData  : in  std_logic_vector(7 downto 0);
  EEPROM_RdLatch : out std_logic;
  EEPROM_WrData  : out std_logic_vector(7 downto 0);
  EEPROM_WrLatch : out std_logic;
  EEPROM_Busy    : in  std_logic
 );
end entity CPU;
--------------------------------------------------------------------------------

architecture a1 of CPU is
 component CPU_Cache is
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
 end component CPU_Cache;
--------------------------------------------------------------------------------

 component CPU_ProgStack is
  port(
   data      : in  std_logic_vector(15 downto 0);
   rdaddress : in  std_logic_vector( 8 downto 0);
   rdclock   : in  std_logic;
   wraddress : in  std_logic_vector( 8 downto 0);
   wrclock   : in  std_logic;
   wren      : in  std_logic;
   q         : out std_logic_vector(15 downto 0)
  );
 end component CPU_ProgStack;
--------------------------------------------------------------------------------

 component CPU_Stack is
  port(
   nReset      : in  std_logic;
   Clk         : in  std_logic;

   Address     : in  std_logic_vector(2 downto 0);
   Input       : in  std_logic_vector(7 downto 0);
   Out0        : out std_logic_vector(7 downto 0);
   Out1        : out std_logic_vector(7 downto 0);
   OutA        : out std_logic_vector(7 downto 0);

   Latch       : in  std_logic;
   Task        : in  std_logic_vector(1 downto 0) 
    --"00" = Store in s0
    --"01" = Push onto stack
    --"10" = Store in s1, then Pop Stack
    --"11" = Swop s0 and sA
  );
 end component CPU_Stack;
--------------------------------------------------------------------------------

 component CPU_Arith is
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
 end component CPU_Arith;
--------------------------------------------------------------------------------

 signal state      : std_logic_vector( 4 downto 0);
 signal ret_state  : std_logic_vector( 4 downto 0);

 signal PC         : std_logic_vector(15 downto 0); 
                     -- Program counter
 signal Prog       : std_logic_vector( 7 downto 0); 
                     -- Program ROM
 signal Prog_Valid : std_logic;                     
                     -- High when the data on Prog is valid

 signal PC_W        : std_logic_vector(15 downto 0); 
                      -- Address to write to program ROM
 signal Prog_Data   : std_logic_vector( 7 downto 0); 
                      -- Data to be written to program ROM
 signal Prog_Latch  : std_logic;
 signal Prog_WrBusy : std_logic;

 signal Bus_tData    : std_logic_vector( 7 downto 0);
 signal Bus_tAddress : std_logic_vector(15 downto 0);

 signal S_Address : std_logic_vector(2 downto 0);
 signal S_Input   : std_logic_vector(7 downto 0);
 signal S_Out0    : std_logic_vector(7 downto 0);
 signal S_Out1    : std_logic_vector(7 downto 0);
 signal S_OutA    : std_logic_vector(7 downto 0);
 signal S_Latch   : std_logic;
 signal S_Task    : std_logic_vector(1 downto 0);

 signal PS_Top     : std_logic_vector(15 downto 0);
 signal PS_Latch   : std_logic;
 signal PS_Address : std_logic_vector( 8 downto 0);
 signal PS_Data    : std_logic_vector(15 downto 0);

 signal Mul_A : std_logic_vector( 7 downto 0);
 signal Mul_B : std_logic_vector( 7 downto 0);
 signal Mul_Y : std_logic_vector(15 downto 0);

 signal Arith_A        : std_logic_vector(7 downto 0);
 signal Arith_B        : std_logic_vector(7 downto 0);
 signal Arith_Out      : std_logic_vector(7 downto 0);
 signal Arith_Task     : std_logic_vector(3 downto 0);
 signal Arith_Carry    : std_logic;
 signal Arith_Zero     : std_logic;

 signal Opcode  : std_logic_vector( 7 downto 0);
 signal Temp    : std_logic_vector( 7 downto 0);
 signal Temp2   : std_logic_vector( 7 downto 0);
 signal Div_Num : std_logic_vector(15 downto 0);

 signal Carry : std_logic;
 signal Zero  : std_logic;

 signal Skip : std_logic;

 signal PCp1 : std_logic_vector(15 downto 0); --PC + 1
 signal PCpS : std_logic_vector(15 downto 0); --PC + Skip count
--------------------------------------------------------------------------------

begin
 Cache1 : CPU_Cache port map(
  nReset,
  Clk_Cache,

  PC,
  Prog,
  Prog_Valid,

  PC_W,
  Prog_Data,
  Prog_Latch,
  Prog_WrBusy,

  EEPROM_Address,
  EEPROM_RdData,
  EEPROM_RdLatch,
  EEPROM_WrData,
  EEPROM_WrLatch,
  EEPROM_Busy
 );

 PC_Stack : CPU_ProgStack port map(
  PS_Data,
  PS_Address,
  not Clk,
  PS_Address,
  not Clk,
  PS_Latch,
  PS_Top
 );

 Stack1 : CPU_Stack port map(
  nReset,
  Clk,
  S_Address,
  S_Input,
  S_Out0,
  S_Out1,
  S_OutA,
  S_Latch,
  S_Task
 );

 Arith1 : CPU_Arith port map(
  Arith_A,
  Arith_B,
  Arith_Task,
  Carry,
  Zero,
  Arith_Out,
  Arith_Carry,
  Arith_Zero
 );

 Mul_Y <= Mul_A * Mul_B;

 Skip <= ((not Carry) and Prog(7)) or ((not Zero) and Prog(6));
 PCp1 <= PC + '1';
 with Prog(5 downto 0) select
  PCpS <= PC + "10" when "101010" |
                         "101100" |
                         "111000" ,
          PC + "11" when "101011" |
                         "101101" |
                         "101110" |
                         "101111" |
                         "111001" |
                         "111010" |
                         "111011" |
                         "111100" |
                         "111101" |
                         "111110" |
                         "111111" ,
          PCp1      when others;

 process(Clk, nReset) is
 begin
  if nReset = '0' then
   state     <= "00000";
   ret_state <= "00000";

   PC         <= "0000000000000000";
   Prog_Data  <= "00000000";
   Prog_Latch <= '0';
   Opcode     <= "00000000";

   S_Address <= "000";
   S_Latch   <= '0';
   S_Task    <= "00";

   PS_Address <= "111111111";
   PS_Data    <= "0000000000000000";
   PS_Latch   <= '0';

   Mutex_Request <= '0';

   Bus_tData    <= "00000000";
   Bus_tAddress <= "0000000000000000";
   Bus_Latch    <= '0';

   Arith_A    <= "00000000";
   Arith_B    <= "00000000";
   Arith_Task <= "0000";

   Mul_A    <= "00000000";
   Mul_B    <= "00000000";

   Temp      <= "00001010"; --Startup wait for 10 cycles
   Temp2     <= "00000000";
   Div_Num   <= "0000000000000000";

   Carry     <= '0';
   Zero      <= '0';
  elsif rising_edge(Clk) then
   case state is
--Decode instruction and do first part
    when "00000" =>
     Mutex_Request <= '0';
     if Prog_Valid = '1' then
      S_Latch    <= '0';
      PS_Latch   <= '0';
      Prog_Latch <= '0';
      Bus_Latch  <= '0';
      if Skip = '1' then -- Instruction prefix = {c; z; cz}
       PC    <= PCpS;
       state <= "00000";
      else
       case Prog(5 downto 0) is
        when "000000" |  -- adc
             "000001" => -- adc pop
         Arith_A <= S_Out1;
         Arith_B <= S_Out0;
         Arith_Task <= "0001";
         S_Task(0) <= '0';
         S_Task(1) <= Prog(0);
         PC <= PCp1;
         state <= "00001";
        when "000010" |  -- add
             "000011" => -- add pop
         Arith_A <= S_Out1;
         Arith_B <= S_Out0;
         Arith_Task <= "0010";
         S_Task(0) <= '0';
         S_Task(1) <= Prog(0);
         PC <= PCp1;
         state <= "00001";
        when "000100" |  -- and
             "000101" => -- and pop
         Arith_A <= S_Out1;
         Arith_B <= S_Out0;
         Arith_Task <= "0011";
         S_Task(0) <= '0';
         S_Task(1) <= Prog(0);
         PC <= PCp1;
         state <= "00001";
        when "000110" |  -- div
             "000111" => -- div pop
         Arith_Task <= "0000";
         S_Address  <= "010";
         state      <= "00101";
        when "001000" |  -- mul
             "001001" => -- mul pop
         Arith_Task <= "0000";
         Mul_A <= S_Out1;
         Mul_B <= S_Out0;
         S_Task(0) <= '0';
         S_Task(1) <= Prog(0);
         state <= "00010";
        when "001010" => -- neg
         Arith_A <= S_Out0;
         Arith_Task <= "0100";
         S_Task <= "00";
         PC <= PCp1;
         state <= "00001";
        when "001011" => -- not
         Arith_A <= S_Out0;
         Arith_Task <= "0101";
         S_Task <= "00";
         PC <= PCp1;
         state <= "00001";
        when "001100" |  -- or
             "001101" => -- or pop
         Arith_A <= S_Out1;
         Arith_B <= S_Out0;
         Arith_Task <= "0110";
         S_Task(0) <= '0';
         S_Task(1) <= Prog(0);
         PC <= PCp1;
         state <= "00001";
        when "001110" |  -- sbb
             "001111" => -- sbb pop
         Arith_A <= S_Out1;
         Arith_B <= S_Out0;
         Arith_Task <= "0111";
         S_Task(0) <= '0';
         S_Task(1) <= Prog(0);
         PC <= PCp1;
         state <= "00001";
        when "010000" |  -- sub
             "010001" => -- sub pop
         Arith_A <= S_Out1;
         Arith_B <= S_Out0;
         Arith_Task <= "1000";
         S_Task(0) <= '0';
         S_Task(1) <= Prog(0);
         PC <= PCp1;
         state <= "00001";
        when "010010" |  -- xor
             "010011" => -- xor pop
         Arith_A <= S_Out1;
         Arith_B <= S_Out0;
         Arith_Task <= "1001";
         S_Task(0) <= '0';
         S_Task(1) <= Prog(0);
         PC <= PCp1;
         state <= "00001";
        when "010100" => -- rcl
         Arith_A <= S_Out0;
         Arith_Task <= "1010";
         S_Task <= "00";
         PC <= PCp1;
         state <= "00001";
        when "010101" => -- rcr
         Arith_A <= S_Out0;
         Arith_Task <= "1011";
         S_Task <= "00";
         PC <= PCp1;
         state <= "00001";
        when "010110" => -- rol
         Arith_A <= S_Out0;
         Arith_Task <= "1100";
         S_Task <= "00";
         PC <= PCp1;
         state <= "00001";
        when "010111" => -- ror 
         Arith_A <= S_Out0;
         Arith_Task <= "1101";
         S_Task <= "00";
         PC <= PCp1;
         state <= "00001";
        when "011000" => -- shl
         Arith_A <= S_Out0;
         Arith_Task <= "1110";
         S_Task <= "00";
         PC <= PCp1;
         state <= "00001";
        when "011001" => -- shr
         Arith_A <= S_Out0;
         Arith_Task <= "1111";
         S_Task <= "00";
         PC <= PCp1;
         state <= "00001";
        when "011010" => -- cc
         Carry <= '0';
         PC <= PCp1;
         state <= "00000";
        when "011011" => -- cz
         Zero <= '0';
         PC <= PCp1;
         state <= "00000";
        when "011100" => -- nc
         Carry <= not Carry;
         PC <= PCp1;
         state <= "00000";
        when "011101" => -- nz
         Zero <= not Zero;
         PC <= PCp1;
         state <= "00000";
        when "011110" => -- sc
         Carry <= '1';
         PC <= PCp1;
         state <= "00000";
        when "011111" => -- sz
         Zero <= '1';
         PC <= PCp1;
         state <= "00000";
        when "100000" |  -- swp 0
             "100001" |  -- swp 1
             "100010" |  -- swp 2
             "100011" |  -- swp 3
             "100100" |  -- swp 4
             "100101" |  -- swp 5
             "100110" |  -- swp 6
             "100111" => -- swp 7
         Arith_Task <= "0000";
         S_Address <= Prog(2 downto 0);
         S_Task    <= "11";
         PC <= PCp1;
         state <= "00001";
        when "101000" => -- pop
         Arith_Task <= "0000";
         Arith_A    <= S_Out1;
         S_Task     <= "10";
         PC         <= PCp1;
         state      <= "00001";
        when "101001" => -- ret
         PC <= PS_Top;
         PS_Address <= PS_Address - '1';
         state <= "01001";
        when "101010" |  -- call rel ??? | call ???
             "101011" => -- call abs ???
         PS_Data    <= PCpS;
         PS_Address <= PS_Address + '1';
         state <= "01011";
        when "101100" |  -- jmp rel ??? | jmp ???
             "101101" => -- jmp abs ???
         Opcode <= Prog;
         PC     <= PCp1;
         state  <= "01100";
        when "101110" |  -- ld ???
             "101111" => -- ld ref ???
         Arith_Task <= "0000";
         Opcode     <= Prog;
         PC         <= PCp1;
         ret_state  <= "10010";
         state      <= "01110";
        when "110000" |  -- lds 0
             "110001" |  -- lds 1
             "110010" |  -- lds 2
             "110011" |  -- lds 3
             "110100" |  -- lds 4
             "110101" |  -- lds 5
             "110110" |  -- lds 6
             "110111" => -- lds 7
         Arith_Task <= "0000";
         S_Address  <= Prog(2 downto 0);
         S_Task     <= "01";
         PC         <= PCp1;
         state      <= "10011";
        when "111000" => -- ldi ???
         Arith_Task <= "0000";
         S_Task     <= "01";
         PC         <= PCp1;
         state      <= "10100";
        when "111001" => -- ldpr ???
         Arith_Task <= "0000";
         PC         <= PCp1;
         Opcode     <= "00000001"; --Reference
         ret_state  <= "10101";
         state      <= "01110";
        when "111010" |  -- stpr
             "111011" => -- stpr pop
         Arith_Task <= "0000";
         PC         <= PCp1;
         Opcode(1)  <= Prog(0); --Pop
         Opcode(0)  <= '1'; --Reference
         ret_state  <= "11000";
         state      <= "01110";
        when "111100" |  -- st ???
             "111101" |  -- st ref ???
             "111110" |  -- st pop ???
             "111111" => -- st pop ref ???
         Arith_Task <= "0000";
         Opcode     <= Prog;
         PC         <= PCp1;
         ret_state  <= "11011";
         state      <= "01110";
        when others =>
       end case;
      end if;
     end if;

-- Latch arithmetic stack and set flags
    when "00001" =>
     S_Latch <= '1';
     S_Input <= Arith_Out;
     Carry   <= Arith_Carry;
     Zero    <= Arith_Zero;
     state   <= "00000";

-- Mul
    when "00010" =>
     Arith_A <= Mul_Y(15 downto 8);
     state <= "00011";
    when "00011" =>
     S_Latch <= '1';
     S_Input <= Arith_Out;
     state <= "00100";
    when "00100" =>
     S_Latch <= '0';
     Arith_A <= Mul_Y(7 downto 0);
     if Mul_Y = "0000000000000000" then
      Zero <= '1';
     else
      Zero <= '0';
     end if;
     S_Task  <= "01";
     PC <= PCp1;
     state   <= "00001";

-- Div
    when "00101" =>
     Div_Num(15 downto 8) <= S_OutA;
     Div_Num( 7 downto 0) <= S_Out1;
     Temp      <= "01111111";
     Temp2     <= "01000000";
     Mul_A     <= "10000000";
     Mul_B     <= S_Out0;
     state <= "00110";
    when "00110" =>
     if Prog_Valid = '1' then
      if Mul_Y > Div_Num then
       Mul_A <= (Mul_A and Temp) or Temp2;
      else
       Mul_A <= Mul_A or Temp2;
      end if;
      if Temp2 = "00000000" then
       if Mul_A = "00000000" then
        Zero <= '1';
       else
        Zero <= '0';
       end if;
       S_Task(0) <= '0';
       S_Task(1) <= Prog(0);
       PC <= PCp1;
       state <= "00111";
      else
       state <= "00110";
      end if;
      Temp (6 downto 0) <= Temp (7 downto 1); Temp(7) <= '1';
      Temp2(6 downto 0) <= Temp2(7 downto 1);
     end if;

-- Pop or store twice - to get the LSb and stack correct
    when "00111" =>
     S_Latch <= '1';
     S_Input <= Arith_Out;
     state   <= "01000";
    when "01000" =>
     S_Latch <= '0';
     Arith_A <= Mul_A;
     state   <= "00001";

-- Latch new program stack address
    when "01001" =>
     PS_Data <= PS_Top;
     state   <= "01010";
    when "01010" =>
     PS_Latch <= '1';
     state    <= "00000";

-- Latch PC onto stack;
    when "01011" =>
     if Prog_Valid = '1' then
      PS_Latch <= '1';
      Opcode   <= Prog;
      PC       <= PCp1;
      state    <= "01100";
     end if;

-- Jump
    when "01100" =>
     if Prog_Valid = '1' then
     Temp <= Prog;
      if Opcode(0) = '1' then
       PC    <= PCp1;
       state <= "01101";
      else
       if Prog(7) = '1' then --negative jump
        PC <= (PC + X"FEFF") + Prog; --PC-1 + sign extend + offset
       else
        PC <= (PC + X"FFFF") + Prog; --PC-1 + offset
       end if;
       state <= "00000";
      end if;
     end if;
    when "01101" =>
     if Prog_Valid = '1' then
      PC( 7 downto 0) <= Temp;
      PC(15 downto 8) <= Prog;
      state <= "00000";
     end if;

-- ld
    when "01110" =>
     if Prog_Valid = '1' then
      Temp <= Prog;
      PC <= PCp1;
      state <= "01111";
     end if;
    when "01111" =>
     if Prog_Valid = '1' then
      Bus_tAddress(15 downto 8) <= Prog;
      Bus_tAddress( 7 downto 0) <= Temp;
      Mutex_Request <= '1';
      if Mutex_Grant = '1' then
       state <= "10000";
      end if;
     end if;
    when "10000" =>
     if Opcode(0) = '1' then
      Temp <= Bus_DataIn;
      Bus_tAddress <= Bus_tAddress + '1';
      state <= "10001";
     else
      state <= ret_state;
     end if;
    when "10001" =>
     Bus_tAddress(15 downto 8) <= Bus_DataIn;
     Bus_tAddress( 7 downto 0) <= Temp;
     state <= ret_state;
    when "10010" =>
     Arith_A <= Bus_DataIn;
     S_Task  <= "01";
     PC      <= PCp1;
     state   <= "00001";

-- Push S_OutA onto stack;
    when "10011" =>
     Arith_A <= S_OutA;
     state <= "00001";

-- Push Prog onto stack;
    when "10100" =>
     if Prog_Valid = '1' then
      Arith_A <= Prog;
      PC      <= PCp1;
      state   <= "00001";
     end if;

-- ldpr
    when "10101" =>
     PC_W <= PCp1;
     PC <= Bus_tAddress;
     state <= "10111";
    when "10111" =>
     if Prog_Valid = '1' then
      Arith_A <= Prog;
      S_Task  <= "01";
      PC      <= PC_W;
      state   <= "00001";
     end if;

-- stpr
    when "11000" =>
     PC_W <= Bus_tAddress;
     Prog_Data <= S_Out0;
     PC <= PCp1;
     state <= "11010";
    when "11010" =>
     if Prog_WrBusy = '0' then
      Prog_Latch <= '1';
      state <= "11101";
     end if;
    when "11101" =>
     if Prog_WrBusy = '1' then
      Prog_Latch <= '0';
      if Opcode(1) = '1' then
       Arith_A <= S_Out1;
       S_Task  <= "10";
       state   <= "00001";
      else
       state <= "00000";
      end if;
     end if;

-- st
    when "11011" =>
     Bus_tData <= S_Out0;
     PC        <= PCp1;
     state     <= "11100";
    when "11100" =>
     Bus_Latch <= '1';
     if Opcode(1) = '1' then
      Arith_A <= S_Out1;
      S_Task  <= "10";
      state   <= "00001";
     else
      state <= "00000";
     end if;
    when others =>
   end case;
  end if;
 end process;

 Bus_DataOut <= Bus_tData;
 Bus_Address <= Bus_tAddress;
end architecture a1;
--------------------------------------------------------------------------------
