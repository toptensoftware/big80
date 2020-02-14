let SerialConversation = require('./serial-conversation');

function showHelp()
{
    console.log("Soft resets the machine");
    console.log();
    console.log("Usage: bet reset [options]");
    console.log();
    console.log("Options:");
    console.log("  --port:<name>      serial port to connect to");
    console.log("  --baud:<value>     serial baud rate")
}


// Handle for `push` command
async function cmd_reset(args)
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
                throw new Error(`Unexpected arg: ${arg}`)
            }
        }

        
        // open serial port
        sc = new SerialConversation(options);
        await sc.open();

    // Send command and wait for ack
        await sc.write(`reset\n`);

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

module.exports = cmd_reset;
