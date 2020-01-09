--------------------------------------------------------------------------
--
-- DebounceFilterSet
--
-- Manages a set of debounced signals
--
-- The parameters p_ClockFrequency and p_DebounceTimeUS control the
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
    p_ClockFrequency : integer;         -- Hz.  eg: 100_000_000 for 100Mhz
    p_DebounceTimeUS : integer;         -- Time signal must be stable in us
    p_SignalCount : integer;            -- The number of signals to debounce
    p_ResetState : std_logic_vector(p_SignalCount-1 downto 0) := (others => '0')
);
port 
( 
    -- Control
    i_Clock : in std_logic;             -- Clock
    i_Reset : in std_logic;             -- Reset (synchronous, active high)

    -- Inputs
    i_Signals : in std_logic_vector(p_SignalCount-1 downto 0);
    
    -- Output
    o_Signals : out std_logic_vector(p_SignalCount-1 downto 0);
    o_SignalEdges : out std_logic_vector(p_SignalCount-1 downto 0)
);
end DebounceFilterSet;

architecture Behavioral of DebounceFilterSet is
begin

    generate_signals: for ii in 0 to p_SignalCount-1 generate

        debouncer : entity work.DebounceFilterWithEdge
        generic map
        (
            p_ClockFrequency => p_ClockFrequency,
            p_DebounceTimeUS => p_DebouncTimeUS,
            p_ResetState => p_ResetState(ii),
        )
        port map
        (
            i_Clock => i_Clock,
            i_Reset => i_Reset,
            i_Signal => i_Signals(ii),
            o_Signal => o_Signals(ii),
            o_SignalEdge => o_SignalEdges(ii)
        );

    end generate;

end Behavioral;

