#include-once

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Func SupportTeamDebug($enabled, $message)
	If $enabled Then Info($message)
EndFunc


Func SupportTeamKickAllHeroesByIDSweep()
	For $i = 0 To UBound($HERO_IDS) - 1
		KickHero($HERO_IDS[$i])
	Next
EndFunc


Func SupportTeamHasExactHeroes(ByRef $requiredHeroIDs, $expectedPartySize = 4)
	If GetPartySize() <> $expectedPartySize Then Return False
	For $i = 0 To UBound($requiredHeroIDs) - 1
		If GetHeroNumberByHeroID($requiredHeroIDs[$i]) == Null Then Return False
	Next
	Return True
EndFunc


Func SupportTeamResolveHeroIndex($heroID, $fallbackIndex)
	Local $index = GetHeroNumberByHeroID($heroID)
	If $index == Null Then Return $fallbackIndex
	Return $index
EndFunc


; Conservative post-travel stabilization to reduce transient party/hero API races.
Func SupportTeamStabilizeAfterTravel($expectedOutpostID, $maxWaitMs = 10000, $pollMs = 250)
	If Not WaitMapLoading($expectedOutpostID, $maxWaitMs, $pollMs) Then Return False

	; Force GW window active after map load — ensures party UI is responsive
	; even when Windows power management turned off the screen.
	ForceGwWindowActive()

	Local $timer = TimerInit()
	Local $stableTicks = 0
	Local $lastPartySize = -1
	While TimerDiff($timer) < 2500
		If GetMapID() <> $expectedOutpostID Then
			$stableTicks = 0
		Else
			Local $partySize = GetPartySize()
			If $partySize == $lastPartySize And $partySize >= 1 Then
				$stableTicks += 1
			Else
				$stableTicks = 0
			EndIf
			$lastPartySize = $partySize
			If $stableTicks >= 3 Then Return True
		EndIf
		RandomSleep($pollMs)
	WEnd

	; Fallback: map loaded but party state not fully stable yet.
	Return GetMapID() == $expectedOutpostID
EndFunc


Func SupportTeamOpenHeroPanels($contextLabel = 'Support team', $hero2Key = '9', $hero4To7Keys = '5|6|7|8')
	Local $heroCount = GetHeroCount()
	If $heroCount <= 0 Then Return

	Local $panelCount = $heroCount < 7 ? $heroCount : 7
	Info($contextLabel & ': forcing hero panels 1-' & $panelCount & ' visible')

	CloseAllPanels()
	Sleep(150 + GetPing())

	If $panelCount >= 1 Then
		ToggleHeroPanel(1)
		Sleep(130 + GetPing())
	EndIf

	If $panelCount >= 2 Then
		SupportTeamSendPanelKey($hero2Key)
		Sleep(130 + GetPing())
	EndIf

	If $panelCount >= 3 Then
		ToggleHeroPanel(3)
		Sleep(130 + GetPing())
	EndIf

	Local $extraHeroes = $panelCount - 3
	If $extraHeroes > 0 Then
		Local $keys = StringSplit($hero4To7Keys, '|')
		For $i = 1 To ($extraHeroes < 4 ? $extraHeroes : 4)
			If $i <= $keys[0] Then
				SupportTeamSendPanelKey($keys[$i])
				Sleep(130 + GetPing())
			EndIf
		Next
	EndIf
EndFunc


Func SupportTeamSendPanelKey($key)
	Local $hWnd = GetWindowHandle()
	If $hWnd <> 0 Then WinActivate($hWnd)
	Sleep(80 + GetPing())
	ControlSend($hWnd, '', '', $key)
EndFunc


