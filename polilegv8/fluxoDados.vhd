library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity fluxoDados is
    port(
        clock : in std_logic; -- entrada de clock
        reset : in std_logic; -- clear assincrono
        extendMSB : in std_logic_vector (4 downto 0); -- sinal de controle sign-extend
        extendLSB : in std_logic_vector (4 downto 0); -- sinal de controle sign-extend
        reg2Loc : in std_logic; -- sinal de controle MUX Read Register 2
        regWrite : in std_logic; -- sinal de controle Write Register
        aluSrc : in std_logic; -- sinal de controle MUX entrada B ULA
        alu_control : in std_logic_vector (5 downto 0); -- sinal de controle da ULA
        branch : in std_logic; -- sinal de controle desvio condicional
        uncondBranch : in std_logic; -- sinal de controle desvio incondicional
        memRead : in std_logic; -- sinal de controle leitura RAM dados
        memWrite : in std_logic; -- sinal de controle escrita RAM dados
        memToReg : in std_logic; -- sinal de controle MUX Write Data
        reg2Pc : in std_logic;
        pc2reg : in std_logic;
        opcode : out std_logic_vector (10 downto 0); -- sinal de condição código da instrução
        miso : in std_logic;
        mosi : out std_logic;
        sck : out std_logic;
        cs : out std_logic;
        GPIO : out std_logic_vector(63 downto 0);
        endereco_instrucoes : out std_logic_vector(9 downto 0)
    );
end entity fluxoDados;

