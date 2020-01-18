let Reflector = require('./Reflector');
let ReflectorUI = require('./ReflectorUI');

let reflector = new Reflector({
    receiveBitCount: 16,
    sendBitCount: 20,
    portName: "COM4",
    portOptions: { 
        baudRate: 115200 
    },
    receiveAccessors: {
        "i_buttons": [ 15, 12 ],
        "i_counter": [ 7, 0 ],
    },
    sendAccessors: {
        "o_leds": [ 7, 0 ],
        "o_counter": [ 19, 8 ],
    }
});

reflector.o_leds = 0x01;

let timer = setInterval(function() {

    // Counter
    reflector.o_counter++;

    // Rotate LEDs
    reflector.o_leds = ((reflector.o_leds << 1) | (reflector.o_leds >> 7)) & 0xFF;

}, 500);

reflector.on('change', function() {
    ui.showStatus(`  to FPGA: counter: ${reflector.formatHex("o_counter")} leds: ${reflector.formatLeds("o_leds")}\nfrom FPGA: counter: ${reflector.formatHex("i_counter")} buttons: ${reflector.formatLeds("i_buttons")}`);
});

let ui = new ReflectorUI();
ui.on('close', () => {
    clearInterval(timer);
    reflector.close();
});
ui.run();
