#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Contributor: Gahais
; Copyright 2025 caustic-kronos
;
; Licensed under the Apache License, Version 2.0 (the 'License');
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an 'AS IS' BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'
#include '../utilities/SupportTeam.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $VOLTAIC_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- completed EotN story once' & @CRLF _
	& '- a full and efficient 7-hero-team' & @CRLF _
	& '- a hero with Frozen Soil' & @CRLF _
	& '- a build that can be run from skill 1 to 8 (no complex combos or conditional skills)' & @CRLF _
	& 'In NM, bot takes 13min (with cons), 15min (without cons) on average' & @CRLF _
	& 'Not tested in HM.'
Global Const $VOLTAIC_FARM_DURATION = 16 * 60 * 1000
Global Const $VS_AGGRO_RANGE = $RANGE_SPELLCAST + 200
Global Const $VOLTAIC_TEAM_ASSEMBLY_PASSES = 4
Global Const $VOLTAIC_TEAM_MISSING_FALLBACK_PASSES = 3
Global Const $VOLTAIC_TEAM_OUTPOST_RETRIES = 4

Global Const $VOLTAIC_HERO_GWEN_TEMPLATE = 'OQlkAkB8wYm0LACIHUeGJQN2OGRA'
Global Const $VOLTAIC_HERO_NORGU_TEMPLATE = 'OQhkAsC8gFKTIc6lDupDBTXG4iB'
Global Const $VOLTAIC_HERO_RAZAH_TEMPLATE = 'OQJUAWxOQ8M0gcw0z0NCxpZgrDA'
Global Const $VOLTAIC_HERO_MOW_TEMPLATE = 'OAhjYoHYIPWb7wnoqKNncDzqHA'
Global Const $VOLTAIC_HERO_DUNKORO_TEMPLATE = 'OwQTcUHDxxnV9xrXEqvLxOI0AA'
Global Const $VOLTAIC_HERO_OLIAS_TEMPLATE = 'OAhjQkGZIP3hhmwrqKNncDzxJA'
Global Const $VOLTAIC_HERO_LIVIA_TEMPLATE = 'OAljUwGpZSUBKgfBVVbh8Y7Y1YA'
Global Const $VOLTAIC_HERO_ZHED_TEMPLATE = 'OgljgwMpZSXVfDeDLg6QhD1Y7YA'
Global Const $VOLTAIC_HERO_XANDRA_TEMPLATE = 'OAOiAyk5gNtePuwJ00ZaNbJA'
Global Const $VOLTAIC_HERO_VEKK_TEMPLATE = 'OgNDwcPPP1CSSARLWPga31VC'

Global Const $VOLTAIC_FLEX3_HERO_ID = $ID_MASTER_OF_WHISPERS
Global Const $VOLTAIC_FLEX3_HERO_NAME = 'Master of Whispers'
Global Const $VOLTAIC_FLEX3_HERO_TEMPLATE = $VOLTAIC_HERO_MOW_TEMPLATE
;~ Global Const $VOLTAIC_FLEX3_HERO_ID = $ID_DUNKORO
;~ Global Const $VOLTAIC_FLEX3_HERO_NAME = 'Dunkoro'
;~ Global Const $VOLTAIC_FLEX3_HERO_TEMPLATE = $VOLTAIC_HERO_DUNKORO_TEMPLATE
Global Const $VOLTAIC_FLEX_HERO_ID = $ID_ZHED_SHADOWHOOF
Global Const $VOLTAIC_FLEX_HERO_NAME = 'Zhed Shadowhoof'
Global Const $VOLTAIC_FLEX_HERO_TEMPLATE = $VOLTAIC_HERO_ZHED_TEMPLATE
;~ Global Const $VOLTAIC_FLEX_HERO_ID = $ID_LIVIA
;~ Global Const $VOLTAIC_FLEX_HERO_NAME = 'Livia'
;~ Global Const $VOLTAIC_FLEX_HERO_TEMPLATE = $VOLTAIC_HERO_LIVIA_TEMPLATE
Global Const $VOLTAIC_FLEX2_HERO_ID = $ID_VEKK
Global Const $VOLTAIC_FLEX2_HERO_NAME = 'Vekk'
Global Const $VOLTAIC_FLEX2_HERO_TEMPLATE = $VOLTAIC_HERO_VEKK_TEMPLATE
;~ Global Const $VOLTAIC_FLEX2_HERO_ID = $ID_XANDRA
;~ Global Const $VOLTAIC_FLEX2_HERO_NAME = 'Xandra'
;~ Global Const $VOLTAIC_FLEX2_HERO_TEMPLATE = $VOLTAIC_HERO_XANDRA_TEMPLATE

