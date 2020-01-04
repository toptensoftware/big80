--------------------------------------------------------------------------
--
-- Trs80VirtualKeyCodes
--
-- Virtual key codes for every PC key used by the TRS-80 keymap.
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;

package Trs80VirtualKeyCodes is

	constant vk_backslash : integer := 0;
	constant vk_A : integer := 1;
	constant vk_B : integer := 2;
	constant vk_C : integer := 3;
	constant vk_D : integer := 4;
	constant vk_E : integer := 5;
	constant vk_F : integer := 6;
	constant vk_G : integer := 7;

	constant vk_H : integer := 8;
	constant vk_I : integer := 9;
	constant vk_J : integer := 10;
	constant vk_K : integer := 11;
	constant vk_L : integer := 12;
	constant vk_M : integer := 13;
	constant vk_N : integer := 14;
	constant vk_O : integer := 15;

	constant vk_P : integer := 16;
	constant vk_Q : integer := 17;
	constant vk_R : integer := 18;
	constant vk_S : integer := 19;
	constant vk_T : integer := 20;
	constant vk_U : integer := 21;
	constant vk_V : integer := 22;
	constant vk_W : integer := 23;

	constant vk_X : integer := 24;
	constant vk_Y : integer := 25;
	constant vk_Z : integer := 26;
	constant vk_caret_tilda : integer := 27;
	constant vk_shift_l : integer := 28;
	constant vk_shift_r : integer := 29; 
	constant vk_ctrl_l : integer := 30;
	constant vk_ctrl_r : integer := 31;
	

	constant vk_0 : integer := 32;
	constant vk_1 : integer := 33;
	constant vk_2 : integer := 34;
	constant vk_3 : integer := 35;
	constant vk_4 : integer := 36;
	constant vk_5 : integer := 37;
	constant vk_6 : integer := 38;
	constant vk_7 : integer := 39;
	
	constant vk_8 : integer := 40;
	constant vk_9 : integer := 41;
	constant vk_minus : integer := 42;
	constant vk_semicolon : integer := 43;
	constant vk_comma_lt : integer := 44;
	constant vk_equals : integer := 45;
	constant vk_period_gt : integer := 46;
	constant vk_slash_question : integer := 47;

	constant vk_cr : integer := 48;
	constant vk_delete : integer := 49;
	constant vk_escape : integer := 50;
	constant vk_up : integer := 51;
	constant vk_down : integer := 52;
	constant vk_left : integer := 53;
	constant vk_right : integer := 54;
	constant vk_space : integer := 55;

	constant vk_backspace : integer := 56;
	constant vk_quote : integer := 57;
	constant vk_none : integer := 58; 

	end Trs80VirtualKeyCodes;

package body Trs80VirtualKeyCodes is

 
end Trs80VirtualKeyCodes;
