#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Contributor: Gahais
; Adaptation: GitHub Copilot (Assassin variant)
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
Global Const $BARBAROUS_SHORE_SIN_CHESTRUNNER_SKILLBAR = 'OwBj4xf84Q8I6M3lNQ0kTQ4OIQA'
Global Const $BARBAROUS_SHORE_SIN_CHESTRUN_INFORMATIONS = 'Assassin Barbarous Shore chest run variant.' & @CRLF _
	& 'Permanent cover:' & @CRLF _
	& '- 1 Deadly Paradox + 2 Shadow Form for spell immunity' & @CRLF _
	& '- 3 Dwarven Stability as stance upkeep' & @CRLF _
	& '- 4 Dark Escape and 6 Dash as movement pair' & @CRLF _
	& '- 7 Death''s Charge and 8 Heart of Shadow for emergency healing'
Global Const $BARBAROUS_SHORE_SIN_FARM_DURATION = (8 * 60) * 1000

; Skill numbers
Global Const $BARBAROUS_SHORE_SIN_DEADLY_PARADOX = 1
Global Const $BARBAROUS_SHORE_SIN_SHADOWFORM = 2
Global Const $BARBAROUS_SHORE_SIN_DWARVEN_STABILITY = 3
Global Const $BARBAROUS_SHORE_SIN_DARK_ESCAPE = 4
Global Const $BARBAROUS_SHORE_SIN_I_AM_UNSTOPPABLE = 5
Global Const $BARBAROUS_SHORE_SIN_DASH = 6
Global Const $BARBAROUS_SHORE_SIN_DEATHS_CHARGE = 7
Global Const $BARBAROUS_SHORE_SIN_HEART_OF_SHADOW = 8

Global Const $BARBAROUS_SHORE_SIN_ID_KAHMU = $ID_KAHMU
Global Const $BARBAROUS_SHORE_SIN_ID_MELONNI = $ID_MELONNI
Global Const $BARBAROUS_SHORE_SIN_ID_MOX = $ID_MOX
Global Const $BARBAROUS_SHORE_SIN_ID_TAHLKORA = $ID_TAHLKORA
Global Const $BARBAROUS_SHORE_SIN_ID_MORGAHN = $ID_GENERAL_MORGAHN
Global Const $BARBAROUS_SHORE_SIN_ID_MOW = $ID_MASTER_OF_WHISPERS
Global Const $BARBAROUS_SHORE_SIN_ID_OLIAS = $ID_OLIAS

Global Const $BARBAROUS_SHORE_SIN_KAHMU_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_SIN_MELONNI_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_SIN_MOX_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_SIN_TAHLKORA_TEMPLATE = 'Owohoyz9FAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_SIN_MORGAHN_TEMPLATE = 'OQijEqmMKO0YAAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_SIN_MOW_TEMPLATE = 'OAlkUwG4RZmDNGAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_SIN_OLIAS_TEMPLATE = 'OAlkUwG4RZmDNGAAAAAAAAAAAAA'

Global Const $BARBAROUS_SHORE_SIN_HERO_KAHMU_INDEX = 1
Global Const $BARBAROUS_SHORE_SIN_HERO_MELONNI_INDEX = 2
Global Const $BARBAROUS_SHORE_SIN_HERO_MOX_INDEX = 3
Global Const $BARBAROUS_SHORE_SIN_HERO_TAHLKORA_INDEX = 4
Global Const $BARBAROUS_SHORE_SIN_HERO_MORGAHN_INDEX = 5
Global Const $BARBAROUS_SHORE_SIN_HERO_MOW_INDEX = 6
Global Const $BARBAROUS_SHORE_SIN_HERO_OLIAS_INDEX = 7
Global Const $BARBAROUS_SHORE_SIN_HERO_SUPPORT_SKILL = 1

Global Const $BARBAROUS_SHORE_SIN_PORTAL_FLAG_VERIFY_RANGE = 380
Global Const $BARBAROUS_SHORE_SIN_PORTAL_FLAG_MAX_RETRIES = 10
Global Const $BARBAROUS_SHORE_SIN_MH_CAST_INTERVAL_MS = 1000
Global Const $BARBAROUS_SHORE_SIN_CAUTERY_CAST_INTERVAL_MS = 5000
Global Const $BARBAROUS_SHORE_SIN_SUPPORT_DEBUG_VERBOSE = False
Global Const $BARBAROUS_SHORE_SIN_SF_RECAST_BUFFER_MS = 3600
Global Const $BARBAROUS_SHORE_SIN_SF_ENERGY_RESERVE = 20
Global Const $BARBAROUS_SHORE_SIN_SF_CRITICAL_WINDOW_MS = 7000
Global Const $BARBAROUS_SHORE_SIN_DWARVEN_UPKEEP_BUFFER_MS = 2500
Global Const $BARBAROUS_SHORE_SIN_CHEST_HOTSPOT_RANGE = $RANGE_COMPASS + 450
Global Const $BARBAROUS_SHORE_SIN_CHEST_OPEN_RANGE = $RANGE_COMPASS + 300
Global Const $BARBAROUS_SHORE_SIN_LIVE_CHEST_SCAN_INTERVAL_MS = 700
Global Const $BARBAROUS_SHORE_SIN_STUCK_MIN_MOVEMENT = 20
Global Const $BARBAROUS_SHORE_SIN_STUCK_TICKS = 4
Global Const $BARBAROUS_SHORE_SIN_DARK_ESCAPE_AFTER_DASH_MS = 2200
Global Const $BARBAROUS_SHORE_SIN_DASH_AFTER_DARK_ESCAPE_MS = 10000
Global Const $BARBAROUS_SHORE_SIN_BYPASS_SIDE_STEP = 520
Global Const $BARBAROUS_SHORE_SIN_BYPASS_TARGET_STEP = 340
Global Const $BARBAROUS_SHORE_SIN_ROUTE_OPTIMIZE_WINDOW = 8
Global Const $BARBAROUS_SHORE_SIN_ROUTE_2OPT_WINDOW = 10
Global Const $BARBAROUS_SHORE_SIN_ROUTE_2OPT_PASSES = 2
Global Const $BARBAROUS_SHORE_SIN_ROUTE_2OPT_MARGIN_SQ = 250000
Global Const $BARBAROUS_SHORE_SIN_ENABLE_ROUTE_REORDER = False
Global Const $BARBAROUS_SHORE_SIN_TIMING_LOG = True
Global Const $BARBAROUS_SHORE_SIN_SKIP_HERO_TEMPLATE_LOAD = True
Global Const $BARBAROUS_SHORE_SIN_EXPAND_HERO_PANELS = True

