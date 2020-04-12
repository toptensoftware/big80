--------------------------------------------------------------------------
--
-- Trs80Model1Core
--
-- Implements a TRS80 Model 1
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.Trs80VirtualKeyCodes.ALL;

entity Trs80Model1Core is
generic
(
	p_enable_video_controller : boolean := true;
	p_enable_keyboard : boolean := true;
	p_enable_cassette_player : boolean := true;
	p_enable_trisstick : boolean := true;
	p_enable_syscon_serial : boolean := true
);
port
(
	-- Debug
	o_uart_debug : out std_logic;

    -- Control
    i_clock_80mhz : in std_logic;                   -- Clock
    i_reset : in std_logic;                         -- Reset (synchronous, active high)
	o_clken_cpu : out std_logic;					-- Clock enable for the CPU
	i_switch_run : in std_logic;

	-- Status indicators
	o_status : out std_logic_vector(7 downto 0);
	o_debug : out std_logic_vector(31 downto 0);

	-- External RAM (128K required)
	o_ram_cs : out std_logic;
	o_ram_addr : out std_logic_vector(16 downto 0);
	o_ram_din : out std_logic_vector(7 downto 0);
	i_ram_dout : in std_logic_vector(7 downto 0);
	o_ram_rd : out std_logic;
	o_ram_wr : out std_logic;
	i_ram_wait : in std_logic;
        
	-- VGA
	o_horz_sync : out std_logic;
	o_vert_sync : out std_logic;
	o_red : out std_logic_vector(2 downto 0);
	o_green : out std_logic_vector(2 downto 0);
	o_blue : out std_logic_vector(2 downto 1);

	-- PS2 Keyboard
	io_ps2_clock : inout std_logic;
	io_ps2_data : inout std_logic;

	-- Audio 
	o_audio : out std_logic;

	-- Serial I/O
	o_uart_tx : out std_logic;
	i_uart_rx : in std_logic;

	-- SD Card
	o_sd_mosi : out std_logic;
	i_sd_miso : in std_logic;
	o_sd_ss_n : out std_logic;
	o_sd_sclk : out std_logic;

	-- Playstation Controller
	o_psx_att : out std_logic;
	o_psx_clock : out std_logic;
	o_psx_hoci : out std_logic;
	i_psx_hico : in std_logic;
	i_psx_ack : in std_logic
);
end Trs80Model1Core;
 
