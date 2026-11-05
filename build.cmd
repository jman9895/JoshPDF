@echo off
setlocal
cd /d "%~dp0"
echo === qpdf GUI installer build ===

call :findiscc
if defined ISCC goto :compile
echo Inno Setup not found - installing it with winget...
winget install --id JRSoftware.InnoSetup -e --silent --accept-package-agreements --accept-source-agreements
call :findiscc
if not defined ISCC goto :noiscc

:compile
"%ISCC%" "qpdf-gui.iss"
if errorlevel 1 goto :buildfail
echo.
echo SUCCESS - installer is in: %~dp0output
explorer "%~dp0output"
goto :end

:findiscc
set "ISCC="
if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"
if exist "%LocalAppData%\Programs\Inno Setup 6\ISCC.exe" set "ISCC=%LocalAppData%\Programs\Inno Setup 6\ISCC.exe"
exit /b 0

:noiscc
echo ERROR: Inno Setup 6 could not be found or installed. Install it from jrsoftware.org and run build.cmd again.
goto :end
:buildfail
echo ERROR: Inno Setup compile failed - see messages above.
:end
echo.
pause
