library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity controladorSD is
    port (
        clock : in std_logic;
        reset : in std_logic;
        request : in std_logic;
        block_addr : in std_logic_vector(31 downto 0);
        miso : in std_logic;
        ready : out std_logic;
        busy : out std_logic;
        bram_wr_en : out std_logic;
        bram_wr_addr : out std_logic_vector(6 downto 0);
        bram_wr_data : out std_logic_vector(63 downto 0);
        mosi, sck, cs : out std_logic;
        clear_request : out std_logic;
        db_estado : out std_logic_vector(7 downto 0)
    );
end entity controladorSD;

architecture rtl of controladorSD is
    
    component moduloSPI is
        generic (
            clock_div : natural := 125
        );
        port (
            clock : in std_logic;
            start : in std_logic;
            data_to_send : in std_logic_vector(7 downto 0);
            miso : in std_logic;
            sck, mosi, cs : out std_logic;
            data_received : out std_logic_vector(7 downto 0);
            done : out std_logic
        );
    end component;

    component contador is
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
    end component;

    type estado_t is (LIGA, MANDA_CMD0, ESPERA_CMD0, MANDA_CMD8, ESPERA_CMD8, MANDA_CMD55, ESPERA_CMD55, MANDA_ACMD41, ESPERA_ACMD41, PRONTO, MANDA_CMD17, ESPERA_CMD17, ESPERA_TOKEN, LE_DADOS, PULA_CRC, LIDO);
    type comando_t is array(0 to 5) of std_logic_vector(7 downto 0);


    signal estado_atual, proximo_estado : estado_t := LIGA;
    signal start, done, clear_cont_liga, rco_cont_liga, enable_cont_liga, cs_unmasked, clear_cont_comando, rco_cont_comando, enable_cont_comando, clear_cont_dados, enable_cont_dados, rco_cont_dados, clear_cont_cmd8, enable_cont_cmd8, rco_cont_cmd8, clear_cont_addr, enable_cont_addr, rco_cont_addr, wr_en_int : std_logic := '0';
    signal data_to_send, data_received, data_received_int : std_logic_vector(7 downto 0);
    signal Q_cont_comando, Q_cont_dados, Q_cont_addr : std_logic_vector(14 downto 0);
    signal watchdog : natural range 0 to 50_000_000;
    signal cont_crc : natural range 0 to 2;
    signal buffer_dado : std_logic_vector(63 downto 0) := (others => '0');

