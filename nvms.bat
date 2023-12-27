@ECHO off

SETLOCAL EnableDelayedExpansion

SET VERSION=1.0
SET NVMS_HOME=%NVMS_HOME%
SET NVMS_NODE_HOME=%NVMS_NODE_HOME%

REM Get command parameters
SET "command=%1"
SET "param1=%2"

IF "!command!" == "auto" (
    ENDLOCAL & (
        SET "PATH=%NVMS_NODE_HOME%;%PATH%"
    )
    GOTO end
)

SET "isSetupCommand="
IF "!command!" == "install" SET "isSetupCommand=1"
IF "!command!" == "list" SET "isSetupCommand=1"
IF "!command!" == "use" SET "isSetupCommand=1"
IF "!command!" == "uninstall" SET "isSetupCommand=1"
IF "!command!" == "clean" SET "isSetupCommand=1"

SET "isOpCommand="
IF "!command!" == "on" SET "isOpCommand=1"
IF "!command!" == "current" SET "isOpCommand=1"

IF "!command!" == "" (
	GOTO help
) ELSE IF "!command!" == "help" (
	GOTO help
) ELSE IF "!command!" == "setup" (
	GOTO setup
) ELSE IF DEFINED isSetupCommand (
    REM Check if root folder path is set
	IF !NVMS_HOME! == "" GOTO rootNotDefined
    IF NOT DEFINED NVMS_HOME GOTO rootNotDefined
	IF "!command!" == "install" (
		GOTO install
	) ELSE IF "!command!" == "list" (
		GOTO list
	) ELSE IF "!command!" == "use" (
		GOTO use
	) ELSE IF "!command!" == "uninstall" (
		GOTO uninstall
	) ELSE IF "!command!" == "clean" (
		GOTO clean
	)
) ELSE IF DEFINED isOpCommand (
    IF !NVMS_NODE_HOME! == "" GOTO versionNotDefined
    IF NOT DEFINED NVMS_NODE_HOME GOTO versionNotDefined
    IF "!command!" == "on" (
        GOTO on
    ) ELSE IF "!command!" == "current" (
        ECHO %NVMS_NODE_HOME%
        GOTO end
    )
)

ECHO The command "!command!" is invalid.
GOTO end

REM ######## Command handlers ########

:help
ECHO Node.js Version Manager Script
ECHO Running version %VERSION%.
ECHO.
ECHO Usage:
ECHO.
ECHO   nvms help                     : Show this help text.
ECHO   nvms setup                    : Set up environment and registry required for nvms.
ECHO   nvms install ^<version^>        : Install a specific version of node.js.
ECHO   nvms list                     : List the node.js installations.
ECHO   nvms use [version]            : Switch to use the specified version.
ECHO   nvms on                       : Switch to use the specified version.
ECHO   nvms uninstall ^<version^>      : Uninstall a specific version of node.js.
ECHO   nvms clean                    : Clean the temp folder used for installation.
GOTO end

:setup
SET "currentDir=%cd%"

SETX NVMS_HOME "%currentDir%"
ECHO Environment variable NVMS_HOME is set as %currentDir%.

reg add "HKCU\Software\Microsoft\Command Processor" /v AutoRun /t REG_EXPAND_SZ /d "nvms auto" /f
ECHO AutoRun command added to HKCU\Software\Microsoft\Command Processor.

REM Get env path
SET "envPath="
FOR /f "tokens=2*" %%a IN ('REG QUERY "HKCU\Environment" /v "Path"') DO SET "envPath=%%~b"

REM Check if current directory is already in the environment path
ECHO !envPath! | find /i "%currentDir%" > nul

REM If the current directory is not in the path, add it
if %errorlevel% neq 0 (
    REM reg add "HKCU\Environment" /v PATH /d "!envPath!;%currentDir%" /f
    ECHO %currentDir% is added to the environment path.
) else (
    ECHO %currentDir% is already in the environment path.
)

