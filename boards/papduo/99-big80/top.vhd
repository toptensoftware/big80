library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity top is
port 
(
	-- Clocking
	i_clock_32mhz : in std_logic;
	i_reset : in std_logic;
	
	-- LEDs
	o_leds : out std_logic_vector(3 downto 0);

	-- Audio
	o_audio : out std_logic_vector(1 downto 0);

	-- VGA
	o_horz_sync : out std_logic;
	o_vert_sync : out std_logic;
	o_red : out std_logic_vector(3 downto 0);
	o_green : out std_logic_vector(3 downto 0);
	o_blue : out std_logic_vector(3 downto 0);

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

	-- RAM
	o_sram_addr : out std_logic_vector(20 downto 0);
	io_sram_data : inout std_logic_vector(7 downto 0);
	o_sram_ce : out std_logic;
	o_sram_we : out std_logic;
	o_sram_oe : out std_logic
);
end top;

architecture Behavioral of top is

	-- Clocking
	signal s_reset : std_logic;
	signal s_clock_80mhz : std_logic;

	-- Status
	signal s_status : std_logic_vector(7 downto 0);

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

	-- VGA
	signal s_red : std_logic_vector(2 downto 0);
	signal s_green : std_logic_vector(2 downto 0);
	signal s_blue : std_logic_vector(2 downto 0);

	signal s_is_ram_op : std_logic;
	signal s_wait_counter : std_logic_vector(1 downto 0);
begin


	------------------------- Clocking -------------------------

	-- Reset signal
	s_reset <= i_reset;

	-- Digital Clock Manager
	dcm : entity work.ClockDCM
	port map
	(
		CLK_IN_32MHz => i_clock_32mhz,
		CLK_OUT_32MHz => open,
		CLK_OUT_80MHz => s_clock_80mhz
	);

	------------------------- Status -------------------------

	o_leds <= s_status(3 downto 0);



	------------------------- Audio Output -------------------------

	o_audio <= s_audio & s_audio;



	------------------------- RAM Mapping -------------------------

	o_sram_addr <= "000" & s_ram_addr;
	io_sram_data <= s_ram_din when s_ram_wr='1' else "ZZZZZZZZ";
	s_ram_dout <= io_sram_data;
	o_sram_ce <= '0' when s_ram_cs='1' and (s_ram_rd='1' or s_ram_wr='1') else '1';
	o_sram_we <= '0' when s_ram_wr='1' else '1';
	o_sram_oe <= '0' when s_ram_rd='1' else '1';
	s_ram_wait <= '1' when s_is_ram_op='1' and s_wait_counter /= "11" else '0';	
	s_is_ram_op <= s_ram_cs and (s_ram_rd or s_ram_wr);

	ram_wait : process(s_clock_80mhz)
	begin
		if rising_edge(s_clock_80mhz) then
			if s_reset = '1' then 
				s_wait_counter <= (others => '0');
			else
				if s_is_ram_op = '1' then
					if s_wait_counter /= "11" then
						s_wait_counter <= std_logic_vector(unsigned(s_wait_counter) + 1);
					end if;
				else
					s_wait_counter <= (others => '0');
				end if;
			end if;
		end if;
	end process;


	------------------------- VGA Mapping -------------------------

	o_red <= s_red & s_red(0);
	o_green <= s_green & s_green(0);
	o_blue <= s_blue & s_blue(0);



	------------------------- TRS-80 Core -------------------------

	trs80 : entity work.Trs80Model1Core
	generic map
	(
		p_enable_trisstick => false
	)
	port map
	(
		o_uart_debug => open,
		i_clock_80mhz => s_clock_80mhz,
		i_reset => s_reset,
		o_clken_cpu => open,
		i_switch_run => '1',
		o_status => s_status,
		o_debug => open,
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
		o_psx_att => open,
		o_psx_clock => open,
		o_psx_hoci => open,
		i_psx_hico => '1',
		i_psx_ack => '1'
	);
	
end Behavioral;

