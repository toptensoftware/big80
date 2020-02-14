let SerialPort = require('serialport');
let util = require('util');

function indexInBuf(buf, ch)
{
    for (let i=0; i<buf.length; i++)
    {
        if (buf[i] == ch)
            return i;
    }
    return -1;
}

// Helper for performing a serial "conversation" where client
// sends a command, waits for a response, repeats
class SerialConversation
{
    constructor(options)
    {
        // Create serial port
        this.serialPort = new SerialPort(options.port, { 
            baudRate : options.baud, 
            autoOpen: false 
        });

        // List of received buffers
        this.receivedBuffers = [];
    }

    // On receiving data, add it to the received buffer list
    onReceive(data)
    {
        //console.log("RX:", data);

        // Capture the data
        this.receivedBuffers.push(data);

        // Resolve waiting promise
        if (this.waiter)
            this.waiter();
    }

    // Open the serial port
    async open()
    {            
        // Open serial port
        await new Promise((resolve, reject) => {
            this.serialPort.open(function(err) { 
                if (err)
                    reject(err);
                else
                    resolve();
            });
        });

        // Flush any data sitting in buffers
        await new Promise((resolve, reject) => {
            this.serialPort.flush(function(err) { 
                if (err)
                    reject(err);
                else
                    resolve();
            });
        });

        // Receive data handler
        this.serialPort.on('data', this.onReceive.bind(this));
    }

    // Close the serial port
    async close()
    {
        if (this.serialPort && this.serialPort.isOpen)
        {
            await new Promise((resolve, reject) => {
                this.serialPort.close(function(err) { 
                    if (err)
                        reject(err);
                    else
                        resolve();
                });
            });
        }
    }

    // Write data/string to serial port
    async write(data, encoding)
    {
        await new Promise((resolve, reject) => {
            //console.log("TX:", data);
            this.serialPort.write(data, encoding, function(err) { 
                if (err)
                    reject(err);
                else
                    resolve();
            });
        });
    }

    // Read all data to the next EOL
    async readToEOL()
    {
        // Create buffer
        let bufs = [];

        while (true)
        {
            if (this.receivedBuffers.length > 0)
            {
                let src = this.receivedBuffers[0]
                let pos = indexInBuf(src, '\n'.charCodeAt(0));
                if (pos >= 0 && pos < src.length)
                {
                    // Use part of the buffer...

                    // Copy out the bit we want
                    let buf = Buffer.alloc(pos);
                    src.copy(buf, 0, 0, pos);
                    bufs.push(buf);

                    // Skip the \n
                    pos++;

                    if (pos < src.length)
                    {
                        // Split the buffer to extract the part we need
                        let subBuf = Buffer.alloc(src.length - pos);
                        src.copy(subBuf, 0, pos, pos + subBuf.length);
                        this.receivedBuffers.shift();
                        this.receivedBuffers.unshift(subBuf);
                    }
                    else
                    {
                        this.receivedBuffers.shift();
                    }

                    // Finished
                    return bufs.map(x=> x.toString("utf8")).join("");
                }
                else
                {
                    // Use the entire buffer
                    bufs.push(src);
                    this.receivedBuffers.shift().length;
                }
            }
            else
            {
                // Wait for more data
                await new Promise((resolve, reject) => {
                    this.waiter = resolve;
                });
                this.waiter = null;
            }
        }
    }

    // Read length bytes from serial port (blocks until the specified
    // number of bytes have been received)
    async readWait(length)
    {
        // Create buffer
        let buf = Buffer.alloc(length);
        let received = 0;

        while (received < length)
        {
            if (this.receivedBuffers.length > 0)
            {
                let src = this.receivedBuffers[0]
                if (src.length > length - received)
                {
                    // Use part of the buffer...

                    // Copy out the bit we want
                    src.copy(buf, received, 0, length - received);

                    // Split the buffer to extract the part we need
                    let subBuf = Buffer.alloc(src.length - (length - received));
                    src.copy(subBuf, 0, length - received, length - received + subBuf.length);
                    this.receivedBuffers.shift();
                    this.receivedBuffers.unshift(subBuf);

                    // Finished
                    received = length;
                }
                else
                {
                    // Use the entire buffer
                    src.copy(buf, received);
                    received += this.receivedBuffers.shift().length;
                }
            }
            else
            {
                // Wait for more data
                await new Promise((resolve, reject) => {
                    this.waiter = resolve;
                });
                this.waiter = null;
            }
        }
        return buf;
    }

    // Check for an ack response
    async waitAck()
    {
        // Read the ack byte
        let ack = await this.readWait(1);

        // If not an ack, read to eol for an error message
        if (ack[0] != 6)
        {
            let err = await this.readToEOL();
            throw new Error(`No ack - ${err}`);
        }
    }
}

module.exports = SerialConversation;