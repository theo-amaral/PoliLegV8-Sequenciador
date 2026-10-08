library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity shiftregister is
    port (
        clock : in std_logic;
        enable : in std_logic;
        parallel_in : in std_logic_vector(7 downto 0);
        serial : in std_logic;
        load : in std_logic;
        parallel_out : out std_logic_vector(7 downto 0)
    );
end entity shiftregister;

architecture rtl of shiftregister is

    signal int : std_logic_vector(7 downto 0);

begin
    process(clock, enable) begin
        if rising_edge(clock) then
            if load = '1' then
                int <= parallel_in;
            elsif enable = '1' then
                int <= int(6 downto 0) & serial;
            end if;
        end if;
    end process;

    parallel_out <= int;
end architecture;

library ieee;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity modulospi is
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
end entity modulospi;

architecture rtl of modulospi is
    
    component contador is
        generic (
            modulo : integer := 1000
        );
        port (
            clock   : in  std_logic;
            clear   : in  std_logic;
            enable  : in  std_logic;
            q       : out std_logic_vector(14 downto 0);
            rco     : out std_logic
        );
    end component;

    component shiftregister is
        port (
            clock : in std_logic;
            enable : in std_logic;
            parallel_in : in std_logic_vector(7 downto 0);
            serial : in std_logic;
            load : in std_logic;
            parallel_out : out std_logic_vector(7 downto 0)
        );
    end component;

    type estado_t is (aguarda, transfere, concluido);

    signal rco_clock_div, clock_div_real, enable_cont_8bits, rco_cont_8bits, load_shiftregister, enable_shiftregister : std_logic := '0';
    signal parallel_out : std_logic_vector(7 downto 0);
    signal estado_atual, proximo_estado : estado_t := aguarda;
    signal done_interno : std_logic;
    signal done_sync    : std_logic;
begin
    
    contador_clock_div: contador
     generic map(
        modulo => clock_div
    )
     port map(
        clock => clock,
        clear => '0',
        enable => '1',
        q => open,
        rco => rco_clock_div
    );
    
    contador_8bits: contador
     generic map(
        modulo => 8
    )
     port map(
        clock => clock_div_real,
        clear => '0',
        enable => enable_cont_8bits,
        q => open,
        rco => rco_cont_8bits
    );

    shiftregister_dados: shiftregister
     port map(
        clock => clock_div_real,
        enable => enable_shiftregister,
        parallel_in => data_to_send,
        serial => miso,
        load => load_shiftregister,
        parallel_out => parallel_out
    );
    process(clock)
    begin
        if rising_edge(clock) then
            done_sync <= done_interno;
            if done_interno = '1' and done_sync = '0' then
                done <= '1';
            else
                done <= '0';
            end if;
        end if;
    end process;
    process (rco_clock_div) begin
        if rising_edge(rco_clock_div) then
            clock_div_real <= not clock_div_real;
        end if;
    end process;

    process (clock_div_real) begin
        if falling_edge(clock_div_real) then
            estado_atual <= proximo_estado;
        end if;
    end process;

    process (start, rco_cont_8bits, estado_atual) begin
        case estado_atual is
            when aguarda =>
                if start = '1' then
                    proximo_estado <= transfere;
                else
                    proximo_estado <= aguarda;
                end if;

                enable_cont_8bits <= '0';
                load_shiftregister <= '1';
                enable_shiftregister <= '0';
                cs <= '1';
                done_interno <= '0';
            when transfere =>
                if rco_cont_8bits = '1' then
                    proximo_estado <= concluido;
                else
                    proximo_estado <= transfere;
                end if;

                enable_cont_8bits <= '1';
                load_shiftregister <= '0';
                enable_shiftregister <= '1';
                cs <= '0';
                done_interno <= '0';
            when concluido =>
                proximo_estado <= aguarda;

                enable_cont_8bits <= '0';
                load_shiftregister <= '0';
                enable_shiftregister <= '0';
                cs <= '1';
                done_interno <= '1';
        end case;
    end process;

    sck <= not clock_div_real;
    mosi <= parallel_out(7);
    data_received <= parallel_out;
end architecture rtl;
