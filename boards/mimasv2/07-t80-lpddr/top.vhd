library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity top is
port 
(
	-- These signals must match what's in the .ucf file
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;
	o_leds : out std_logic_vector(7 downto 0);
	o_seven_segment : out std_logic_vector(7 downto 0);
	o_seven_segment_en : out std_logic_vector(2 downto 0);

	-- UART
	o_uart_tx : out std_logic;

	-- Folded memory controller bus
	mcb_xcl : out std_logic_vector(1 downto 0);
	mcb_xtx : out std_logic_vector(20 downto 0);
	mcb_xtr : inout  std_logic_vector(18 downto 0)
);
end top;

architecture Behavioral of top is
	-- Reset and clocking
	signal s_reset : std_logic;
	signal s_reset_n : std_logic;
	signal s_cpu_reset_n : std_logic;
	signal s_clock_100mhz : std_logic;
	signal s_clock_80mhz : std_logic;
	signal s_clken_cpu : std_logic;

	-- RAM
	signal s_ram_write : std_logic;
	signal s_ram_addr : std_logic_vector(29 downto 0);
	signal s_ram_din : std_logic_vector(7 downto 0);
	signal s_ram_dout : std_logic_vector(7 downto 0);
	signal s_ram_wait : std_logic;

	-- ROM
	signal s_rom_addr : std_logic_vector(9 downto 0);
	signal s_rom_dout : std_logic_vector(7 downto 0);

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
	signal s_mem_wr_pulse : std_logic;
	signal s_port_rd : std_logic;
	signal s_port_wr : std_logic;
	signal s_is_rom_range : std_logic;
	signal s_is_ram_range : std_logic;

	-- Seven segment value
	signal s_seven_seg_value : std_logic_vector(11 downto 0);

	-- MIG Port
	signal mig_xtx_p0 : std_logic_vector(80 downto 0);
	signal mig_xrx_p0 : std_logic_vector(56 downto 0);
	signal s_calib_done : std_logic;

	-- Debug
	signal s_logic_capture : std_logic_vector(52 downto 0);
	signal s_logic_trigger : std_logic;
	signal s_pc : std_logic_vector(15 downto 0);
	signal s_m1_n : std_logic;

begin

	-- Logic Capture
	s_logic_capture <= 
		s_pc & s_cpu_addr & s_cpu_din & s_cpu_dout 
		& s_cpu_mreq_n & s_cpu_iorq_n 
		& s_cpu_rd_n & s_cpu_wr_n & s_cpu_wait_n
		;
	s_logic_trigger <= s_calib_done;

	cap : entity work.LogicCapture
	generic map
	(
		p_clock_hz => 80_000_000,
		p_bit_width => 53,
		p_addr_width => 11
	)
	port map
	( 
		i_clock => s_clock_80mhz,
		i_clken => s_clken_cpu,
		i_reset => s_reset,
		i_trigger => s_logic_trigger,
		i_signals => s_logic_capture,
		o_uart_tx => o_uart_tx
	);

	-- Capture PC address
	pcproc : process(s_clock_80mhz)
	begin
		if rising_edge(s_clock_80mhz) then 
			if s_reset = '1' then
				s_pc <= x"FFFF";
			else
				if s_m1_n = '0' then
					s_pc <= s_cpu_addr;
				end if;
			end if;
		end if;
	end process;

	-- Reset signal
	s_reset <= '1' when i_button_b = '0' else '0';
	s_cpu_reset_n <= not (s_reset or not s_calib_done);

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

	-- Generate CPU clock enable (1.774Mhz)
	-- (80Mhz / 45 = 1.777Mhz)
	clock_div_cpu_1774 : entity work.ClockDivider
	generic map
	(
		p_period => 2
	)
	port map
	(
		i_clock => s_clock_80mhz,
		i_clken => '1',
		i_reset => s_reset,
		o_clken => s_clken_cpu
	);

	-- Test Rom
	rom : entity work.TestRom
	PORT MAP
	(
		clock => s_clock_80mhz,
		addr => s_rom_addr,
		dout => s_rom_dout
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
		RESET_n => s_cpu_reset_n, 
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
		M1_n => s_m1_n,
		RFSH_n => open,
		HALT_n => open,
		BUSAK_n => open
	);

	-- Edge detection for memory read/write
	mem_wr_edge_detector : entity work.EdgeDetector
	port map
	( 
		i_clock => s_clock_80mhz,
		i_clken => s_clken_cpu,
		i_reset => s_reset,
		i_signal => s_mem_wr,
		o_pulse => s_mem_wr_pulse
	);

	-- Decode I/O control signals from cpu
	s_mem_rd <= '1' when (s_cpu_mreq_n = '0' and s_cpu_iorq_n = '1' and s_cpu_rd_n = '0') else '0';
	s_mem_wr <= '1' when (s_cpu_mreq_n = '0' and s_cpu_iorq_n = '1' and s_cpu_wr_n = '0') else '0';
