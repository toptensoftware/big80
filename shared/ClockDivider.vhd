--------------------------------------------------------------------------
--
-- ClockDivider
--
-- Divides a clock signal by an arbitrary number of cycles, producing
-- an active high signal every p_period.
--
-- During reset, the generated clock enable signal will be held at '0'.
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity ClockDivider is
generic
(
    p_period : integer                  -- Period of the clock enable (in clock cycles)
);
port 
( 
    -- Control
    i_clock : in std_logic;             -- Clock
    i_clken : in std_logic;             -- Clock Enable for clock being divided
    i_reset : in std_logic;             -- Reset (synchronous, active high)
    
    -- Output
    o_clken : out std_logic             -- Generated clock enable signal
);
end ClockDivider;

architecture Behavioral of ClockDivider is

    signal s_divider: integer range 0 to p_period - 1;

begin

    -- Clock enabled?
    o_clken <= '1' when s_divider = 0 and i_reset = '0' and i_clken = '1' else '0';

	-- Process to handle clock ticks
	process (i_clock)
	begin
		if rising_edge(i_clock) then
            if i_reset='1' then
                s_divider <= 0;
            elsif i_clken = '1' then
                if s_divider = p_period - 1 then
                    s_divider <= 0;
                else
                    s_divider <= s_divider + 1;
                end if;
            end if;
        end if;
	end process;

end Behavioral;

