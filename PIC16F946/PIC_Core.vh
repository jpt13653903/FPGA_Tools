// Instruction set
`define ADDWF  14'b00_0111_xxxx_xxxx
`define ANDWF  14'b00_0101_xxxx_xxxx
`define CLRWF  14'b00_0001_xxxx_xxxx
`define COMF   14'b00_1001_xxxx_xxxx
`define DECF   14'b00_0011_xxxx_xxxx
`define DECFSZ 14'b00_1011_xxxx_xxxx
`define INCF   14'b00_1010_xxxx_xxxx
`define INCFSZ 14'b00_1111_xxxx_xxxx
`define IORWF  14'b00_0100_xxxx_xxxx
`define MOVF   14'b00_1000_xxxx_xxxx
`define MOVWF  14'b00_0000_1xxx_xxxx
`define NOP    14'b00_0000_0xx0_0000
`define RLF    14'b00_1101_xxxx_xxxx
`define RRF    14'b00_1100_xxxx_xxxx
`define SUBWF  14'b00_0010_xxxx_xxxx
`define SWAPF  14'b00_1110_xxxx_xxxx
`define XORWF  14'b00_0110_xxxx_xxxx

`define BCF    14'b01_00xx_xxxx_xxxx
`define BSF    14'b01_01xx_xxxx_xxxx
`define BTFSC  14'b01_10xx_xxxx_xxxx
`define BTFSS  14'b01_11xx_xxxx_xxxx

`define ADDLW  14'b11_111x_xxxx_xxxx
`define ANDLW  14'b11_1001_xxxx_xxxx
`define CALL   14'b10_0xxx_xxxx_xxxx
`define CLRWDT 14'b00_0000_0110_0100
`define GOTO   14'b10_1xxx_xxxx_xxxx
`define IORLW  14'b11_1000_xxxx_xxxx
`define MOVLW  14'b11_00xx_xxxx_xxxx
`define RETFIE 14'b00_0000_0000_1001
`define RETLW  14'b11_01xx_xxxx_xxxx
`define RETURN 14'b00_0000_0000_1000
`define SLEEP  14'b00_0000_0110_0011
`define SUBLW  14'b11_110x_xxxx_xxxx
`define XORLW  14'b11_1010_xxxx_xxxx

// States
`define LatchWF    2'b00
`define Test_Zero  2'b01
`define Test_nZero 2'b10
`define Wait       2'b11

// Goto Types
`define Branch_None   2'h0
`define Branch_Goto   2'h1
`define Branch_Call   2'h2
`define Branch_Return 2'h3
//------------------------------------------------------------------------------

