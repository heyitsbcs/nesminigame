@md build

@PUSHD wrapper
call build.bat
@POPD
@if ERRORLEVEL 1 goto error

@echo.
@echo.
@echo Build successful!
@goto end
:error
@echo.
@echo.
@echo Build error!
:end
@if NOT "%1" == "nopause" pause
