library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
(
	-- These signals must match what's in the .ucf file
	CLK_100MHz : in std_logic;
	Button_B : in std_logic;
	HSync : out std_logic;
	VSync : out std_logic;
	Red : out std_logic_vector(2 downto 0);
	Green : out std_logic_vector(2 downto 0);
	Blue : out std_logic_vector(2 downto 1);
	PS2_Clock : inout std_logic;
	PS2_Data : inout std_logic;

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
	Audio : out std_logic_vector(1 downto 0)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_reset_n : std_logic;
	signal s_blank : std_logic;
	signal s_hpos : integer range -2048 to 2047;
	signal s_vpos : integer range -2048 to 2047;
	signal s_CLK_80Mhz : std_logic;
	signal s_CLK_40Mhz_en : std_logic;
	signal s_CLK_CPU_en : std_logic;
    signal s_VideoRamAddr : std_logic_vector(9 downto 0);
    signal s_VideoRamData : std_logic_vector(7 downto 0);
    signal s_CharRomAddr : std_logic_vector(11 downto 0);
    signal s_CharRomData : std_logic_vector(5 downto 0);
	signal s_VideoRamWrite_cpu : std_logic;
	signal s_VideoRamAddr_cpu : std_logic_vector(9 downto 0);
	signal s_VideoRamDataIn_cpu : std_logic_vector(7 downto 0);
	signal s_VideORamDataOut_cpu : std_logic_vector(7 downto 0);
	signal s_RamWrite_cpu : std_logic;
	signal s_RamAddr_cpu : std_logic_vector(13 downto 0);
	signal s_RamDataIn_cpu : std_logic_vector(7 downto 0);
	signal s_RamDataOut_cpu : std_logic_vector(7 downto 0);
	signal s_RomAddr_cpu : std_logic_vector(13 downto 0);
	signal s_RomDataOut_cpu : std_logic_vector(7 downto 0);
	signal s_pixel : std_logic;
	signal s_cpu_addr : std_logic_vector(15 downto 0);
	signal s_cpu_din : std_logic_vector(7 downto 0);
	signal s_cpu_dout : std_logic_vector(7 downto 0);
	signal s_cpu_mreq_n : std_logic;
	signal s_cpu_iorq_n : std_logic;
	signal s_cpu_rd_n : std_logic;
	signal s_cpu_wr_n : std_logic;
	signal s_cpu_wait_n : std_logic;

	-- keyboard related
	signal s_scan_code : std_logic_vector(6 downto 0);
	signal s_extended_key : std_logic;
	signal s_key_release : std_logic;
	signal s_key_available : std_logic;
	signal s_key_switches : std_logic_vector(63 downto 0);
	signal s_KeyboardMapDataOut_cpu : std_logic_vector(7 downto 0);

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

	-- Cassette
	signal s_sd_op_wr : std_logic;
	signal s_sd_op_cmd : std_logic_vector(1 downto 0);
	signal s_sd_op_block_number : std_logic_vector(31 downto 0);
	signal s_sd_dcycle :  std_logic;
	signal s_sd_data : std_logic_vector(7 downto 0);
	signal s_sd_last_block_number : std_logic_vector(31 downto 0);
	signal s_sd_status : std_logic_vector(7 downto 0);
	signal s_seven_seg_value : std_logic_vector(11 downto 0);
	signal s_selected_tape : std_logic_vector(11 downto 0);
	signal s_PrevCasAudio : std_logic;
	signal s_CasAudio : std_logic;
	signal s_CasAudioEdge : std_logic;
	signal s_Audio : std_logic;
	signal s_Speaker : std_logic_vector(1 downto 0);

begin

	-- Reset signal
	s_reset_n <= Button_B;
	s_reset <= not Button_B;

	-- Digital Clock Manager
	dcm : entity work.ClockDCM
	port map
	(
		CLK_IN_100MHz => CLK_100MHz,
		CLK_OUT_100MHz => open,
		CLK_OUT_80MHz => s_CLK_80MHz
	);

	-- Generate the 40Mhz clock enable
	process (s_CLK_80Mhz)
	begin
		if rising_edge(s_CLK_80Mhz) then
			if s_reset = '1' then
				s_CLK_40Mhz_en <= '0';
			else
				s_CLK_40Mhz_en <= not s_CLK_40Mhz_en;
			end if;
		end if;
	end process;

	-- Generate CPU clock enable (1.774Mhz)
	-- (80Mhz / 45 = 1.777Mhz)
	clock_div_cpu774 : entity work.ClockDivider
	generic map
	(
		p_DivideCycles => 45
	)
	port map
	(
		i_Clock => s_CLK_80Mhz,
		i_Reset => s_reset,
		o_ClockEnable => s_CLK_CPU_en
	);

	-- Generate VGA timing signals for 800x600 @ 60Hz
	vga_timing : entity work.VGATiming800x600
	port map
	(
		i_Clock => s_CLK_80MHz,
		i_ClockEnable => s_CLK_40Mhz_en,
		i_Reset => s_reset,
		o_VSync => VSync,
		o_HSync => HSync,
		o_HPos => s_hpos,
		o_VPos => s_vpos,
		o_Blank => s_blank
	);

	-- TRS80 Video Controller
	video_controller : entity work.Trs80VideoController
	generic map
	(
		p_LeftMarginPixels => 16,
		p_TopMarginPixels => 12
	)
	port map
	(
		i_Clock => s_CLK_80MHz,
		i_ClockEnable => s_CLK_40Mhz_en,
		i_Reset => s_reset,
		i_HPos => s_hpos,
		i_VPos => s_vpos,
		o_VideoRamAddr => s_VideoRamAddr,
		i_VideoRamData => s_VideoRamData,
		o_CharRomAddr => s_CharRomAddr,
		i_CharRomData => s_CharRomData,
		o_Pixel => s_Pixel
	);

	-- Generate color
	Red <= "000";
	Green <= s_pixel & s_pixel & s_pixel;
	Blue <= "00";

	-- TRS80 Character ROM
	charrom : entity work.Trs80CharRom
	port map
	(
		clock => s_CLK_80MHz,
		addr => s_CharRomAddr,
		dout => s_CharRomData
	);

	-- Video RAM (1K)
	vram : entity work.RamDualPortInferred	
	GENERIC MAP
	(
		p_AddrWidth => 10
	)
	PORT MAP
	(
		-- Read only port for video controller
		i_Clock_A => s_CLK_80Mhz,
		i_ClockEn_A => s_CLK_40Mhz_en,
		i_Write_A  => '0',
		i_Addr_A => s_VideoRamAddr,
		i_Data_A => (others => '0'),
		o_Data_A => s_VideoRamData,

		-- Read/Write port for CPU
		i_Clock_B => s_CLK_80Mhz,
		i_ClockEn_B => '1',
		i_Write_B => s_VideoRamWrite_cpu,
		i_Addr_B => s_VideoRamAddr_cpu,
		i_Data_B => s_VideoRamDataIn_cpu,
		o_Data_B => s_VideORamDataOut_cpu
	);

	-- Main RAM (16K)
	ram : entity work.RamInferred	
	GENERIC MAP
	(
		p_AddrWidth => 14
	)
	PORT MAP
	(
		-- Read/Write port for CPU
		i_Clock => s_CLK_80Mhz,
		i_Write => s_RamWrite_cpu,
		i_Addr => s_RamAddr_cpu,
		i_Data => s_RamDataIn_cpu,
		o_Data => s_RamDataOut_cpu
	);

	-- Model 1 ROM (12K)
	rom : entity work.Trs80Model1Rom
	PORT MAP
	(
		clock => s_CLK_80Mhz,
		addr => s_RomAddr_cpu,
		dout => s_RomDataOut_cpu
	);

	-- PS2 Keyboard Controller
	keyboardController : entity work.PS2KeyboardController
	GENERIC MAP
	(
		p_ClockFrequency => 80_000_000 
	)
	PORT MAP
	(
		i_Clock => s_CLK_80MHz,
		i_Reset => s_reset,
		io_PS2Clock => PS2_Clock,
		io_PS2Data => PS2_Data,
		o_ScanCode => s_scan_code,
		o_ExtendedKey => s_extended_key,
		o_KeyRelease => s_key_release,
		o_DataAvailable => s_key_available
	);

	-- TRS80 Keyboard Switches
	keyboardMemoryMap : entity work.Trs80KeyMemoryMap
	PORT MAP
	(
		i_Clock => s_CLK_80Mhz,
		i_Reset => s_reset,
		i_ScanCode => s_scan_code,
		i_ExtendedKey => s_extended_key,
		i_KeyRelease => s_key_release,
		i_DataAvailable => s_key_available,
		i_Addr => s_cpu_addr(7 downto 0),
		o_Data => s_KeyboardMapDataOut_cpu
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
		CLK_n =>  s_CLK_80MHz,
		CLKEN => s_CLK_CPU_en,
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

	-- Memory range mapping
	memmap : process(s_cpu_addr)
	begin
		s_is_rom_range <= '0';
		s_is_vram_range <= '0';
		s_is_ram_range <= '0';
		s_is_keyboard_range <= '0';

		if s_cpu_addr(15 downto 14) /= "00" then
			-- RAM 0x4000 -> 0xFFFF
			s_is_ram_range <= '1';
		elsif s_cpu_addr(15 downto 10) = "001111" then
			-- Video RAM 0x3C00 -> 0x3FFF
			s_is_vram_range <= '1';
		elsif s_cpu_addr(15 downto 10) = "001110" then
			-- Keyboard 0x3800 -> 0x3BFF (shadowed 4 times)
			s_is_keyboard_range <= '1';
		elsif s_cpu_addr(15 downto 14) = "00" or s_cpu_addr(15 downto 14) = "01" or s_cpu_addr(15 downto 14) = "01" then
			-- ROM 0x0000 -> 0x2FFF
			s_is_rom_range <= '1';
		end if;
	end process;

	-- Generate addresses and write flags
	s_VideoRamAddr_cpu <= s_cpu_addr(9 downto 0);
	s_VideoRamWrite_cpu <= s_mem_wr and s_is_vram_range;
	s_VideoRamDataIn_cpu <= s_cpu_dout;

	s_RamAddr_cpu <= s_cpu_addr(13 downto 0);
	s_RamWrite_cpu <= s_mem_wr and s_is_ram_range;
	s_RamDataIn_cpu <= s_cpu_dout;
	s_RomAddr_cpu <= s_cpu_addr(13 downto 0);

	s_cpu_wait_n <= '1';

	cpu_data_in : process(s_mem_rd, 
							s_is_rom_range, s_RomDataOut_cpu, 
							s_is_ram_range, s_RamDataOut_cpu, 
							s_is_vram_range, s_VideoRamDataOut_cpu,
							s_is_keyboard_Range, s_KeyboardMapDataOut_cpu,
						  s_port_rd,
						  	s_is_cas_port, s_CasAudio, s_CasAudioEdge
							)
	begin

		s_cpu_din <= x"00";

		if s_mem_rd = '1' then
			if s_is_rom_range = '1' then
				s_cpu_din <= s_RomDataOut_cpu;
			elsif s_is_ram_range = '1' then
				s_cpu_din <= s_RamDataOut_cpu;
			elsif s_is_keyboard_range = '1' then
				s_cpu_din <= s_KeyboardMapDataOut_cpu;
			elsif s_is_vram_range = '1' then
				s_cpu_din <= s_VideoRamDataOut_cpu;
			end if;
		elsif s_port_rd = '1' then
			if s_is_cas_port = '1' then
				s_cpu_din <= s_CasAudioEdge & "000000" & s_CasAudio;
			else
				s_cpu_din <= x"FF";
			end if;
		end if;

	end process;

	--      audio signal        reading            sdhc             initok
	LEDs <= s_CasAudio & "0000" & s_sd_status(1) & s_sd_status(7) & s_sd_status(4);

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
	generic map
	(
		p_ClockDiv800Khz => 100,
		p_ClockDiv50Mhz => 2
	)
	port map
	(
		-- Clocking
		reset => s_reset,
		clock => s_CLK_80MHz,

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
		o_Audio => s_CasAudio
	);

	cas_edge_detect : process(s_CLK_80Mhz)
	begin
		if rising_edge(s_CLK_80Mhz) then
			if s_reset = '1' then
				s_CasAudioEdge <= '0';
				s_PrevCasAudio <= '0';
				s_Speaker <= "00";
			else

				-- Detect edge
				s_PrevCasAudio <= s_CasAudio;
				if s_PrevCasAudio /= s_CasAudio then 
					s_CasAudioEdge <= '1';
				end if;

				-- Clear flag
				if s_port_wr = '1' and s_is_cas_port='1' and s_CLK_CPU_en='1' then
					s_CasAudioEdge <= s_cpu_dout(7);
					s_Speaker <= s_cpu_dout(1 downto 0);
				end if;

			end if;
		end if;
	end process;

	-- Output audio on both channels
	s_Audio <= s_Speaker(0) xor s_CasAudio;
	Audio <= s_Audio & s_Audio;

end Behavioral;

