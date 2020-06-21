module PIC16F946(
  input nReset, // N2
  input Clk,    // B9

  input [4:1]nButtons, // B10 A10 F2 F1
  inout [4:1]nLED      // N9 N12 P12 P13
 
// inout [7:0]PortA, // B10 A10 F2  F1  N9  N12 P12 P13
// inout [7:0]PortB, // N13 L13 P17 M14 P18 R17 R5  R18 
// inout [7:0]PortC, // G18 M18 K18 L14 L18 L15 L16 M17 
// inout [7:0]PortD, // R1  E18 T3  H17 R3  H18 G17 L17 
// inout [7:0]PortE, // R4  M6  T17 N6  T18 R2  M13 E17 
// inout [7:0]PortF, // L3  C2  G2  C1  G1  H2  K2  H1  
// inout [5:0]PortG  //         N16 B2  N15 B1  R16 T16 
);
//------------------------------------------------------------------------------

reg tnReset;
always @(negedge Clk) tnReset <= nReset;
//------------------------------------------------------------------------------

wire       Sync;

wire [ 7:0]PCL;
wire       IRP;
wire [ 1:0]RP;
wire       Carry;
wire       DecimalCarry;
wire       Zero;
wire [ 7:0]FSR;
wire [ 4:0]PCLATH;
wire       GIE;

PIC_Core Core(
  tnReset,
  Clk,
  Sync,

  ROM_Address,
  ROM_Output,
  T0IE & T0IF,

  File_Address,
  File_Data_Out,
  File_Data_In,
  File_Latch,

  PCL,
  IRP,
  RP,
  Carry,
  DecimalCarry,
  Zero,
  FSR,
  PCLATH,
  GIE
);
//------------------------------------------------------------------------------

wire [12:0]ROM_Address;
wire [13:0]ROM_Output;

PIC_Program_ROM Program_ROM(
  .address(ROM_Address),
  .clock  (Clk),
  .q      (ROM_Output)
);
//------------------------------------------------------------------------------

// RAM
wire [8:0]RAM_Address;
wire [7:0]RAM_Output;

assign RAM_Address = &File_Address[6:4]        ? 
                     {2'h0, File_Address[6:0]} : 
                     File_Address;

PIC_RAM PIC_RAM1(
  .address(RAM_Address),
  .clock  (Clk),
  .data   (File_Data_In),
  .wren   (File_Latch),
  .q      (RAM_Output)
);
//------------------------------------------------------------------------------

wire [7:0]TMR0;
 
wire      T0IE;
wire      T0IF;

wire      T0CS;
wire      T0SE;
wire      PSA;
wire [2:0]PS;

Timer0 Timer0_Instance(
  tnReset,
  Clk,
  Sync,
 
  File_Address,
  File_Data_In,
  File_Latch,

  1'b0,

  TMR0,
  T0IE,
  T0IF,

  T0CS,
  T0SE,
  PSA,
  PS
);
//------------------------------------------------------------------------------

reg [7:0]PORTA;
reg [7:0]TRISA;

always @(posedge Clk) begin
  if(!tnReset) begin
    PORTA <= 0;
    TRISA <= 8'hFF;
  end else begin
 
    if(File_Latch) begin
      case(File_Address)
        9'h005: PORTA <= File_Data_In;
        9'h085: TRISA <= File_Data_In;

        default:;
      endcase
    end
  end
end

assign nLED[1] = TRISA[0] ? 1'bZ : ~PORTA[0];
assign nLED[2] = TRISA[1] ? 1'bZ : ~PORTA[1];
assign nLED[3] = TRISA[2] ? 1'bZ : ~PORTA[2];
assign nLED[4] = TRISA[3] ? 1'bZ : ~PORTA[3];
//------------------------------------------------------------------------------

wire [ 8:0]File_Address;
wire [ 7:0]File_Data_In;
reg  [ 7:0]File_Data_Out;
wire       File_Latch;

always @(*) begin
  case(File_Address)
    9'h001, 9'h101: File_Data_Out <= TMR0;
    9'h081, 9'h181: File_Data_Out <= {2'b11, T0CS, T0SE, PSA, PS}; // OPTION_REG

    9'h002, 9'h082, 9'h102, 9'h182: File_Data_Out <= PCL;

    9'h005: File_Data_Out <= {~nButtons, ~nLED}; // PORTA
    9'h085: File_Data_Out <= TRISA;

    9'h003, 9'h083, 9'h103, 9'h183: begin // STATUS
      File_Data_Out <= {IRP, RP, 2'b11, Zero, DecimalCarry, Carry};
    end

    9'h004, 9'h084, 9'h104, 9'h184: File_Data_Out <= FSR;
    9'h00A, 9'h08A, 9'h10A, 9'h18A: File_Data_Out <= {3'h0, PCLATH};

    9'h00B, 9'h08B, 9'h10B, 9'h18B: begin // INTCON
      File_Data_Out <= {GIE, 1'b0, T0IE, 2'b00, T0IF, 2'b00};
    end

    9'h09A, 9'h09B, 9'h11F, 9'h18E, 9'h19F: File_Data_Out <= 8'd0;

    default: File_Data_Out <= RAM_Output;
  endcase
end
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

