library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity fulladder is
  port (
    a, b, facin: in std_logic;
    s, cout: out std_logic
  );
 end entity;
-------------------------------------------------------
architecture structural of fulladder is
  signal axorb: std_logic;
begin
  axorb <= a xor b;
  s <= axorb xor facin;
  cout <= (axorb and facin) or (a and b);
end architecture;


library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity ula1bit is
    port(
        a, b, cin, ainvert, binvert : in std_logic;
        operation : in std_logic_vector(3 downto 0);
        result, cout, overflow : out std_logic
    );
end entity;

architecture ulaArch of ula1bit is

    component fulladder is
    port (
        a, b, facin: in std_logic;
        s, cout: out std_logic
    );
    end component;


    signal trueA : std_logic;
    signal trueB : std_logic;
    signal soma : std_logic;
    signal facout : std_logic;

begin
    fa: fulladder
    port map (
        a => trueA,
        b => trueB,
        facin => cin,
        s => soma,
        cout => facout
    );
    trueA <= a xor ainvert;
    trueB <= b xor binvert;
    result <= trueA and trueB when operation = "0000" else
              trueA or trueB when operation = "0001" else
              soma when operation = "0010" else
              b when operation = "0011" else
              a xor b when operation = "0100" else
              trueB;
    overflow <= (((not trueA) and (not trueB)) and soma) or ((trueA and trueB) and not soma);
    cout <= facout;


end ulaArch ; -- ulaArch