Global $voltaic_farm_setup = False

;~ Main method to farm Voltaic
Func VoltaicFarm()
	If Not $voltaic_farm_setup Then SetupVoltaicFarm()

	GoToVerdantCascades()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = VoltaicFarmLoop()
	AdlibUnregister('TrackPartyStatus')
	TravelToOutpost($ID_UMBRAL_GROTTO, $district_name)
	Return $result
EndFunc


;~ Voltaic farm setup
Func SetupVoltaicFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_UMBRAL_GROTTO, $district_name)
	If Not SupportTeamStabilizeAfterTravel($ID_UMBRAL_GROTTO, 10000, 250) Then
		Warn('Voltaic setup: outpost stabilization timed out before team setup')
	EndIf
	If SetupVoltaicFlexibleTeam() == $FAIL Then Return $FAIL
	SwitchToHardModeIfEnabled()
	SetDisplayedTitle($ID_ASURA_TITLE)
	SupportTeamOpenHeroPanels('Voltaic')
	$voltaic_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupVoltaicFlexibleTeam()
	Info('Voltaic team: Gwen, Norgu, Razah, ' & $VOLTAIC_FLEX3_HERO_NAME & ', Olias, ' & $VOLTAIC_FLEX_HERO_NAME & ', ' & $VOLTAIC_FLEX2_HERO_NAME)
	Local $heroIDs[7] = [ _
		$ID_GWEN, _
		$ID_NORGU, _
		$ID_RAZAH, _
		$VOLTAIC_FLEX3_HERO_ID, _
		$ID_OLIAS, _
		$VOLTAIC_FLEX_HERO_ID, _
		$VOLTAIC_FLEX2_HERO_ID _
	]
	Local $heroNames[7] = [ _
		'Gwen', _
		'Norgu', _
		'Razah', _
		$VOLTAIC_FLEX3_HERO_NAME, _
		'Olias', _
		$VOLTAIC_FLEX_HERO_NAME, _
		$VOLTAIC_FLEX2_HERO_NAME _
	]

	If VoltaicAssembleFixedTeamWithRecovery($heroIDs, $heroNames, 'Voltaic') == $FAIL Then Return $FAIL

	LoadSkillTemplate($VOLTAIC_HERO_GWEN_TEMPLATE, 1)
	RandomSleep(150)
	LoadSkillTemplate($VOLTAIC_HERO_NORGU_TEMPLATE, 2)
	RandomSleep(150)
	LoadSkillTemplate($VOLTAIC_HERO_RAZAH_TEMPLATE, 3)
	RandomSleep(150)
	LoadSkillTemplate($VOLTAIC_FLEX3_HERO_TEMPLATE, 4)
	RandomSleep(150)
	LoadSkillTemplate($VOLTAIC_HERO_OLIAS_TEMPLATE, 5)
	RandomSleep(150)
	LoadSkillTemplate($VOLTAIC_FLEX_HERO_TEMPLATE, 6)
	RandomSleep(150)
	LoadSkillTemplate($VOLTAIC_FLEX2_HERO_TEMPLATE, 7)
	RandomSleep(250)

	ClearPartyCommands()
	CancelAllHeroes()
	Return $SUCCESS
EndFunc


Func VoltaicEnsureSoloParty($maxWaitMs = 9000)
	Local $timer = TimerInit()
	SupportTeamKickAllHeroesByIDSweep()
	KickAllHeroes()
	LeaveParty(False)
	While TimerDiff($timer) < $maxWaitMs
		If GetPartySize() <= 1 Then Return $SUCCESS
		SupportTeamKickAllHeroesByIDSweep()
		KickAllHeroes()
		LeaveParty(False)
		RandomSleep(320)
	WEnd
	Warn('Voltaic team: party reset timeout. Party=' & GetPartySize() & ', heroes=' & GetHeroCount())
	Return $FAIL
EndFunc


