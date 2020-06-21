-- J Taylor
-- Last modified 2009-11-23
--------------------------------------------------------------------------------

-- This is an abstracion of the SD-Card. It sopports:
-- > Version 1.X up to 2 GB
-- > Version 2.0 Standard Capacity up to 2 GB
-- > Version 2.0 High Capacity up to 8 GB

-- "Busy" remains high until both "BlockRead" and "BlockWrite" are low.
-- Use "BlockRead" and "BlockWrite" one at a time.
-- A block is 512 Bytes.
-- When a card becomes unresponsive (or is replaced), 
--   "CardError" goes high and process goes into reset.
--   To recover, make "CardPresent" low and then high.

-- The data is double-buffered. Buffers are swaped:
-- > on the rising edge of "Busy" when writing.
-- > when reading from the card is finished and "BlockRead" is low.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--------------------------------------------------------------------------------

entity SD_Card is
  port(
    nReset : in std_logic;
    Clk    : in std_logic; -- max 50 MHz
  
    CardPresent : in  std_logic;
    CardError   : out std_logic;
  
    BlockMaxAddress : out std_logic_vector(31 downto 0);
    BlockAddress    : in  std_logic_vector(31 downto 0);
    BlockRead       : in  std_logic;
    BlockWrite      : in  std_logic;
    Busy            : out std_logic;
 
    DataAddress : in  std_logic_vector(8 downto 0);
    DataIn      : in  std_logic_vector(7 downto 0);
    DataLatch   : in  std_logic;
    DataOut     : out std_logic_vector(7 downto 0);
  
    SD_Data : inout std_logic_vector(3 downto 0);
    SD_CMD  : inout std_logic;
    SD_Clk  : out   std_logic
  );
end entity SD_Card;
--------------------------------------------------------------------------------

architecture a1 of SD_Card is
  component SD_Bus is
    port(
      nReset : in std_logic;
      Clk    : in std_logic;
 
      ClockDiv : in std_logic_vector(6 downto 0);
 
      Command      : in  std_logic_vector( 5 downto 0);
      Argument     : in  std_logic_vector(31 downto 0);
      ResponseType : in  std_logic_vector( 1 downto 0);
      ResponseCRC  : out std_logic;
   
      DataRnW      : in  std_logic;
      SwapOnWrite  : in  std_logic;
      DataWidth    : in  std_logic_vector(8 downto 0);
      DataCRC      : out std_logic;
 
      Execute : in  std_logic;
      Busy    : out std_logic;
 
      Response  : out std_logic_vector(127 downto 0);
 
      DataAddress : in  std_logic_vector(8 downto 0);
      DataIn      : in  std_logic_vector(7 downto 0);
      DataLatch   : in  std_logic;
      DataOut     : out std_logic_vector(7 downto 0);
 
      SD_Data : inout std_logic_vector(3 downto 0);
      SD_CMD  : inout std_logic;
      SD_Clk  : out   std_logic
    );
  end component SD_Bus;
--------------------------------------------------------------------------------

  signal state           : std_logic_vector(  4 downto 0);
  signal retstate        : std_logic_vector(  4 downto 0);
  signal TimeOut         : std_logic_vector( 25 downto 0);
 
  signal tBusy           : std_logic;

  signal ClockDiv        : std_logic_vector(  6 downto 0);
  signal Command         : std_logic_vector(  5 downto 0);
  signal Argument        : std_logic_vector( 31 downto 0);
  signal ResponseType    : std_logic_vector(  1 downto 0);
  signal ResponseCRC     : std_logic;

  signal DataRnW         : std_logic;
  signal SwapOnWrite     : std_logic;
  signal DataWidth       : std_logic_vector(  8 downto 0);
  signal DataCRC         : std_logic;
 
  signal Execute         : std_logic;
  signal BusBusy         : std_logic;
  signal Response        : std_logic_vector(127 downto 0);
 
  signal CardVersion     : std_logic_vector(  1 downto 0);
  signal OCR             : std_logic_vector( 31 downto 0);
  signal RCA             : std_logic_vector( 15 downto 0);

  signal CSD_STRUCTURE   : std_logic_vector(  1 downto 0);
  signal CSD_READ_BL_LEN : std_logic_vector(  3 downto 0);
  signal CSD_TRAN_SPEED  : std_logic_vector(  7 downto 0);
  signal CSD_C_SIZE      : std_logic_vector( 21 downto 0);
  signal CSD_C_SIZE_MULT : std_logic_vector(  2 downto 0);
 
  signal BLOCK_NR        : std_logic_vector( 31 downto 0);
  signal MAX_CLOCK       : std_logic_vector( 19 downto 0); -- kHz
 
  signal A               : std_logic_vector( 13 downto 0);
  signal B               : std_logic_vector(  6 downto 0);
  signal Y               : std_logic_vector( 20 downto 0);
