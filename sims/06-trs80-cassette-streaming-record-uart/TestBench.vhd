library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    constant c_clock_hz : real := 2_400_000.0;
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic := '0';
    signal s_uart_tx : std_logic;
    signal s_record_button : std_logic;
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

    uat : entity work.Trs80CassetteStreamerTest
    generic map
    (
        p_clock_hz => integer(c_clock_hz),
        p_buffer_size => 5
    )
    port map
    (
        i_clock => s_clock,
        i_reset => s_reset,
        i_record_button => s_record_button,
        o_uart_tx => s_uart_tx,
        o_debug => open
    );

        
    stop_proc: process
    begin
        s_record_button <= '1';
        wait for 5 ms;
        s_record_button <= '0';
        wait for 6 ms;
        s_record_button <= '1';

        wait for 900 ms;

        s_record_button <= '0';
        wait for 6 ms;
        s_record_button <= '1';

        wait;

    end process;


end;