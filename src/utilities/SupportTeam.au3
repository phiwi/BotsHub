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
