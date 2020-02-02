library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
(
	-- These signals must match what's in the .ucf file
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;
	o_horz_sync : out std_logic;
	o_vert_sync : out std_logic;
	o_red : out std_logic_vector(2 downto 0);
	o_green : out std_logic_vector(2 downto 0);
	o_blue : out std_logic_vector(2 downto 1);
	io_ps2_clock : inout std_logic;
	io_ps2_data : inout std_logic;

	i_button_right : in std_logic;
	i_button_up : in std_logic;
	i_button_down : in std_logic;
	i_button_left : in std_logic;

	i_switch_turbo_tape : in std_logic;
	i_switch_typing_mode : in std_logic;
	i_switch_green_screen : in std_logic;
	i_switch_no_scan_lines : in std_logic;
	i_switch_cas_audio : in std_logic;
	i_switch_auto_cas : in std_logic;

	i_switch_run : in std_logic;

	o_sd_mosi : out std_logic;
	i_sd_miso : in std_logic;
	o_sd_ss_n : out std_logic;
	o_sd_sclk : out std_logic;
	o_leds : out std_logic_vector(7 downto 0);
	o_seven_segment : out std_logic_vector(7 downto 0);
	o_seven_segment_en : out std_logic_vector(2 downto 0);
	o_audio : out std_logic_vector(1 downto 0);

	-- PSX Signals
	o_psx_att : out std_logic;
	o_psx_clock : out std_logic;
	o_psx_hoci : out std_logic;
	i_psx_hico : in std_logic;
	i_psx_ack : in std_logic
	
);
end top;

