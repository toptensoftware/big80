--------------------------------------------------------------------------
--
-- DebounceFilterWithEdge
--
-- Debounced a signal, only switching to a new output signal if the 
-- input signal remains stable for a specified time period.
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

entity DebounceFilterWithEdge is
generic
(
    p_ClockFrequency : integer;         -- Hz.  eg: 100_000_000 for 100Mhz
    p_DebounceTimeUS : integer;          -- Time signal must be stable in us
    p_ResetState : std_logic := '0'    -- Starting state after reset
);
port 
( 
    -- Control
    i_Clock : in std_logic;             -- Clock
    i_Reset : in std_logic;             -- Reset (synchronous, active high)

    -- Inputs
    i_Signal : in std_logic;            -- The input signal
    
    -- Output
    o_Signal : out std_logic;           -- The output debounced signal
    o_SignalEdge : out std_logic        -- Asserted for one clock cycle when o_Signal has changed
);
end DebounceFilterWithEdge;

architecture Behavioral of DebounceFilterWithEdge is
    constant c_DebounceTicks : integer := p_ClockFrequency * p_DebounceTimeUS / 1000000;
    signal s_Current : std_logic;
    signal s_Previous : std_logic;
    signal s_Signal : std_logic;
    signal s_SignalEdge : std_logic;
begin

    -- Output the filtered signal and edge flag
    o_Signal <= s_Signal;
    o_SignalEdge <= s_SignalEdge;

    process (i_Clock)
        variable counter : integer range 0 to c_DebounceTicks;
    begin
        if rising_edge(i_Clock) then
            if i_Reset = '1' then
                -- Reset
                s_Current <= p_ResetState;
                s_Previous <= p_ResetState;
                s_Signal <= p_ResetState;
                s_SignalEdge <= '0';
            else
                -- Shift input signal
                s_Previous <= s_Current;
                s_Current <= i_Signal;
                s_SignalEdge <= '0';

                if (s_Current xor s_Previous) = '1' then
                    -- signal changed, reset the signal
                    counter := 0;
                elsif counter < c_DebounceTicks then 
                    -- stable period hasn't been hit yet, increment counter
                    counter := counter + 1;
                else
                    -- Signal is stable, output the new signal
                    s_Signal <= s_Current;

                    -- and edge flag
                    s_SignalEdge <= s_Signal xor s_Current;
                end if;
            end if;
        end if;        
    end process;
  
end Behavioral;

