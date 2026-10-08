library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;


entity memoriaDados is
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

end entity memoriaDados;

architecture archMemoriaDados of memoriaDados is
    type mem_t is array(0 to (2 ** addressSize)-1) of std_logic_vector(dataSize-1 downto 0);

    shared variable mem : mem_t;

    attribute ram_init_file : string;
    attribute ram_init_file of mem : variable is "dados.mif";

begin
    process(clock)
    begin
        if rising_edge(clock) then
            if wr = '1' then
                mem(to_integer(unsigned(addr))) := data_in;
            end if;
            data_out <= mem(to_integer(unsigned(addr)));
        end if;
    end process;

end archMemoriaDados ; -- archMemoriaDados
