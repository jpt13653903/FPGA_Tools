-- J Taylor
-- Last modified 2009-11-23
--------------------------------------------------------------------------------

-- This is an abstraction of the SD-Card physical interface.

-- "Busy" remains high until "Execute" goes low.
-- CRC checks are performed on both read and write.
--   Data is re-read or re-written on a CRC fault
-- Set DataWidth to zero when no data is to be transferred.
-- Leave "DataRnW" high unless data is to be written.

-- The data is double-buffered. Buffers are swaped:
-- > on the rising edge of "Busy" when executing a command with "DataRnW" low.
-- > when reading from the card is finished and "Execute" is low.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--------------------------------------------------------------------------------

entity SD_Bus is
  port(
    nReset : in std_logic;
    Clk    : in std_logic; -- max 50 MHz
 
    ClockDiv : in std_logic_vector(6 downto 0); -- the card clock is Clk / 
                                                -- 2xClockDiv + 2
 
    Command      : in  std_logic_vector( 5 downto 0);
    Argument     : in  std_logic_vector(31 downto 0);
    ResponseType : in  std_logic_vector( 1 downto 0); -- 0 = none,
                                                      -- 1 = short,
                                                      -- 2 = long
    ResponseCRC  : out std_logic;
  
    DataRnW      : in  std_logic;
    SwapOnWrite  : in  std_logic;
    DataWidth    : in  std_logic_vector(8 downto 0); -- No of bytes - 1
    DataCRC      : out std_logic;
 
    Execute : in  std_logic;
    Busy    : out std_logic;
 
    Response  : out std_logic_vector(127 downto 0); -- use 37 downto 0 for short
 
    DataAddress : in  std_logic_vector(8 downto 0);
    DataIn      : in  std_logic_vector(7 downto 0);
    DataLatch   : in  std_logic;
    DataOut     : out std_logic_vector(7 downto 0);
 
    SD_Data : inout std_logic_vector(3 downto 0);
    SD_CMD  : inout std_logic;
    SD_Clk  : out   std_logic
  );
end entity SD_Bus;
--------------------------------------------------------------------------------

architecture a1 of SD_Bus is
  component SD_RAM is
    port(
      Data      : in  std_logic_vector(7 downto 0);
      rdAddress : in  std_logic_vector(8 downto 0);
      rdClock   : in  std_logic;
      wrAddress : in  std_logic_vector(8 downto 0);
      wrClock   : in  std_logic;
      Q         : out std_logic_vector(7 downto 0)
    );
  end component; 
--------------------------------------------------------------------------------

  signal state          : std_logic_vector(  4 downto 0);
  signal count          : std_logic_vector(  7 downto 0);
  signal clkcount       : std_logic_vector(  6 downto 0);
 
  signal cmd            : std_logic_vector( 39 downto 0);
  signal cmdRnW         : std_logic;
 
  signal tResponse      : std_logic_vector(127 downto 0);
  signal TimeOut        : std_logic_vector( 23 downto 0);
 
  signal datastate      : std_logic_vector(  2 downto 0);
  signal DataRdCount    : std_logic_vector(  8 downto 0);
  signal DataWrCount    : std_logic_vector(  8 downto 0);

  signal RamSelect      : std_logic;

  signal tDataIn        : std_logic_vector(  7 downto 0);
  signal tDataRdAddress : std_logic_vector(  8 downto 0);
  signal tDataWrAddress : std_logic_vector(  8 downto 0);
  signal tDataLatch     : std_logic;
  signal tDataOut       : std_logic_vector(  7 downto 0);

  signal DataIn0        : std_logic_vector(  7 downto 0);
  signal DataRdAddress0 : std_logic_vector(  8 downto 0);
  signal DataWrAddress0 : std_logic_vector(  8 downto 0);
  signal DataLatch0     : std_logic;
  signal DataOut0       : std_logic_vector(  7 downto 0);

  signal DataIn1        : std_logic_vector(  7 downto 0);
  signal DataRdAddress1 : std_logic_vector(  8 downto 0);
  signal DataWrAddress1 : std_logic_vector(  8 downto 0);
  signal DataLatch1     : std_logic;
  signal DataOut1       : std_logic_vector(  7 downto 0);

  signal DataBusy       : std_logic;
 
  signal tdata          : std_logic_vector(  3 downto 0);
  signal tDataRnW       : std_logic;
 
  signal crc7           : std_logic_vector(  6 downto 0);
  signal crc16_0        : std_logic_vector( 15 downto 0);
  signal crc16_1        : std_logic_vector( 15 downto 0);
  signal crc16_2        : std_logic_vector( 15 downto 0);
  signal crc16_3        : std_logic_vector( 15 downto 0);
  signal crc16_4        : std_logic_vector( 31 downto 0);
  signal crc16_5        : std_logic_vector( 31 downto 0);
  signal crc16_6        : std_logic_vector( 31 downto 0);
  signal crc16_7        : std_logic_vector( 31 downto 0);
 
  signal tSD_CLK        : std_logic;
