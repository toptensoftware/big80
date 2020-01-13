library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_parser_reset : std_logic;
    signal s_clock_enable : std_logic;
    signal s_audio : std_logic;
    signal s_dout : std_logic_vector(7 downto 0);
    signal s_dout_available : std_logic;
    constant c_ClockFrequency : real := 1_774_000.0 * 2.0;
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
        wait for 1 sec / (c_ClockFrequency * 2.0);
    end process;

    clken_proc : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then 
                s_clock_enable <= '0';
            else
                s_clock_enable <= not s_clock_enable;
            end if;
        end if;
    end process;

    renderer : entity work.Trs80FakeCassetteAudio
    port map
    (
        i_Clock => s_clock,
        i_ClockEnable => s_clock_enable,
        i_Reset => s_reset,
        o_Audio => s_audio
    );

    parser : entity work.Trs80CassetteParser
    generic map
    (
        p_ClockEnableFrequency => 1_774_000
    )
    port map
    (
        i_Clock => s_clock,
        i_ClockEnable => s_clock_enable,
        i_Reset => s_parser_reset,
        i_Audio => s_audio,
        o_Data => s_dout,
        o_DataAvailable => s_dout_available
    );

    parser_reset_proc: process
    begin
        s_parser_reset <= '1';
        wait for 5 ms;
        s_parser_reset <= '0';
        wait;
    end process;



end;