--------------------------------------------------------------------------
--
-- PS2KeyboardController
--
-- Combines PS2Input and PCKeyboardDecoder to produce keyboard events
-- for a keyboard attached to a PS2 connector.
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity PS2KeyboardController is
generic
(
    p_clock_hz : integer                                   -- In Hz, Used to calculate timings
);
port 
( 
    -- Control
    i_clock : in std_logic;                             -- Clock
    i_reset : in std_logic;                             -- Reset (synchronous, active high)
        
    -- PS2 Signals
    io_ps2_clock : inout std_logic;                     -- PS2 Clock
    io_ps2_data : inout std_logic;                      -- PS2 Data

    -- Generated keyboard event
    o_key_scancode : out std_logic_vector(6 downto 0);  -- Output scan code
    o_key_extended : out std_logic;                  	-- 0 for normal key, 1 for extended key
    o_key_released : out std_logic;                   	-- 0 if press, 1 if release
    o_key_available : out std_logic                 	-- Asserted for one clock cycle on event
);
end PS2KeyboardController;

architecture Behavioral of PS2KeyboardController is
    signal s_ps2_data : std_logic_vector(7 downto 0);
    signal s_ps2_data_available : std_logic;
    signal s_ps2_data_error : std_logic;
begin

    ps2 : entity work.PS2Input
    GENERIC MAP
    (
        p_clock_hz => p_clock_hz 
    )
    PORT MAP
    (
        i_clock => i_clock,
        i_reset => i_reset,
        io_ps2_clock => io_ps2_clock,
        io_ps2_data => io_ps2_data,
        o_rx_data => s_ps2_data,
        o_rx_data_available => s_ps2_data_available,
        o_rx_error => s_ps2_data_error
    );

    keyboardDecoder : entity work.PCKeyboardDecoder
    PORT MAP
    (
        i_clock => i_clock,
        i_reset => i_reset,
        i_data => s_ps2_data,
        i_data_available => s_ps2_data_available,
        i_data_error => s_ps2_data_error,
        o_key_scancode => o_key_scancode,
        o_key_extended => o_key_extended,
        o_key_released => o_key_released,
        o_key_available => o_key_available
    );


end Behavioral;

