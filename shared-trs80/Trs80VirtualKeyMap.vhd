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
    i_ScanCode : in std_logic_vector(6 downto 0);  -- Input scan code
    i_ExtendedKey : in std_logic;                  -- 0 for normal key, 1 for extended key
	
	-- Output
	o_VirtualKey : out integer range 0 to vk_none
);
end Trs80VirtualKeyMap;
 
architecture behavior of Trs80VirtualKeyMap is 
begin
	process(i_ScanCode, i_ExtendedKey)
	begin
		
		case (i_ExtendedKey & i_ScanCode) is
		
			when x"1c" => o_VirtualKey <= vk_A;
			when x"32" => o_VirtualKey <= vk_B;
			when x"21" => o_VirtualKey <= vk_C;
			when x"23" => o_VirtualKey <= vk_D;
			when x"24" => o_VirtualKey <= vk_E;
			when x"2b" => o_VirtualKey <= vk_F;
			when x"34" => o_VirtualKey <= vk_G;
			when x"33" => o_VirtualKey <= vk_H;
			when x"43" => o_VirtualKey <= vk_I;
			when x"3b" => o_VirtualKey <= vk_J;
			when x"42" => o_VirtualKey <= vk_K;
			when x"4b" => o_VirtualKey <= vk_L;
			when x"3a" => o_VirtualKey <= vk_M;
			when x"31" => o_VirtualKey <= vk_N;
			when x"44" => o_VirtualKey <= vk_O;
			when x"4d" => o_VirtualKey <= vk_P;
			when x"15" => o_VirtualKey <= vk_Q;
			when x"2d" => o_VirtualKey <= vk_R;
			when x"1b" => o_VirtualKey <= vk_S;
			when x"2c" => o_VirtualKey <= vk_T;
			when x"3c" => o_VirtualKey <= vk_U;
			when x"2a" => o_VirtualKey <= vk_V;
			when x"1d" => o_VirtualKey <= vk_W;
			when x"22" => o_VirtualKey <= vk_X;
			when x"35" => o_VirtualKey <= vk_Y;
			when x"1a" => o_VirtualKey <= vk_Z;
			when x"5d" => o_VirtualKey <= vk_backslash;
			when x"45" => o_VirtualKey <= vk_0;
			when x"16" => o_VirtualKey <= vk_1;
			when x"1e" => o_VirtualKey <= vk_2;
			when x"26" => o_VirtualKey <= vk_3;
			when x"25" => o_VirtualKey <= vk_4;
			when x"2e" => o_VirtualKey <= vk_5;
			when x"36" => o_VirtualKey <= vk_6;
			when x"3d" => o_VirtualKey <= vk_7;
			when x"3e" => o_VirtualKey <= vk_8;
			when x"46" => o_VirtualKey <= vk_9;
			when x"41" => o_VirtualKey <= vk_comma_lt;		-- ,
			when x"49" => o_VirtualKey <= vk_period_gt;		-- .
			when x"4A" => o_VirtualKey <= vk_slash_question;
			when x"52" => o_VirtualKey <= vk_quote;
			when x"76" => o_VirtualKey <= vk_escape;		
			when x"66" => o_VirtualKey <= vk_backspace;		
			when x"5a" => o_VirtualKey <= vk_cr;		
			when x"29" => o_VirtualKey <= vk_space;		
			when x"12" => o_VirtualKey <= vk_shift_l;		
			when x"59" => o_VirtualKey <= vk_shift_r;		
			when x"14" => o_VirtualKey <= vk_ctrl_r;
			when x"4e" => o_VirtualKey <= vk_minus;
			when x"55" => o_VirtualKey <= vk_equals;
			when x"4c" => o_VirtualKey <= vk_semicolon;
			when x"F1" => o_VirtualKey <= vk_delete;
			when x"F5" => o_VirtualKey <= vk_up;
			when x"F2" => o_VirtualKey <= vk_down;
			when x"Eb" => o_VirtualKey <= vk_left;
			when x"F4" => o_VirtualKey <= vk_right;
			when x"94" => o_VirtualKey <= vk_ctrl_l;
			when others => o_VirtualKey <= vk_none;

		end case;
			
	end process;


end;