--	s_port_rd <= '1' when (s_cpu_iorq_n = '0' and s_cpu_mreq_n = '1' and s_cpu_rd_n = '0') else '0';
	s_port_wr <= '1' when (s_cpu_iorq_n = '0' and s_cpu_mreq_n = '1' and s_cpu_wr_n = '0') else '0';

	-- Memory range mapping
	memmap : process(s_cpu_addr)
	begin
		s_is_rom_range <= '0';
		s_is_ram_range <= '0';
		if s_cpu_addr(15 downto 10) = "000000" then
			s_is_rom_range <= '1';
		else
			s_is_ram_range <= '1';
		end if;
	end process;

	s_rom_addr <= s_cpu_addr(9 downto 0);

	s_ram_addr <= "00000000000000" & s_cpu_addr(15 downto 0);
	s_ram_write <= s_mem_wr_pulse and s_is_ram_range;
	s_ram_din <= s_cpu_dout;

	s_cpu_wait_n <= not s_ram_wait;

	cpu_data_in : process(s_mem_rd, 
							s_is_rom_range, s_rom_dout,
							s_is_ram_range, s_ram_dout
							)
	begin

		s_cpu_din <= x"FF";

		if s_mem_rd = '1' then
			if s_is_rom_range = '1' then
				s_cpu_din <= s_rom_dout;
			elsif s_is_ram_range = '1' then
				s_cpu_din <= s_ram_dout;
			end if;
		end if;

	end process;

	-- Listen for port writes
	port_handler : process(s_clock_80mhz)
	begin
		if rising_edge(s_clock_80mhz) then
			if s_reset = '1' then
				o_leds <= (others => '0');
				s_seven_seg_value <= (others => '0');
			elsif s_clken_cpu = '1' then
			
				if s_port_wr = '1' then

					if s_cpu_addr(7 downto 0) = x"00" then
						o_leds <= s_cpu_dout;
					elsif s_cpu_addr(7 downto 0) = x"01" then
						s_seven_seg_value(7 downto 0) <= s_cpu_dout;
					elsif s_cpu_addr(7 downto 0) = x"02" then
						s_seven_seg_value(11 downto 8) <= s_cpu_dout(3 downto 0);
					end if;

				end if;

			end if;
		end if;
	end process;

	-- Seven segment display driver
	seven_seg : entity work.SevenSegmentHexDisplayWithClockDivider
	generic map
	(
		p_clock_hz => 80_000_000
	)
	port map
	( 
		i_clock => s_clock_80mhz,
		i_reset => s_reset,
		i_data => s_seven_seg_value,
		o_segments => o_seven_segment(7 downto 1),
		o_segments_en => o_seven_segment_en
	);
	o_seven_segment(0) <= '1';

	-- LPDDR Wrapper
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

	sri : entity work.SimpleRamInterface
	port map
	( 
		i_clock => s_clock_80mhz,
		i_clken => s_clken_cpu,
		i_reset => s_reset,
		i_wr => s_ram_write,
		i_cs => s_is_ram_range,
		i_addr => s_ram_addr,
		i_data => s_ram_din,
		o_data => s_ram_dout,
		o_wait => s_ram_wait,
		mig_xtx => mig_xtx_p0,
		mig_xrx => mig_xrx_p0
	);

end Behavioral;

