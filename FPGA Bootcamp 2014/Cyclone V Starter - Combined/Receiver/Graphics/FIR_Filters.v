module FIR_Filters(
  input Reset,
  input Clk,
  input FIR_Clk,
  input Sound_Clk, // DDR

  input [15:0]Sound,

  input       Sound_Sync,
  input       Level_Sync,
  output [3:0]Spectrum[7:0][4:0]
);
//------------------------------------------------------------------------------

reg  [12:0]Buffer_Address;
reg        Buffer_WrEn;
wire [15:0]Buffer_Data[1:0];

FIR_Buffer Sound_Buffer(
  .clock    (FIR_Clk),

  .address_a(Buffer_Address),
  .data_a   (Sound),
  .wren_a   (Buffer_WrEn),
  .q_a      (Buffer_Data[0]),

  .address_b(Buffer_Address-1'b1),
  .data_b   (16'd0),
  .wren_b   ( 1'b0),
  .q_b      (Buffer_Data[1])
);
//------------------------------------------------------------------------------

reg  [12:1]Taps_Address;
wire [17:0]Taps_Data[7:0][1:0];

FIR_Taps_0 Taps0(
  .clock    (FIR_Clk),
  .address_a({Taps_Address, 1'b0}),
  .address_b({Taps_Address, 1'b1}),
  .q_a      (Taps_Data[0][0]),
  .q_b      (Taps_Data[0][1])
);

FIR_Taps_1 Taps1(
  .clock    (FIR_Clk),
  .address_a({Taps_Address, 1'b0}),
  .address_b({Taps_Address, 1'b1}),
  .q_a      (Taps_Data[1][0]),
  .q_b      (Taps_Data[1][1])
);

FIR_Taps_2 Taps2(
  .clock    (FIR_Clk),
  .address_a({Taps_Address, 1'b0}),
  .address_b({Taps_Address, 1'b1}),
  .q_a      (Taps_Data[2][0]),
  .q_b      (Taps_Data[2][1])
);

FIR_Taps_3 Taps3(
  .clock    (FIR_Clk),
  .address_a({Taps_Address, 1'b0}),
  .address_b({Taps_Address, 1'b1}),
  .q_a      (Taps_Data[3][0]),
  .q_b      (Taps_Data[3][1])
);

FIR_Taps_4 Taps4(
  .clock    (FIR_Clk),
  .address_a({Taps_Address, 1'b0}),
  .address_b({Taps_Address, 1'b1}),
  .q_a      (Taps_Data[4][0]),
  .q_b      (Taps_Data[4][1])
);

FIR_Taps_5 Taps5(
  .clock    (FIR_Clk),
  .address_a({Taps_Address, 1'b0}),
  .address_b({Taps_Address, 1'b1}),
  .q_a      (Taps_Data[5][0]),
  .q_b      (Taps_Data[5][1])
);

FIR_Taps_6 Taps6(
  .clock    (FIR_Clk),
  .address_a({Taps_Address, 1'b0}),
  .address_b({Taps_Address, 1'b1}),
  .q_a      (Taps_Data[6][0]),
  .q_b      (Taps_Data[6][1])
);

FIR_Taps_7 Taps7(
  .clock    (FIR_Clk),
  .address_a({Taps_Address, 1'b0}),
  .address_b({Taps_Address, 1'b1}),
  .q_a      (Taps_Data[7][0]),
  .q_b      (Taps_Data[7][1])
);
//------------------------------------------------------------------------------

wire [33:0]Product[7:0][1:0];

genvar g;
generate
  for(g = 0; g < 8; g++) begin: Gen_Multipliers
    FIR_Multiply Multiply0(
      FIR_Clk, 
      Buffer_Data [0],
      Taps_Data[g][0],
      Product  [g][0]
    );

    FIR_Multiply Multiply1(
      FIR_Clk, 
      Buffer_Data [1], 
      Taps_Data[g][1], 
      Product  [g][1]
    );
  end
endgenerate
//------------------------------------------------------------------------------

reg [37:0]Sum     [7:0];
reg [15:0]Filtered[7:0];
reg [12:0]Address;
//------------------------------------------------------------------------------

reg   [1:0]State;
localparam Idle   = 2'd0;
localparam Sample = 2'd1;
localparam Filter = 2'd2;
localparam Done   = 2'd3;
//------------------------------------------------------------------------------

integer j;

reg      tReset;
reg [1:0]tSound_Clk;

always @(posedge FIR_Clk) begin
  tReset     <= Reset;
  tSound_Clk <= {tSound_Clk[0], Sound_Clk};
//------------------------------------------------------------------------------

  if(tReset) begin
    Address        <= 0;
    Buffer_Address <= 0;
    Buffer_WrEn    <= 0;

    Taps_Address <= 0;

    for(j = 0; j < 8; j++) begin
      Sum     [j] <= 0;
      Filtered[j] <= 0;
    end

    State <= Idle;
//------------------------------------------------------------------------------

  end else begin
    case(State)
      Idle: begin
        if(^tSound_Clk) begin
          Buffer_Address <= Address;
          Buffer_WrEn    <= 1'b1;
          State          <= Sample;
        end
      end
//------------------------------------------------------------------------------

      Sample: begin
        Buffer_WrEn <= 1'b0;
        Address     <= Address + 1'b1;
        State       <= Filter;

        for(j = 0; j < 8; j++) Sum[j] <= 0;
      end
//------------------------------------------------------------------------------

      Filter: begin
        if(|Taps_Address[12:3]) begin // Pipe-line delay of Address -> Product
          for(j = 0; j < 8; j++) begin
            Sum[j] <= Sum[j] + {{4{Product[j][0][33]}}, Product[j][0]} + 
                               {{4{Product[j][1][33]}}, Product[j][1]} ;
          end
        end

        if(&Taps_Address) State <= Done;
    
        Taps_Address   <= Taps_Address   + 1'b1;
        Buffer_Address <= Buffer_Address - 2'd2;
      end
//------------------------------------------------------------------------------

      Done: begin
        // No need to add the last few products: the taps are zero

        for(j = 0; j < 8; j++) begin
          if(Sum[j][37]) begin
            if(&Sum[j][36:32]) Filtered[j] <= Sum[j][32:17];
            else               Filtered[j] <= 16'h8000;
          end else begin
            if(|Sum[j][36:32]) Filtered[j] <= 16'h7FFF;
            else               Filtered[j] <= Sum[j][32:17];
          end
        end

        State <= Idle;
      end
//------------------------------------------------------------------------------

      default:;
    endcase
  end
end
//------------------------------------------------------------------------------

wire [15:0]Abs[7:0];

generate
  for(g = 0; g < 8; g++) begin: Gen_Levels
    assign Abs[g] = Filtered[g][15] ? ~Filtered[g] + 1'b1 : Filtered[g];

    LevelFilter #(16'd_13_045) Filter_4(Reset, Clk, Sound_Sync, Level_Sync, 
                                        Abs[g], Spectrum[g][4]);
    LevelFilter #(16'd__5_193) Filter_3(Reset, Clk, Sound_Sync, Level_Sync, 
                                        Abs[g], Spectrum[g][3]);
    LevelFilter #(16'd__2_068) Filter_2(Reset, Clk, Sound_Sync, Level_Sync, 
                                        Abs[g], Spectrum[g][2]);
    LevelFilter #(16'd____823) Filter_1(Reset, Clk, Sound_Sync, Level_Sync, 
                                        Abs[g], Spectrum[g][1]);
    LevelFilter #(16'd____328) Filter_0(Reset, Clk, Sound_Sync, Level_Sync, 
                                        Abs[g], Spectrum[g][0]);
  end
endgenerate
//------------------------------------------------------------------------------

endmodule
//------------------------------------------------------------------------------

