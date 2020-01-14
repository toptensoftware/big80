library ieee;
use ieee.std_logic_1164.all;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    constant c_clock_hz : real := 1_774_000.0;
    signal s_reset : std_logic;
    signal s_clock : std_logic := '0';
    signal s_motor : std_logic;
    signal s_audio : std_logic;
    signal s_start : std_logic;
    signal s_record : std_logic;
    signal s_stop : std_logic;
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

    auto : entity work.Trs80AutoCassette
    generic map
    (
        p_clken_hz => 1_774_000,
        p_monitor_ms => 50
    )
    port map
    (
        i_clock => s_clock,
        i_clken => '1',
        i_reset => s_reset,
        i_motor => s_motor,
        i_audio => s_audio,
        o_start => s_start,
        o_record => s_record,
        o_stop => s_stop
    );

    fake : process
    begin

        s_motor <= '0';
        s_audio <= '0';

        wait for 1 ms;
        s_motor <= '1';

--        wait for 5 ms;
--        s_audio <= '1';
--        wait for 5 ms;
--        s_audio <= '0';
--        wait for 5 ms;
--        s_audio <= '1';
--        wait for 5 ms;
--        s_audio <= '0';

        wait for 60 ms;
        s_motor <= '0';

        wait;

    end process;
        
end;