`include "PIC_Core.vh"
//------------------------------------------------------------------------------

module PIC_Core(
  input            nReset,
  input            Clk,
  output           Sync,

  output reg [12:0]ProgramCounter,
  input      [13:0]Program,
  input            Interrupt, 

  output     [ 8:0]Address,
  input      [ 7:0]Data_In,
  output reg [ 7:0]Data_Out,
  output reg       Latch,

  output     [ 7:0]PCL,
  output reg       IRP,
  output reg [ 1:0]RP,
  output reg       Carry,
  output reg       DecimalCarry,
  output reg       Zero,
  output reg [ 7:0]FSR,
  output reg [ 4:0]PCLATH,
  output reg       GIE
);
//------------------------------------------------------------------------------

reg [ 7:0]W;
reg [ 1:0]State;
reg [ 1:0]ClockCycle;
reg       Test;
reg [ 2:0]FlagMask;
reg [ 1:0]Branch;
reg [12:0]Branch_Address;
reg [13:0]Instruction;
//------------------------------------------------------------------------------

assign Sync = &ClockCycle;
assign PCL  =  ProgramCounter[7:0];

assign Address = |Instruction[6:0]      ? 
                 {RP, Instruction[6:0]} : 
                 {IRP, FSR};

always @(posedge Clk) begin
  if(!nReset) begin
    IRP    <= 0;
    RP     <= 0;
    FSR    <= 0;
    PCLATH <= 0;
  end else begin

    if(Latch) begin
      case(Address)
        9'h003, 9'h083, 9'h103, 9'h183: {IRP, RP} <= Data_Out[7:5]; // STATUS
        9'h004, 9'h084, 9'h104, 9'h184: FSR       <= Data_Out;
        9'h00A, 9'h08A, 9'h10A, 9'h18A: PCLATH    <= Data_Out[4:0];

        default:;
      endcase
    end
  end
end
//------------------------------------------------------------------------------

reg  [3:0]ALU_Instruction;
reg  [7:0]ALU_In1;
reg  [7:0]ALU_In2;
wire [7:0]ALU_Out;
wire      ALU_Zero;
wire      ALU_DecimalCarry;
wire      ALU_Carry;

`include "ALU_Instructions.vh"

PIC_ALU ALU(
  ALU_Instruction,

  ALU_In1,
  ALU_In2,
  ALU_Out,

  ALU_Zero,
  ALU_DecimalCarry,
  ALU_Carry
);
//------------------------------------------------------------------------------

reg [12:0]PC_Stack[7:0];
reg [12:0]PC_Stack_Top;
reg [ 2:0]PC_Stack_Pointer; // Points to just above the stack

always @(*) begin
  case(PC_Stack_Pointer)
    3'h0: PC_Stack_Top <= PC_Stack[7];
    3'h1: PC_Stack_Top <= PC_Stack[0];
    3'h2: PC_Stack_Top <= PC_Stack[1];
    3'h3: PC_Stack_Top <= PC_Stack[2];
    3'h4: PC_Stack_Top <= PC_Stack[3];
    3'h5: PC_Stack_Top <= PC_Stack[4];
    3'h6: PC_Stack_Top <= PC_Stack[5];
    3'h7: PC_Stack_Top <= PC_Stack[6];
    default:;
  endcase
end

always @(posedge Clk) begin
  if(!nReset) begin
    PC_Stack[0] <= 0;
    PC_Stack[1] <= 0;
    PC_Stack[2] <= 0;
    PC_Stack[3] <= 0;
    PC_Stack[4] <= 0;
    PC_Stack[5] <= 0;
    PC_Stack[6] <= 0;
    PC_Stack[7] <= 0;

  end else begin
    case(PC_Stack_Pointer)
      3'h0: PC_Stack[0] <= ProgramCounter;
      3'h1: PC_Stack[1] <= ProgramCounter;
      3'h2: PC_Stack[2] <= ProgramCounter;
      3'h3: PC_Stack[3] <= ProgramCounter;
      3'h4: PC_Stack[4] <= ProgramCounter;
      3'h5: PC_Stack[5] <= ProgramCounter;
      3'h6: PC_Stack[6] <= ProgramCounter;
      3'h7: PC_Stack[7] <= ProgramCounter;
      default:;
    endcase
  end
