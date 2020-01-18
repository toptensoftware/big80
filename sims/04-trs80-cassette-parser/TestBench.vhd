library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_parser_reset : std_logic;
    signal s_clken : std_logic;
    signal s_audio : std_logic_vector(1 downto 0);
    signal s_dout : std_logic_vector(7 downto 0);
    signal s_dout_available : std_logic;
    constant c_clock_hz : real := 1_774_000.0 * 2.0;
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

    clken_proc : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then 
                s_clken <= '0';
            else
                s_clken <= not s_clken;
            end if;
        end if;
    end process;

    renderer : entity work.Trs80FakeCassetteAudio
    port map
    (
        i_clock => s_clock,
        i_clken => s_clken,
        i_reset => s_reset,
        o_audio => s_audio
    );

    parser : entity work.Trs80CassetteParser
    generic map
    (
        p_clken_hz => 1_774_000
    )
    port map
    (
        i_clock => s_clock,
        i_clken => s_clken,
        i_reset => s_parser_reset,
        i_audio => s_audio(0),
        o_data => s_dout,
        o_data_available => s_dout_available
    );

    parser_reset_proc: process
    begin
        s_parser_reset <= '1';
        wait for 5 ms;
        s_parser_reset <= '0';
        wait;
    end process;



end;