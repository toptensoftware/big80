library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity top is
port 
(
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;
	o_uart_tx : out std_logic;
	i_uart_rx : in  std_logic
);
end top;

architecture Behavioral of top is
	-- Reset and clocking
	signal s_reset : std_logic;
	signal s_reset_n : std_logic;
	signal s_clock_100mhz : std_logic;
	signal s_clock_80mhz : std_logic;
	signal s_clken_cpu : std_logic;

	-- RAM
	signal s_ram_write : std_logic;
	signal s_ram_addr : std_logic_vector(14 downto 0);
	signal s_ram_din : std_logic_vector(7 downto 0);
	signal s_ram_dout : std_logic_vector(7 downto 0);

	-- ROM
	signal s_rom_addr : std_logic_vector(13 downto 0);
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
	signal s_mem_rd_pulse : std_logic;
	signal s_mem_wr_pulse : std_logic;
	signal s_port_rd : std_logic;
	signal s_port_rd_falling_edge : std_logic;
	signal s_port_wr : std_logic;
	signal s_port_wr_edge : std_logic;
	signal s_is_rom_range : std_logic;
	signal s_is_ram_range : std_logic;

	signal s_uart_tx_write : std_logic;
	signal s_uart_tx_din : std_logic_vector(7 downto 0);
	signal s_uart_tx_count : std_logic_vector(7 downto 0);

	signal s_uart_rx_read : std_logic;
	signal s_uart_rx_dout : std_logic_vector(7 downto 0);
	signal s_uart_rx_count : std_logic_vector(7 downto 0);

begin

	-- Reset signal
	s_reset <= '1' when i_button_b = '0' else '0';
	s_reset_n <= not s_reset;

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
		p_period => 45
	)
	port map
	(
		i_clock => s_clock_80mhz,
		i_clken => '1',
		i_reset => s_reset,
		o_clken => s_clken_cpu
	);

	-- Test Rom
	rom : entity work.BootRom
	PORT MAP
	(
		i_clock => s_clock_80mhz,
		i_addr => s_rom_addr,
		o_dout => s_rom_dout
	);


	-- Main RAM (32K)
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
		i_write => s_ram_write,
		i_write_mask => "0",
		i_addr => s_ram_addr,
		i_data => s_ram_din,
		o_data => s_ram_dout
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

	-- Memory range mapping
	memmap : process(s_cpu_addr)
	begin
		s_is_rom_range <= '0';
		s_is_ram_range <= '0';
		if s_cpu_addr(15 downto 14) = "00" then
			s_is_rom_range <= '1';
		elsif s_cpu_addr(15) = '1' then
			s_is_ram_range <= '1';
		end if;
	end process;

	s_rom_addr <= s_cpu_addr(13 downto 0);

	s_ram_addr <= s_cpu_addr(14 downto 0);
	s_ram_write <= s_mem_wr and s_is_ram_range;
	s_ram_din <= s_cpu_dout;

	s_cpu_wait_n <= '1';

	cpu_data_in : process(s_mem_rd, 
							s_is_rom_range, s_rom_dout,
							s_is_ram_range, s_ram_dout,
						  s_port_rd,
						    s_cpu_addr, s_uart_tx_count, 
							s_uart_rx_dout, s_uart_rx_count
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

		if s_port_rd = '1' then
			case s_cpu_addr(7 downto 0) is

				when x"80" =>
					s_cpu_din <= s_uart_tx_count;

				when x"81" =>
					s_cpu_din <= s_uart_rx_count;

				when x"82" =>
					s_cpu_din <= s_uart_rx_dout;

				when others =>
					s_cpu_din <= x"FF";

			end case;
		end if;

	end process;

	port_wr_edge : entity work.EdgeDetector
	port map
	( 
		i_clock => s_clock_80mhz,
		i_clken => s_clken_cpu,
		i_reset => s_reset,
		i_signal => s_port_wr,
		o_pulse => s_port_wr_edge
	);

	port_rd_edge : entity work.EdgeDetector
	generic map
	(
		p_falling_edge => true,
		p_rising_edge => false
	)
	port map
	( 
		i_clock => s_clock_80mhz,
		i_clken => s_clken_cpu,
		i_reset => s_reset,
		i_signal => s_port_rd,
		o_pulse => s_port_rd_falling_edge
	);


	-- Listen for port writes
	port_handler : process(s_clock_80mhz)
	begin
		if rising_edge(s_clock_80mhz) then
			if s_reset = '1' then
				s_uart_tx_write <= '0';
				s_uart_rx_read <= '0';
			else
				s_uart_tx_write <= '0';
				s_uart_rx_read <= '0';

				if s_clken_cpu = '1' and s_port_wr_edge = '1' and s_cpu_addr(7 downto 0) = x"80" then
					s_uart_tx_din <= s_cpu_dout;
					s_uart_tx_write <= '1';
				end if;

				if s_clken_cpu = '1' and s_port_rd_falling_edge = '1' and s_cpu_addr(7 downto 0) = x"82" then
					s_uart_rx_read <= '1';
				end if;

			end if;
		end if;
	end process;

	-- Uart transmitter
	uart_tx : entity work.UartTxBuffered
	generic map
	(
		p_clken_hz => 80_000_000,
		p_baud => 115200,
		p_addr_width => 8
	)
	port map
	( 
		i_clock => s_clock_80mhz,
		i_clken => '1',
		i_reset => s_reset,
		i_write => s_uart_tx_write,
		i_din => s_uart_tx_din,
		o_uart_tx => o_uart_tx,
		o_busy => open,
		o_full => open,
		o_empty => open,
		o_underflow => open,
		o_overflow => open,
		o_count => s_uart_tx_count
	);

	uart_rx : entity work.UartRxBuffered
	generic map
	(
		p_clock_hz => 80_000_000,
		p_baud => 115200,
		p_sync => true,
		p_debounce => true,
		p_addr_width => 8
	)
	port map
	( 
		i_clock => s_clock_80mhz,
		i_reset => s_reset,
		i_uart_rx => i_uart_rx,
		i_read => s_uart_rx_read,
		o_dout => s_uart_rx_dout,
		o_busy => open,
		o_error => open,
		o_full => open,
		o_empty => open,
		o_underflow => open,
		o_overflow => open,
		o_count => s_uart_rx_count
	);


--	s_logic_capture <= s_uart_tx_write & s_uart_tx_din & s_port_wr & s_cpu_addr;
--
--	cap : entity work.LogicCapture
--	generic map
--	(
--		p_clock_hz => 80_000_000,
--		p_baud => 115200,
--		p_bit_width => 26,
--		p_addr_width => 12
--	)
--	port map
--	( 
--		i_clock => s_clock_80mhz,
--		i_clken => s_clken_cpu,
--		i_reset => s_reset,
--		i_trigger => '1',
--		i_signals => s_logic_capture,
--		o_uart_tx => o_uart_tx
--	);
--

end Behavioral;


--xilt:nowarn:~WARNING:Par:288 - The signal uart_.x/fifo
--xilt:nowarn:WARNING:Par:283 - There are 18 loadless signals
--xilt:nowarn:~WARNING:PhysDesignRules:367 - The signal <uart_.x/fifo