end
//------------------------------------------------------------------------------

wire [ 2:0]Bit;
wire [12:0]PC_p1;
wire [10:0]Literal;
wire       Destination;

assign Bit         = Instruction[ 9:7];
assign PC_p1       = ProgramCounter + 1'b1;
assign Literal     = Instruction[10:0];
assign Destination = Instruction[   7];

always @(posedge Clk) begin
  if(!nReset) begin
    ProgramCounter   <= 0;
    PC_Stack_Pointer <= 0;

    Data_Out <= 0;
    Latch    <= 0;

    W            <= 0;
    Zero         <= 0;
    Carry        <= 0;
    DecimalCarry <= 0;

    GIE <= 0;

    ALU_Instruction <= 0;
    ALU_In1         <= 0;
    ALU_In2         <= 0;

    Test        <= 0;
    FlagMask    <= 0;
    Instruction <= 0;

    Branch         <= 0;
    Branch_Address <= 0;

    State      <= 0;
    ClockCycle <= 0;
//------------------------------------------------------------------------------

  end else begin
    ClockCycle <= ClockCycle + 1'b1;
  
    case(ClockCycle) 
      2'h0:; // Wait for RAM to be read
//------------------------------------------------------------------------------

      2'h1: begin
        casex(Instruction)
          `ADDWF: begin 
            FlagMask        <= 3'b111; 
            ALU_Instruction <= `ALU_Add;
            ALU_In1         <= Data_In;
            ALU_In2         <= W;
            State           <= `LatchWF;
          end

          `ANDWF: begin 
            FlagMask        <= 3'b100; 
            ALU_Instruction <= `ALU_And;
            ALU_In1         <= Data_In;
            ALU_In2         <= W;
            State           <= `LatchWF;
          end

          `CLRWF: begin 
            FlagMask        <= 3'b100; 
            ALU_Instruction <= `ALU_Add;
            ALU_In1         <= 8'h00;
            ALU_In2         <= 8'h00;
            State           <= `LatchWF;
          end

          `COMF: begin 
            FlagMask        <= 3'b100; 
            ALU_Instruction <= `ALU_XOr;
            ALU_In1         <= Data_In;
            ALU_In2         <= 8'hFF;
            State           <= `LatchWF;
          end

          `DECF: begin 
            FlagMask        <= 3'b100; 
            ALU_Instruction <= `ALU_Add;
            ALU_In1         <= Data_In;
            ALU_In2         <= 8'hFF;
            State           <= `LatchWF;
          end

          `DECFSZ: begin 
            FlagMask        <= 3'b000; 
            ALU_Instruction <= `ALU_Add;
            ALU_In1         <= Data_In;
            ALU_In2         <= 8'hFF;
            State           <= `LatchWF;
            Test            <= 1'b1;
          end

          `INCF: begin 
            FlagMask        <= 3'b100; 
            ALU_Instruction <= `ALU_Add;
            ALU_In1         <= Data_In;
            ALU_In2         <= 8'h01;
            State           <= `LatchWF;
          end

          `INCFSZ: begin 
            FlagMask        <= 3'b000; 
            ALU_Instruction <= `ALU_Add;
            ALU_In1         <= Data_In;
            ALU_In2         <= 8'h01;
            State           <= `LatchWF;
            Test            <= 1'b1;
          end

          `IORWF: begin 
            FlagMask        <= 3'b100; 
            ALU_Instruction <= `ALU_Or;
            ALU_In1         <= Data_In;
            ALU_In2         <= W;
            State           <= `LatchWF;
          end

          `MOVF: begin 
            FlagMask        <= 3'b100; 
            ALU_Instruction <= `ALU_Add;
            ALU_In1         <= Data_In;
            ALU_In2         <= 8'h00;
            State           <= `LatchWF;
          end

          `MOVWF: begin 
            FlagMask        <= 3'b000; 
            ALU_Instruction <= `ALU_Add;
            ALU_In1         <= 8'h00;
            ALU_In2         <= W;
            State           <= `LatchWF;
          end

          `RLF: begin 
            FlagMask        <= 3'b001; 
            ALU_Instruction <= `ALU_RotateLeft;
            ALU_In1         <= Data_In;
            ALU_In2         <= {7'h00, Carry};
            State           <= `LatchWF;
          end

          `RRF: begin 
            FlagMask        <= 3'b001; 
            ALU_Instruction <= `ALU_RotateRight;
            ALU_In1         <= Data_In;
            ALU_In2         <= {7'h00, Carry};
            State           <= `LatchWF;
          end

          `SUBWF: begin 
            FlagMask        <= 3'b111; 
            ALU_Instruction <= `ALU_Add;
            ALU_In1         <= Data_In;
            ALU_In2         <= ~W + 1'b1;
            State           <= `LatchWF;
          end

          `SWAPF: begin 
            FlagMask        <= 3'b000; 
            ALU_Instruction <= `ALU_Swap;
            ALU_In1         <= Data_In;
            ALU_In2         <= 8'h00;
            State           <= `LatchWF;
          end

          `XORWF: begin 
            FlagMask        <= 3'b100; 
            ALU_Instruction <= `ALU_XOr;
            ALU_In1         <= Data_In;
            ALU_In2         <= W;
            State           <= `LatchWF;
          end

          // Bit-Oriented File Register Operations
          `BCF: begin 
            FlagMask        <= 3'b000; 
            ALU_Instruction <= `ALU_BitClear;
            ALU_In1         <= Data_In;
            ALU_In2         <= {5'h00, Bit};
            State           <= `LatchWF;
            Instruction[7]  <= 1'b1; // Destination
          end

          `BSF: begin 
            FlagMask        <= 3'b000; 
            ALU_Instruction <= `ALU_BitSet;
            ALU_In1         <= Data_In;
            ALU_In2         <= {5'h00, Bit};
            State           <= `LatchWF;
            Instruction[7]  <= 1'b1; // Destination
          end

          `BTFSC: begin 
            FlagMask        <= 3'b000; 
            ALU_Instruction <= `ALU_BitTest;
            ALU_In1         <= Data_In;
            ALU_In2         <= {5'h00, Bit};
            State           <= `Test_Zero;
          end

          `BTFSS: begin 
            FlagMask        <= 3'b000; 
            ALU_Instruction <= `ALU_BitTest;
            ALU_In1         <= Data_In;
            ALU_In2         <= {5'h00, Bit};
            State           <= `Test_nZero;
          end

          // Literal and Control Operations
          `ADDLW: begin 
            FlagMask        <= 3'b111; 
            ALU_Instruction <= `ALU_Add;
            ALU_In1         <= Literal[7:0];
            ALU_In2         <= W;
            State           <= `LatchWF;
            Instruction[7]  <= 1'b0; // Destination
          end

          `ANDLW: begin 
            FlagMask        <= 3'b100; 
            ALU_Instruction <= `ALU_And;
            ALU_In1         <= Literal[7:0];
            ALU_In2         <= W;
            State           <= `LatchWF;
            Instruction[7]  <= 1'b0; // Destination
          end

          `CALL: begin 
            Branch         <= `Branch_Call;
            Branch_Address <= {PCLATH[4:3], Literal};
            State          <= `Wait;
          end

          `GOTO: begin 
            Branch         <= `Branch_Goto; 
            Branch_Address <= {PCLATH[4:3], Literal};
            State          <= `Wait;
          end

          `IORLW: begin 
            FlagMask        <= 3'b100; 
            ALU_Instruction <= `ALU_Or;
            ALU_In1         <= Literal[7:0];
            ALU_In2         <= W;
            State           <= `LatchWF;
            Instruction[7]  <= 1'b0; // Destination
          end
 
          `MOVLW: begin 
            FlagMask        <= 3'b000; 
            ALU_Instruction <= `ALU_Add;
            ALU_In1         <= Literal[7:0];
            ALU_In2         <= 8'h00;
            State           <= `LatchWF;
            Instruction[7]  <= 1'b0; // Destination
          end
 
          `RETFIE: begin 
            GIE    <= 1'b1;
            Branch <= `Branch_Return;
            State  <= `Wait;
          end
 
          `RETLW: begin 
            W      <= Literal[7:0];
            Branch <= `Branch_Return;
            State  <= `Wait;
          end
 
          `RETURN: begin 
            Branch <= `Branch_Return; 
            State  <= `Wait;
          end
 
          `SUBLW: begin 
            FlagMask        <= 3'b111; 
            ALU_Instruction <= `ALU_Add;
            ALU_In1         <= Literal[7:0];
            ALU_In2         <= ~W + 1'b1;
            State           <= `LatchWF;
            Instruction[7]  <= 1'b0; // Destination
          end
 
          `XORLW: begin 
            FlagMask        <= 3'b100; 
            ALU_Instruction <= `ALU_XOr;
            ALU_In1         <= Literal[7:0];
            ALU_In2         <= W;
            State           <= `LatchWF;
            Instruction[7]  <= 1'b0; // Destination
          end
 
          default: State <= `Wait;
        endcase
      end
//------------------------------------------------------------------------------

      2'h2: begin
        case(State)
          `LatchWF: begin 
            if(FlagMask[0]) Carry        <= ALU_Carry;
            if(FlagMask[1]) DecimalCarry <= ALU_DecimalCarry;
            if(FlagMask[2]) Zero         <= ALU_Zero;
       
            Data_Out <= ALU_Out;
            if(Destination) begin
              Latch <= 1'b1;
  
              case(Address)
                9'h002, 9'h082, 9'h102, 9'h182: begin // PCL
                  Branch         <= `Branch_Goto;
                  Branch_Address <= {PCLATH, ALU_Out};
                end
  
                default: begin
                  Branch_Address             <= PC_p1;
                  if(Test & ALU_Zero) Branch <= `Branch_Goto;
                end
              endcase
        
              case(Address)
                9'h003, 9'h083, 9'h103, 9'h183: begin // STATUS
                  {Zero, DecimalCarry, Carry} <= ALU_Out[2:0];
                end
  
                9'h00B, 9'h08B, 9'h10B, 9'h18B: begin // INTCON
                  GIE <= ALU_Out[7];
                end
  
                default:;
              endcase
  
            end else begin
              W <= ALU_Out;
            end
          end
  
          `Test_Zero: begin
            Branch_Address      <= PC_p1;
            if(ALU_Zero) Branch <= `Branch_Goto;
          end
  
          `Test_nZero: begin
            Branch_Address       <= PC_p1;
            if(~ALU_Zero) Branch <= `Branch_Goto;
          end
  
          default:;
        endcase
      end
//------------------------------------------------------------------------------

      2'h3: begin
        case(Branch)
          `Branch_None: begin 
            if(GIE & Interrupt) begin
              GIE              <= 1'b0;
              Instruction      <= 0; // NOP
              ProgramCounter   <= 13'h0004;
              PC_Stack_Pointer <= PC_Stack_Pointer + 1'b1;
 
            end else begin
              Instruction    <= Program;
              ProgramCounter <= PC_p1;
            end
          end
 
          `Branch_Goto: begin 
            Instruction    <= 0; // NOP
            ProgramCounter <= Branch_Address;
          end
 
          `Branch_Call: begin 
            Instruction      <= 0; // NOP
            ProgramCounter   <= Branch_Address;
            PC_Stack_Pointer <= PC_Stack_Pointer + 1'b1;
          end

          `Branch_Return: begin  
            Instruction      <= 0; // NOP
            ProgramCounter   <= PC_Stack_Top;
            PC_Stack_Pointer <= PC_Stack_Pointer - 1'b1;
          end
   
          default:;
        endcase
 
        Test   <= 1'b0;
        Latch  <= 1'b0;
        Branch <= `Branch_None;
      end
//------------------------------------------------------------------------------

      default:;
    endcase
  end
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

