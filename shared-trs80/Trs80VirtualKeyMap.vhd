--------------------------------------------------------------------------
--
-- Trs80VirtualKeyMap
--
-- Maps PC keyboard scancodes into Trs80 virtual key codes.
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.Trs80VirtualKeyCodes.ALL;

entity Trs80VirtualKeyMap is
port
(
	-- Input
    i_key_scancode : in std_logic_vector(6 downto 0);  -- Input scan code
    i_key_extended : in std_logic;                  -- 0 for normal key, 1 for extended key
	
	-- Output
	o_virtual_key : out integer range 0 to vk_none
);
end Trs80VirtualKeyMap;
 
architecture behavior of Trs80VirtualKeyMap is 
begin
	process(i_key_scancode, i_key_extended)
	begin
		
		case (i_key_extended & i_key_scancode) is
		
			when x"1c" => o_virtual_key <= vk_A;
			when x"32" => o_virtual_key <= vk_B;
			when x"21" => o_virtual_key <= vk_C;
			when x"23" => o_virtual_key <= vk_D;
			when x"24" => o_virtual_key <= vk_E;
			when x"2b" => o_virtual_key <= vk_F;
			when x"34" => o_virtual_key <= vk_G;
			when x"33" => o_virtual_key <= vk_H;
			when x"43" => o_virtual_key <= vk_I;
			when x"3b" => o_virtual_key <= vk_J;
			when x"42" => o_virtual_key <= vk_K;
			when x"4b" => o_virtual_key <= vk_L;
			when x"3a" => o_virtual_key <= vk_M;
			when x"31" => o_virtual_key <= vk_N;
			when x"44" => o_virtual_key <= vk_O;
			when x"4d" => o_virtual_key <= vk_P;
			when x"15" => o_virtual_key <= vk_Q;
			when x"2d" => o_virtual_key <= vk_R;
			when x"1b" => o_virtual_key <= vk_S;
			when x"2c" => o_virtual_key <= vk_T;
			when x"3c" => o_virtual_key <= vk_U;
			when x"2a" => o_virtual_key <= vk_V;
			when x"1d" => o_virtual_key <= vk_W;
			when x"22" => o_virtual_key <= vk_X;
			when x"35" => o_virtual_key <= vk_Y;
			when x"1a" => o_virtual_key <= vk_Z;
			when x"5d" => o_virtual_key <= vk_backslash;
			when x"45" => o_virtual_key <= vk_0;
			when x"16" => o_virtual_key <= vk_1;
			when x"1e" => o_virtual_key <= vk_2;
			when x"26" => o_virtual_key <= vk_3;
			when x"25" => o_virtual_key <= vk_4;
			when x"2e" => o_virtual_key <= vk_5;
			when x"36" => o_virtual_key <= vk_6;
			when x"3d" => o_virtual_key <= vk_7;
			when x"3e" => o_virtual_key <= vk_8;
			when x"46" => o_virtual_key <= vk_9;
			when x"41" => o_virtual_key <= vk_comma_lt;		-- ,
			when x"49" => o_virtual_key <= vk_period_gt;		-- .
			when x"4A" => o_virtual_key <= vk_slash_question;
			when x"52" => o_virtual_key <= vk_quote;
			when x"76" => o_virtual_key <= vk_escape;		
			when x"66" => o_virtual_key <= vk_backspace;		
			when x"5a" => o_virtual_key <= vk_cr;		
			when x"29" => o_virtual_key <= vk_space;		
			when x"12" => o_virtual_key <= vk_shift_l;		
			when x"59" => o_virtual_key <= vk_shift_r;		
			when x"14" => o_virtual_key <= vk_ctrl_r;
			when x"4e" => o_virtual_key <= vk_minus;
			when x"55" => o_virtual_key <= vk_equals;
			when x"4c" => o_virtual_key <= vk_semicolon;
			when x"F1" => o_virtual_key <= vk_delete;
			when x"F5" => o_virtual_key <= vk_up;
			when x"F2" => o_virtual_key <= vk_down;
			when x"Eb" => o_virtual_key <= vk_left;
			when x"F4" => o_virtual_key <= vk_right;
			when x"94" => o_virtual_key <= vk_ctrl_l;
			when others => o_virtual_key <= vk_none;

		end case;
			
	end process;


end;