--------------------------------------------------------------------------------

begin
  Y    <= A * B;
  Busy <= BusBusy or tBusy;
--------------------------------------------------------------------------------

  SD_Bus1 : SD_Bus port map(
    nReset,
    Clk,
 
    ClockDiv,
 
    Command,
    Argument,
    ResponseType,
    ResponseCRC,
   
    DataRnW,
    SwapOnWrite,
    DataWidth,
    DataCRC,
 
    Execute,
    BusBusy,
 
    Response,
 
    DataAddress,
    DataIn,
    DataLatch,
    DataOut,
 
    SD_Data,
    SD_CMD,
    SD_Clk
  );
--------------------------------------------------------------------------------

  process(Clk, nReset) is
  begin
    if nReset = '0' then
      state           <= (others => '0');
      retstate        <= (others => '0');
   
      CardError       <= '0';
   
      tBusy           <= '1';
      BlockMaxAddress <= (others => '0');
      TimeOut         <= "00" & X"009C3F"; -- 40e6 => 1 ms
   
      ClockDiv        <= (others => '1'); -- Disabled
      Command         <= (others => '0');
      Argument        <= (others => '0');
      ResponseType    <= (others => '0');
      DataRnW         <= '1';
      SwapOnWrite     <= '1';
      DataWidth       <= (others => '0');
      Execute         <= '0';
   
      CardVersion     <= (others => '0');
      OCR             <= (others => '0');
      RCA             <= (others => '0');
      CSD_STRUCTURE   <= (others => '0');
      CSD_READ_BL_LEN <= (others => '0');
      CSD_TRAN_SPEED  <= (others => '0');
      CSD_C_SIZE      <= (others => '0');
      CSD_C_SIZE_MULT <= (others => '0');
   
      BLOCK_NR        <= (others => '0');
      MAX_CLOCK       <= (others => '0');
   
      A               <= (others => '0');
      B               <= (others => '0');
--------------------------------------------------------------------------------

    elsif rising_edge(Clk) then
      case state is
        when "00000" =>
          Command      <= "000000"; -- Soft Reset
          Argument     <= X"00000000";
          ResponseType <= "00";     -- None
          retstate     <= "00001";
          if CardPresent = '1' then
            ClockDiv <= "1100011"; -- 200 kHz
            if TimeOut = "00" & X"000000" then
              state <= "11100";
            end if;
            TimeOut <= TimeOut - '1';
          else
            TimeOut <= "00" & X"009C3F"; -- 40e6 => 1 ms
          end if;
--------------------------------------------------------------------------------

        when "00001" =>
          Command      <= "001000"; -- Read Interface Condition
          Argument     <= X"000001AA";
          ResponseType <= "01";     -- R7
          retstate     <= "00010";
          state        <= "11100";
--------------------------------------------------------------------------------

        when "00010" =>
          if ResponseCRC = '1' then  -- HD Card
            CardVersion  <= "10";
            state        <= "00011";

          else                       -- Standard Card
            CardVersion  <= "01";
            Command      <= "000000"; -- Soft Reset
            Argument     <= X"00000000";
            ResponseType <= "00";     -- None
            retstate     <= "00011";
            state        <= "11100";
          end if;
