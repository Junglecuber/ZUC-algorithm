`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:
// Design Name:
// Module Name:
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module testbench();

    //Inputs
    reg clk;
    reg rstn;
    reg init;
    reg start;
    reg [127:0] KEY;
    reg [127:0] IV;
    //Outputs
    wire [31:0] Z;
    wire Done;


    ZucCore uut(
        .clk       (clk),
        .rstn      (rstn),
        .init      (init),
        .start     (start),
        .KEY       (KEY),
        .IV        (IV),
        .Z         (Z),
        .Done      (Done)
    );

    initial
    begin
        clk  = 0;
        rstn = 0;
        init = 0;
        start = 0;
        KEY = 0;
        IV = 0;

        #35
        rstn = 1;
        #10;

        init = 1;
        // #1
        //KEY = 128'h0;
        //IV = 128'h0;

        // #2
        // KEY = 128'hffffffffffffffffffffffffffffffff;
        // IV  = 128'hffffffffffffffffffffffffffffffff;

        // #3
        KEY = 128'h3d4c4be96a82fdaeb58f641db17b455b;
        IV  = 128'h84319aa8de6915ca1f6bda6bfbd8c766;


        #10
        init = 0;
        start = 1;
        #10
        start = 0;

   end
    always clk = #5 ~clk;   // clk = 10ns

endmodule
