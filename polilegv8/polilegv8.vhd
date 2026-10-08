library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity polilegv8 is
    port (
        clock : in std_logic;
        reset : in std_logic;
        GPIO  : out std_logic_vector(63 downto 0);
        miso : in std_logic;
        mosi, sck, cs : out std_logic;
        display0, display1, display2, display3 : out std_logic_vector(6 downto 0);
        db_cs : out std_logic;
        db_mosi : out std_logic;
        db_miso : out std_logic;
        db_sck : out std_logic
    );
end entity polilegv8;

architecture archPolilegv8 of polilegv8 is

    component fluxoDados is
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
        miso : in std_logic;
        opcode : out std_logic_vector (10 downto 0); -- sinal de condição código da instrução
        mosi : out std_logic;
        sck : out std_logic;
        cs : out std_logic;
        GPIO : out std_logic_vector(63 downto 0);
        endereco_instrucoes : out std_logic_vector(9 downto 0)
    );
    end component;

    component ip_clock is
    port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		locked   : out std_logic         --  locked.export
	);
    end component;

    component unidadeControle is
    port(
        opcode : in std_logic_vector (10 downto 0); -- sinal de condição código da instrução
        extendMSB : out std_logic_vector (4 downto 0); -- sinal de controle sign-extend
        extendLSB : out std_logic_vector (4 downto 0); -- sinal de controle sign-extend
        reg2Loc : out std_logic; -- sinal de controle MUX Read Register 2
        regWrite : out std_logic; -- sinal de controle Write Register
        aluSrc : out std_logic; -- sinal de controle MUX entrada B ULA
        alu_control : out std_logic_vector (5 downto 0); -- sinal de controle da ULA
        branch : out std_logic; -- sinal de controle desvio condicional
        uncondBranch : out std_logic; -- sinal de controle desvio incondicional
        memRead : out std_logic; -- sinal de controle leitura RAM dados
        memWrite : out std_logic; -- sinal de controle escrita RAM dados
        memToReg : out std_logic; -- sinal de controle MUX Write Data
        reg2Pc  : out std_logic;
        pc2reg : out std_logic
    );
    end component;
    component hex7seg is
	port (  
        hex      : in  std_logic_vector(3 downto 0);
        display  : out std_logic_vector(6 downto 0)
	);
    end component;

    signal opcode : std_logic_vector (10 downto 0);
    signal extendMSB, extendLSB : std_logic_vector (4 downto 0);
    signal alu_control : std_logic_vector (5 downto 0);
    signal reg2loc, regWrite, aluSrc, branch, uncondBranch, memRead, memWrite, memToReg : std_logic;
    signal cs_int, mosi_int, miso_int, sck_int, reg2Pc, pc2reg : std_logic;
    signal endereco_instrucoes : std_logic_vector(9 downto 0);
    signal clock_div : std_logic;

begin
    FA: fluxoDados
     port map(
        clock => clock_div,
        reset => reset,
        extendMSB => extendMSB,
        extendLSB => extendLSB,
        reg2Loc => reg2Loc,
        regWrite => regWrite,
        aluSrc => aluSrc,
        alu_control => alu_control,
        branch => branch,
        uncondBranch => uncondBranch,
        memRead => memRead,
        memWrite => memWrite,
        memToReg => memToReg,
        reg2Pc => reg2Pc,
        pc2reg => pc2reg,
        miso => miso_int,
        opcode => opcode,
        mosi => mosi_int,
        sck => sck_int,
        cs => cs_int,
        GPIO => GPIO,
        endereco_instrucoes => endereco_instrucoes
    );

    unidadeControle_inst: unidadeControle
     port map(
        opcode => opcode,
        extendMSB => extendMSB,
        extendLSB => extendLSB,
        reg2Loc => reg2Loc,
        regWrite => regWrite,
        aluSrc => aluSrc,
        alu_control => alu_control,
        branch => branch,
        uncondBranch => uncondBranch,
        memRead => memRead,
        memWrite => memWrite,
        memToReg => memToReg,
        reg2Pc => reg2Pc,
        pc2reg => pc2reg
    );

    display0_inst: hex7seg
     port map(
        hex => endereco_instrucoes(3 downto 0),
        display => display0
    );

    display1_inst: hex7seg
     port map(
        hex => endereco_instrucoes(7 downto 4),
        display => display1
    );

    display2_inst: hex7seg
     port map(
        hex => "00" & endereco_instrucoes(9 downto 8),
        display => display2
    );

    display3_inst: hex7seg
     port map(
        hex => "0000",
        display => display3
    );

    db_cs <= cs_int;
    cs <= cs_int;
    db_mosi <= mosi_int;
    mosi <= mosi_int;
    db_miso <= miso_int;
    miso_int <= miso;
    db_sck <= sck_int;
    sck <= sck_int;

    ip_clock_inst: ip_clock
     port map(
        refclk => clock,
        rst => reset,
        outclk_0 => clock_div,
        locked => open
    );

    

end archPolilegv8 ; -- archPolilegv8