--------------------------------------------------------------------------------

begin
  SD_RAM0 : SD_RAM port map(
    DataIn0,
    DataRdAddress0,
    not Clk,
    DataWrAddress0,
    DataLatch0,
    DataOut0
  );
--------------------------------------------------------------------------------

  SD_RAM1 : SD_RAM port map(
    DataIn1,
    DataRdAddress1,
    not Clk,
    DataWrAddress1,
    DataLatch1,
    DataOut1
  );
--------------------------------------------------------------------------------

  DataIn0        <= DataIn      when RamSelect = '0' else tDataIn;
  DataRdAddress0 <= DataAddress when RamSelect = '0' else tDataRdAddress;
  DataWrAddress0 <= DataAddress when RamSelect = '0' else tDataWrAddress;
  DataLatch0     <= DataLatch   when RamSelect = '0' else tDataLatch;

  DataIn1        <= DataIn      when RamSelect = '1' else tDataIn;
  DataRdAddress1 <= DataAddress when RamSelect = '1' else tDataRdAddress;
  DataWrAddress1 <= DataAddress when RamSelect = '1' else tDataWrAddress;
  DataLatch1     <= DataLatch   when RamSelect = '1' else tDataLatch;

  DataOut        <= DataOut0    when RamSelect = '0' else DataOut1;
  tDataOut       <= DataOut0    when RamSelect = '1' else DataOut1;
--------------------------------------------------------------------------------

  process(Clk, nReset) is
  begin
    if nReset = '0' then
      state          <= (others => '1');
      count          <= (others => '0');
      clkcount       <= (others => '1');
   
      cmd            <= (others => '0');
      cmdRnW         <= '1';
   
      tResponse      <= (others => '0');
      TimeOut        <= X"0000FF";
      ResponseCRC    <= '0';
   
      datastate      <= (others => '0');
      DataRdCount    <= (others => '0');
      DataWrCount    <= (others => '0');
      DataCRC        <= '0';
   
      RamSelect      <= '0';
   
      tDataIn        <= (others => '0');
      tDataRdAddress <= (others => '0');
      tDataWrAddress <= (others => '0');
      tDataLatch     <= '0';
      DataBusy       <= '0';
   
      tdata          <= (others => '1');
      tDataRnW       <= '1';
   
      crc7           <= (others => '0');
      crc16_0        <= (others => '0');
      crc16_1        <= (others => '0');
      crc16_2        <= (others => '0');
      crc16_3        <= (others => '0');
      crc16_4        <= (others => '0');
      crc16_5        <= (others => '0');
      crc16_6        <= (others => '0');
      crc16_7        <= (others => '0');
   
      Busy           <= '1';
      Response       <= (others => '0');
   
      tSD_Clk        <= '0';
--------------------------------------------------------------------------------

    elsif rising_edge(Clk) then
      if (clkcount = "0000000") and (ClockDiv /= "1111111") then
        tSD_Clk  <= not tSD_Clk;
        clkcount <= ClockDiv;

        case state is
          when "00000" =>
            if Execute = '0' then
              Busy     <= '0';
              tDataRnW <= '1';
              state    <= "00001";
            end if;
--------------------------------------------------------------------------------

          when "00001" =>
            if (Execute = '1') and (tSD_CLK = '1') then
              cmd         <= "01" & Command & Argument;
              cmdRnW      <= '0';
              crc7        <= (others => '0');
              count       <= X"27"; -- 39
              Busy        <= '1';
              tDataRnW    <= DataRnW;
              ResponseCRC <= '0';
              DataCRC     <= '0';

              if (DataRnW = '0') and (SwapOnWrite = '1') then
                RamSelect <= not RamSelect;
              end if;
       
              state <= "00010";
            else
              state <= "00001";
            end if;
