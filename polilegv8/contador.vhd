library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity contador is
    generic (
        MODULO : integer := 1000
    );
    port (
        clock   : in  std_logic;
        clear   : in  std_logic;
        enable  : in  std_logic;
        Q       : out std_logic_vector(14 downto 0);
        RCO     : out std_logic
    );
end contador;

architecture arch of contador is
    signal IQ: integer range 0 to MODULO-1;
begin

    process (clock, clear, enable)
    begin
        if clear = '1' then         -- clear assincrono
            IQ <= 0;
            
        elsif clock'event and clock='1' then
            if enable = '1' then
                if (IQ = MODULO-1) then
                    IQ <= 0;
                else
                    IQ <= IQ + 1;
                end if;
            end if;
        end if;
    end process;	
  
    RCO <= '1' when IQ = MODULO-1 else '0';
    Q   <= std_logic_vector(to_unsigned(IQ, Q'length));  -- saida Q
end architecture;
