library ieee;
use IEEE.numeric_std.all;
use ieee.std_logic_1164.all;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    constant c_clock_hz : real := 100_000_000.0;
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_uart_tx : std_logic;
    signal s_genen : std_logic;
    signal s_signals_in : std_logic_vector(15 downto 0);
    signal s_signals_out : std_logic_vector(15 downto 0);
begin

    reset_proc: process
    begin
        s_reset <= '1';
        wait until falling_edge(s_clock);
        wait until rising_edge(s_clock);
        wait until falling_edge(s_clock);
        s_reset <= '0';
        wait;
    end process;

    stim_proc: process
    begin
        s_clock <= not s_clock;
        wait for 1 sec / (c_clock_hz * 2.0);
    end process;


    tx : entity work.ReflectorTx
    generic map
    (
        p_clken_hz => integer(c_clock_hz),
        p_baud => 115_200,
        p_bit_width => 4 
    )
    port map
    ( 
        i_clock => s_clock,
        i_clken => '1',
        i_reset => s_reset,
        o_uart_tx => s_uart_tx,
        i_signals => s_signals_in(3 downto 0)
    );

    rx : entity work.ReflectorRx
    generic map
    (
        p_clock_hz => integer(c_clock_hz),
        p_baud => 115_200,
        p_bit_width => 4
    )
    port map
    ( 
        i_clock => s_clock,
        i_reset => s_reset,
        i_uart_rx => s_uart_tx,
        o_signals => s_signals_out(3 downto 0)
    );


    div : entity work.ClockDivider
    generic map
    (
        p_period => 120_000
    )
    port map
    ( 
        i_clock => s_clock,
        i_clken => '1',
        i_reset => s_reset,
        o_clken => s_genen
    );    

    gen : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_signals_in <= (others => '0');
            elsif s_genen = '1' then
                s_signals_in <= std_logic_vector(unsigned(s_signals_in) + 1);
            end if;
        end if;
    end process;
        
end;