let SerialConversation = require('./serial-conversation');
let fs = require('fs');
let path = require('path');

function showHelp()
{
    console.log("Transfers a local file to the FPGA's SD card");
    console.log();
    console.log("Usage: bet pull [options] remoteFile [localFile]");
    console.log();
    console.log("Options:");
    console.log("  --port:<name>      serial port to connect to");
    console.log("  --baud:<value>     serial baud rate")
}


// Handle for `pull` command
async function cmd_pull(args)
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

                    case "help":
                        showHelp();
                        return;
        
                    default:
                        throw new Error(`Unknown switch: ${parts[0]}`)
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
        let sourceName = files[0];
        let targetName = files.length == 1 ? path.basename(files[0]) : files[1];
        
        // open serial port
        sc = new SerialConversation(options);
        await sc.open();

        // Send command and wait for response
        await sc.write(`pull ${sourceName}\n`);

        // Read line (response should be length of file in decimal)
        let line = await sc.readToEOL();
        if (line[0] == '!')
            throw new Error(`Failed - ${line.substr(1)}`);
        
        // Allocate buffer 
        let fileBuf = Buffer.alloc(Number(line));

        // Log message
        console.log(`Receiving ${sourceName} (${fileBuf.length} bytes) `)

        // Receive data...
        let pos = 0;
        while (pos < fileBuf.length)
        {
            // Read chunk length
            let chunkLen = (await sc.readWait(1))[0];

            // Read chunk data
            let chunkData = await sc.readWait(chunkLen);

            // Read the checksum
            let checkSumReceived = (await sc.readWait(1))[0];

            // Calculate the checksum
            let checksumData = 0;
            for (let i=0; i<chunkLen; i++)
            {
                checksumDtaa += chunkData[i];
            }

            // Check if matches
            if (checkSumReceived[0] != (checksumData % 0xff))
            {
                await sc.write("\x00");     // non-ack
                throw new Error("Checksum");
            }

            // Send ack
            await sc.write("\x06");

            // Copy data to file buffer
            chunkData.copy(fileBuf, pos);

            // Progress display
            process.stdout.write(".");

            // Update position
            pos += chunkData.length;
        }

        // Read EOT
        let eot = (await sc.readWait(1))[0];
        if (eot != "\x04")
            throw new Error("Didn't receive EOT");

        // Save the file
        fs.writeFileSync(targetFile, fileBuf);

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

module.exports = cmd_pull;