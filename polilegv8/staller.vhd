library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity staller is
    port (
        clock : in std_logic;
        reset : in std_logic;
        memToReg : in std_logic;
        stall : out std_logic
    );
end entity staller;

architecture rtl of staller is
    
    type ESTADOS is (RODANDO, STALL_1, STALL_2, SOLTA_PC);

    signal estado_atual, proximo_estado : ESTADOS;

begin
    
process(clock, reset) begin
    if (reset = '1') then
        estado_atual <= RODANDO;
    elsif (rising_edge(clock)) then
        estado_atual <= proximo_estado;
    end if;
end process;

process(estado_atual, memToReg) begin
    case(estado_atual) is
        when RODANDO =>
            if (memToReg = '1') then
                proximo_estado <= STALL_1;
                stall <= '1';
            else
                proximo_estado <= RODANDO;
                stall <= '0';
            end if;
        when STALL_1 =>
            proximo_estado <= STALL_2;

            stall <= '1';

        when STALL_2 =>
            proximo_estado <= SOLTA_PC;

            stall <= '1';

        when SOLTA_PC =>
            proximo_estado <= RODANDO;
            stall <= '0';
    end case;
end process;
    
end architecture rtl;
