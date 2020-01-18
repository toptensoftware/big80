let events = require('events');
let SerialPort = require('serialport');

let BitPacket = require('./BitPacket');

/* TODO

- receive packets fire change events
- only send packet if really changed 
- only send packet if last packet finished
- fire event if send packet changed
- format display string eg: ${i_counter:hex}
- running console log output
- interactive UI (including ability to set values)
- save vcd file

*/

class Reflector extends events.EventEmitter
{
    constructor(options)
    {
        super();

        // Create default port options
        if (!options.portOptions)
            options.portOptions = {};
        if (!options.portOptions.baudRate)
            options.portOptions.baudRate = 115200;

        // Store options
        this.options = options;

        // Create accessors
        this.accessors = {};
        let sWidth = this.defineAccessors(this.options.sendAccessors, false);
        let rWidth = this.defineAccessors(this.options.receiveAccessors, true);

        // Auto bit widths?
        if (this.options.receiveBitCount === undefined)
            this.options.receiveBitCount = rWidth;
        if (this.options.sendBitCount === undefined)
            this.options.sendBitCount = sWidth;
        
        // Sanity checks
        if (sWidth > this.sendBitCount)
            throw new Error(`One of more send accessors references out of range bits (${sWidth} > ${this.sendBitCount})`);
        if (rWidth > this.receiveBitCount)
            throw new Error(`One of more receive accessors references out of range bits (${rWidth} > ${this.receiveBitCount})`);

        // Create bit packets
        this.receivePacket = new BitPacket(this.receiveBitCount);
        this.sendPacket = new BitPacket(this.sendBitCount, () => this.onSendPacketChanged());
        this.sendPacketDirty = false;

        // Create receive buffer where we'll collect received packets until they're complete
        this.receiveBuffer = Buffer.alloc(this.receivePacket._buffer.length);
        this.receiveBufferUsed = 0;

        // Create buffers to detect if data actually changed
        this.receiveCompareBuffer = Buffer.alloc(this.receivePacket._buffer.length);
        this.sendCompareBuffer = Buffer.alloc(this.sendPacket._buffer.length);

        // Create serial port
        this.serialPort = new SerialPort(options.portName, options.portOptions);
        this.serialPort.on('data', this.onReceive.bind(this));
    }


    close()
    {
        this.serialPort.close();
    }

    defineAccessors(accessors, receive)
    {
        let member = receive ? "this.receivePacket" : "this.sendPacket";

        let maxMsb = -1;
        // Create accessors for the send buffer
        for (let k of Object.keys(accessors))
        {
            // Get the bit range
            let bitRange = accessors[k];
            let msb = bitRange[0];
            let lsb = bitRange[1];

            // Check it
            if (msb < lsb)
                throw new Error(`Bit range incorrect for '${k}', msb must be greater than lsb`);

            // Calculate max MSB
            if (msb > maxMsb)
                maxMsb = msb;

            let getter = BitPacket.buildGetAccessorBody(member, msb, lsb);
            let setter = BitPacket.buildSetAccessorBody(member, msb, lsb, k);

            // Define properties
            Object.defineProperty(this, k, {
                get: Function([], getter),
                set: Function(['value'], setter),
            });

            // Store meta data about accessors
            this.accessors[k] = {
                msb,
                lsb,
                width: msb - lsb + 1,
                receive,
            }
        }

        return maxMsb + 1;
    }

    get sendBitCount() { return this.options.sendBitCount };
    get receiveBitCount() { return this.options.receiveBitCount };

    formatHex(name)
    {
        // Get accessor info
        let ai = this.accessors[name];

        // get the value
        let val = this[name];

        return val.toString(16).padStart(Math.floor((ai.width + 3)/4), '0');
    }

    formatBinary(name)
    {
        // Get accessor info
        let ai = this.accessors[name];

        // get the value
        let val = this[name];

        return val.toString(2).padStart(ai.width, '0');
    }

    formatLeds(name)
    {
        return this.formatBinary(name).replace(/./g, x => x =='1' ? "●" : "-");
    }
    
    setBits(name, value)
    {
        let ai = this.accessors[name];
        (ai.receive ? this.receivePacket : this.sendPacket).setBits(ai.msb, ai.lsb, value);
    }

    getBits(name)
    {
        let ai = this.accessors[name];
        return (ai.receive ? this.receivePacket : this.sendPacket).getBits(ai.msb, ai.lsb);
    }

    // Received serial data
    onReceive(data)
    {
        for (let i=0; i<data.length; i++)
        {
            // Start of a new packet?
            if ((data[i] & 0x80) != 0)
            {
                this.receiveBufferUsed = 0;
            }
            else if (this.receiveBufferUsed < 0)
            {
                // Haven't received start of packet byte yet
                continue;
            }

            // Copy byte to the buffer
            this.receiveBuffer[this.receiveBufferUsed++] = data[i];

            // Entire packet received?
            if (this.receiveBufferUsed == this.receiveBuffer.length)
            {
                // Yep, swap buffers with the receive packet
                let temp = this.receiveBuffer;
                this.receiveBuffer = this.receivePacket._buffer;
                this.receivePacket._buffer = temp;

                // Prepare for next
                this.receiveBufferUsed = -1;

                // Fire events...
                this.onChange();
            }
        }
    }

    // Check if the receive buffer really did change since the last time we generated an event
    get didReceiveChange()
    {
        for (let i=0; i<this.receiveCompareBuffer.length; i++)
        {
            if (this.receiveCompareBuffer[i] != this.receivePacket._buffer[i])
                return true;
        }
        return false;
    }

    // Check it the send buffer really did change since the last time we generated an event
    get didSendChange()
    {
        for (let i=0; i<this.sendCompareBuffer.length; i++)
        {
            if (this.sendCompareBuffer[i] != this.sendPacket._buffer[i])
                return true;
        }
        return false;
    }

    onChange()
    {
        if (!this.changeEventPending)
        {
            this.changeEventPending = true;
            process.nextTick(() => {
                this.changeEventPending = false;
                if (this.didReceiveChange || this.didSendChange)
                {
                    this.sendPacket._buffer.copy(this.sendCompareBuffer);
                    this.receivePacket._buffer.copy(this.receiveCompareBuffer);
                    this.emit('change');
                }
            });
        }
    }

    // Someone changes the send packet, send it via serial port on the next
    // event loop tick.
    onSendPacketChanged()
    {
        if (!this.sendPacketDirty)
        {
            this.onChange();
            this.sendPacketDirty = true;
            process.nextTick(() => {
                this.sendPacketDirty = false;
                this.serialPort.write(this.sendPacket._buffer);
            });
        }

    }
}


module.exports = Reflector;
