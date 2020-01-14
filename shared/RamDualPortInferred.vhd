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
		p_addr_width : integer;
		p_data_width : integer := 8
	);
	port
	(
		-- Port A
		i_clock_a : in std_logic;
		i_clken_a : in std_logic;
		i_addr_a : in std_logic_vector(p_addr_width-1 downto 0);
		i_data_a : in std_logic_vector(p_data_width-1 downto 0);
		o_data_a : out std_logic_vector(p_data_width-1 downto 0);
		i_write_a : in std_logic;

		-- Port B
		i_clock_b : in std_logic;
		i_clken_b : in std_logic;
		i_addr_b : in std_logic_vector(p_addr_width-1 downto 0);
		i_data_b : in std_logic_vector(p_data_width-1 downto 0);
		o_data_b : out std_logic_vector(p_data_width-1 downto 0);
		i_write_b : in std_logic
	);
end RamDualPortInferred;
 
architecture behavior of RamDualPortInferred is 
	constant c_mem_depth : integer := 2**p_addr_width;
	type mem_type is array(0 to c_mem_depth-1) of std_logic_vector(p_data_width-1 downto 0);
	shared variable ram : mem_type;
begin

	process (i_clock_a)
	begin
		if rising_edge(i_clock_a) then
			if i_clken_a = '1' then 

				if i_write_a = '1' then
					ram(to_integer(unsigned(i_addr_a))) := i_data_a;
				end if;

				o_data_a <= ram(to_integer(unsigned(i_addr_a)));
			
			end if;
		end if;
	end process;

	process (i_clock_b)
	begin
		if rising_edge(i_clock_b) then
			if i_clken_b = '1' then 

				if i_write_b = '1' then
					ram(to_integer(unsigned(i_addr_b))) := i_data_b;
				end if;

				o_data_b <= ram(to_integer(unsigned(i_addr_b)));

			end if;
		end if;
	end process;

end;