architecture Behavioral of top is
	-- Reset and clocking
	signal s_reset : std_logic;
	signal s_reset_n : std_logic;
	signal s_soft_reset : integer range 0 to 15 := 0;
	signal s_clock_80mhz : std_logic;
	signal s_clken_40mhz : std_logic;
	signal s_clken_cpu_normal : std_logic;
	signal s_clken_cpu_turbo : std_logic;
	signal s_clken_cpu : std_logic;
	signal s_turbo_mode : std_logic;

	-- Video
	signal s_blank : std_logic;
	signal s_hpos : integer range -2048 to 2047;
	signal s_vpos : integer range -2048 to 2047;
	signal s_video_ram_addr : std_logic_vector(9 downto 0);
	signal s_video_ram_data : std_logic_vector(7 downto 0);
	signal s_char_rom_addr : std_logic_vector(10 downto 0);
	signal s_char_rom_data : std_logic_vector(5 downto 0);
	signal s_pixel : std_logic;
	signal s_line_rep : integer range 0 to 2;

	signal s_video_ram_write_cpu : std_logic;
	signal s_video_ram_addr_cpu : std_logic_vector(9 downto 0);
	signal s_video_ram_din_cpu : std_logic_vector(7 downto 0);
	signal s_video_ram_dout_cpu : std_logic_vector(7 downto 0);

	-- RAM
	signal s_ram_write_cpu : std_logic;
	signal s_ram_addr_cpu : std_logic_vector(14 downto 0);
	signal s_ram_din_cpu : std_logic_vector(7 downto 0);
	signal s_ram_dout_cpu : std_logic_vector(7 downto 0);

	-- ROM
	signal s_rom_addr_cpu : std_logic_vector(13 downto 0);
	signal s_rom_dout_cpu : std_logic_vector(7 downto 0);

	-- CPU
	signal s_cpu_addr : std_logic_vector(15 downto 0);
	signal s_cpu_din : std_logic_vector(7 downto 0);
	signal s_cpu_dout : std_logic_vector(7 downto 0);
	signal s_cpu_mreq_n : std_logic;
	signal s_cpu_iorq_n : std_logic;
	signal s_cpu_rd_n : std_logic;
	signal s_cpu_wr_n : std_logic;
	signal s_cpu_wait_n : std_logic;

	-- Memory/Port Mapping
	signal s_mem_rd : std_logic;
	signal s_mem_wr : std_logic;
	signal s_port_rd : std_logic;
	signal s_port_wr : std_logic;
	signal s_is_rom_range : std_logic;
	signal s_is_vram_range : std_logic;
	signal s_is_ram_range : std_logic;
	signal s_is_keyboard_range : std_logic;
	signal s_is_cas_port : std_logic;
	signal s_is_trisstick_port : std_logic;

	-- Keyboard
	signal s_key_scancode : std_logic_vector(6 downto 0);
	signal s_key_extended : std_logic;
	signal s_key_release : std_logic;
	signal s_key_available : std_logic;
	signal s_key_switches : std_logic_vector(63 downto 0);
	signal s_key_dout_cpu : std_logic_vector(7 downto 0);

	-- Button debounce and edge detection
	signal s_buttons_unbounced : std_logic_vector(2 downto 0);
	signal s_buttons_debounced : std_logic_vector(2 downto 0);
	signal s_buttons_edges : std_logic_vector(2 downto 0);
	signal s_buttons_trigger : std_logic_vector(2 downto 0);
	signal s_button_start : std_logic;
	signal s_button_stop : std_logic;
	signal s_button_record : std_logic;

	-- Media Keys
	signal s_key_extended_press : std_logic;
	signal s_media_key_play : std_logic;
	signal s_media_key_next : std_logic;
	signal s_media_key_prev : std_logic;
	signal s_media_keys : std_logic_vector(2 downto 0);

	-- Cassette
	signal s_sd_op_wr : std_logic;
	signal s_sd_op_cmd : std_logic_vector(1 downto 0);
	signal s_sd_op_block_number : std_logic_vector(31 downto 0);
	signal s_sd_dcycle : std_logic;
	signal s_sd_din : std_logic_vector(7 downto 0);
	signal s_sd_dout : std_logic_vector(7 downto 0);
	signal s_sd_last_block_number : std_logic_vector(31 downto 0);
	signal s_sd_status : std_logic_vector(7 downto 0);
	signal s_seven_seg_value : std_logic_vector(11 downto 0);
	signal s_selected_tape : std_logic_vector(11 downto 0);
	signal s_recording : std_logic;
	signal s_playing_or_recording : std_logic;
	signal s_cas_prev_audio_in : std_logic_vector(1 downto 0);
	signal s_cas_audio_in : std_logic_vector(1 downto 0);
	signal s_cas_audio_out : std_logic_vector(1 downto 0);
	signal s_cas_audio_in_edge : std_logic;
	signal s_cas_motor : std_logic;
	signal s_audio : std_logic;
	signal s_wide_video_mode : std_logic;

	-- Auto cassette control
	signal s_cas_motor_monitored : std_logic;
	signal s_cas_auto_start : std_logic;
	signal s_cas_auto_record : std_logic;
	signal s_cas_auto_stop : std_logic;

	-- PSX Controller
	signal s_psx_buttons : std_logic_vector(15 downto 0);

