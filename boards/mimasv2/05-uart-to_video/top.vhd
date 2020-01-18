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
	i_uart_rx : in std_logic;
	o_leds : out std_logic_vector(7 downto 0)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_blank : std_logic;
	signal s_hpos : integer range -2048 to 2047;
	signal s_vpos : integer range -2048 to 2047;
	signal s_clock_80mhz : std_logic;
	signal s_clken_40mhz : std_logic;
    signal s_video_ram_addr : std_logic_vector(9 downto 0);
    signal s_video_ram_data : std_logic_vector(7 downto 0);
    signal s_char_rom_addr : std_logic_vector(10 downto 0);
    signal s_char_rom_data : std_logic_vector(5 downto 0);
	signal s_pixel : std_logic;

	signal s_video_ram_addr_uart : std_logic_vector(9 downto 0);
	signal s_video_ram_data_uart : std_logic_vector(7 downto 0);
	signal s_video_ram_write_uart : std_logic;

	signal s_uart_data : std_logic_vector(7 downto 0);
	signal s_uart_data_available : std_logic;
	signal s_uart_busy : std_logic;
	signal s_uart_error : std_logic;

	signal s_uart_have_received : std_logic;
	signal s_uart_have_error : std_logic;

begin

	-- Reset signal
	s_reset <= not i_button_b;

	dcm : entity work.ClockDCM
	port map
	(
		CLK_IN_100MHz => i_clock_100mhz,
		CLK_OUT_100MHz => open,
		CLK_OUT_80MHz => s_clock_80mhz
	);

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
		i_wide_mode => '0',
		o_video_ram_addr => s_video_ram_addr,
		i_video_ram_data => s_video_ram_data,
		o_char_rom_addr => s_char_rom_addr,
		i_char_rom_data => s_char_rom_data,
		o_pixel => s_pixel,
		o_line_rep => open
	);

	charrom : entity work.Trs80CharRom
	port map
	(
		clock => s_clock_80mhz,
		addr => s_char_rom_addr,
		dout => s_char_rom_data
	);

	-- Video RAM (1K)
	vram : entity work.RamDualPortInferred	
	GENERIC MAP
	(
		p_addr_width => 10
	)
	PORT MAP
	(
		-- Read/Write port for uart
		i_clock_a => s_clock_80mhz,
		i_clken_a => '1',
		i_write_a => s_video_ram_write_uart,
		i_addr_a => s_video_ram_addr_uart,
		i_data_a => s_video_ram_data_uart,
		o_data_a => open,

		-- Read only port for video controller
		i_clock_b => s_clock_80mhz,
		i_clken_b => s_clken_40mhz,
		i_write_b => '0',
		i_addr_b => s_video_ram_addr,
		i_data_b => (others => '0'),
		o_data_b => s_video_ram_data
	);

	
	o_red <= "000";
	o_green <= (s_pixel & s_pixel & s_pixel);
	o_blue <= "00";

	-- Uart
	uart_rx : entity work.UartRx
	generic map
	(
	    p_clock_hz => 80_000_000
	)
	port map
	(
		i_clock => s_clock_80mhz,
		i_reset => s_reset,
		i_uart_rx => i_uart_rx,
		o_data => s_uart_data,
		o_data_available => s_uart_data_available,
		o_busy => s_uart_busy,
		o_error => s_uart_error
	);

	-- Status
	o_leds <= i_uart_rx & "000" & s_uart_data_available & s_uart_busy & s_uart_have_error & s_uart_have_received;

	s_video_ram_write_uart <= s_uart_data_available;
	s_video_ram_data_uart <= s_uart_data;

	uart_handler : process(s_clock_80mhz)
	begin
		if rising_edge(s_clock_80mhz) then
			if s_reset = '1' then
				s_video_ram_addr_uart <= (others => '1');
				s_uart_have_received <= '0';
				s_uart_have_error <= '0';
			else
				if s_uart_data_available = '1' then 
					s_video_ram_addr_uart <= std_logic_vector(unsigned(s_video_ram_addr_uart)+1);
					s_uart_have_received <= '1';

					if s_uart_error = '1' then
						s_uart_have_error <= '1';
					end if;
				end if;
			end if;
		end if;

	end process;

end Behavioral;

