library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;
	i_button_right : in std_logic;
	i_button_up : in std_logic;
	i_button_down : in std_logic;
	i_button_left : in std_logic;
	o_sd_mosi : out std_logic;
	i_sd_miso : in std_logic;
	o_sd_ss_n : out std_logic;
	o_sd_sclk : out std_logic;
	o_leds : out std_logic_vector(7 downto 0);
	o_seven_segment : out std_logic_vector(7 downto 0);
	o_seven_segment_en : out std_logic_vector(2 downto 0);
	o_audio : out std_logic_vector(1 downto 0);
	o_uart_tx : out std_logic;
	o_uart2_tx : out std_logic;
	debug_audio : out std_logic
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_clock_100mhz : std_logic;
	signal s_clock_80mhz : std_logic;
	signal s_clken_cpu : std_logic;

	signal s_sd_op_wr : std_logic;
	signal s_sd_op_cmd : std_logic_vector(1 downto 0);
	signal s_sd_op_block_number : std_logic_vector(31 downto 0);
	signal s_sd_dcycle :  std_logic;
	signal s_sd_din : std_logic_vector(7 downto 0);
	signal s_sd_dout : std_logic_vector(7 downto 0);
	signal s_sd_status : std_logic_vector(7 downto 0);

	signal s_buttons_unbounced : std_logic_vector(2 downto 0);
	signal s_buttons_debounced : std_logic_vector(2 downto 0);
	signal s_buttons_edges : std_logic_vector(2 downto 0);
	signal s_buttons_trigger : std_logic_vector(2 downto 0);
	signal s_button_start : std_logic;
	signal s_button_stop : std_logic;
	signal s_button_record : std_logic;

	signal s_seven_seg_value : std_logic_vector(11 downto 0);
	signal s_selected_tape : std_logic_vector(11 downto 0);

	signal s_Audio : std_logic_vector(1 downto 0);
	signal s_recording : std_logic;
	signal s_playing_or_recording : std_logic;

	signal s_parser_reset : std_logic;
	signal s_parser_audio : std_logic;
	signal s_dout : std_logic_vector(7 downto 0);
	signal s_dout_available : std_logic;
	signal s_dout_available_pulse : std_logic;
	signal s_uart_tx : std_logic;
	signal s_uart_busy : std_logic;

	signal s_fake_audio_reset : std_logic;
	signal s_fake_audio : std_logic_vector(1 downto 0);
