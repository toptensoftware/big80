let fs = require('fs');
var path = require('path');

try
{
let inFile;
let outFile;
let entityName;

for (let i=2; i<process.argv.length; i++)
{
    let a = process.argv[i];

    let isSwitch = false;
    if (a.startsWith("--"))
    {
        isSwitch = true;
        a = a.substring(2);
    }
    else if (a.startsWith("/"))
    {
        isSwitch = true;
        a = a.substring(1);
    }

    if (isSwitch)
    {
        let parts = a.split(':');
        if (parts.length > 2)
        {
            parts = [parts[0], parts.slice(1).join(":")]
        }
        if (parts.length == 2)
        {
            if (parts[1]=='false' || parts[1]=='no')
                parts[1] = false;
            if (parts[1]=='true' || parts[1]=='yes')
                parts[1] = true;
        }
        parts[0] = parts[0].toLowerCase();

        switch (parts[0])
        {
            case "help":
                showHelp();
                process.exit(0);
                break;

            case "entity":
                entityName = parts[1];
                break;

            default:
                throw new Error(`Unrecognized switch: --${parts[0]}`)
        }
    }
    else
    {
        if (!inFile)
            inFile = a;
        else if (!outFile)
            outFile = a;
        else
            throw new Error(`Too many args: ${a}`);
    }

}

if (!inFile)
{
    showHelp();
    throw new Error("Input file not specified");
    process.exit(7);
}

if (!outFile)
{
    outFile = inFile;
    var lastDot = outFile.lastIndexOf('.');
    if (lastDot >= 0)
        outFile = outFile.substring(0, lastDot);
    outFile += ".vhd";
}

if (!entityName)
{
    entityName = path.parse(outFile).name;
}


// Load data
var data = fs.readFileSync(inFile);

// Work out address width
var addrWidth = parseInt(Math.log2(data.length));
if (Math.pow(2, addrWidth) < data.length)
    addrWidth++;
var dataLength = Math.pow(2, addrWidth);

var out = "";

out += "--\n";
out += "--\n";
out += "-- THIS FILE WAS AUTOMATICALLY GENERATED - DO NOT EDIT\n";
out += "--\n";
out += "--\n";
out += "";
out += "library ieee;\n";
out += "use ieee.std_logic_1164.ALL;\n";
out += "use ieee.numeric_std.ALL;\n";
out += "use std.textio.all;\n";
out += "use ieee.std_logic_textio.all;\n";
out += "\n";
out += `entity ${entityName} is\n`;
out += "port\n";
out += "(\n";
out += "	clock : in std_logic;\n";
out += `	addr : in std_logic_vector(${addrWidth-1} downto 0);\n`;
out += "	dout : out std_logic_vector(7 downto 0)\n";
out += ");\n";
out += `end ${entityName};\n`;
out += "\n";
out += `--xilt:nowarn:Signal 'ram', unconnected in block '${entityName}', is tied to its initial value.\n`;
out += "\n";
out += `architecture behavior of ${entityName} is\n`;
out += `	type mem_type is array(0 to ${dataLength-1}) of std_logic_vector(7 downto 0);\n`;
out += "	signal ram : mem_type := (\n";

let comma = ",";
for (let i=0; i<dataLength; i++)
{
    if (i == dataLength -1)
        comma ="";
    if ((i % 16) ==0)
        out += "\n\t";
    else
        out += " ";

    var byte = i<data.length ? data[i] : 0;
    out += "x\"" + byte.toString(16).padStart(2, "0") + "\"" + comma;
}

out += ");\n";
out += "begin\n";
out += "	process (clock)\n";
out += "	begin\n";
out += "		if rising_edge(clock) then\n";
out += "			dout <= ram(to_integer(unsigned(addr)));\n";
out += "		end if;\n";
out += "	end process;\n";
out += "end;\n";

fs.writeFileSync(outFile, out, "utf8");
}
catch (err)
{
    console.error(err.message);
}


function showHelp()
{
    console.log("bin2vhdlrom inputBinaryFile [vhdlFileToWrite] [options]");
    console.log();
    console.log("Options:");
    console.log(" --entityName:<name>  name of the VHDL entity to generate");
    console.log("                         (defaults to outfile name)");
    console.log(" --help               show this help");
}