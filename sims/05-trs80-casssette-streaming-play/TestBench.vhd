library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_clken : std_logic;
    constant c_buffer_size : integer := 2;
    constant c_addr_ones : std_logic_vector(c_buffer_size - 1 downto 0) := (others => '1');
    signal s_load_addr : std_logic_vector(c_buffer_size - 1 downto 0);
    signal s_loading : std_logic;
    signal s_block_needed : std_logic;
    signal s_data_cycle : std_logic;
    signal s_audio : std_logic_vector(1 downto 0);
    constant c_clock_hz : real := 1_774_000.0 * 2.0;
    signal s_load_divider : unsigned(3 downto 0);
    signal s_data : std_logic_vector(7 downto 0);
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

    streamer : entity work.Trs80CassetteStreamer
    generic map
    (
        p_clken_hz => 1_774_000,
        p_buffer_size => c_buffer_size
    )
    port map
    (
        i_clock => s_clock,
        i_clken => s_clken,
        i_reset => s_reset,
        i_record_mode => '0',
        i_data => s_data,
        i_data_cycle => s_data_cycle,
        o_block_needed => s_block_needed,
        o_audio => s_audio,
        i_audio => '0',
        o_block_available => open,
        o_data => open,
        i_stop_recording => '0',
        o_recording_finished => open
    );

    s_data_cycle <= '1' when s_loading='1' and s_load_divider="1000" else '0';

    data : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_load_addr <= (others => '0');
                s_loading <= '0';
                s_load_divider <= (others => '0');
                s_data <= (others => '0');
            elsif s_block_needed = '1' then
                s_load_addr <= (others => '0');
                s_loading <= '1';
                s_load_divider <= (others => '0');
            elsif s_loading = '1' then
                s_load_divider <= s_load_divider + 1;
                if (s_load_divider = "1111") then
                    s_data <= std_logic_vector(unsigned(s_data) + 1);
                    s_load_addr <= std_logic_vector(unsigned(s_load_addr) + 1);
                    if s_load_addr = c_addr_ones then 
                        s_loading <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;


end;