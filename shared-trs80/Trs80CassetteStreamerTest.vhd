library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity Trs80CassetteStreamerTest is
generic
(
	p_clock_hz : integer;
	p_buffer_size : integer := 4
);
port 
( 
	i_clock : in std_logic;
	i_reset : in std_logic;
	i_record_button : in std_logic;
	o_uart_tx : out std_logic;
	o_debug : out std_logic_vector(7 downto 0)
);
end Trs80CassetteStreamerTest;

architecture Behavioral of Trs80CassetteStreamerTest is
	constant c_ones : std_logic_vector(p_buffer_size - 1 downto 0) := (others => '1');
	signal s_fake_audio_reset : std_logic;
	signal s_streamer_reset : std_logic;
	signal s_audio : std_logic_vector(1 downto 0);
	signal s_sd_block_available : std_logic;
	signal s_sd_data : std_logic_vector(7 downto 0);
	signal s_sd_data_cycle : std_logic;
	signal s_stop_recording : std_logic;
	signal s_recording_finished : std_logic;
	signal s_tx : std_logic;
	signal s_tx_busy : std_logic;
	signal s_tx_data_available : std_logic;
	signal s_button_deb : std_logic;
	signal s_button_edge : std_logic;		
	signal s_bytes_sent : std_logic_vector(p_buffer_size - 1 downto 0);

	type tx_states is
	(
		tx_state_idle,
		tx_state_transmitting,
		tx_state_get_next_byte,
		tx_state_send_next_byte
	);

	signal s_tx_state : tx_states := tx_state_idle;

	type states is
	(
		state_idle,
		state_recording,
		state_stopping,
		state_flushing,
		state_finished
	);
	signal s_state : states := state_idle;

--pragma synthesis_off
signal s_state_integer : integer;
signal s_tx_state_integer : integer;
--pragma synthesis_on

begin
--pragma synthesis_off
	s_state_integer <= states'pos(s_state);
	s_tx_state_integer <= tx_states'pos(s_tx_state);
--pragma synthesis_on

	-- Output stuff
	o_uart_tx <= s_tx;

    -- Fake cassette audio stream
	fake : entity work.Trs80FakeCassetteAudio
	generic map
	(
		p_clken_hz => p_clock_hz
	)
    port map
    (
        i_clock => i_clock,
        i_clken => '1',
        i_reset => s_fake_audio_reset,
        o_audio => s_audio
    );

    -- Unit under test.  Feed audio into this, expected
    -- buffer blocks to be produced
    streamer : entity work.Trs80CassetteStreamer
    generic map
    (
		p_clken_hz => p_clock_hz,
        p_buffer_size => p_buffer_size
    )
    port map
    (
        i_clock => i_clock,
        i_clken => '1',
        i_reset => s_streamer_reset,
        i_record_mode => '1',
        o_block_needed => open,
        o_audio => open,
        i_audio => s_audio(0),
        o_block_available => s_sd_block_available,
        i_data_cycle => s_sd_data_cycle,
        i_data => x"00",
        o_data => s_sd_data,
        i_stop_recording => s_stop_recording,
        o_recording_finished => s_recording_finished
    );

	-- UART to send it
	txer : entity work.UartTx
	generic map
	(
		p_clken_hz  => p_clock_hz
	)
	port map
	( 
		i_clock => i_clock,
		i_clken => '1',
		i_reset => i_reset,
		i_data => s_sd_data,
		i_data_available => s_tx_data_available,
		o_uart_tx => s_tx,
		o_busy => s_tx_busy
	);

	-- Debounce button
	debounce : entity work.DebounceFilterWithEdge 
	generic map
	(
		p_clock_hz => p_clock_hz,
		p_stable_us => 5000,
		p_default_state => '1'
	)
	port map
	( 
		i_clock => i_clock,
		i_reset => i_reset,
		i_signal => i_record_button,
		o_signal => s_button_deb,
		o_signal_edge => s_button_edge
	);

	uart_streamer : process(i_clock)
	begin
		if rising_edge(i_clock) then 
			if i_reset = '1' then
				s_tx_state <= tx_state_idle;
				s_tx_data_available <= '0';
				s_sd_data_cycle <= '0';
				s_bytes_sent <= (others => '0');
			else
				s_tx_data_available <= '0';
				s_sd_data_cycle <= '0';

				case s_tx_state is
					when tx_state_idle => 
						if s_sd_block_available = '1' then
							s_tx_data_available <= '1';
							s_tx_state <= tx_state_transmitting;
							s_bytes_sent <= (others => '0');
						end if;

					when tx_state_transmitting => 
						if s_tx_busy = '0' then 
							s_tx_state <= tx_state_get_next_byte;
							s_sd_data_cycle <= '1';
						end if;

					when tx_state_get_next_byte => 
						if s_bytes_sent = c_ones then
							s_tx_state <= tx_state_idle;
						else
							s_tx_state <= tx_state_send_next_byte;
							s_bytes_sent <= std_logic_vector(unsigned(s_bytes_sent) + 1);
						end if;

					when tx_state_send_next_byte =>
						s_tx_data_available <= '1';
						s_tx_state <= tx_state_transmitting;
					
				end case;
			end if;
		end if;
	end process;

	-- Control logic
	control : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then
				s_state <= state_idle;
				s_fake_audio_reset <= '1';
				s_streamer_reset <= '1';
				s_stop_recording <= '0';
				o_debug <= (others => '0');
			else
				s_stop_recording <= '0';

				case s_state is

					when state_idle =>
						o_debug(0) <= '1';
						if s_button_deb = '0' and s_button_edge = '1' then
							o_debug(1) <= '1';
							s_state <= state_recording;
							s_streamer_reset <= '0';
							s_fake_audio_reset <= '0';
						end if;

					when state_recording =>
						o_debug(2) <= '1';
						if s_button_deb = '0' and s_button_edge = '1' then
							s_state <= state_stopping;
							o_debug(3) <= '1';
						end if;
						
					when state_stopping =>
						s_stop_recording <= '1';
						s_state <= state_flushing;
						o_debug(4) <= '1';

					when state_flushing =>
						o_debug(5) <= '1';
						if s_recording_finished = '1' then
							o_debug(6) <= '1';
							s_state <= state_finished;
						end if;

					when state_finished =>
						o_debug(7) <= '1';
						s_streamer_reset <= '1';
						s_fake_audio_reset <= '1';
						s_state <= state_idle;

				end case;
			end if;
		end if;
	end process;

end Behavioral;

