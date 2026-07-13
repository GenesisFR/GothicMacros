#Requires AutoHotkey v2.0
#SingleInstance

class AnimationStates
{
	static SNEAK_ANIM_DURATION_STILL := 500
	static SNEAK_ANIM_DURATION_MOVING := 200
	static iSneakTimePressed := 0

	static GetSneakAnimDuration()
	{
		; The transition between standing up and sneaking is shorter when moving forward
		return GetKeyState(g_sForwardKey) ? AnimationStates.SNEAK_ANIM_DURATION_MOVING : AnimationStates.SNEAK_ANIM_DURATION_STILL
	}
}

class HoldStates
{
	static bFastAttacking := 0
	static bLooting       := 0
	static bMarvinning    := 0
	static bSmithing      := 0
	static bSneaking      := 0
}

class ToggleStates
{
	static bAutobuy         := 0
	static bAutocook        := 0
	static bAutojump        := 0
	static bAutorun         := 0
	static bAutoswim        := 0
	static bFirstPersonMode := 0
	static bMarvinMode      := 0
	static bSteamOverlay    := 0
	static bWalk            := GetKeyState("CapsLock", "T")
}

Init()

Init()
{
	; Window group for Gothic
	GroupAdd("Gothic", "ahk_exe Gothic.exe")
	GroupAdd("Gothic", "ahk_exe GothicMod.exe")
	global g_sWindowTitle := "ahk_group Gothic"

	ReadConfigFile()
	RegisterHotkeys()

	; Set an event hook to detect when the game window loses focus
	DllCall("user32\SetWinEventHook",
			"Int", EVENT_SYSTEM_FOREGROUND := 0x0003,
			"Int", EVENT_SYSTEM_FOREGROUND,
			"Ptr", 0,
			"Ptr", CallbackCreate(OnFocusChanged, "F"),
			"Int", 0,
			"Int", 0,
			"Int", 0)

	OnExit((*) => ResetAll())
}

Cook(p_iStep := 1)
{
	switch p_iStep
	{
		; Stop cooking
		case 0:
			Send("{" g_sActionKey " up}{" g_sBackwardKey " up}")
			SetTimer(Cook, 0)
		; Start cooking then finish once the meat is in the pan
		case 1:
			Send("{" g_sActionKey " down}{" g_sBackwardKey " down}")
			SetTimer(Cook.Bind(2), ToggleStates.bAutocook * -2000)
		; Finish cooking then start again once your character stands up
		case 2:
			Send("{" g_sActionKey " up}{" g_sBackwardKey " up}")
			SetTimer(Cook, ToggleStates.bAutocook * -1200)
	}
}

Marvin(p_iStep := 1)
{
	switch p_iStep
	{
		; Open the player status menu
		case 1:
			TapKey(g_sPlayerStatusKey)
			SetTimer(Marvin.Bind(2), -100 * HoldStates.bMarvinning ^= 1)
		; Toggle Marvin mode
		case 2:
			Send(ToggleStates.bMarvinMode ? "marvin" : "42")
			SetTimer(Marvin.Bind(3), -100 * HoldStates.bMarvinning)
		; Close the player status menu
		case 3:
			TapKey(g_sPlayerStatusKey)
			SetTimer(Marvin.Bind(4), -100 * HoldStates.bMarvinning)
		; Allow Marvin mode to be toggled again
		case 4:
			SetTimer(Marvin, HoldStates.bMarvinning := 0)
	}
}

; Continously fast attack, use it preferably on enemies you can't parry (you must have your weapon pulled out beforehand)
OnFastAttackPress(*)
{
	HoldStates.bFastAttacking := 1
	Send("{" g_sActionKey " down}{" g_sBackwardKey " down}{" g_sForwardKey " down}")
}

OnFastAttackRelease(*)
{
	HoldStates.bFastAttacking := 0
	Send("{" g_sActionKey " up}{" g_sBackwardKey " up}{" g_sForwardKey " up}")
}

OnFocusChanged(*)
{
	if WinActive(g_sWindowTitle)
	{
		WinWaitNotActive(g_sWindowTitle)
		ResetAll()
	}
}

; Turn off autojump
OnJumpPress(*)
{
	SetTimer(TapJump, ToggleStates.bAutojump := ToggleStates.bAutoswim := 0)
}

OnLootPress(*)
{
	TapKey(g_sActionKey)
	SetTimer(TapAction, 200 * HoldStates.bLooting := 1)
}

OnLootRelease(*)
{
	SetTimer(TapAction, HoldStates.bLooting := 0)
}

