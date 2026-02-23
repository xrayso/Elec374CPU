// SIMULATION COMMANDS:
// vsim -voptargs=+acc work.p1_testbench
// add wave -r sim:/p1_testbench/*
// run 500 ns

`timescale 1ns/10ps
module p1_testbench;

    // on old testbench, but not used signals
    // reg [31:0] CextInput;
    // wire [31:0] BusMuxOut;
    // wire [31:0] Q_mem;

    reg clock;
    reg clear;

    reg [31:0] Mdatain;
    reg READ;
    reg WRITE;

    reg R0in;
	reg R1in;
	reg R2in;
	reg R3in;
	reg R4in;
	reg R5in;
	reg R6in;
	reg R7in;
	reg R8in;
	reg R9in;
	reg R10in;
	reg R11in;
	reg R12in;
	reg R13in;
	reg R14in;
	reg R15in;
    reg LOin;
    reg HIin;
	reg PCin;
    reg IRin;
    reg MARin;
	reg MDRin;
	reg InPortin;
    reg OutPortin;
	reg Yin;
	reg Zin;

    reg R0out;
	reg R1out;
	reg R2out;
	reg R3out;
	reg R4out;
	reg R5out;
	reg R6out;
	reg R7out;
	reg R8out;
	reg R9out;
	reg R10out;
	reg R11out;
	reg R12out;
	reg R13out;
	reg R14out;
	reg R15out;
	reg HIout;
	reg LOout;
	reg PCout;
	reg MDRout;
	reg InPortout;
	reg CextInputout;
    reg Zlowout;
    reg Zhighout;

    reg ADD;
    reg SUB;
    reg AND;
    reg OR;
    reg SHR;
    reg SHRA;
    reg SHL;
    reg ROR;
    reg ROL;
    reg ADDI;
    reg ANDI;
    reg ORI;
    reg DIV;
    reg MUL;
    reg NEG;
    reg NOT;
    reg IncPC;

    wire [31:0] BusMuxOut;
    //reg [31:0] CextInput;
    wire [31:0] Q_mem;
    
    parameter   Default = 4'b0000, Reg_load1a = 4'b0001, Reg_load1b = 4'b0010, Reg_load2a = 4'b0011,
                Reg_load2b = 4'b0100, Reg_load3a = 4'b0101, Reg_load3b = 4'b0110, T0 = 4'b0111,
                T1 = 4'b1000, T2 = 4'b1001, T3 = 4'b1010, T4 = 4'b1011, T5 = 4'b1100, T6 = 4'b1101;
    
    reg [3:0] Present_state = Default;
    
    DataPath DUT(
        .clock(clock),
        .clear(clear),
        .BusMuxOut(BusMuxOut), // not used in testbench, not provided in documentation
    
        .Mdatain(Mdatain),
        .READ(READ),
        .WRITE(WRITE),
        .Q_mem(Q_mem), // not used in testbench, not provided in documentation

        .R0in(R0in),
        .R1in(R1in),
        .R2in(R2in),
        .R3in(R3in),
        .R4in(R4in),
        .R5in(R5in),
        .R6in(R6in),
        .R7in(R7in),
        .R8in(R8in),
        .R9in(R9in),
        .R10in(R10in),
        .R11in(R11in),
        .R12in(R12in),
        .R13in(R13in),
        .R14in(R14in),
        .R15in(R15in),
        .LOin(LOin),
        .HIin(HIin),
        .PCin(PCin),
        .IRin(IRin),
        .MARin(MARin),
        .MDRin(MDRin),
        .InPortin(InPortin),
        .OutPortin(Outportin),
        .Yin(Yin),
        .Zin(Zin),

        .R0out(R0out),
        .R1out(R1out),
        .R2out(R2out),
        .R3out(R3out),
        .R4out(R4out),
        .R5out(R5out),
        .R6out(R6out),
        .R7out(R7out),
        .R8out(R8out),
        .R9out(R9out),
        .R10out(R10out),
        .R11out(R11out),
        .R12out(R12out),
        .R13out(R13out),
        .R14out(R14out),
        .R15out(R15out),
        .HIout(HIout),
        .LOout(LOout),
        .PCout(PCout),
        .MDRout(MDRout),
        .InPortout(InPortout),
        .CextInputout(CextInputout),
        .Zlowout(Zlowout),
        .Zhighout(Zhighout),

        .ADD(ADD),
        .SUB(SUB),
        .AND(AND),
        .OR(OR),
        .SHR(SHR),
        .SHRA(SHRA),
        .SHL(SHL),
        .ROR(ROR),
        .ROL(ROL),
        .ADDI(ADDI),
        .ANDI(ANDI),
        .ORI(ORI),
        .DIV(DIV),
        .MUL(MUL),
        .NEG(NEG),
        .NOT(NOT),
        .IncPC(IncPC)

        //.CextInput(CextInput) // not used in testbench, not provided in documentation

    );

    initial
        begin
        clock = 0;
        forever #10 clock = ~ clock;
    end

    always @(posedge clock) // finite state machine; if clock rising-edge
        begin
        case (Present_state)
            Default : Present_state <= Reg_load1a;
            Reg_load1a : Present_state <= Reg_load1b;
            Reg_load1b : Present_state <= Reg_load2a;
            Reg_load2a : Present_state <= Reg_load2b;
            Reg_load2b : Present_state <= Reg_load3a;
            Reg_load3a : Present_state <= Reg_load3b;
            Reg_load3b : Present_state <= T0;
            T0 : Present_state <= T1;
            T1 : Present_state <= T2;
            T2 : Present_state <= T3;
            T3 : Present_state <= T4;
            T4 : Present_state <= T5;
            T5 : Present_state <= T6;
        endcase
    end

    always @(Present_state) // do the required job in each state
        begin

            clear = 0;
            Mdatain = 32'h00000000;
            READ = 0;
            WRITE = 0;

            R0in = 0;
            R1in = 0;
            R2in = 0;
            R3in = 0;
            R4in = 0;
            R5in = 0;
            R6in = 0;
            R7in = 0;
            R8in = 0;
            R9in = 0;
            R10in = 0;
            R11in = 0;
            R12in = 0;
            R13in = 0;
            R14in = 0;
            R15in = 0;
            LOin = 0;
            HIin = 0;
            PCin = 0;
            IRin = 0;
            MARin = 0;
            MDRin = 0;
            InPortin = 0;
            OutPortin = 0;
            Yin = 0;
            Zin = 0;

            R0out = 0;
            R1out = 0;
            R2out = 0;
            R3out = 0;
            R4out = 0;
            R5out = 0;
            R6out = 0;
            R7out = 0;
            R8out = 0;
            R9out = 0;
            R10out = 0;
            R11out = 0;
            R12out = 0;
            R13out = 0;
            R14out = 0;
            R15out = 0;
            HIout = 0;
            LOout = 0;
            PCout = 0;
            MDRout = 0;
            InPortout = 0;
            CextInputout = 0;
            Zlowout = 0;
            Zhighout = 0;

            ADD = 0;
            SUB = 0;
            AND = 0;
            OR = 0;
            SHR = 0;
            SHRA = 0;
            SHL = 0;
            ROR = 0;
            ROL = 0;
            ADDI = 0;
            ANDI = 0;
            ORI = 0;
            DIV = 0;
            MUL = 0;
            NEG = 0;
            NOT = 0;
            IncPC = 0;

            //Q_mem = 32'h00000000;
            //BusMuxOut = 32'h00000000;
            //CextInput = 32'h00000000;


            case (Present_state) // assert the required signals in each clock cycle
                Default: begin //0
                    clear = 1;
                end

                Reg_load1a: begin //1
                    Mdatain = 32'h00000034;
                    READ = 0; 
                    MDRin = 0; // the first zero is there for completeness
                    READ = 1; 
                    MDRin = 1; // Took out #20 for '1', as it may not be needed
                end

                Reg_load1b: begin //2
                    MDRout = 1; 
                    R5in = 1;
                end

                Reg_load2a: begin //3
                    Mdatain = 32'h00000045;
                    READ = 1; 
                    MDRin = 1;
                end

                Reg_load2b: begin //4
                    MDRout = 1; 
                    R6in = 1;
                end

                Reg_load3a: begin //5
                    Mdatain = 32'h00000067;
                    READ = 1;
                    MDRin = 1;
                end

                Reg_load3b: begin //6
                    MDRout = 1; 
                    PCin = 1;
                end

                T0: begin // 7  see if you need to de-assert these signals
                    PCout = 1; 
                    MARin = 1; 
                    IncPC = 1; 
                    Zin = 1;
                end

                T1: begin
                    Zlowout = 1; 
                    PCin = 1; 
                    READ = 1; 
                    MDRin = 1;
                    Mdatain = 32'h112B0000; // opcode for “and R2, R5, R6”

                    // Opcodes for Different Instructions:
                    // 32'b00000xxxxxxxxxxxxxxxxxxxxxxxxxxx | ADD
                    // 32'b00001xxxxxxxxxxxxxxxxxxxxxxxxxxx | SUB
                    // 32'b00010xxxxxxxxxxxxxxxxxxxxxxxxxxx | AND
                    // 32'b00011xxxxxxxxxxxxxxxxxxxxxxxxxxx | OR
                    // 32'b00100xxxxxxxxxxxxxxxxxxxxxxxxxxx | SHR
                    // 32'b00101xxxxxxxxxxxxxxxxxxxxxxxxxxx | SHRA
                    // 32'b00110xxxxxxxxxxxxxxxxxxxxxxxxxxx | SHL
                    // 32'b00111xxxxxxxxxxxxxxxxxxxxxxxxxxx | ROR
                    // 32'b01000xxxxxxxxxxxxxxxxxxxxxxxxxxx | ROL
                    // 32'b01001xxxxxxxxxxxxxxxxxxxxxxxxxxx | ADDI (not implemented)
                    // 32'b01010xxxxxxxxxxxxxxxxxxxxxxxxxxx | ANDI (not implemented)
                    // 32'b01011xxxxxxxxxxxxxxxxxxxxxxxxxxx | ORI (not implemented)
                    // 32'b01100xxxxxxxxxxxxxxxxxxxxxxxxxxx | DIV
                    // 32'b01101xxxxxxxxxxxxxxxxxxxxxxxxxxx | MUL
                    // 32'b01110xxxxxxxxxxxxxxxxxxxxxxxxxxx | NEG
                    // 32'b01111xxxxxxxxxxxxxxxxxxxxxxxxxxx | NOT

                end

                T2: begin
                    MDRout = 1; 
                    IRin = 1;
                end

                T3: begin
                    R5out = 1; 
                    Yin = 1;
                end

                T4: begin
                    R6out = 1;
                    AND = 1;
                    Zin = 1;
                end

                T5: begin
                    LOin = 1;
                    Zlowout = 1; 
                    R2in = 1;
                end

                T6: begin
                    Zhighout = 1;
                    HIin = 1;
                end
            endcase
        end
endmodule