begin

	-- Reset signal
	s_reset <= not i_button_b;

	-- sdhc/sdinit/sdwrite/sdread
	o_leds(7 downto 4) <=  s_sd_status(7) & s_sd_status(4) & s_sd_status(2) & s_sd_status(1);

	-- uarttx/audio/recording/active
	o_leds(3 downto 0) <=  s_uart_busy & (s_Audio(0) or s_Audio(1)) & s_recording & s_playing_or_recording;

	o_uart_tx <= s_uart_tx;
	o_uart2_tx <= s_uart_tx;

	-- Generate 80MHz
	dcm : entity work.ClockDCM
	port map
	(
		CLK_IN_100MHz => i_clock_100mhz,
		CLK_OUT_100MHz => s_clock_100mhz,
		CLK_OUT_80MHz => s_clock_80mhz
	);

	-- Divide by 45 for 1.774Mhz
	cpu_clock_divider : entity work.ClockDivider
	generic map
	(
		p_period => 45
	)
	port map
	(
		i_clock => s_clock_80mhz,
		i_clken => '1',
		i_reset => s_reset,
		o_clken => s_clken_cpu
	);

	-- Seven segment driver
	seven_seg : entity work.SevenSegmentHexDisplayWithClockDivider
	generic map
	(
		p_clock_hz => 80_000_000
	)
	port map
	( 
		i_clock => s_clock_80mhz,
		i_reset => s_Reset,
		i_data => s_seven_seg_value,
		o_segments => o_seven_segment(7 downto 1),
		o_segments_en => o_seven_segment_en
	);
	o_seven_segment(0) <= '1';

	-- Show the selected tape/current play position
	s_seven_seg_value <= s_selected_tape;

	-- SD Controller
	sdcard : entity work.SDCardController
	generic map
	(
		p_clock_div_800khz => 100,
		p_clock_div_50mhz => 2
	)
	port map
	(
		i_reset => s_reset,
		i_clock => s_clock_80mhz,
		o_ss_n => o_sd_ss_n,
		o_mosi => o_sd_mosi,
		i_miso => i_sd_miso,
		o_sclk => o_sd_sclk,
		o_status => s_sd_status,
		i_op_write => s_sd_op_wr,
		i_op_cmd => s_sd_op_cmd,
		i_op_block_number => s_sd_op_block_number,
		o_last_block_number => open,
		o_data_start => open,
		o_data_cycle => s_sd_dcycle,
		i_din => s_sd_din,
		o_dout => s_sd_dout
	);

	-- Debounce buttons
	debounce : entity work.DebounceFilterSet
	generic map
	(
		p_clock_hz => 80_000_000,
		p_stable_us => 5000,
		p_signal_count => 3,
		p_default_state => '1'
	)
	port map
	(
		i_clock => s_clock_80mhz,
		i_reset => s_Reset,
		i_signals => s_buttons_unbounced,
		o_signals => s_buttons_debounced,
		o_signal_edges => s_buttons_edges
	);

	s_buttons_unbounced <= i_button_down & i_button_up & i_button_right;
	s_buttons_trigger <= s_buttons_edges and not s_buttons_debounced;
	s_button_start <= s_buttons_trigger(0) and not s_playing_or_recording;
	s_button_stop <= s_buttons_trigger(0) and s_playing_or_recording;
	s_button_record <= not i_button_left;


	-- Cassette Player
	player : entity work.Trs80CassettePlayer
	generic map
	(
		p_clken_hz => 1_774_000
	)
	port map
	(
		i_clock => s_clock_80mhz,
		i_clken => s_clken_cpu,
		i_reset => s_Reset,
		i_button_start => s_button_start,
		i_button_record => s_button_record,
		i_button_stop => s_button_stop,
		i_button_next => s_buttons_trigger(1),
		i_button_prev => s_buttons_trigger(2),
		o_playing_or_recording => s_playing_or_recording,
		o_recording => s_recording,
		o_sd_op_wr => s_sd_op_wr,
		o_sd_op_cmd => s_sd_op_cmd,
		o_sd_op_block_number => s_sd_op_block_number,
		i_sd_status => s_sd_status,
		i_sd_dcycle => s_sd_dcycle,
		i_sd_data => s_sd_dout,
		o_sd_data => s_sd_din,
		o_display => s_selected_tape,
		o_audio => s_Audio,
		i_audio => s_fake_audio(0)
	);

	-- Output audio on both channels
	o_audio <= s_Audio(0) & s_Audio(0);
	debug_audio <= s_Audio(0);

	-- Also parse and send to uart
	parser : entity work.Trs80CassetteParser
	generic map
	(
		p_clken_hz => 1_774_000
	)
	port map
	(
		i_clock => s_clock_80mhz,
		i_clken => s_clken_cpu,
		i_reset => s_parser_reset,
		i_audio => s_parser_audio,
		o_data_available => s_dout_available,
		o_data => s_dout
	);

	-- Hold parser in reset state when not active
	s_parser_reset <= s_reset or not s_playing_or_recording;

	-- Send it either the playback or record audio
	s_parser_audio <= s_Audio(0) when s_recording = '0' else s_fake_audio(0);

	-- Convert pulse back to master clock
	s_dout_available_pulse <= s_dout_available and s_clken_cpu;

	-- UART to send parsed audio to PC
	uart_txer : entity work.UartTx
	generic map
	(
		p_clken_hz => 80_000_000
	)
	port map
	( 
		i_clock => s_clock_80mhz,
		i_clken => '1',
		i_reset => s_reset,
		i_data => s_dout,
		i_data_available => s_dout_available_pulse,
		o_uart_tx => s_uart_tx,
		o_busy => s_uart_busy
	);	

	-- Generate fake audio to test the recorder with
	fake_audio : entity work.Trs80FakeCassetteAudio
	generic map
	(
		p_clken_hz => 1_744_000
	)
	port map
	(
		i_clock => s_clock_80mhz,
		i_clken => s_clken_cpu,
		i_reset => s_fake_audio_reset,
		o_audio => s_fake_audio
	);

	-- Hold fake audio in reset when not recording
	s_fake_audio_reset <= s_reset or not s_recording;

end Behavioral;