; Tap the Action key then spam Backward until the Smithing key is released
OnSmithPress(*)
{
	TapKey(g_sActionKey)
	SetTimer(TapBackward, 200 * HoldStates.bSmithing := 1)
}

OnSmithRelease(*)
{
	SetTimer(TapBackward, HoldStates.bSmithing := 0)
}

OnSneakOffAnimComplete()
{
	Output(A_ThisFunc)
	HoldStates.bSneaking := 0
}

OnSneakPress(*)
{
	Output(A_ThisFunc)
	HoldStates.bSneaking := 1
	AnimationStates.iSneakTimePressed := A_TickCount
}

OnSneakRelease(*)
{
	l_nTimeSinceSneakPress := A_TickCount - AnimationStates.iSneakTimePressed
	Output(A_ThisFunc "::l_nTimeSinceSneakPress: " l_nTimeSinceSneakPress)

	; If the key was held for longer than the minimum delay, toggle sneak off immediately, otherwise wait until the minimum delay has passed
	if (l_nTimeSinceSneakPress > AnimationStates.GetSneakAnimDuration())
		ToggleSneakOff()
	else
	{
		Output(A_ThisFunc "::released too early!")

		if (g_bWaitForSneakAnimation)
		{
			l_iSneakOffDelay := AnimationStates.GetSneakAnimDuration() - l_nTimeSinceSneakPress
			Output(A_ThisFunc "::delaying sneak tap by " l_iSneakOffDelay "ms")
			SetTimer(ToggleSneakOff, -l_iSneakOffDelay)
		}
	}
}

Output(p_sMsg := "")
{
	OutputDebug(p_sMsg "`n")
}

ReadConfigFile()
{
	global

	local l_sConfigFile := "GothicMacros.ini"

	; General
	g_bAutobuyStacks                  := IniRead(l_sConfigFile, "General", "bAutobuyStacks", false) == true
	g_bBeepOnSuspend                  := IniRead(l_sConfigFile, "General", "bBeepOnSuspend", true) == true
	g_bForceShiftEscape               := IniRead(l_sConfigFile, "General", "bForceShiftEscape", false) == true
	g_bInvertControlsWhenAutoswimming := IniRead(l_sConfigFile, "General", "bInvertControlsWhenAutoswimming", false) == true
	g_bSuspendDuringMarvinMode        := IniRead(l_sConfigFile, "General", "bSuspendDuringMarvinMode", true) == true
	g_bWaitForSneakAnimation          := IniRead(l_sConfigFile, "General", "bWaitForSneakAnimation", false) == true

	if !IsInteger(g_iAutobuyClickFrequency := IniRead(l_sConfigFile, "General", "iAutobuyClickFrequency", 100))
		g_iAutobuyClickFrequency := 100
	if !IsInteger(g_iAutojumpFrequency := IniRead(l_sConfigFile, "General", "iAutojumpFrequency", 300))
		g_iAutojumpFrequency := 300

	; Mandatory keys
	g_sActionKey                := IniRead(l_sConfigFile, "MandatoryKeys", "sActionKey", "f")
	g_sBackwardKey              := IniRead(l_sConfigFile, "MandatoryKeys", "sBackwardKey", "s")
	g_sForwardKey               := IniRead(l_sConfigFile, "MandatoryKeys", "sForwardKey", "w")
	g_sJumpKey                  := IniRead(l_sConfigFile, "MandatoryKeys", "sJumpKey", "Space")
	g_sPlayerStatusKey          := IniRead(l_sConfigFile, "MandatoryKeys", "sPlayerStatusKey", "z")
	g_sQuickLoadKey             := IniRead(l_sConfigFile, "MandatoryKeys", "sQuickLoadKey", "F9")
	g_sSteamOverlayKey          := IniRead(l_sConfigFile, "MandatoryKeys", "sSteamOverlayKey", "ScrollLock")

	; Optional keys
	g_sFastAttackKey            := IniRead(l_sConfigFile, "OptionalKeys", "sFastAttackKey", "")
	g_sLootKey                  := IniRead(l_sConfigFile, "OptionalKeys", "sLootKey", "")
	g_sSmithKey                 := IniRead(l_sConfigFile, "OptionalKeys", "sSmithKey", "")
	g_sSneakKey                 := IniRead(l_sConfigFile, "OptionalKeys", "sSneakKey", "")
	g_sToggleAutobuyKey         := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutobuyKey", "")
	g_sToggleAutocookKey        := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutocookKey", "")
	g_sToggleAutojumpKey        := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutojumpKey", "")
	g_sToggleAutorunKey         := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutorunKey", "")
	g_sToggleAutoswimKey        := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutoswimKey", "")
	g_sToggleFirstPersonModeKey := IniRead(l_sConfigFile, "OptionalKeys", "sToggleFirstPersonModeKey", "")
	g_sToggleMarvinModeKey      := IniRead(l_sConfigFile, "OptionalKeys", "sToggleMarvinModeKey", "")
	g_sToggleWalkKey            := IniRead(l_sConfigFile, "OptionalKeys", "sToggleWalkKey", "")

	; Remappable keys
	g_sLeftClickKey             := IniRead(l_sConfigFile, "RemappableKeys", "sLeftClickKey", "")
	g_sMiddleClickKey           := IniRead(l_sConfigFile, "RemappableKeys", "sMiddleClickKey", "")
	g_sRightClickKey            := IniRead(l_sConfigFile, "RemappableKeys", "sRightClickKey", "")
	g_sXButton1Key              := IniRead(l_sConfigFile, "RemappableKeys", "sXButton1Key", "")
	g_sXButton2Key              := IniRead(l_sConfigFile, "RemappableKeys", "sXButton2Key", "")

	; Prevent some variables from being negative or set to 0, otherwise timers won't work
	g_iAutobuyClickFrequency := Max(g_iAutobuyClickFrequency, 1)
	g_iAutojumpFrequency     := Max(g_iAutojumpFrequency, 1)
}

