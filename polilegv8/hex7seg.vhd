-------------------------------------------------------------------------------
-- Arquivo   : hex7seg.vhd
-------------------------------------------------------------------------------
-- Descricao : Conversor de hexadecimal para 7 segmentos        
-------------------------------------------------------------------------------
-- Revisoes  :
--     Data        Versao  Autor                               Descricao
--     20/02/2026  1.0     Edson Midorikawa e Felipe Valencia  versao inicial
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity hex7seg is
	port (  
			hex      : in  std_logic_vector(3 downto 0);
         display  : out std_logic_vector(6 downto 0)
	);
end hex7seg;

architecture arch of hex7seg is
begin
   --
   --       0  
   --      ---  
   --     |   |
   --    5|   |1
   --     | 6 |
   --      ---  
   --     |   |
   --    4|   |2
   --     |   |
   --      ---  
   --       3  
   --
  display <= "1000000" when hex = "0000" else -- 0
				 "1111001" when hex = "0001" else -- 1
				 "0100100" when hex = "0010" else -- 2
			 	 "0110000" when hex = "0011" else -- 3
				 "0011001" when hex = "0100" else -- 4
				 "0010010" when hex = "0101" else -- 5
				 "0000010" when hex = "0110" else -- 6
				 "1111000" when hex = "0111" else -- 7
				 "0000000" when hex = "1000" else -- 8
				 "0010000" when hex = "1001" else -- 9
				 "0001000" when hex = "1010" else -- A
				 "0000011" when hex = "1011" else -- B
				 "1000110" when hex = "1100" else -- C
				 "0100001" when hex = "1101" else -- D
				 "0000110" when hex = "1110" else -- E
				 "0001110" when hex = "1111" else -- F
				 "1111111";
end architecture;