--------------------------------------------------------------------------------

          -- Rising Edge
          when "00010" =>
            crc7 <=  crc7(5 downto 3) &
                    (crc7(2         ) xor (cmd(39) xor crc7(6))) &
                     crc7(1 downto 0) &   (cmd(39) xor crc7(6));

            state <= "00011";
--------------------------------------------------------------------------------

          -- Falling Edge
          when "00011" =>
            if count = X"00" then
              count             <= X"07";
              cmd(39 downto 32) <= crc7 & '1';
              state             <= "00100";
      
            else
              count <= count - '1';
              cmd   <= cmd(38 downto 0) & '0';
              state <= "00010";
            end if;
--------------------------------------------------------------------------------

          -- Rising Edge
          when "00100" =>
            state <= "00101";
--------------------------------------------------------------------------------

          -- Falling Edge
          when "00101" =>
            Response <= (others => '0');

            if count = X"00" then
              cmdRnW <= '1';
              case ResponseType is
                when "01" => -- Short
                  count   <= X"2F"; -- 47
                  TimeOut <= X"0000FF"; -- 255
                  state   <= "00110";
                when "10" => -- Long
                  count   <= X"87"; -- 135
                  TimeOut <= X"0000FF"; -- 255
                  state   <= "00110";
                when others => -- No response
                  state    <= "11110";
              end case;

            else
              count <= count - '1';
              cmd   <= cmd(38 downto 0) & '0';
              state <= "00100";
            end if;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

          -- Rising Edge
          when "00110" => -- Get Response
            tResponse <= (others => '0');
            crc7      <= (others => '0');
       
            if (tSD_CLK = '0') and (SD_CMD = '0') then
              state <= "00111";
            elsif TimeOut = X"000000" then
              state <= "00000";
            end if;
       
            TimeOut <= TimeOut - '1';
--------------------------------------------------------------------------------

          -- Falling Edge
          when "00111" =>
            count <= count - '1';
            state <= "01000";
--------------------------------------------------------------------------------

          -- Rising Edge
          when "01000" =>
            if (count > X"07") and (count < X"80") then
              crc7 <=  crc7(5 downto 3) &
                      (crc7(2         ) xor (SD_CMD xor crc7(6))) &
                       crc7(1 downto 0) &   (SD_CMD xor crc7(6));
            end if;

            if count = X"00" then
              Response <= tResponse(126 downto 0) & SD_CMD;
       
              if (tResponse(6 downto 0) & SD_CMD) = (crc7 & '1') then
                ResponseCRC <= '1';
              end if;
       
              if DataWidth = "000000000" then
                state <= "11110";
              elsif tDataRnW = '1' then
                TimeOut <= X"FFFFFF"; -- 420 ms
                state <= "01001";
              else
                TimeOut <= X"FFFFFF"; -- 420 ms
                state <= "01011";
              end if;
       
            else
              tResponse <= tResponse(126 downto 0) & SD_CMD;
              state <= "00111";
            end if;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

          -- Falling Edge
          when "01001" => -- Wait for read to start
            if DataBusy = '1' then
              state <= "01010";
            elsif TimeOut = X"000000" then
              ResponseCRC <= '0';
              DataCRC     <= '0';
              state       <= "00000";
            end if;
            TimeOut <= TimeOut - '1';
-------------------------------------------------------------------------------

          -- Rising Edge
          when "01010" => -- Wait for read to finish
            if (DataBusy = '0') and (Execute = '0') then
              if (crc16_4(31 downto 16) = crc16_4(15 downto 0)) and
                 (crc16_5(31 downto 16) = crc16_5(15 downto 0)) and
                 (crc16_6(31 downto 16) = crc16_6(15 downto 0)) and
                 (crc16_7(31 downto 16) = crc16_7(15 downto 0)) then
                DataCRC <= '1';
              end if;
              RamSelect <= not RamSelect;
              state     <= "00000";
            end if;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

          -- Falling Edge
          when "01011" => -- Write buffer to card
            DataWrCount    <= DataWidth;
            tDataRdAddress <= (others => '0');
            crc16_0        <= (others => '0');
            crc16_1        <= (others => '0');
            crc16_2        <= (others => '0');
            crc16_3        <= (others => '0');
            count          <= X"06";
            state          <= "01100";
--------------------------------------------------------------------------------

          -- Rising Edge
          when "01100" => -- wait 3 clock rising edges
            if count = X"00" then
              state <= "01101";
            end if;
            count <= count - '1';
