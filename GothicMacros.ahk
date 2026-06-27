#Requires AutoHotkey v2.0
#SingleInstance

class HoldStates
{
	static bSmithing      := 0
	static bFastAttacking := 0
}

class ToggleStates
{
	static bAutobuy      := 0
	static bAutocook     := 0
	static bAutojump     := 0
	static bAutorun      := 0
	static bAutoswim     := 0
	static bSteamOverlay := 0
	static bWalk         := 0
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

	OnExit((*) => ReleaseAllKeys())
}

CleanHotkey(p_sHotkey)
{
	return LTrim(RTrim(p_sHotkey, " up"), "~*$")
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
		ReleaseAllKeys()
	}
}

OnForwardPress(*)
{
	ToggleStates.bAutorun := 0
}

; Turn off autojump
OnJumpPress(*)
{
	SetTimer(SendJump, ToggleStates.bAutojump := 0)
}

OnQuickLoadPress(*)
{
	ReleaseAllKeys()
	KeyWait(g_sQuickLoadKey)
}

; Tap the Action key then spam Backward until the Smithing key is released
OnSmithPress(*)
{
	HoldStates.bSmithing := 1
	SendKey(g_sActionKey)
	SetTimer(SendBackward, 200)
}

OnSmithRelease(*)
{
	SetTimer(SendBackward, HoldStates.bSmithing := 0)
}

ReadConfigFile()
{
	global

	local l_sConfigFile := "GothicMacros.ini"

	; General
	g_bBeepOnSuspend := IniRead(l_sConfigFile, "General", "bBeepOnSuspend", true) == true
	if !IsInteger(g_iAutobuyClickFrequency := IniRead(l_sConfigFile, "General", "iAutobuyClickFrequency", 100))
		g_iAutobuyClickFrequency := 100

	; Mandatory Keys
	g_sActionKey         := IniRead(l_sConfigFile, "MandatoryKeys", "sActionKey", "f")
	g_sBackwardKey       := IniRead(l_sConfigFile, "MandatoryKeys", "sBackwardKey", "s")
	g_sForwardKey        := IniRead(l_sConfigFile, "MandatoryKeys", "sForwardKey", "w")
	g_sJumpKey           := IniRead(l_sConfigFile, "MandatoryKeys", "sJumpKey", "Space")
	g_sSteamOverlayKey   := IniRead(l_sConfigFile, "MandatoryKeys", "sSteamOverlayKey", "ScrollLock")

	; Optional Keys
	g_sFastAttackKey     := IniRead(l_sConfigFile, "OptionalKeys", "sFastAttackKey", "")
	g_sQuickLoadKey      := IniRead(l_sConfigFile, "OptionalKeys", "sQuickLoadKey", "")
	g_sRightClickKey     := IniRead(l_sConfigFile, "OptionalKeys", "sRightClickKey", "")
	g_sSmithKey          := IniRead(l_sConfigFile, "OptionalKeys", "sSmithKey", "")
	g_sToggleAutobuyKey  := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutobuyKey", "")
	g_sToggleAutocookKey := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutocookKey", "")
	g_sToggleAutojumpKey := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutojumpKey", "")
	g_sToggleAutorunKey  := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutorunKey", "")
	g_sToggleAutoswimKey := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutoswimKey", "")
	g_sToggleWalkKey     := IniRead(l_sConfigFile, "OptionalKeys", "sToggleWalkKey", "")

	; Prevent some variables from being negative or set to 0, otherwise timers won't work
	g_iAutobuyClickFrequency := Max(g_iAutobuyClickFrequency, 1)
}

RegisterHotkey(p_sPrefix, p_sHotkey, p_fnAction, p_sSuffix := "")
{
	; If the hotkey is empty, don't register it (allows keys like toggles to be optional)
	if (p_sHotkey)
		Hotkey(p_sPrefix p_sHotkey p_sSuffix, p_fnAction, "On")
}

