--------------------------------------------------------------------------
--
-- Trs80KeyMemoryMap
--
-- Accepts keystrokes from a PC keyboard, tracks key states and implements
-- the TRS-80 Keyboard Memory Map
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.Trs80VirtualKeyCodes.ALL;

entity Trs80KeyMemoryMap is
port
(
    -- Control
    i_Clock : in std_logic;                         -- Clock
    i_Reset : in std_logic;                         -- Reset (synchronous, active high)
        
    -- Generated keyboard event
    i_ScanCode : in std_logic_vector(6 downto 0);  -- Input scan code
    i_ExtendedKey : in std_logic;                  -- 0 for normal key, 1 for extended key
    i_KeyRelease : in std_logic;                   -- 0 if press, 1 if release
	i_DataAvailable : in std_logic;                -- Assert for one clock cycle on event
	
	-- CPU interface
	i_Addr : in std_logic_vector(7 downto 0);		-- Lowest 8 bits of memory address being read
	o_Data : out std_logic_vector(7 downto 0)	    -- Output byte
);
end Trs80KeyMemoryMap;
 
architecture behavior of Trs80KeyMemoryMap is 
	signal s_key_switches : std_logic_vector(63 downto 0);
	signal s_bank_0 : std_logic_vector(7 downto 0);
	signal s_bank_1 : std_logic_vector(7 downto 0);
	signal s_bank_2 : std_logic_vector(7 downto 0);
	signal s_bank_3 : std_logic_vector(7 downto 0);
	signal s_bank_4 : std_logic_vector(7 downto 0);
	signal s_bank_5 : std_logic_vector(7 downto 0);
	signal s_bank_6 : std_logic_vector(7 downto 0);
	signal s_bank_7 : std_logic_vector(7 downto 0);
begin

	-- TRS80 Keyboard Switches
	keyboardSwitches : entity work.Trs80KeySwitches
	PORT MAP
	(
		i_Clock => i_Clock,
		i_Reset => i_Reset,
		i_ScanCode => i_ScanCode,
		i_ExtendedKey => i_ExtendedKey,
		i_KeyRelease => i_KeyRelease,
		i_DataAvailable => i_DataAvailable,
		o_KeySwitches => s_key_switches
	);

	-- Select either zeros or key state from key switches depending on 
    -- which address bits are selected
	s_bank_0 <= s_key_switches(7 downto 0) when i_Addr(0)='1' else x"00";
	s_bank_1 <= s_key_switches(15 downto 8) when i_Addr(1)='1' else x"00";
	s_bank_2 <= s_key_switches(23 downto 16) when i_Addr(2)='1' else x"00";
	s_bank_3 <= s_key_switches(31 downto 24) when i_Addr(3)='1' else x"00";
	s_bank_4 <= s_key_switches(39 downto 32) when i_Addr(4)='1' else x"00";
	s_bank_5 <= s_key_switches(47 downto 40) when i_Addr(5)='1' else x"00";
	s_bank_6 <= s_key_switches(55 downto 48) when i_Addr(6)='1' else x"00";
	s_bank_7 <= s_key_switches(63 downto 56) when i_Addr(7)='1' else x"00";

	-- Combine them all together
	o_Data <= s_bank_0 or s_bank_1 or s_bank_2 or s_bank_3 or
			  s_bank_4 or s_bank_5 or s_bank_6 or s_bank_7;

end;
