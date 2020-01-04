--------------------------------------------------------------------------
--
-- Trs80KeySwitches
--
-- Accepts keystrokes from a PC keyboard, maintains the state of all 
-- relevant keys and produces a map of 64 key switch values reflecting
-- which TRS-80 keys are currently pressed.
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.Trs80VirtualKeyCodes.ALL;

entity Trs80KeySwitches is
port
(
    -- Control
    i_Clock : in std_logic;                         -- Clock
    i_Reset : in std_logic;                         -- Reset (synchronous, active high)
        
    -- Generated keyboard event
    i_ScanCode : in std_logic_vector(6 downto 0);  -- Input scan code
    i_ExtendedKey : in std_logic;                  -- 0 for normal key, 1 for extended key
    i_KeyRelease : in std_logic;                   -- 0 if press, 1 if release
	i_DataAvailable : in std_logic;                 -- Assert for one clock cycle on event
	
	i_TypingMode : in std_logic;					-- typing mode?
	o_KeySwitches : out std_logic_vector(63 downto 0)		-- '1' for each key currently pressed
);
end Trs80KeySwitches;
 
architecture behavior of Trs80KeySwitches is 
	signal s_VKSwitches : std_logic_Vector(vk_none downto 0);
	signal s_VirtualKey : integer range 0 to vk_none;

	signal s_shift : std_logic;
	signal s_tm_at : std_logic;
	signal s_tm_double_quote : std_logic;
	signal s_tm_quote : std_logic;
	signal s_tm_amper : std_logic;
	signal s_tm_asterisk : std_logic;
	signal s_tm_open_round : std_logic;
	signal s_tm_close_round : std_logic;
	signal s_tm_equals : std_logic;
	signal s_tm_minus : std_logic;
	signal s_tm_plus : std_logic;
	signal s_tm_semicolon : std_logic;
	signal s_tm_colon : std_logic;
	signal s_tm_shift : std_logic;
