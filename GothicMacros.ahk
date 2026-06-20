#Requires AutoHotkey v2.0
#SingleInstance

g_bAutorunToggle := 0
g_bBuyToggle := 0
g_bCookToggle := 0
g_bJumpAutofireToggle := 0
g_bSteamOverlay := 0
g_sWindowTitle := "ahk_group Gothic"

GroupAdd("Gothic", "ahk_exe Gothic.exe")
GroupAdd("Gothic", "ahk_exe GothicMod.exe")

; Set a callback to SetWinEventHook
DllCall("user32\SetWinEventHook",
	"Int", EVENT_SYSTEM_FOREGROUND := 0x0003,
	"Int", EVENT_SYSTEM_FOREGROUND,
	"Ptr", 0,
	"Ptr", CallbackCreate(OnFocusChanged, "F"),
	"Int", 0,
	"Int", 0,
	"Int", 0)

OnExit(OnExitCallback)

Buy()
{
	Send("{LButton down}")
	Sleep(10)
	Send("{LButton up}")
}

Cook(p_iStep := 1)
{
	switch p_iStep
	{
		; Stop cooking
		case 0:
			Send("{f up}{s up}")
			SetTimer(Cook, 0)
		; Start cooking then finish once the meat is in the pan
		case 1:
			Send("{f down}{s down}")
			SetTimer(Cook.Bind(2), g_bCookToggle * -2000)
		; Finish cooking then start again once your character stands up
		case 2:
			Send("{f up}{s up}")
			SetTimer(Cook, g_bCookToggle * -1200)
	}
}

Jump()
{
	Send("{Space down}")
	Sleep(10)
	Send("{Space up}")
}

OnExitCallback(*)
{
	ReleaseAllKeys()
}

OnFocusChanged(hWinEventHook, vEvent, hWnd)
{
	if WinActive(g_sWindowTitle)
	{
		WinWaitNotActive(g_sWindowTitle)
		ReleaseAllKeys()
	}
}

ReleaseAllKeys()
{
	global

	; Release keys
	g_bAutorunToggle := g_bBuyToggle := g_bCookToggle := g_bJumpAutofireToggle := 0
	Send("{f up}{s up}{w up}{Shift up}{Space up}{LButton up}{MButton up}")

	; Delete timers
	SetTimer(Buy, 0)
	SetTimer(Cook, 0)
	SetTimer(Jump, 0)
}

#HotIf WinActive(g_sWindowTitle)
; Steam overlay
~ScrollLock up::
{
	global g_bSteamOverlay ^= 1
	ReleaseAllKeys()
}
#HotIf

#HotIf WinActive(g_sWindowTitle) && !g_bSteamOverlay
~F1 up::
{
	global g_bAutorunToggle ^= 1
	Send("{w " (g_bAutorunToggle ? "down}" : "up}"))
}

~F2 up::
{
	global g_bJumpAutofireToggle ^= 1
	Send("{Space " (g_bJumpAutofireToggle ? "down}" : "up}"))

	; Spam SPACE to continuously jump, should be combined with autorun
	SetTimer(Jump, g_bJumpAutofireToggle * 500)
}

; Buy/Sell/Use in bulk (put the cursor on the desired item beforehand)
~k up::
{
	global g_bBuyToggle ^= 1
	Send("{Shift " (g_bBuyToggle ? "down}" : "up}"))

	; Spam left-click to buy/sell/use items faster
	SetTimer(Buy, g_bBuyToggle * 100)
}

; Autocook (you must be looking at a fireplace/pan and be within range beforehand)
~l up::
{
	global g_bCookToggle ^= 1
	Cook(g_bCookToggle)
}

; Continously fast attack, use it preferably on enemies you can't parry (you must have your weapon pulled out beforehand)
~MButton::
{
	Send("{f down}{s down}{w down}")
	KeyWait("MButton")
	Send("{f up}{s up}{w up}")
}
#HotIf

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
	SoundBeep(1000, 100)

	if (A_IsSuspended)
		ReleaseAllKeys()
	; Double beep when resumed
	else
		SoundBeep(1000, 100)
}
#SuspendExempt False
