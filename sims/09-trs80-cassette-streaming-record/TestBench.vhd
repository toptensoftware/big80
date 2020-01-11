library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_clock_enable : std_logic;
    signal s_audio : std_logic;
    signal s_sd_data : std_logic_vector(7 downto 0);
    signal s_sd_data_needed : std_logic;
    signal s_sd_data_available : std_logic;
    signal s_recording_finished : std_logic;
    signal s_stop_recording : std_logic;
    constant c_ClockFrequency : real := 1_774_000.0 * 2.0;
    constant c_BufferSize : integer := 2;
    constant c_addr_ones : std_logic_vector(c_BufferSize - 1 downto 0) := (others => '1');
    signal s_drain_addr : std_logic_vector(c_BufferSize - 1 downto 0);
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

    -- Fake cassette audio stream
    fake : entity work.Trs80FakeCassetteAudio
    port map
    (
        i_Clock => s_clock,
        i_ClockEnable => s_clock_enable,
        i_Reset => s_reset,
        o_Audio => s_audio
    );

    -- Unit under test.  Feed audio into this, expected
    -- buffer blocks to be produced
    streamer : entity work.Trs80CassetteStreamer
    generic map
    (
        p_BufferSize => c_BufferSize
    )
    port map
    (
        i_Clock => s_clock,
        i_ClockEnable => s_clock_enable,
        i_Reset => s_reset,
        i_RecordMode => '1',
        i_Data => x"00",
        i_DataAvailable => '0',
        o_DataNeeded => open,
        o_Audio => open,
        i_Audio => s_audio,
        o_DataAvailable => s_sd_data_available,
        i_DataNeeded => s_sd_data_needed,
        o_Data => s_sd_data,
        i_StopRecording => s_stop_recording,
        o_RecordingFinished => s_recording_finished
    );

    s_sd_data_needed <= '1' when s_drain_divider="0001" else '0';

    write_data : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_drain_addr <= (others => '0');
                s_draining <= '0';
                s_drain_divider <= (others => '0');
            elsif s_sd_data_available = '1' then
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