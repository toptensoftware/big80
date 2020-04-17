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

	-- Serial I/O
	o_uart_tx : out std_logic;
	i_uart_rx : in std_logic;

	-- SD Card
	o_sd_mosi : out std_logic;
	i_sd_miso : in std_logic;
	o_sd_ss_n : out std_logic;
	o_sd_sclk : out std_logic

);
end top;

architecture Behavioral of top is
	-- Reset and clocking
	signal s_reset : std_logic;
	signal s_reset_n : std_logic;
	signal s_clock_100mhz : std_logic;
	signal s_clock_80mhz : std_logic;
	signal s_clken_cpu : std_logic;

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

	-- Memory/Port Mapping
	signal s_mem_rd : std_logic;
	signal s_mem_wr : std_logic;
	signal s_mem_rd_pulse : std_logic;
	signal s_mem_wr_pulse : std_logic;
	signal s_port_rd : std_logic;
	signal s_port_wr : std_logic;
	signal s_is_rom_range : std_logic;
	signal s_is_ram_range : std_logic;
	signal s_port_wr_rising_edge : std_logic;
	signal s_port_rd_rising_edge : std_logic;
	signal s_port_rd_falling_edge : std_logic;

	-- Interrupt Controller
	signal s_is_interrupt_controller_port : std_logic;
	signal s_irqs_active : std_logic_vector(0 downto 0);
	signal s_irqs : std_logic_vector(0 downto 0);
	signal s_irq : std_logic;
	signal s_irq_ack : std_logic;

	-- RAM
	signal s_ram_write : std_logic;
	signal s_ram_addr : std_logic_vector(14 downto 0);
	signal s_ram_din : std_logic_vector(7 downto 0);
	signal s_ram_dout : std_logic_vector(7 downto 0);

	-- ROM
	signal s_rom_addr : std_logic_vector(13 downto 0);
	signal s_rom_dout : std_logic_vector(7 downto 0);

	-- SD Card Controller
	signal s_sd_status : std_logic_vector(7 downto 0);
	signal s_sd_op_write : std_logic;
	signal s_sd_op_cmd : std_logic_vector(1 downto 0);
	signal s_sd_op_block_number : std_logic_vector(31 downto 0);
	signal s_sd_data_start : std_logic;
	signal s_sd_data_cycle : std_logic;
	signal s_sd_din : std_logic_vector(7 downto 0);
	signal s_sd_dout : std_logic_vector(7 downto 0);

	-- Serial Port
	signal s_is_serial_port : std_logic;
	signal s_serial_port_wr_rising_edge : std_logic;
	signal s_serial_port_rd_falling_edge : std_logic;
	signal s_serial_cpu_din : std_logic_vector(7 downto 0);

	-- Disk Controller
	signal s_is_disk_port : std_logic;
	signal s_disk_port_wr_rising_edge : std_logic;
	signal s_disk_port_rd_falling_edge : std_logic;
	signal s_disk_cpu_din : std_logic_vector(7 downto 0);

	
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
		NMI_n => s_cpu_nmi_n,
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


	s_cpu_wait_n <= '1';
	s_cpu_nmi_n <= not s_irq;
	

	cpu_data_in : process(s_mem_rd, 
							s_is_rom_range, s_rom_dout,
							s_is_ram_range, s_ram_dout,
							s_is_serial_port, s_serial_cpu_din,
							s_is_disk_port, s_disk_cpu_din,
							s_is_interrupt_controller_port, s_irqs_active
							)
	begin

		s_cpu_din <= x"FF";

		if s_mem_rd = '1' then

			if s_is_rom_range = '1' then
				s_cpu_din <= s_rom_dout;
			elsif s_is_ram_range = '1' then
				s_cpu_din <= s_ram_dout;
			end if;

		elsif s_is_serial_port = '1' then 

			s_cpu_din <= s_serial_cpu_din;
	
		elsif s_is_disk_port = '1' then 

			s_cpu_din <= s_disk_cpu_din;

		elsif s_is_interrupt_controller_port = '1' then

			s_cpu_din <= "0000000" & s_irqs_active;
	
		end if;

	end process;

	-- Detect port write rising edges
	port_wr_rising_edge : entity work.EdgeDetector
	port map
	( 
		i_clock => s_clock_80mhz,
		i_clken => s_clken_cpu,
		i_reset => s_reset,
		i_signal => s_port_wr,
		o_pulse => s_port_wr_rising_edge
	);

	-- Detect port read rising edges
	port_rd_rising_edge : entity work.EdgeDetector
	generic map
	(
		p_falling_edge => false,
		p_rising_edge => true
	)
	port map
	( 
		i_clock => s_clock_80mhz,
		i_clken => s_clken_cpu,
		i_reset => s_reset,
		i_signal => s_port_rd,
		o_pulse => s_port_rd_rising_edge
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
				o_leds <= (others => '0');
			elsif s_clken_cpu = '1' then
			
				if s_port_wr = '1' then

					if s_cpu_addr(7 downto 0) = x"00" then
						o_leds <= s_cpu_dout;
					end if;

				end if;

			end if;
		end if;
	end process;



	-- Interrupt Controller

	s_is_interrupt_controller_port <= '1' when s_cpu_addr(7 downto 0) = x"1c" else '0';
	s_serial_port_wr_rising_edge <= s_is_interrupt_controller_port and s_port_wr_rising_edge;
	s_serial_port_rd_falling_edge <= s_is_interrupt_controller_port and s_port_rd_falling_edge;
	s_irq_ack <= s_is_interrupt_controller_port and s_port_rd_rising_edge;

	interrupt_controller : entity work.GenericInterruptController
	generic map
	(
		p_irq_count => 1
	)
	port map
	(
		i_reset => s_reset,
		i_clock => s_clock_80mhz,
		o_irqs => s_irqs_active,
		i_irqs => s_irqs,
		o_irq => s_irq,
		i_ack => s_irq_ack
	);
		


	-- ROM

	s_rom_addr <= s_cpu_addr(13 downto 0);

	rom : entity work.TestRom
	PORT MAP
	(
		i_clock => s_clock_80mhz,
		i_addr => s_rom_addr,
		o_dout => s_rom_dout
	);



	-- RAM

	s_ram_addr <= s_cpu_addr(14 downto 0);
	s_ram_write <= s_mem_wr and s_is_ram_range;
	s_ram_din <= s_cpu_dout;

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



	-- SD Card Controller

	e_card_controller : entity work.SDCardController
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
		o_last_block_number => open,
		i_op_write => s_sd_op_write,
		i_op_cmd => s_sd_op_cmd,
		i_op_block_number => s_sd_op_block_number,
		o_data_start => s_sd_data_start,
		o_data_cycle => s_sd_data_cycle,
		i_din => s_sd_din,
		o_dout => s_sd_dout 
	);
		


	-- Serial Port

	s_is_serial_port <= '1' when s_cpu_addr(7 downto 4) = x"8" else '0';
	s_serial_port_wr_rising_edge <= s_is_serial_port and s_port_wr_rising_edge;
	s_serial_port_rd_falling_edge <= s_is_serial_port and s_port_rd_falling_edge;

	serial : entity work.GenericSerialPort
	generic map
	(
		p_clock_hz => 80_000_000,
		p_irq_delay_ms => 11,
		p_baud => 115200
	)
	port map
	(
		i_reset => s_reset,
		i_clock => s_clock_80mhz,
		i_cpu_port_number => s_cpu_addr(1 downto 0),
		i_cpu_port_wr_rising_pulse => s_serial_port_wr_rising_edge,
		i_cpu_port_rd_falling_edge => s_serial_port_rd_falling_edge,
		o_cpu_din => s_serial_cpu_din,
		i_cpu_dout => s_cpu_dout,
		o_irq_rx => open,
		o_irq_tx => open,
		o_uart_tx => o_uart_tx,
		i_uart_rx => i_uart_rx
	);



	-- Disk Controller

	s_is_disk_port <= '1' when s_cpu_addr(7 downto 4) = x"9" else '0';
	s_disk_port_wr_rising_edge <= s_is_disk_port and s_port_wr_rising_edge;
	s_disk_port_rd_falling_edge <= s_is_disk_port and s_port_rd_falling_edge;

	syscon_disk : entity work.GenericDiskController
	port map
	(
		i_reset => s_reset,
		i_clock => s_clock_80mhz,
		i_cpu_port_number => s_cpu_addr(2 downto 0),
		i_cpu_port_wr_rising_edge => s_disk_port_wr_rising_edge,
		i_cpu_port_rd_falling_edge => s_disk_port_rd_falling_edge,
		o_cpu_din => s_disk_cpu_din,
		i_cpu_dout => s_cpu_dout,
		o_irq => s_irqs(0),
		i_sd_status => s_sd_status,
		o_sd_op_write => s_sd_op_write,
		o_sd_op_cmd => s_sd_op_cmd,
		o_sd_op_block_number => s_sd_op_block_number,
		i_sd_data_start => s_sd_data_start,
		i_sd_data_cycle => s_sd_data_cycle,
		o_sd_din => s_sd_din,
		i_sd_dout => s_sd_dout
	);

	

end Behavioral;

