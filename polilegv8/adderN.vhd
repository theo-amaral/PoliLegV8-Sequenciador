library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity adder_n is
    generic(dataSize : natural := 64);
    port(
        in0 : in std_logic_vector(dataSize-1 downto 0);
        in1 : in std_logic_vector(dataSize-1 downto 0);
        sum : out std_logic_vector(dataSize-1 downto 0);
        cOut : out std_logic
    );
end entity adder_n;

architecture adderArch of adder_n is
begin
    process(in0, in1)
        variable cInternal : std_logic := '0';
        variable sumVar : std_logic_vector(dataSize-1 downto 0);
    begin
        cInternal := '0';
        for i in 0 to dataSize-1 loop
            sumVar(i) := in0(i) xor in1(i) xor cInternal;
            cInternal := ((in0(i) xor in1(i)) and cInternal) or (in0(i) and in1(i));
        end loop;
        sum <= sumVar;
        cOut <= cInternal;
    end process;
end adderArch;
