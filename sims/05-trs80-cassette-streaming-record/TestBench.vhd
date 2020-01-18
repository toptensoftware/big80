library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_clken : std_logic;
    signal s_audio : std_logic_vector(1 downto 0);
    signal s_sd_data : std_logic_vector(7 downto 0);
    signal s_sd_data_cycle : std_logic;
    signal s_sd_block_available : std_logic;
    signal s_recording_finished : std_logic;
    signal s_stop_recording : std_logic;
    constant c_clock_hz : real := 1_774_000.0 * 2.0;
    constant c_buffer_size : integer := 2;
    constant c_addr_ones : std_logic_vector(c_buffer_size - 1 downto 0) := (others => '1');
    signal s_drain_addr : std_logic_vector(c_buffer_size - 1 downto 0);
    signal s_draining : std_logic;
    signal s_drain_divider : std_logic_vector(3 downto 0);
begin


    reset_proc: process
    begin
        s_reset <= '1';
        wait for 1 us;
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

    -- Fake cassette audio stream
    fake : entity work.Trs80FakeCassetteAudio
    port map
    (
        i_clock => s_clock,
        i_clken => s_clken,
        i_reset => s_reset,
        o_audio => s_audio
    );

    -- Unit under test.  Feed audio into this, expected
    -- buffer blocks to be produced
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
        i_record_mode => '1',
        i_data => x"00",
        o_audio => open,
        i_audio => s_audio(0),
        o_block_available => s_sd_block_available,
        i_data_cycle => s_sd_data_cycle,
        o_data => s_sd_data,
        i_stop_recording => s_stop_recording,
        o_recording_finished => s_recording_finished
    );

    s_sd_data_cycle <= '1' when s_drain_divider="0001" else '0';

    write_data : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_drain_addr <= (others => '0');
                s_draining <= '0';
                s_drain_divider <= (others => '0');
            elsif s_sd_block_available = '1' then
                s_drain_addr <= (others =>'0');
                s_draining <= '1';
                s_drain_divider <= (others => '0');
            elsif s_draining = '1' then
                s_drain_divider <= std_logic_vector(unsigned(s_drain_divider) + 1);
                if (s_drain_divider = "1111") then
                    s_drain_addr <= std_logic_vector(unsigned(s_drain_addr) + 1);
                    if s_drain_addr = c_addr_ones then 
                        s_draining <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    stop_proc: process
    begin
        s_stop_recording <= '0';
        wait for 160 ms;
        s_stop_recording <= '1';
        wait;
    end process;


end;