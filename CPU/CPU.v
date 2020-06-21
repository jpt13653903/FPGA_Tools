//==============================================================================
// Copyright (C) John-Philip Taylor
// jpt13653903@gmail.com
//
// This file is part of a library
//
// This file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>
//==============================================================================

module CPU(
 input  nReset,
 input  Clk, // max 10 MHz
  
 output reg Bus_Mutex_Request,
 input      Bus_Mutex_Grant,

 output reg [15:0]Bus_Address,
 output reg       Bus_Latch,
 output reg [ 7:0]Bus_DataOut,
 input      [ 7:0]Bus_DataIn,
 
 output reg [15:0]PC,        // Program counter
 input      [ 7:0]Prog,      // Program ROM
 input            Prog_Valid // High when the data on Prog is valid
);
//------------------------------------------------------------------------------
 
 reg  [4:0]state;
 reg  [4:0]ret_state;
 
 reg  [15:0]PC_W;      // Address to write to program ROM
 reg  [ 7:0]Prog_Data; // Data to be written to program ROM
 reg        Prog_Latch;
 wire       Prog_WrBusy;
 assign     Prog_WrBusy = Prog_Latch; // EPCS cache does not support writing

 reg  [2:0]S_Address;
 reg  [7:0]S_Input;
 wire [7:0]S_Out0;
 wire [7:0]S_Out1;
 wire [7:0]S_OutA;
 reg       S_Latch;
 reg  [1:0]S_Task;

 wire [15:0]PS_Top;
 reg        PS_Latch;
 reg  [ 8:0]PS_Address;
 reg  [15:0]PS_Data;

 reg  [ 7:0]Mul_A;
 reg  [ 7:0]Mul_B;
 wire [15:0]Mul_Y;

 reg  [7:0]Arith_A;
 reg  [7:0]Arith_B;
 wire [7:0]Arith_Out;
 reg  [3:0]Arith_Task;
 wire      Arith_Carry;
 wire      Arith_Zero;

 reg  [ 7:0]Opcode;
 reg  [ 7:0]Temp;
 reg  [ 7:0]Temp2;
 reg  [15:0]Div_Num;

 reg  Carry;
 reg  Zero;

 wire Skip;

 wire [15:0]PCp1; // PC + 1
 reg  [15:0]PCpS; // PC + Skip count
//------------------------------------------------------------------------------

 CPU_ProgStack PC_Stack(
  PS_Data,
  PS_Address,
  ~Clk,
  PS_Address,
  ~Clk,
  PS_Latch,
  PS_Top
 );
