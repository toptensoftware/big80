library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_clock_enable : std_logic;
    signal s_load_addr : std_logic_vector(8 downto 0);
    signal s_loading : std_logic;
    signal s_data_needed : std_logic;
    signal s_data_available : std_logic;
    signal s_audio : std_logic;
    constant c_ClockFrequency : real := 1_774_000.0 * 2.0;
    signal s_load_divider : unsigned(3 downto 0);
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

    streamer : entity work.Trs80CassetteStreamer
    port map
    (
        i_Clock => s_clock,
        i_ClockEnable => s_clock_enable,
        i_Reset => s_reset,
        i_Data => s_load_addr(7 downto 0),
        i_DataAvailable => s_data_available,
        o_DataNeeded => s_data_needed,
        o_Audio => s_audio
    );

    s_data_available <= '1' when s_loading='1' and s_load_divider="1000" else '0';

    data : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_load_addr <= "000000000";
                s_loading <= '0';
                s_load_divider <= (others => '0');
            elsif s_data_needed = '1' then
                s_load_addr <= "000000000";
                s_loading <= '1';
                s_load_divider <= (others => '0');
            elsif s_loading = '1' then
                s_load_divider <= s_load_divider + 1;
                if (s_load_divider = "1111") then
                    s_load_addr <= std_logic_vector(unsigned(s_load_addr) + 1);
                    if s_load_addr = "111111111" then 
                        s_loading <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;


end;