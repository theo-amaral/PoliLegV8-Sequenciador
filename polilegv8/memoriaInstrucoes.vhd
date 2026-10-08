library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
library altera_mf;
use altera_mf.altera_mf_components.all;

entity memoriaInstrucoes is
    generic (
        addressSize : natural := 5;
        dataSize    : natural := 32
    );
    port (
        clock : in std_logic;
        addr : in  std_logic_vector(addressSize-1 downto 0);
        data : out std_logic_vector(dataSize-1 downto 0)
    );
end entity memoriaInstrucoes;

architecture archMemoria of memoriaInstrucoes is
begin
    rom : altsyncram
    generic map (
        operation_mode        => "ROM",
        width_a               => dataSize,
        widthad_a             => addressSize,
        numwords_a            => 2**addressSize,
        outdata_reg_a         => "UNREGISTERED",
        init_file             => "instrucoes.mif",
        intended_device_family => "Cyclone V"
    )
    port map (
        clock0 => clock,
        address_a => addr,
        q_a       => data
    );
end archMemoria;
