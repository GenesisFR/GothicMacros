#Requires AutoHotkey v2.0
#SingleInstance

g_bBuyToggle := 0
g_bCookToggle := 0
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
	global g_bBuyToggle := 0
	global g_bCookToggle := 0
	Send("{f up}{s up}{w up}{MButton up}")
	SetTimer(Buy, 0)
	SetTimer(Cook, 0)
}

#HotIf WinActive(g_sWindowTitle)
~k up::
{
	global g_bBuyToggle ^= 1
	Send("{f " (g_bBuyToggle ? "down}" : "up}"))

	; Spam left-click to buy items faster
	SetTimer(Buy, g_bBuyToggle * 20)
}

~l up::
{
	global g_bCookToggle ^= 1
	Cook(g_bCookToggle)
}

; Pull out your weapon then hold the middle mouse button to continously attack the fastest way possible (only use it on enemies you can't parry)
~MButton::
{
	Send("{f down}{s down}{w down}")
	KeyWait("MButton")
	Send("{f up}{s up}{w up}")
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
	SoundBeep(1000, 100)

	if (A_IsSuspended)
		ReleaseAllKeys()
	; Double beep when resumed
	else
		SoundBeep(1000, 100)
}
#SuspendExempt False
#HotIf
