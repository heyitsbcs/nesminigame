..\..\bin\bin\ca65 header.s
..\..\bin\bin\cc65 csamp.c
..\..\bin\bin\ca65 csamp.s

..\..\bin\bin\ld65 -C ..\minigame.cfg -o ..\minigame.bin -m ..\minigame.map header.o csamp.o ..\..\bin\runtime.lib
