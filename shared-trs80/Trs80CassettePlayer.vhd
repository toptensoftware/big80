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

	-- User Interface
	i_ButtonStartStop : in std_logic;				-- Press to toggle play/stop
	i_ButtonRecord : in std_logic;					-- Hold while start to enter record mode
	i_ButtonNext : in std_logic;					-- Press to load next tape
	i_ButtonPrev : in std_logic;					-- Press to load prev tape
	o_SelectedTape : out std_logic_vector(11 downto 0);	-- selected tape number
	o_PlayingOrRecording : out std_logic;
	o_Recording : out std_logic;

	-- SD Inteface
	o_sd_op_wr : out std_logic;
	o_sd_op_cmd : out std_logic_vector(1 downto 0);
	o_sd_op_block_number : out std_logic_vector(31 downto 0);
	i_sd_status : in std_logic_vector(7 downto 0);
	i_sd_dcycle : in std_logic;
	i_sd_data : in std_logic_vector(7 downto 0);	
	o_sd_data : out std_logic_vector(7 downto 0);

	-- Audio
	o_Audio : out std_logic_vector(1 downto 0);		-- to Trs80
	i_Audio : in std_logic							-- from Trs80

);
end Trs80CassettePlayer;
 
architecture behavior of Trs80CassettePlayer is 
	signal s_streamer_reset : std_logic;
	signal s_sd_block_needed : std_logic;
	signal s_sd_block_available : std_logic;
	signal s_stop_recording : std_logic;
	signal s_recording_finished : std_logic;
	signal s_sd_op_block_number : std_logic_vector(31 downto 0);
	signal s_sd_op_wr : std_logic;
	signal s_playing_or_recording : std_logic;
	signal s_recording : std_logic;
	signal s_mode_changed : std_logic;		-- either playing or recording changed
	signal s_sd_op_pending : std_logic;
	signal s_selected_tape : std_logic_vector(11 downto 0);
	signal s_start_block_number : std_logic_vector(31 downto 0);
	signal s_play_position : std_logic_vector(31 downto 0);
	signal s_record_position : std_logic_vector(31 downto 0);
	signal s_position : std_logic_vector(31 downto 0);
begin

	-- Combinatorial outputs
	o_sd_op_cmd <= "01" when s_recording = '0' else "10";
	o_sd_op_block_number <= s_sd_op_block_number;
	o_sd_op_wr <= s_sd_op_wr;
	o_SelectedTape <= s_selected_tape when s_playing_or_recording='0' else s_position(11 downto 0);
	o_PlayingOrRecording <= s_playing_or_recording;
	o_Recording <= s_recording;

	-- Combinatirial Internal
	s_start_block_number <= "000000000000000" & s_selected_tape & "00000";		-- x 32
	s_record_position <= std_logic_vector(unsigned(s_sd_op_block_number) - unsigned(s_start_block_number));
	s_play_position <= std_logic_vector(unsigned(s_record_position) - 2);
	s_position <= s_record_position when s_recording = '1' else s_play_position;

	-- Handles start/stop user control of the cassette player
	-- (including waiting for final block flush after stopping recording)
	start_stop_control : process(i_Clock)
	begin
		if rising_edge(i_Clock) then
			if i_Reset = '1' then 
				s_playing_or_recording <= '0';
				s_recording <= '0';
				s_mode_changed <= '0';
				s_stop_recording <= '0';
			else
				s_mode_changed <= '0';

				if s_stop_recording = '1' then

					-- Wait for final block to be flushed
					if s_recording_finished = '1' then
						s_playing_or_recording <= '0';
						s_recording <= '0';
						s_mode_changed <= '1';
						s_stop_recording <= '0';
					end if;

				elsif i_ButtonStartStop = '1' then

					if s_playing_or_recording = '0' then
						-- Start play/record
						s_playing_or_recording <= '1';
						s_recording <= i_ButtonRecord;
						s_mode_changed <= '1';
					else
						-- Stop play/record
						if s_recording = '1' then 
							-- For recording, need to wait for last
							-- block to be flushed
							s_stop_recording <= '1';
						else
							-- For playback just stop immedately
							s_playing_or_recording <= '0';
							s_mode_changed <= '1';
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;

	-- Handles next/prev tape select buttons
	-- (unresponsive during play/record)
	tape_selector : process(i_Clock)
	begin
		if rising_edge(i_Clock) then
			if i_Reset = '1' then 
				s_selected_tape <= (others => '0');
			elsif s_playing_or_recording = '0' then
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

		i_RecordMode => s_recording,

		o_BlockNeeded => s_sd_block_needed,
		o_Audio => o_Audio,

		i_Audio => i_Audio,
		o_BlockAvailable => s_sd_block_available,
		i_StopRecording => s_stop_recording,
		o_RecordingFinished => s_recording_finished,	

		i_DataCycle => i_sd_dcycle,
		i_Data => i_sd_data,
		o_Data => o_sd_data
	);

	-- Hold the stream in reset state when not playing or recording
	s_streamer_reset <= '1' when i_Reset = '1' or s_playing_or_recording = '0' else '0';

	-- generates read/write commands for the SD card controller and  increments 
	-- block number after each comamd has been invoked
	sd_command_generator : process(i_Clock)
	begin
		if rising_edge(i_Clock) then 
			if i_Reset = '1' then
				s_sd_op_wr <= '0';
				s_sd_op_block_number <= (others => '0');
				s_sd_op_pending <= '0';
			else
				s_sd_op_wr <= '0';

				-- Setup the starting block number 
				if s_mode_changed = '1' and s_playing_or_recording = '1' then
					s_sd_op_block_number <= s_start_block_number;
				end if;

				-- If the streamer needs, or has available a block
				-- then start the next SD card operation
				if s_sd_block_needed = '1' or s_sd_block_available = '1' then
					s_sd_op_pending <= '1';
				end if;

				-- Wait for SD controller to become idle before sending
				-- the read or write command
				if s_sd_op_pending = '1' and i_sd_status(0) = '0' then
					s_sd_op_wr <= '1';
					s_sd_op_pending <= '0';
				end if;

				-- Once we've invoked the command for the current block
				-- increment the block number ready for the next op
				if s_sd_op_wr = '1' then 
					s_sd_op_block_number <= std_logic_vector(unsigned(s_sd_op_block_number) + 1);
				end if;
			end if;
		end if;
	end process;

end;


