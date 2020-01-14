--------------------------------------------------------------------------
--
-- PCKeyboarDecoder
--
-- Accepts bytes from a PC keyboard and decodes them into a single
-- event including the scan code, extended key flag and whether the
-- event was a press or release.
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity PCKeyboardDecoder is
port 
( 
    -- Control
    i_clock : in std_logic;                             -- Clock
    i_reset : in std_logic;                             -- Reset (synchronous, active high)
    
    -- Data from keyboard
    i_data : in std_logic_vector(7 downto 0);           -- Data byte from the keyboard
    i_data_available : in std_logic;                    -- Assert for 1 cycle when data is available
    i_data_error : in std_logic;                        -- Assert if there was an error in the data

    -- Generated keyboard event
    o_key_scancode : out std_logic_vector(6 downto 0);  -- Output scan code
    o_key_extended : out std_logic;                     -- 0 for normal key, 1 for extended key
    o_key_released : out std_logic;                     -- 0 if press, 1 if release
    o_key_available : out std_logic                     -- Asserted for one clock cycle on event
);
end PCKeyboardDecoder;

architecture Behavioral of PCKeyboardDecoder is
    signal s_key_available : std_logic;
begin

    -- Output the data available flag
    o_key_available <= s_key_available;

    process (i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                -- Reset
                o_key_released <= '0';
                o_key_extended <= '0';
                s_key_available <= '0';
            else
                -- Clear data available
                s_key_available <= '0';

                -- If event generated on the previous
                -- cycle, then reset the event flags
                if s_key_available = '1' then
                    o_key_released <= '0';
                    o_key_extended <= '0';
                end if;

                -- Input data available?
                if i_data_available = '1' then
                    if i_data_error = '1' then
                        -- Error, reset the flags
                        o_key_released <= '0';
                        o_key_extended <= '0';
                    else
                        if i_data = x"F0" then
                            -- This is a key release event
                            o_key_released <= '1';
                        elsif i_data = x"E0" then
                            -- This is an extended key code
                            o_key_extended <= '1';
                        elsif i_data(7) = '0' then
                            -- Scan codes are <= 127, generate
                            -- the outgoing event
                            o_key_scancode <= i_data(6 downto 0);
                            s_key_available <= '1';
                        else
                            -- Not sure what that was, reset for next
                            -- event                            
                            o_key_released <= '0';
                            o_key_extended <= '0';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;