CALL :updateRegistryChange

ECHO.
ECHO Restart the terminal for these changes to take effect.
GOTO end

:install
IF "!param1!" == ""  (
	ECHO A node.js version must be specified.
	GOTO end
)

SET "url=https://nodejs.org/dist/!param1!/node-!param1!-win-x64.zip"
SET httpcode=
REM Check if url is valid
FOR /f %%a IN ('curl -sS -I -w "%%{http_code}" !url!') DO SET httpcode=%%a

IF !httpcode! == 200 (
	REM Download from nodejs
	ECHO Downloading from !url! ...
	curl -o %NVMS_HOME%\temp\!param1!.zip !url!
	
	REM Unzip
	ECHO Unzipping ...
	powershell Expand-Archive %NVMS_HOME%\temp\!param1!.zip -DestinationPath %NVMS_HOME%\temp
	
	REM Rename and move to root folder
	ren %NVMS_HOME%\temp\node-!param1!-win-x64 !param1!
	move %NVMS_HOME%\temp\!param1! %NVMS_HOME%

	ECHO Node.js version !param1! is installed to %NVMS_HOME%\!param1!.
) ELSE IF !httpcode! == 404 (
	ECHO "!param1!" is not a valid node.js version.
) ELSE (
	ECHO Failed to download node.js version !param!. HTTP !httpcode!.
)

GOTO end

:list
SET "list="
FOR /d %%D IN ("%NVMS_HOME%\*") DO (
    IF EXIST "%%D\node.exe" (
        ECHO %%~nxD
    )
)
GOTO end

:use
IF "!param1!" == ""  (
	ECHO A node.js version must be specified.
	GOTO end
)
IF NOT EXIST %NVMS_HOME%\!param1!\node.exe (
	ECHO Node.js version !param1! is not installed.
	GOTO end
)

SET "newpath=%PATH%"
SET "nodepath=%NVMS_HOME%\!param1!"

CALL :prependNodePath

REM Save current path
SETX NVMS_NODE_HOME "!nodepath!"

ECHO Current node.js version is set to !param1!.
ENDLOCAL & (
    REM Update env path
    SET "PATH=%newpath%"
    REM powershell -command '$env:path=\"%newpath%\"'
)
GOTO end

:on
SET "newpath=%PATH%"
SET "nodepath=%NVMS_NODE_HOME%"
CALL :prependNodePath
ENDLOCAL & (
    SET "PATH=%newpath%"
    REM powershell -command '$env:path=\"%newpath%\"'
)
GOTO end

:uninstall
IF "!param1!" == ""  (
	ECHO A node.js version must be specified.
	GOTO end
)
IF NOT EXIST %NVMS_HOME%\!param1!\node.exe (
	ECHO Node.js version !param1! is not installed.
	GOTO end
)

REM Delete folder recursively
del /s /q %NVMS_HOME%\!param1!
rmdir /s /q %NVMS_HOME%\!param1!

ECHO Node.js version !param1! is deleted.
GOTO end

:clean
REM Delete folder recursively
del /s /q %NVMS_HOME%\temp
rmdir /s /q %NVMS_HOME%\temp

ECHO Temp folder is cleaned.
GOTO end

:rootNotDefined
ECHO The root path for node.js installation is not defined. 
ECHO Run "nvms setup" to fix this.
GOTO end

:versionNotDefined
ECHO A working node.js version is not defined. 
ECHO Run "nvms use <version>" to fix this.
GOTO end

:updateRegistryChange
REM Update registry changes
RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters ,1 ,True

:prependNodePath
REM Remove new path from env path
CALL SET "newpath=%%newpath:!nodepath!=%%"

REM REM Clean up semicolon
SET "newpath=!newpath:;;=;!"

REM Add the path to the top of the list of env path
SET "newpath=!nodepath!;!newpath!"

REM Clean up semicolon
SET "newpath=!newpath:;;=;!"

:end
EXIT /B