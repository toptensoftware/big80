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
    i_Clock : in std_logic;                         -- Clock
    i_Reset : in std_logic;                         -- Reset (synchronous, active high)
    
    -- Data from keyboard
    i_Data : in std_logic_vector(7 downto 0);       -- Data byte from the keyboard
    i_DataAvailable : in std_logic;                 -- Assert for 1 cycle when data is available
    i_Error : in std_logic;                         -- Assert if there was an error in the data

    -- Generated keyboard event
    o_ScanCode : out std_logic_vector(6 downto 0);  -- Output scan code
    o_ExtendedKey : out std_logic;                  -- 0 for normal key, 1 for extended key
    o_KeyRelease : out std_logic;                   -- 0 if press, 1 if release
    o_DataAvailable : out std_logic                 -- Asserted for one clock cycle on event
);
end PCKeyboardDecoder;

architecture Behavioral of PCKeyboardDecoder is
    signal s_DataAvailable : std_logic;
begin

    -- Output the data available flag
    o_DataAvailable <= s_DataAvailable;

    process (i_Clock)
    begin
        if rising_edge(i_Clock) then
            if i_Reset = '1' then
                -- Reset
                o_KeyRelease <= '0';
                o_ExtendedKey <= '0';
                s_DataAvailable <= '0';
            else
                -- Clear data available
                s_DataAvailable <= '0';

                -- If event generated on the previous
                -- cycle, then reset the event flags
                if s_DataAvailable = '1' then
                    o_KeyRelease <= '0';
                    o_ExtendedKey <= '0';
                end if;

                -- Input data available?
                if i_DataAvailable = '1' then
                    if i_Error = '1' then
                        -- Error, reset the flags
                        o_KeyRelease <= '0';
                        o_ExtendedKey <= '0';
                    else
                        if i_Data = x"F0" then
                            -- This is a key release event
                            o_KeyRelease <= '1';
                        elsif i_Data = x"E0" then
                            -- This is an extended key code
                            o_ExtendedKey <= '1';
                        elsif i_Data(7) = '0' then
                            -- Scan codes are <= 127, generate
                            -- the outgoing event
                            o_ScanCode <= i_Data(6 downto 0);
                            s_DataAvailable <= '1';
                        else
                            -- Not sure what that was, reset for next
                            -- event                            
                            o_KeyRelease <= '0';
                            o_ExtendedKey <= '0';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;

