library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_clken : std_logic;
    signal s_uart_tx : std_logic;
    constant c_clock_hz : real := 100_000_000.0;
    constant c_baud : integer := 100_000;
begin


    reset_proc: process
    begin
        s_reset <= '1';
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

    uart_tx : entity work.UartTxTest
    generic map
    (
        p_clock_hz => integer(c_clock_hz),
        p_bytes_per_chunk => 4,
        p_chunks_per_second => 2000,
        p_baud => c_baud-5000
    )
    port map
    (
        i_clock => s_clock,
        i_reset => s_reset,
        o_uart_tx => s_uart_tx
    );

    uart_rx : entity work.UartRx
    generic map
    (
        p_clock_hz => integer(c_clock_hz),
        p_baud => c_baud,
        p_sync => false,
        p_debounce => false
    )
    port map
    ( 
        i_clock => s_clock,
        i_reset => s_reset,
        i_uart_rx => s_uart_tx,
        o_data => open,
        o_data_available => open,
        o_busy => open,
        o_error => open
    );


end;