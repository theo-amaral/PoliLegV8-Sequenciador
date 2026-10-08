library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity mux32x64 is
    port(
        sel : in std_logic_vector(4 downto 0);
        d   : in std_logic_vector(2047 downto 0);
        q   : out std_logic_vector(63 downto 0)
    );
end entity mux32x64;

architecture archMux32x64 of mux32x64 is
begin
    q <= d(64*to_integer(unsigned(sel)) + 63 downto 64*to_integer(unsigned(sel)));
end archMux32x64 ; -- archMux32x64

library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity decoder5x32 is
    port(
        input_decoder: in std_logic_vector(4 downto 0);
        output_decoder : out std_logic_vector(31 downto 0)
    );
end entity decoder5x32;

architecture archDecoder of decoder5x32 is
    begin
        output_decoder <= "00000000000000000000000000000001" when input_decoder = "00000" else
                  "00000000000000000000000000000010" when input_decoder = "00001" else
                  "00000000000000000000000000000100" when input_decoder = "00010" else
                  "00000000000000000000000000001000" when input_decoder = "00011" else
                  "00000000000000000000000000010000" when input_decoder = "00100" else
                  "00000000000000000000000000100000" when input_decoder = "00101" else
                  "00000000000000000000000001000000" when input_decoder = "00110" else
                  "00000000000000000000000010000000" when input_decoder = "00111" else
                  "00000000000000000000000100000000" when input_decoder = "01000" else
                  "00000000000000000000001000000000" when input_decoder = "01001" else
                  "00000000000000000000010000000000" when input_decoder = "01010" else
                  "00000000000000000000100000000000" when input_decoder = "01011" else
                  "00000000000000000001000000000000" when input_decoder = "01100" else
                  "00000000000000000010000000000000" when input_decoder = "01101" else
                  "00000000000000000100000000000000" when input_decoder = "01110" else
                  "00000000000000001000000000000000" when input_decoder = "01111" else
                  "00000000000000010000000000000000" when input_decoder = "10000" else
                  "00000000000000100000000000000000" when input_decoder = "10001" else
                  "00000000000001000000000000000000" when input_decoder = "10010" else
                  "00000000000010000000000000000000" when input_decoder = "10011" else
                  "00000000000100000000000000000000" when input_decoder = "10100" else
                  "00000000001000000000000000000000" when input_decoder = "10101" else
                  "00000000010000000000000000000000" when input_decoder = "10110" else
                  "00000000100000000000000000000000" when input_decoder = "10111" else
                  "00000001000000000000000000000000" when input_decoder = "11000" else
                  "00000010000000000000000000000000" when input_decoder = "11001" else
                  "00000100000000000000000000000000" when input_decoder = "11010" else
                  "00001000000000000000000000000000" when input_decoder = "11011" else
                  "00010000000000000000000000000000" when input_decoder = "11100" else
                  "00100000000000000000000000000000" when input_decoder = "11101" else
                  "01000000000000000000000000000000" when input_decoder = "11110" else
                  "10000000000000000000000000000000" when input_decoder = "11111" else
                  "00000000000000000000000000000000";

    end archDecoder ; -- archDecoder

library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity regfile is
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
end entity regfile;

architecture archRegFile of regfile is

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

    component mux32x64 is
    port(
        sel : in std_logic_vector(4 downto 0);
        d   : in std_logic_vector(2047 downto 0);
        q   : out std_logic_vector(63 downto 0)
    );
    end component;

    component decoder5x32 is
    port(
        input_decoder: in std_logic_vector(4 downto 0);
        output_decoder : out std_logic_vector(31 downto 0)
    );
    end component;

    signal regOuts: std_logic_vector(2047 downto 0);
    signal decoded: std_logic_vector(31 downto 0);
    signal decodedMasked: std_logic_vector(31 downto 0);
    
begin
    muxrr1: mux32x64 port map (rr1, regOuts, q1);
    muxrr2: mux32x64 port map (rr2, regOuts, q2);
    decoder: decoder5x32 port map (wr, decoded);

    decodedMasked <= decoded when regWrite = '1' else 
                    "00000000000000000000000000000000";

    registers: for i in 30 downto 0 generate
        regs: reg port map (clock, reset, decodedMasked(i), d, regOuts(i*64 + 63 downto i*64));
    end generate;

    regOuts(2047 downto 1984) <= (others => '0');

end archRegFile ; -- archRegFile
