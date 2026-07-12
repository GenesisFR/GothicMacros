#Requires AutoHotkey v2.0
#SingleInstance

class AnimationStates
{
	static SNEAK_ANIM_DURATION_IDLE := 500
	static SNEAK_ANIM_DURATION_MOVING := 200
	static iSneakTimePressed := 0

	static GetSneakAnimDuration()
	{
		; The transition between standing up and sneaking is shorter when moving forward
		return GetKeyState(g_sForwardKey) ? AnimationStates.SNEAK_ANIM_DURATION_MOVING : AnimationStates.SNEAK_ANIM_DURATION_IDLE
	}
}

class HoldStates
{
	static bFastAttacking := 0
	static bLooting       := 0
	static bSmithing      := 0
	static bSneaking      := 0
	static bWalking       := 0
}

class ToggleStates
{
	static bAutobuy         := 0
	static bAutocook        := 0
	static bAutojump        := 0
	static bAutorun         := 0
	static bAutoswim        := 0
	static bFirstPersonMode := 0
	static bSteamOverlay    := 0
	static bWalk            := 0
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
		ResetAll()
	}
}

; Turn off autojump
OnJumpPress(*)
{
	SetTimer(SendJump, ToggleStates.bAutojump := ToggleStates.bAutoswim := 0)
}

OnLootPress(*)
{
	HoldStates.bLooting := 1
	SendKey(g_sActionKey)
	SetTimer(SendAction, 200)
}

OnLootRelease(*)
{
	SetTimer(SendAction, HoldStates.bLooting := 0)
}

OnQuickLoadPress(*)
{
	ResetAll()
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

	ToggleSneakOff()
	{
		Output(A_ThisFunc)
		SendKey(g_sSneakKey)

		; Wait until the animation is over before allowing the Sneak key to be pressed again
		SetTimer(OnSneakOffAnimComplete, -AnimationStates.GetSneakAnimDuration())
	}

	OnSneakOffAnimComplete()
	{
		Output(A_ThisFunc)
		HoldStates.bSneaking := 0
	}
}

OnWalkPress(*)
{
	HoldStates.bWalking := 1
	Send("{Blind}{" g_sToggleWalkKey " down}")
}

