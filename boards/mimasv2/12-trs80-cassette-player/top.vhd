library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	CLK_100MHz_in : in std_logic;
	Button_B : in std_logic;
	Button_Right : in std_logic;
	Button_Up : in std_logic;
	Button_Down : in std_logic;
	Button_Left : in std_logic;
	sd_mosi : out std_logic;
	sd_miso : in std_logic;
	sd_ss_n : out std_logic;
	sd_sclk : out std_logic;
	LEDs : out std_logic_vector(7 downto 0);
	SevenSegment : out std_logic_vector(7 downto 0);
	SevenSegmentEnable : out std_logic_vector(2 downto 0);
	Audio : out std_logic_vector(1 downto 0);
	UART_TX : out std_logic;
	UART2_TX : out std_logic;
	debug_audio : out std_logic
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_CLK_100Mhz_unused : std_logic;
	signal s_CLK_80Mhz : std_logic;
	signal s_CLK_CPU_en : std_logic;

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
	signal s_button_record : std_logic;

	signal s_seven_seg_value : std_logic_vector(11 downto 0);
	signal s_selected_tape : std_logic_vector(11 downto 0);

	signal s_Audio : std_logic;
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
	signal s_fake_audio : std_logic;

	signal s_debug : std_logic_vector(7 downto 0);
begin

	-- Reset signal
	s_reset <= not Button_B;

	-- sdhc/sdinit/sdwrite/sdread
--	LEDs(7 downto 4) <=  s_sd_status(7) & s_sd_status(4) & s_sd_status(2) & s_sd_status(1);

	-- uarttx/audio/recording/active
--	LEDS(3 downto 0) <=  s_uart_busy & s_Audio & s_recording & s_playing_or_recording;

	LEDs <= s_debug;

	UART_TX <= s_uart_tx;
	UART2_TX <= s_uart_tx;

	-- Generate 80MHz
	dcm : entity work.ClockDCM
	port map
	(
		CLK_IN_100MHz => CLK_100MHz_in,
		CLK_OUT_100MHz => s_CLK_100Mhz_unused,
		CLK_OUT_80MHz => s_CLK_80MHz
	);

	-- Divide by 45 for 1.774Mhz
	cpu_clock_divider : entity work.ClockDivider
	generic map
	(
		p_DivideCycles => 45
	)
	port map
	(
		i_Clock => s_CLK_80Mhz,
		i_ClockEnable => '1',
		i_Reset => s_reset,
		o_ClockEnable => s_CLK_CPU_en
	);

	-- Seven segment driver
	seven_seg : entity work.SevenSegmentHexDisplayWithClockDivider
	generic map
	(
		p_ClockFrequency => 80_000_000
	)
	port map
	( 
		i_Clock => s_CLK_80Mhz,
		i_Reset => s_Reset,
		i_Value => s_seven_seg_value,
		o_SevenSegment => SevenSegment(7 downto 1),
		o_SevenSegmentEnable => SevenSegmentEnable
	);
	SevenSegment(0) <= '1';

	-- Show the selected tape/current play position
	s_seven_seg_value <= s_selected_tape;

	-- SD Controller
	sdcard : entity work.SDCardController
	generic map
	(
		p_ClockDiv800Khz => 100,
		p_ClockDiv50Mhz => 2
	)
	port map
	(
		reset => s_reset,
		clock => s_CLK_80MHz,
		ss_n => sd_ss_n,
		mosi => sd_mosi,
		miso => sd_miso,
		sclk => sd_sclk,
		status => s_sd_status,
		op_wr => s_sd_op_wr,
		op_cmd => s_sd_op_cmd,
		op_block_number => s_sd_op_block_number,
		last_block_number => open,
		dstart => open,
		dcycle => s_sd_dcycle,
		din => s_sd_din,
		dout => s_sd_dout
	);

	-- Debounce buttons
	debounce : entity work.DebounceFilterSet
	generic map
	(
		p_ClockFrequency => 80_000_000,
		p_DebounceTimeUS => 5000,
		p_SignalCount => 3,
		p_ResetState => '1'
	)
	port map
	(
		i_Clock => s_CLK_80Mhz,
		i_Reset => s_Reset,
		i_Signals => s_buttons_unbounced,
		o_Signals => s_buttons_debounced,
		o_SignalEdges => s_buttons_edges
	);

	s_buttons_unbounced <= Button_Down & Button_Up & Button_Right;
	s_buttons_trigger <= s_buttons_edges and not s_buttons_debounced;
	s_button_record <= not Button_Left;


	-- Cassette Player
	player : entity work.Trs80CassettePlayer
	generic map
	(
		p_ClockEnableFrequency => 1_774_000
	)
	port map
	(
		i_Clock => s_CLK_80Mhz,
		i_ClockEnable => s_CLK_CPU_en,
		i_Reset => s_Reset,
		i_ButtonStartStop => s_buttons_trigger(0),
		i_ButtonRecord => s_button_record,
		i_ButtonNext => s_buttons_trigger(1),
		i_ButtonPrev => s_buttons_trigger(2),
		o_PlayingOrRecording => s_playing_or_recording,
		o_Recording => s_recording,
		o_sd_op_wr => s_sd_op_wr,
		o_sd_op_cmd => s_sd_op_cmd,
		o_sd_op_block_number => s_sd_op_block_number,
		i_sd_status => s_sd_status,
		i_sd_dcycle => s_sd_dcycle,
		i_sd_data => s_sd_dout,
		o_sd_data => s_sd_din,
		o_SelectedTape => s_selected_tape,
		o_Audio => s_Audio,
		i_Audio => s_fake_audio,
		debug => s_debug
	);

	-- Output audio on both channels
	Audio <= s_Audio & s_Audio;
	debug_audio <= s_Audio;

	-- Also parse and send to uart
	parser : entity work.Trs80CassetteParser
	generic map
	(
		p_ClockEnableFrequency => 1_774_000
	)
	port map
	(
		i_Clock => s_CLK_80Mhz,
		i_ClockEnable => s_CLK_CPU_en,
		i_Reset => s_parser_reset,
		i_Audio => s_parser_audio,
		o_DataAvailable => s_dout_available,
		o_Data => s_dout
	);

	-- Hold parser in reset state when not active
	s_parser_reset <= s_reset or not s_playing_or_recording;

	-- Send it either the playback or record audio
	s_parser_audio <= s_Audio when s_recording = '0' else s_fake_audio;

	-- Convert pulse back to master clock
	s_dout_available_pulse <= s_dout_available and s_CLK_CPU_en;

	-- UART to send parsed audio to PC
	uart_txer : entity work.UartTx
	generic map
	(
		p_ClockFrequency => 80_000_000
	)
	port map
	( 
		i_Clock => s_CLK_80Mhz,
		i_ClockEnable => '1',
		i_Reset => s_reset,
		i_Data => s_dout,
		i_DataAvailable => s_dout_available_pulse,
		o_UartTx => s_uart_tx,
		o_Busy => s_uart_busy
	);	

	-- Generate fake audio to test the recorder with
	fake_audio : entity work.Trs80FakeCassetteAudio
	generic map
	(
		p_ClockEnableFrequency => 1_744_000
	)
	port map
	(
		i_Clock => s_CLK_80Mhz,
		i_ClockEnable => s_CLK_CPU_en,
		i_Reset => s_fake_audio_reset,
		o_Audio => s_fake_audio
	);

	-- Hold fake audio in reset when not recording
	s_fake_audio_reset <= s_reset or not s_recording;

end Behavioral;

