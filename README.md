"Framework" for loading cycript/javascript into processes. 

Has full capabilities of cycript. 
Features filter list like Substrate: Bundles, Executables, and Classes
Also features an Enabled key: globally enable/disable the cycript

__core.cy contains some ease-of-use functions from the iphonedevwiki and pre-loads Substrate.
Comes with an example "tweak", FolderBadgeKiller, that is disabled by default (flip the 0 to a 1 in the FolderBadgeKiller.plist)


HOW TO: 
1. Create your cycript file (look in __core.cy for some functions you *don't* need to re-declare or import)
2. Create your filter (With the same name as the cycript file, but plist extension)
    2a. this is especially important if using the "include" function - don't hook the cycript executable or you will have an infinite loop of cycript loading and it won't start. 
3. Place them in /Library/MobileSubstrate/Scripts/ (you could package them in a deb for distribution)
4. Restart needed processes

TODO:
native include function
native framework loading function
easier hooking methods (%hook-syntax extension?)
easier function wrapping
load Lua (using LuaJit/LibFFI)