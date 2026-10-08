library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity unidadeControle is
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
end entity unidadeControle;

architecture archUC of unidadeControle is

    type estado_t is (ADD, SUB, ANDD, ORR, XORR, LSL, LSR, LDUR, STUR, CBZ, B, BR, BL, INV); 
    signal instrucao : estado_t;
begin
instrucao <= ADD  when opcode = "10001011000" else
             SUB  when opcode = "11001011000" else
             ANDD when opcode = "10001010000" else
             ORR  when opcode = "10101010000" else
             XORR when opcode = "10101010100" else
             LSL  when opcode = "11010011011" else
             LSR  when opcode = "11010011010" else
             LDUR when opcode = "11111000010" else
             STUR when opcode = "11111000000" else
             BR   when opcode = "11010110000" else
             CBZ  when opcode(10 downto 3) = "10110100" else
             B    when opcode(10 downto 5) = "000101" else
             BL   when opcode(10 downto 5) = "100101" else
             INV;

    process(opcode, instrucao) begin
        case(instrucao) is
            when ADD =>
                reg2loc      <= '0';
                aluSrc       <= '0';
                memToReg     <= '0';
                regWrite     <= '1';
                memRead      <= '0';
                memWrite     <= '0';
                branch       <= '0';
                uncondBranch <= '0';
                reg2Pc       <= '0';
                pc2reg       <= '0';
                alu_control  <= "000010";
                extendMSB    <= "00000";
                extendlSB    <= "00000";

            when SUB =>
                reg2loc      <= '0';
                aluSrc       <= '0';
                memToReg     <= '0';
                regWrite     <= '1';
                memRead      <= '0';
                memWrite     <= '0';
                branch       <= '0';
                uncondBranch <= '0';
                reg2Pc       <= '0';
                pc2reg       <= '0';
                alu_control  <= "010010";
                extendMSB    <= "00000";
                extendLSB    <= "00000";
                
            when ANDD =>
                reg2loc      <= '0';
                aluSrc       <= '0';
                memToReg     <= '0';
                regWrite     <= '1';
                memRead      <= '0';
                memWrite     <= '0';
                branch       <= '0';
                uncondBranch <= '0';
                reg2Pc      <= '0';
                pc2reg       <= '0';
                alu_control  <= "000000";
                extendMSB    <= "00000";
                extendLSB    <= "00000";

            when ORR =>
                reg2loc      <= '0';
                aluSrc       <= '0';
                memToReg     <= '0';
                regWrite     <= '1';
                memRead      <= '0';
                memWrite     <= '0';
                branch       <= '0';
                uncondBranch <= '0';
                reg2Pc      <= '0';
                pc2reg       <= '0';
                alu_control  <= "000001";
                extendMSB    <= "00000";
                extendLSB    <= "00000";

            when XORR =>
                reg2loc      <= '0';
                aluSrc       <= '0';
                memToReg     <= '0';
                regWrite     <= '1';
                memRead      <= '0';
                memWrite     <= '0';
                branch       <= '0';
                uncondBranch <= '0';
                reg2Pc      <= '0';
                pc2reg       <= '0';
                alu_control  <= "000100";
                extendMSB    <= "00000";
                extendLSB    <= "00000";

            when LSL =>
                reg2loc      <= '0';
                aluSrc       <= '0';
                memToReg     <= '0';
                regWrite     <= '1';
                memRead      <= '0';
                memWrite     <= '0';
                branch       <= '0';
                uncondBranch <= '0';
                reg2Pc      <= '0';
                pc2reg       <= '0';
                alu_control  <= "100000";
                extendMSB    <= "00000";
                extendlSB    <= "00000";

            when LSR =>
                reg2loc      <= '0';
                aluSrc       <= '0';
                memToReg     <= '0';
                regWrite     <= '1';
                memRead      <= '0';
                memWrite     <= '0';
                branch       <= '0';
                uncondBranch <= '0';
                reg2Pc       <= '0';
                pc2reg       <= '0';
                alu_control  <= "110000";
                extendMSB    <= "00000";
                extendlSB    <= "00000";

            when LDUR =>
                reg2loc      <= '0';
                aluSrc       <= '1';
                memToReg     <= '1';
                regWrite     <= '1';
                memRead      <= '1';
                memWrite     <= '0';
                branch       <= '0';
                uncondBranch <= '0';
                reg2Pc       <= '0';
                pc2reg       <= '0';
                alu_control  <= "000010";
                extendMSB    <= "10100";
                extendLSB    <= "01100";

            when STUR =>
                reg2loc      <= '1';
                aluSrc       <= '1';
                memToReg     <= '0';
                regWrite     <= '0';
                memRead      <= '0';
                memWrite     <= '1';
                branch       <= '0';
                uncondBranch <= '0';
                reg2Pc       <= '0';
                pc2reg       <= '0';
                alu_control  <= "000010";
                extendMSB    <= "10100";
                extendLSB    <= "01100";

            when CBZ =>
                reg2loc      <= '1';
                aluSrc       <= '0';
                memToReg     <= '0';
                regWrite     <= '0';
                memRead      <= '0';
                memWrite     <= '0';
                branch       <= '1';
                uncondBranch <= '0';
                reg2Pc       <= '0';
                pc2reg       <= '0';
                alu_control  <= "000011";
                extendMSB    <= "10111";
                extendLSB    <= "00101";

            when B =>
                reg2loc      <= '1';
                aluSrc       <= '0';
                memToReg     <= '0';
                regWrite     <= '0';
                memRead      <= '0';
                memWrite     <= '0';
                branch       <= '0';
                uncondBranch <= '1';
                reg2Pc      <= '0';
                pc2reg       <= '0';
                alu_control  <= "000011";
                extendMSB    <= "11001";
                extendLSB    <= "00000";

            when BR =>
                reg2loc      <= '1';
                aluSrc       <= '0';
                memToReg     <= '0';
                regWrite     <= '0';
                memRead      <= '0';
                memWrite     <= '0';
                branch       <= '0';
                uncondBranch <= '1';
                reg2Pc      <= '1';
                pc2reg       <= '0';
                alu_control  <= "000011";
                extendMSB    <= "11001";
                extendLSB    <= "00000";

            when BL =>
                reg2loc      <= '1';
                aluSrc       <= '0';
                memToReg     <= '0';
                regWrite     <= '1';
                memRead      <= '0';
                memWrite     <= '0';
                branch       <= '0';
                uncondBranch <= '1';
                reg2Pc      <= '0';
                pc2reg       <= '1';
                alu_control  <= "000011";
                extendMSB    <= "11001";
                extendLSB    <= "00000";

            when INV =>
                reg2loc      <= '0';
                aluSrc       <= '0';
                memToReg     <= '0';
                regWrite     <= '0';
                memRead      <= '0';
                memWrite     <= '0';
                branch       <= '0';
                uncondBranch <= '0';
                reg2Pc      <= '0';
                pc2reg       <= '0';
                alu_control  <= "000000";
                extendMSB    <= "00000";
                extendLSB    <= "00000";
        end case;
    end process;


end archUC ; -- archUC
