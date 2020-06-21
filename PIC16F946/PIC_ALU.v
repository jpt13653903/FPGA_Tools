`include "ALU_Instructions.vh"
//------------------------------------------------------------------------------

module PIC_ALU(
  input      [3:0]Instruction,

  input      [7:0]In1, // File / Literal
  input      [7:0]In2, // W / Bit / Carry
  output reg [7:0]Out,

  output     Zero,
  output     DecimalCarry,
  output reg Carry
);
//------------------------------------------------------------------------------

reg [7:0]BitMask;

always @(In2[2:0]) begin
  case(In2[2:0])
    3'h0: BitMask <= 8'b00000001;
    3'h1: BitMask <= 8'b00000010;
    3'h2: BitMask <= 8'b00000100;
    3'h3: BitMask <= 8'b00001000;
    3'h4: BitMask <= 8'b00010000;
    3'h5: BitMask <= 8'b00100000;
    3'h6: BitMask <= 8'b01000000;
    3'h7: BitMask <= 8'b10000000;
    default:;
  endcase
end
//------------------------------------------------------------------------------

always @(Instruction, In1, In2, BitMask) begin
  case(Instruction)
    `ALU_Add        : {Carry, Out} <= {1'b0, In1} + {1'b0, In2};
    `ALU_And        : {Carry, Out} <= {1'b0, In1 & In2};
    `ALU_Or         : {Carry, Out} <= {1'b0, In1 | In2};
    `ALU_XOr        : {Carry, Out} <= {1'b0, In1 ^ In2};
    `ALU_RotateLeft : {Carry, Out} <= {In1, In2[0]};
    `ALU_RotateRight: {Out, Carry} <= {In2[0], In1};
    `ALU_Swap       : {Carry, Out} <= {1'b0, In1[3:0], In1[7:4]};
    `ALU_BitSet     : {Carry, Out} <= {1'b0, In1 |   BitMask };
    `ALU_BitClear   : {Carry, Out} <= {1'b0, In1 & (~BitMask)};
    `ALU_BitTest    : {Carry, Out} <= {1'b0, In1 &   BitMask };
    default         : {Carry, Out} <= 9'd0;
  endcase
end
//------------------------------------------------------------------------------

assign DecimalCarry =   Out[4] ^ (In1[4] ^ In2[4]);
assign Zero         = ~|Out;
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