begin

	-- Reset signal
	s_reset <= '1' when i_button_b = '0' or s_soft_reset /= 0 else '0';
	s_reset_n <= not s_reset;

	-- Soft reset process
	soft_reset : process(s_clock_80mhz)
	begin		
		if rising_edge(s_clock_80mhz) then
			if s_key_extended_press = '1' and s_key_scancode = "0110111" then
				s_soft_reset <= 15;
			end if;
			if s_soft_reset /= 0 then
				s_soft_reset <= s_soft_reset - 1;
			end if;
		end if;
	end process;

	-- Digital Clock Manager
	dcm : entity work.ClockDCM
	port map
	(
		CLK_IN_100MHz => i_clock_100mhz,
		CLK_OUT_100MHz => open,
		CLK_OUT_80MHz => s_clock_80mhz
	);

	-- Generate the 40Mhz clock enable
	process (s_clock_80mhz)
	begin
		if rising_edge(s_clock_80mhz) then
			if s_reset = '1' then
				s_clken_40mhz <= '0';
			else
				s_clken_40mhz <= not s_clken_40mhz;
			end if;
		end if;
	end process;

	-- Generate CPU clock enable (1.774Mhz)
	-- (80Mhz / 45 = 1.777Mhz)
	clock_div_cpu_1774 : entity work.ClockDivider
	generic map
	(
		p_period => 45
	)
	port map
	(
		i_clock => s_clock_80mhz,
		i_clken => '1',
		i_reset => s_reset,
		o_clken => s_clken_cpu_normal
	);

	s_clken_cpu_turbo <= s_clken_40mhz;
	s_clken_cpu <= 
		'0' when i_switch_run = '0' else 
		s_clken_cpu_turbo when s_turbo_mode = '1' else
		s_clken_cpu_normal;
	s_turbo_mode <= s_cas_motor and i_switch_turbo_tape;

	-- Generate VGA timing signals for 800x600 @ 60Hz
	vga_timing : entity work.VGATiming800x600
	port map
	(
		i_clock => s_clock_80mhz,
		i_clken => s_clken_40mhz,
		i_reset => s_reset,
		o_vert_sync => o_vert_sync,
		o_horz_sync => o_horz_sync,
		o_horz_pos => s_hpos,
		o_vert_pos => s_vpos,
		o_blank => s_blank
	);

	-- TRS80 Video Controller
	video_controller : entity work.Trs80VideoController
	generic map
	(
		p_left_margin_pixels => 16,
		p_top_margin_pixels => 12
	)
	port map
	(
		i_clock => s_clock_80mhz,
		i_clken => s_clken_40mhz,
		i_reset => s_reset,
		i_horz_pos => s_hpos,
		i_vert_pos => s_vpos,
		i_wide_mode => s_wide_video_mode,
		o_video_ram_addr => s_video_ram_addr,
		i_video_ram_data => s_video_ram_data,
		o_char_rom_addr => s_char_rom_addr,
		i_char_rom_data => s_char_rom_data,
		o_pixel => s_pixel,
		o_line_rep => s_line_rep
	);

	-- Generate color
	color_gen : process(s_pixel, i_switch_green_screen, i_switch_no_scan_lines, s_line_rep)
	begin
		if i_switch_green_screen = '1' then
			o_red <= "000";
			if i_switch_no_scan_lines = '0' then
				if s_line_rep = 1 then
					o_green <= s_pixel & s_pixel & s_pixel;
				else
					o_green <= s_pixel & "0" & s_pixel;
				end if;
			else
				o_green <= s_pixel & s_pixel & s_pixel;
			end if;
			o_blue <= "00";
		else
			o_red <= "000";
			if i_switch_no_scan_lines = '0' then
				if s_line_rep = 1 then
					o_red <= s_pixel & s_pixel & s_pixel;
					o_green <= s_pixel & "00";
				else
					o_red <= s_pixel & "0" & s_pixel;
					o_green <= "0" & s_pixel & "0";
				end if;
			else
				o_red <= s_pixel & s_pixel & s_pixel;
				o_green <= s_pixel & "00";
			end if;
			o_blue <= "00";
		end if;
	end process;


	-- TRS80 Character ROM
	charrom : entity work.Trs80CharRom
	port map
	(
		i_clock => s_clock_80mhz,
		i_addr => s_char_rom_addr,
		o_dout => s_char_rom_data
	);

	-- Video RAM (1K)
	vram : entity work.RamDualPortInferred	
	GENERIC MAP
	(
		p_addr_width => 10
	)
	PORT MAP
	(
		-- Read/Write port for CPU
		i_clock_a => s_clock_80mhz,
		i_clken_a => s_clken_cpu,
		i_write_a => s_video_ram_write_cpu,
		i_addr_a => s_video_ram_addr_cpu,
		i_data_a => s_video_ram_din_cpu,
		o_data_a => s_video_ram_dout_cpu,

		-- Read only port for video controller
		i_clock_b => s_clock_80mhz,
		i_clken_b => s_clken_40mhz,
		i_write_b => '0',
		i_addr_b => s_video_ram_addr,
		i_data_b => (others => '0'),
		o_data_b => s_video_ram_data
	);

	-- Main RAM (48K)
	ram : entity work.RamInferred	
	GENERIC MAP
	(
		p_addr_width => 15
	)
	PORT MAP
	(
		-- Read/Write port for CPU
		i_clock => s_clock_80mhz,
		i_clken => s_clken_cpu,
		i_write => s_ram_write_cpu,
		i_write_mask => "0",
		i_addr => s_ram_addr_cpu,
		i_data => s_ram_din_cpu,
		o_data => s_ram_dout_cpu
	);

	-- Model 1 ROM (12K)
	rom : entity work.Trs80Level2Rom
	PORT MAP
	(
		i_clock => s_clock_80mhz,
		i_addr => s_rom_addr_cpu,
		o_dout => s_rom_dout_cpu
	);

	-- PS2 Keyboard Controller
	keyboardController : entity work.PS2KeyboardController
	GENERIC MAP
	(
		p_clock_hz => 80_000_000 
	)
	PORT MAP
	(
		i_clock => s_clock_80mhz,
		i_reset => s_reset,
		io_ps2_clock => io_ps2_clock,
		io_ps2_data => io_ps2_data,
		o_key_scancode => s_key_scancode,
		o_key_extended => s_key_extended,
		o_key_released => s_key_release,
		o_key_available => s_key_available
	);

	-- TRS80 Keyboard Switches
	keyboardMemoryMap : entity work.Trs80KeyMemoryMap
	PORT MAP
	(
		i_clock => s_clock_80mhz,
		i_reset => s_reset,
		i_key_scancode => s_key_scancode,
		i_key_extended => s_key_extended,
		i_key_released => s_key_release,
		i_key_available => s_key_available,
		i_typing_mode => i_switch_typing_mode,
		i_addr => s_cpu_addr(7 downto 0),
		o_data => s_key_dout_cpu
	);

	-- CPU
	cpu: entity work.T80se 
	GENERIC MAP
	(
		Mode 	=> 0,		-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write => 1,		-- 0 => WR_n active in T3, /=0 => WR_n active in T2
		IOWait 	=> 1		-- 0 => Single cycle I/O, 1 => Std I/O cycle
	)
	PORT MAP
	(
		RESET_n => s_reset_n, 
		CLK_n => s_clock_80mhz,
		CLKEN => s_clken_cpu,
		A => s_cpu_addr,
		DI => s_cpu_din,
		DO => s_cpu_dout,
		MREQ_n => s_cpu_mreq_n,
		IORQ_n => s_cpu_iorq_n,
		RD_n => s_cpu_rd_n,
		WR_n => s_cpu_wr_n,
		WAIT_n => s_cpu_wait_n,
		INT_n => '1',
		NMI_n => '1',
		BUSRQ_n => '1',
		M1_n => open,
		RFSH_n => open,
		HALT_n => open,
		BUSAK_n => open
	);

	-- Decode I/O control signals from cpu
	s_mem_rd <= '1' when (s_cpu_mreq_n = '0' and s_cpu_iorq_n = '1' and s_cpu_rd_n = '0') else '0';
	s_mem_wr <= '1' when (s_cpu_mreq_n = '0' and s_cpu_iorq_n = '1' and s_cpu_wr_n = '0') else '0';
	s_port_rd <= '1' when (s_cpu_iorq_n = '0' and s_cpu_mreq_n = '1' and s_cpu_rd_n = '0') else '0';
	s_port_wr <= '1' when (s_cpu_iorq_n = '0' and s_cpu_mreq_n = '1' and s_cpu_wr_n = '0') else '0';

	s_is_cas_port <= '1' when (s_cpu_addr(7 downto 0) = x"FF") else '0';
	s_is_trisstick_port <= '1' when (s_cpu_addr(7 downto 0) = x"13") else '0';

	-- Memory range mapping
	memmap : process(s_cpu_addr)
	begin
		s_is_rom_range <= '0';
		s_is_vram_range <= '0';
		s_is_ram_range <= '0';
		s_is_keyboard_range <= '0';

		if s_cpu_addr(15 downto 14) /= "00" then
			-- RAM 0x4000 -> 0x7FFF
			s_is_ram_range <= '1';
		elsif s_cpu_addr(15 downto 10) = "001111" then
			-- Video RAM 0x3C00 -> 0x3FFF
			s_is_vram_range <= '1';
		elsif s_cpu_addr(15 downto 10) = "001110" then
			-- Keyboard 0x3800 -> 0x3BFF (shadowed 4 times)
			s_is_keyboard_range <= '1';
		elsif s_cpu_addr(15 downto 12) = "0000" or s_cpu_addr(15 downto 12) = "0001" or s_cpu_addr(15 downto 12) = "0010" then
			-- ROM 0x0000 -> 0x2FFF
			s_is_rom_range <= '1';
		end if;
	end process;

	-- Generate addresses and write flags
	s_video_ram_addr_cpu <= s_cpu_addr(9 downto 0);
	s_video_ram_write_cpu <= s_mem_wr and s_is_vram_range;
	s_video_ram_din_cpu <= s_cpu_dout;

	s_ram_addr_cpu <= s_cpu_addr(14 downto 0);
	s_ram_write_cpu <= s_mem_wr and s_is_ram_range;
	s_ram_din_cpu <= s_cpu_dout;
	s_rom_addr_cpu <= s_cpu_addr(13 downto 0);

	s_cpu_wait_n <= '1';

	cpu_data_in : process(s_mem_rd, 
							s_is_rom_range, s_rom_dout_cpu, 
							s_is_ram_range, s_ram_dout_cpu, 
							s_is_vram_range, s_video_ram_dout_cpu,
							s_is_keyboard_Range, s_key_dout_cpu,
							s_port_rd,
							s_is_cas_port, s_cas_audio_in, s_cas_audio_in_edge,
							s_is_trisstick_port, s_psx_buttons
							)
	begin

		s_cpu_din <= x"FF";

		if s_mem_rd = '1' then
			if s_is_rom_range = '1' then
				s_cpu_din <= s_rom_dout_cpu;
			elsif s_is_ram_range = '1' then
				s_cpu_din <= s_ram_dout_cpu;
			elsif s_is_keyboard_range = '1' then
				s_cpu_din <= s_key_dout_cpu;
			elsif s_is_vram_range = '1' then
				s_cpu_din <= s_video_ram_dout_cpu;
			end if;
		elsif s_port_rd = '1' then
			if s_is_cas_port = '1' then
				s_cpu_din <= s_cas_audio_in_edge & "00000" & s_cas_audio_in;
			end if;
			if s_is_trisstick_port = '1' then
				s_cpu_din <= "111" & 
					not s_psx_buttons(14) & 	-- X
					not s_psx_buttons(5) &		-- Right 
					not s_psx_buttons(7) &		-- Left
					not s_psx_buttons(6) & 		-- Down
					not s_psx_buttons(4);		-- Up
			end if;
		end if;

	end process;

	o_leds <= 
		s_sd_status(4)				-- SD Init
		 & s_sd_status(7)			-- SDHC
		 & s_sd_status(2)			-- SD Write
		 & s_sd_status(1)			-- SD Read
		 & (s_cas_audio_out(0) or  s_cas_audio_out(1))
		 & (s_cas_audio_in(0) or s_cas_audio_in(1))
		 & s_recording
		 & s_playing_or_recording;


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

	s_seven_seg_value <= s_selected_Tape when i_button_left = '1' else s_sd_last_block_number(11 downto 0);

	sdcard : entity work.SDCardController
	generic map
	(
		p_clock_div_800khz => 100,
		p_clock_div_50mhz => 2
	)
	port map
	(
		-- Clocking
		i_reset => s_reset,
		i_clock => s_clock_80mhz,

		-- SD Card Signals
		o_ss_n => o_sd_ss_n,
		o_mosi => o_sd_mosi,
		i_miso => i_sd_miso,
		o_sclk => o_sd_sclk,

		-- Status signals
		o_status => s_sd_status,

		-- Operation
		i_op_write => s_sd_op_wr,
		i_op_cmd => s_sd_op_cmd,
		i_op_block_number => s_sd_op_block_number,

		o_last_block_number => s_sd_last_block_number,

		-- DMA access
		o_data_start => open,
		o_data_cycle => s_sd_dcycle,
		i_data => s_sd_din,
		o_data => s_sd_dout
	);

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

	-- Debounced all buttons
	s_buttons_unbounced <= i_button_down & i_button_up & i_button_right;
	s_buttons_trigger <= (s_buttons_edges and not s_buttons_debounced) or s_media_keys;
	s_button_start <= s_cas_auto_start or (s_buttons_trigger(0) and not s_playing_or_recording);
	s_button_stop <= s_cas_auto_stop or (s_buttons_trigger(0) and s_playing_or_recording);
	s_button_record <= not i_button_left or s_cas_auto_record;

	-- Also map, media keys
	s_key_extended_press <= s_key_available and not s_key_release and s_key_extended;
	s_media_key_play <= '1' when s_key_extended_press = '1' and s_key_scancode = "0110100" else '0';
	s_media_key_next <= '1' when s_key_extended_press = '1' and s_key_scancode = "1001101" else '0';
	s_media_key_prev <= '1' when s_key_extended_press = '1' and s_key_scancode = "0010101" else '0';
	s_media_keys <= s_media_key_prev & s_media_key_next & s_media_key_play;


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
		o_audio => s_cas_audio_in,
		i_audio => s_cas_audio_out(0)
	);

	cas_edge_detect : process(s_clock_80mhz)
	begin
		if rising_edge(s_clock_80mhz) then
			if s_reset = '1' then
				s_cas_audio_in_edge <= '0';
				s_cas_prev_audio_in <= "00";
				s_cas_audio_out <= "00";
				s_cas_motor <= '0';
				s_wide_video_mode <= '0';
			else

				-- Detect edge
				s_cas_prev_audio_in <= s_cas_audio_in;
				if s_cas_prev_audio_in /= s_cas_audio_in then 
					s_cas_audio_in_edge <= '1';
				end if;

				-- Clear flag
				if s_port_wr = '1' and s_is_cas_port='1' and s_clken_cpu='1' then
					s_cas_audio_in_edge <= s_cpu_dout(7);
					s_cas_audio_out <= s_cpu_dout(1 downto 0);
					s_cas_motor <= s_cpu_dout(2);
					s_wide_video_mode <= s_cpu_dout(3);
				end if;

			end if;
		end if;
	end process;

	-- Output audio on both channels
	s_audio <=  s_cas_audio_out(0) xor s_cas_audio_in(0)	-- all cass i/o 
				when i_switch_cas_audio = '1' else
				s_cas_audio_out(0) and not s_cas_motor;	    -- only cas out when motor off
	o_audio <= s_audio & s_audio;

	-- Cassette auto start/stop
	cas_auto : entity work.Trs80AutoCassette
	generic map
	(
		p_clken_hz => 1_774_000
	)
	port map
	(
		i_clock => s_clock_80mhz,
		i_clken => s_clken_cpu,
		i_reset => s_reset,
		i_motor => s_cas_motor_monitored,
		i_audio => s_cas_audio_out(0),
		o_start => s_cas_auto_start,
		o_record => s_cas_auto_record,
		o_stop => s_cas_auto_stop
	);

	-- When auto cassette mode turned off, hide the motor signal from the detector
	s_cas_motor_monitored <= s_cas_motor and i_switch_auto_cas;

	psxhost : entity work.PsxControllerHost
	generic map
	(
		p_clken_hz => 80_000_000,
		p_poll_hz => 60
	)
	port map
	( 
		i_clock => s_clock_80mhz,
		i_clken => '1',
		i_reset => s_reset,
		o_psx_att => o_psx_att,
		o_psx_clock => o_psx_clock,
		o_psx_hoci => o_psx_hoci,
		i_psx_hico => i_psx_hico,
		i_psx_ack => i_psx_ack,
		o_connected => open,
		o_buttons => s_psx_buttons
	);

end Behavioral;