--------------------------------------------------------------------------------

        when "00011" =>
          if OCR(31) = '0' then
            Command      <= "110111"; -- Next Command is Application Specific
            Argument     <= X"00000000";
            ResponseType <= "01";     -- R1
            retstate     <= "00100";
            state        <= "11100";
          else
            Command      <= "000010"; -- Read Card Identification Register
            Argument     <= X"00000000";
            ResponseType <= "10";     -- R2
            retstate     <= "00110";
            state        <= "11100";
          end if;
--------------------------------------------------------------------------------

        when "00100" =>
          Command      <= "101001"; -- Set Operating Voltage
          ResponseType <= "01";     -- R3
          if CardVersion = "01" then
            Argument    <= X"00300000";
          else
            Argument    <= X"40300000";
          end if;
          retstate     <= "00101";
          if ResponseCRC = '1' then -- Valid response
            state <= "11100";
          else                      -- No response
            state <= "11000"; -- Reset
          end if;
--------------------------------------------------------------------------------

        when "00101" =>
          OCR <= Response(39 downto 8);
          if Response(7 downto 0) = X"FF" then -- Valid response
            state <= "00011";
          else
            state <= "11000"; -- Reset
          end if;
--------------------------------------------------------------------------------

        when "00110" =>
          -- Store CID if required
     
          Command      <= "000011"; -- Read Relative Card Address
          Argument     <= X"00000000";
          ResponseType <= "01";     -- R6
          retstate     <= "00111";
          if ResponseCRC = '1' then -- Valid response
            state <= "11100";
          else                      -- No response
            state <= "11000"; -- Reset
          end if;
--------------------------------------------------------------------------------

        when "00111" =>
          RCA <= Response(39 downto 24);
     
          Command      <= "001001"; -- Read Card Specific Data Register
          Argument     <= Response(39 downto 24) & X"0000";
          ResponseType <= "10";     -- R2
          retstate     <= "01000";
          if ResponseCRC = '1' then -- Valid response
            state <= "11100";
          else                      -- No response
            state <= "11000"; -- Reset
          end if;
--------------------------------------------------------------------------------

        when "01000" =>
          CSD_STRUCTURE   <= Response(127 downto 126);
          CSD_TRAN_SPEED  <= Response(103 downto  96);
          CSD_READ_BL_LEN <= Response( 83 downto  80);

          case Response(127 downto 126) is
            when "00" => -- Standard Capacity
              CSD_C_SIZE_MULT <=                    Response(49 downto 47);
              BLOCK_NR        <= (("00" & X"0000" & Response(73 downto 62)) + '1') & "00";
            when "01" => -- High Capacity
              CSD_C_SIZE_MULT <= "000";
              BLOCK_NR        <= (Response(69 downto 48) + '1') & "0000000000";
            when others =>
          end case;
     
          if ResponseCRC = '1' then -- Valid response
            state <= "01001";
          else
            state <= "11000"; -- Reset
          end if;
--------------------------------------------------------------------------------

        when "01001" =>
          if CSD_C_SIZE_MULT = "000" then
            state           <= "01010";
          else
            BLOCK_NR        <= BLOCK_NR(30 downto 0) & '0';
            CSD_C_SIZE_MULT <= CSD_C_SIZE_MULT - '1';
          end if;