Global $barbarous_shore_sin_farm_setup = False
Global $barbarous_shore_sin_support_enabled = False
Global $barbarous_shore_sin_next_mh_tick = 0
Global $barbarous_shore_sin_next_cautery_tick = 0
Global $barbarous_shore_sin_mh_rotation_index = 0
Global $barbarous_shore_sin_cautery_rotation_index = 0
Global $barbarous_shore_sin_kahmu_index = $BARBAROUS_SHORE_SIN_HERO_KAHMU_INDEX
Global $barbarous_shore_sin_melonni_index = $BARBAROUS_SHORE_SIN_HERO_MELONNI_INDEX
Global $barbarous_shore_sin_mox_index = $BARBAROUS_SHORE_SIN_HERO_MOX_INDEX
Global $barbarous_shore_sin_tahlkora_index = $BARBAROUS_SHORE_SIN_HERO_TAHLKORA_INDEX
Global $barbarous_shore_sin_morgahn_index = $BARBAROUS_SHORE_SIN_HERO_MORGAHN_INDEX
Global $barbarous_shore_sin_mow_index = $BARBAROUS_SHORE_SIN_HERO_MOW_INDEX
Global $barbarous_shore_sin_olias_index = $BARBAROUS_SHORE_SIN_HERO_OLIAS_INDEX
Global $barbarous_shore_sin_portal_anchor_x = 0
Global $barbarous_shore_sin_portal_anchor_y = 0


Func BarbarousShoreSinChestFarm()
	If Not $barbarous_shore_sin_farm_setup Then SetupBarbarousShoreSinChestFarm()

	GoToBarbarousShore()
	Local $result = BarbarousShoreSinChestFarmLoop()
	ResignAndReturnToOutpost($ID_CAMP_HOJANU)
	Return $result
EndFunc


Func SetupBarbarousShoreSinChestFarm()
	Info('Setting up Barbarous Shore Sin farm')
	Local $setupTimer = TimerInit()
	Local $stepTimer = TimerInit()
	TravelToOutpost($ID_CAMP_HOJANU, $district_name)
	BarbarousShoreSinLogTiming('setup.travel_to_outpost', $stepTimer)

	$stepTimer = TimerInit()
	SetupPlayerBarbarousShoreSinChestFarm()
	BarbarousShoreSinLogTiming('setup.player_build', $stepTimer)
	$stepTimer = TimerInit()
	SetupTeamBarbarousShoreSinChestFarm()
	BarbarousShoreSinLogTiming('setup.team_build', $stepTimer)

	$stepTimer = TimerInit()
	SwitchMode($ID_NORMAL_MODE)
	BarbarousShoreSinLogTiming('setup.switch_mode', $stepTimer)
	$barbarous_shore_sin_farm_setup = True
	BarbarousShoreSinLogTiming('setup.total', $setupTimer)
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerBarbarousShoreSinChestFarm()
	Info('Setting up player build skill bar')
	Local $timer = TimerInit()
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
		If BarbarousShoreSinHasExpectedPlayerBuild() Then
			BarbarousShoreSinLogTiming('setup.player_build.skip_template_already_loaded', $timer)
		Else
			LoadSkillTemplate($BARBAROUS_SHORE_SIN_CHESTRUNNER_SKILLBAR)
			RandomSleep(250)
			BarbarousShoreSinLogTiming('setup.player_build.load_template', $timer)
		EndIf
	Else
		Warn('Should run this farm as assassin')
		BarbarousShoreSinLogTiming('setup.player_build.invalid_profession', $timer)
	EndIf
EndFunc


Func BarbarousShoreSinHasExpectedPlayerBuild()
	If GetSkillbarSkillID(1) <> $ID_DEADLY_PARADOX Then Return False
	If GetSkillbarSkillID(2) <> $ID_SHADOW_FORM Then Return False
	If GetSkillbarSkillID(3) <> $ID_DWARVEN_STABILITY Then Return False
	If GetSkillbarSkillID(4) <> $ID_DARK_ESCAPE Then Return False
	If GetSkillbarSkillID(5) <> $ID_I_AM_UNSTOPPABLE Then Return False
	If GetSkillbarSkillID(6) <> $ID_DASH Then Return False
	If GetSkillbarSkillID(7) <> $ID_DEATHS_CHARGE Then Return False
	If GetSkillbarSkillID(8) <> $ID_HEART_OF_SHADOW Then Return False
	Return True
EndFunc


