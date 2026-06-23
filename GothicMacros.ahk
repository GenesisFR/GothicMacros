#Requires AutoHotkey v2.0
#SingleInstance

g_bAutorunToggle := 0
g_bBuyToggle := 0
g_bCookToggle := 0
g_bJumpAutofireToggle := 0
g_bSteamOverlay := 0
g_bWalkToggle := 0
g_sWindowTitle := "ahk_group Gothic"

Init()

Init()
{
	; Window group for Gothic
	GroupAdd("Gothic", "ahk_exe Gothic.exe")
	GroupAdd("Gothic", "ahk_exe GothicMod.exe")

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

CleanHotkey(p_sThisHotkey)
{
	return LTrim(RTrim(p_sThisHotkey, " up"), "~*$")
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
			SetTimer(Cook.Bind(2), g_bCookToggle * -2000)
		; Finish cooking then start again once your character stands up
		case 2:
			Send("{" g_sActionKey " up}{" g_sBackwardKey " up}")
			SetTimer(Cook, g_bCookToggle * -1200)
	}
}

Forward(*)
{
	global g_bAutorunToggle := 0
}

; Continously fast attack, use it preferably on enemies you can't parry (you must have your weapon pulled out beforehand)
HoldFastAttack(p_sThisHotkey)
{
	Send("{" g_sActionKey " down}{" g_sBackwardKey " down}{" g_sForwardKey " down}")
	l_sCleanHotkey := CleanHotkey(p_sThisHotkey)
	KeyWait(l_sCleanHotkey)
	Send("{" g_sActionKey " up}{" g_sBackwardKey " up}{" g_sForwardKey " up}")
}

; Turn off autojump
Jump(*)
{
	if (g_bJumpAutofireToggle)
	{
		global g_bJumpAutofireToggle := 0
		SetTimer(SendJump, 0)
	}
}

OnFocusChanged(hWinEventHook, vEvent, hWnd)
{
	if WinActive(g_sWindowTitle)
	{
		WinWaitNotActive(g_sWindowTitle)
		ReleaseAllKeys()
	}
}

ReadConfigFile()
{
	global

	local l_sConfigFile := "GothicMacros.ini"

	; General
	g_bBeepOnSuspend         := IniRead(l_sConfigFile, "General", "bBeepOnSuspend", true) == true
	g_iAutobuyClickFrequency := IniRead(l_sConfigFile, "General", "iAutobuyClickFrequency", 100)

	; Mandatory Keys
	g_sActionKey         := IniRead(l_sConfigFile, "MandatoryKeys", "sActionKey", "f")
	g_sBackwardKey       := IniRead(l_sConfigFile, "MandatoryKeys", "sBackwardKey", "s")
	g_sForwardKey        := IniRead(l_sConfigFile, "MandatoryKeys", "sForwardKey", "w")
	g_sJumpKey           := IniRead(l_sConfigFile, "MandatoryKeys", "sJumpKey", "Space")
	g_sSteamOverlayKey   := IniRead(l_sConfigFile, "MandatoryKeys", "sSteamOverlayKey", "ScrollLock")

	; Optional Keys
	g_sFastAttackKey     := IniRead(l_sConfigFile, "OptionalKeys", "sFastAttackKey", "")
	g_sToggleAutobuyKey  := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutobuyKey", "")
	g_sToggleAutocookKey := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutocookKey", "")
	g_sToggleAutojumpKey := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutojumpKey", "")
	g_sToggleAutorunKey  := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutorunKey", "")
	g_sToggleWalkKey     := IniRead(l_sConfigFile, "OptionalKeys", "sToggleWalkKey", "")

	; Prevent some variables from being negative or set to 0, otherwise timers won't work
	if !IsInteger(g_iAutobuyClickFrequency) g_iAutobuyClickFrequency := 100
	g_iAutobuyClickFrequency := Max(g_iAutobuyClickFrequency, 1)
}

