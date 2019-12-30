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
	debug_audio : out std_logic
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_CLK_100Mhz_unused : std_logic;
	signal s_CLK_80Mhz : std_logic;
	signal s_CLK_CPU_en : std_logic;
	signal s_CLK_CPU_divider : integer range 0 to 44;

	signal s_sd_op_wr : std_logic;
	signal s_sd_op_cmd : std_logic_vector(1 downto 0);
	signal s_sd_op_block_number : std_logic_vector(31 downto 0);
	signal s_sd_dcycle :  std_logic;
	signal s_sd_data : std_logic_vector(7 downto 0);
	signal s_sd_last_block_number : std_logic_vector(31 downto 0);
	signal s_sd_status : std_logic_vector(7 downto 0);

	signal s_seven_seg_value : std_logic_vector(11 downto 0);
	signal s_selected_tape : std_logic_vector(11 downto 0);

	signal s_Audio : std_logic;
begin

	-- Reset signal
	s_reset <= not Button_B;

	--      audio signal        reading            sdhc             initok
	LEDs <= s_Audio & "0000" & s_sd_status(1) & s_sd_status(7) & s_sd_status(4);

	dcm : entity work.ClockDCM
	port map
	(
		CLK_IN_100MHz => CLK_100MHz_in,
		CLK_OUT_100MHz => s_CLK_100Mhz_unused,
		CLK_OUT_80MHz => s_CLK_80MHz
	);

	cpu_clock_divider : process (s_CLK_80Mhz)
	begin
		if rising_edge(s_CLK_80Mhz) then
			if s_Reset = '1' then
				s_CLK_CPU_divider <= 0;
			else
				if s_CLK_CPU_divider = 44 then
					s_CLK_CPU_divider <= 0;
				else
					s_CLK_CPU_divider <= s_CLK_CPU_divider + 1;
				end if;
			end if;
		end if;
	end process;
	s_CLK_CPU_en <= '1' when s_CLK_CPU_divider = 0 else '0';

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

	s_seven_seg_value <= s_selected_Tape when Button_Left = '1' else s_sd_last_block_number(11 downto 0);

	sdcard : entity work.SDCardController
	port map
	(
		-- Clocking
		reset => s_reset,
		clock_108_000 => s_CLK_80MHz,

		-- SD Card Signals
		ss_n => sd_ss_n,
		mosi => sd_mosi,
		miso => sd_miso,
		sclk => sd_sclk,

		-- Status signals
		status => s_sd_status,

		-- Operation
		op_wr => s_sd_op_wr,
		op_cmd => s_sd_op_cmd,
		op_block_number => s_sd_op_block_number,

		last_block_number => s_sd_last_block_number,

		-- DMA access
		dstart => open,
		dcycle => s_sd_dcycle,
		din => x"00",
		dout => s_sd_data
	);

	player : entity work.Trs80CassettePlayer
	generic map
	(
		p_ClockEnableFrequency => 1_774_000,
		p_ButtonActive => '0'
	)
	port map
	(
		i_Clock => s_CLK_80Mhz,
		i_ClockEnable => s_CLK_CPU_en,
		i_Reset => s_Reset,
		i_ButtonStartStop => Button_Right,
		i_ButtonNext => Button_Up,
		i_ButtonPrev => Button_Down,
		o_sd_op_wr => s_sd_op_wr,
		o_sd_op_cmd => s_sd_op_cmd,
		o_sd_op_block_number => s_sd_op_block_number,
		i_sd_status => s_sd_status,
		i_sd_dcycle => s_sd_dcycle,
		i_sd_data => s_sd_data,
		o_SelectedTape => s_selected_tape,
		o_Audio => s_Audio
	);

	-- Output audio on both channels
	Audio <= s_Audio & s_Audio;
	debug_audio <= s_Audio;

end Behavioral;

