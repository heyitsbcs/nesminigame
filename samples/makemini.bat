..\bin\bin\ca65 testmg.s
..\bin\bin\cc65 testmgc.c
..\bin\bin\ca65 testmgc.s
..\bin\bin\ld65 -C minigame.cfg -o minigame.bin  -m minigame.map testmg.o testmgc.o ..\bin\runtime.lib
