# Astral Redo

Detailed Overview
Astral Redo is a remake of the original astral mod. It replaces standard Minetest sky behavior with a dynamic system that tracks lunar cycles, solar events, and atmospheric conditions.

Core Features
- Lunar Cycles: Tracks 8 distinct moon phases with unique textures.
- Solar Events: Includes the rainbow sun, ring of fire, crescent sun, and solar eclipse.
- Lunar Events: Includes the blood moons, pink moon, blue moon, harvest moon, golden moon, super moon, eerie moon, and black moon.
- Cloud Density: Re-implemented cloud density controls for newer Luanti versions. (something disabled in the original astral mod)
- Interactive Calendars: Lunar and Solar calendars that show current or upcoming events.

Installation
1. Download the mod.
2. Extract the archive.
3. Ensure the folder is named astral_redo.
4. Move the folder to your Minetest mods directory.
5. Enable the mod in your world configuration.

Usage
Calendars
- Left Click (Use): Toggles between Current Event and Next Special Event.
- Texture Update: The item texture in your inventory changes to match the selected mode.
- Inventory Hover: The item description updates to show exactly how many days remain until the next event.

Calendar Nodes
- Placement: Place on any wall or surface.
- Interaction: Right-click the placed node to toggle its display mode.

Technical Information
- Day Offset: Randomized per-world to ensure different worlds have different event schedules.
- Light Ratios: Modifies day-night light levels during different events
- Mod Storage: Saves the day offset to ensure schedule consistency across restarts.
