library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity top is
port 
(
	-- Clocking
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;

	o_uart_debug : out std_logic;
	
	i_switch_run : in std_logic;

	-- LEDs
	o_leds : out std_logic_vector(7 downto 0);

	-- Seven segment
	o_seven_segment : out std_logic_vector(7 downto 0);
	o_seven_segment_en : out std_logic_vector(2 downto 0);

	-- Audio
	o_audio : out std_logic_vector(1 downto 0);

	-- VGA
	o_horz_sync : out std_logic;
	o_vert_sync : out std_logic;
	o_red : out std_logic_vector(2 downto 0);
	o_green : out std_logic_vector(2 downto 0);
	o_blue : out std_logic_vector(2 downto 1);

	-- PS2 Keyboard
	io_ps2_clock : inout std_logic;
	io_ps2_data : inout std_logic;

	-- Serial I/O
	o_uart_tx : out std_logic;
	i_uart_rx : in std_logic;

	-- SD Card
	o_sd_mosi : out std_logic;
	i_sd_miso : in std_logic;
	o_sd_ss_n : out std_logic;
	o_sd_sclk : out std_logic;

	-- Folded memory controller bus
	mcb_xcl : out std_logic_vector(1 downto 0);
	mcb_xtx : out std_logic_vector(20 downto 0);
	mcb_xtr : inout  std_logic_vector(18 downto 0);

	-- PSX Signals
	o_psx_att : out std_logic;
	o_psx_clock : out std_logic;
	o_psx_hoci : out std_logic;
	i_psx_hico : in std_logic;
	i_psx_ack : in std_logic	
);
end top;

architecture Behavioral of top is

	-- Clocking
	signal s_reset : std_logic;
	signal s_clock_100mhz : std_logic;
	signal s_clock_80mhz : std_logic;
	signal s_clken_cpu : std_logic;

	-- LPDDR
    signal mig_xtx_p0 : std_logic_vector(80 downto 0);
    signal mig_xrx_p0 : std_logic_vector(56 downto 0);
    signal s_sri_addr : std_logic_vector(29 downto 0);
	signal s_calib_done : std_logic;

	-- RAM
	signal s_ram_cs : std_logic;
	signal s_ram_rd : std_logic;
	signal s_ram_wr : std_logic;
	signal s_ram_din : std_logic_vector(7 downto 0);
	signal s_ram_dout : std_logic_vector(7 downto 0);
	signal s_ram_wait : std_logic;
	signal s_ram_addr : std_logic_vector(17 downto 0);

	-- Audio
	signal s_audio : std_logic;

	signal s_seven_seg_value : std_logic_vector(11 downto 0);
	signal s_debug : std_logic_vector(31 downto 0);

	signal s_red : std_logic_vector(2 downto 0);
	signal s_green : std_logic_vector(2 downto 0);
	signal s_blue : std_logic_vector(2 downto 0);

begin


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

	s_seven_seg_value <= s_debug(11 downto 0);

	------------------------- Clocking -------------------------

	-- Reset signal
	s_reset <= not i_button_b or not s_calib_done;

	-- Clock Buffer
    clk_ibufg : IBUFG
    port map
    (
		I => i_clock_100mhz,
		O => s_clock_100mhz
	);

	-- Digital Clock Manager
	dcm : entity work.ClockDCM
	port map
	(
		CLK_IN_100MHz => s_clock_100mhz,
		CLK_OUT_100MHz => open,
		CLK_OUT_80MHz => s_clock_80mhz
	);


	------------------------- LPDDR RAM Controller -------------------------

	lpddr : entity work.MimasSinglePortSDRAM
	generic map
	(
		C3_INPUT_CLK_TYPE => "IBUFG"
	)
	port map
	(
		mcb_xtr => mcb_xtr,
		mcb_xtx => mcb_xtx,
		mcb_xcl => mcb_xcl,

		i_sys_clk       => s_clock_100mhz,
		i_sys_rst_n     => '0',
		o_calib_done    => s_calib_done,
		o_clk0          => open,
		o_rst0          => open,

		mig_xtx_p0 => mig_xtx_p0,
		mig_xrx_p0 => mig_xrx_p0
	);
	
	------------------------- Audio Output -------------------------

	o_audio <= s_audio & s_audio;

	-- Simple RAM Interface
	sri : entity work.SimpleRamInterface
	port map
	( 
		i_clock => s_clock_80mhz,
		i_reset => s_reset,
		i_rd => s_ram_rd,
		i_wr => s_ram_wr,
		i_addr => s_sri_addr,
		i_data => s_ram_din,
		o_data => s_ram_dout,
		o_wait => s_ram_wait,
		mig_xtx => mig_xtx_p0,
		mig_xrx => mig_xrx_p0
	);


	s_sri_addr <= "000000000000" & s_ram_addr;

	trs80 : entity work.Trs80Model1Core
	generic map
	(
		p_enable_video_controller => true,
		p_enable_keyboard => true,
		p_enable_cassette_player => true,
		p_enable_trisstick => true
	)
	port map
	(
		o_debug => s_debug,
		o_uart_debug => o_uart_debug,
		i_clock_80mhz => s_clock_80mhz,
		i_reset => s_reset,
		o_clken_cpu => s_clken_cpu,
		i_switch_run => i_switch_run,
		o_status => o_leds,
		o_ram_cs => s_ram_cs,
		o_ram_addr => s_ram_addr,
		o_ram_din => s_ram_din,
		i_ram_dout => s_ram_dout,
		o_ram_rd => s_ram_rd,
		o_ram_wr => s_ram_wr,
		i_ram_wait => s_ram_wait,
		o_horz_sync => o_horz_sync,
		o_vert_sync => o_vert_sync,
		o_red => s_red,
		o_green => s_green,
		o_blue => s_blue,
		io_ps2_clock => io_ps2_clock,
		io_ps2_data => io_ps2_data,
		o_audio => s_audio,
		o_uart_tx => o_uart_tx,
		i_uart_rx => i_uart_rx,
		o_sd_mosi => o_sd_mosi,
		i_sd_miso => i_sd_miso,
		o_sd_ss_n => o_sd_ss_n,
		o_sd_sclk => o_sd_sclk,
		o_psx_att => o_psx_att,
		o_psx_clock => o_psx_clock,
		o_psx_hoci => o_psx_hoci,
		i_psx_hico => i_psx_hico,
		i_psx_ack => i_psx_ack
	);

	o_red <= s_red;
	o_green <= s_green;
	o_blue <= s_blue(2 downto 1);
	
end Behavioral;

