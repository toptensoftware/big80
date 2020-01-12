--------------------------------------------------------------------------
--
-- Trs80CassetteRenderer
--
-- Renders TRS-80 500 Baud audio cassette signals
--
--   * takes a single byte at a time and generates an audio signal for it
--   * asserts o_DataNeeded for one cycle when a new data byte is needed
--   * after o_DataNeeded has been asserted the new byte must be available
--      on the next clock cycle
--
-- This component constantly produces an audio signal.  When not in use,
-- assert i_Reset to go silent.
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity Trs80CassetteRenderer is
generic
(
	p_ClockEnableFrequency : integer;  				-- Frequency of the clock enable
	p_BaudRate : integer := 500;					-- Frequency of zero bit pulses
	p_PulseWidth_us : integer := 100				-- Width of each pulse (in us)
);
port
(
    -- Control
	i_Clock : in std_logic;                         -- Clock
	i_ClockEnable : in std_logic;					-- Clock Enable
	i_Reset : in std_logic;                         -- Reset (synchronous, active high)
	
	-- Input
	i_Data : in std_logic_vector(7 downto 0);			-- The byte to be rendered

	-- Output
	o_DataNeeded : out std_logic;					-- Asserts high for one clock cycle when next byte needed
	o_Audio : out std_logic							-- generated audio signal
);
end Trs80CassetteRenderer;
 
architecture behavior of Trs80CassetteRenderer is 

	-- The width of each pulse in clock enabled ticks (177)
	constant c_PulseWidth_ticks : integer := p_PulseWidth_us * p_ClockEnableFrequency / 1_000_000;

	-- Baud rate converted to clock ticks (3548)
	constant c_BaudRate_ticks : integer := p_ClockEnableFrequency  / p_BaudRate;

	signal s_BaudRateDivider : integer range 0 to c_BaudRate_ticks - 1;
	signal s_CurrentByte : std_logic_vector(7 downto 0);
	signal s_BitCounter : integer range 0 to 7;
begin

	-- Byte shifter
	byte_shifter : process(i_Clock)
	begin
		if rising_edge(i_Clock) then
			if i_Reset = '1' then
				s_CurrentByte <= x"00";
				s_BitCounter <= 0;
			elsif i_ClockEnable = '1' then
				if s_BaudRateDivider = c_BaudRate_ticks - 1 then
					if s_BitCounter = 7 then
						s_CurrentByte <= i_Data;
						s_BitCounter <= 0;
					else
						s_CurrentByte <= s_CurrentByte(6 downto 0) & '0';
						s_BitCounter <= s_BitCounter + 1;
					end if;
				end if;
			end if;
		end if;
	end process;

	o_DataNeeded <= 
		'1' when s_BitCounter = 7 and s_BaudRateDivider = c_BaudRate_ticks - 2
		else '0';

	-- Divide clock to baud rate
	audio_clock : process(i_Clock)
	begin
		if rising_edge(i_Clock) then
			if i_Reset = '1' then
				s_BaudRateDivider <= 0;
			elsif i_ClockEnable = '1' then
				if s_BaudRateDivider = c_BaudRate_ticks - 1 then
					s_BaudRateDivider <= 0;
				else
					s_BaudRateDivider <= s_BaudRateDivider + 1;
				end if;
			end if;
		end if;
	end process;

	-- Generate audio
	o_Audio <= 
		'0' when
			i_Reset = '1'
		else '1' when 
			s_BaudRateDivider < c_PulseWidth_ticks 
		else '1' when 
			s_CurrentByte(7) = '1' and 
			s_BaudRateDivider >= (c_BaudRate_ticks / 2) and 
			s_BaudRateDivider < (c_BaudRate_ticks / 2) + c_PulseWidth_ticks 
		else '0';


end;
