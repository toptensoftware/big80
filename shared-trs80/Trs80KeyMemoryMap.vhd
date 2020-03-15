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
    i_clock : in std_logic;                         -- Clock
    i_reset : in std_logic;                         -- Reset (synchronous, active high)
        
    -- Generated keyboard event
    i_key_scancode : in std_logic_vector(7 downto 0);  -- Input scan code
    i_key_released : in std_logic;                   -- 0 if press, 1 if release
	i_key_available : in std_logic;                -- Assert for one clock cycle on event
	
	-- Options
	i_typing_mode : in std_logic;

	-- CPU interface
	i_addr : in std_logic_vector(7 downto 0);		-- Lowest 8 bits of memory address being read
	o_data : out std_logic_vector(7 downto 0);	    -- Output byte

	-- Is the current key a trs80 key
	o_is_other_key : out std_logic;
	o_modifiers : out std_logic_vector(1 downto 0);

	-- Suppress all keys because syscon has keyboard captured
	i_suppress_all_keys : in std_logic
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

	-- TRS80 Keyboard i_switches
	keyboardSwitches : entity work.Trs80KeySwitches
	PORT MAP
	(
		i_clock => i_clock,
		i_reset => i_reset,
		i_key_scancode => i_key_scancode,
		i_key_released => i_key_released,
		i_key_available => i_key_available,
		i_typing_mode => i_typing_mode,
		o_key_switches => s_key_switches,
		o_is_other_key => o_is_other_key,
		o_modifiers => o_modifiers,
		i_suppress_all_keys => i_suppress_all_keys
	);

	-- Select either zeros or key state from key switches depending on 
    -- which address bits are selected
	s_bank_0 <= s_key_switches(7 downto 0) when i_addr(0)='1' else x"00";
	s_bank_1 <= s_key_switches(15 downto 8) when i_addr(1)='1' else x"00";
	s_bank_2 <= s_key_switches(23 downto 16) when i_addr(2)='1' else x"00";
	s_bank_3 <= s_key_switches(31 downto 24) when i_addr(3)='1' else x"00";
	s_bank_4 <= s_key_switches(39 downto 32) when i_addr(4)='1' else x"00";
	s_bank_5 <= s_key_switches(47 downto 40) when i_addr(5)='1' else x"00";
	s_bank_6 <= s_key_switches(55 downto 48) when i_addr(6)='1' else x"00";
	s_bank_7 <= s_key_switches(63 downto 56) when i_addr(7)='1' else x"00";

	-- Combine them all together
	o_data <= s_bank_0 or s_bank_1 or s_bank_2 or s_bank_3 or
			  s_bank_4 or s_bank_5 or s_bank_6 or s_bank_7;

end;
