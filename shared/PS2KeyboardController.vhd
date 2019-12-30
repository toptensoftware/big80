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
    p_ClockFrequency : integer                  	-- In Hz, Used to calculate timings
);
port 
( 
    -- Control
    i_Clock : in std_logic;                         -- Clock
    i_Reset : in std_logic;                         -- Reset (synchronous, active high)
        
    -- PS2 Signals
    io_PS2Clock : inout std_logic;              	-- PS2 Clock
    io_PS2Data : inout std_logic;               	-- PS2 Data

    -- Generated keyboard event
    o_ScanCode : out std_logic_vector(6 downto 0);  -- Output scan code
    o_ExtendedKey : out std_logic;                  -- 0 for normal key, 1 for extended key
    o_KeyRelease : out std_logic;                   -- 0 if press, 1 if release
    o_DataAvailable : out std_logic                 -- Asserted for one clock cycle on event
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
		p_ClockFrequency => p_ClockFrequency 
	)
	PORT MAP
	(
		i_Clock => i_Clock,
		i_Reset => i_Reset,
		io_PS2Clock => io_PS2Clock,
		io_PS2Data => io_PS2Data,
		o_Data => s_ps2_data,
		o_DataAvailable => s_ps2_data_available,
		o_Error => s_ps2_data_error
	);

	keyboardDecoder : entity work.PCKeyboardDecoder
	PORT MAP
	(
		i_Clock => i_Clock,
		i_Reset => i_Reset,
		i_Data => s_ps2_data,
		i_DataAvailable => s_ps2_data_available,
		i_Error => s_ps2_data_error,
		o_ScanCode => o_ScanCode,
		o_ExtendedKey => o_ExtendedKey,
		o_KeyRelease => o_KeyRelease,
		o_DataAvailable => o_DataAvailable
	);


end Behavioral;

