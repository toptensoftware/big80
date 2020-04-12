--------------------------------------------------------------------------
--
-- Trs80CassetteController
--
-- Implements a virtual cassette controller providing the following:
--
-- This component is driven by the syscon software to start/stop
-- playback/record, provide SD block numbers etc...
-- 
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity Trs80CassetteController is
generic
(
	p_clken_hz : integer := 1_774_000  -- Frequency of the clock enable
);
port
(
    -- Control
	i_clock : in std_logic;                         -- Main Clock
	i_clken_audio : in std_logic;					-- Clock Enable
	i_clken_cpu : in std_logic;						-- Clock Enable
	i_reset : in std_logic;                         -- Reset (synchronous, active high)

	-- User Interface
	i_command_play : in std_logic;					-- Assert to start playback/recording
	i_command_record : in std_logic;				-- Assert with i_command_play to enter record mode
	i_command_stop : std_logic;						-- Assert to stop playback/recording
	
	-- Output status
	o_status_playing : out std_logic;
	o_status_recording : out std_logic;
	o_status_need_block_number : out std_logic;

	-- Raised for one clken_cpu cycle anytime any of the above status bits change
	o_irq : out std_logic;

	-- Block number register
	i_block_number : in std_logic_vector(31 downto 0);
	i_block_number_load : in std_logic;

	-- SD Inteface
	o_sd_op_wr : out std_logic;
	o_sd_op_cmd : out std_logic_vector(1 downto 0);
	o_sd_op_block_number : out std_logic_vector(31 downto 0);
	i_sd_status : in std_logic_vector(7 downto 0);
	i_sd_dcycle : in std_logic;
	i_sd_data : in std_logic_vector(7 downto 0);	
	o_sd_data : out std_logic_vector(7 downto 0);

	debug : out std_logic_vector(7 downto 0);

	-- Audio
	o_audio : out std_logic_vector(1 downto 0);		-- to Trs80
	i_audio : in std_logic							-- from Trs80

);
end Trs80CassetteController;
 
architecture behavior of Trs80CassetteController is 
	signal s_streamer_reset : std_logic;
	signal s_streamer_block_needed : std_logic;
	signal s_streamer_block_available : std_logic;
	signal s_stop_recording : std_logic;
	signal s_recording_finished : std_logic;
	signal s_sd_op_wr : std_logic;
	signal s_playing_or_recording : std_logic;
	signal s_recording : std_logic;
	signal s_need_block_number : std_logic;
	signal s_mode_changed : std_logic;		-- either playing or recording changed

	signal s_prev_need_block_number : std_logic;

	type states is
	(
		state_idle,
		state_waiting_block_number,
		state_waiting_sd_not_busy
	);

	signal s_state : states := state_idle;
begin

	-- Combinatorial outputs
	o_sd_op_cmd <= "01" when s_recording = '0' else "10";
	o_sd_op_block_number <= i_block_number;
	o_sd_op_wr <= s_sd_op_wr;
	o_status_playing <= s_playing_or_recording and not s_recording;
	o_status_recording <= s_recording;
	s_need_block_number <= '1' when s_state = state_waiting_block_number else '0';
	o_status_need_block_number <= s_need_block_number;


	-- Generate IRQ whenever any of the output status bits change
	irq_gen : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then
				s_prev_need_block_number <= '0';
				o_irq <= '0';
			elsif i_clken_cpu = '1' then

				-- Pulse irq on rising edge of need block number, or when 
				-- the play/record status bits change
				o_irq <= '0';
				s_prev_need_block_number <= s_need_block_number;
				if (s_prev_need_block_number = '0' and s_need_block_number = '1') or s_mode_changed = '1' then
					o_irq <= '1';
				end if;

			end if;
		end if;
	end process;

	-- Handles start/stop control of the cassette player
	-- (including waiting for final block flush after stopping recording)
	start_stop_control : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then 
				s_playing_or_recording <= '0';
				s_recording <= '0';
				s_mode_changed <= '0';
				s_stop_recording <= '0';
				debug(3 downto 0) <= "1000";
			elsif i_clken_cpu = '1' then
				s_mode_changed <= '0';

				if s_stop_recording = '1' then

					-- Wait for final block to be flushed
					if s_recording_finished = '1' then
						s_playing_or_recording <= '0';
						s_recording <= '0';
						s_mode_changed <= '1';
						s_stop_recording <= '0';
					end if;

				elsif (i_command_play = '1' or i_command_record = '1') and s_playing_or_recording = '0' then

					-- Start play/record
					s_playing_or_recording <= '1';
					s_recording <= i_command_record;
					s_mode_changed <= '1';
					debug(0) <= '1';

				elsif i_command_stop = '1' and s_playing_or_recording = '1' then

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

					debug(1) <= '1';

				end if;
			end if;
		end if;
	end process;

	-- Cassette streamer
	streamer : entity work.Trs80CassetteStreamer
	generic map
	(
		p_clken_hz => p_clken_hz
	)
	port map
	(
		i_clock => i_clock,
		i_clken => i_clken_audio,
		i_reset => s_streamer_reset,
		i_record_mode => s_recording,
		o_block_needed => s_streamer_block_needed,
		o_audio => o_audio,
		i_audio => i_audio,
		o_block_available => s_streamer_block_available,
		i_stop_recording => s_stop_recording,
		o_recording_finished => s_recording_finished,	
		i_data_cycle => i_sd_dcycle,
		i_data => i_sd_data,
		o_data => o_sd_data
	);

	-- Hold the streamer in reset state when not playing or recording
	s_streamer_reset <= '1' when i_reset = '1' or s_playing_or_recording = '0' else '0';

	-- generates read/write commands for the SD card controller and requests next block
	-- numbers as needed
	sd_command_generator : process(i_clock)
	begin
		if rising_edge(i_clock) then 
			if i_reset = '1' then
				s_sd_op_wr <= '0';
				s_state <= state_idle;
				debug(7 downto 4) <= (others => '0');
			else
				s_sd_op_wr <= '0';

				-- Aborted?
				if s_playing_or_recording = '0' then
					s_state <= state_idle;
				else

					case s_state is

						when state_idle =>
							if s_streamer_block_needed = '1' or s_streamer_block_available = '1' then
								s_state <= state_waiting_block_number;
								debug(4) <= '1';
							end if;

						when state_waiting_block_number =>
							if i_block_number_load = '1' then
								s_state <= state_waiting_sd_not_busy;
								debug(5) <= '1';
							end if;

						when state_waiting_sd_not_busy =>
							if i_sd_status(0) = '0' then
								s_sd_op_wr <= '1';
								s_state <= state_idle;
								debug(6) <= '1';
							end if;

					end case;
				end if;

			end if;
		end if;
	end process;

end;


