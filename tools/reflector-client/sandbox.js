let Reflector = require('./Reflector');
let ReflectorUI = require('./ReflectorUI');

// Reflector establishes a connection with the FPGA over serial port
let reflector = new Reflector({
    receiveBitCount: 16,
    sendBitCount: 20,
    portName: "COM4",
    portOptions: { 
        baudRate: 115200 
    },
    receiveAccessors: {                 // Declare bit fields from FPGA
        "i_buttons": [ 15, 12 ],
        "i_counter": [ 7, 0 ],
    },
    sendAccessors: {                    // Declare bit fields to FPGA
        "o_leds": [ 7, 0 ],
        "o_counter": [ 19, 8 ],
    }
});

// The accessors declared above are now available as properties
// For sendAccessors, changes will be automatically sent to the FPGA
// For receiveAccessors, they'll update when those signals in the FPGA change
reflector.o_leds = 0x01;

// Use a timer to change things.
let timer = setInterval(function() {

    // Counter
    reflector.o_counter++;

    // Rotate LEDs
    reflector.o_leds = ((reflector.o_leds << 1) | (reflector.o_leds >> 7)) & 0xFF;

}, 500);


// This event notifies us that either something sent or received changed
// Note the use of reflector.formatXxx() methods to get values and format for display
reflector.on('change', function() {
    let msg =  `  to FPGA: counter: ${reflector.formatHex("o_counter")} leds: ${reflector.formatLeds("o_leds")}\n`;
        msg += `from FPGA: counter: ${reflector.formatHex("i_counter")} buttons: ${reflector.formatLeds("i_buttons")}`;
    ui.showStatus(msg);
});


// This is a simple console UI that displays a status string at
// the top of the screen and provides a prompt where commands can be entered
let ui = new ReflectorUI();
ui.on('close', () => {
    clearInterval(timer);
    reflector.close();
});
ui.run();
