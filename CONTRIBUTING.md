## Tools
- Any IDE with Lua syntax support
- See **Debugging** for instructions to obtain Decoda and luacheck.
- Check out [Modding: Useful Tools](https://noita.wiki.gg/wiki/Modding:_Useful_Tools)
  - [CheatGUI](https://steamcommunity.com/sharedfiles/filedetails/?id=1984977713) - Incredibly helpful, spawn stuff, teleport to Holy Mountains.
  - [Component Explorer](https://noita.wiki.gg/wiki/Mod:Component_Explorer) - Useful for debugging component hierarchies.
  - [Enable Logger](https://steamcommunity.com/workshop/filedetails/?id=2124936579) - Recommended, shows `print()` output in `logger.txt`.
  - [Visual Studio Marketplace: Noita Lua API](https://marketplace.visualstudio.com/items?itemName=evaisa.vscode-noita-api) - Autocomplete plugin for VSCode.

## References
- [Lua 5.2 reference manual](https://www.lua.org/manual/5.2/)
- [Noita Modding: Lua API](https://noita.wiki.gg/wiki/Modding:_Lua_API)

## Debugging
The following is the contents of `Noita/tools_modding/lua_debugging.txt`. This is highly recommended to assist with figuring out Lua problems.

```
This file contains instructions for debugging Noita's Lua scripts. 

We assume that you have basic experience using a graphical debugger (e.g. understand the concept of a breakpoint).
Please note that running the game with the -debug_lua parameter enables some lua sandbox escape exploits, so you shouldn't do that when any untrusted mods are enabled.

1) Download and install the Decoda IDE: https://unknownworlds.com/decoda/download/
2) Start Decoda
3) Select Project -> Settings
4) In the dialog set "Command" to point to your noita_dev.exe
5) Set "Command arguments" to -debug_lua
6) Set "Working directory" to point to the directory where noita_dev.exe is located
7) Select Debug -> Start debugging (or press F5)
8) Press F9 or click the bar on the left side of the source view to add/remove a breakpoint on the current source line


Tips:
- In case you'd like to debug a lua file before it's been loaded by the game (and auto-added to Project Explorer), drag and drop the file to Project explorer, open the file and set breakpoints where needed, then press F5 to start debugging.
- Adding _G to the Watch window allows you to watch the entire state of a lua context.
- Please note that Noita runs lua scripts inside multiple lua contexts.


Using luacheck to statically check lua scripts
---
1) Get a copy of luacheck.exe (https://github.com/luarocks/luacheck) and place it into Noita/tools_modding. A precompiled 64-bit binary can be found here: https://github.com/mpeterv/luacheck/releases/download/0.23.0/luacheck.exe
2) Open a command line and set your working directory to Noita/tools_modding
3) Run luacheck_all
```

For more debugging assistance check out [Noita Modding: Basics - Debugging](https://noita.wiki.gg/wiki/Modding:_Basics#Debugging).
