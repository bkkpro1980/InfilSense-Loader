```lua
local global = getgenv() or shared or _G
if not global then error("Failed to get global env.") end

-- Get your key from the Discord server.
global.infilsenseKey = 'YOUR KEY HERE'
loadstring(game:HttpGet('https://raw.githubusercontent.com/bkkpro1980/InfilSense-Loader/refs/heads/main/loader.lua'))()
```

Source codes are private due to privacy and security reasons.
Contact me on Discord via the community server or DM @bkkpro1980 if you have any concerns or questions.

## License

This project is licensed under the **Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)** Public License.

[![License: CC BY-NC-ND 4.0](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-purple.svg)](https://creativecommons.org/licenses/by-nc-nd/4.0/)

By using, downloading, or interacting with this repository, you agree to the following terms:
*   **Attribution (BY):** You must give appropriate credit to the original creator and provide a link to this license.
*   **Non-Commercial (NC):** You may not use this material or any part of this software for commercial purposes or financial gain.
*   **No Derivatives (ND):** If you remix, transform, alter, or build upon this material, **you may not distribute the modified material.**

> **Notice to Crackers & Leakers:** Modifying this script to bypass authentication, stripping its key systems, or re-hosting modified versions (derivative works) constitutes an immediate and automatic termination of your right to use this software under Section 6 of the CC Public License, and is a direct violation of copyright law.
