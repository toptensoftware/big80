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
        p_DividerWidth_1 => 2,
        p_DividerWidth_2 => 4
    )
    port map
    (
        i_Clock => s_clock,
        i_Reset => s_reset,
        o_ClockEnable_1 => s_clken_1,
        o_ClockEnable_2 => s_clken_2
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