const ansiEscapes = require('ansi-escapes');
const readline = require('readline');
const SerialPort = require('serialport');

// Open Serial port
const port = new SerialPort('COM4', {
    baudRate: 115200
})
  

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

let leds = "00000001";
let counter = 0;

setInterval(function() {

    // 12-bit counter
    counter = counter + 1;
    if (counter == 0x1000)
        counter = 0;

    // Rotate LEDs
    leds = leds.substr(1, 7) + leds[0];

    // Write it
    port.write(encodeBits(counter.toString(2).padStart(12, 0) + leds));

}, 200);


