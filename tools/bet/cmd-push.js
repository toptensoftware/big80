let SerialConversation = require('./serial-conversation');
let fs = require('fs');
let path = require('path');


// Handle for `push` command
async function cmd_push(args)
{
    let sc;
    try
    {
        // Parse arguments
        options = {
            port: "COM8",
            baud: 115200,
        }
        let files = [];

        for (let arg of args.slice(1))
        {
            if (arg.startsWith("--"))
            {
                let parts = arg.substr(2).split(":");
                switch (parts[0].toLowerCase())
                {
                    case "port":
                        options.port = parts[1];
                        break;
        
                    case "baud":
                        options.baud = Number(parts[1]);
                        break;
        
                }
            }
            else
            {
                files.push(arg);
            }
        }

        // Must have a file to send
        if (files.length < 1)
        {
            throw new Error("No file specified");
        }

        // Read the file
        let fileBuf = fs.readFileSync(files[0]);
        let targetName = files.length == 1 ? path.basename(files[0]) : files[1];
        
        // open serial port
        sc = new SerialConversation(options);
        await sc.open();

        // Send command and wait for ack
        await sc.write(`push ${targetName} ${fileBuf.length}\n`);
        await sc.waitAck();

        // Log message
        console.log(`Sending ${targetName} (${fileBuf.length} bytes) `)

        // Send in chunks of 64 bytes
        let pos = 0;
        while (pos < fileBuf.length)
        {
            // Create chunk
            let chunkLength = Math.min(fileBuf.length - pos, 64);
            let chunkBuf = Buffer.alloc(chunkLength + 2);
            fileBuf.copy(chunkBuf, 1, pos, pos+chunkLength);

            // First byte is the chunk length
            chunkBuf[0] = chunkLength;

            // Last byte is the checksum
            let checksum = 0;
            for (let i=0; i<chunkLength; i++)
            {
                checksum += chunkBuf[i+1];
            }
            chunkBuf[chunkLength+1] = checksum & 0xFF;

            // Send it, wait for ack
            await sc.write(chunkBuf);
            await sc.waitAck();

            // Progress display
            process.stdout.write(".");

            // Update position
            pos += chunkLength;
        }

        // Send the EOT and wait for ack
        await sc.write("\x04");
        await sc.waitAck();

        // Done!
        console.log("\nOK");
    }
    finally
    {
        // Close connection
        if (sc)
            await sc.close();
    }
}

module.exports = cmd_push;