OnWalkRelease(*)
{
	HoldStates.bWalking := 0
	Send("{Blind}{" g_sToggleWalkKey " up}")
	SetCapsLockState(ToggleStates.bWalk ^= 1)
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
	g_bAutobuyStacks := IniRead(l_sConfigFile, "General", "bAutobuyStacks", false) == true
	g_bBeepOnSuspend := IniRead(l_sConfigFile, "General", "bBeepOnSuspend", true) == true
	g_bInvertControlsWhenAutoSwimming := IniRead(l_sConfigFile, "General", "bInvertControlsWhenAutoSwimming", false) == true
	g_bWaitForSneakAnimation := IniRead(l_sConfigFile, "General", "bWaitForSneakAnimation", false) == true

	if !IsInteger(g_iAutobuyClickFrequency := IniRead(l_sConfigFile, "General", "iAutobuyClickFrequency", 100))
		g_iAutobuyClickFrequency := 100
	if !IsInteger(g_iAutojumpFrequency := IniRead(l_sConfigFile, "General", "iAutojumpFrequency", 500))
		g_iAutojumpFrequency := 500

	; Mandatory Keys
	g_sActionKey       := IniRead(l_sConfigFile, "MandatoryKeys", "sActionKey", "f")
	g_sBackwardKey     := IniRead(l_sConfigFile, "MandatoryKeys", "sBackwardKey", "s")
	g_sForwardKey      := IniRead(l_sConfigFile, "MandatoryKeys", "sForwardKey", "w")
	g_sJumpKey         := IniRead(l_sConfigFile, "MandatoryKeys", "sJumpKey", "Space")
	g_sSteamOverlayKey := IniRead(l_sConfigFile, "MandatoryKeys", "sSteamOverlayKey", "ScrollLock")

	; Optional Keys
	g_sFastAttackKey            := IniRead(l_sConfigFile, "OptionalKeys", "sFastAttackKey", "")
	g_sLootKey                  := IniRead(l_sConfigFile, "OptionalKeys", "sLootKey", "")
	g_sQuickLoadKey             := IniRead(l_sConfigFile, "OptionalKeys", "sQuickLoadKey", "")
	g_sRightClickKey            := IniRead(l_sConfigFile, "OptionalKeys", "sRightClickKey", "")
	g_sSmithKey                 := IniRead(l_sConfigFile, "OptionalKeys", "sSmithKey", "")
	g_sSneakKey                 := IniRead(l_sConfigFile, "OptionalKeys", "sSneakKey", "")
	g_sToggleAutobuyKey         := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutobuyKey", "")
	g_sToggleAutocookKey        := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutocookKey", "")
	g_sToggleAutojumpKey        := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutojumpKey", "")
	g_sToggleAutorunKey         := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutorunKey", "")
	g_sToggleAutoswimKey        := IniRead(l_sConfigFile, "OptionalKeys", "sToggleAutoswimKey", "")
	g_sToggleFirstPersonModeKey := IniRead(l_sConfigFile, "OptionalKeys", "sToggleFirstPersonModeKey", "")
	g_sToggleWalkKey            := IniRead(l_sConfigFile, "OptionalKeys", "sToggleWalkKey", "")

	; Prevent some variables from being negative or set to 0, otherwise timers won't work
	g_iAutobuyClickFrequency := Max(g_iAutobuyClickFrequency, 1)
	g_iAutojumpFrequency     := Max(g_iAutojumpFrequency, 1)
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
	HotIf((*) => WinActive(g_sWindowTitle) && ToggleStates.bAutoswim && g_bInvertControlsWhenAutoswimming && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*", g_sBackwardKey, (*) => Send("{" g_sForwardKey " down}"))
		RegisterHotkey("*", g_sBackwardKey, (*) => Send("{" g_sForwardKey " up}"), " up")
		RegisterHotkey("*", g_sForwardKey, (*) => Send("{" g_sBackwardKey " down}"))
		RegisterHotkey("*", g_sForwardKey, (*) => Send("{" g_sBackwardKey " up}"), " up")
	HotIf((*) => WinActive(g_sWindowTitle) && !HoldStates.bLooting && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sLootKey, OnLootPress)
	HotIf((*) => WinActive(g_sWindowTitle) && !HoldStates.bSmithing && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sSmithKey, OnSmithPress)
	HotIf((*) => WinActive(g_sWindowTitle) && !HoldStates.bSneaking && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sSneakKey, OnSneakPress)
	HotIf((*) => WinActive(g_sWindowTitle) && HoldStates.bSneaking && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sSneakKey, OnSneakRelease, " up")
	HotIf((*) => WinActive(g_sWindowTitle) && !HoldStates.bWalking && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*", g_sToggleWalkKey, OnWalkPress)

	; Hotkeys fired only when Gothic is the active window and the Steam overlay is not in the foreground
	HotIf((*) => WinActive(g_sWindowTitle) && !ToggleStates.bSteamOverlay)
		RegisterHotkey("*~", g_sForwardKey, (*) => ToggleStates.bAutorun := 0)
		RegisterHotkey("*~", g_sJumpKey, OnJumpPress)
		RegisterHotkey("*~", g_sQuickLoadKey, OnQuickLoadPress)
		RegisterHotkey("*~", g_sFastAttackKey, OnFastAttackRelease, " up")
		RegisterHotkey("*~", g_sLootKey, OnLootRelease, " up")
		RegisterHotkey("*~", g_sSmithKey, OnSmithRelease, " up")
		RegisterHotkey("*~", g_sToggleAutobuyKey, ToggleAutobuy, " up")
		RegisterHotkey("*~", g_sToggleAutocookKey, ToggleAutocook, " up")
		RegisterHotkey("*~", g_sToggleAutojumpKey, ToggleAutojump, " up")
		RegisterHotkey("*~", g_sToggleAutorunKey, ToggleAutorun, " up")
		RegisterHotkey("*~", g_sToggleAutoswimKey, ToggleAutoswim, " up")
		RegisterHotkey("*~", g_sToggleFirstPersonModeKey, ToggleFirstPersonMode, " up")
		RegisterHotkey("*",  g_sToggleWalkKey, OnWalkRelease, " up")
	HotIf()
}

ResetAll(p_bToggleOffCapsLock := true)
{
	; Delete timers
	for l_fnTimer in [Cook, SendAction, SendBackward, SendJump, SendLeftMouseButton]
		SetTimer(l_fnTimer, 0)

	; Release keys
	for l_sKey in ["LAlt", "LButton", "LCtrl", "LShift", g_sActionKey, g_sBackwardKey, g_sFastAttackKey, g_sForwardKey, g_sJumpKey, g_sSneakKey]
		Send("{Blind}{" l_sKey " up}")

	; Reset states
	AnimationStates.iSneakTimePressed := 0
	HoldStates.bFastAttacking := HoldStates.bSmithing := HoldStates.bSneaking := HoldStates.bWalking := 0
	ToggleStates.bAutobuy := ToggleStates.bAutocook := ToggleStates.bAutojump := ToggleStates.bAutorun := ToggleStates.bAutoswim := ToggleStates.bFirstPersonMode := 0

	if (p_bToggleOffCapsLock)
		SetCapsLockState(ToggleStates.bWalk := 0)
}

SendAction()
{
	SendKey(g_sActionKey)
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
	Send("{Blind}{" p_sKey " down}")
	Sleep(25)
	Send("{Blind}{" p_sKey " up}")
}

SendLeftMouseButton()
{
	SendKey("LButton")
}

; Buy/Sell/Use in bulk (highlight the desired item beforehand)
ToggleAutobuy(*)
{
	ToggleStates.bAutobuy ^= 1

	if (g_bAutobuyStacks)
		Send(ToggleStates.bAutobuy ? "{LShift down}" : "{LShift up}")
	else
		Send(ToggleStates.bAutobuy ? "{" g_sActionKey " down}" :  "{" g_sActionKey " up}")

	; Spam left-click to buy/sell/use items faster
	SetTimer(SendLeftMouseButton, ToggleStates.bAutobuy * g_iAutobuyClickFrequency)
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
	SendJump()

	; Continuously spam jump, should be combined with autorun
	SetTimer(SendJump, ToggleStates.bAutojump * g_iAutojumpFrequency)
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

ToggleSteamOverlay(*)
{
	ToggleStates.bSteamOverlay ^= 1
	ResetAll()
	SendKey(g_sSteamOverlayKey)
	KeyWait(g_sSteamOverlayKey)
}

; When doing Shift + left-click to buy stacks of 100 items
#HotIf WinActive(g_sWindowTitle) && g_sToggleWalkKey && !ToggleStates.bSteamOverlay
<+LButton::
{
	if (ToggleStates.bAutobuy)
		ToggleAutobuy()

	l_bPrevCapsLockState := GetKeyState("CapsLock", "T")
	KeyWait("LShift")
	SetCapsLockState(l_bPrevCapsLockState)
}
#HotIf

; When right-click has been remapped
#HotIf WinActive(g_sWindowTitle) && g_sRightClickKey && !ToggleStates.bSteamOverlay
*RButton::
{
	if (ToggleStates.bAutobuy)
		ToggleAutobuy()

	Send("{" g_sRightClickKey " down}")
}
*RButton up::Send("{" g_sRightClickKey " up}")
#HotIf

#HotIf WinActive(g_sWindowTitle) && !ToggleStates.bSteamOverlay
*~Escape::ResetAll(false)
*~LButton::
*~RButton::
{
	if (ToggleStates.bAutobuy)
		ToggleAutobuy()
}
#HotIf

#SuspendExempt
; Automatically reload the script after saving in VSCode (skipped in the compiled script)
;@Ahk2Exe-IgnoreBegin
#HotIf WinActive("Visual Studio Code") && InStr(WinGetTitle("A"), A_ScriptName)
~^s::Send("^+{F5}")
#HotIf
;@Ahk2Exe-IgnoreEnd

; Exit script (CTRL + ALT + F10)
*~^!F10::ExitApp()

; Reload script (CTRL + ALT + F11)
*~^!F11::Reload()

; Suspend script, useful in menus (CTRL + ALT + F12)
*~^!F12::
{
	Suspend()

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