# Big-80 Version 2.0

Big-80 is an FPGA implementation of TRS-80 Model 1.  

It currently supports:

* Z80 CPU (using the [T80](https://opencores.org/projects/t80) open core) running at 1.777Mhz
* 48Kb RAM
* 12Kb Level II BASIC ROM
* 1Kb Video RAM
* 4Kb Character ROM
* PS2 Keyboard Inteface
* VGA Display at 800 x 600 @ 60Hz
* Virtual Cassette Player using reading from SD Card
* On-screen Menus
* FAT support on SD card

Supported boards:

* [Numato Lab Mimas V2](https://numato.com/product/mimas-v2-spartan-6-fpga-development-board-with-ddr-sdram)

## Blog Posts

There's a series of blog posts about this project [available here](https://www.toptensoftware.com/blog/tag/big80/).

## Download and Setup (Mimas V2)

1. Download the [FPGA binary file]((https://github.com/toptensoftware/big80/raw/V2/boards/mimasv2/99-big80-lpddr/bin/99-big80-lpddr.bin)

2. Upload it to the FPGA board.  You can use either the tools provided by Numato or use [this updated firmware](https://github.com/toptensoftware/MimasV2-Loader) in which case you can upload to the board from Linux like so:

        $ mimasv2-prog --filename 99-big80-lpddr.bin

3. Download the Big-80 system firmware - [big80.sys](https://github.com/toptensoftware/big80/raw/V2/syscon/bin/big80.sys) and place it in the root directory of a FAT formatted SD card.

4. Place a copy of the TRS-80 Model 1 ROM image in the root directory of the SD card.  This file must be named "level2-a.rom".  (you'll have to locate this file yourself).

4. Insert the SD card in the FPGA board

5. Make sure all the DIP switches are in the down position

6. Connect a VGA monitor

7. Connect a speaker to the audio output (optional)

8. Connect a [PS2 Pmod](https://store.digilentinc.com/pmod-ps2-keyboard-mouse-connector/) to the lower 6 pins of the left most GPIO connector (P6) and connect a keyboard to the PS2 PMod.

9. Power on the FPGA board, and you should be presented with the TRS-80 BASIC prompt.



## Operating Big-80's Virtual Cassette Player

Big-80 can load cassette images using the built-in virtual cassette player.

1. Place the required .cas files on the SD card
2. Press the F12 key do display the on-screen menu
3. Select the "Choose Tape..." command
4. Select a .cas file by navigating the displayed menu
5. In the Options menu, make sure "Auto Start Tape" is enabled
6. Close the on-screen by pressing F12 again (or Escape key)
7. In the TRS-80 load the cassette with the `SYSTEM` or `CLOAD` command as per normal

To record a cassette:

1. Make sure the "Auto Start Tape" option is enabled
2. Save your file from the TRS-80 as per normal `CSAVE`
3. The recording will be saved as a file named "RECORD.CAS" in the root director of the SD card
4. Each save will overwrite the previous recording
5. To keep a copy of recording, press F12, choose "Save Recording..." and enter the path/name of 
   where to copy the file.

You can also manually control the cassette player by turning off the option "Auto Start Tape" and 
using the menu commands "Play", "Record" and "Stop" to control the player.



## Options

To access the Options menu, press F12 and choose the Options command from the displayed menu.

The following options are available:

* Screen Color - choose green screen or amber
* Scan Lines - enable/disable fake screen lines
* Auto Start Tape - automatically start and stop the cassette player/recorder
* Turbo Tape - enable for much faster tape loading and saving
* Tape Audio Monitor - send cassette audio signals to speakers
* Typing Mode - enables a more natural typing mode on PC keyboards. You may need to disable for some games in which case the keys map to approximate positions on an original TRS-80 keyboard.

The selected options are saved to the SD card in a file name "BIG80.CFG".



## DIP Switch Settings

The left most DIP switch is is a Run/Stop switch.  When in the down position the machine runs normally.  In the up position the CPU stops execution and display freezes (including the on-scren menus).

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

For a detailed guide on how to setup all these tools with a simple helper script, see this [blog post](https://www.toptensoftware.com/blog/the-ultimate-xilinx-ise-14-7-setup-guide/).


## Build Instructions

To build the project:

```
$ cd ./boards/mimasv2/99-big80-lpddr
$ make
```

The final .bin file will be in the `./boards/mimasv2/99-big80-lpddr/bin` directory.

If you've got the previously mentioned updated firmware, you can upload to the board with the following command (from th e 99-big80-lpddr directory):

```
$ make upload
```

Notes:

1. if you're running Linux in a virtual machine, you'll have to make sure the USB port the
board is plugged into is forwarded by the VM host. In VirtualBox, check the Devices -> USB menu.
2. for the Mimas V2 board you need to upload the `.bin` file - not the `.bit` file.


## Hacking on Big-80

The directory structure of this project is as follows:


* `./boards` - anything that's specific to a particular FPGA board.
* `./resources` - miscellaneous resources like original ROM images etc...
* `./shared` - shared VHDL components that aren't specific to a TRS-80
* `./shared` shared VHDL code specified to a TRS-80
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