--------------------------------------------------------------------------------

          -- Falling Edge, then Rising Edge
          when "01101" => -- transmit "0000"
            tdata <= "0000";
            if tSD_CLK = '0' then
              state <= "01111";
            end if;
--------------------------------------------------------------------------------

          -- Rising Edge
          when "01110" => -- transmit data
            crc16_0 <= crc16_0(14 downto 12) &
                      (crc16_0(11          ) xor (tdata(0) xor crc16_0(15))) &
                       crc16_0(10 downto  5) &
                      (crc16_0( 4          ) xor (tdata(0) xor crc16_0(15))) & 
                       crc16_0( 3 downto  0) &   (tdata(0) xor crc16_0(15))  ;
            crc16_1 <= crc16_1(14 downto 12) &
                      (crc16_1(11          ) xor (tdata(1) xor crc16_1(15))) &
                       crc16_1(10 downto  5) &
                      (crc16_1( 4          ) xor (tdata(1) xor crc16_1(15))) & 
                       crc16_1( 3 downto  0) &   (tdata(1) xor crc16_1(15))  ;
            crc16_2 <= crc16_2(14 downto 12) &
                      (crc16_2(11          ) xor (tdata(2) xor crc16_2(15))) &
                       crc16_2(10 downto  5) &
                      (crc16_2( 4          ) xor (tdata(2) xor crc16_2(15))) & 
                       crc16_2( 3 downto  0) &   (tdata(2) xor crc16_2(15))  ;
            crc16_3 <= crc16_3(14 downto 12) &
                      (crc16_3(11          ) xor (tdata(3) xor crc16_3(15))) &
                       crc16_3(10 downto  5) &
                      (crc16_3( 4          ) xor (tdata(3) xor crc16_3(15))) & 
                       crc16_3( 3 downto  0) &   (tdata(3) xor crc16_3(15))  ;

            if DataWrCount = "000000000" then
              DataWrCount <= "000010000"; -- 16
              state <= "10010";
            else
              DataWrCount <= DataWrCount - '1';
              state <= "01111";
            end if;
--------------------------------------------------------------------------------

          -- Falling Edge
          when "01111" => -- transmit data
            tdata <= tDataOut(7 downto 4);
            state <= "10000";
--------------------------------------------------------------------------------

          --  Rising Edge
          when "10000" => -- transmit data
            crc16_0 <= crc16_0(14 downto 12) &
                      (crc16_0(11          ) xor (tdata(0) xor crc16_0(15))) &
                       crc16_0(10 downto  5) &
                      (crc16_0( 4          ) xor (tdata(0) xor crc16_0(15))) & 
                       crc16_0( 3 downto  0) &   (tdata(0) xor crc16_0(15))  ;
            crc16_1 <= crc16_1(14 downto 12) &
                      (crc16_1(11          ) xor (tdata(1) xor crc16_1(15))) &
                       crc16_1(10 downto  5) &
                      (crc16_1( 4          ) xor (tdata(1) xor crc16_1(15))) & 
                       crc16_1( 3 downto  0) &   (tdata(1) xor crc16_1(15))  ;
            crc16_2 <= crc16_2(14 downto 12) &
                      (crc16_2(11          ) xor (tdata(2) xor crc16_2(15))) &
                       crc16_2(10 downto  5) &
                      (crc16_2( 4          ) xor (tdata(2) xor crc16_2(15))) & 
                       crc16_2( 3 downto  0) &   (tdata(2) xor crc16_2(15))  ;
            crc16_3 <= crc16_3(14 downto 12) &
                      (crc16_3(11          ) xor (tdata(3) xor crc16_3(15))) &
                       crc16_3(10 downto  5) &
                      (crc16_3( 4          ) xor (tdata(3) xor crc16_3(15))) & 
                       crc16_3( 3 downto  0) &   (tdata(3) xor crc16_3(15))  ;
            state <= "10001";
--------------------------------------------------------------------------------

          -- Falling Edge
          when "10001" => -- transmit data
            tdata          <= tDataOut(3 downto 0);
            tDataRdAddress <= tDataRdAddress + '1';
            state          <= "01110";