//------------------------------------------------------------------------------

 CPU_Stack Stack1(
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
//------------------------------------------------------------------------------

 CPU_Arith Arith1(
  Arith_A,
  Arith_B,
  Arith_Task,
  Carry,
  Zero,
  Arith_Out,
  Arith_Carry,
  Arith_Zero
 );
//------------------------------------------------------------------------------

 assign Mul_Y = Mul_A * Mul_B;

 assign Skip = ((!Carry) && Prog[7]) || ((!Zero) && Prog[6]);
 assign PCp1 = PC + 1'b1;
//------------------------------------------------------------------------------
 
 always @* begin
  case(Prog[5:0])
   6'b101010,
   6'b101100,
   6'b111000: PCpS <= PC + 2'b10;
   
   6'b101011,
   6'b101101,
   6'b101110,
   6'b101111,
   6'b111001,
   6'b111010,
   6'b111011,
   6'b111100,
   6'b111101,
   6'b111110,
   6'b111111: PCpS <= PC + 2'b11;
   
   default  : PCpS <= PCp1;
  endcase
 end
//------------------------------------------------------------------------------

 always @(negedge nReset, posedge Clk) begin
  if(!nReset) begin
   state     <= 0;
   ret_state <= 0;

   PC         <= 0;
   Prog_Data  <= 0;
   Prog_Latch <= 0;
   Opcode     <= 0;

   S_Address <= 0;
   S_Latch   <= 0;
   S_Task    <= 0;

   PS_Address <= {9{1'b1}};
   PS_Data    <= 0;
   PS_Latch   <= 0;

   Bus_Mutex_Request <= 0;

   Bus_DataOut <= 0;
   Bus_Address <= 0;
   Bus_Latch   <= 0;

   Arith_A    <= 0;
   Arith_B    <= 0;
   Arith_Task <= 0;

   Mul_A    <= 0;
   Mul_B    <= 0;

   Temp      <= 8'h0A; // Startup wait for 10 cycles
   Temp2     <= 0;
   Div_Num   <= 0;

   Carry     <= 0;
   Zero      <= 0;
//------------------------------------------------------------------------------
   
  end else begin
   case(state)
// Decode instruction and do first part
    5'b00000: begin
     Bus_Mutex_Request <= 1'b0;
     if(Prog_Valid) begin
      S_Latch    <= 1'b0;
      PS_Latch   <= 1'b0;
      Prog_Latch <= 1'b0;
      Bus_Latch  <= 1'b0;
      if(Skip) begin // Instruction prefix = {c; z; cz}
       PC    <= PCpS;
       state <= 5'b00000;
      end else begin
       case(Prog[5:0])
        6'h000000,       // adc
        6'h000001: begin // adc pop
         Arith_A    <= S_Out1;
         Arith_B    <= S_Out0;
         Arith_Task <= 4'b0001;
         S_Task[0]  <= 1'b0;
         S_Task[1]  <= Prog[0];
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b000010,       // add
        6'b000011: begin // add pop
         Arith_A    <= S_Out1;
         Arith_B    <= S_Out0;
         Arith_Task <= 4'b0010;
         S_Task[0]  <= 1'b0;
         S_Task[1]  <= Prog[0];
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b000100,       // and
        6'b000101: begin // and pop
         Arith_A    <= S_Out1;
         Arith_B    <= S_Out0;
         Arith_Task <= 4'b0011;
         S_Task[0]  <= 1'b0;
         S_Task[1]  <= Prog[0];
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b000110,       // div
        6'b000111: begin // div pop
         Arith_Task <= 4'b0000;
         S_Address  <= 3'b010;
         state      <= 5'b00101;
        end
        
        6'b001000,       // mul
        6'b001001: begin // mul pop
         Arith_Task <= 4'b0000;
         Mul_A      <= S_Out1;
         Mul_B      <= S_Out0;
         S_Task[0]  <= 1'b0;
         S_Task[1]  <= Prog[0];
         state      <= 5'b00010;
        end
        
        6'b001010: begin // neg
         Arith_A    <= S_Out0;
         Arith_Task <= 4'b0100;
         S_Task     <= 2'b00;
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b001011: begin // not
         Arith_A    <= S_Out0;
         Arith_Task <= 4'b0101;
         S_Task     <= 2'b00;
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b001100,       // or
        6'b001101: begin // or pop
         Arith_A    <= S_Out1;
         Arith_B    <= S_Out0;
         Arith_Task <= 4'b0110;
         S_Task[0] <= 1'b0;
         S_Task[1] <= Prog[0];
         PC        <= PCp1;
         state     <= 5'b00001;
        end
        
        6'b001110,       // sbb
        6'b001111: begin // sbb pop
         Arith_A    <= S_Out1;
         Arith_B    <= S_Out0;
         Arith_Task <= 4'b0111;
         S_Task[0]  <= 1'b0;
         S_Task[1]  <= Prog[0];
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b010000,       // sub
        6'b010001: begin // sub pop
         Arith_A    <= S_Out1;
         Arith_B    <= S_Out0;
         Arith_Task <= 4'b1000;
         S_Task[0]  <= 1'b0;
         S_Task[1]  <= Prog[0];
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b010010,       // xor
        6'b010011: begin // xor pop
         Arith_A    <= S_Out1;
         Arith_B    <= S_Out0;
         Arith_Task <= 4'b1001;
         S_Task[0]  <= 1'b0;
         S_Task[1]  <= Prog[0];
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b010100: begin // rcl
         Arith_A    <= S_Out0;
         Arith_Task <= 4'b1010;
         S_Task     <= 2'b00;
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b010101: begin // rcr
         Arith_A    <= S_Out0;
         Arith_Task <= 4'b1011;
         S_Task     <= 2'b00;
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b010110: begin // rol
         Arith_A    <= S_Out0;
         Arith_Task <= 4'b1100;
         S_Task     <= 2'b00;
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b010111: begin // ror 
         Arith_A    <= S_Out0;
         Arith_Task <= 4'b1101;
         S_Task     <= 2'b00;
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b011000: begin // shl
         Arith_A    <= S_Out0;
         Arith_Task <= 4'b1110;
         S_Task     <= 2'b00;
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b011001: begin // shr         
         Arith_A    <= S_Out0;
         Arith_Task <= 4'b1111;
         S_Task     <= 2'b00;
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b011010: begin // cc
         Carry <= 1'b0;
         PC    <= PCp1;
         state <= 5'b00000;
        end
        
        6'b011011: begin // cz
         Zero  <= 1'b0;
         PC    <= PCp1;
         state <= 5'b00000;
        end
        
        6'b011100: begin // nc
         Carry <= !Carry;
         PC    <= PCp1;
         state <= 5'b00000;
        end
        
        6'b011101: begin // nz
         Zero  <= !Zero;
         PC    <= PCp1;
         state <= 5'b00000;
        end
        
        6'b011110: begin // sc
         Carry <= 1'b1;
         PC    <= PCp1;
         state <= 5'b00000;
        end
        
        6'b011111: begin // sz
         Zero  <= 1'b1;
         PC    <= PCp1;
         state <= 5'b00000;
        end
        
        6'b100000,       // swp 0
        6'b100001,       // swp 1
        6'b100010,       // swp 2
        6'b100011,       // swp 3
        6'b100100,       // swp 4
        6'b100101,       // swp 5
        6'b100110,       // swp 6
        6'b100111: begin // swp 7
         Arith_Task <= 4'b0000;
         S_Address  <= Prog[2:0];
         S_Task     <= 2'b11;
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b101000: begin // pop
         Arith_Task <= 4'b0000;
         Arith_A    <= S_Out1;
         S_Task     <= 2'b10;
         PC         <= PCp1;
         state      <= 5'b00001;
        end
        
        6'b101001: begin // ret
         PC         <= PS_Top;
         PS_Address <= PS_Address - 1'b1;
         state      <= 5'b01001;
        end
        
        6'b101010,       // call rel ??? | call ???
        6'b101011: begin // call abs ???
         PS_Data    <= PCpS;
         PS_Address <= PS_Address + 1'b1;
         state      <= 5'b01011;
        end
        
        6'b101100,       // jmp rel ??? | jmp ???
        6'b101101: begin // jmp abs ???
         Opcode <= Prog;
         PC     <= PCp1;
         state  <= 5'b01100;
        end
        
        6'b101110,       // ld ???
        6'b101111: begin // ld ref ???
         Arith_Task <= 4'b0000;
         Opcode     <= Prog;
         PC         <= PCp1;
         ret_state  <= 5'b10010;
         state      <= 5'b01110;
        end
        
        6'b110000,       // lds 0
        6'b110001,       // lds 1
        6'b110010,       // lds 2
        6'b110011,       // lds 3
        6'b110100,       // lds 4
        6'b110101,       // lds 5
        6'b110110,       // lds 6
        6'b110111: begin // lds 7
         Arith_Task <= 4'b0000;
         S_Address  <= Prog[2:0];
         S_Task     <= 2'b01;
         PC         <= PCp1;
         state      <= 5'b10011;
        end
        
        6'b111000: begin // ldi ???
         Arith_Task <= 4'b0000;
         S_Task     <= 2'b01;
         PC         <= PCp1;
         state      <= 5'b10100;
        end
        
        6'b111001: begin // ldpr ???
         Arith_Task <= 4'b0000;
         PC         <= PCp1;
         Opcode     <= 8'b00000001; // Reference
         ret_state  <= 5'b10101;
         state      <= 5'b01110;
        end
        
        6'b111010,       // stpr
        6'b111011: begin // stpr pop
         Arith_Task <= 4'b0000;
         PC         <= PCp1;
         Opcode[1]  <= Prog[0]; // Pop
         Opcode[0]  <= 1'b1;    // Reference
         ret_state  <= 5'b11000;
         state      <= 5'b01110;
        end
        
        6'b111100,       // st ???
        6'b111101,       // st ref ???
        6'b111110,       // st pop ???
        6'b111111: begin // st pop ref ???
         Arith_Task <= 4'b0000;
         Opcode     <= Prog;
         PC         <= PCp1;
         ret_state  <= 5'b11011;
         state      <= 5'b01110;
        end
        
        default:;
       endcase
      end
     end
    end

// Latch arithmetic stack and set flags
    5'b00001: begin
     S_Latch <= 1'b1;
     S_Input <= Arith_Out;
     Carry   <= Arith_Carry;
     Zero    <= Arith_Zero;
     state   <= 5'b00000;
    end

// Mul
    5'b00010: begin
     Arith_A <= Mul_Y[15:8];
     state   <= 5'b00011;
    end
    
    5'b00011: begin
     S_Latch <= 1'b1;
     S_Input <= Arith_Out;
     state   <= 5'b00100;
    end
    
    5'b00100: begin
     S_Latch <= 1'b0;
     Arith_A <= Mul_Y[7:0];
     Zero    <= (!(|Mul_Y));
     S_Task  <= 2'b01;
     PC      <= PCp1;
     state   <= 5'b00001;
    end

// Div
    5'b00101: begin
     Div_Num <= {S_OutA, S_Out1};
     Temp    <= 8'b01111111;
     Temp2   <= 8'b01000000;
     Mul_A   <= 8'b10000000;
     Mul_B   <= S_Out0;
     state   <= 5'b00110;
    end
    
    5'b00110: begin
     if(Prog_Valid) begin
      if(Mul_Y > Div_Num) begin
       Mul_A <= (Mul_A & Temp) | Temp2;
      end else begin
       Mul_A <= Mul_A | Temp2;
      end
      if(Temp2 == 8'b00000000) begin
       Zero      <= (!(|Mul_Y));
       S_Task[0] <= 1'b0;
       S_Task[1] <= Prog[0];
       PC        <= PCp1;
       state     <= 5'b00111;
      end else begin
       state     <= 5'b00110;
      end
      Temp       <= {1'b1, Temp [7:1]};
      Temp2[6:0] <=        Temp2[7:1] ;
     end
    end

// Pop or store twice - to get the LSb and stack correct
    5'b00111: begin
     S_Latch <= 1'b1;
     S_Input <= Arith_Out;
     state   <= 5'b01000;
    end
    
    5'b01000: begin
     S_Latch <= 1'b0;
     Arith_A <= Mul_A;
     state   <= 5'b00001;
    end

// Latch new program stack address
    5'b01001: begin
     PS_Data <= PS_Top;
     state   <= 5'b01010;
    end
    
    5'b01010: begin
     PS_Latch <= 1'b1;
     state    <= 5'b00000;
    end

// Latch PC onto stack;
    5'b01011: begin
     if(Prog_Valid) begin
      PS_Latch <= 1'b1;
      Opcode   <= Prog;
      PC       <= PCp1;
      state    <= 5'b01100;
     end
    end

// Jump
    5'b01100: begin
     if(Prog_Valid) begin
     Temp <= Prog;
      if(Opcode[0]) begin
       PC    <= PCp1;
       state <= 5'b01101;
      end else begin
       if(Prog[7]) begin // negative jump
        PC <= (PC + 16'hFEFF) + Prog; // PC-1 + sign extend + offset
       end else begin
        PC <= (PC + 16'hFFFF) + Prog; // PC-1 + offset
       end
       state <= 5'b00000;
      end
     end
    end
    
    5'b01101: begin
     if(Prog_Valid) begin
      PC[ 7:0] <= Temp;
      PC[15:8] <= Prog;
      state    <= 5'b00000;
     end
    end

// ld
    5'b01110: begin
     if(Prog_Valid) begin
      Temp  <= Prog;
      PC    <= PCp1;
      state <= 5'b01111;
     end
    end
    
    5'b01111: begin
     if(Prog_Valid) begin
      Bus_Address[15:8] <= Prog;
      Bus_Address[ 7:0] <= Temp;
      Bus_Mutex_Request <= 1'b1;
      if(Bus_Mutex_Grant) begin
       state <= 5'b10000;
      end
     end
    end
    
    5'b10000: begin
     if(Opcode[0]) begin
      Temp        <= Bus_DataIn;
      Bus_Address <= Bus_Address + 1'b1;
      state       <= 5'b10001;
     end else begin
      state <= ret_state;
     end
    end
    
    5'b10001: begin
     Bus_Address[15:8] <= Bus_DataIn;
     Bus_Address[ 7:0] <= Temp;
     state             <= ret_state;
    end
    
    5'b10010: begin
     Arith_A <= Bus_DataIn;
     S_Task  <= 2'b01;
     PC      <= PCp1;
     state   <= 5'b00001;
    end

// Push S_OutA onto stack;
    5'b10011: begin
     Arith_A <= S_OutA;
     state   <= 5'b00001;
    end

// Push Prog onto stack;
    5'b10100: begin
     if(Prog_Valid) begin
      Arith_A <= Prog;
      PC      <= PCp1;
      state   <= 5'b00001;
     end
    end

// ldpr
    5'b10101: begin
     PC_W  <= PCp1;
     PC    <= Bus_Address;
     state <= 5'b10111;
    end
    
    5'b10111: begin
     if(Prog_Valid) begin
      Arith_A <= Prog;
      S_Task  <= 2'b01;
      PC      <= PC_W;
      state   <= 5'b00001;
     end
    end

// stpr
    5'b11000: begin
     PC_W      <= Bus_Address;
     Prog_Data <= S_Out0;
     PC        <= PCp1;
     state     <= 5'b11010;
    end
    
    5'b11010: begin
     if(!Prog_WrBusy) begin
      Prog_Latch <= 1'b1;
      state      <= 5'b11101;
     end
    end
    
    5'b11101: begin
     if(Prog_WrBusy) begin
      Prog_Latch <= 1'b0;
      if(Opcode[1]) begin
       Arith_A <= S_Out1;
       S_Task  <= 2'b10;
       state   <= 5'b00001;
      end else begin
       state <= 5'b00000;
      end
     end
    end

// st
    5'b11011: begin
     Bus_DataOut <= S_Out0;
     PC          <= PCp1;
     state       <= 5'b11100;
    end
    
    5'b11100: begin
     Bus_Latch <= 1'b1;
     if(Opcode[1]) begin
      Arith_A <= S_Out1;
      S_Task  <= 2'b10;
      state   <= 5'b00001;
     end else begin
      state <= 5'b00000;
     end
    end
    
    default:;
   endcase
  end
 end
endmodule
//------------------------------------------------------------------------------