Func SetupTeamBarbarousShoreSinChestFarm()
	Info('Setting up fixed support team for Barbarous Shore Sin chest run')
	Local $stepTimer = TimerInit()
	SupportTeamKickAllHeroesByIDSweep()
	LeaveParty()
	AddHero($BARBAROUS_SHORE_SIN_ID_KAHMU)
	AddHero($BARBAROUS_SHORE_SIN_ID_MELONNI)
	AddHero($BARBAROUS_SHORE_SIN_ID_MOX)
	AddHero($BARBAROUS_SHORE_SIN_ID_TAHLKORA)
	AddHero($BARBAROUS_SHORE_SIN_ID_MORGAHN)
	AddHero($BARBAROUS_SHORE_SIN_ID_MOW)
	AddHero($BARBAROUS_SHORE_SIN_ID_OLIAS)
	RandomSleep(500)
	BarbarousShoreSinLogTiming('setup.team_build.party_compose', $stepTimer)

	$stepTimer = TimerInit()
	Local $requiredHeroes[] = [$BARBAROUS_SHORE_SIN_ID_KAHMU, $BARBAROUS_SHORE_SIN_ID_MELONNI, $BARBAROUS_SHORE_SIN_ID_MOX, $BARBAROUS_SHORE_SIN_ID_TAHLKORA, $BARBAROUS_SHORE_SIN_ID_MORGAHN, $BARBAROUS_SHORE_SIN_ID_MOW, $BARBAROUS_SHORE_SIN_ID_OLIAS]
	If Not SupportTeamHasExactHeroes($requiredHeroes, 8) Then
		Warn('Party not set up correctly. Team size different than 8')
		$barbarous_shore_sin_support_enabled = False
		Return $FAIL
	EndIf
	BarbarousShoreSinLogTiming('setup.team_build.verify_party', $stepTimer)

	$stepTimer = TimerInit()
	$barbarous_shore_sin_kahmu_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_SIN_ID_KAHMU, $BARBAROUS_SHORE_SIN_HERO_KAHMU_INDEX)
	$barbarous_shore_sin_melonni_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_SIN_ID_MELONNI, $BARBAROUS_SHORE_SIN_HERO_MELONNI_INDEX)
	$barbarous_shore_sin_mox_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_SIN_ID_MOX, $BARBAROUS_SHORE_SIN_HERO_MOX_INDEX)
	$barbarous_shore_sin_tahlkora_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_SIN_ID_TAHLKORA, $BARBAROUS_SHORE_SIN_HERO_TAHLKORA_INDEX)
	$barbarous_shore_sin_morgahn_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_SIN_ID_MORGAHN, $BARBAROUS_SHORE_SIN_HERO_MORGAHN_INDEX)
	$barbarous_shore_sin_mow_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_SIN_ID_MOW, $BARBAROUS_SHORE_SIN_HERO_MOW_INDEX)
	$barbarous_shore_sin_olias_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_SIN_ID_OLIAS, $BARBAROUS_SHORE_SIN_HERO_OLIAS_INDEX)
	BarbarousShoreSinLogTiming('setup.team_build.resolve_indexes', $stepTimer)

	$stepTimer = TimerInit()
	If $BARBAROUS_SHORE_SIN_SKIP_HERO_TEMPLATE_LOAD Then
		BarbarousShoreSinLogTiming('setup.team_build.skip_load_templates', $stepTimer)
	Else
		LoadSkillTemplate($BARBAROUS_SHORE_SIN_KAHMU_TEMPLATE, $barbarous_shore_sin_kahmu_index)
		RandomSleep(150)
		LoadSkillTemplate($BARBAROUS_SHORE_SIN_MELONNI_TEMPLATE, $barbarous_shore_sin_melonni_index)
		RandomSleep(150)
		LoadSkillTemplate($BARBAROUS_SHORE_SIN_MOX_TEMPLATE, $barbarous_shore_sin_mox_index)
		RandomSleep(150)
		LoadSkillTemplate($BARBAROUS_SHORE_SIN_TAHLKORA_TEMPLATE, $barbarous_shore_sin_tahlkora_index)
		RandomSleep(150)
		LoadSkillTemplate($BARBAROUS_SHORE_SIN_MORGAHN_TEMPLATE, $barbarous_shore_sin_morgahn_index)
		RandomSleep(150)
		LoadSkillTemplate($BARBAROUS_SHORE_SIN_MOW_TEMPLATE, $barbarous_shore_sin_mow_index)
		RandomSleep(150)
		LoadSkillTemplate($BARBAROUS_SHORE_SIN_OLIAS_TEMPLATE, $barbarous_shore_sin_olias_index)
		RandomSleep(250)
		BarbarousShoreSinLogTiming('setup.team_build.load_templates', $stepTimer)
	EndIf

	$stepTimer = TimerInit()
	DisableAllHeroSkills($barbarous_shore_sin_kahmu_index)
	DisableAllHeroSkills($barbarous_shore_sin_melonni_index)
	DisableAllHeroSkills($barbarous_shore_sin_mox_index)
	DisableAllHeroSkills($barbarous_shore_sin_tahlkora_index)
	DisableAllHeroSkills($barbarous_shore_sin_morgahn_index)
	DisableAllHeroSkills($barbarous_shore_sin_mow_index)
	DisableAllHeroSkills($barbarous_shore_sin_olias_index)
	EnableHeroSkillSlot($barbarous_shore_sin_kahmu_index, $BARBAROUS_SHORE_SIN_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_sin_melonni_index, $BARBAROUS_SHORE_SIN_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_sin_mox_index, $BARBAROUS_SHORE_SIN_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_sin_tahlkora_index, $BARBAROUS_SHORE_SIN_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_sin_morgahn_index, $BARBAROUS_SHORE_SIN_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_sin_mow_index, $BARBAROUS_SHORE_SIN_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_sin_olias_index, $BARBAROUS_SHORE_SIN_HERO_SUPPORT_SKILL)
	BarbarousShoreSinLogTiming('setup.team_build.configure_skills', $stepTimer)

	$stepTimer = TimerInit()
	ResetBarbarousShoreSinHeroSupportScheduler()
	$barbarous_shore_sin_support_enabled = True
	BarbarousShoreSinLogTiming('setup.team_build.finalize', $stepTimer)

	If $BARBAROUS_SHORE_SIN_EXPAND_HERO_PANELS Then
		$stepTimer = TimerInit()
		SupportTeamOpenHeroPanels('Barbarous Shore Sin')
		BarbarousShoreSinLogTiming('setup.team_build.open_hero_panels', $stepTimer)
	EndIf
	Return $SUCCESS
EndFunc


Func BarbarousShoreSinLogTiming($label, $timer)
	If Not $BARBAROUS_SHORE_SIN_TIMING_LOG Then Return
	Info('Barbarous timing: ' & $label & '=' & Int(TimerDiff($timer)) & 'ms')
EndFunc


Func GoToBarbarousShore()
	TravelToOutpost($ID_CAMP_HOJANU, $district_name)
	While GetMapID() <> $ID_BARBAROUS_SHORE
		Info('Moving to Barbarous Shore')
		MoveTo(-17236, 17474)
		MoveTo(-15948, 18021)
		MoveTo(-14576, 18262)
		Move(-14012, 18242)
		RandomSleep(1000)
		WaitMapLoading($ID_BARBAROUS_SHORE, 10000, 2000)
	WEnd
	ClearChestsMap()
	CaptureBarbarousShoreSinPortalAnchor()
	FlagBarbarousShoreSinSupportHeroesAtPortal()
EndFunc


Func ResetBarbarousShoreSinHeroSupportScheduler()
	$barbarous_shore_sin_next_mh_tick = 0
	$barbarous_shore_sin_next_cautery_tick = 0
	$barbarous_shore_sin_mh_rotation_index = 0
	$barbarous_shore_sin_cautery_rotation_index = 0
EndFunc


Func FlagBarbarousShoreSinSupportHeroesAtPortal()
	If Not $barbarous_shore_sin_support_enabled Then Return
	If GetMapID() <> $ID_BARBAROUS_SHORE Then Return

	Local $flagX = $barbarous_shore_sin_portal_anchor_x
	Local $flagY = $barbarous_shore_sin_portal_anchor_y
	If $flagX == 0 And $flagY == 0 Then
		CaptureBarbarousShoreSinPortalAnchor()
		$flagX = $barbarous_shore_sin_portal_anchor_x
		$flagY = $barbarous_shore_sin_portal_anchor_y
	EndIf

	SupportTeamDebug($BARBAROUS_SHORE_SIN_SUPPORT_DEBUG_VERBOSE, 'Barbarous support: flag heroes at portal X=' & $flagX & ' Y=' & $flagY)
	For $i = 1 To $BARBAROUS_SHORE_SIN_PORTAL_FLAG_MAX_RETRIES
		BarbarousShoreSinCommandAllSupportHeroesTo($flagX, $flagY)
		RandomSleep(140)
		If BarbarousShoreSinAreAllSupportHeroesAt($flagX, $flagY, $BARBAROUS_SHORE_SIN_PORTAL_FLAG_VERIFY_RANGE) Then Return
	Next
	Warn('Barbarous support: not all heroes reached portal flag before run start')
EndFunc


