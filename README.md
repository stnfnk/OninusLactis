# Oninus Lactis

A simple framework for lactating/nipple squirt visual effects. Supports individual player and NPC effect offset and scaling.

Rebuilt for Dripping When Aroused NG by stnfnk 2025 - [Original mod page](https://www.nexusmods.com/skyrimspecialedition/mods/54017)

## Requirements
+ Skyrim: Special Edition (1.5.39+) or VR
+ [SKSE64](https://skse.silverlock.org/)
+ [PapyrusUtil SE v3.9+](https://www.nexusmods.com/skyrimspecialedition/mods/13048?tab=files) 
+ [CBBE 3BA (3BBB)](https://www.nexusmods.com/skyrimspecialedition/mods/30174) optional
+ [XPMSSE](https://www.nexusmods.com/skyrimspecialedition/mods/1988?tab=files)

## Features

### General
+ Rebuilt to integrate with Dripping When Aroused NG
+ Customizable player and NPC nipple squirt offset and scaling.
+ (Optional) CBBE nipple leak overlay. UNP-B replacement included.
+ For mod authors: Public API to integrate the effect into other mods.

### Standalone mode
+ Press "K" with no NPC under the crosshair to toggle the effect on/off for the player.
+ Press "K" key to toggle the effect on/off for any female NPC under the crosshair. Supports up to 20 NPCs (including the player).

## Installation
Install with your favorite mod manager (developed and tested with MO2).

## Deinstallation
Click the uninstall option in the MCM menu. This will stop all running effects and delete all stored actor settings and prepare the mod for deinstallation. 

After clicking the option you need to exit MCM, then save and exit the game. Deactivate the Lactis mod and restart the game again. Load your save, play for a little while, change cell, save and exit game again.

When using standalone mode (key K) on various NPCs, don't save or travel. Leaving cells and saving/reloading save games may cause issues with save game bloat.

## MCM settings export
The MCM setting can be exported to and imported from a file. Choose the option "Export MCM settings" in the MCM menu and find the file in your Data folder at 'SKSE/Plugins/Lactis/MCM_Settings.json'.

Choose "Import MCM settings" to import from the file at the location mentioned above.

Note that NPC offsets are NOT exported for now. This feature will be added in a future release.

## Physics
Developed and works best with CBPC. With SMP nipple offset is somewhat off/delayed.

## Technical details
This mod was developed using XPMSSE and the 3BA body. It was tested by a BHUNP user who confirmed that this works, too.

## Known issues
+ Particles look weird from some angles.
+ When using SMP nipple offset is somehow delayed (CBPC works better)
+ During OStim scenes: Flickering face effects when using face lights. Affects player and NPCs.

## MCM configuration
Use MCM to configure nipple offset and scale for the player and NPCs. You can enable a debug axis to make this step easier. Use other parameters to adjust effect if desired.

The standalone nipple squirt effect can be toggled on/off via the key "K" (can be configured via MCM). This works for up to 20 NPCS and the player actor. The effect can be toggled on/off at any time even when your character or the NPC is not naked.

### Settings page
+ Toggle nipple squirt key - remaps toggle nipples squirting on a target actor or the player.
+ Player Nipple Offset - Player offset for the nipple squirt emitter origin. Adjust to match the player's body.
+ Enable nipple squirt even when actor is not naked. This might help with revealing armors/clothing.
+ Enable nipple leak (CBBE EffectShader) overlay texture which simulates nipple leak. A UNP-B replacement texture is also included.
+ Enable debug axis for nipple offset adjustments. Applies to player and NPCs.
+ Global emitter scale for left and right emitters. Applies to player and NPCs.

### Actor offsets page
+ Select actor under crosshair or from *Stored Actor Offset*
+ Configure the offset and scale, all changes are automatically saved. You have to exit MCM and re-toggle the effect to have the new values applied.

## Thanks & asset contributors
Thanks to Orbus Ninus for the original mod. Uses some textures textures from https://www.loverslab.com/topic/98782-sexlab-hentai-pregnancy-special-edition/ with permission.
