..\..\bin\bin\ca65 -g header.s
..\..\bin\bin\cc65 -O -T -g csamp.c
..\..\bin\bin\ca65 -g csamp.s

..\..\bin\bin\ld65 -C ..\minigame.cfg -o ..\minigame.bin -m ..\..\build\minigame.map header.o csamp.o ..\..\bin\runtime.lib
