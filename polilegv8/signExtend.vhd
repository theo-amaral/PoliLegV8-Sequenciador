library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity sign_extend is
    generic (
        dataISize       : natural := 32;
        dataOSize       : natural := 64;
        dataMaxPosition : natural := 5
    );
    port (
        inData      : in  std_logic_vector(dataISize-1 downto 0);
        inDataStart : in  std_logic_vector(dataMaxPosition-1 downto 0);
        inDataEnd   : in  std_logic_vector(dataMaxPosition-1 downto 0);
        outData     : out std_logic_vector(dataOSize-1 downto 0)
    );
end entity;

architecture archSignExtend of sign_extend is
begin
    process(inData, inDataStart, inDataEnd)
    begin
        case inDataStart is
            when "10100" =>
                outData <= (dataOSize-1 downto 9 => inData(20)) & inData(20 downto 12);
            when "10111" =>
                outData <= (dataOSize-1 downto 19 => inData(23)) & inData(23 downto 5);
            when "11001" =>
                outData <= (dataOSize-1 downto 26 => inData(25)) & inData(25 downto 0);
            when others =>
                outData <= (others => '0');
        end case;
    end process;
end architecture;
