`timescale 1ns / 1ps

module MODEcontroller_tb;
    // Parameters
    parameter is_sub = 0;
    parameter connections = 1;

    // Inputs
    reg clk;
    reg [4:0] opcode;
    reg MLD;
    reg MSD;
    reg SCD;
    reg Start;
    reg VSync_in;

    // Outputs
    wire [2:0] state;
    wire HSync_out;
    wire VSync_out;
    wire MACG_en;
    wire MCMem_en;
    wire ALU_en;

    // Instantiate the Unit Under Test (UUT)
    MODEcontroller #(
        .is_sub(is_sub),
        .connections(connections)
    ) uut (
        .clk(clk),
        .opcode(opcode),
        .MLD(MLD),
        .MSD(MSD),
        .SCD(SCD),
        .Start(Start),
        .VSync_in(VSync_in),
        .state(state),
        .HSync_out(HSync_out),
        .VSync_out(VSync_out),
        .MACG_en(MACG_en),
        .MCMem_en(MCMem_en),
        .ALU_en(ALU_en)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock

    // Test sequence
    initial begin
        // Initialize inputs
        opcode = 0;
        MLD = 0;
        MSD = 0;
        SCD = 0;
        Start = 0;
        VSync_in = 0;

        // Wait for global reset
        #10;

        // Test case 1: Start signal triggers state transition
        Start = 1;
        #10;
        Start = 0;
        #20;

        // Test case 2: Transition through states 1 -> 2 -> 3 -> 4 -> 5
        opcode = 5'd18; // Transition to state 2
        #10;
        opcode = 0;
        #10;
        MLD = 1; // Transition to state 4
        #10;
        MLD = 0;
        SCD = 1; // Transition to state 5
        #10;
        SCD = 0;
        MSD = 1; // Transition back to state 1
        #10;
        MSD = 0;

        // Test case 3: Test state 6 behavior with VSync_in
        opcode = 5'd19; // Transition to state 6
        #10;
        opcode = 0;
        VSync_in = 1;
        #10;
        VSync_in = 0;
        #10;
        VSync_in = 1;
        #10;
        VSync_in = 0;

        // Test case 4: Test state 7 behavior
        opcode = 5'd20; // Transition to state 7
        #10;
        opcode = 0;

        // End simulation
        #50;
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time: %0t | State: %0d | HSync_out: %b | VSync_out: %b | MACG_en: %b | MCMem_en: %b | ALU_en: %b",
                 $time, state, HSync_out, VSync_out, MACG_en, MCMem_en, ALU_en);
    end

endmodule
