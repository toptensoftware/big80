--------------------------------------------------------------------------
--
-- Trs80FakeCassetteAudio
--
-- Produces an valid, but fake TRS-80 cassette audio stream
--   00 00 00 00 00 A5 00 01 02 03 04 05
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.Trs80VirtualKeyCodes.ALL;

entity Trs80FakeCassetteAudio is
generic
(
	p_ClockEnableFrequency : integer := 1_774_000;  -- Frequency of the clock enable
	p_BaudRate : integer := 500					-- Frequency of zero bit pulses
);
port
(
    -- Control
	i_Clock : in std_logic;                         -- Main Clock
	i_ClockEnable : in std_logic;					-- Clock Enable
	i_Reset : in std_logic;                         -- Reset (synchronous, active high)

	-- Output
	o_Audio : out std_logic
);
end Trs80FakeCassetteAudio;
 
architecture behavior of Trs80FakeCassetteAudio is 
    signal s_render_data : std_logic_vector(7 downto 0);
    signal s_render_data_needed : std_logic;
begin

    -- Produces the stream of bytes we want to record
    gen_data : process(i_Clock)
        variable count : integer range 0 to 6 := 0;
    begin
        if rising_edge(i_Clock) then
            if i_Reset = '1' then
                s_render_data <= x"00";
                count := 0;
            elsif i_ClockEnable = '1' then            
                if s_render_data_needed = '1' then
                    if count < 4 then
                        s_render_data <= x"00";
                        count := count + 1;
                    elsif count = 4 then
                        s_render_data <= x"A5";
                        count := count + 1;
                    elsif count = 5 then
                        s_render_data <= x"00";
                        count := count + 1;
                    else
					   	if s_render_data = x"07" then
							s_render_data <= x"00";
					   	else
							s_render_data <= std_logic_vector(unsigned(s_render_data) + 1);
						end if;
                    end if;

                end if;
            end if;
        end if;
    end process;

    -- Render a stream of audio to record
	renderer : entity work.Trs80CassetteRenderer
	generic map
	(
		p_ClockEnableFrequency => p_ClockEnableFrequency, 
		p_BaudRate => p_BaudRate
	)
    port map
    (
        i_Clock => i_Clock,
        i_ClockEnable => i_ClockEnable,
        i_Reset => i_Reset,
        i_Data => s_render_data,
        o_DataNeeded => s_render_data_needed,
        o_Audio => o_Audio
    );

end;
