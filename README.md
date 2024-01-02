# Node Version Manager Script
A standalone batch script to manage Node.js versions.  
* No administrator privilege required.  
* Only works for Windows Command Prompt.

## How It Works
The script switches between Node.js version by overriding `PATH` variable using **Command Prompt AutoRun**.  
```
HKCU\SOFTWARE\Microsoft\Command Processor\AutoRun
```  
This will run when a Command Prompt terminal starts:  
```
SET "PATH=%NVMS_NODE_HOME%;%PATH%"
```  

## Getting Started
1. Download and place `nvms.bat` and `RefreshEnv.cmd` in a folder. This will be the root folder for your Node.js installations.  
2. Go to the folder and open `cmd`.  
3. Run `nvms setup`.  Now you can run `nvms` anywhere.
```
C:\Users\User\AppData\Roaming\nvms>nvms setup

SUCCESS: Specified value was saved.
Environment variable NVMS_HOME is set as C:\Users\User\AppData\Roaming\nvms.
The operation completed successfully.
AutoRun command added to HKCU\Software\Microsoft\Command Processor.
C:\Users\User\AppData\Roaming\nvms is added to the environment path.

Restart the terminal for these changes to take effect.
```
4. Run `nvms install <version>` to install a specific Node.js version. E.g. `nvms install v20.10.0`.
5. Run `nvms use <version>` to start using that Node.js version.
6. Run `node -v` and check the correct Node.js is running.
```
C:\Users\User>node -v
v20.10.0
```
8. Restart Command Prompt and check if the correct Node.js is running.

## Credits
* RefreshEnv.cmd - [Chocolatey](https://github.com/chocolatey/choco/blob/stable/src/chocolatey.resources/redirects/RefreshEnv.cmd)  
* nvms.bat - [zqtay](https://github.com/zqtay)  
