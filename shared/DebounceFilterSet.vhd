--------------------------------------------------------------------------
--
-- DebounceFilterSet
--
-- Manages a set of debounced signals
--
-- The parameters p_clock_hz and p_stable_us control the
-- number of clock ticks the cycle must remain stable.
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity DebounceFilterSet is
generic
(
    p_clock_hz : integer;              -- Hz.  eg: 100_000_000 for 100Mhz
    p_stable_us : integer;          -- Time signal must be stable in us
    p_signal_count : integer;       -- The number of signals to debounce
    p_default_state : std_logic     -- The default (reset) state of all buttons
);
port 
( 
    -- Control
    i_clock : in std_logic;         -- Clock
    i_reset : in std_logic;         -- Reset (synchronous, active high)

    -- Inputs
    i_signals : in std_logic_vector(p_signal_count-1 downto 0);
    
    -- Output
    o_signals : out std_logic_vector(p_signal_count-1 downto 0);
    o_signal_edges : out std_logic_vector(p_signal_count-1 downto 0)
);
end DebounceFilterSet;

architecture Behavioral of DebounceFilterSet is
begin

    generate_signals: for ii in 0 to p_signal_count-1 generate

        debouncer : entity work.DebounceFilterWithEdge
        generic map
        (
            p_clock_hz => p_clock_hz,
            p_stable_us => p_stable_us,
            p_default_state => p_default_state
        )
        port map
        (
            i_clock => i_clock,
            i_reset => i_reset,
            i_signal => i_signals(ii),
            o_signal => o_signals(ii),
            o_signal_edge => o_signal_edges(ii)
        );

    end generate;

end Behavioral;

