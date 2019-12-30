let glob = require('glob');
let fs = require('fs');

let input = process.argv.length > 2 ? process.argv[2] : "*.cas";
let output = process.argv.length > 3 ? process.argv[3] : "caspack.img";

console.log("Packing from:", input);
console.log("          to:", output);

// Buid a list of input files
let inFiles  = glob.hasMagic(input) ? glob.sync(input) : [input];

// Create the output file
let fdOut = fs.openSync(output, "w+");

let pos = 0;
for (let i=0; i<inFiles.length; i++)
{
    console.log(`Slot #${pos / 16384}: ${inFiles[i]}`);
    var fileContent = fs.readFileSync(inFiles[i]);
    fs.writeSync(fdOut, fileContent);
    pos += fileContent.length;

    // Round up to 16k boundary
    if ((pos % 16384) != 0)
    {
        var buf = Buffer.alloc(16384 - pos % 16384);
        fs.writeSync(fdOut, buf);
        pos += buf.length;
    }
}

fs.closeSync(fdOut);