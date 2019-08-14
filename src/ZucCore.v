// `timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Data Assurance & Communications Security Center.
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 2009 - 2019 DCS Center.
//                           ALL RIGHTS RESERVED
//
// The entire notice above must be reproduced on all authorized copies.
//
// AUTHOR:    Junglecuber 19.8.10
//
// VERSION:   Verilog
//
//
////////////////////////////////////////////////////////////////////////////////

`define d 240'h89ae9af3135935eaf12d78b89a89af9af0bc4f5e21af1bc4cf137c4d47ac //d0 ... d15

module ZucCore(
    input            clk,
    input            rstn,
    input            init,
    input            start,
    input   [127:0]  KEY, // K0 to K15
    input   [127:0]  IV,  // IV0 to IV15
    output  [31:0]   Z, // keystream
    output  reg      Done
    );

    reg     [1:0]    State;
    reg     [7:0]    round;
    reg              flag; // LFSR init_mode for 0 and work_mode for 1
    reg     [30:0]   S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15;
    reg     [31:0]   R1,R2;
    reg     [239:0]  d;    // d0 to d15


    // The linear feedback shift register (LFSR)
    wire [30:0] U,V,S16;
    // U = W >> 1
    assign U = flag ?  31'd0 : W[31:1];
    // V = (S15<<<15)+(S13<<<17)+(S10<<<21)+(S4<<<20)+(S0<<<8)+S0 mod (2^31-1)
    assign V = Add(Add(Add(Add(Add(S0,{S0[22:0],S0[30:23]}),{S4[10:0],S4[30:11]}),{S10[9:0],S10[30:10]}),{S13[13:0],S13[30:14]}),{S15[15:0],S15[30:16]});
    // S16 = U + V
    // S16 = 2^31 -1 ,if S16 = 0
    assign S16 = Add(U, V) ? Add(U, V) : 31'h7fffffff;

    // The bit-reorganization
    wire [31:0] X0,X1,X2,X3;
    assign {X0,X1,X2,X3} = {{S15[30:15], S14[15:0]},{S11[15:0], S9[30:15]},{S7[15:0], S5[30:15]},{S2[15:0], S0[30:15]}};

    // The nonlinear function F
    wire [31:0] W,W1,W2;
    wire [31:0] T1,T2,L1,L2,L1_BOX,L2_BOX;

    assign W  = (X0 ^ R1) + R2;
    assign W1 = R1 + X1;
    assign W2 = R2 ^ X2;

    assign T1 = {W1[15:0],W2[31:16]};
    assign L1 = T1 ^ {T1[29:0],T1[31:30]} ^ {T1[21:0],T1[31:22]} ^ {T1[13:0],T1[31:14]} ^ {T1[7:0],T1[31:8]};
    wire [7:0] y1,y2,y3,y4;
    S0_box sbox1(.a(L1[31:24]),.d(y1));
    S1_box sbox2(.a(L1[23:16]),.d(y2));
    S0_box sbox3(.a(L1[15:8]),.d(y3));
    S1_box sbox4(.a(L1[7:0]),.d(y4));
    assign L1_BOX = {y1,y2,y3,y4};

    assign T2 = {W2[15:0],W1[31:16]};
    assign L2 = T2 ^ {T2[23:0],T2[31:24]} ^ {T2[17:0],T2[31:18]} ^ {T2[9:0],T2[31:10]} ^ {T2[1:0],T2[31:2]};
    wire [7:0] y5,y6,y7,y8;
    S0_box sbox5(.a(L2[31:24]),.d(y5));
    S1_box sbox6(.a(L2[23:16]),.d(y6));
    S0_box sbox7(.a(L2[15:8]),.d(y7));
    S1_box sbox8(.a(L2[7:0]),.d(y8));
    assign L2_BOX = {y5,y6,y7,y8};

    // producing keystream for one operation in LFSR work_mode
    assign Z = W ^ X3;

    // Add Function for mod 2^31 - 1
    function [31:0] Add;
    input    [31:0] a,b;
    begin
        Add = ((a + b) & 32'h7FFF_FFFF) + ((a + b) >> 31);
    end
    endfunction

    parameter   Idle       = 2'b00,
                InitialS   = 2'b01,
                Iteration  = 2'b10,
                Assign     = 2'b11;

    // State control
    always@(posedge clk or negedge rstn) begin
        if (!rstn) State <= Idle;
        else begin
            case (State)
                Idle: begin
                    if (init) State <= InitialS;
                    else State <= State;
                end
                InitialS: begin
                    if (start) State <= Iteration;
                    else  State <= State;
                end
                Iteration: begin
                    if(round >= 8'd33) State <= Assign;
                    else State <= State;
                end
                Assign:  State <= Idle;
                default: State <= Idle;
            endcase
        end
    end

    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            // clear
            {S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15} <= 31'd0;
            {R1,R2} <= 32'd0;
            round <= 8'd0;
            Done <= 1'd0;
            flag <= 1'd0;
            d <= 240'd0;
        end else begin
            case(State)
                Idle: begin
                    {S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15} <= 31'd0;
                    {R1,R2} <= 32'd0;
                    round <= 8'd0;
                    Done <= 1'd0;
                    flag <= 1'd0;
                    d <= `d;
                end
                InitialS : {S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15} <= { {KEY[127:120],d[239:225],IV[127:120]},{KEY[119:112],d[224:210],IV[119:112]},{KEY[111:104],d[209:195],IV[111:104]},{KEY[103:96],d[194:180],IV[103:96]},{KEY[95:88],d[179:165],IV[95:88]},{KEY[87:80],d[164:150],IV[87:80]},{KEY[79:72],d[149:135],IV[79:72]},{KEY[71:64],d[134:120],IV[71:64]},{KEY[63:56],d[119:105],IV[63:56]},{KEY[55:48],d[104:90],IV[55:48]},{KEY[47:40],d[89:75],IV[47:40]},{KEY[39:32],d[74:60],IV[39:32]},{KEY[31:24],d[59:45],IV[31:24]},{KEY[23:16],d[44:30],IV[23:16]},{KEY[15:8],d[29:15],IV[15:8]},{KEY[7:0],d[14:0],IV[7:0]} };
                Iteration: begin
                    round <= round + 8'd1;
                    // round = 0 to 0x20
                    if (round < 8'h1f) begin
                        flag <= 1'd0;
                        {R1,R2} <= {L1_BOX,L2_BOX};
                        {S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15} <= {S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15,S16};
                    end
                    else begin
                         flag <= 1'd1; // LFSR work_mode for 1
                         {R1,R2} <= {L1_BOX,L2_BOX};
                         {S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15} <= {S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15,S16};
                    end
                end
                Assign: Done <= 1'b1;
            endcase
        end
    end

endmodule




