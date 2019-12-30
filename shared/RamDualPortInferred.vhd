--------------------------------------------------------------------------
--
-- RamDualPortInferred
--
-- Infers a dual port RAM of specified address and data width
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity RamDualPortInferred is
	generic
	(
		p_AddrWidth : integer;
		p_DataWidth : integer := 8
	);
	port
	(
		-- Port A
		i_Clock_A : in std_logic;
		i_ClockEn_A : in std_logic;
		i_Addr_A : in std_logic_vector(p_AddrWidth-1 downto 0);
		i_Data_A : in std_logic_vector(p_DataWidth-1 downto 0);
		o_Data_A : out std_logic_vector(p_DataWidth-1 downto 0);
		i_Write_A : in std_logic;

		-- Port B
		i_Clock_B : in std_logic;
		i_ClockEn_B : in std_logic;
		i_Addr_B : in std_logic_vector(p_AddrWidth-1 downto 0);
		i_Data_B : in std_logic_vector(p_DataWidth-1 downto 0);
		o_Data_B : out std_logic_vector(p_DataWidth-1 downto 0);
		i_Write_B : in std_logic
	);
end RamDualPortInferred;
 
architecture behavior of RamDualPortInferred is 
	constant MEM_DEPTH : integer := 2**p_AddrWidth;
	type mem_type is array(0 to MEM_DEPTH-1) of std_logic_vector(p_DataWidth-1 downto 0);
	shared variable ram : mem_type;
begin

	process (i_Clock_A)
	begin
		if rising_edge(i_Clock_A) then
			if i_ClockEn_A = '1' then 

				if i_Write_A = '1' then
					ram(to_integer(unsigned(i_Addr_A))) := i_Data_A;
				end if;

				o_Data_A <= ram(to_integer(unsigned(i_Addr_A)));
			
			end if;
		end if;
	end process;

	process (i_Clock_B)
	begin
		if rising_edge(i_Clock_B) then
			if i_ClockEn_B = '1' then 

				if i_Write_B = '1' then
					ram(to_integer(unsigned(i_Addr_B))) := i_Data_B;
				end if;

				o_Data_B <= ram(to_integer(unsigned(i_Addr_B)));

			end if;
		end if;
	end process;

end;
