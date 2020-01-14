--------------------------------------------------------------------------
--
-- Trs80AutoCassette
--
-- Monitors the output of the TRS-80 cassette port and generates signals
-- that can be used to automatically start and stop the cassette player
-- 
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity Trs80AutoCassette is
generic
(
	p_clken_hz : integer;							-- Frequency of the clock enable
	p_monitor_ms : integer := 8						-- How long to monitor after motor turning on
													-- (8 = 4 zero bit pulses)
);
port
(
    -- Control
	i_clock : in std_logic;                         -- Clock
	i_clken : in std_logic;							-- Clock Enable
	i_reset : in std_logic;                         -- Reset (synchronous, active high)
	
	-- Input
	i_motor : in std_logic;							-- Motor control bit
	i_audio : in std_logic;							-- The audio signal to be monitored

	-- Output
	o_start : out std_logic;						-- Asserts for one cycle when cassette operation should start
	o_record : out std_logic;						-- Asserted with o_start_stop if operation is record operation
	o_stop : out std_logic							-- Asserted for one cycle when cassette operation should stop
);
end Trs80AutoCassette;
 
architecture behavior of Trs80AutoCassette is 

	-- How many ticks to monitor for after the motor is turned on before deciding if it's a record or play operation
	constant c_monitor_ticks : integer := p_clken_hz * p_monitor_ms / 1000;

	signal s_playing_or_recording : std_logic;		-- '1' when current playing or recording
	signal s_audio_prev : std_logic;
	signal s_any_edges : std_logic;
	signal s_ticks_since_motor_on : integer range 0 to c_monitor_ticks;

begin

	-- Count how many ticks since the motor turn on
	idle_timer : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then
				s_ticks_since_motor_on <= 0;
				s_any_edges <= '0';
				s_audio_prev <= '0';
			elsif i_clken = '1' then

				-- Track audio edges
				s_audio_prev <= i_audio;

				if i_motor = '0' then

					-- Motor is off, hold everything in default state 
					s_ticks_since_motor_on <= 0;
					s_any_edges <= '0';

				else

					-- Update idle timer
					if s_ticks_since_motor_on /= c_monitor_ticks then
						s_ticks_since_motor_on <= s_ticks_since_motor_on + 1;
					end if;

					-- Watch for a positive edge on the audio
					if s_audio_prev = '0' and i_audio = '1' then
						s_any_edges <= '1';
					end if;
	
				end if;

			end if;
		end if;
	end process;

	control : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then

				o_start <= '0';
				o_record <= '0';
				o_stop <= '0';
				s_playing_or_recording <= '0';
			
			elsif i_clken = '1' then

				-- These are pulses, default them to off
				o_start <= '0';
				o_record <= '0';
				o_stop <= '0';
				
				if s_playing_or_recording = '1' then

					-- If currently playing watch for motor turning off
					if i_motor = '0' then
						o_stop <= '1';
						s_playing_or_recording <= '0';
					end if;

				else

					-- If currently not playing watch for motor turning on...
					if i_motor = '1' then

						-- ...and then monitor for a bit and if any audio activity detected
						-- then start a record operation (otherwise it's a play)
						if s_ticks_since_motor_on = c_monitor_ticks or s_any_edges = '1' then

							o_start <= '1';
							o_record <= s_any_edges;
							s_playing_or_recording <= '1';

						end if;
					
					end if;

				end if;
			end if;
		end if;
	end process;


end;
