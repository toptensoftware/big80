const ansiEscapes = require('ansi-escapes');
const readline = require('readline');
const SerialPort = require('serialport');

// Open Serial port
const port = new SerialPort('COM6', {
    baudRate: 115200
})

// Clear screen and make room for status line
process.stdout.write(ansiEscapes.clearScreen);
process.stdout.write("\n\n");

// Show status message
function showStatus(msg)
{
    process.stdout.write(ansiEscapes.cursorHide);
    process.stdout.write(ansiEscapes.cursorSavePosition);
    process.stdout.write(ansiEscapes.cursorTo(0,0));
    process.stdout.write(msg);
    process.stdout.write(ansiEscapes.cursorRestorePosition);
    process.stdout.write(ansiEscapes.cursorShow);
}

// Serial port data
let bits = "";
port.on('data', function (data) {

    //console.log(data);

    // Process incoming data
    for (let i=0; i<data.length; i++)
    {
        // High-bit set = start of bit packet
        if (data[i] & 0x80)
            bits = "";

        // Combine bit packet back into a binary string
        bits = (data[i] & 0x7f).toString(2).padStart(7, '0') + bits;
    }

    // Prettify and show
    if (bits.length > 16)
        showStatus(bits.replace(/./g, x => x =='1' ? "●" : "-").substr(-16));
});
  

function encodeBits(bits)
{
    let byteCount = parseInt((bits.length + 6) / 7);
    bits = bits.padStart(byteCount * 7, '0');
    let buf = Buffer.allocUnsafe(byteCount);
    for (let i=0; i<byteCount; i++)
    {
        let subbits = bits.substr(-7 - i * 7, 7);
        buf[i] = parseInt(subbits, 2) | (i==0 ? 0x80 : 0);
    }
    return buf;
}


// Readline console
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  prompt: "> ",
});
process.stdout.write(ansiEscapes.cursorTo(0,6));
rl.prompt();
rl.on('line', (line) => {

    // Quit?
    if (line.trim() == "exit")
    {
        rl.close();
        return;
    }

    port.write(encodeBits("11110000000010000001"), function (err, written) {
        if (err)
            console.log("err", err);
        else
            console.log("ok");
    });
    
    
    // Display command result
    process.stdout.write(ansiEscapes.cursorTo(0,2));
    process.stdout.write(ansiEscapes.eraseDown);
    process.stdout.write(`Entered: '${line.trim()}'`);

    // Prompt again
    process.stdout.write(ansiEscapes.cursorTo(0,6));
    rl.prompt();
});
rl.on('close', () => {
    port.close();
    process.stdout.write("\n\n");
});

/*

## Display string format ##

[000{7..0}000] - binary 10010001
[{15..8}:x] - hex 
[{7..0}:c] - ascii - "A"
[{7..0}:l] - led eg: #--#---#
[{7..0}:m:init,idle,tx,rx] - enumerated state


## Serial Protocol ##

High bit set indicates start of packet
High bit clear indicates continuation of packet

Remaining bit = bits being transmitted

*/

