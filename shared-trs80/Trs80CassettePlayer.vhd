--------------------------------------------------------------------------
--
-- Trs80CassettePlayer
--
-- Implements a virtual cassette player providing the following:
--
--   * buttons to select the next/previous tape
--   * button to start/stop playback
--   * outputs selected tape/current block play position
--   * tapes are assumed to be at 16k boundaries (ie: every 32 blocks)
--       on the SD card
--   * drives SD controller to start read operations and streams
--       the read data into a Trs80CassetteStreamer to produce audio
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity Trs80CassettePlayer is
generic
(
	p_ClockEnableFrequency : integer := 1_774_000;  -- Frequency of the clock enable
	p_BaudRate : integer := 500;					-- Frequency of zero bit pulses
	p_PulseWidth_us : integer := 100				-- Width of each pulse (in us)
);
port
(
    -- Control
	i_Clock : in std_logic;                         -- Main Clock
	i_ClockEnable : in std_logic;					-- Clock Enable
	i_Reset : in std_logic;                         -- Reset (synchronous, active high)

	-- Control buttons
	i_ButtonStartStop : in std_logic;				-- Press to toggle play/stop
	i_ButtonNext : in std_logic;					-- Press to load next tape
	i_ButtonPrev : in std_logic;					-- Press to load prev tape

	-- SD Inteface
	o_sd_op_wr : out std_logic;
	o_sd_op_cmd : out std_logic_vector(1 downto 0);
	o_sd_op_block_number : out std_logic_vector(31 downto 0);
	i_sd_status : in std_logic_vector(7 downto 0);
	i_sd_dcycle : in std_logic;
	i_sd_data : in std_logic_vector(7 downto 0);	

	-- Output
	o_SelectedTape : out std_logic_vector(11 downto 0);	-- selected tape number
	o_Audio : out std_logic							-- generated audio signal

);
end Trs80CassettePlayer;
 
architecture behavior of Trs80CassettePlayer is 
	signal s_streamer_reset : std_logic;
	signal s_data_needed : std_logic;
	signal s_sd_op_block_number : std_logic_vector(31 downto 0);
	signal s_sd_op_wr : std_logic;
	signal s_playing : std_logic;
	signal s_playing_changed : std_logic;
	signal s_req_pending : std_logic;
	signal s_selected_tape : std_logic_vector(11 downto 0);
	signal s_start_block_number : std_logic_vector(31 downto 0);
	signal s_play_position : std_logic_vector(31 downto 0);
begin

	-- Output request block number
	o_sd_op_block_number <= s_sd_op_block_number;
	o_sd_op_wr <= s_sd_op_wr;
	o_SelectedTape <= s_selected_tape when s_playing='0' else s_play_position(11 downto 0);

	s_start_block_number <= "000000000000000" & s_selected_tape & "00000";		-- x 32
	s_play_position <= std_logic_vector(unsigned(s_sd_op_block_number) - unsigned(s_start_block_number) - 2);

	play_pause : process(i_Clock)
	begin
		if rising_edge(i_Clock) then
			if i_Reset = '1' then 
				s_playing <= '0';
				s_playing_changed <= '0';
			else
				s_playing_changed <= '0';
				if i_ButtonStartStop = '1' then
					s_playing <= not s_playing;
					s_playing_changed <= '1';
				end if;
			end if;
		end if;
	end process;

	tape_selector : process(i_Clock)
	begin
		if rising_edge(i_Clock) then
			if i_Reset = '1' then 
				s_selected_tape <= (others => '0');
			else
			if i_ButtonNext = '1' then
				s_selected_tape <= std_logic_vector(unsigned(s_selected_tape) + 1);
			end if;
			if i_ButtonPrev = '1' then
				s_selected_tape <= std_logic_vector(unsigned(s_selected_tape) - 1);
			end if;
			end if;
		end if;
	end process;

	-- Cassette streamer
	streamer : entity work.Trs80CassetteStreamer
	generic map
	(
		p_ClockEnableFrequency => p_ClockEnableFrequency,
		p_BaudRate => p_BaudRate,
		p_PulseWidth_us => p_PulseWidth_us
	)
	port map
	(
		i_Clock => i_Clock,
		i_ClockEnable => i_ClockEnable,
		i_Reset => s_streamer_reset,
		i_RecordMode => '0',
		i_Data => i_sd_data,
		i_DataAvailable => i_sd_dcycle,
		o_DataNeeded => s_data_needed,
		o_Audio => o_Audio,

		i_Audio => '0',
		o_DataAvailable => open,
		i_DataNeeded => '0',
		o_Data => open,
		i_StopRecording => '0',
		o_RecordingFinished => open	
	);

	s_streamer_reset <= '1' when i_Reset = '1' or s_playing = '0' else '0';

	-- generates read commands and increments block number after
	-- each read comamd has been issued
	sd_command_generator : process(i_Clock)
	begin
		if rising_edge(i_Clock) then 
			if i_Reset = '1' then
				s_sd_op_wr <= '0';
				o_sd_op_cmd <= "01";		 -- read
				s_sd_op_block_number <= (others => '0');
				s_req_pending <= '0';
			else
				s_sd_op_wr <= '0';

				if s_playing_changed = '1' and s_playing = '1' then
					s_sd_op_block_number <= s_start_block_number;
				end if;

				if s_data_needed = '1' then
					s_req_pending <= '1';
				end if;

				if s_req_pending = '1' and i_sd_status(0) = '0' then
					s_sd_op_wr <= '1';
					s_req_pending <= '0';
				end if;

				if s_sd_op_wr = '1' then 
					s_sd_op_block_number <= std_logic_vector(unsigned(s_sd_op_block_number) + 1);
				end if;
			end if;
		end if;
	end process;

end;