Func CaptureBarbarousShoreSinPortalAnchor()
	If GetMapID() <> $ID_BARBAROUS_SHORE Then Return
	Local $me = GetMyAgent()
	If $me == Null Then Return
	$barbarous_shore_sin_portal_anchor_x = Int(DllStructGetData($me, 'X'))
	$barbarous_shore_sin_portal_anchor_y = Int(DllStructGetData($me, 'Y'))
	SupportTeamDebug($BARBAROUS_SHORE_SIN_SUPPORT_DEBUG_VERBOSE, 'Barbarous support: captured portal anchor X=' & $barbarous_shore_sin_portal_anchor_x & ' Y=' & $barbarous_shore_sin_portal_anchor_y)
EndFunc


Func BarbarousShoreSinCommandAllSupportHeroesTo($x, $y)
	CommandHero($barbarous_shore_sin_kahmu_index, $x, $y)
	CommandHero($barbarous_shore_sin_melonni_index, $x, $y)
	CommandHero($barbarous_shore_sin_mox_index, $x, $y)
	CommandHero($barbarous_shore_sin_tahlkora_index, $x, $y)
	CommandHero($barbarous_shore_sin_morgahn_index, $x, $y)
	CommandHero($barbarous_shore_sin_mow_index, $x, $y)
	CommandHero($barbarous_shore_sin_olias_index, $x, $y)
EndFunc