--------------------------------------------------------------------------------

          -- Falling Edge
          when "10010" => -- transmit crc16
            if DataWrCount(4 downto 0) = "00000" then
              tData <= "1111";
              state <= "10100";
            else
              tData <= crc16_3(15) & crc16_2(15) & crc16_1(15) & crc16_0(15);
              state <= "10011";
            end if;
--------------------------------------------------------------------------------

          -- Rising Edge
          when "10011" => -- transmit crc16
            crc16_0     <= crc16_0(14 downto 0) & '0';
            crc16_1     <= crc16_1(14 downto 0) & '0';
            crc16_2     <= crc16_2(14 downto 0) & '0';
            crc16_3     <= crc16_3(14 downto 0) & '0';
            DataWrCount <= DataWrCount - '1';
            state       <= "10010";
--------------------------------------------------------------------------------

          -- Rising Edge
          when "10100" => -- transmit "1111"
            state <= "10101";
--------------------------------------------------------------------------------

          when "10101" => -- set output to high Z
            tdataRnW <= '1';
            if (tSD_CLK = '0') and (SD_Data(0) = '0') then
              count       <= X"00";
              DataWrCount <= "000000011"; -- 3
              state       <= "10110";
            elsif TimeOut = X"000000" then
              ResponseCRC <= '0';
              DataCRC     <= '0';
              state       <= "00000";
            end if;
            TimeOut <= TimeOut - '1';
--------------------------------------------------------------------------------

          -- Falling Edge
          when "10110" => -- Read CRC Status
            if DataWrCount(1 downto 0) = "00" then
              if count(2 downto 0) = "010" then -- CRC Correct
                DataCRC <= '1';
                TimeOut <= X"FFFFFF"; -- 420 ms
                state   <= "11000";

              else
              TimeOut  <= X"000010"; -- 16;
                state   <= "11110";
              end if;
       
            else
              state <= "10111";
            end if;
      
            DataWrCount <= DataWrCount - '1';
--------------------------------------------------------------------------------

          -- Rising Edge
          when "10111" => -- Read CRC Status
            count <= count(6 downto 0) & SD_Data(0);
            state <= "10110";
--------------------------------------------------------------------------------

          when "11000" => -- wait for busy
            if (tSD_CLK = '0') and (SD_Data(0) = '0') then
              state <= "11110";
            elsif TimeOut = X"000000" then
              ResponseCRC <= '0';
              DataCRC     <= '0';
              state       <= "00000";
            end if;
            TimeOut <= TimeOut - '1';
-------------------------------------------------------------------------------
--------------------------------------------------------------------------------

          when "11110" => -- wait while busy
            TimeOut <= X"000010"; -- 16
      
            if (tSD_CLK = '0') and (SD_Data(0) = '1') then
              state <= "11111";
            end if;
--------------------------------------------------------------------------------

          when "11111" => -- Must wait 8 clock cycles between commands
            if TimeOut = X"000000" then
              state <= "00000";
            end if;
      
            TimeOut <= TimeOut - '1';
--------------------------------------------------------------------------------

          when others =>
        end case;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

        case datastate is
          when "000" =>
            if (tSD_CLK =    '0') and (tDataRnW   =         '1') and 
               (SD_Data = "0000") and (DataWidth /= "000000000") then
              DataRdCount    <= DataWidth;
              tDataWrAddress <= (others => '1');
              DataBusy       <= '1';
              crc16_4        <= (others => '0');
              crc16_5        <= (others => '0');
              crc16_6        <= (others => '0');
              crc16_7        <= (others => '0');
              datastate      <= "001";
            end if;
--------------------------------------------------------------------------------

          -- Falling Edge
          when "001" =>
            datastate <= "010";
