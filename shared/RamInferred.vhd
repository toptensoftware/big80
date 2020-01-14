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
		p_addr_width : integer;
		p_data_width : integer := 8
	);
	port
	(
		-- Port A
		i_clock : in std_logic;
		i_clken : in std_logic;
		i_addr : in std_logic_vector(p_addr_width-1 downto 0);
		i_data : in std_logic_vector(p_data_width-1 downto 0);
		o_data : out std_logic_vector(p_data_width-1 downto 0);
		i_write : in std_logic
	);
end RamInferred;
 
architecture behavior of RamInferred is 
	constant c_mem_depth : integer := 2**p_addr_width;
	type mem_type is array(0 to c_mem_depth-1) of std_logic_vector(p_data_width-1 downto 0);
	shared variable ram : mem_type;
begin

	process (i_clock)
	begin
		if rising_edge(i_clock) then
			if i_clken = '1' then

				if i_write = '1' then
					ram(to_integer(unsigned(i_addr))) := i_data;
				end if;

				o_data <= ram(to_integer(unsigned(i_addr)));

			end if;
		end if;
	end process;

end;