Func BarbarousShoreSinAreAllSupportHeroesAt($x, $y, $maxDist)
	If Not BarbarousShoreSinIsHeroAtFlag($barbarous_shore_sin_kahmu_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreSinIsHeroAtFlag($barbarous_shore_sin_melonni_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreSinIsHeroAtFlag($barbarous_shore_sin_mox_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreSinIsHeroAtFlag($barbarous_shore_sin_tahlkora_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreSinIsHeroAtFlag($barbarous_shore_sin_morgahn_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreSinIsHeroAtFlag($barbarous_shore_sin_mow_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreSinIsHeroAtFlag($barbarous_shore_sin_olias_index, $x, $y, $maxDist) Then Return False
	Return True
EndFunc


Func BarbarousShoreSinIsHeroAtFlag($heroIndex, $x, $y, $maxDist)
	If $heroIndex <= 0 Then Return False
	Local $heroAgent = GetAgentByID(GetHeroID($heroIndex))
	If $heroAgent == Null Then Return False
	Return GetDistanceToPoint($heroAgent, $x, $y) <= $maxDist
EndFunc


Func TickBarbarousShoreSinHeroSupportCasts()
	If Not $barbarous_shore_sin_support_enabled Then Return
	If GetMapID() <> $ID_BARBAROUS_SHORE Then Return
	Local $mhOrder[] = [$barbarous_shore_sin_melonni_index, $barbarous_shore_sin_kahmu_index, $barbarous_shore_sin_mox_index, $barbarous_shore_sin_tahlkora_index]
	Local $cauteryOrder[] = [$barbarous_shore_sin_morgahn_index, $barbarous_shore_sin_mow_index, $barbarous_shore_sin_olias_index]

	If $barbarous_shore_sin_next_mh_tick == 0 Or TimerDiff($barbarous_shore_sin_next_mh_tick) >= $BARBAROUS_SHORE_SIN_MH_CAST_INTERVAL_MS Then
		Local $mhCount = UBound($mhOrder)
		For $i = 0 To $mhCount - 1
			Local $mhPos = Mod($barbarous_shore_sin_mh_rotation_index + $i, $mhCount)
			Local $mhHero = $mhOrder[$mhPos]
			If IsRecharged($BARBAROUS_SHORE_SIN_HERO_SUPPORT_SKILL, $mhHero) Then
				SupportTeamDebug($BARBAROUS_SHORE_SIN_SUPPORT_DEBUG_VERBOSE, 'Barbarous support: MH cast hero index=' & $mhHero)
				UseHeroSkill($mhHero, $BARBAROUS_SHORE_SIN_HERO_SUPPORT_SKILL)
				$barbarous_shore_sin_mh_rotation_index = Mod($mhPos + 1, $mhCount)
				$barbarous_shore_sin_next_mh_tick = TimerInit()
				ExitLoop
			EndIf
		Next
	EndIf

	If $barbarous_shore_sin_next_cautery_tick == 0 Or TimerDiff($barbarous_shore_sin_next_cautery_tick) >= $BARBAROUS_SHORE_SIN_CAUTERY_CAST_INTERVAL_MS Then
		Local $cauteryCount = UBound($cauteryOrder)
		For $i = 0 To $cauteryCount - 1
			Local $cauteryPos = Mod($barbarous_shore_sin_cautery_rotation_index + $i, $cauteryCount)
			Local $cauteryHero = $cauteryOrder[$cauteryPos]
			If IsRecharged($BARBAROUS_SHORE_SIN_HERO_SUPPORT_SKILL, $cauteryHero) Then
				SupportTeamDebug($BARBAROUS_SHORE_SIN_SUPPORT_DEBUG_VERBOSE, 'Barbarous support: Cautery cast hero index=' & $cauteryHero)
				UseHeroSkill($cauteryHero, $BARBAROUS_SHORE_SIN_HERO_SUPPORT_SKILL)
				$barbarous_shore_sin_cautery_rotation_index = Mod($cauteryPos + 1, $cauteryCount)
				$barbarous_shore_sin_next_cautery_tick = TimerInit()
				ExitLoop
			EndIf
		Next
	EndIf
EndFunc


Func BarbarousShoreSinChestFarmLoop()
	If FindInInventory($ID_LOCKPICK)[0] == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf

	If GetMapID() <> $ID_BARBAROUS_SHORE Then Return $FAIL
	Info('Starting chest farm run')
	ClearChestsMap()
	FlagBarbarousShoreSinSupportHeroesAtPortal()
	ResetBarbarousShoreSinHeroSupportScheduler()

	Local $openedChests = 0
	Local $waypoints[][2] = [ _
		[-12830, 17372], [-12174, 16706], [-11841, 15849], [-11915, 14928], [-12225, 14039], _
		[-12654, 13212], [-13033, 12350], [-13080, 11439], [-13673, 10698], [-14066, 9837], _
		[-14366, 8944], [-14628, 8037], [-14546, 7110], [-14722, 6186], [-15056, 5278], _
		[-15467, 4407], [-15857, 3538], [-16184, 2609], [-16384, 1673], [-15826, 924], _
		[-15055, 408], [-14477, -284], [-14154, -1183], [-13858, -2084], [-13483, -2955], _
		[-13021, -3736], [-12623, -4587], [-12304, -5457], [-12095, -6334], [-11850, -7245], _
		[-11599, -8123], [-11805, -9048], [-11919, -9971], [-12099, -10862], [-11432, -11471], _
		[-10552, -11716], [-9773, -11179], [-9269, -10375], [-8897, -9507], [-8498, -8621], _
		[-7968, -7893], [-7114, -7519], [-6162, -7374], [-5249, -7177], [-4629, -6517], _
		[-4578, -5352], [-3841, -4784], [-3891, -3884], [-4602, -3268], [-4501, -2326], _
		[-3563, -2429], [-3046, -3194], [-2250, -3709], [-1748, -4481], [-886, -4183], _
		[-383, -3423], [221, -2742], [1161, -2832], [1778, -3528], [2194, -4361], _
		[2483, -5270], [3077, -5996], [3908, -6461], [4683, -6958], [5346, -7622], _
		[6273, -7526], [6608, -6641], [6987, -5777], [7636, -5105], [8462, -4704], _
		[9399, -4668], [10192, -5148], [11111, -5174], [12081, -5030], [12958, -4768], _
		[13705, -4241], [14607, -4518], [15446, -4962], [15386, -4024], [15441, -3078], _
		[14807, -2381], [14100, -1727], [13363, -1103], [13281, -179], [12734, 567], _
		[12045, 1197], [11843, 2090], [10941, 2119], [10207, 2664], [9740, 3474], _
		[9700, 4428], [9490, 5343], [9976, 6147], [10533, 6895], [11126, 7640], _
		[11323, 8565], [10915, 9422], [10319, 10138], [9703, 10871], [9093, 11571], _
		[8456, 12283], [7610, 12699], [6692, 12562], [6166, 11780], [5659, 10995], _
		[5126, 10233], [4333, 9785], [3470, 9464], [2540, 9517], [1645, 9755], _
		[814, 9378], [343, 8594], [-238, 7831], [-1090, 7444], [-1991, 7328], _
		[-2913, 7197], [-3768, 7603], [-4097, 8501], [-3938, 9388], [-3636, 10283], _
		[-2991, 10971], [-2271, 11587], [-1522, 12195], [-748, 12698], [-326, 13556], _
		[34, 14400], [429, 15254], [-154, 16004], [-919, 16512], [-1836, 16696], _
		[-2761, 16876], [-3668, 17042], [-4616, 16965] _
	]

	Local $spotCount = UBound($waypoints)
	If $BARBAROUS_SHORE_SIN_ENABLE_ROUTE_REORDER Then BarbarousShoreSinOptimizeWaypointRoute($waypoints)
	Local $i = 0
	While $i < $spotCount
		If IsPlayerDead() Then
			Warn('Barbarous run: player dead, aborting run for resign/restart')
			Return $FAIL
		EndIf

		Info('Running to Spot #' & ($i + 1) & '/' & $spotCount)

		If BarbarousShoreSinOpenChestNearPoint($waypoints[$i][0], $waypoints[$i][1]) Then
			$openedChests += 1
			$i = BarbarousShoreSinAdvanceRouteAfterChest($waypoints, $i)
			ContinueLoop
		EndIf

		If BarbarousShoreSinRunToWaypointWithBypass($waypoints[$i][0], $waypoints[$i][1]) == $FAIL Then
			If IsPlayerDead() Then
				Warn('Barbarous run: player dead while moving, aborting run for resign/restart')
				Return $FAIL
			EndIf
			Warn('Barbarous pathing: skipped blocked spot #' & ($i + 1))
			$i += 1
			ContinueLoop
		EndIf

		If FindAndOpenChests($BARBAROUS_SHORE_SIN_CHEST_OPEN_RANGE, DefendWhileOpeningChestsBarbarousShoreSin) Then
			$openedChests += 1
			$i = BarbarousShoreSinAdvanceRouteAfterChest($waypoints, $i)
			ContinueLoop
		EndIf

		If IsPlayerDead() Then
			Warn('Barbarous run: player dead after chest interaction, aborting run for resign/restart')
			Return $FAIL
		EndIf

		If BarbarousShoreSinOpenChestNearPoint($waypoints[$i][0], $waypoints[$i][1]) Then
			$openedChests += 1
			$i = BarbarousShoreSinAdvanceRouteAfterChest($waypoints, $i)
			ContinueLoop
		EndIf

		$i += 1
	WEnd

	Info('Opened ' & $openedChests & ' chests.')
	Return $openedChests > 0 And IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func BarbarousShoreSinOptimizeWaypointRoute(ByRef $waypoints)
	Local $count = UBound($waypoints)
	If $count < 4 Then Return

	Local $oldLength = BarbarousShoreSinEstimateWaypointRouteLength($waypoints)

	Local $i
	For $i = 0 To $count - 2
		Local $bestIdx = $i + 1
		Local $bestDistSq = BarbarousShoreSinDistanceSq($waypoints[$i][0], $waypoints[$i][1], $waypoints[$bestIdx][0], $waypoints[$bestIdx][1])
		Local $maxJ = $i + $BARBAROUS_SHORE_SIN_ROUTE_OPTIMIZE_WINDOW
		If $maxJ > ($count - 1) Then $maxJ = $count - 1

		Local $j
		For $j = $i + 2 To $maxJ
			Local $distSq = BarbarousShoreSinDistanceSq($waypoints[$i][0], $waypoints[$i][1], $waypoints[$j][0], $waypoints[$j][1])
			If $distSq < $bestDistSq Then
				$bestDistSq = $distSq
				$bestIdx = $j
			EndIf
		Next

		If $bestIdx <> ($i + 1) Then BarbarousShoreSinSwapWaypoints($waypoints, $i + 1, $bestIdx)
	Next

	Local $pass
	For $pass = 1 To $BARBAROUS_SHORE_SIN_ROUTE_2OPT_PASSES
		Local $improved = False
		For $i = 0 To $count - 4
			Local $maxK = $i + $BARBAROUS_SHORE_SIN_ROUTE_2OPT_WINDOW
			If $maxK > ($count - 2) Then $maxK = $count - 2

			Local $k
			For $k = $i + 2 To $maxK
				Local $oldDistSq = BarbarousShoreSinDistanceSq($waypoints[$i][0], $waypoints[$i][1], $waypoints[$i + 1][0], $waypoints[$i + 1][1]) _
					+ BarbarousShoreSinDistanceSq($waypoints[$k][0], $waypoints[$k][1], $waypoints[$k + 1][0], $waypoints[$k + 1][1])
				Local $newDistSq = BarbarousShoreSinDistanceSq($waypoints[$i][0], $waypoints[$i][1], $waypoints[$k][0], $waypoints[$k][1]) _
					+ BarbarousShoreSinDistanceSq($waypoints[$i + 1][0], $waypoints[$i + 1][1], $waypoints[$k + 1][0], $waypoints[$k + 1][1])

				If $newDistSq + $BARBAROUS_SHORE_SIN_ROUTE_2OPT_MARGIN_SQ < $oldDistSq Then
					BarbarousShoreSinReverseWaypointSegment($waypoints, $i + 1, $k)
					$improved = True
				EndIf
			Next
		Next

		If Not $improved Then ExitLoop
	Next

	Local $newLength = BarbarousShoreSinEstimateWaypointRouteLength($waypoints)
	If $newLength < $oldLength Then
		Info('Barbarous route optimized: ' & Int($oldLength) & ' -> ' & Int($newLength))
	EndIf
EndFunc


Func BarbarousShoreSinSwapWaypoints(ByRef $waypoints, $a, $b)
	If $a == $b Then Return
	Local $tmpX = $waypoints[$a][0]
	Local $tmpY = $waypoints[$a][1]
	$waypoints[$a][0] = $waypoints[$b][0]
	$waypoints[$a][1] = $waypoints[$b][1]
	$waypoints[$b][0] = $tmpX
	$waypoints[$b][1] = $tmpY
EndFunc


Func BarbarousShoreSinReverseWaypointSegment(ByRef $waypoints, $startIdx, $endIdx)
	While $startIdx < $endIdx
		BarbarousShoreSinSwapWaypoints($waypoints, $startIdx, $endIdx)
		$startIdx += 1
		$endIdx -= 1
	WEnd
EndFunc


Func BarbarousShoreSinDistanceSq($x1, $y1, $x2, $y2)
	Local $dx = $x1 - $x2
	Local $dy = $y1 - $y2
	Return ($dx * $dx) + ($dy * $dy)
EndFunc


Func BarbarousShoreSinEstimateWaypointRouteLength(ByRef $waypoints)
	Local $count = UBound($waypoints)
	If $count < 2 Then Return 0

	Local $total = 0
	Local $i
	For $i = 0 To $count - 2
		$total += Sqrt(BarbarousShoreSinDistanceSq($waypoints[$i][0], $waypoints[$i][1], $waypoints[$i + 1][0], $waypoints[$i + 1][1]))
	Next
	Return $total
EndFunc


Func BarbarousShoreSinOpenChestNearPoint($x, $y)
	Local $chest = ScanForChests($BARBAROUS_SHORE_SIN_CHEST_HOTSPOT_RANGE, True, $x, $y)
	If $chest == Null Then Return False

	Local $chestX = DllStructGetData($chest, 'X')
	Local $chestY = DllStructGetData($chest, 'Y')
	If BarbarousShoreSinRunToWaypointWithBypass($chestX, $chestY) == $FAIL Then Return False
	Return FindAndOpenChests($BARBAROUS_SHORE_SIN_CHEST_OPEN_RANGE, DefendWhileOpeningChestsBarbarousShoreSin)
EndFunc



Func BarbarousShoreSinRunToWaypointWithBypass($targetX, $targetY)
	If AssassinRunBarbarousShore($targetX, $targetY) == $SUCCESS Then Return $SUCCESS

	; Try both sides around local obstacles (rocks/bodyblock) before giving up.
	If BarbarousShoreSinTrySideBypassPath($targetX, $targetY, 1) Then Return $SUCCESS
	If BarbarousShoreSinTrySideBypassPath($targetX, $targetY, -1) Then Return $SUCCESS

	Return $FAIL
EndFunc


Func BarbarousShoreSinTrySideBypassPath($targetX, $targetY, $sideSign)
	Local $me = GetMyAgent()
	If $me == Null Then Return False

	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $dx = $targetX - $myX
	Local $dy = $targetY - $myY
	Local $len = Sqrt(($dx * $dx) + ($dy * $dy))
	If $len < 1 Then Return False

	Local $rightX = $dy / $len
	Local $rightY = -$dx / $len
	Local $pivotX = $myX + ($rightX * $sideSign * $BARBAROUS_SHORE_SIN_BYPASS_SIDE_STEP)
	Local $pivotY = $myY + ($rightY * $sideSign * $BARBAROUS_SHORE_SIN_BYPASS_SIDE_STEP)
	Local $approachX = $targetX + ($rightX * $sideSign * $BARBAROUS_SHORE_SIN_BYPASS_TARGET_STEP)
	Local $approachY = $targetY + ($rightY * $sideSign * $BARBAROUS_SHORE_SIN_BYPASS_TARGET_STEP)

	If AssassinRunBarbarousShore($pivotX, $pivotY) == $FAIL Then Return False
	If AssassinRunBarbarousShore($approachX, $approachY) == $FAIL Then Return False
	Return AssassinRunBarbarousShore($targetX, $targetY) == $SUCCESS
EndFunc


Func BarbarousShoreSinAdvanceRouteAfterChest(ByRef $waypoints, $currentIdx)
	Local $nextIdx = BarbarousShoreSinFindBestForwardJoinPoint($waypoints, $currentIdx + 1)
	If $nextIdx < 0 Then Return UBound($waypoints)
	Return $nextIdx
EndFunc


Func BarbarousShoreSinFindBestForwardJoinPoint(ByRef $waypoints, $startIdx)
	Local $me = GetMyAgent()
	If $me == Null Then Return -1

	Local $count = UBound($waypoints)
	If $startIdx < 0 Then $startIdx = 0
	If $startIdx >= ($count - 1) Then Return $startIdx < $count ? $startIdx : -1

	Local $meX = DllStructGetData($me, 'X')
	Local $meY = DllStructGetData($me, 'Y')
	Local $bestSeg = $startIdx
	Local $bestDistSq = 1e+30

	Local $i
	For $i = $startIdx To $count - 2
		Local $distSq = BarbarousShoreSinPointToSegmentDistanceSq($meX, $meY, $waypoints[$i][0], $waypoints[$i][1], $waypoints[$i + 1][0], $waypoints[$i + 1][1])
		If $distSq < $bestDistSq Then
			$bestDistSq = $distSq
			$bestSeg = $i
		EndIf
	Next

	Local $joinIdx = $bestSeg + 1
	If $joinIdx >= $count Then $joinIdx = $count - 1

	If GetDistanceToPoint($me, $waypoints[$joinIdx][0], $waypoints[$joinIdx][1]) > 120 Then
		AssassinRunBarbarousShore($waypoints[$joinIdx][0], $waypoints[$joinIdx][1])
	EndIf
	Return $joinIdx
EndFunc


Func BarbarousShoreSinPointToSegmentDistanceSq($px, $py, $ax, $ay, $bx, $by)
	Local $abx = $bx - $ax
	Local $aby = $by - $ay
	Local $abLenSq = ($abx * $abx) + ($aby * $aby)
	If $abLenSq <= 0 Then Return BarbarousShoreSinDistanceSq($px, $py, $ax, $ay)

	Local $apx = $px - $ax
	Local $apy = $py - $ay
	Local $t = (($apx * $abx) + ($apy * $aby)) / $abLenSq
	If $t < 0 Then
		$t = 0
	ElseIf $t > 1 Then
		$t = 1
	EndIf

	Local $projX = $ax + ($abx * $t)
	Local $projY = $ay + ($aby * $t)
	Return BarbarousShoreSinDistanceSq($px, $py, $projX, $projY)
EndFunc


Func AssassinRunBarbarousShore($x, $y)
	Move($x, $y)
	Local $blockedCounter = 0
	Local $me = GetMyAgent()
	Local $energy
	Local Static $lastDashUse = 0
	Local Static $lastDarkEscapeUse = 0
	Local Static $lastChestScan = 0
	IsPlayerStuck(Default, Default, True)

	While GetDistanceToPoint($me, $x, $y) > 100 And $blockedCounter < 15
		TickBarbarousShoreSinHeroSupportCasts()
		Local $sfRemaining = GetEffectTimeRemaining($ID_SHADOW_FORM)
		Local $energyNow = GetEnergy()
		Local $needSfRefresh = ($sfRemaining <= $BARBAROUS_SHORE_SIN_SF_RECAST_BUFFER_MS)
		Local $sfCritical = ($sfRemaining <= $BARBAROUS_SHORE_SIN_SF_CRITICAL_WINDOW_MS)

		If $needSfRefresh Then
			If IsRecharged($BARBAROUS_SHORE_SIN_SHADOWFORM) And $energyNow >= 20 Then
				; Prioritize 1 -> 2 chain whenever possible for maximum SF coverage.
				If IsRecharged($BARBAROUS_SHORE_SIN_DEADLY_PARADOX) And $energyNow >= 25 Then
					UseSkillEx($BARBAROUS_SHORE_SIN_DEADLY_PARADOX)
					RandomSleep(35)
				EndIf
				UseSkillEx($BARBAROUS_SHORE_SIN_SHADOWFORM)
				$sfRemaining = GetEffectTimeRemaining($ID_SHADOW_FORM)
				$needSfRefresh = ($sfRemaining <= $BARBAROUS_SHORE_SIN_SF_RECAST_BUFFER_MS)
				$sfCritical = ($sfRemaining <= $BARBAROUS_SHORE_SIN_SF_CRITICAL_WINDOW_MS)
				$energyNow = GetEnergy()
			EndIf
		EndIf

		If $lastChestScan == 0 Or TimerDiff($lastChestScan) >= $BARBAROUS_SHORE_SIN_LIVE_CHEST_SCAN_INTERVAL_MS Then
			If FindAndOpenChests($BARBAROUS_SHORE_SIN_CHEST_OPEN_RANGE, DefendWhileOpeningChestsBarbarousShoreSin) Then
				$blockedCounter = 0
				Move($x, $y)
			EndIf
			$lastChestScan = TimerInit()
		EndIf

		If GetEffectTimeRemaining($ID_DWARVEN_STABILITY) <= $BARBAROUS_SHORE_SIN_DWARVEN_UPKEEP_BUFFER_MS And IsRecharged($BARBAROUS_SHORE_SIN_DWARVEN_STABILITY) And $energyNow >= 5 Then
			UseSkillEx($BARBAROUS_SHORE_SIN_DWARVEN_STABILITY)
			$energyNow = GetEnergy()
		EndIf

		If Not $sfCritical And $energyNow >= 5 And IsRecharged($BARBAROUS_SHORE_SIN_I_AM_UNSTOPPABLE) And GetEffect($ID_CRIPPLED) <> Null Then
			UseSkillEx($BARBAROUS_SHORE_SIN_I_AM_UNSTOPPABLE)
			$energyNow = GetEnergy()
		EndIf

		If Not $sfCritical And GetHealth() < 100 And $energyNow >= 5 And IsRecharged($BARBAROUS_SHORE_SIN_DEATHS_CHARGE) Then
			Local $target = GetTargetForDeathsChargeBarbarousShoreSin($x, $y, 700)
			If $target <> Null Then
				UseSkillEx($BARBAROUS_SHORE_SIN_DEATHS_CHARGE, $target)
				$energyNow = GetEnergy()
			EndIf
		EndIf

		$sfRemaining = GetEffectTimeRemaining($ID_SHADOW_FORM)
		$energyNow = GetEnergy()
		If $sfRemaining > $BARBAROUS_SHORE_SIN_SF_CRITICAL_WINDOW_MS And $energyNow > ($BARBAROUS_SHORE_SIN_SF_ENERGY_RESERVE + 5) Then
			If IsRecharged($BARBAROUS_SHORE_SIN_DARK_ESCAPE) And $lastDashUse <> 0 And TimerDiff($lastDashUse) >= $BARBAROUS_SHORE_SIN_DARK_ESCAPE_AFTER_DASH_MS Then
				If IsRecharged($BARBAROUS_SHORE_SIN_DWARVEN_STABILITY) And $energyNow >= 10 Then
					UseSkillEx($BARBAROUS_SHORE_SIN_DWARVEN_STABILITY)
					RandomSleep(25)
				EndIf
				UseSkillEx($BARBAROUS_SHORE_SIN_DARK_ESCAPE)
				$lastDarkEscapeUse = TimerInit()
			ElseIf IsRecharged($BARBAROUS_SHORE_SIN_DASH) And ($lastDarkEscapeUse == 0 Or TimerDiff($lastDarkEscapeUse) >= $BARBAROUS_SHORE_SIN_DASH_AFTER_DARK_ESCAPE_MS) Then
				If IsRecharged($BARBAROUS_SHORE_SIN_DWARVEN_STABILITY) And $energyNow >= 10 Then
					UseSkillEx($BARBAROUS_SHORE_SIN_DWARVEN_STABILITY)
					RandomSleep(25)
				EndIf
				UseSkillEx($BARBAROUS_SHORE_SIN_DASH)
				$lastDashUse = TimerInit()
			EndIf
		EndIf

		$energy = GetEnergy()

		$me = GetMyAgent()
		If Not IsPlayerMoving() Then
			$blockedCounter += 1
			Move($x, $y)
			If $blockedCounter >= 3 Then
				If BarbarousShoreSinTryBreakBodyblock($x, $y) Then
					$blockedCounter = 0
					IsPlayerStuck(Default, Default, True)
					Move($x, $y)
				EndIf
			EndIf
		EndIf

		If IsPlayerStuck($BARBAROUS_SHORE_SIN_STUCK_MIN_MOVEMENT, $BARBAROUS_SHORE_SIN_STUCK_TICKS) Then
			If BarbarousShoreSinTryBreakBodyblock($x, $y) Then
				$blockedCounter = 0
				IsPlayerStuck(Default, Default, True)
				Move($x, $y)
			EndIf
		ElseIf Not $sfCritical And GetHealth() < 100 And $energy >= 5 And IsRecharged($BARBAROUS_SHORE_SIN_HEART_OF_SHADOW) Then
			If $blockedCounter > 5 Then $blockedCounter = 0
			Local $npc = GetNPCInTheBackBarbarousShoreSin($x, $y)
			If $npc == Null Then $npc = $me
			UseSkillEx($BARBAROUS_SHORE_SIN_HEART_OF_SHADOW, $npc)
		EndIf

		RandomSleep(250)
		$me = GetMyAgent()
		If IsPlayerDead() Then Return $FAIL
	WEnd
	$me = GetMyAgent()
	If GetDistanceToPoint($me, $x, $y) > 100 Then Return $FAIL
	Return $SUCCESS
EndFunc


Func BarbarousShoreSinTryBreakBodyblock($targetX, $targetY)
	Local $me = GetMyAgent()
	If $me == Null Then Return False
	Local $startX = DllStructGetData($me, 'X')
	Local $startY = DllStructGetData($me, 'Y')

	Local $energy = GetEnergy()
	Local $sfRemaining = GetEffectTimeRemaining($ID_SHADOW_FORM)
	If $sfRemaining <= $BARBAROUS_SHORE_SIN_SF_RECAST_BUFFER_MS And IsRecharged($BARBAROUS_SHORE_SIN_SHADOWFORM) And $energy >= $BARBAROUS_SHORE_SIN_SF_ENERGY_RESERVE Then
		If IsRecharged($BARBAROUS_SHORE_SIN_DEADLY_PARADOX) And $energy >= 5 Then
			UseSkillEx($BARBAROUS_SHORE_SIN_DEADLY_PARADOX)
			RandomSleep(35)
		EndIf
		UseSkillEx($BARBAROUS_SHORE_SIN_SHADOWFORM)
		$energy = GetEnergy()
	EndIf

	If IsRecharged($BARBAROUS_SHORE_SIN_HEART_OF_SHADOW) And $energy >= 5 Then
		Local $npc = GetNPCInTheBackBarbarousShoreSin($targetX, $targetY)
		If $npc == Null Then $npc = $me
		UseSkillEx($BARBAROUS_SHORE_SIN_HEART_OF_SHADOW, $npc)
		RandomSleep(90)
		$energy = GetEnergy()
	EndIf

	If IsRecharged($BARBAROUS_SHORE_SIN_DEATHS_CHARGE) And $energy >= 5 Then
		Local $target = GetTargetForDeathsChargeBarbarousShoreSin($targetX, $targetY, 550)
		If $target <> Null Then
			UseSkillEx($BARBAROUS_SHORE_SIN_DEATHS_CHARGE, $target)
			RandomSleep(90)
		EndIf
	EndIf

	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $dx = $targetX - $myX
	Local $dy = $targetY - $myY
	Local $len = Sqrt(($dx * $dx) + ($dy * $dy))
	If $len < 1 Then Return False

	Local $rightX = $dy / $len
	Local $rightY = -$dx / $len
	Move($myX + ($rightX * $BARBAROUS_SHORE_SIN_BYPASS_SIDE_STEP), $myY + ($rightY * $BARBAROUS_SHORE_SIN_BYPASS_SIDE_STEP))
	RandomSleep(100)
	Move($myX - ($rightX * $BARBAROUS_SHORE_SIN_BYPASS_SIDE_STEP), $myY - ($rightY * $BARBAROUS_SHORE_SIN_BYPASS_SIDE_STEP))
	RandomSleep(100)
	Move($targetX, $targetY)
	RandomSleep(100)

	$me = GetMyAgent()
	If $me == Null Then Return False
	Return ComputeDistance($startX, $startY, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y')) >= 120
EndFunc


Func AreFoesInFrontBarbarousShoreSin($x, $y)
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST + 350)
	If Not IsArray($foes) Or UBound($foes) <= 0 Then Return False
	For $foe In $foes
		If (GetDistanceToPoint($me, $x, $y) - GetDistanceToPoint($foe, $x, $y)) > 0 Then Return True
	Next
	Return False
EndFunc


Func GetNPCInTheBackBarbarousShoreSin($x, $y)
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $npcs = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST)
	If Not IsArray($npcs) Or UBound($npcs) <= 0 Then Return Null
	Local $bestNpc = Null
	Local $minDot = 1

	Local $moveX = $x - $myX
	Local $moveY = $y - $myY
	Local $myMovementVector = Sqrt($moveX ^ 2 + $moveY ^ 2)
	If $myMovementVector = 0 Then Return Null
	$moveX /= $myMovementVector
	$moveY /= $myMovementVector

	For $npc In $npcs
		Local $npcMoveX = DllStructGetData($npc, 'X') - $myX
		Local $npcMoveY = DllStructGetData($npc, 'Y') - $myY
		Local $npcMovementVector = Sqrt($npcMoveX ^ 2 + $npcMoveY ^ 2)
		If $npcMovementVector = 0 Then ContinueLoop
		$npcMoveX /= $npcMovementVector
		$npcMoveY /= $npcMovementVector

		Local $dot = $npcMoveX * $moveX + $npcMoveY * $moveY
		If $dot < $minDot Then
			$minDot = $dot
			$bestNpc = $npc
		EndIf
	Next
	Return $bestNpc
EndFunc


Func GetTargetForDeathsChargeBarbarousShoreSin($x, $y, $distance = 700)
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST)
	If Not IsArray($foes) Or UBound($foes) <= 0 Then Return Null
	For $foe In $foes
		If (GetDistanceToPoint($me, $x, $y) - GetDistanceToPoint($foe, $x, $y)) > $distance Then Return $foe
	Next
	Return Null
EndFunc


Func DefendWhileOpeningChestsBarbarousShoreSin()
	TickBarbarousShoreSinHeroSupportCasts()
	Local $nearestFoe = GetNearestEnemyToAgent(GetMyAgent())
	If $nearestFoe == Null Then Return

	If GetEnergy() >= 5 And IsRecharged($BARBAROUS_SHORE_SIN_I_AM_UNSTOPPABLE) And GetEffect($ID_CRIPPLED) <> Null Then UseSkillEx($BARBAROUS_SHORE_SIN_I_AM_UNSTOPPABLE)
	If GetEnergy() >= 20 And IsRecharged($BARBAROUS_SHORE_SIN_SHADOWFORM) And GetDistance(GetMyAgent(), $nearestFoe) < ($RANGE_SPELLCAST + 200) Then
		UseSkillEx($BARBAROUS_SHORE_SIN_DEADLY_PARADOX)
		RandomSleep(20)
		UseSkillEx($BARBAROUS_SHORE_SIN_SHADOWFORM)
	EndIf
EndFunc