RegisterHotkey(p_sPrefix, p_sHotkey, p_fnAction, p_bOnRelease := false, p_bSuspendExempt := false)
{
	; If the hotkey is empty, don't register it (allows keys like toggles to be optional)
	if (p_sHotkey)
		Hotkey(p_sPrefix p_sHotkey (p_bOnRelease ? " up" : ""), p_fnAction, p_bSuspendExempt ? "On S" : "On S0")
}

RegisterHotkeys()
{
	; Hotkeys fired only when Gothic is the active window
	HotIfWinActive(g_sWindowTitle)
		RegisterHotkey("*", g_sSteamOverlayKey, ToggleSteamOverlay, true, true)
	HotIfWinActive()

	; Hotkeys fired only when Gothic is the active window, the key isn't being held and the Steam overlay is not in the foreground
	HotIf((*) => WinActive(g_sWindowTitle) && !HoldStates.bFastAttacking && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sFastAttackKey, OnFastAttackPress)
	HotIf((*) => WinActive(g_sWindowTitle) && ToggleStates.bAutoswim && g_bInvertControlsWhenAutoswimming && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*", g_sBackwardKey, (*) => Send("{" g_sForwardKey " down}"))
		RegisterHotkey("*", g_sBackwardKey, (*) => Send("{" g_sForwardKey " up}"), true)
		RegisterHotkey("*", g_sForwardKey, (*) => Send("{" g_sBackwardKey " down}"))
		RegisterHotkey("*", g_sForwardKey, (*) => Send("{" g_sBackwardKey " up}"), true)
	HotIf((*) => WinActive(g_sWindowTitle) && !HoldStates.bLooting && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sLootKey, OnLootPress)
	HotIf((*) => WinActive(g_sWindowTitle) && !HoldStates.bSmithing && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sSmithKey, OnSmithPress)
	HotIf((*) => WinActive(g_sWindowTitle) && !HoldStates.bSneaking && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sSneakKey, OnSneakPress)
	HotIf((*) => WinActive(g_sWindowTitle) && HoldStates.bSneaking && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sSneakKey, OnSneakRelease, true)
	HotIf((*) => WinActive(g_sWindowTitle) && !HoldStates.bMarvinning && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sToggleMarvinModeKey, ToggleMarvinMode, true, true)

	; Hotkeys fired only when Gothic is the active window and the Steam overlay is not in the foreground
	HotIf((*) => WinActive(g_sWindowTitle) && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sFastAttackKey, OnFastAttackRelease, true)
		RegisterHotkey("*~", g_sForwardKey, (*) => ToggleStates.bAutorun := 0)
		RegisterHotkey("*~", g_sJumpKey, OnJumpPress)
		RegisterHotkey("*~", g_sLootKey, OnLootRelease, true)
		RegisterHotkey("*~", g_sQuickLoadKey, (*) => ResetAll())
		RegisterHotkey("*~", g_sSmithKey, OnSmithRelease, true)
		RegisterHotkey("*~", g_sToggleAutobuyKey, ToggleAutobuy, true)
		RegisterHotkey("*~", g_sToggleAutocookKey, ToggleAutocook, true)
		RegisterHotkey("*~", g_sToggleAutojumpKey, ToggleAutojump, true)
		RegisterHotkey("*~", g_sToggleAutorunKey, ToggleAutorun, true)
		RegisterHotkey("*~", g_sToggleAutoswimKey, ToggleAutoswim, true)
		RegisterHotkey("*~", g_sToggleFirstPersonModeKey, ToggleFirstPersonMode, true)
		RegisterHotkey("*~", g_sToggleWalkKey, ToggleWalk, true)
	HotIf()
}

ResetAll(p_bToggleOffCapsLock := true)
{
	; Delete timers
	for l_fnTimer in [Cook, Marvin, OnSneakOffAnimComplete, TapAction, TapBackward, TapJump, TapLeftMouseButton, ToggleSneakOff]
		SetTimer(l_fnTimer, 0)

	; Release keys
	for l_sKey in ["LAlt", "LButton", "LCtrl", "LShift", g_sActionKey, g_sBackwardKey, g_sFastAttackKey, g_sForwardKey, g_sJumpKey, g_sSneakKey]
		Send("{Blind}{" l_sKey " up}")

	; Reset states
	AnimationStates.iSneakTimePressed := 0
	HoldStates.bFastAttacking := HoldStates.bMarvinning := HoldStates.bSmithing := HoldStates.bSneaking := 0
	ToggleStates.bAutobuy := ToggleStates.bAutocook := ToggleStates.bAutojump := ToggleStates.bAutorun := ToggleStates.bAutoswim := ToggleStates.bFirstPersonMode := 0

	; Reset Walk toggle
	if (p_bToggleOffCapsLock)
		SetCapsLockState(ToggleStates.bWalk := 0)
}

TapAction()
{
	TapKey(g_sActionKey)
}

TapBackward()
{
	TapKey(g_sBackwardKey)
}

TapJump()
{
	TapKey(g_sJumpKey)
}

TapKey(p_sKey)
{
	Send("{Blind}{" p_sKey " down}")
	SetTimer(() => Send("{Blind}{" p_sKey " up}"), -25)
}

TapLeftMouseButton()
{
	TapKey("LButton")
}

; Buy/Sell/Use in bulk (highlight the desired item beforehand)
ToggleAutobuy(*)
{
	if (g_bAutobuyStacks)
		Send((ToggleStates.bAutobuy ^= 1) ? "{LShift down}" : "{LShift up}")
	else
		Send((ToggleStates.bAutobuy ^= 1) ? "{" g_sActionKey " down}" :  "{" g_sActionKey " up}")

	; Spam left-click to buy/sell/use items faster
	SetTimer(TapLeftMouseButton, g_iAutobuyClickFrequency * ToggleStates.bAutobuy)
}

; Autocook (you must be looking at a fireplace/pan and be within range beforehand)
ToggleAutocook(*)
{
	Cook(ToggleStates.bAutocook ^= 1)
}

; Autojump (works best on flat ground and upward slopes)
ToggleAutojump(*)
{
	ToggleStates.bAutojump ^= 1
	TapJump()

	; Continuously spam jump, should be combined with autorun
	SetTimer(TapJump, g_iAutojumpFrequency * ToggleStates.bAutojump)
}

; Autorun (shouldn't be used underwater)
ToggleAutorun(*)
{
	Send("{" g_sForwardKey ((ToggleStates.bAutorun ^= 1) ? " down}" : " up}"))
}

; Autoswim (should only be used underwater)
ToggleAutoswim(*)
{
	Send("{" g_sJumpKey ((ToggleStates.bAutoswim ^= 1) ? " down}" : " up}"))
}

ToggleFirstPersonMode(*)
{
	Send("{" g_sToggleFirstPersonModeKey ((ToggleStates.bFirstPersonMode ^= 1) ? " down}" : " up}"))
}

ToggleMarvinMode(*)
{
	Output("Marvin mode toggled " ((ToggleStates.bMarvinMode ^= 1) ? "on" : "off"))
	ResetAll()
	Marvin()

	if (g_bSuspendDuringMarvinMode)
		Suspend(ToggleStates.bMarvinMode)
}

ToggleSneakOff()
{
	Output(A_ThisFunc)
	TapKey(g_sSneakKey)

	; Wait until the animation is over before allowing the Sneak key to be pressed again
	SetTimer(OnSneakOffAnimComplete, -AnimationStates.GetSneakAnimDuration())
}

ToggleSteamOverlay(*)
{
	if (!HoldStates.bMarvinning)
	{
		Output("Steam overlay toggled " ((ToggleStates.bSteamOverlay ^= 1) ? "on" : "off"))
		ResetAll()
		TapKey(g_sSteamOverlayKey)
	}
}

ToggleWalk(*)
{
	; Sync CapsLock with the Walk toggle state
	SetCapsLockState(ToggleStates.bWalk ^= 1)
}

; When doing Shift + left-click to buy stacks of 100 items
#HotIf WinActive(g_sWindowTitle) && g_sToggleWalkKey && !ToggleStates.bSteamOverlay
<+LButton::
{
	if (ToggleStates.bAutobuy)
		ToggleAutobuy()

	; Pressing LShift may toggle walk so we need to restore CapsLock to its previous value after LShift is released
	l_bPrevCapsLockState := GetKeyState("CapsLock", "T")
	KeyWait("LShift")
	SetCapsLockState(l_bPrevCapsLockState)
}

; Left-click remap
#HotIf WinActive(g_sWindowTitle) && g_sLeftClickKey && !ToggleStates.bSteamOverlay
*$LButton::Send("{" g_sLeftClickKey " down}")
*$LButton up::Send("{" g_sLeftClickKey " up}")

; Middle-click remap
#HotIf WinActive(g_sWindowTitle) && g_sMiddleClickKey && !ToggleStates.bSteamOverlay
*$MButton::Send("{" g_sMiddleClickKey " down}")
*$MButton up::Send("{" g_sMiddleClickKey " up}")

; Right-click remap
#HotIf WinActive(g_sWindowTitle) && g_sRightClickKey && !ToggleStates.bSteamOverlay
*$RButton::Send("{" g_sRightClickKey " down}")
*$RButton up::Send("{" g_sRightClickKey " up}")

; XButton1 remap
#HotIf WinActive(g_sWindowTitle) && g_sXButton1Key && !ToggleStates.bSteamOverlay
*$XButton1::Send("{" g_sXButton1Key " down}")
*$XButton1 up::Send("{" g_sXButton1Key " up}")

; XButton2 remap
#HotIf WinActive(g_sWindowTitle) && g_sXButton2Key && !ToggleStates.bSteamOverlay
*$XButton2::Send("{" g_sXButton2Key " down}")
*$XButton2 up::Send("{" g_sXButton2Key " up}")

#HotIf WinActive(g_sWindowTitle) && !GetKeyState("Escape", "P") && !ToggleStates.bSteamOverlay
*$Escape::
{
	ResetAll(false)
	Send((g_bForceShiftEscape ? "+" : "") "{Escape}")
}

#HotIf WinActive(g_sWindowTitle) && !ToggleStates.bSteamOverlay
*~LButton::
*~RButton::
{
	if (ToggleStates.bAutobuy)
		ToggleAutobuy()
}

#SuspendExempt
; Automatically reload the script after saving in VSCode (skipped in the compiled script)
;@Ahk2Exe-IgnoreBegin
#HotIf WinActive("Visual Studio Code") && InStr(WinGetTitle("A"), A_ScriptName)
~^s::Send("^+{F5}")
;@Ahk2Exe-IgnoreEnd

; Escape can also be used to close the Steam overlay
#HotIf WinActive(g_sWindowTitle) && ToggleStates.bSteamOverlay
*~Escape::
{
	Output("Steam overlay toggled off")
	ToggleStates.bSteamOverlay := 0
}
#HotIf

; Sync the Walk toggle state with CapsLock
~CapsLock up::ToggleStates.bWalk := GetKeyState("CapsLock", "T")

; Exit script (CTRL + ALT + F10)
*~^!F10::ExitApp()

; Reload script (CTRL + ALT + F11)
*~^!F11::Reload()

; Suspend script, useful in menus (CTRL + ALT + F12)
*~^!F12::
{
	Suspend()

	; Manually suspending the script should force exempted hotkeys to also be suspended
	HotIfWinActive(g_sWindowTitle)
		RegisterHotkey("*", g_sSteamOverlayKey, ToggleSteamOverlay, true, !A_IsSuspended)
	HotIfWinActive()

	HotIf((*) => WinActive(g_sWindowTitle) && !HoldStates.bMarvinning && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sToggleMarvinModeKey, ToggleMarvinMode, true, !A_IsSuspended)
	HotIf()

	; Single beep when suspended
	if (g_bBeepOnSuspend)
		SoundBeep(1000, 100)

	if (A_IsSuspended)
		ResetAll()
	; Double beep when resumed
	else
	{
		if (g_bBeepOnSuspend)
			SoundBeep(1000, 100)
	}
}
#SuspendExempt False