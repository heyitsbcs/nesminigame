# nesminigame
Sample and wrapper for NES minigame collection in the works. Note that this is the initial release and future updates should come to make this easier.
The `wrapper` directory contains the wrapper core that will build into a runnable .NES rom file.
The `samples` directory contains VERY basic examples of implementations of a minigame (really just a solid screen that waits for a keypress) in both C and assembly. Better samples coming soon!

**Note:** you'll need to build one of the samples before building the wrapper or it will fail to build.

## what is it?
This is a small project (made to be built with CC65/CA65) for making simple minigames that can run on the NES. The goal is to gather a small collection of these minigames to be sorted together in a collection to be announced in the future.
Minigames can be written either in C or in 6502 Assembly. Assembly is recommended due to the tighter control on RAM usage and codesize, but both are supported and have examples provided.

## how it works
You first setup a small header to provide the entrypoints and data for your minigame:
```
TEST_MINIGAME:
    .addr _testmg_init
    .addr _testmg_update
    .addr testmg_tiles
    .addr testmg_map
    .addr testmg_pal
    .word $0000
```

Note in this case the sample is using c for code but defining the data in the sample assembler file (with the underscore pre-pended to function names).
This provides the points for:

  `void testmg_init()` - Your minigame's init function. Called once at the start, AFTER your tiles / nametable / palette have been copied
  
  `void testmg_update(unsigned char keys)` - Your minigame's update / tick function. Called once per frame immediately after vblank processing is complete. The current keys pressed are passed in and can be checked against the values in minigame.h/minigame.inc (for C/assembly).

Then you simply implement those two functions for your minigame's logic and you're set to go.

Helper functions will be defined based on feedback. Currently the only planned helper functions are to play a song or sound via FamiStudio. Room is set aside for additional helper functions in the reserved jump table. Please let me know what else may be helpful!

## limitations
Because these are intended to run in the scope of a larger project, there are limitations, more so than even what is typical for an older system such as the NES:
 - You have a single 16k bank for your art and code to exist in
 - You have a smaller amount of RAM (256 bytes) and zero-page (48 bytes)
 - No control over the interrupt vectors (no nmi/vblank)

## benefits
However, along with these limitations, the system does a lot for you:
 - System setup is already done for you, allowing you to simply focus on your minigame
 - Initial tile and character copying is done for you, meaning if you have a single-screen game, you shouldn't need to touch that at all
 - There's already a 256-byte OAM table reserved that's automatically DMAd in during vblank making sprites easier to manage
 - FamiStudio is included outside of your code/ram usage, you'll just need to supply your song data along with the minigame binary


## building
First, you need to make the minigame. Go into the samples directory, pick a sample (currently there's only csamp), and in that directory, run make.bat

Then, build the wrapper by running build_rom.bat in the root of the project.

The output rom will be build/wrapper.nes

Depending on the sample chosen you'll see different things when running.

### csamp

![image](https://github.com/user-attachments/assets/c46f7f0f-940a-4086-8dac-39de47e841f6)


(more samples coming soon)
