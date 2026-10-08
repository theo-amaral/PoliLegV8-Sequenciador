library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity two_left_shifts is
    generic(
        dataSize : natural := 64
    );
    port(
        input : in std_logic_vector(dataSize-1 downto 0);
        output : out std_logic_vector(dataSize-1 downto 0)
    );
end entity;

architecture archShifter of two_left_shifts is
begin
    output <= input(dataSize-3 downto 0) & "00";

end archShifter ; -- archShifter