RegisterHotkeys()
{
	; Hotkeys fired only when Gothic is the active window
	HotIfWinActive(g_sWindowTitle)
		RegisterHotkey("*", g_sSteamOverlayKey, ToggleSteamOverlay)
	HotIfWinActive()

	; Hotkeys fired only when Gothic is the active window, the key isn't being held and the Steam overlay is not in the foreground
	HotIf((*) => WinActive(g_sWindowTitle) && !HoldStates.bFastAttacking && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sFastAttackKey, OnFastAttackPress)
	HotIf((*) => WinActive(g_sWindowTitle) && !HoldStates.bSmithing && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sSmithKey, OnSmithPress)

	; Hotkeys fired only when Gothic is the active window and the Steam overlay is not in the foreground
	HotIf((*) => WinActive(g_sWindowTitle) && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sForwardKey, OnForwardPress)
		RegisterHotkey("*~", g_sJumpKey, OnJumpPress)
		RegisterHotkey("*~", g_sQuickLoadKey, OnQuickLoadPress)
		RegisterHotkey("*~", g_sFastAttackKey, OnFastAttackRelease, " up")
		RegisterHotkey("*~", g_sSmithKey, OnSmithRelease, " up")
		RegisterHotkey("*~", g_sToggleAutobuyKey, ToggleAutobuy, " up")
		RegisterHotkey("*~", g_sToggleAutocookKey, ToggleAutocook, " up")
		RegisterHotkey("*~", g_sToggleAutojumpKey, ToggleAutojump, " up")
		RegisterHotkey("*~", g_sToggleAutorunKey, ToggleAutorun, " up")
		RegisterHotkey("*~", g_sToggleAutoswimKey, ToggleAutoswim, " up")
		RegisterHotkey("*~", g_sToggleWalkKey, ToggleWalk, " up")
	HotIf()
}

ReleaseAllKeys()
{
	; Delete timers
	for l_fnTimer in [Cook, SendBackward, SendJump, SendLeftMouseButton]
		SetTimer(l_fnTimer, 0)

	; Release keys
	Send("{" g_sActionKey " up}{" g_sBackwardKey " up}{" g_sFastAttackKey " up}{" g_sForwardKey " up}{" g_sJumpKey " up}{LButton up}{Shift up}")

	; Reset states
	HoldStates.bFastAttacking := HoldStates.bSmithing := 0
	ToggleStates.bAutobuy := ToggleStates.bAutocook := ToggleStates.bAutojump := ToggleStates.bAutorun := ToggleStates.bAutoswim := ToggleStates.bWalk := 0
}

SendBackward()
{
	SendKey(g_sBackwardKey)
}

SendJump()
{
	SendKey(g_sJumpKey)
}

SendKey(p_sKey)
{
	Send("{" p_sKey " down}")
	Sleep(25)
	Send("{" p_sKey " up}")
}

SendLeftMouseButton()
{
	SendKey("LButton")
}

; Buy/Sell/Use in bulk (highlight the desired item beforehand)
ToggleAutobuy(*)
{
	Send((ToggleStates.bAutobuy ^= 1) ? "{Shift down}{" g_sActionKey " down}" : "{Shift up}{" g_sActionKey " up}")

	; Spam left-click to buy/sell/use items faster
	SetTimer(SendLeftMouseButton, ToggleStates.bAutobuy * g_iAutobuyClickFrequency)
}

; Autocook (you must be looking at a fireplace/pan and be within range beforehand)
ToggleAutocook(*)
{
	Cook(ToggleStates.bAutocook ^= 1)
}

ToggleAutojump(*)
{
	Send("{" g_sJumpKey ((ToggleStates.bAutojump ^= 1) ? "down}" : "up}"))

	; Continuously spam jump, should be combined with autorun
	SetTimer(SendJump, ToggleStates.bAutojump * 500)
}

ToggleAutorun(*)
{
	Send("{" g_sForwardKey ((ToggleStates.bAutorun ^= 1) ? " down}" : " up}"))
}

ToggleAutoswim(*)
{
	Send("{" g_sJumpKey ((ToggleStates.bAutoswim ^= 1) ? " down}" : " up}"))
}

ToggleSteamOverlay(*)
{
	ToggleStates.bSteamOverlay ^= 1
	ReleaseAllKeys()
	SendKey(g_sSteamOverlayKey)
	KeyWait(g_sSteamOverlayKey)
}

ToggleWalk(*)
{
	Send("{" g_sToggleWalkKey ((ToggleStates.bWalk ^= 1) ? " down}" : " up}"))
}

#HotIf WinActive(g_sWindowTitle) && g_sRightClickKey && !ToggleStates.bSteamOverlay
*RButton::
{
	if (ToggleStates.bAutobuy)
		ToggleAutobuy()

	Send("{" g_sRightClickKey " down}")
}
*RButton up::Send("{" g_sRightClickKey " up}")
#HotIf

*~Escape::
*~LButton::
*~RButton::
*~Shift::
{
	if (ToggleStates.bAutobuy)
		ToggleAutobuy()
}

#SuspendExempt
; Exit script
*~!F10::ExitApp() ; ALT+F10

; Reload script
*~!F11::Reload() ; ALT+F11

; Suspend script (useful in menus)
*~!F12:: ; ALT+F12
{
	Suspend()

	; Single beep when suspended
	if (g_bBeepOnSuspend)
		SoundBeep(1000, 100)

	if (A_IsSuspended)
		ReleaseAllKeys()
	; Double beep when resumed
	else
	{
		if (g_bBeepOnSuspend)
			SoundBeep(1000, 100)
	}
}
#SuspendExempt False
