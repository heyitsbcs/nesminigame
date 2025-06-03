..\..\bin\bin\ca65 -g header.s
..\..\bin\bin\ca65 -g asamp.s

..\..\bin\bin\ld65 -C ..\minigame.cfg -o ..\minigame.bin -m minigame.map --dbgfile minigame.dbg header.o asamp.o ..\..\bin\runtime.lib
