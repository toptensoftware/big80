--------------------------------------------------------------------------
--
-- RamInferred
--
-- Infers a single port RAM of specified address and data width
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity RamInferred is
	generic
	(
		p_AddrWidth : integer;
		p_DataWidth : integer := 8
	);
	port
	(
		-- Port A
		i_Clock : in std_logic;
		i_Addr : in std_logic_vector(p_AddrWidth-1 downto 0);
		i_Data : in std_logic_vector(p_DataWidth-1 downto 0);
		o_Data : out std_logic_vector(p_DataWidth-1 downto 0);
		i_Write : in std_logic
	);
end RamInferred;
 
architecture behavior of RamInferred is 
	constant MEM_DEPTH : integer := 2**p_AddrWidth;
	type mem_type is array(0 to MEM_DEPTH-1) of std_logic_vector(p_DataWidth-1 downto 0);
	shared variable ram : mem_type;
begin

	process (i_Clock)
	begin
		if rising_edge(i_Clock) then

			if i_Write = '1' then
				ram(to_integer(unsigned(i_Addr))) := i_Data;
			end if;

			o_Data <= ram(to_integer(unsigned(i_Addr)));

		end if;
	end process;

end;
