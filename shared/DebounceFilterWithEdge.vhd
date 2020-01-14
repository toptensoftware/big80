--------------------------------------------------------------------------
--
-- DebounceFilterWithEdge
--
-- Debounced a signal, only switching to a new output signal if the 
-- input signal remains stable for a specified time period.
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

entity DebounceFilterWithEdge is
generic
(
    p_clock_hz : integer;                      -- Hz.  eg: 100_000_000 for 100Mhz
    p_stable_us : integer;                  -- Time signal must be stable in us
    p_default_state : std_logic := '0'      -- Starting state after reset
);
port 
( 
    -- Control
    i_clock : in std_logic;                 -- Clock
    i_reset : in std_logic;                 -- Reset (synchronous, active high)

    -- Inputs
    i_signal : in std_logic;                -- The input signal
    
    -- Output
    o_signal : out std_logic;               -- The output debounced signal
    o_signal_edge : out std_logic           -- Asserted for one clock cycle when o_signal has changed
);
end DebounceFilterWithEdge;

architecture Behavioral of DebounceFilterWithEdge is
    constant c_debounce_ticks : integer := integer(real(p_clock_hz) * real(p_stable_us) / 1000000.0);
    signal s_current : std_logic;
    signal s_previous : std_logic;
    signal s_output : std_logic;
    signal s_signal_edge : std_logic;
    signal s_counter : integer range 0 to c_debounce_ticks;
begin

    -- Output the filtered signal and edge flag
    o_signal <= s_output;
    o_signal_edge <= s_signal_edge;

    process (i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                -- Reset
                s_current <= p_default_state;
                s_previous <= p_default_state;
                s_output <= p_default_state;
                s_signal_edge <= '0';
                s_counter <= 0;
            else
                -- Shift input signal
                s_previous <= s_current;
                s_current <= i_signal;
                s_signal_edge <= '0';

                if (s_current xor s_previous) = '1' then
                    -- signal changed, reset the signal
                    s_counter <= 0;
                elsif s_counter < c_debounce_ticks then 
                    -- stable period hasn't been hit yet, increment s_counter
                    s_counter <= s_counter + 1;
                else
                    -- Signal is stable, output the new signal
                    s_output <= s_current;

                    -- and edge flag
                    s_signal_edge <= s_output xor s_current;
                end if;
            end if;
        end if;        
    end process;
  
end Behavioral;

