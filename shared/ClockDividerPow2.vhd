--------------------------------------------------------------------------
--
-- ClockDividerPow2
--
-- Divides a clock signal by 2^N cycles for up to 4 different values
-- of N.
--
-- For each divider, the associated o_clken signal will be asserted
-- for one clock cycle every 2^N cycles.
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

entity ClockDividerPow2 is
generic
(
    -- Nuber of bits for each divider
    p_divider_width_1 : integer;
    p_divider_width_2 : integer := 1;
    p_divider_width_3 : integer := 1;
    p_divider_width_4 : integer := 1
);
port 
( 
    -- Control
    i_clock : in std_logic;             -- Clock
    i_reset : in std_logic;             -- Reset (synchronous, active high)
    
    -- Output
    o_clken_1 : out std_logic;          -- Generated clock enable
    o_clken_2 : out std_logic;          -- Generated clock enable
    o_clken_3 : out std_logic;          -- Generated clock enable
    o_clken_4 : out std_logic           -- Generated clock enable
);
end ClockDividerPow2;

architecture Behavioral of ClockDividerPow2 is

    signal s_divider: unsigned(IntMax(IntMax(IntMax(p_divider_width_1, p_divider_width_2), p_divider_width_3), p_divider_width_4)-1 downto 0);

begin

    -- Clock enabled?
    o_clken_1 <= '1' when s_divider(p_divider_width_1-1 downto 0) = 0 and i_reset = '0' else '0';
    o_clken_2 <= '1' when s_divider(p_divider_width_2-1 downto 0) = 0 and i_reset = '0' else '0';
    o_clken_3 <= '1' when s_divider(p_divider_width_3-1 downto 0) = 0 and i_reset = '0' else '0';
    o_clken_4 <= '1' when s_divider(p_divider_width_4-1 downto 0) = 0 and i_reset = '0' else '0';

	-- Process to handle clock ticks
	process (i_clock)
	begin
		if rising_edge(i_clock) then
            if i_reset='1' then
                s_divider <= (others => '0');
            else
    			s_divider <= s_divider + 1;
            end if;
        end if;
	end process;

end Behavioral;

