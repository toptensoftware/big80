const ansiEscapes = require('ansi-escapes');
const readline = require('readline');

// Clear screen and make room for status line
process.stdout.write(ansiEscapes.clearScreen);
process.stdout.write("\n\n");

// Current status 
let counter = 1;

// Show current status
function showStatus()
{
    process.stdout.write(ansiEscapes.cursorHide);
    process.stdout.write(ansiEscapes.cursorSavePosition);
    process.stdout.write(ansiEscapes.cursorTo(0,0));
    process.stdout.write("THIS IS THE STATUS LINE: " + counter);
    process.stdout.write(ansiEscapes.cursorRestorePosition);
    process.stdout.write(ansiEscapes.cursorShow);
}
showStatus();

// Do stuff in the background
let timer = setInterval(() => {
    counter++;
    showStatus();
}, 100);

// Setup readline
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
    process.stdout.write(`Entered: '${line.trim()}'`);

    // Prompt again
    process.stdout.write(ansiEscapes.cursorTo(0,6));
    rl.prompt();
});
rl.on('close', () => {
    clearInterval(timer);
    process.stdout.write("\n\n");
});

/*

## Display string format ##

[000{7..0}000] - binary 10010001
[{15..8}:x] - hex 
[{7..0}:c] - ascii - "A"
[{7..0}:l] - led eg: #--#---#
[{7..0}:m:init,idle,tx,rx] - enumerated state


## Serial Protocol ##

High bit set indicates start of packet
High bit clear indicates continuation of packet

Remaining bit = bits being transmitted

*/