begin

	-- Map scan codes to virtual key codes
	keymap : entity work.Trs80VirtualKeyMap
	port map
	(
		i_ScanCode => i_ScanCode,
		i_ExtendedKey => i_ExtendedKey,
		o_VirtualKey => s_VirtualKey
	);

	-- On data available, store the key state of keys we care about
	-- uninterested keys will be mapped to virtual key code 127 which
	-- we never map to microbee.
	process (i_Clock)
	begin
		if rising_edge(i_Clock) then
			if i_Reset = '1' then
				s_VKSwitches <= (others => '0');
			elsif i_DataAvailable = '1' then 
				s_VKSwitches(s_VirtualKey) <= not i_KeyRelease;
			end if;
		end if;
	end process;

	-- Map all keys!

	-- Map typing mode keys
	s_shift <= s_VKSwitches(vk_shift_l) or s_VKSwitches(vk_shift_r);
	s_tm_at <= s_VKSwitches(vk_2) and s_shift;
	s_tm_double_quote <= s_VKSwitches(vk_quote) and s_shift;
	s_tm_quote <= s_VKSwitches(vk_quote) and not s_shift;
	s_tm_amper <= s_VKSwitches(vk_7) and s_shift;
	s_tm_asterisk <= s_VKSwitches(vk_8) and s_shift;
	s_tm_open_round <= s_VKSwitches(vk_9) and s_shift;
	s_tm_close_round <= s_VKSwitches(vk_0) and s_shift;
	s_tm_equals <= s_VKSwitches(vk_equals) and not s_shift;
	s_tm_minus <=  s_VKSwitches(vk_minus) and not s_shift;
	s_tm_plus <= s_VKSwitches(vk_equals) and s_shift;
	s_tm_semicolon <= s_VKSwitches(vk_semicolon) and not s_shift;
	s_tm_colon <= s_VKSwitches(vk_semicolon) and s_shift;

	s_tm_shift <=
		'0' when s_tm_at = '1' else
		'1' when s_tm_quote = '1' else
		'0' when s_tm_colon = '1' else
		'1' when s_tm_equals = '1' else
		s_shift;

	-- 0x3801
	o_KeySwitches(0) <= 								-- @
		(s_VKSwitches(vk_backslash) or s_VKSwitches(vk_caret_tilda))
		when i_TypingMode = '0' else
		s_tm_at;
			
	o_KeySwitches(1) <= s_VKSwitches(vk_A);			
	o_KeySwitches(2) <= s_VKSwitches(vk_B);			
	o_KeySwitches(3) <= s_VKSwitches(vk_C);			
	o_KeySwitches(4) <= s_VKSwitches(vk_D);			
	o_KeySwitches(5) <= s_VKSwitches(vk_E);			
	o_KeySwitches(6) <= s_VKSwitches(vk_F);			
	o_KeySwitches(7) <= s_VKSwitches(vk_G);			

	-- 0x3802
	o_KeySwitches(8) <= s_VKSwitches(vk_H);
	o_KeySwitches(9) <= s_VKSwitches(vk_I);			
	o_KeySwitches(10) <= s_VKSwitches(vk_J);			
	o_KeySwitches(11) <= s_VKSwitches(vk_K);			
	o_KeySwitches(12) <= s_VKSwitches(vk_L);			
	o_KeySwitches(13) <= s_VKSwitches(vk_M);			
	o_KeySwitches(14) <= s_VKSwitches(vk_N);			
	o_KeySwitches(15) <= s_VKSwitches(vk_O);			

	-- 0x3804
	o_KeySwitches(16) <= s_VKSwitches(vk_P);
	o_KeySwitches(17) <= s_VKSwitches(vk_Q);			
	o_KeySwitches(18) <= s_VKSwitches(vk_R);			
	o_KeySwitches(19) <= s_VKSwitches(vk_S);			
	o_KeySwitches(20) <= s_VKSwitches(vk_T);			
	o_KeySwitches(21) <= s_VKSwitches(vk_U);			
	o_KeySwitches(22) <= s_VKSwitches(vk_V);			
	o_KeySwitches(23) <= s_VKSwitches(vk_W);			

	-- 0x3808
	o_KeySwitches(24) <= s_VKSwitches(vk_X);
	o_KeySwitches(25) <= s_VKSwitches(vk_Y);			
	o_KeySwitches(26) <= s_VKSwitches(vk_Z);			
	o_KeySwitches(27) <= '0';			
	o_KeySwitches(28) <= '0';
	o_KeySwitches(29) <= '0';
	o_KeySwitches(30) <= '0';
	o_KeySwitches(31) <= '0';

	-- 0x3810
	o_KeySwitches(32) <= 
		s_VKSwitches(vk_0)
		when i_TypingMode = '0' else
		s_VKSwitches(vk_0) and not s_shift;

	o_KeySwitches(33) <= s_VKSwitches(vk_1);			

	o_KeySwitches(34) <= 
		s_VKSwitches(vk_2)
		when i_TypingMode = '0' else
		((s_VKSwitches(vk_2) and not s_shift) or s_tm_double_quote);

	o_KeySwitches(35) <= s_VKSwitches(vk_3);			
	o_KeySwitches(36) <= s_VKSwitches(vk_4);			
	o_KeySwitches(37) <= s_VKSwitches(vk_5);			
	o_KeySwitches(38) <= 
		s_VKSwitches(vk_6)
		when i_TypingMode = '0' else
		((s_VKSwitches(vk_6) and not s_shift) or s_tm_amper);

	o_KeySwitches(39) <= 
		s_VKSwitches(vk_7)
		when i_TypingMode = '0' else
		((s_VKSwitches(vk_7) and not s_shift) or s_tm_quote);

	-- 0x3820
	o_KeySwitches(40) <= 
		s_VKSwitches(vk_8)
		when i_TypingMode = '0' else 
		((s_VKSwitches(vk_8) and not s_shift) or s_tm_open_round);

	o_KeySwitches(41) <= 
		s_VKSwitches(vk_9)
		when i_TypingMode = '0' else
		((s_VKSwitches(vk_9) and not s_shift) or s_tm_close_round);
		
	o_KeySwitches(42) <=  		-- : *
		s_VKSwitches(vk_minus)
		when i_TypingMode = '0' else
		s_tm_colon or s_tm_asterisk;

	 o_KeySwitches(43) <= 	-- ; +	
		s_VKSwitches(vk_semicolon)
		when i_TypingMode = '0' else
		s_tm_semicolon or s_tm_plus;

	o_KeySwitches(44) <= s_VKSwitches(vk_comma_lt);		-- , <
	o_KeySwitches(45) <= 		-- _ =	
		s_VKSwitches(vk_equals)
		when i_TypingMode = '0' else
		s_tm_equals or s_tm_minus;

	o_KeySwitches(46) <= s_VKSwitches(vk_period_gt);	-- . >
	o_KeySwitches(47) <= s_VKSwitches(vk_slash_question);-- / ?			

	-- 0x3840
	o_KeySwitches(48) <= s_VKSwitches(vk_cr);			-- enter
	o_KeySwitches(49) <= s_VKSwitches(vk_delete);		-- clear			
	o_KeySwitches(50) <= -- break
		(s_VKSwitches(vk_backspace) or s_VKSwitches(vk_escape))
		when i_TypingMode = '0' else
		s_VKSwitches(vk_escape);
	o_KeySwitches(51) <= s_VKSwitches(vk_up);			
	o_KeySwitches(52) <= s_VKSwitches(vk_down);			
	o_KeySwitches(53) <= 
		s_VKSwitches(vk_left)
		when i_TypingMode = '0' else
		s_VKSwitches(vk_left) or s_VKSwitches(vk_backspace);
	o_KeySwitches(54) <= s_VKSwitches(vk_right);			
	o_KeySwitches(55) <= s_VKSwitches(vk_space);			

	-- 0x3880
	o_KeySwitches(56) <= 
		s_shift
		when i_TypingMode = '0' else
		s_tm_shift;
	o_KeySwitches(57) <= '0'; -- rshift on model III
	o_KeySwitches(58) <= '0'; 
	o_KeySwitches(59) <= '0';
	o_KeySwitches(60) <= s_VKSwitches(vk_ctrl_l) or s_VKSwitches(vk_ctrl_r);
	o_KeySwitches(61) <= '0';
	o_KeySwitches(62) <= '0';
	o_KeySwitches(63) <= '0';

end;