Func VoltaicTryAddHero($heroID, $heroName, $teamLabel = 'Voltaic')
	For $i = 1 To 7
		If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
		AddHero($heroID)
		Local $verifyTimer = TimerInit()
		While TimerDiff($verifyTimer) < 2200
			If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
			RandomSleep(120)
		WEnd

		If Mod($i, 2) == 0 Then
			SupportTeamStabilizeAfterTravel($ID_UMBRAL_GROTTO, 1800, 150)
		EndIf
	Next
	Warn('Could not add ' & $teamLabel & ' hero ' & $heroName & ' after retries (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')
	Return $FAIL
EndFunc


Func VoltaicAssembleFixedTeamWithRecovery(ByRef $heroIDs, ByRef $heroNames, $teamLabel)
	Local $attempt
	For $attempt = 1 To $VOLTAIC_TEAM_OUTPOST_RETRIES
		If $attempt > 1 Then
			Warn($teamLabel & ' team assembly pass ' & $attempt & ' after outpost refresh')
			If TravelToOutpost($ID_UMBRAL_GROTTO, $district_name) == $FAIL Then Return $FAIL
			If Not SupportTeamStabilizeAfterTravel($ID_UMBRAL_GROTTO, 10000, 250) Then
				Warn($teamLabel & ' team: outpost stabilization timed out before pass ' & $attempt)
			EndIf
		EndIf

		If VoltaicEnsureSoloParty() == $FAIL Then Return $FAIL
		If VoltaicAssembleTeamPass($heroIDs, $heroNames, $teamLabel) == $SUCCESS Then Return $SUCCESS
		Warn($teamLabel & ' team assembly pass ' & $attempt & ' failed, trying targeted missing-hero fallback')
		If VoltaicRetryMissingHeroes($heroIDs, $heroNames, $teamLabel) == $SUCCESS Then Return $SUCCESS
	Next

	Warn($teamLabel & ' team assembly failed after all recovery passes')
	VoltaicWarnMissingHeroes($heroIDs, $heroNames, $teamLabel)
	Return $FAIL
EndFunc


Func VoltaicAssembleTeamPass(ByRef $heroIDs, ByRef $heroNames, $teamLabel)
	Local $round
	Local $i
	For $round = 1 To $VOLTAIC_TEAM_ASSEMBLY_PASSES
		For $i = 0 To UBound($heroIDs) - 1
			If GetHeroNumberByHeroID($heroIDs[$i]) == Null Then
				VoltaicTryAddHero($heroIDs[$i], $heroNames[$i], $teamLabel)
			EndIf
		Next

		If SupportTeamHasExactHeroes($heroIDs, 8) Then Return $SUCCESS
		Warn($teamLabel & ' team fill round ' & $round & ' incomplete (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')
		SupportTeamStabilizeAfterTravel($ID_UMBRAL_GROTTO, 2200, 150)
	Next

	VoltaicWarnMissingHeroes($heroIDs, $heroNames, $teamLabel)
	Return $FAIL
EndFunc


Func VoltaicRetryMissingHeroes(ByRef $heroIDs, ByRef $heroNames, $teamLabel)
	Local $round
	Local $i
	For $round = 1 To $VOLTAIC_TEAM_MISSING_FALLBACK_PASSES
		Local $attemptedAny = False
		For $i = 0 To UBound($heroIDs) - 1
			If GetHeroNumberByHeroID($heroIDs[$i]) == Null Then
				$attemptedAny = True
				Info($teamLabel & ' targeted fallback round ' & $round & ': retrying missing hero ' & $heroNames[$i])
				VoltaicTryAddHero($heroIDs[$i], $heroNames[$i], $teamLabel)
			EndIf
		Next

		If SupportTeamHasExactHeroes($heroIDs, 8) Then
			Info($teamLabel & ' targeted missing-hero fallback succeeded on round ' & $round)
			Return $SUCCESS
		EndIf

		If Not $attemptedAny Then ExitLoop
		SupportTeamStabilizeAfterTravel($ID_UMBRAL_GROTTO, 2200, 150)
	Next

	VoltaicWarnMissingHeroes($heroIDs, $heroNames, $teamLabel)
	Return $FAIL
EndFunc


