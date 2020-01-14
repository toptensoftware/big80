library ieee;
use ieee.std_logic_1164.all;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_clken_1 : std_logic;
    signal s_clken_2 : std_logic;
begin

    divider : entity work.ClockDividerPow2
    generic map
    (
        p_divider_width_1 => 2,
        p_divider_width_2 => 4
    )
    port map
    (
        i_clock => s_clock,
        i_reset => s_reset,
        o_clken_1 => s_clken_1,
        o_clken_2 => s_clken_2
    );

    reset_proc: process
    begin
        s_reset <= '1';
        wait for 2 us;
        s_reset <= '0';
        wait;
    end process;

    stim_proc: process
    begin
        s_clock <= not s_clock;
        wait for 1 us;
    end process;
end;