architecture behavior of Trs80Model1Core is 

	signal s_logic_capture : std_logic_vector(39 downto 0);
	signal s_pc : std_logic_vector(15 downto 0);
	signal s_logic_capture_trigger : std_logic;

	-- Clocking
	signal s_reset : std_logic;
	signal s_reset_n : std_logic;
	signal s_soft_reset : integer range 0 to 15 := 0;
	signal s_soft_reset_request : std_logic;
	signal s_clken_40mhz : std_logic;
	signal s_clken_cpu_normal : std_logic;
	signal s_clken_cpu : std_logic;
	signal s_turbo_mode : std_logic;

	-- Switches
	signal s_is_syscon_options_port : std_logic;
	signal s_options : std_logic_vector(5 downto 0) := (others => '1');
	signal s_option_turbo_tape : std_logic;
	signal s_option_typing_mode : std_logic;
	signal s_option_green_screen : std_logic;
	signal s_option_no_scan_lines : std_logic;
	signal s_option_cas_audio : std_logic;
	signal s_option_auto_cas : std_logic;

	-- SD Card Controller
	signal s_sd_status : std_logic_vector(7 downto 0);
	signal s_sd_last_block_number : std_logic_vector(31 downto 0);

	signal s_sd_status_a : std_logic_vector(7 downto 0);
	signal s_sd_op_write_a : std_logic;
	signal s_sd_op_cmd_a : std_logic_vector(1 downto 0);
	signal s_sd_op_block_number_a : std_logic_vector(31 downto 0);
	signal s_sd_data_start_a : std_logic;
	signal s_sd_data_cycle_a : std_logic;
	signal s_sd_din_a : std_logic_vector(7 downto 0);
	signal s_sd_dout_a : std_logic_vector(7 downto 0);

	signal s_sd_status_b : std_logic_vector(7 downto 0);
	signal s_sd_op_write_b : std_logic;
	signal s_sd_op_cmd_b : std_logic_vector(1 downto 0);
	signal s_sd_op_block_number_b : std_logic_vector(31 downto 0);
	signal s_sd_data_start_b : std_logic;
	signal s_sd_data_cycle_b : std_logic;
	signal s_sd_din_b : std_logic_vector(7 downto 0);
	signal s_sd_dout_b : std_logic_vector(7 downto 0);

	-- CPU
	signal s_cpu_addr : std_logic_vector(15 downto 0);
	signal s_cpu_din : std_logic_vector(7 downto 0);
	signal s_cpu_dout : std_logic_vector(7 downto 0);
	signal s_cpu_mreq_n : std_logic;
	signal s_cpu_iorq_n : std_logic;
	signal s_cpu_rd_n : std_logic;
	signal s_cpu_wr_n : std_logic;
	signal s_cpu_wait_n : std_logic;
	signal s_cpu_nmi_n : std_logic;
	signal s_cpu_m1_n : std_logic;

	-- Memory/Port Mapping
	signal s_mem_rd : std_logic;
	signal s_mem_wr : std_logic;
	signal s_mem_rd_rising_edge : std_logic;
	signal s_mem_wr_rising_edge : std_logic;
	signal s_port_rd : std_logic;
	signal s_port_wr : std_logic;
	signal s_port_wr_rising_edge : std_logic;
	signal s_port_rd_falling_edge : std_logic;

	-- Address mapping
	signal s_is_apm_pagebank_port : std_logic;
	signal s_is_apm_enable_port : std_logic;
	signal s_apm_pagebank_enabled : std_logic;
	signal s_apm_videobank_enabled : std_logic;
	signal s_apm_bootmode : std_logic := '1';
	signal s_apm_pagebank : std_logic_vector(7 downto 0);

	-- Boot ROM.  (Actually it's a writeable RAM but hey... )
	signal s_is_bootrom_range : std_logic;
	signal s_bootrom_addr : std_logic_vector(14 downto 0);
	signal s_bootrom_dout : std_logic_vector(7 downto 0);
	signal s_bootrom_din : std_logic_vector(7 downto 0);
	signal s_bootrom_write : std_logic;

	-- Interrupt Controller
	signal s_is_syscon_ic_port : std_logic;
	signal s_syscon_ic_cpu_din : std_logic_vector(7 downto 0);
	signal s_irqs : std_logic_vector(4 downto 0);

	-- Video RAM
	signal s_is_vram_range : std_logic;
	signal s_vram_write_cpu : std_logic;
	signal s_vram_addr_cpu : std_logic_vector(9 downto 0);
	signal s_vram_din_cpu : std_logic_vector(7 downto 0);
	signal s_vram_dout_cpu : std_logic_vector(7 downto 0);

	-- ROM
	signal s_is_rom_range : std_logic;

	-- RAM
	signal s_is_ram_range : std_logic;

	-- Video Controller
	signal s_blank : std_logic;
	signal s_horz_pos : integer range -2048 to 2047;
	signal s_vert_pos : integer range -2048 to 2047;
	signal s_vram_addr : std_logic_vector(9 downto 0);
	signal s_vram_data : std_logic_vector(7 downto 0);
	signal s_char_rom_addr : std_logic_vector(10 downto 0);
	signal s_char_rom_data : std_logic_vector(5 downto 0);
	signal s_pixel : std_logic;
	signal s_line_rep : integer range 0 to 2;
	signal s_trs80_red : std_logic_vector(2 downto 0);
	signal s_trs80_green : std_logic_vector(2 downto 0);
	signal s_trs80_blue : std_logic_vector(2 downto 1);

	-- Keyboard Controller
	signal s_is_keyboard_range : std_logic;
	signal s_key_scancode : std_logic_vector(7 downto 0);
	signal s_key_release : std_logic;
	signal s_key_available : std_logic;
	signal s_key_switches : std_logic_vector(63 downto 0);
	signal s_key_dout_cpu : std_logic_vector(7 downto 0);

	-- Syscon Keyboard
	signal s_is_other_key : std_logic;
	signal s_key_modifiers : std_logic_vector(1 downto 0);
	signal s_all_keys : std_logic;
	signal s_is_syscon_keyboard_port : std_logic;
	signal s_syscon_keyboard_port_rd_falling_edge : std_logic;
	signal s_syscon_keyboard_cpu_din : std_logic_vector(7 downto 0);

	-- Media Keys
	signal s_key_press : std_logic;

	-- Cassette Player
	signal s_is_syscon_cas_port : std_logic;			-- x"C?"
	signal s_is_syscon_cas_cmdstat_port : std_logic;	-- x"C0"
	signal s_is_syscon_cas_data_port : std_logic;		-- x"C1"
	signal s_clken_cassette : std_logic;
	signal s_is_cas_port : std_logic;
	signal s_cas_prev_audio_in : std_logic_vector(1 downto 0);
	signal s_cas_audio_in : std_logic_vector(1 downto 0);
	signal s_cas_audio_out : std_logic_vector(1 downto 0);
	signal s_cas_audio_in_edge : std_logic;
	signal s_cas_motor : std_logic;
	signal s_wide_video_mode : std_logic;

	signal s_cas_command_play : std_logic;
	signal s_cas_command_record : std_logic;
	signal s_cas_command_stop : std_logic;
	signal s_cas_status_playing : std_logic;
	signal s_cas_status_recording : std_logic;
	signal s_cas_status_need_block_number : std_logic;
	signal s_cas_block_number : std_logic_vector(31 downto 0);
	signal s_cas_block_number_load : std_logic;

	-- Syscon cas port
	signal s_syscon_cas_play : std_logic;
	signal s_syscon_cas_record : std_logic;
	signal s_syscon_cas_stop : std_logic;
	signal s_syscon_cas_block_number_load : std_logic;

	-- Auto cassette control
	signal s_cas_motor_monitored : std_logic;
	signal s_autocas_start : std_logic;
	signal s_autocas_record : std_logic;
	signal s_autocas_stop : std_logic;

	-- TrisStick
	signal s_is_trisstick_port : std_logic;
	signal s_psx_buttons : std_logic_vector(15 downto 0);

	-- Hijacked Mode
	signal s_hijacked : std_logic := '1';

	-- SysCon Serial
	signal s_is_syscon_serial_port : std_logic;
	signal s_syscon_serial_port_wr_rising_edge : std_logic;
	signal s_syscon_serial_port_rd_falling_edge : std_logic;
	signal s_syscon_serial_cpu_din : std_logic_vector(7 downto 0);

	-- SysCon Disk
	signal s_is_syscon_disk_port : std_logic;
	signal s_syscon_disk_port_wr_rising_edge : std_logic;
	signal s_syscon_disk_port_rd_falling_edge : std_logic;
	signal s_syscon_disk_cpu_din : std_logic_vector(7 downto 0);

	-- SysCon Video
	signal s_is_syscon_vram_char_range : std_logic;
	signal s_syscon_vram_char_write_cpu : std_logic;
	signal s_syscon_vram_char_addr_cpu : std_logic_vector(8 downto 0);
	signal s_syscon_vram_char_din_cpu : std_logic_vector(7 downto 0);
	signal s_syscon_vram_char_dout_cpu : std_logic_vector(7 downto 0);

	signal s_is_syscon_vram_color_range : std_logic;
	signal s_syscon_vram_color_write_cpu : std_logic;
	signal s_syscon_vram_color_addr_cpu : std_logic_vector(8 downto 0);
	signal s_syscon_vram_color_din_cpu : std_logic_vector(7 downto 0);
	signal s_syscon_vram_color_dout_cpu : std_logic_vector(7 downto 0);

	signal s_syscon_vram_addr : std_logic_vector(8 downto 0);
	signal s_syscon_vram_char : std_logic_vector(7 downto 0);
	signal s_syscon_vram_color : std_logic_vector(7 downto 0);

	signal s_syscon_red : std_logic_vector(1 downto 0);
	signal s_syscon_green : std_logic_vector(1 downto 0);
	signal s_syscon_blue : std_logic_vector(1 downto 0);
	signal s_syscon_transparent  : std_logic;
	signal s_syscon_show_video : std_logic;
	signal s_syscon_show_pixel  : std_logic;

begin

	
	
	------------------------- Clocking -------------------------

	-- Reset signal
	s_reset <= '1' when i_reset = '1' or s_soft_reset /= 0 else '0';
	s_reset_n <= not s_reset;

	-- Soft reset process
	soft_reset : process(i_clock_80mhz)
	begin		
		if rising_edge(i_clock_80mhz) then
			if s_key_press = '1' and s_key_scancode = "10110111" then
				s_soft_reset <= 15;
			end if;
			if s_soft_reset_request = '1' then
				s_soft_reset <= 15;
			end if;
			if s_soft_reset /= 0 then
				s_soft_reset <= s_soft_reset - 1;
			end if;
		end if;
	end process;

	-- Generate the 40Mhz clock enable
	process (i_clock_80mhz)
	begin
		if rising_edge(i_clock_80mhz) then
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
		i_clock => i_clock_80mhz,
		i_clken => '1',
		i_reset => s_reset,
		o_clken => s_clken_cpu_normal
	);


	s_clken_cpu <= 
		'0' when i_switch_run = '0' else 
		s_clken_40mhz when s_hijacked = '1' else
		s_clken_40mhz when s_turbo_mode = '1' else
		s_clken_cpu_normal;
	o_clken_cpu <= s_clken_cpu;
	s_turbo_mode <= s_cas_motor and s_option_turbo_tape;

	
	
	------------------------- CPU -------------------------

	cpu : entity work.T80se 
	GENERIC MAP
	(
		Mode 	=> 0,		-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write => 1,		-- 0 => WR_n active in T3, /=0 => WR_n active in T2
		IOWait 	=> 1		-- 0 => Single cycle I/O, 1 => Std I/O cycle
	)
	PORT MAP
	(
		RESET_n => s_reset_n, 
		CLK_n => i_clock_80mhz,
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
		NMI_n => s_cpu_nmi_n,
		BUSRQ_n => '1',
		M1_n => s_cpu_m1_n,
		RFSH_n => open,
		HALT_n => open,
		BUSAK_n => open
	);

	-- Generate wait
	s_cpu_wait_n <= not i_ram_wait;

	-- Decode I/O control signals from cpu
	s_mem_rd <= '1' when (s_cpu_mreq_n = '0' and s_cpu_iorq_n = '1' and s_cpu_rd_n = '0') else '0';
	s_mem_wr <= '1' when (s_cpu_mreq_n = '0' and s_cpu_iorq_n = '1' and s_cpu_wr_n = '0') else '0';
	s_port_rd <= '1' when (s_cpu_iorq_n = '0' and s_cpu_mreq_n = '1' and s_cpu_rd_n = '0') else '0';
	s_port_wr <= '1' when (s_cpu_iorq_n = '0' and s_cpu_mreq_n = '1' and s_cpu_wr_n = '0') else '0';

	-- Address Decoder
	cpu_addr_decoder : process(
			s_cpu_addr, 
			s_hijacked,
			s_apm_bootmode,
			s_apm_pagebank,
			s_apm_pagebank_enabled,
			s_apm_videobank_enabled
			)
	begin
		s_is_bootrom_range <= '0';
		s_is_syscon_vram_char_range <= '0';
		s_is_syscon_vram_color_range <= '0';
		s_is_rom_range <= '0';
		s_is_vram_range <= '0';
		s_is_ram_range <= '0';
		s_is_keyboard_range <= '0';

		if s_hijacked = '1' then
			if s_apm_bootmode = '1' and s_cpu_addr(15) = '0' then
				-- 0x0000 -> 0x6FFF
				s_is_bootrom_range <= '1';
			elsif s_apm_videobank_enabled = '1' and s_cpu_addr(15 downto 10) = "111111" then
				-- SysCon video at 0xFC00
				s_is_syscon_vram_char_range <= not s_cpu_addr(9);
				s_is_syscon_vram_color_range <= s_cpu_addr(9);
			else
				s_is_ram_range <= '1';
			end if;

			if s_cpu_addr(15 downto 10) = "111111" and s_apm_pagebank_enabled='1' then
				o_ram_addr <= s_apm_pagebank(6 downto 0) & s_cpu_addr(9 downto 0);
			else
				o_ram_addr <= '1' & s_cpu_addr;
			end if;
		else

			o_ram_addr <= '0' & s_cpu_addr;

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
				s_is_ram_range <= '1';
			end if;
		end if;
	end process;

	-- Multiplex data into CPU
	cpu_din_multiplexer : process(
						s_hijacked,
						s_mem_rd, 
							s_is_bootrom_range, s_bootrom_dout, 
							s_is_ram_range, i_ram_dout, 
							s_is_vram_range, s_vram_dout_cpu,
							s_is_keyboard_Range, s_key_dout_cpu,
							s_is_syscon_vram_char_range, s_syscon_vram_char_dout_cpu,
							s_is_syscon_vram_color_range, s_syscon_vram_color_dout_cpu,
						s_port_rd,
							s_is_cas_port, s_cas_audio_in, s_cas_audio_in_edge,
							s_is_trisstick_port, s_psx_buttons,
						    s_is_syscon_serial_port, s_syscon_serial_cpu_din,
						    s_is_syscon_disk_port, s_syscon_disk_cpu_din,
							s_is_syscon_options_port, s_options,
							s_is_syscon_ic_port , s_syscon_ic_cpu_din,
							s_is_apm_enable_port,
							s_is_apm_pagebank_port, 
							s_syscon_show_video, s_apm_pagebank, s_apm_pagebank_enabled, s_apm_videobank_enabled,
							s_apm_bootmode,
							s_all_keys,
							s_is_syscon_keyboard_port,
							s_syscon_keyboard_cpu_din,
							s_is_syscon_cas_cmdstat_port,
							s_cas_status_playing,
							s_cas_status_recording,
							s_cas_status_need_block_number
							)
	begin

		s_cpu_din <= x"FF";

		if s_mem_rd = '1' then

			if s_is_bootrom_range = '1' then
				s_cpu_din <= s_bootrom_dout;
			elsif s_is_ram_range = '1' then
				s_cpu_din <= i_ram_dout;
			elsif s_is_keyboard_range = '1' then
				s_cpu_din <= s_key_dout_cpu;
			elsif s_is_vram_range = '1' then
				s_cpu_din <= s_vram_dout_cpu;
			elsif s_is_syscon_vram_char_range = '1' then
				s_cpu_din <= s_syscon_vram_char_dout_cpu;
			elsif s_is_syscon_vram_color_range = '1' then
				s_cpu_din <= s_syscon_vram_color_dout_cpu;
			end if;

		elsif s_port_rd = '1' then

			if s_is_cas_port = '1' then

				s_cpu_din <= s_cas_audio_in_edge & "00000" & s_cas_audio_in;

			elsif s_is_trisstick_port = '1' then

				s_cpu_din <= "111" & 
					not s_psx_buttons(14) & 	-- X
					not s_psx_buttons(5) &		-- Right 
					not s_psx_buttons(7) &		-- Left
					not s_psx_buttons(6) & 		-- Down
					not s_psx_buttons(4);		-- Up

			-- SysCon Port reads
			elsif s_is_syscon_ic_port = '1' then
				s_cpu_din <= s_syscon_ic_cpu_din;
			elsif s_is_syscon_disk_port = '1' then 
				s_cpu_din <= s_syscon_disk_cpu_din;
			elsif s_is_syscon_serial_port = '1' then 
				s_cpu_din <= s_syscon_serial_cpu_din;
			elsif s_is_syscon_options_port = '1' then
				s_cpu_din <= "00" & s_options;
			elsif s_is_apm_pagebank_port = '1' then
				s_cpu_din <= s_apm_pagebank;
			elsif s_is_apm_enable_port = '1' then
				s_cpu_din <= "000" & s_all_keys & s_syscon_show_video & s_apm_pagebank_enabled & s_apm_bootmode & s_apm_videobank_enabled;
			elsif s_is_syscon_keyboard_port = '1' then
				s_cpu_din <= s_syscon_keyboard_cpu_din;
			elsif s_is_syscon_cas_cmdstat_port = '1' then
				s_cpu_din <= "00000" & s_cas_status_need_block_number & s_cas_status_recording & s_cas_status_playing;
			end if;

		end if;

	end process;

	-- Detect mem write rising edges
	mem_wr_rising_edge : entity work.EdgeDetector
	port map
	( 
		i_clock => i_clock_80mhz,
		i_clken => '1',
		i_reset => s_reset,
		i_signal => s_mem_wr,
		o_pulse => s_mem_wr_rising_edge
	);

	-- Detect mem read rising edges
	mem_rd_rising_edge : entity work.EdgeDetector
	port map
	( 
		i_clock => i_clock_80mhz,
		i_clken => '1',
		i_reset => s_reset,
		i_signal => s_mem_rd,
		o_pulse => s_mem_rd_rising_edge
	);

	-- Detect port write rising edges
	port_wr_rising_edge : entity work.EdgeDetector
	port map
	( 
		i_clock => i_clock_80mhz,
		i_clken => s_clken_cpu,
		i_reset => s_reset,
		i_signal => s_port_wr,
		o_pulse => s_port_wr_rising_edge
	);

	-- Detect port read falling edges
	port_rd_falling_edge : entity work.EdgeDetector
	generic map
	(
		p_falling_edge => true,
		p_rising_edge => false
	)
	port map
	( 
		i_clock => i_clock_80mhz,
		i_clken => s_clken_cpu,
		i_reset => s_reset,
		i_signal => s_port_rd,
		o_pulse => s_port_rd_falling_edge
	);


	
	------------------------- Address Mapping -------------------------

	s_is_apm_pagebank_port <= s_hijacked when s_cpu_addr(7 downto 0) = x"A1" else '0';
	s_is_apm_enable_port <= s_hijacked when s_cpu_addr(7 downto 0) = x"A2" else '0';

	addr_map : process(i_clock_80mhz)
	begin
		if rising_edge(i_clock_80mhz) then
			if s_reset = '1' then
				s_apm_pagebank <= (others => '0');
				s_apm_pagebank_enabled <= '0';
				s_apm_bootmode <= '1';
				s_soft_reset_request <= '0';
				s_syscon_show_video <= '0';
				s_all_keys <= '0';
			elsif s_clken_cpu = '1' then

				if s_port_wr = '1' then

					if s_is_apm_pagebank_port = '1' then
						s_apm_pagebank <= s_cpu_dout;
					end if;

					if s_is_apm_enable_port = '1' then
						s_apm_videobank_enabled <= s_cpu_dout(0);
						s_apm_bootmode <= s_cpu_dout(1);
						s_apm_pagebank_enabled <= s_cpu_dout(2);
						s_syscon_show_video <= s_cpu_dout(3);
						s_all_keys <= s_cpu_dout(4);
						s_soft_reset_request <= s_cpu_dout(7);
					end if;

				end if;
			end if;
		end if;
	end process;


	
	------------------------- SysCon Interrupt Controller -------------------------

	interrupt_controller : entity work.SysConInterruptController
	generic map
	(
		p_irq_count => 5
	)
	port map
	(
		i_reset => s_reset,
		i_clock => i_clock_80mhz,
		i_clken => s_clken_cpu,
		i_cpu_port_wr => s_port_wr,
		i_cpu_port_rd => s_port_rd,
		i_cpu_addr => s_cpu_addr,
		i_cpu_din => s_cpu_din,
		i_cpu_dout => s_cpu_dout,
		i_cpu_m1_n => s_cpu_m1_n,
		i_cpu_wait_n => s_cpu_wait_n,
		i_irqs => s_irqs,
		o_hijacked => s_hijacked,
		o_nmi_n => s_cpu_nmi_n,
		o_is_ic_port => s_is_syscon_ic_port,
		o_cpu_din => s_syscon_ic_cpu_din
	);

	
	
	------------------------- Options -------------------------

	s_is_syscon_options_port <= s_hijacked when s_cpu_addr(7 downto 0) = x"00" else '0';

	s_option_turbo_tape <= s_options(0);
	s_option_typing_mode <= s_options(1);
	s_option_green_screen <= s_options(2);
	s_option_no_scan_lines <= s_options(3);
	s_option_cas_audio <= s_options(4);
	s_option_auto_cas <= s_options(5);

	-- Listen for writes to options port
	options_port_handler : process(i_clock_80mhz)
	begin
		if rising_edge(i_clock_80mhz) then
			if s_reset = '1' then
				s_options <= (others => '1');
			elsif s_hijacked = '1' then

				if s_port_wr_rising_edge = '1' and s_is_syscon_options_port = '1' then
					s_options <= s_cpu_dout(5 downto 0);
				end if;

			end if;
		end if;
	end process;



	------------------------- SD Card Controller -------------------------

	sdcard : entity work.SDCardControllerDualPort
	generic map
	(
		p_clock_div_800khz => 100,
		p_clock_div_50mhz => 2
	)
	port map
	(
		i_reset => s_reset,
		i_clock => i_clock_80mhz,

		o_ss_n => o_sd_ss_n,
		o_mosi => o_sd_mosi,
		i_miso => i_sd_miso,
		o_sclk => o_sd_sclk,
		o_status => s_sd_status,
		o_last_block_number => s_sd_last_block_number,

		o_status_a => s_sd_status_a,
		i_op_write_a => s_sd_op_write_a,
		i_op_cmd_a => s_sd_op_cmd_a,
		i_op_block_number_a => s_sd_op_block_number_a,
		o_data_start_a => s_sd_data_start_a,
		o_data_cycle_a => s_sd_data_cycle_a,
		i_din_a => s_sd_din_a,
		o_dout_a => s_sd_dout_a,

		o_status_b => s_sd_status_b,
		i_op_write_b => s_sd_op_write_b,
		i_op_cmd_b => s_sd_op_cmd_b,
		i_op_block_number_b => s_sd_op_block_number_b,
		o_data_start_b => s_sd_data_start_b,
		o_data_cycle_b => s_sd_data_cycle_b,
		i_din_b => s_sd_din_b,
		o_dout_b => s_sd_dout_b
	);



	------------------------- Audio Output -------------------------

	o_audio <=  s_cas_audio_out(0) xor s_cas_audio_in(0)	-- all cass i/o 
				when s_option_cas_audio = '1' else
				s_cas_audio_out(0) and not s_cas_motor;	    -- only cas out when motor off



	------------------------- LED status indicators -------------------------

	o_debug <= s_cas_block_number;

	o_status <=
		s_sd_status(4)				-- SD Init
		 & s_sd_status(7)			-- SDHC
		 & s_sd_status(2)			-- SD Write
		 & s_sd_status(1)			-- SD Read
		 & (s_cas_audio_out(0) or  s_cas_audio_out(1))
		 & (s_cas_audio_in(0) or s_cas_audio_in(1))
		 & s_cas_status_recording
		 & s_cas_status_playing;



	------------------------- Video RAM -------------------------

	s_vram_addr_cpu <= s_cpu_addr(9 downto 0);
	s_vram_write_cpu <= s_mem_wr and s_is_vram_range;
	s_vram_din_cpu <= s_cpu_dout;

	vram : entity work.RamDualPortInferred	
	GENERIC MAP
	(
		p_addr_width => 10
	)
	PORT MAP
	(
		-- Read/Write port for CPU
		i_clock_a => i_clock_80mhz,
		i_clken_a => s_clken_cpu,
		i_write_a => s_vram_write_cpu,
		i_addr_a => s_vram_addr_cpu,
		i_din_a => s_vram_din_cpu,
		o_dout_a => s_vram_dout_cpu,

		-- Read only port for video controller
		i_clock_b => i_clock_80mhz,
		i_clken_b => s_clken_40mhz,
		i_write_b => '0',
		i_addr_b => s_vram_addr,
		i_din_b => (others => '0'),
		o_dout_b => s_vram_data
	);



	------------------------- ROM -------------------------

	-- Boot ROM is read-only from  0x0000 -> 0x5fff
	--             read-write from 0x6000 -> 0x7fff
	s_bootrom_addr <= s_cpu_addr(14 downto 0);
	s_bootrom_din <= s_cpu_dout;
	s_bootrom_write <= s_mem_wr and s_is_bootrom_range and s_cpu_addr(14) and s_cpu_addr(13);

	bootrom : entity work.BootRom
	PORT MAP
	(
		i_clock => i_clock_80mhz,
		i_write => s_bootrom_write,
		i_addr => s_bootrom_addr,
		o_dout => s_bootrom_dout,
		i_din => s_bootrom_din
	);

	
	
	------------------------- RAM -------------------------

	o_ram_din <= s_cpu_dout;
	o_ram_cs <= s_is_ram_range;
	o_ram_wr <= s_is_ram_range and s_mem_wr_rising_edge and not s_is_rom_range;
	o_ram_rd <= s_is_ram_range and s_mem_rd_rising_edge;



	------------------------- Video Controller -------------------------

	-- Combine trs80 and sys-con video
	s_syscon_show_pixel <= s_syscon_show_video and not s_syscon_transparent;
	o_red <= s_trs80_red when s_syscon_show_pixel = '0' else s_syscon_red & '0';
	o_green <= s_trs80_green when s_syscon_show_pixel = '0' else s_syscon_green & '0';
	o_blue <= s_trs80_blue when s_syscon_show_pixel = '0' else s_syscon_blue;

	without_video : if not p_enable_video_controller generate
		o_vert_sync <= '0';
		o_horz_sync <= '0';
		s_trs80_red <= (others => '0');
		s_trs80_green <= (others => '0');
		s_trs80_blue <= (others => '0');
		s_vram_addr <= (others => '0');
	end generate;

	with_video : if p_enable_video_controller generate

		-- Generate VGA timing signals for 800x600 @ 60Hz
		vga_timing : entity work.VGATiming800x600
		port map
		(
			i_clock => i_clock_80mhz,
			i_clken => s_clken_40mhz,
			i_reset => s_reset,
			o_vert_sync => o_vert_sync,
			o_horz_sync => o_horz_sync,
			o_horz_pos => s_horz_pos,
			o_vert_pos => s_vert_pos,
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
			i_clock => i_clock_80mhz,
			i_clken => s_clken_40mhz,
			i_reset => s_reset,
			i_horz_pos => s_horz_pos,
			i_vert_pos => s_vert_pos,
			i_wide_mode => s_wide_video_mode,
			o_vram_addr => s_vram_addr,
			i_vram_data => s_vram_data,
			o_char_rom_addr => s_char_rom_addr,
			i_char_rom_data => s_char_rom_data,
			o_pixel => s_pixel,
			o_line_rep => s_line_rep
		);

		-- Generate color
		color_gen : process(s_pixel, s_option_green_screen, s_option_no_scan_lines, s_line_rep)
		begin
			if s_option_green_screen = '1' then
				s_trs80_red <= "000";
				if s_option_no_scan_lines = '0' then
					if s_line_rep = 1 then
						s_trs80_green <= s_pixel & s_pixel & s_pixel;
					else
						s_trs80_green <= s_pixel & "0" & s_pixel;
					end if;
				else
					s_trs80_green <= s_pixel & s_pixel & s_pixel;
				end if;
				s_trs80_blue <= "00";
			else
				s_trs80_red <= "000";
				if s_option_no_scan_lines = '0' then
					if s_line_rep = 1 then
						s_trs80_red <= s_pixel & s_pixel & s_pixel;
						s_trs80_green <= s_pixel & "00";
					else
						s_trs80_red <= s_pixel & "0" & s_pixel;
						s_trs80_green <= "0" & s_pixel & "0";
					end if;
				else
					s_trs80_red <= s_pixel & s_pixel & s_pixel;
					s_trs80_green <= s_pixel & "00";
				end if;
				s_trs80_blue <= "00";
			end if;
		end process;


		-- TRS80 Character ROM
		charrom : entity work.Trs80CharRom
		port map
		(
			i_clock => i_clock_80mhz,
			i_addr => s_char_rom_addr,
			o_dout => s_char_rom_data
		);
	end generate;

	
	
	------------------------- Keyboard Controller -------------------------
	
	without_keyboard : if not p_enable_keyboard generate
		io_ps2_clock <= '1';
		io_ps2_data <= '1';
		s_key_dout_cpu <= (others => '0');
		s_key_scancode <= (others => '0');
		s_key_release <= '0';
		s_key_available <= '1';
		s_key_press <= '0';
	end generate;

	with_keyboard : if p_enable_keyboard generate

		keyboardController : entity work.PS2KeyboardController
		GENERIC MAP
		(
			p_clock_hz => 80_000_000 
		)
		PORT MAP
		(
			i_clock => i_clock_80mhz,
			i_reset => s_reset,
			io_ps2_clock => io_ps2_clock,
			io_ps2_data => io_ps2_data,
			o_key_scancode => s_key_scancode,
			o_key_released => s_key_release,
			o_key_available => s_key_available
		);

		-- TRS80 Keyboard Switches
		keyboardMemoryMap : entity work.Trs80KeyMemoryMap
		PORT MAP
		(
			i_clock => i_clock_80mhz,
			i_reset => s_reset,
			i_key_scancode => s_key_scancode,
			i_key_released => s_key_release,
			i_key_available => s_key_available,
			i_typing_mode => s_option_typing_mode,
			i_addr => s_cpu_addr(7 downto 0),
			o_data => s_key_dout_cpu,
			o_is_other_key => s_is_other_key,
			o_modifiers => s_key_modifiers,
			i_suppress_all_keys => s_all_keys
		);

		-- Media key mapping
		s_key_press <= s_key_available and not s_key_release;

		s_is_syscon_keyboard_port <= s_hijacked when s_cpu_addr(7 downto 4) = x"7" else '0';
		s_syscon_keyboard_port_rd_falling_edge <= s_is_syscon_keyboard_port and s_port_rd_falling_edge;

		-- SysCon Keyboard Controller
		e_SysConKeyboardController : entity work.SysConKeyboardController
		port map
		(
			i_reset => s_reset,
			i_clock => i_clock_80mhz,
			i_cpu_port_number => s_cpu_addr(0),
			i_cpu_port_rd_falling_edge => s_syscon_keyboard_port_rd_falling_edge,
			o_cpu_din => s_syscon_keyboard_cpu_din,
			o_irq => s_irqs(3),
			i_key_scancode => s_key_scancode,
			i_key_released => s_key_release,
			i_key_available => s_key_available,
			i_key_modifiers => s_key_modifiers,
			i_is_syscon_key => s_is_other_key,
			i_all_keys => s_all_keys
		);


	end generate;



	------------------------- Cassette Player -------------------------

	s_is_cas_port <= not s_hijacked when (s_cpu_addr(7 downto 0) = x"FF") else '0';

	without_cassette_player : if not p_enable_cassette_player generate
		s_cas_audio_out	<= (others => '0');
		s_cas_audio_in <= (others => '0');
		s_cas_motor <= '0';
		s_cas_motor_monitored <= '0';
		s_sd_op_write_a <= '0';
		s_sd_op_cmd_a <= (others => '0');
		s_sd_op_block_number_a <= (others => '0');
		s_sd_din_a <= (others => '0');
		s_cas_status_recording <= '0';
		s_cas_status_playing <= '0';
		s_cas_audio_in_edge <= '0';
		s_clken_cassette <= '0';
	end generate;

	with_cassette_player : if p_enable_cassette_player generate

		-- SysCon cassette port flags
	    s_is_syscon_cas_port <= s_hijacked when s_cpu_addr(7 downto 4) = x"C" else '0';
		s_is_syscon_cas_cmdstat_port <= s_is_syscon_cas_port and not s_cpu_addr(0);
		s_is_syscon_cas_data_port <= s_is_syscon_cas_port and s_cpu_addr(0);

		-- Disable cassette play/record when in hijacked mode
		s_clken_cassette <= s_clken_cpu and not s_hijacked and s_cpu_wait_n;

		-- Syscon cassette command port
		syscon_cas_cmd_port : process(i_clock_80mhz)
		begin
			if rising_edge(i_clock_80mhz) then
				if i_reset = '1' then 
					s_syscon_cas_play <= '0';
					s_syscon_cas_record <= '0';
					s_syscon_cas_stop <= '0';
					s_syscon_cas_block_number_load <= '0';
				elsif s_clken_cpu = '1' then
					s_syscon_cas_play <= '0';
					s_syscon_cas_record <= '0';
					s_syscon_cas_stop <= '0';
					s_syscon_cas_block_number_load <= '0';
					if s_is_syscon_cas_cmdstat_port = '1' and s_port_wr_rising_edge = '1' then
						s_syscon_cas_play <= s_cpu_dout(0);
						s_syscon_cas_record <= s_cpu_dout(1);
						s_syscon_cas_stop <= s_cpu_dout(2);
						s_syscon_cas_block_number_load <= s_cpu_dout(3);
					end if;
				end if;
			end if;
		end process;

		-- Syscon cassette data port (ie: load block number)
		syscon_cas_data_port : process(i_clock_80mhz)
		begin
			if rising_edge(i_clock_80mhz) then
				if i_reset = '1' then 
					s_cas_block_number <= (others => '0');
				elsif s_clken_cpu = '1' then
					if s_is_syscon_cas_data_port = '1' and s_port_wr_rising_edge = '1' then
						-- LSB first
						s_cas_block_number <= s_cpu_dout & s_cas_block_number(31 downto 8);
					end if;
				end if;
			end if;
		end process;

		-- Cassette Player
		player : entity work.Trs80CassetteController
		generic map
		(
			p_clken_hz => 1_774_000
		)
		port map
		(
			debug => open,
			i_clock => i_clock_80mhz,
			i_clken_cpu => s_clken_cpu,
			i_clken_audio => s_clken_cassette,
			i_reset => s_reset,
			i_command_play => s_cas_command_play,
			i_command_record => s_cas_command_record,
			i_command_stop => s_cas_command_stop,
			o_status_playing => s_cas_status_playing,
			o_status_recording => s_cas_status_recording,
			o_status_need_block_number => s_cas_status_need_block_number,
			o_irq => s_irqs(4),
			i_block_number => s_cas_block_number,
			i_block_number_load => s_cas_block_number_load,
			o_sd_op_wr => s_sd_op_write_a,
			o_sd_op_cmd => s_sd_op_cmd_a,
			o_sd_op_block_number => s_sd_op_block_number_a,
			i_sd_status => s_sd_status_a,
			i_sd_dcycle => s_sd_data_cycle_a,
			i_sd_data => s_sd_dout_a,
			o_sd_data => s_sd_din_a,
			o_audio => s_cas_audio_in,
			i_audio => s_cas_audio_out(0)
		);

		cas_edge_detect : process(i_clock_80mhz)
		begin
			if rising_edge(i_clock_80mhz) then
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

		-- Cassette auto start/stop
		cas_auto : entity work.Trs80AutoCassette
		generic map
		(
			p_clken_hz => 1_774_000
		)
		port map
		(
			i_clock => i_clock_80mhz,
			i_clken => s_clken_cpu,
			i_reset => s_reset,
			i_motor => s_cas_motor_monitored,
			i_audio => s_cas_audio_out(0),
			o_start => s_autocas_start,
			o_record => s_autocas_record,
			o_stop => s_autocas_stop
		);

		-- When auto cassette mode turned off, hide the motor signal from the detector
		s_cas_motor_monitored <= s_cas_motor and s_option_auto_cas;

		-- Generate cassette control commands
		s_cas_command_play <= (s_autocas_start and not s_autocas_record) or s_syscon_cas_play;
		s_cas_command_record <= (s_autocas_start and s_autocas_record) or s_syscon_cas_record;
		s_cas_command_stop <= s_autocas_stop or s_syscon_cas_stop;
		s_cas_block_number_load <= s_syscon_cas_block_number_load;
		
	end generate;

	
	
	------------------------- TrisStick -------------------------

	without_trisstick : if not p_enable_trisstick generate
		s_is_trisstick_port <= '0';
		s_psx_buttons <= (others => '0');
		o_psx_att <= '1';
		o_psx_clock <= '1';
		o_psx_hoci <= '1';
	end generate;

	with_trisstick : if p_enable_trisstick generate

		s_is_trisstick_port <= not s_hijacked when (s_cpu_addr(7 downto 0) = x"13") else '0';

		psxhost : entity work.PsxControllerHost
		generic map
		(
			p_clken_hz => 80_000_000,
			p_poll_hz => 60
		)
		port map
		( 
			i_clock => i_clock_80mhz,
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
	end generate;



	------------------------- SysCon Serial -------------------------

	w_serial : if not p_enable_syscon_serial generate
		s_is_syscon_serial_port <= '0';
		s_syscon_serial_port_wr_rising_edge <= '0';
		s_syscon_serial_port_rd_falling_edge <= '0';
		s_syscon_serial_cpu_din <= (others => '0');
		o_uart_tx <= '1';
	end generate;

	wo_serial : if p_enable_syscon_serial generate

		s_is_syscon_serial_port <= s_hijacked when s_cpu_addr(7 downto 4) = x"8" else '0';
		s_syscon_serial_port_wr_rising_edge <= s_is_syscon_serial_port and s_port_wr_rising_edge;
		s_syscon_serial_port_rd_falling_edge <= s_is_syscon_serial_port and s_port_rd_falling_edge;

		serial : entity work.SysConSerialPort
		port map
		(
			i_reset => s_reset,
			i_clock => i_clock_80mhz,
			i_cpu_port_number => s_cpu_addr(1 downto 0),
			i_cpu_port_wr_rising_pulse => s_syscon_serial_port_wr_rising_edge,
			i_cpu_port_rd_falling_edge => s_syscon_serial_port_rd_falling_edge,
			o_cpu_din => s_syscon_serial_cpu_din,
			i_cpu_dout => s_cpu_dout,
			o_irq_rx => s_irqs(0),
			o_irq_tx => s_irqs(1),
			o_uart_tx => o_uart_tx,
			i_uart_rx => i_uart_rx
		);

	end generate;



	------------------------- SysCon Disk Controller -------------------------

	s_is_syscon_disk_port <= s_hijacked when s_cpu_addr(7 downto 4) = x"9" else '0';
	s_syscon_disk_port_wr_rising_edge <= s_is_syscon_disk_port and s_port_wr_rising_edge;
	s_syscon_disk_port_rd_falling_edge <= s_is_syscon_disk_port and s_port_rd_falling_edge;

	syscon_disk : entity work.SysConDiskController
	port map
	(
		i_reset => s_reset,
		i_clock => i_clock_80mhz,
		i_cpu_port_number => s_cpu_addr(2 downto 0),
		i_cpu_port_wr_rising_edge => s_syscon_disk_port_wr_rising_edge,
		i_cpu_port_rd_falling_edge => s_syscon_disk_port_rd_falling_edge,
		o_cpu_din => s_syscon_disk_cpu_din,
		i_cpu_dout => s_cpu_dout,
		o_irq => s_irqs(2),
		i_sd_status => s_sd_status_b,
		o_sd_op_write => s_sd_op_write_b,
		o_sd_op_cmd => s_sd_op_cmd_b,
		o_sd_op_block_number => s_sd_op_block_number_b,
		i_sd_data_start => s_sd_data_start_b,
		i_sd_data_cycle => s_sd_data_cycle_b,
		o_sd_din => s_sd_din_b,
		i_sd_dout => s_sd_dout_b
	);



	------------------------- SysCon Video Controller -------------------------


	s_syscon_vram_char_addr_cpu <= s_cpu_addr(8 downto 0);
	s_syscon_vram_char_write_cpu <= s_mem_wr and s_is_syscon_vram_char_range;
	s_syscon_vram_char_din_cpu <= s_cpu_dout;

	syscon_vram_char : entity work.RamDualPortInferred	
	GENERIC MAP
	(
		p_addr_width => 9
	)
	PORT MAP
	(
		-- Read/Write port for CPU
		i_clock_a => i_clock_80mhz,
		i_clken_a => s_clken_cpu,
		i_write_a => s_syscon_vram_char_write_cpu,
		i_addr_a => s_syscon_vram_char_addr_cpu,
		i_din_a => s_syscon_vram_char_din_cpu,
		o_dout_a => s_syscon_vram_char_dout_cpu,

		-- Read only port for video controller
		i_clock_b => i_clock_80mhz,
		i_clken_b => s_clken_40mhz,
		i_write_b => '0',
		i_addr_b => s_syscon_vram_addr,
		i_din_b => (others => '0'),
		o_dout_b => s_syscon_vram_char
	);

	s_syscon_vram_color_addr_cpu <= s_cpu_addr(8 downto 0);
	s_syscon_vram_color_write_cpu <= s_mem_wr and s_is_syscon_vram_color_range;
	s_syscon_vram_color_din_cpu <= s_cpu_dout;

	syscon_vram_color : entity work.RamDualPortInferred	
	GENERIC MAP
	(
		p_addr_width => 9
	)
	PORT MAP
	(
		-- Read/Write port for CPU
		i_clock_a => i_clock_80mhz,
		i_clken_a => s_clken_cpu,
		i_write_a => s_syscon_vram_color_write_cpu,
		i_addr_a => s_syscon_vram_color_addr_cpu,
		i_din_a => s_syscon_vram_color_din_cpu,
		o_dout_a => s_syscon_vram_color_dout_cpu,

		-- Read only port for video controller
		i_clock_b => i_clock_80mhz,
		i_clken_b => s_clken_40mhz,
		i_write_b => '0',
		i_addr_b => s_syscon_vram_addr,
		i_din_b => (others => '0'),
		o_dout_b => s_syscon_vram_color
	);


	e_SysConVideoController : entity work.SysConVideoController
	port map
	(
		i_reset => s_reset,
		i_clock => i_clock_80mhz,
		i_clken => s_clken_40mhz,
		i_horz_pos => s_horz_pos,
		i_vert_pos => s_vert_pos,
		o_red => s_syscon_red,
		o_green => s_syscon_green,
		o_blue => s_syscon_blue,
		o_transparent => s_syscon_transparent,
		o_vram_addr => s_syscon_vram_addr,
		i_vram_char => s_syscon_vram_char,
		i_vram_color => s_syscon_vram_color
	);




--	------------------------- Logic Capture -------------------------
--
--	capture_pc : process(i_clock_80mhz)
--	begin
--		if rising_edge(i_clock_80mhz) then
--			if s_reset = '1' then
--				s_pc <= (others => '0');
--			elsif s_clken_cpu = '1' then
--				if s_cpu_m1_n = '0' then
--					s_pc <= s_cpu_addr;
--				end if;
--			end if;
--		end if;
--	end process;
--
--	s_logic_capture_trigger <= s_reset_n; -- '1' when s_pc = x"031A" else '0';
--
--	s_logic_capture <= 
--		s_cpu_addr &
--		s_cpu_din &
--		s_cpu_dout &
--		s_mem_rd &
--		s_mem_wr &
--		s_port_rd &
--		s_port_wr &
--		s_cpu_wait_n &
--		s_cpu_nmi_n &
--		s_cpu_m1_n &
--		s_hijacked;
--
--	e_LogicCapture : entity work.LogicCapture
--	generic map
--	(
--		p_clock_hz => 80_000_000,
--		p_baud => 115200,
--		p_bit_width => 40,
--		p_addr_width => 11
--	)
--	port map
--	(
--		i_clock => i_clock_80mhz,
--		i_clken => s_clken_cpu,
--		i_reset => s_reset,
--		i_trigger => s_logic_capture_trigger,
--		i_signals => s_logic_capture,
--		o_uart_tx => o_uart_debug
--	);

	o_uart_debug <= '1';

end;