architecture archFluxoDados of fluxoDados is

    constant DATA_WIDTH : natural := 12;
    constant INSTRUCTION_WIDTH : natural := 10;
    constant CONTROLE_ADDR : std_logic_vector(15 downto 0) := x"1000";
    constant GPIO_ADDR : std_logic_vector(15 downto 0) := x"1001";

    component staller is
        port (
            clock : in std_logic;
            reset : in std_logic;
            memToReg : in std_logic;
            stall : out std_logic
        );
    end component;
    component adder_n is
        generic(dataSize : natural := 64);
        port(
            in0 : in std_logic_vector(dataSize-1 downto 0);
            in1 : in std_logic_vector(dataSize-1 downto 0);
            sum : out std_logic_vector(dataSize-1 downto 0);
            cOut : out std_logic
        );
    end component;
    component regfile is
        port (
            clock : in std_logic;
            reset : in std_logic;
            regWrite: in std_logic;
            rr1 : in std_logic_vector(4 downto 0);
            rr2 : in std_logic_vector(4 downto 0);
            wr : in std_logic_vector(4 downto 0);
            d : in std_logic_vector(63 downto 0);
            q1 : out std_logic_vector(63 downto 0);
            q2 : out std_logic_vector(63 downto 0)
        );
    end component;
    component memoriaDados is
    generic (
        addressSize : natural := 7;
        dataSize : natural := 64
    );
    port (
        clock : in std_logic;

        addr : in std_logic_vector(addressSize-1 downto 0);
        data_out : out std_logic_vector(dataSize-1 downto 0);
        data_in : in std_logic_vector(dataSize-1 downto 0);
        wr : in std_logic
    );
    end component;
    component memoriaInstrucoes is
        generic (
            addressSize : natural := 8;
            dataSize : natural := 32
        );
        port (
            clock : in std_logic;
            addr : in std_logic_vector(addressSize-1 downto 0);
            data : out std_logic_vector(dataSize-1 downto 0)
        );
    end component;
    component mux_n is
        generic(dataSize : natural := 64);
        port(
            in0: in std_logic_vector (dataSize-1 downto 0);
            in1: in std_logic_vector (dataSize-1 downto 0);
            sel: in std_logic;
            dOut: out std_logic_vector(dataSize-1 downto 0)
        );
    end component;
    component reg is 
        generic(dataSize: natural := 64);
        port(
            clock : in std_logic;
            reset: in std_logic;
            enable: in std_logic;
            d: in std_logic_vector(dataSize-1 downto 0);
            q: out std_logic_vector(dataSize-1 downto 0)
        );
    end component;
    component sign_extend is
        generic (
            dataISize : natural := 32;
            dataOSize : natural := 64;
            dataMaxPosition : natural := 5

        );
        port (
            inData      : in  std_logic_vector(dataISize-1 downto 0);
            inDataStart : in  std_logic_vector(dataMaxPosition-1 downto 0);
            inDataEnd   : in  std_logic_vector(dataMaxPosition-1 downto 0);
            outData     : out std_logic_vector(dataOSize-1 downto 0)
        );
    end component;
    component ula is
        port (
            A : in std_logic_vector(63 downto 0);
            B : in std_logic_vector(63 downto 0);
            shamt : in std_logic_vector(5 downto 0);
            S : in std_logic_vector(5 downto 0);
            F : out std_logic_vector(63 downto 0);
            Z : out std_logic;
            Ov : out std_logic;
            Co : out std_logic
        );
    end component;

    component controladorSD is
        port (
            clock : in std_logic;
            reset : in std_logic;
            request : in std_logic;
            block_addr : in std_logic_vector(31 downto 0);
            miso : in std_logic;
            ready : out std_logic;
            busy : out std_logic;
            bram_wr_en : out std_logic;
            bram_wr_addr : out std_logic_vector(6 downto 0);
            bram_wr_data : out std_logic_vector(63 downto 0);
            mosi, sck, cs : out std_logic;
            clear_request : out std_logic;
            db_estado : out std_logic_vector(7 downto 0)
        );
    end component;

    signal PCOut : std_logic_vector(INSTRUCTION_WIDTH-1 downto 0);
    signal instructionAddr, addr_a : std_logic_vector(INSTRUCTION_WIDTH-1 downto 0);
    signal dataAddr : std_logic_vector(15 downto 0);
    signal instruction : std_logic_vector(31 downto 0);
    signal regGPIO_in, regGPIO_out : std_logic_vector(63 downto 0);
    signal rr2In, writeRegAddrIn : std_logic_vector(4 downto 0);
    signal dataMemoryOut, ULAOut, data_a_in, writeRegisterIn, reg1Data, reg2Data, signExtendOut, ulaB, PCIn, adderBranchOut, adderNextInstructionOut, adderBranchA, adderNextInstructionA, regControle_in, regControle_out, dataToReg, branchOut, memToRegMuxOut, PCSomaUmOut, RegSomaUmOut : std_logic_vector(63 downto 0);
    signal zero, branchSignal, isUsingAddrDataMemory, enable_regGPIO : std_logic;
    signal notClock, PCenable, stall, wr_a, ready, busy, enable_regControle, enable_memoriaDados : std_logic;

