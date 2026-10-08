library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity reg is 
    generic(dataSize: natural := 64);
    port(
        clock : in std_logic;
        reset: in std_logic;
        enable: in std_logic;
        d: in std_logic_vector(dataSize-1 downto 0);
        q: out std_logic_vector(dataSize-1 downto 0)
    );
end entity reg;

architecture archReg of reg is

    signal internal: std_logic_vector(dataSize-1 downto 0);

    begin
        q <= internal;
        process(clock, reset, enable) begin
            if (reset = '1') then
                internal <= (others => '0');
            elsif(rising_edge(clock) and enable = '1') then
                internal <= d;
            end if;
        end process;

end archReg; -- archReg
