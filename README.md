```lua
local global = getgenv() or shared or _G
if not global then error("Failed to get global env.") end

-- Get your key from the Discord server.
global.infilsenseKey = 'YOUR KEY HERE'
loadstring(game:HttpGet('https://raw.githubusercontent.com/bkkpro1980/InfilSense-Loader/refs/heads/main/loader.lua'))()
```
