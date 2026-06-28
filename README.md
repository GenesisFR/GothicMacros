# GothicMacros
An AutoHotkey 2 script that brings quality-of-life features to the classic version of _Gothic 1_.

## Installation

You can run the script anywhere at any time, as long as `GothicMacros.ini` is in the same directory. All keys are configurable in the config file. Setting the optional keys to blank disables them.

Make sure your hotkeys are the same than the ones in-game (otherwise they won't work and unexpected behavior may occur).

If the game is run as admin, you must also run the script as admin for hotkeys to work.

## Usage

It features the following macros that are only active when the game's window is active" They're automatically disabled when alt-tabbing or bringing up the Steam overlay, and stopped when pressing `Quick Load` or `Escape`.

- **autobuy (toggle)**: holds `Shift + Action` and spams `LButton` to allow you to buy stacks of 100 items faster. It can also be used to sell items faster and use consumables. The clicking frequency is customizable through `iAutobuyClickFrequency`. Automatically disabled when manually pressing `Escape`, `LButton`, `RButton` (if not remapped) or `Shift`.
- **autocook (toggle)**: your character can only cook one meat at a time, so you can start the macro and come back later. You need to make sure you're looking at a fireplace/pan and within range beforehand.
- **autojump (toggle)**: combine it with autorun to cover long distances faster without having to hold any key. Drawing your weapon while going up makes it even more effective. The jumping frequency is customizable through `iAutojumpFrequency`. Automatically disabled when manually pressing `Jump`.
- **autorun (toggle)**: self-explanatory. Automatically disabled when manually pressing `Forward`. Works best on flat ground and upward slopes with a weapon drawn. **Shouldn't be used underwater**.
- **autoswim (toggle)**: self-explanatory. Automatically disabled when manually pressing `Jump`. **Should only be used underwater**.
- **fast attack (hold)**: holds the `Action` + `Backward` + `Forward` to let you attack the fastest way possible, therefore maximizing your DPS. You need to make sure your weapon is drawn beforehand. The drawback is you can't parry while doing it, so use it sparingly.
- **first person (toggle)**: self-explanatory. Must be the same as the in-game `Look around first person` key.
- **smith (hold)**: taps the `Action` key then spams `Backward`. Hold it until you notice the current smithing animation gets cancelled. You need to make sure you're using the smithing objects in the right order, looking at one of them and within range beforehand.
- **walk (toggle)**: there's already a hard-coded in-game walk toggle (`Caps Lock`) but this one is customizable. Must be the same as the in-game `Walk` key.

Moreover, right-click can be remapped to another key through `sRightClickKey` but requires [G1NoRMBJump](https://steamcommunity.com/sharedfiles/filedetails/?id=3210234170) in order to work.

## Default hotkeys (see [KeyList](https://www.autohotkey.com/docs/v2/KeyList.htm))

- `e`: toggle first-person mode  
- `f`: action  
- `k`: toggle autobuy  
- `l`: toggle autocook  
- `s`: move backward  
- `w`: move forward  
- `x`: toggle autoswim  
- `F1`: toggle autorun  
- `F2`: toggle autojump  
- `F9`: quick load  
- `ScrollLock`: toggle Steam overlay  
- `Shift`: toggle walk  
- `Space`: jump  
- `MButton`: fast attack  
- `XButton2`: smith  

## Hard-coded hotkeys

- `Escape`: stops and resets all macros
- `LButton`, `RButton`, `Shift`: stops and resets the autobuy macro
- `Left ALT + F10`: closes the script  
- `Left ALT + F11`: reloads the script  
- `Left ALT + F12`: suspends/unsuspends the script (stops and resets all macros, disables all hotkeys)

## Useful in-game hotkeys

- `Caps Lock`: toggle walk  
- `Ctrl + Alt + F8`: unstick your character  
- `Shift + Escape`: force open the menu

## Limitations

- Hotkeys using modifiers (ex: `Ctrl + K`) may not work.
- Some macros (such as autobuy) don't work without `Gothic2_Control=1` in `SystemPack.ini`.
- The Steam overlay must not be visible before running the script otherwise its internal state in the script will be desynced and hotkeys won't work when it's hidden.

## Credits

[CharnamelessOne](https://www.reddit.com/user/CharnamelessOne): alternative to `KeyWait`  
[xxx_420_blaze_it_69_xxx](https://www.twitch.tv/xxx_420_blaze_it_69_xxx): info about useful in-game hotkeys

## Disclaimer

I won't be held responsible for unexpected behavior such as loss of items. Use at your own risk!