--------------------------------------------------------------------------------

        when "01010" =>
          case CSD_READ_BL_LEN is
            when X"9" => --  512 Byte Block
              BlockMaxAddress <=  BLOCK_NR - '1';
            when X"A" => -- 1024 Byte Block
              BLOCK_NR        <=  BLOCK_NR(30 downto 0) & '0';
              BlockMaxAddress <= (BLOCK_NR(30 downto 0) & '0') - '1';
            when X"B" => -- 2048 Byte Block
              BLOCK_NR        <=  BLOCK_NR(29 downto 0) & "00";
              BlockMaxAddress <= (BLOCK_NR(29 downto 0) & "00") - '1';
            when others =>
              BLOCK_NR        <= (others => '0');
              BlockMaxAddress <= (others => '0');
          end case;     
     
          case CSD_TRAN_SPEED(2 downto 0) is
            when "000" =>
              A <= "00000000001010"; --     10
            when "001" =>
              A <= "00000001100100"; --    100
            when "010" =>
              A <= "00001111101000"; --  1 000
            when "011" =>
              A <= "10011100010000"; -- 10 000
            when others =>
              A <= (others => '0');
          end case;
     
          case CSD_TRAN_SPEED(6 downto 3) is
            when X"1" =>
              B <= "0001010"; -- 10
            when X"2" =>
              B <= "0001100"; -- 12
            when X"3" =>
              B <= "0001101"; -- 13
            when X"4" =>
              B <= "0001111"; -- 15
            when X"5" =>
              B <= "0010100"; -- 20
            when X"6" =>
              B <= "0011001"; -- 25
            when X"7" =>
              B <= "0011110"; -- 30
            when X"8" =>
              B <= "0100011"; -- 35
            when X"9" =>
              B <= "0101000"; -- 40
            when X"A" =>
              B <= "0101101"; -- 45
            when X"B" =>
              B <= "0110010"; -- 50
            when X"C" =>
              B <= "0110111"; -- 55
            when X"D" =>
              B <= "0111100"; -- 60
            when X"E" =>
              B <= "1000110"; -- 70
            when X"F" =>
              B <= "1010000"; -- 80
            when others =>
              B <= (others => '0');
          end case;
     
          state <= "01011";
--------------------------------------------------------------------------------

        when "01011" =>
          MAX_CLOCK <= Y(19 downto 0);

          if Y >= X"04E20" then -- 20 MHz
            ClockDiv <= (others => '0');
          end if;
     
          Command      <= "000111"; -- Set to Transfer State
          Argument     <= RCA & X"0000";
          ResponseType <= "01";     -- R1b
          retstate     <= "01100";
          state        <= "11100";
--------------------------------------------------------------------------------

        when "01100" =>
          Command      <= "010000"; -- Set Block Length to 512 Bytes
          Argument     <= X"00000200";
          ResponseType <= "01";     -- R1
          retstate     <= "01101";
          if ResponseCRC = '1' then -- Valid response
            state        <= "11100";
          else                      -- No response
            state <= "11000"; -- Reset
          end if;
--------------------------------------------------------------------------------

        when "01101" =>
          Command      <= "110111"; -- Next Command is Application Specific
          Argument     <= RCA & X"0000";
          ResponseType <= "01";     -- R1
          retstate     <= "01110";
          if ResponseCRC = '1' then -- Valid response
            state        <= "11100";
          else                      -- No response
            state <= "11000"; -- Reset
          end if;
--------------------------------------------------------------------------------

        when "01110" =>
          Command      <= "000110"; -- Set Data Width to 4 Lines
          Argument     <= X"00000002";
          ResponseType <= "01";     -- R1
          retstate     <= "01111";
          if ResponseCRC = '1' then -- Valid response
            state        <= "11100";
          else                      -- No response
            state <= "11000"; -- Reset
          end if;
