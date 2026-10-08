library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;


entity shifter is 
port(
    A : in std_logic_vector(63 downto 0);
    shamt : in std_logic_vector(5 downto 0);
    shift_right_en : in std_logic;
    result_shift : out std_logic_vector(63 downto 0)
);
end entity;

architecture rtl of shifter is

begin

    result_shift <= std_logic_vector(shift_left(unsigned(A), to_integer(unsigned(shamt)))) when shift_right_en = '0' else
                    std_logic_vector(shift_right(unsigned(A), to_integer(unsigned(shamt))));

end architecture;

library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity nor64bits is
    port (
        A : in std_logic_vector (63 downto 0);
        Q : out std_logic
    );
end entity;

architecture archOr of nor64bits is

begin
    process(A) 
        variable result : std_logic;
    begin
        for i in 0 to 63 loop
            if i = 0 then
                result := A(i);
            else
                result := result or A(i);
            end if;
        end loop;
    Q <= not result;
    end process;
end archOr ; -- archOr

library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity ula is
    port (
        A : in std_logic_vector(63 downto 0);
        B : in std_logic_vector(63 downto 0);
        shamt : in std_logic_vector(5 downto 0);
        S : in std_logic_vector(5 downto 0);
        F : out std_logic_vector(63 downto 0);
        Z : out std_logic;
        Ov : out std_logic;
        Co : out std_logic
    );
end entity;

architecture archUla of ula is

    component shifter is
    port(
        A : in std_logic_vector(63 downto 0);
        shamt : in std_logic_vector(5 downto 0);
        shift_right_en : in std_logic;
        result_shift : out std_logic_vector(63 downto 0)
    );
    end component;

    component ula1bit is
    port (
        a, b, cin, ainvert, binvert : in std_logic;
        operation : in std_logic_vector(3 downto 0);
        result, cout, overflow : out std_logic
    );
    end component;

    component nor64bits is
    port (
        A : in std_logic_vector (63 downto 0);
        Q : out std_logic
    );
    end component;

    signal Couts : std_logic_vector(62 downto 0);
    signal results, result_shift : std_logic_vector (63 downto 0);

begin
    shifter_inst: shifter
     port map(
        A => A,
        shamt => shamt,
        shift_right_en => S(4),
        result_shift => result_shift
    );
    nor64: nor64bits port map(results, Z); 
    ulas: for i in 0 to 63 generate
        ula63: if i = 63 generate
            ulaOv: ula1bit port map (A(i), B(i), Couts(i-1), S(5), S(4), S(3 downto 0), results(i), Co, Ov);
        end generate;
        ula0: if i = 0 generate
            ulaIni: ula1bit port map(A(i), B(i), S(4), S(5), S(4), S(3 downto 0), results(i), Couts(i), open);
        end generate;
        ulaGenericas: if i /= 0 and i /= 63 generate
            ulaGen: ula1bit port map(A(i), B(i), Couts(i-1), S(5), S(4), S(3 downto 0), results(i), Couts(i), open);
        end generate;
    end generate ulas;

    F <= results when S(5) = '0' else
         result_shift;

end archUla ; -- archUla
