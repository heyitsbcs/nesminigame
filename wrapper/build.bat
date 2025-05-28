@del ..\build\*.s    /q
@del ..\build\*.o    /q
@del ..\build\*.dbg  /q
@del ..\build\*.map  /q
@del ..\build\*.nes  /q

@REM compile all C sources into assembly
@for %%X in (*.c)          do ..\bin\bin\cc65.exe %%X -O -T -g -Werror -o ..\build\%%~nX.s || @goto error

@REM assemble objects
@for %%X in (*.s)          do ..\bin\bin\ca65.exe %%X       -g         -o ..\build\%%~nX.o || @goto error
@for %%X in (oss\*.s)      do ..\bin\bin\ca65.exe %%X       -g         -o ..\build\%%~nX.o || @goto error
@for %%X in (..\build\*.s) do ..\bin\bin\ca65.exe %%X       -g         -o ..\build\%%~nX.o || @goto error

@REM add every object to OBJECTS list
@setlocal EnableDelayedExpansion
@set OBJECTS=
@for %%X in (..\build\*.o) do @set OBJECTS=!OBJECTS! %%X
@set OBJECTS=!OBJECTS! ..\bin\runtime.lib

@REM link all objects into NES build
..\bin\bin\ld65.exe -o ..\build\wrapper.nes -m ..\build\wrapper.map --dbgfile ..\build\wrapper.dbg -C wrapper.cfg %OBJECTS% || @goto error

@echo.
@echo ROM build complete.

:error
