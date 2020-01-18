let events = require('events');
const ansiEscapes = require('ansi-escapes');
const readline = require('readline');

class ReflectorUI extends events.EventEmitter
{
    constructor()
    {
        super();
    }

    // Show status message
    showStatus(msg)
    {
        process.stdout.write(ansiEscapes.cursorHide);
        process.stdout.write(ansiEscapes.cursorSavePosition);
        process.stdout.write(ansiEscapes.cursorTo(0,0));
        process.stdout.write(msg);
        process.stdout.write(ansiEscapes.cursorRestorePosition);
        process.stdout.write(ansiEscapes.cursorShow);
    }

    run()
    {
        // Clear screen and make room for status line
        process.stdout.write(ansiEscapes.clearScreen);
        process.stdout.write("\n\n");

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
            
            // Display command result
            process.stdout.write(ansiEscapes.cursorTo(0,2));
            process.stdout.write(ansiEscapes.eraseDown);

            // Generate event
            this.emit("line", line);
        
            // Prompt again
            process.stdout.write(ansiEscapes.cursorTo(0,6));
            rl.prompt();
        });
        rl.on('close', () => {
            this.emit("close");
            process.stdout.write("\n\n");
        });
    }    
}

module.exports = ReflectorUI;