begin

    -- ============ MUXES ============
    reg2locMux : mux_n generic map (5) port map (instruction(20 downto 16), instruction(4 downto 0), reg2Loc, rr2In);
    mem2regMux : mux_n port map (ULAOut, dataToReg, memToReg, memToRegMuxOut);
    ALUsrcMux : mux_n port map (reg2Data, signExtendOut, aluSrc, ulaB);
    branchMux : mux_n port map (adderNextInstructionOut, branchOut, branchSignal, PCIn);
    dataMemoryAddrMux: mux_n generic map (16) port map(x"0000", ULAOut(15 downto 0), isUsingAddrDataMemory, dataAddr);
    branchSrcMux: mux_n
     generic map(
        dataSize => 64
    )
     port map(
        in0 => adderBranchOut,
        in1 => reg1Data,
        sel => reg2Pc,
        dOut => branchOut
    );
    pc2regMux: mux_n
     generic map(
        dataSize => 64
    )
     port map(
        in0 => memToRegMuxOut,
        in1 => RegSomaUmOut,
        sel => pc2reg,
        dOut => writeRegisterIn
    );
    writeRegDataMux: mux_n
     generic map(
        dataSize => 5
    )
     port map(
        in0 => instruction(4 downto 0),
        in1 => "11110",
        sel => pc2reg,
        dOut => writeRegAddrIn
    );


    -- ============ COMPONENTES GERAIS ============
    staller_inst: staller
     port map(
        clock => clock,
        reset => reset,
        memToReg => memToReg,
        stall => stall
    );
    PC : reg generic map (10) port map (notClock, reset, PCEnable, PCIn(INSTRUCTION_WIDTH-1 downto 0), PCOut);
    RegSomaUm: reg
     generic map(
        dataSize => 64
    )
     port map(
        clock => clock,
        reset => reset,
        enable => '1',
        d => PCSomaUmOut,
        q => RegSomaUmOut
    );
    InstructionMemory : memoriaInstrucoes generic map (10, 32) port map (clock, instructionAddr, instruction);
    BancoRegistradores : regfile port map (clock, reset, regWrite, instruction(9 downto 5), rr2In, writeRegAddrIn, writeRegisterIn, reg1Data, reg2Data);
    ALU: ula
     port map(
        A => reg1Data,
        B => ulaB,
        shamt => instruction(15 downto 10),
        S => alu_control,
        F => ULAOut,
        Z => zero,
        Ov => open,
        Co => open
    );
    SignExtend : sign_extend port map (instruction, extendMSB, extendLSB, signExtendOut);
    AdderBranch : adder_n port map (adderBranchA, signExtendOut, adderBranchOut);
    PCSomaUm: adder_n
     generic map(
        dataSize => 64
    )
     port map(
        in0 => x"0000000000000" & "00" & PCOut,
        in1 => x"0000000000000001",
        sum => PCSomaUmOut,
        cOut => open
    );
    AdderNextInstruction : adder_n port map (adderNextInstructionA, x"0000000000000001", adderNextInstructionOut);
    memoriaDados_inst: memoriaDados
     generic map(
        addressSize => DATA_WIDTH,
        dataSize => 64
    )
     port map(
        clock => clock,
        addr => dataAddr(DATA_WIDTH-1 downto 0),
        data_in => reg2Data,
        data_out => dataMemoryOut,
        wr => enable_memoriaDados
    );
    regControle: reg
     generic map(
        dataSize => 64
    )
     port map(
        clock => clock,
        reset => reset,
        enable => enable_regControle,
        d => regControle_in,
        q => regControle_out
    );
    regGPIO: reg
     generic map(
        dataSize => 64
    )
     port map(
        clock => clock,
        reset => reset,
        enable => enable_regGPIO,
        d => regGPIO_in,
        q => regGPIO_out
    );
    
    PCenable <= not stall;
    notClock <= not clock;
    branchSignal <= (zero and branch) or uncondBranch;
    opcode <= instruction(31 downto 21);
    instructionAddr <= PCOut;
    adderBranchA <= "000000000000000000000000000000000000000000000000000000" & PCOut;
    adderNextInstructionA <= "000000000000000000000000000000000000000000000000000000" & PCOut;
    isUsingAddrDataMemory <= memRead or memWrite;
    regControle_in <= x"000000000000000" & miso & reg2Data(2 downto 0);
    regGPIO_in <= reg2Data;
    dataToReg <= regControle_out when dataAddr = CONTROLE_ADDR else
                 regGPIO_out when dataAddr = GPIO_ADDR else
                 dataMemoryOut;
    enable_regControle <= memWrite when dataAddr = CONTROLE_ADDR else '0';
    enable_regGPIO <= memWrite when dataAddr = GPIO_ADDR else '0';
    enable_memoriaDados <= memWrite when dataAddr(DATA_WIDTH) = '0' else '0';
    GPIO <= regGPIO_out;
    endereco_instrucoes <= PCOut;
    sck <= regControle_out(0);
    cs <= regControle_out(1);
    mosi <= regControle_out(2);
end archFluxoDados ; -- archFluxoDados
