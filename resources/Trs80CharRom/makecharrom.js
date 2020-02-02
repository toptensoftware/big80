var fs = require('fs');
var data = fs.readFileSync('charrom.bin');

let out="";

out += "--\n";
out += "--\n";
out += "-- THIS FILE WAS AUTOMATICALLY GENERATED - DO NOT EDIT\n";
out += "--\n";
out += "--\n";
out += "";
out += "library ieee;\n";
out += "use ieee.std_logic_1164.ALL;\n";
out += "use ieee.numeric_std.ALL;\n";
out += "\n";
out += "entity Trs80CharRom is\n";
out += "	port\n";
out += "	(\n";
out += "		i_clock : in std_logic;\n";
out += "		i_addr : in std_logic_vector(10 downto 0);\n";
out += "		o_dout : out std_logic_vector(5 downto 0)\n";
out += "	);\n";
out += "end Trs80CharRom;\n";
out += " \n";
out += "--xilt:nowarn:Signal 'ram', unconnected in block 'Trs80CharRom', is tied to its initial value.\n";
out += " \n";
out += "architecture behavior of Trs80CharRom is \n";
out += "	type mem_type is array(0 to 2047) of std_logic_vector(5 downto 0);\n";
out += "	signal ram : mem_type := (\n";

let comma = ",";
for (let i=0; i<2048; i++)
{
    if (i == 2048 -1)
        comma ="";
    if (i % 16 == 0)
        out += "\n\t\t-- char " + (i/16).toString(16).padStart(2, "0") + "\n";
    out += "\t\t\"" + data[i].toString(2).padStart(8, "0").substring(0, 6) + "\"" + comma + "\n";
}

out += ");\n\n";
out += "begin\n";
out += "	process (i_clock)\n";
out += "	begin\n";
out += "		if rising_edge(i_clock) then\n";
out += "			o_dout <= ram(to_integer(unsigned(i_addr)));\n";
out += "		end if;\n";
out += "	end process;\n";
out += "end;\n";

fs.writeFileSync(process.argv[2], out);