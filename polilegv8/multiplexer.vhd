library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity mux_n is
    generic(dataSize : natural := 64);
    port(
        in0: in std_logic_vector (dataSize-1 downto 0);
        in1: in std_logic_vector (dataSize-1 downto 0);
        sel: in std_logic;
        dOut: out std_logic_vector(dataSize-1 downto 0)
    );
end entity;

architecture archMux of mux_n is
begin
    with sel select dOut <=
        in0 when '0',
        in1 when '1';
end archMux ; -- archMux
