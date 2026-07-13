# GothicMacros
An AutoHotkey 2 script that brings quality-of-life features to the classic version of _Gothic 1_.

## Installation

You can run the script anywhere at any time, as long as `GothicMacros.ini` is in the same directory. All keys are configurable in the config file. Setting the optional keys to blank disables them.

Make sure your hotkeys are the same than the ones in-game (otherwise they won't work and unexpected behavior may occur).

If the game is run as admin, you must also run the script as admin for hotkeys to work.

## Usage

It supports the following macros, that are only active when the game's window is active. They're automatically disabled when alt-tabbing or bringing up the Steam overlay, and stopped when pressing `Quick Load` or `Escape`.

- **autobuy (toggle)**: holds `Action` and spams `LButton` to allow you to buy items faster. It can also be used to sell items faster and use consumables. The clicking frequency is customizable through `iAutobuyClickFrequency` and it can buy stacks of 100 items using `bAutobuyStacks`. Automatically disabled when pressing `Escape`, `LButton` or `RButton` (if not remapped).
- **autocook (toggle)**: your character can only cook one meat at a time, so you can start the macro and come back later. You need to make sure you're looking at a fireplace/pan and within range beforehand.
- **autojump (toggle)**: combine it with autorun to cover long distances faster without having to hold any key. Works best on flat ground and upward slopes, preferably with a weapon drawn (once you learn Acrobatics). The jumping frequency is customizable through `iAutojumpFrequency`. Automatically disabled when pressing `Jump`.
- **autorun (toggle)**: self-explanatory. Automatically disabled when pressing `Forward`. **Shouldn't be used underwater**.
- **autoswim (toggle)**: self-explanatory. Controls can be inverted using `bInvertControlsWhenAutoswimming`. Automatically disabled when pressing `Jump`. **Should only be used underwater**.
- **fast attack (hold)**: holds the `Action` + `Backward` + `Forward` keys to let you attack the fastest way possible, therefore maximizing your DPS. You need to make sure your weapon is drawn beforehand. The drawback is you can't parry while doing it, so use it sparingly.
- **first person (toggle)**: self-explanatory. Must be the same as the in-game `Look around first person` key.
- **loot (hold)**: periodically taps the `Action` key until released, therefore allowing you to pick up multiple items next to each other.
- **marvin mode (toggle)**: allows you to enable/disable Marvin mode (aka cheats). In order to avoid triggering macros while typing in the console, the script can be suspended when enabling Marvin mode with `bSuspendDuringMarvinMode`.
- **smith (hold)**: taps the `Action` key then periodically taps `Backward`. Hold it until you notice the current smithing animation gets cancelled. You need to make sure you're using the smithing objects in the right order, looking at one of them and within range beforehand.
- **sneak (hold)**: turns the `Sneak` key into a hold key. It basically taps the key on press then taps it again on release. If you don't hold the key long enough (~500ms), you can use `bWaitForSneakAnimation` to delay the actual release (it can get a bit buggy though, be gentle with it). Must be the same as the in-game `Sneak` key.
- **walk (toggle)**: there's already a hard-coded in-game walk toggle (`Caps Lock`) but this one is customizable. Must be the same as the in-game `Run` key.

Moreover, all mouse buttons can be remapped to other keys (except right-click which requires [G1NoRMBJump](https://steamcommunity.com/sharedfiles/filedetails/?id=3210234170) in order to be remapped).

## Default hotkeys (see [KeyList](https://www.autohotkey.com/docs/v2/KeyList.htm))

- `e`: toggle first-person mode  
- `f`: action  
- `k`: toggle autobuy  
- `l`: toggle autocook  
- `s`: backward  
- `w`: forward  
- `x`: toggle autoswim  
- `z`: player's status  
- `F1`: toggle autorun  
- `F2`: toggle autojump  
- `F3`: toggle Marvin mode  
- `F9`: quick load  
- `LShift`: toggle walk  
- `ScrollLock`: toggle Steam overlay  
- `Space`: jump  
- `MButton`: fast attack  
- `XButton1`: loot  
- `XButton2`: smith  

## Hard-coded hotkeys

- `Escape`: stops and resets all macros
- `LButton`, `RButton`, `Shift + LButton`: stops and resets the autobuy macro
- `LCtrl + LAlt + F10`: closes the script  
- `LCtrl + LAlt + F11`: reloads the script  
- `LCtrl + LAlt + F12`: suspends/unsuspends the script (stops and resets all macros, disables all hotkeys)

## Useful in-game hotkeys

- `Caps Lock`: toggle walk  
- `Ctrl + Alt + F8`: unstick your character  
- `Shift + Escape`: force open the menu, useful in some rare cases where controls don't respond (can be set as default behavior of `Escape` by using `bForceShiftEscape`)

## Limitations

- Hotkeys using modifiers (ex: `^k` aka `Ctrl + K`) may not work.
- Left-click and right-click have hardcoded behavior in some instances (for example, left-click acts as `Action` with a weapon drawn) that'll persist after remaps.
- Some macros (such as autobuy) don't work without `Gothic2_Control=1` in `SystemPack.ini`.
- The game must be in a clean state (Steam overlay hidden, character standing up, no menu open) before running the script, otherwise its internal states will not match the actual states in the game and it won't work properly.

## Credits

[CharnamelessOne](https://www.reddit.com/user/CharnamelessOne): alternative to `KeyWait`  
[xxx_420_blaze_it_69_xxx](https://www.twitch.tv/xxx_420_blaze_it_69_xxx): info about useful in-game hotkeys

## Disclaimer

I won't be held responsible for unexpected behavior such as loss of items. Use at your own risk!