begin
    
    moduloSPI_inst: moduloSPI
     generic map(
        clock_div => 125
    )
     port map(
        clock => clock,
        start => start,
        data_to_send => data_to_send,
        miso => miso,
        sck => sck,
        mosi => mosi,
        cs => cs_unmasked,
        data_received => data_received,
        done => done
    );

    
    contador_liga : contador
     generic map(
        MODULO => 80
    )
     port map(
        clock => clock,
        clear => clear_cont_liga,
        enable => enable_cont_liga,
        Q => open,
        RCO => rco_cont_liga
    );
    
    contador_comando: contador
     generic map(
        MODULO => 6
    )
     port map(
        clock => clock,
        clear => clear_cont_comando,
        enable => enable_cont_comando,
        Q => Q_cont_comando,
        RCO => rco_cont_comando
    );

    contador_dados: contador
     generic map(
        MODULO => 8
    )
     port map(
        clock => clock,
        clear => clear_cont_dados,
        enable => enable_cont_dados,
        Q => Q_cont_dados,
        RCO => rco_cont_dados
    );

    contador_inst: contador
     generic map(
        MODULO => 64
    )
     port map(
        clock => clock,
        clear => clear_cont_addr,
        enable => enable_cont_addr,
        Q => Q_cont_addr,
        RCO => rco_cont_addr
    );

    contador_cmd8: contador
     generic map(
        MODULO => 5
    )
     port map(
        clock => clock,
        clear => clear_cont_cmd8,
        enable => enable_cont_cmd8,
        Q => open,
        RCO => rco_cont_cmd8
    );

    process(clock, reset) begin
        if reset = '1' then
            estado_atual <= LIGA;
        elsif rising_edge(clock) then
            estado_atual <= proximo_estado;
            wr_en_int <= '0';
            if estado_atual = ESPERA_CMD8 and unsigned(Q_cont_comando) = 0 and done = '1' then
                data_received_int <= data_received;
            elsif estado_atual = MANDA_CMD55 then
                data_received_int <= "00000000";
            elsif estado_atual = LE_DADOS and done = '1' then
                case Q_cont_dados(2 downto 0) is
                    when "000" => buffer_dado(7 downto 0)  <= data_received;
                    when "001" => buffer_dado(15 downto 8)  <= data_received;
                    when "010" => buffer_dado(23 downto 16) <= data_received;
                    when "011" => buffer_dado(31 downto 24) <= data_received;
                    when "100" => buffer_dado(39 downto 32) <= data_received;
                    when "101" => buffer_dado(47 downto 40) <= data_received;
                    when "110" => buffer_dado(55 downto 48) <= data_received;
                    when "111" => buffer_dado(63 downto 56) <= data_received;
                                  wr_en_int <= '1';
                    when others => null;
                end case;
            elsif estado_atual = PULA_CRC and done = '1' then
                cont_crc <= cont_crc + 1;
            elsif estado_atual = LIDO then
                cont_crc <= 0;
            end if;
            if(estado_atual = proximo_estado) then
                watchdog <= watchdog + 1;
            else
                watchdog <= 0;
            end if;
        end if;
    end process;

    process(estado_atual, done, rco_cont_liga, watchdog, rco_cont_comando, rco_cont_dados, cs_unmasked, data_received, Q_cont_comando, data_received_int, request, block_addr, buffer_dado, cont_crc, Q_cont_dados)
        variable cmd : comando_t;
    begin
        case estado_atual is
            when LIGA =>
                if rco_cont_liga = '1' then
                    proximo_estado <= MANDA_CMD0;
                else
                    proximo_estado <= LIGA;
                end if;

                cs <= '1';
                start <= '1';
                data_to_send <= x"FF";
                clear_cont_liga <= '0';
                enable_cont_liga <= done;
                clear_cont_comando <= '1';
                enable_cont_comando <='0';
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                clear_cont_addr <= '1';
                enable_cont_addr <= '0';
                ready <= '0';
                busy <= '1';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '0';

                db_estado <= x"00";

            when MANDA_CMD0 =>
                if rco_cont_comando = '1' and done = '1' then
                    proximo_estado <= ESPERA_CMD0;
                else
                    proximo_estado <= MANDA_CMD0;
                end if;


                cmd(0) := x"40";
                cmd(1) := x"00";
                cmd(2) := x"00";
                cmd(3) := x"00";
                cmd(4) := x"00";
                cmd(5) := x"95";

                cs <= cs_unmasked;
                start <= '1';
                data_to_send <= cmd(to_integer(unsigned(Q_cont_comando)));
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '0';
                enable_cont_comando <= done;
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                clear_cont_addr <= '1';
                enable_cont_addr <= '0';
                ready <= '0';
                busy <= '1';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '0';

                db_estado <= x"01";

            when ESPERA_CMD0 =>
                if data_received = x"01" and done = '1' then
                    proximo_estado <= MANDA_CMD8;
                elsif watchdog >= 50_000_000 then
                    proximo_estado <= LIGA;
                else
                    proximo_estado <= ESPERA_CMD0;
                end if;

                cs <= cs_unmasked;
                start <= '1';
                data_to_send <= x"FF";
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '1';
                enable_cont_comando <= '0';
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                clear_cont_addr <= '1';
                enable_cont_addr <= '0';
                ready <= '0';
                busy <= '1';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '0';
                
                db_estado <= x"02";

            when MANDA_CMD8 =>
                if rco_cont_comando = '1' and done = '1' then
                    proximo_estado <= ESPERA_CMD8;
                else
                    proximo_estado <= MANDA_CMD8;
                end if;


                cmd(0) := x"48";
                cmd(1) := x"00";
                cmd(2) := x"00";
                cmd(3) := x"01";
                cmd(4) := x"AA";
                cmd(5) := x"87";

                cs <= cs_unmasked;
                start <= '1';
                data_to_send <= cmd(to_integer(unsigned(Q_cont_comando)));
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '0';
                enable_cont_comando <= done;
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                clear_cont_addr <= '1';
                enable_cont_addr <= '0';
                ready <= '0';
                busy <= '1';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '0';

                db_estado <= x"03";

            when ESPERA_CMD8 =>
                if data_received_int = x"01" and done = '1' and rco_cont_cmd8 = '1' then
                    proximo_estado <= MANDA_CMD55;
                elsif watchdog >= 50_000_000 then
                    proximo_estado <= LIGA;
                else
                    proximo_estado <= ESPERA_CMD8;
                end if;

                cs <= cs_unmasked;
                start <= '1';
                data_to_send <= x"FF";
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '1';
                enable_cont_comando <= '0';
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '0';
                enable_cont_cmd8 <= done;
                clear_cont_addr <= '1';
                enable_cont_addr <= '0';
                ready <= '0';
                busy <= '1';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '0';

                db_estado <= x"04";

            when MANDA_CMD55 =>
                if rco_cont_comando = '1' and done = '1' then
                    proximo_estado <= ESPERA_CMD55;
                else
                    proximo_estado <= MANDA_CMD55;
                end if;


                cmd(0) := x"77";
                cmd(1) := x"00";
                cmd(2) := x"00";
                cmd(3) := x"00";
                cmd(4) := x"00";
                cmd(5) := x"01";

                cs <= cs_unmasked;
                start <= '1';
                data_to_send <= cmd(to_integer(unsigned(Q_cont_comando)));
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '0';
                enable_cont_comando <= done;
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                clear_cont_addr <= '1';
                enable_cont_addr <= '0';
                ready <= '0';
                busy <= '1';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '0';

                db_estado <= x"05";

            when ESPERA_CMD55 =>
                if data_received = x"01" and done = '1' then
                    proximo_estado <= MANDA_ACMD41;
                elsif watchdog >= 50_000_000 then
                    proximo_estado <= LIGA;
                else
                    proximo_estado <= ESPERA_CMD55;
                end if;

                cs <= cs_unmasked;
                start <= '1';
                data_to_send <= x"FF";
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '1';
                enable_cont_comando <= '0';
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                clear_cont_addr <= '1';
                enable_cont_addr <= '0';
                ready <= '0';
                busy <= '1';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '0';

                db_estado <= x"06";

            when MANDA_ACMD41 =>
                if rco_cont_comando = '1' and done = '1' then
                    proximo_estado <= ESPERA_ACMD41;
                else
                    proximo_estado <= MANDA_ACMD41;
                end if;


                cmd(0) := x"69";
                cmd(1) := x"40";
                cmd(2) := x"00";
                cmd(3) := x"00";
                cmd(4) := x"00";
                cmd(5) := x"01";

                cs <= cs_unmasked;
                start <= '1';
                data_to_send <= cmd(to_integer(unsigned(Q_cont_comando)));
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '0';
                enable_cont_comando <= done;
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                clear_cont_addr <= '1';
                enable_cont_addr <= '0';
                ready <= '0';
                busy <= '1';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '0';

                db_estado <= x"07";

            when ESPERA_ACMD41 =>
                if data_received = x"00" and done = '1' then
                    proximo_estado <= PRONTO;
                elsif data_received = x"01" and done = '1' then
                    proximo_estado <= MANDA_CMD55;
                elsif watchdog >= 50_000_000 then
                    proximo_estado <= LIGA;
                else
                    proximo_estado <= ESPERA_ACMD41;
                end if;

                cs <= cs_unmasked;
                start <= '1';
                data_to_send <= x"FF";
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '1';
                enable_cont_comando <= '0';
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                clear_cont_addr <= '1';
                enable_cont_addr <= '0';
                ready <= '0';
                busy <= '1';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '0';

                db_estado <= x"08";

            when PRONTO =>
                if request = '1' then
                    proximo_estado <= MANDA_CMD17;
                else
                    proximo_estado <= PRONTO;
                end if;

                cs <= cs_unmasked;
                start <= '0';
                data_to_send <= x"00";
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '1';
                enable_cont_comando <= '0';
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                clear_cont_addr <= '1';
                enable_cont_addr <= '0';
                ready <= '1';
                busy <= '0';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '0';

                db_estado <= x"09";

            when MANDA_CMD17 =>
                if rco_cont_comando = '1' and done = '1' then
                    proximo_estado <= ESPERA_CMD17;
                else
                    proximo_estado <= MANDA_CMD17;
                end if;


                cmd(0) := x"51";
                cmd(1) := block_addr(31 downto 24);
                cmd(2) := block_addr(23 downto 16);
                cmd(3) := block_addr(15 downto 8);
                cmd(4) := block_addr(7 downto 0);
                cmd(5) := x"01";

                cs <= cs_unmasked;
                start <= '1';
                data_to_send <= cmd(to_integer(unsigned(Q_cont_comando)));
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '0';
                enable_cont_comando <= done;
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                clear_cont_addr <= '1';
                enable_cont_addr <= '0';
                ready <= '0';
                busy <= '1';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '0';

                db_estado <= x"0A";

            when ESPERA_CMD17 =>
                if data_received = x"00" and done = '1' then
                    proximo_estado <= ESPERA_TOKEN;
                else
                    proximo_estado <= ESPERA_CMD17;
                end if;

                cs <= cs_unmasked;
                start <= '1';
                data_to_send <= x"FF";
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '1';
                enable_cont_comando <= '0';
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                clear_cont_addr <= '1';
                enable_cont_addr <= '0';
                ready <= '0';
                busy <= '1';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '0';

                db_estado <= x"0B";

            when ESPERA_TOKEN =>
                if data_received = x"FE" and done = '1' then
                    proximo_estado <= LE_DADOS; else
                    proximo_estado <= ESPERA_TOKEN;
                end if;

                cs <= cs_unmasked;
                start <= '1';
                data_to_send <= x"FF";
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '1';
                enable_cont_comando <= '0';
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                clear_cont_addr <= '1';
                enable_cont_addr <= '0';
                ready <= '0';
                busy <= '1';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '0';

                db_estado <= x"0C";

            when LE_DADOS =>
                if rco_cont_addr = '1' and wr_en_int = '1' then
                    proximo_estado <= PULA_CRC;
                else
                    proximo_estado <= LE_DADOS;
                end if;


                cs <= cs_unmasked;
                start <= '1';
                data_to_send <= x"FF";
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '1';
                enable_cont_comando <= '0';
                clear_cont_dados <= '0';
                enable_cont_dados <= done;
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                clear_cont_addr <= '0';
                enable_cont_addr <= wr_en_int;
                ready <= '0';
                busy <= '1';
                bram_wr_data <= buffer_dado;
                bram_wr_addr <= '1' & Q_cont_addr(5 downto 0);
                bram_wr_en <= wr_en_int;
                clear_request <= '0';

                db_estado <= x"0D";


            when PULA_CRC =>
                if cont_crc = 2 then
                    proximo_estado <= LIDO;
                else
                    proximo_estado <= PULA_CRC;
                end if;

                cs <= cs_unmasked;
                start <= '1';
                data_to_send <= x"FF";
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '1';
                enable_cont_comando <= '0';
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                ready <= '0';
                busy <= '1';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '0';

                db_estado <= x"0E";


            when LIDO =>
                proximo_estado <= PRONTO;

                cs <= cs_unmasked;
                start <= '0';
                data_to_send <= x"FF";
                clear_cont_liga <= '1';
                enable_cont_liga <= '0';
                clear_cont_comando <= '1';
                enable_cont_comando <= '0';
                clear_cont_dados <= '1';
                enable_cont_dados <= '0';
                clear_cont_cmd8 <= '1';
                enable_cont_cmd8 <= '0';
                ready <= '1';
                busy <= '0';
                bram_wr_data <= (others => '0');
                bram_wr_addr <= (others => '0');
                bram_wr_en <= '0';
                clear_request <= '1';
                
                db_estado <= x"0F";


        end case;
    end process;
end architecture rtl;
