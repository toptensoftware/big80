library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	CLK_100MHz_in : in std_logic;
	c3_sys_rst_n : in std_logic;
	Button_B : in std_logic;
	LEDs : out std_logic_vector(7 downto 0);
	SevenSegment : out std_logic_vector(7 downto 0);
	SevenSegmentEnable : out std_logic_vector(2 downto 0);

	-- Memory controller
	mcb3_dram_dq    : inout  std_logic_vector(15 downto 0);
	mcb3_dram_a     : out std_logic_vector(12 downto 0);
	mcb3_dram_ba    : out std_logic_vector(1 downto 0);
	mcb3_dram_cke   : out std_logic;
	mcb3_dram_ras_n : out std_logic;
	mcb3_dram_cas_n : out std_logic;
	mcb3_dram_we_n  : out std_logic;
	mcb3_dram_dm    : out std_logic;
	mcb3_dram_udqs  : inout std_logic;
	mcb3_rzq        : inout std_logic;
	mcb3_dram_udm   : out std_logic;
	mcb3_dram_dqs   : inout std_logic;
	mcb3_dram_ck    : out std_logic;
	mcb3_dram_ck_n  : out std_logic
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_CLK_100Mhz_buffered : std_logic;
	signal s_CLK_80Mhz : std_logic;
	signal s_CLK_CPU_en : std_logic;
	signal s_seven_seg_value : std_logic_vector(11 downto 0);

	signal c3_calib_done : std_logic;
begin

	-- Reset signal
	s_reset <= (not Button_B);

	-- LEDs
	LEDs <= "0000000" & c3_calib_done;

	-- Seven segment value
	s_seven_seg_value <= "000000000000";

    clk_ibufg : IBUFG
    port map
    (
		I => CLK_100Mhz_in,
		O => s_CLK_100MHz_buffered
	);

	 -- DCM
	dcm : entity work.ClockDCM
	port map
	(
		CLK_IN_100MHz => s_CLK_100MHz_buffered,
		CLK_OUT_100MHz => open,
		CLK_OUT_80MHz => s_CLK_80MHz
	);

	-- Clock divider
	clock_divider : entity work.ClockDivider
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

	-- Seven segment display
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


	-- LPDDR Wrapper
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/mimas_lpddr.vhd
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/memc3_infrastructure.vhd
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/memc3_wrapper.vhd
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/mcb_raw_wrapper.vhd
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/mcb_soft_calibration_top.vhd
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/mcb_soft_calibration.vhd
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/iodrp_controller.vhd
	--xilt:require:./coregen/mimas_lpddr/user_design/rtl/iodrp_mcb_controller.vhd
	lpddr : entity work.mimas_lpddr
	generic map
	(
		C3_INPUT_CLK_TYPE => "IBUFG"
	)
	port map
	(
		mcb3_dram_dq     => mcb3_dram_dq,
		mcb3_dram_a      => mcb3_dram_a,
		mcb3_dram_ba     => mcb3_dram_ba,
		mcb3_dram_cke    => mcb3_dram_cke,
		mcb3_dram_ras_n  => mcb3_dram_ras_n,
		mcb3_dram_cas_n  => mcb3_dram_cas_n,
		mcb3_dram_we_n   => mcb3_dram_we_n,
		mcb3_dram_dm     => mcb3_dram_dm,
		mcb3_dram_udqs   => mcb3_dram_udqs,
		mcb3_rzq         => mcb3_rzq,
		mcb3_dram_udm    => mcb3_dram_udm,
		mcb3_dram_dqs    => mcb3_dram_dqs,
		mcb3_dram_ck     => mcb3_dram_ck,
		mcb3_dram_ck_n   => mcb3_dram_ck_n,

		c3_sys_clk       => s_CLK_100MHz_buffered,
		c3_sys_rst_n     => c3_sys_rst_n,
		c3_calib_done    => c3_calib_done,
		c3_clk0          => open,
		c3_rst0          => open,

		c3_p0_cmd_clk => s_CLK_80Mhz,
		c3_p0_cmd_en => s_CLK_CPU_en,
		c3_p0_cmd_instr => (others => '0'),
		c3_p0_cmd_bl => (others => '0'),
		c3_p0_cmd_byte_addr => (others => '0'),
		c3_p0_cmd_empty => open,
		c3_p0_cmd_full => open,
		
		c3_p0_wr_clk => s_CLK_80Mhz,
		c3_p0_wr_en => s_CLK_CPU_en,
		c3_p0_wr_mask => (others => '0'),
		c3_p0_wr_data => (others => '0'),
		c3_p0_wr_full => open,
		c3_p0_wr_empty => open,
		c3_p0_wr_count => open,
		c3_p0_wr_underrun => open,
		c3_p0_wr_error => open,
		
		c3_p0_rd_clk => s_CLK_80Mhz,
		c3_p0_rd_en => s_CLK_CPU_en,
		c3_p0_rd_data => open,
		c3_p0_rd_full => open,
		c3_p0_rd_empty => open,
		c3_p0_rd_count => open,
		c3_p0_rd_overflow => open,
		c3_p0_rd_error => open
	);


end Behavioral;