--------------------------------------------------------------------------------

          -- Rising Edge
          when "010" =>
            tDataLatch          <= '0';
            tDataIn(7 downto 4) <= SD_Data;
            crc16_4 <= crc16_4(30 downto 12) &
                      (crc16_4(11          ) xor (SD_Data(0) xor crc16_4(15))) &
                       crc16_4(10 downto  5) &
                      (crc16_4( 4          ) xor (SD_Data(0) xor crc16_4(15))) & 
                       crc16_4( 3 downto  0) &   (SD_Data(0) xor crc16_4(15))  ;
            crc16_5 <= crc16_5(30 downto 12) &
                      (crc16_5(11          ) xor (SD_Data(1) xor crc16_5(15))) &
                       crc16_5(10 downto  5) &
                      (crc16_5( 4          ) xor (SD_Data(1) xor crc16_5(15))) & 
                       crc16_5( 3 downto  0) &   (SD_Data(1) xor crc16_5(15))  ;
            crc16_6 <= crc16_6(30 downto 12) &
                      (crc16_6(11          ) xor (SD_Data(2) xor crc16_6(15))) &
                       crc16_6(10 downto  5) &
                      (crc16_6( 4          ) xor (SD_Data(2) xor crc16_6(15))) & 
                       crc16_6( 3 downto  0) &   (SD_Data(2) xor crc16_6(15))  ;
            crc16_7 <= crc16_7(30 downto 12) &
                      (crc16_7(11          ) xor (SD_Data(3) xor crc16_7(15))) &
                       crc16_7(10 downto  5) &
                      (crc16_7( 4          ) xor (SD_Data(3) xor crc16_7(15))) & 
                       crc16_7( 3 downto  0) &   (SD_Data(3) xor crc16_7(15))  ;
            datastate <= "011";
--------------------------------------------------------------------------------

          -- Falling Edge
          when "011" =>
            tDataWrAddress <= tDataWrAddress + '1';
            datastate      <= "100";
--------------------------------------------------------------------------------

          -- Rising Edge
          when "100" =>
            tDataIn(3 downto 0) <= SD_Data;
            crc16_4 <= crc16_4(30 downto 12) &
                      (crc16_4(11          ) xor (SD_Data(0) xor crc16_4(15))) &
                       crc16_4(10 downto  5) &
                      (crc16_4( 4          ) xor (SD_Data(0) xor crc16_4(15))) & 
                       crc16_4( 3 downto  0) &   (SD_Data(0) xor crc16_4(15))  ;
            crc16_5 <= crc16_5(30 downto 12) &
                      (crc16_5(11          ) xor (SD_Data(1) xor crc16_5(15))) &
                       crc16_5(10 downto  5) &
                      (crc16_5( 4          ) xor (SD_Data(1) xor crc16_5(15))) & 
                       crc16_5( 3 downto  0) &   (SD_Data(1) xor crc16_5(15))  ;
            crc16_6 <= crc16_6(30 downto 12) &
                      (crc16_6(11          ) xor (SD_Data(2) xor crc16_6(15))) &
                       crc16_6(10 downto  5) &
                      (crc16_6( 4          ) xor (SD_Data(2) xor crc16_6(15))) & 
                       crc16_6( 3 downto  0) &   (SD_Data(2) xor crc16_6(15))  ;
            crc16_7 <= crc16_7(30 downto 12) &
                      (crc16_7(11          ) xor (SD_Data(3) xor crc16_7(15))) &
                       crc16_7(10 downto  5) &
                      (crc16_7( 4          ) xor (SD_Data(3) xor crc16_7(15))) & 
                       crc16_7( 3 downto  0) &   (SD_Data(3) xor crc16_7(15))  ;
            datastate <= "101";
--------------------------------------------------------------------------------

          -- Falling Edge
          when "101" =>
            tDataLatch <= '1';

            if DataRdCount = "000000000" then
              DataRdCount <= "000001111"; -- 15
              datastate   <= "110";
            else
              DataRdCount <= DataRdCount - '1';
              datastate   <= "010";
            end if;
--------------------------------------------------------------------------------

          -- Rising Edge
          when "110" => -- Read CRC
            tDataLatch <= '0';
      
            if tSD_CLK = '0' then

              if DataRdCount(3 downto 0) = "0000" then
                DataBusy  <= '0';
                datastate <= "000";
              end if;
       
              crc16_4 <= crc16_4(30 downto 0) & SD_Data(0);
              crc16_5 <= crc16_5(30 downto 0) & SD_Data(1);
              crc16_6 <= crc16_6(30 downto 0) & SD_Data(2);
              crc16_7 <= crc16_7(30 downto 0) & SD_Data(3);

              DataRdCount <= DataRdCount - '1';
            end if;
--------------------------------------------------------------------------------

          when others =>
        end case;
--------------------------------------------------------------------------------

      else
        clkcount <= clkcount - '1';
      end if;
    end if;
  end process;
--------------------------------------------------------------------------------

  SD_CLK  <= tSD_CLK;
  SD_CMD  <= cmd(39) when cmdRnW   = '0' else 'Z';
  SD_Data <= tdata   when tdataRnW = '0' else (others => 'Z');
end architecture a1;
--------------------------------------------------------------------------------