RegisterHotkey(p_sPrefix, p_sHotkey, p_fnAction, p_sSuffix := "")
{
	; If the hotkey is empty, don't register it
	if (!p_sHotkey)
		return
	
	Hotkey(p_sPrefix p_sHotkey p_sSuffix, p_fnAction, "On")
}

RegisterHotkeys()
{
	; Hotkeys are fired only when Gothic is the active window
	HotIfWinActive(g_sWindowTitle)
	RegisterHotkey("*", g_sSteamOverlayKey, SteamOverlay)
	HotIfWinActive()

	HotIf((*) => WinActive(g_sWindowTitle) && !g_bSteamOverlay)
	RegisterHotkey("*~", g_sFastAttackKey, HoldFastAttack)
	RegisterHotkey("*~", g_sForwardKey, Forward)
	RegisterHotkey("*~", g_sJumpKey, Jump)
	RegisterHotkey("*~", g_sToggleAutobuyKey, ToggleAutobuy, " up")
	RegisterHotkey("*~", g_sToggleAutocookKey, ToggleAutocook, " up")
	RegisterHotkey("*~", g_sToggleAutojumpKey, ToggleAutojump, " up")
	RegisterHotkey("*~", g_sToggleAutorunKey, ToggleAutorun, " up")
	RegisterHotkey("*~", g_sToggleWalkKey, ToggleWalk, " up")
	HotIf()
}

ReleaseAllKeys()
{
	global

	; Release keys
	g_bAutorunToggle := g_bBuyToggle := g_bCookToggle := g_bJumpAutofireToggle := g_bWalkToggle := 0
	Send("{" g_sActionKey " up}{" g_sBackwardKey " up}{" g_sFastAttackKey " up}{" g_sForwardKey " up}{" g_sJumpKey " up}{LButton up}{Shift up}")

	; Delete timers
	SetTimer(SendLeftMouseButton, 0)
	SetTimer(Cook, 0)
	SetTimer(SendJump, 0)
}

SendJump()
{
	Send("{" g_sJumpKey " down}")
	Sleep(25)
	Send("{" g_sJumpKey " up}")
}

SendLeftMouseButton()
{
	Send("{LButton down}")
	Sleep(25)
	Send("{LButton up}")
}

SteamOverlay(p_sThisHotkey)
{
	global g_bSteamOverlay ^= 1
	ReleaseAllKeys()

	l_sCleanHotkey := CleanHotkey(p_sThisHotkey)
	Send("{" l_sCleanHotkey "}")
	KeyWait(l_sCleanHotkey)
}

; Buy/Sell/Use in bulk (highlight the desired item beforehand)
ToggleAutobuy(*)
{
	global g_bBuyToggle ^= 1
	Send("{Shift " (g_bBuyToggle ? "down}" : "up}"))

	; Spam left-click to buy/sell/use items faster
	SetTimer(SendLeftMouseButton, g_bBuyToggle * g_iAutobuyClickFrequency)
}

; Autocook (you must be looking at a fireplace/pan and be within range beforehand)
ToggleAutocook(*)
{
	global g_bCookToggle ^= 1
	Cook(g_bCookToggle)
}

ToggleAutojump(*)
{
	global g_bJumpAutofireToggle ^= 1
	Send("{" g_sJumpKey (g_bJumpAutofireToggle ? "down}" : "up}"))

	; Continuously spam jump, should be combined with autorun
	SetTimer(SendJump, g_bJumpAutofireToggle * 500)
}

ToggleAutorun(*)
{
	global g_bAutorunToggle ^= 1
	Send("{" g_sForwardKey (g_bAutorunToggle ? " down}" : " up}"))
}

ToggleWalk(p_sThisHotkey)
{
	global g_bWalkToggle ^= 1
	l_sCleanHotkey := CleanHotkey(p_sThisHotkey)
	Send("{" l_sCleanHotkey (g_bWalkToggle ? " down}" : " up}"))
}

; Turn off autobuy
*~LButton::
*~Shift::
{
	if (g_bBuyToggle)
	{
		global g_bBuyToggle := 0
		SetTimer(SendLeftMouseButton, 0)
	}
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
