
function showHelp()
{
    console.log("Big80 Utilities");
    console.log();
    console.log("Copyright (C) 2020 Topten Software.");
    console.log("All Rights Reserved");
    console.log();
    console.log("Usage: bet <command> <options>");
    console.log();
    console.log("Commands:");
    console.log("  push      push a file to FPGA SD card");
    console.log("  reset     soft reset the machine")
    console.log();
    console.log("For more help on a command, use bet <command> --help");
}

if (process.argv.length < 3)
{
    showHelp();
    return;
}

switch (process.argv[2])
{
    case "push":
        require('./cmd-push')(process.argv.slice(2));
        break;

    case "reset":
        require('./cmd-reset')(process.argv.slice(2));
        break;

    case "help":
        showHelp();
        break;

    default:
        console.error(`Unknown command: ${process.argv[2]}`);
}