--------------------------------------------------------------------------------

        when "01111" =>
          if (BlockRead = '0') and (BlockWrite = '0') then
            tBusy <= '0';
            state <= "10000";
          end if;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

        when "10000" =>
          if (ResponseCRC = '1') and (CardPresent = '1') then -- Valid response
            tBusy <= '0';
      
            if TimeOut = "00" & X"000000" then
              TimeOut      <= "10" & X"6259FF"; -- 40e6 => 1 sec
              Command      <= "001101"; -- Get Status
              Argument     <= RCA & X"0000";
              ResponseType <= "01";     -- R1
              DataRnW      <= '1';
              DataWidth    <= (others => '0');
              retstate     <= "10000";
              state        <= "11100";
       
            elsif (BlockAddress < BLOCK_NR) and (BlockRead = '1') then
              TimeOut      <= "10" & X"6259FF"; -- 40e6 => 1 sec
              Command      <= "010001"; -- Read Data
              ResponseType <= "01";     -- R1
              if CSD_STRUCTURE = "00" then
                Argument    <= BlockAddress(22 downto 0) & "000000000";
              else
                Argument    <= BlockAddress;
              end if;
              DataRnW      <= '1';
              DataWidth    <= "1" & X"FF";
              retstate     <= "10001";
              state        <= "11100";
      
            elsif (BlockAddress < BLOCK_NR) and (BlockWrite = '1') then
              TimeOut      <= "10" & X"6259FF"; -- 40e6 => 1 sec
              Command      <= "011000"; -- Write Data
              ResponseType <= "01";     -- R1
              if CSD_STRUCTURE = "00" then
                Argument    <= BlockAddress(22 downto 0) & "000000000";
              else
                Argument    <= BlockAddress;
              end if;
              DataRnW      <= '0';
              DataWidth    <= "1" & X"FF";
              retstate     <= "10001";
              state        <= "11100";

            else
              TimeOut <= TimeOut - '1';
            end if;
      
          else -- No response
            state <= "11000"; -- Reset
          end if;
--------------------------------------------------------------------------------
     
        when "10001" =>
          if ResponseCRC = '1' then
            if DataCRC = '1' then
              tBusy       <= '0';
              SwapOnWrite <= '1';
              state       <= "10000";
            else
              TimeOut     <= "10" & X"6259FF"; -- 40e6 => 1 sec
              SwapOnWrite <= '0';
              state       <= "11100";
            end if;
          else
            state <= "11000";
          end if;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

        when "11000" => -- Reset
          retstate        <= (others => '0');
   
          tBusy           <= '1';
          BlockMaxAddress <= (others => '0');
          TimeOut         <= "00" & X"009C3F"; -- 40e6 => 1 ms
   
          ClockDiv        <= (others => '1'); -- Disabled
          Command         <= (others => '0');
          Argument        <= (others => '0');
          ResponseType    <= (others => '0');
          DataRnW         <= '1';
          SwapOnWrite     <= '1';
          DataWidth       <= (others => '0');
          Execute         <= '0';
   
          CardVersion     <= (others => '0');
          OCR             <= (others => '0');
          RCA             <= (others => '0');
          CSD_STRUCTURE   <= (others => '0');
          CSD_READ_BL_LEN <= (others => '0');
          CSD_TRAN_SPEED  <= (others => '0');
          CSD_C_SIZE      <= (others => '0');
          CSD_C_SIZE_MULT <= (others => '0');
   
          BLOCK_NR        <= (others => '0');
          MAX_CLOCK       <= (others => '0');
   
          A               <= (others => '0');
          B               <= (others => '0');
     
          if CardPresent = '0' then
            CardError <= '0';
            state <= "00000";
          else
            CardError <= '1';
          end if;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

        when "11100" => -- Execute Command
          if BusBusy = '0' then
            Execute <= '1';
            state   <= "11101";
          end if;
--------------------------------------------------------------------------------

        when "11101" =>
          if BusBusy = '1' then
            tBusy <= '1';
            state <= "11110";
          end if;
--------------------------------------------------------------------------------

        when "11110" =>
          if (BlockRead = '0') and (BlockWrite = '0') then
            Execute <= '0';
            state   <= "11111";
          end if;
--------------------------------------------------------------------------------

        when "11111" =>
          if BusBusy = '0' then
            state <= retstate;
          end if;
--------------------------------------------------------------------------------

        when others =>
      end case;
    end if;
  end process;
end architecture a1;
--------------------------------------------------------------------------------
