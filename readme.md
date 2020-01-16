# Big-80

Big-80 is an FPGA implementation of TRS-80 Model 1.  

It currently supports/includes:

* Z80 CPU (using the [T80](https://opencores.org/projects/t80) open core) running at 1.777Mhz
* 48Kb RAM
* 12Kb Level II BASIC ROM
* 1Kb Video RAM
* 4Kb Character ROM
* PS2 Keyboard Inteface
* VGA Display at 800 x 600 @ 60Hz
* Virtual Cassette Player using reading from SD Card

Supported boards:

* [Numato Lab Mimas V2](https://numato.com/product/mimas-v2-spartan-6-fpga-development-board-with-ddr-sdram)

## Blog Posts

I've written/am writing a series of blog posts about this project.  You can [read them all here](https://www.toptensoftware.com/blog/tag/big80/).

## Download

* [Mimas V2 .bin file](https://github.com/toptensoftware/big80/blob/master/boards/mimasv2/99-big80/bin/big80.bin?raw=true)


## Build Prerequisites

To build this project you'll need a Linux machine with the following 
tools installed:

* [Xilinx ISE Design Suite 14.7](https://www.xilinx.com/products/design-tools/ise-design-suite.html) (the free WebPack license will do)
* [Node 10.x](https://nodejs.org/en/) (v8.x might work too)
* [Xilt](https://www.npmjs.com/package/xilt) (front-end driver for Xilinx command line tool chain).
* Make (ie: sudo apt-get install build-essential)
* [GHDL](http://ghdl.free.fr) (optional, required to run simulations)
* [GTKWave](http://gtkwave.sourceforge.net) (options, required to view simulations)
* [Visual Studio Code](https://code.visualstudio.com/docs/setup/linux) (optional)

To install any or all of the above you might find my [xilsetup](https://bitbucket.org/toptensoftware/xilsetup/) script handy.


## Build Instructions (Mimas V2)

To build the project:

```
$ cd ./boards/mimasv2/99-big80
$ make
```

The final .bin file will be in the `./boards/mimasv2/99-big80/bin` directory.

I recommend using [this updated firmware](https://github.com/toptensoftware/MimasV2-Loader) for the Mimas V2 which will then let you upload to the board like so:

```
$ make upload
```

Notes:

1. if you're running Linux in a virtual machine, you'll have to make sure the USB port the
board is plugged into is forwarded by the VM host. In VirtualBox, check the Devices -> USB menu.
2. for the Mimas V2 board you need to upload the `.bin` file - not the `.bit` file.
3. the `./boards/mimasv2` directory also contains several other experiments and 
test projects that you can try if you're interested.


## Running Simulation Test Benches

Simulation test benches for various components are available in the `./sims` sub-directory.

These simulations have only been tested using the LLVM build of GHDL - they may or may not
work in the other builds.

To run and view the simulation signal traces,  run `make view` in the project directory.

```
$ cd ./sims/01-sim-basics
$ make view
```


## Big-80 Operating Instructions

To use Big-80 on the Mimas V2, you'll need to:

* Upload the .bin file to the Mimas V2 board (see notes above)
* Make sure all the DIP switches are in the on (down) position
* Connect a VGA monitor
* Connect a speaker to the audio output (optional, for sound)
* Connect a [PS2 Pmod](https://store.digilentinc.com/pmod-ps2-keyboard-mouse-connector/) to the lower 6 pins of the left most GPIO connector (P6)
* Connect a keyboard to the PS2 PMod
* Insert an SD card with cassette images (optional)

Power on the board, and you should be presented with the TRS-80 Basic prompt.

If the keyboard doesn't work, it could be that your keyboard doesn't work on the 3.3V
supplied by the Mimas, or it might take a few seconds to start up at that lower voltage. Give it a good 10 seconds and if it still doesn't work try a different keyboard.

To reset the board, use the top-right button on the Mimas board.

## DIP Switch Settings

From left-to-right, the DIP switches on the Mimas V2 control the following features:

* Run/Stop Switch - when off, the CPU stops execution and display freezes.
* Unused
* Auto Cassette Mode - when on, the virtual cassette player start/stop automatically
* Cassette Audio Monitor - when on, cassette audio signals will be sent to the speaker output
* No Scan Lines - switch to the off position to enable simulated scan lines on the monitor
* Green Screen - switches between green and amber screen colour
* Turbo Tape Mode - enables fast cassette loading (approx 20x faster)
* Typing Mode - maps PC key strokes to equivalent TRS-80 keys for easier typing

## LED Indicators

From left-to-right, the LED indicators show the followin:

* SD Initialized Successfully (reset to retry if failed)
* SDHC Mode - indicates if SD card was recognised as an SDHC card
* SD Write - SD busy writing
* SD Read - SD busy reading
* Cassette Audio Out - flickers when sending cassette audio (or sound)
* Cassette Audio In - flickers when receiving cassette audio
* Cassette Recording Mode - indicates cassette is recording in progress
* Cassette Active - indicates cassette is either playing or recording

## Operating Big-80's Virtual Cassette Player

Big-80 can load cassette images using the built-in virtual cassette player.

1. Prepare the SD card (as described below) and insert into the Mimas V2
2. If you've just inserted the SD card, you'll need to reset the board for it to be detected
3. Select the tape number using the 7-segment LED display and the up and down navigation buttons on the Mimas board
3. If you have the auto-cassette option enabled (third DIP switch from the left in down position) then you don't need
to do anything else, the cassette player will start and stop automatically. (including automatically recording)
4. Start the TRS-80 load or save (eg: SYSTEM command, type name of tape and press Enter)
5. Start the tape playing by pressing the right navigation button.  If you're saving, press and hold the left navigation button while pressing the right navigation button.
6. Wait for the tape to load/save
7. Press the right navigation button again to stop the cassette player

(if you don't stop the cassette player it will continue to play indefinitely, reading each
successive block from the SD card and rendering to audio).

While the tape is playing the 7-segment display switches to show the number of SD card 
blocks that have been rendered. Each block is 512 bytes so you can estimate the tape progress.

eg: suppose the tape is 10Kb in length, that's 20 blocks, or 14 hex (as it will be displayed 
on the 7-segment display)


## Preparing an SD Card with Virtual Cassette Images

Since Big-80 doesn't understand any file systems, the SD card needs to be prepared
in such a way that the cassette images can be streamed sequentially from the card.

The SD card format is very simple... each virtual tape starts at a 16Kb boundary.  Given each
block is 512 bytes, that means the first tape occupies blocks 0 to 31, the second 32 to 63 etc...

To prepare the SD image is a two step process - first create an image file containing all the 
tapes you want, and the writing that image to the SD card.

To prepare the image, in the `./tools/caspack` sub-directory is a node script.  Before you 
run it the first time, you'll need to run `npm install` in that directory.

~~~
$ cd ./tools/caspack
$ npm install
~~~

Once you've done that, change to the directory where your TRS-80 .cas files reside. (Note you need `.cas` files - not `.wav` audio files)

~~~
$ cd ~/MyTrs80Tapes/
$ node ~/your-big80-dir-whatever/tools/caspack/caspack.js
~~~

This will produce a file `caspack.img` and list out the tape numbers for each .cas file added.

You can now write the image file to the SD Card using any disk image writing tool.

Here's how to do it on Linux command line:

1. With the SD card removed, run the following command and note the names of your current
   disk devices:

        $ sudo fdisk --list
        
2. Insert the SD into a card reader (remember, if you're using a USB card reader that in VirtualBox you might need to forward the USB port so Linux can see it)

3. Run the above `fdisk` command again and notice that name of the new device that appeared.  It should
   be something like `/dev/sdd`

4. Make sure the SD card doesn't have anything you want to keep as you're about to completely overwrite that card.

5. Finally, write the caspack image to the SD card.  Double and triple check /NAME/OF/DISK since
    whichever disk name you enter here will be erased.

        $ sudo dd of=/NAME/OF/DISK/FROM/STEP/3 if=caspack.img bs=1M

## Hacking on Big-80

The directory structure of this project is as follows:


* `./boards` - anything that's specific to a particular FPGA board.
* `./resources` - miscellaneous resources like original ROM images etc...
* `./shared` - shared VHDL components that aren't specific to a TRS-80
* `./shared-trs80` shared VHDL code specified to a TRS-80
* `./sims` - all simulation test benches
* `./tools` - tools and scripts.

The `./boards` and `./sims` directory both contain numbered sub-projects.  The idea here is to keep all experiments and test benches and the numbers help keep them in sequence.

Within each project directory is a VS Code workpace file and tasks.json file.  To work with these:

1. Change to the directory of the project
2. Run `code workspace.code-workspace`
3. Use the VS Code build command to build the project
4. For FPGA projects, use the Terminal menu -> Run Task -> "Upload" task program the board
5. For simulation projects, use the Terminal menu -> Run Task -> "View" task to run the simulation and launch GTKWave.

Note: if you launch GTKWave from VS Code you'll need to close it before being able to run additional tasks in VS Code.  I've not been able to find a solution for this.  Remember to Ctrl+S before closing GTKWave to keep your displayed signals and positions.

## License

Copyright © 2019 Topten Software. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this product except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.