Func VoltaicWarnMissingHeroes(ByRef $heroIDs, ByRef $heroNames, $teamLabel)
	Local $missing = ''
	Local $i
	For $i = 0 To UBound($heroIDs) - 1
		If GetHeroNumberByHeroID($heroIDs[$i]) == Null Then
			If $missing <> '' Then $missing &= ', '
			$missing &= $heroNames[$i]
		EndIf
	Next
	If $missing == '' Then $missing = 'none'
	Warn($teamLabel & ' missing heroes after pass: ' & $missing & ' (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')
EndFunc


;~ Move out of outpost into Verdant Cascades
Func GoToVerdantCascades()
	TravelToOutpost($ID_UMBRAL_GROTTO, $district_name)
	While GetMapID() <> $ID_VERDANT_CASCADES
		Info('Moving to Verdant Cascades')
		MoveTo(-23200, 7100)
		Move(-22735, 6339)
		RandomSleep(1000)
		WaitMapLoading($ID_VERDANT_CASCADES, 10000, 2000)
	WEnd
EndFunc


;~ Farm loop
Func VoltaicFarmLoop()
	If GetMapID() <> $ID_VERDANT_CASCADES Then Return $FAIL
	ResetFailuresCounter()

	MoveAggroAndKillInRange(-19887, 6074, '1', $VS_AGGRO_RANGE)
	Info('Making way to Slavers')
	MoveAggroAndKillInRange(-10273, 3251, '2', $VS_AGGRO_RANGE)
	MoveAggroAndKillInRange(-6878, -329, '3', $VS_AGGRO_RANGE)
	MoveAggroAndKillInRange(-3041, -3446, '4', $VS_AGGRO_RANGE)
	MoveAggroAndKillInRange(3571, -9501, '5', $VS_AGGRO_RANGE)
	MoveAggroAndKillInRange(10764, -6448, '6', $VS_AGGRO_RANGE)
	MoveAggroAndKillInRange(13063, -4396, '7', $VS_AGGRO_RANGE)
	If IsRunFailed() Then Return $FAIL

	Info('At the Troll Bridge - TROLL TOLL')
	MoveAggroAndKillInRange(18054, -3275, '8', $VS_AGGRO_RANGE)
	MoveAggroAndKillInRange(20966, -6476, '9', $VS_AGGRO_RANGE)
	MoveAggroAndKillInRange(25298, -9456, '10', $VS_AGGRO_RANGE)
	If IsRunFailed() Then Return $FAIL

	Move(25729, -9360)
	Info('Entering Slavers')
	While Not WaitMapLoading($ID_SLAVERS_EXILE)
		Sleep(50)
	WEnd
	MoveTo(-16797, 9251)
	MoveTo(-17835, 12524)
	Move(-18300, 12527)
	; The map has the same ID as slavers
	While Not WaitMapLoading()
		Sleep(50)
	WEnd
	Info('Now in Justicar')
	Sleep(500)
	GoToNPC(GetNearestNPCToCoords(-12135, -18210))
	RandomSleep(250)
	Dialog(0x84)
	RandomSleep(500)

	If IsHardmodeEnabled() Then UseConset()

	Sleep(1000)
	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -18500, -8000, 1250)
		WaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		UseConsumable($ID_LEGIONNAIRE_SUMMONING_CRYSTAL)
		MoveAggroAndKillInRange(-13500, -15750, 'In front of the door', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-12500, -15000, 'Before the bridge', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10400, -14800, 'After the bridge', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-11500, -13300, 'First group', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-13400, -11500, 'Second group', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-13700, -9550, 'Third group', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-14100, -8600, 'Fourth group', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-15000, -7500, 'Fourth group, again', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16500, -8000, 'Fifth group', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-18800, -7850, 'To the shrine', $VS_AGGRO_RANGE)
	WEnd
	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -17500, -14250, 1250)
		WaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		UseConsumable($ID_LEGIONNAIRE_SUMMONING_CRYSTAL)
		MoveAggroAndKillInRange(-18500, -11500, 'Pre-Boss group', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-17700, -12500, 'Boss group', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-17500, -14250, 'Final group', $VS_AGGRO_RANGE)
	WEnd
	If IsRunFailed() Then Return $FAIL
	Info('Opening chest')
	; Tripled to secure looting of chest
	For $i = 0 To 2
		MoveRadial(-17500, -14250, 600)
		Sleep(5000)
		TargetNearestItem()
		ActionInteract()
		Sleep(2500)
		PickUpItems()
	Next
	Info('Finished Run')
	Return $SUCCESS
EndFunc
