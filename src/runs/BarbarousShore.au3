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
Global Const $BARBAROUS_SHORE_CHESTRUNNER_SKILLBAR = 'OwBj4xf84Q8I6M3lNQ0kTQ4OIQA'
Global Const $BARBAROUS_SHORE_CHESTRUN_INFORMATIONS = 'Assassin Barbarous Shore chest run variant.' & @CRLF _
	& 'Runs to a single chest spot and resigns when no chest spawned there' & @CRLF _
	& 'Permanent cover:' & @CRLF _
	& '- 1 Deadly Paradox + 2 Shadow Form for spell immunity' & @CRLF _
	& '- 3 Dwarven Stability as stance upkeep' & @CRLF _
	& '- 4 Dark Escape, 6 Dash fills its cooldown' & @CRLF _
	& '- 7 Death''s Charge and 8 Heart of Shadow for emergency healing'
Global Const $BARBAROUS_SHORE_FARM_DURATION = (8 * 60) * 1000

; Skill numbers
Global Const $BARBAROUS_SHORE_DEADLY_PARADOX = 1
Global Const $BARBAROUS_SHORE_SHADOWFORM = 2
Global Const $BARBAROUS_SHORE_DWARVEN_STABILITY = 3
Global Const $BARBAROUS_SHORE_DARK_ESCAPE = 4
Global Const $BARBAROUS_SHORE_I_AM_UNSTOPPABLE = 5
Global Const $BARBAROUS_SHORE_DASH = 6
Global Const $BARBAROUS_SHORE_DEATHS_CHARGE = 7
Global Const $BARBAROUS_SHORE_HEART_OF_SHADOW = 8

Global Const $BARBAROUS_SHORE_ID_KAHMU = $ID_KAHMU
Global Const $BARBAROUS_SHORE_ID_MELONNI = $ID_MELONNI
Global Const $BARBAROUS_SHORE_ID_MOX = $ID_MOX
Global Const $BARBAROUS_SHORE_ID_TAHLKORA = $ID_TAHLKORA
Global Const $BARBAROUS_SHORE_ID_MORGAHN = $ID_GENERAL_MORGAHN
Global Const $BARBAROUS_SHORE_ID_MOW = $ID_MASTER_OF_WHISPERS
Global Const $BARBAROUS_SHORE_ID_OLIAS = $ID_OLIAS

Global Const $BARBAROUS_SHORE_KAHMU_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_MELONNI_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_MOX_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_TAHLKORA_TEMPLATE = 'Owohoyz9FAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_MORGAHN_TEMPLATE = 'OQijEqmMKO0YAAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_MOW_TEMPLATE = 'OAlkUwG4RZmDNGAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_OLIAS_TEMPLATE = 'OAlkUwG4RZmDNGAAAAAAAAAAAAA'

Global Const $BARBAROUS_SHORE_HERO_KAHMU_INDEX = 1
Global Const $BARBAROUS_SHORE_HERO_MELONNI_INDEX = 2
Global Const $BARBAROUS_SHORE_HERO_MOX_INDEX = 3
Global Const $BARBAROUS_SHORE_HERO_TAHLKORA_INDEX = 4
Global Const $BARBAROUS_SHORE_HERO_MORGAHN_INDEX = 5
Global Const $BARBAROUS_SHORE_HERO_MOW_INDEX = 6
Global Const $BARBAROUS_SHORE_HERO_OLIAS_INDEX = 7
Global Const $BARBAROUS_SHORE_HERO_SUPPORT_SKILL = 1

Global Const $BARBAROUS_SHORE_PORTAL_FLAG_VERIFY_RANGE = 380
Global Const $BARBAROUS_SHORE_PORTAL_FLAG_MAX_RETRIES = 10
Global Const $BARBAROUS_SHORE_MH_CAST_INTERVAL_MS = 1000
Global Const $BARBAROUS_SHORE_CAUTERY_CAST_INTERVAL_MS = 5000
Global Const $BARBAROUS_SHORE_SUPPORT_DEBUG_VERBOSE = False
Global Const $BARBAROUS_SHORE_SF_LOGGING = True

;~ Perma Shadow Form, same rhythm as Focus Hanaku: request Shadow Form, then slip Deadly Paradox into its cast time
Global Const $BARBAROUS_SHORE_SF_DP_MIN_ENERGY = 20
Global Const $BARBAROUS_SHORE_DP_AFTER_SF_DELAY_MS = 500
Global Const $BARBAROUS_SHORE_SF_QUEUE_RETRY_MS = 250
Global Const $BARBAROUS_SHORE_IAU_MIN_ENERGY = 5
Global Const $BARBAROUS_SHORE_DWARVEN_STABILITY_CAST_MS = 800

;~ Single chest spot taken from the 2026-11-16 recording, plus the approach that was recorded
Global Const $BARBAROUS_SHORE_CHEST_OPEN_RANGE = $RANGE_COMPASS + 300
Global Const $BARBAROUS_SHORE_WAYPOINT_REACH_RANGE = 100
Global Const $BARBAROUS_SHORE_WAYPOINT_TIMEOUT_MS = 45000
Global Const $BARBAROUS_SHORE_APPROACH_TIMEOUT_MS = 5 * 60 * 1000
Global Const $BARBAROUS_SHORE_BLOCKED_TICKS_BEFORE_UNSTUCK = 3
Global Const $BARBAROUS_SHORE_BYPASS_SIDE_STEP = 520
Global Const $BARBAROUS_SHORE_TIMING_LOG = True
Global Const $BARBAROUS_SHORE_SKIP_HERO_TEMPLATE_LOAD = False
Global Const $BARBAROUS_SHORE_EXPAND_HERO_PANELS = True

Global Const $BARBAROUS_SHORE_APPROACH_WAYPOINTS[][] = [ _
	[-12830, 17372], _
	[-12562, 17138], _
	[-12279, 16879], _
	[-11902, 16271], _
	[-11860, 15544], _
	[-11870, 14824], _
	[-12061, 14121], _
	[-12270, 13426], _
	[-12483, 12728], _
	[-12834, 12096], _
	[-13177, 11454], _
	[-13491, 10801], _
	[-13761, 10122], _
	[-13993, 9331], _
	[-14132, 8709], _
	[-14220, 8316], _
	[-14408, 7760], _
	[-14754, 7308], _
	[-15098, 6689], _
	[-15237, 6333] _
]

Global Const $BARBAROUS_SHORE_PORTAL_PATH[][] = [ _
	[-17236, 17474], _
	[-15948, 18021], _
	[-14576, 18262], _
	[-14012, 18242] _
]

Global Const $BARBAROUS_SHORE_OUTPOST_RETURN[2] = [-14062, 18220]

Global $barbarous_shore_farm_setup = False
Global $barbarous_shore_support_enabled = False
Global $barbarous_shore_next_mh_tick = 0
Global $barbarous_shore_next_cautery_tick = 0
Global $barbarous_shore_mh_rotation_index = 0
Global $barbarous_shore_cautery_rotation_index = 0
Global $barbarous_shore_kahmu_index = $BARBAROUS_SHORE_HERO_KAHMU_INDEX
Global $barbarous_shore_melonni_index = $BARBAROUS_SHORE_HERO_MELONNI_INDEX
Global $barbarous_shore_mox_index = $BARBAROUS_SHORE_HERO_MOX_INDEX
Global $barbarous_shore_tahlkora_index = $BARBAROUS_SHORE_HERO_TAHLKORA_INDEX
Global $barbarous_shore_morgahn_index = $BARBAROUS_SHORE_HERO_MORGAHN_INDEX
Global $barbarous_shore_mow_index = $BARBAROUS_SHORE_HERO_MOW_INDEX
Global $barbarous_shore_olias_index = $BARBAROUS_SHORE_HERO_OLIAS_INDEX
Global $barbarous_shore_portal_anchor_x = 0
Global $barbarous_shore_portal_anchor_y = 0


Func BarbarousShoreChestFarm()
	If Not $barbarous_shore_farm_setup Then SetupBarbarousShoreChestFarm()

	GoToBarbarousShore()
	Local $result = BarbarousShoreChestFarmLoop()
	ResignAndReturnToOutpost($ID_CAMP_HOJANU)
	Return $result
EndFunc


Func SetupBarbarousShoreChestFarm()
	Info('Setting up Barbarous Shore farm')
	Local $setupTimer = TimerInit()
	Local $stepTimer = TimerInit()
	TravelToOutpost($ID_CAMP_HOJANU, $district_name)
	BarbarousShoreLogTiming('setup.travel_to_outpost', $stepTimer)

	$stepTimer = TimerInit()
	SetupPlayerBarbarousShoreChestFarm()
	BarbarousShoreLogTiming('setup.player_build', $stepTimer)
	$stepTimer = TimerInit()
	SetupTeamBarbarousShoreChestFarm()
	BarbarousShoreLogTiming('setup.team_build', $stepTimer)

	$stepTimer = TimerInit()
	SwitchMode($ID_NORMAL_MODE)
	BarbarousShoreLogTiming('setup.switch_mode', $stepTimer)

	$stepTimer = TimerInit()
	If BarbarousShoreRezoneCampHojanu() Then
		BarbarousShoreLogTiming('setup.rezone', $stepTimer)
	Else
		Warn('Barbarous rezone failed - runs will start from the far outpost spawn')
	EndIf

	$barbarous_shore_farm_setup = True
	BarbarousShoreLogTiming('setup.total', $setupTimer)
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerBarbarousShoreChestFarm()
	Info('Setting up player build skill bar')
	Local $timer = TimerInit()
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
		If BarbarousShoreHasExpectedPlayerBuild() Then
			BarbarousShoreLogTiming('setup.player_build.skip_template_already_loaded', $timer)
		Else
			LoadSkillTemplate($BARBAROUS_SHORE_CHESTRUNNER_SKILLBAR)
			RandomSleep(250)
			BarbarousShoreLogTiming('setup.player_build.load_template', $timer)
		EndIf
	Else
		Warn('Should run this farm as assassin')
		BarbarousShoreLogTiming('setup.player_build.invalid_profession', $timer)
	EndIf
EndFunc


Func BarbarousShoreHasExpectedPlayerBuild()
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


Func SetupTeamBarbarousShoreChestFarm()
	Info('Setting up fixed support team for Barbarous Shore chest run')
	Local $stepTimer = TimerInit()
	Local $requiredHeroes[] = [$BARBAROUS_SHORE_ID_KAHMU, $BARBAROUS_SHORE_ID_MELONNI, $BARBAROUS_SHORE_ID_MOX, $BARBAROUS_SHORE_ID_TAHLKORA, $BARBAROUS_SHORE_ID_MORGAHN, $BARBAROUS_SHORE_ID_MOW, $BARBAROUS_SHORE_ID_OLIAS]
	If SupportTeamHasExactHeroes($requiredHeroes, 8) Then
		BarbarousShoreLogTiming('setup.team_build.party_already_set', $stepTimer)
	Else
		SupportTeamKickAllHeroesByIDSweep()
		LeaveParty()
		AddHero($BARBAROUS_SHORE_ID_KAHMU)
		AddHero($BARBAROUS_SHORE_ID_MELONNI)
		AddHero($BARBAROUS_SHORE_ID_MOX)
		AddHero($BARBAROUS_SHORE_ID_TAHLKORA)
		AddHero($BARBAROUS_SHORE_ID_MORGAHN)
		AddHero($BARBAROUS_SHORE_ID_MOW)
		AddHero($BARBAROUS_SHORE_ID_OLIAS)
		RandomSleep(500)
		BarbarousShoreLogTiming('setup.team_build.party_compose', $stepTimer)

		$stepTimer = TimerInit()
		If Not SupportTeamHasExactHeroes($requiredHeroes, 8) Then
			Warn('Party not set up correctly. Team size different than 8')
			$barbarous_shore_support_enabled = False
			Return $FAIL
		EndIf
		BarbarousShoreLogTiming('setup.team_build.verify_party', $stepTimer)
	EndIf

	$stepTimer = TimerInit()
	$barbarous_shore_kahmu_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_ID_KAHMU, $BARBAROUS_SHORE_HERO_KAHMU_INDEX)
	$barbarous_shore_melonni_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_ID_MELONNI, $BARBAROUS_SHORE_HERO_MELONNI_INDEX)
	$barbarous_shore_mox_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_ID_MOX, $BARBAROUS_SHORE_HERO_MOX_INDEX)
	$barbarous_shore_tahlkora_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_ID_TAHLKORA, $BARBAROUS_SHORE_HERO_TAHLKORA_INDEX)
	$barbarous_shore_morgahn_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_ID_MORGAHN, $BARBAROUS_SHORE_HERO_MORGAHN_INDEX)
	$barbarous_shore_mow_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_ID_MOW, $BARBAROUS_SHORE_HERO_MOW_INDEX)
	$barbarous_shore_olias_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_ID_OLIAS, $BARBAROUS_SHORE_HERO_OLIAS_INDEX)
	BarbarousShoreLogTiming('setup.team_build.resolve_indexes', $stepTimer)

	$stepTimer = TimerInit()
	If $BARBAROUS_SHORE_SKIP_HERO_TEMPLATE_LOAD Then
		BarbarousShoreLogTiming('setup.team_build.skip_load_templates', $stepTimer)
	Else
		BarbarousShoreApplyHeroTemplate($barbarous_shore_kahmu_index, $BARBAROUS_SHORE_KAHMU_TEMPLATE)
		BarbarousShoreApplyHeroTemplate($barbarous_shore_melonni_index, $BARBAROUS_SHORE_MELONNI_TEMPLATE)
		BarbarousShoreApplyHeroTemplate($barbarous_shore_mox_index, $BARBAROUS_SHORE_MOX_TEMPLATE)
		BarbarousShoreApplyHeroTemplate($barbarous_shore_tahlkora_index, $BARBAROUS_SHORE_TAHLKORA_TEMPLATE)
		BarbarousShoreApplyHeroTemplate($barbarous_shore_morgahn_index, $BARBAROUS_SHORE_MORGAHN_TEMPLATE)
		BarbarousShoreApplyHeroTemplate($barbarous_shore_mow_index, $BARBAROUS_SHORE_MOW_TEMPLATE)
		BarbarousShoreApplyHeroTemplate($barbarous_shore_olias_index, $BARBAROUS_SHORE_OLIAS_TEMPLATE)
		RandomSleep(250)
		BarbarousShoreLogTiming('setup.team_build.load_templates', $stepTimer)
	EndIf

	$stepTimer = TimerInit()
	DisableAllHeroSkills($barbarous_shore_kahmu_index)
	DisableAllHeroSkills($barbarous_shore_melonni_index)
	DisableAllHeroSkills($barbarous_shore_mox_index)
	DisableAllHeroSkills($barbarous_shore_tahlkora_index)
	DisableAllHeroSkills($barbarous_shore_morgahn_index)
	DisableAllHeroSkills($barbarous_shore_mow_index)
	DisableAllHeroSkills($barbarous_shore_olias_index)
	EnableHeroSkillSlot($barbarous_shore_kahmu_index, $BARBAROUS_SHORE_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_melonni_index, $BARBAROUS_SHORE_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_mox_index, $BARBAROUS_SHORE_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_tahlkora_index, $BARBAROUS_SHORE_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_morgahn_index, $BARBAROUS_SHORE_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_mow_index, $BARBAROUS_SHORE_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_olias_index, $BARBAROUS_SHORE_HERO_SUPPORT_SKILL)
	BarbarousShoreLogTiming('setup.team_build.configure_skills', $stepTimer)

	$stepTimer = TimerInit()
	ResetBarbarousShoreHeroSupportScheduler()
	$barbarous_shore_support_enabled = True
	BarbarousShoreLogTiming('setup.team_build.finalize', $stepTimer)

	If $BARBAROUS_SHORE_EXPAND_HERO_PANELS Then
		$stepTimer = TimerInit()
		SupportTeamOpenHeroPanels('Barbarous Shore')
		BarbarousShoreLogTiming('setup.team_build.open_hero_panels', $stepTimer)
	EndIf
	Return $SUCCESS
EndFunc


Func BarbarousShoreApplyHeroTemplate($heroIndex, $templateCode)
	If HeroHasTemplate($heroIndex, $templateCode) Then Return
	LoadSkillTemplate($templateCode, $heroIndex)
	RandomSleep(150)
EndFunc


Func BarbarousShoreLogTiming($label, $timer)
	If Not $BARBAROUS_SHORE_TIMING_LOG Then Return
	Info('Barbarous timing: ' & $label & '=' & Int(TimerDiff($timer)) & 'ms')
EndFunc


Func BarbarousShoreLogSF($eventName, $sfRemaining = -1, $energy = -1, $extra = '')
	If Not $BARBAROUS_SHORE_SF_LOGGING Then Return
	Local $msg = 'Barbarous SF: ' & $eventName
	If $sfRemaining >= 0 Then $msg &= ';sf=' & Int($sfRemaining)
	If $energy >= 0 Then $msg &= ';e=' & Round($energy, 1)
	If $extra <> '' Then $msg &= ';' & $extra
	Info($msg)
EndFunc


Func GoToBarbarousShore()
	TravelToOutpost($ID_CAMP_HOJANU, $district_name)
	While GetMapID() <> $ID_BARBAROUS_SHORE
		Info('Moving to Barbarous Shore')
		BarbarousShoreWalkToPortal()
		RandomSleep(1000)
		WaitMapLoading($ID_BARBAROUS_SHORE, 10000, 2000)
	WEnd
	ClearChestsMap()
	CaptureBarbarousShorePortalAnchor()
	FlagBarbarousShoreSupportHeroesAtPortal()
EndFunc


;~ The rezone moves the outpost spawn point next to the portal, so start the path at the closest waypoint
Func BarbarousShoreWalkToPortal()
	Local $me = GetMyAgent()
	Local $startIndex = 0
	Local $closestDistance = 1000000
	For $i = 0 To UBound($BARBAROUS_SHORE_PORTAL_PATH) - 1
		Local $distance = GetDistanceToPoint($me, $BARBAROUS_SHORE_PORTAL_PATH[$i][0], $BARBAROUS_SHORE_PORTAL_PATH[$i][1])
		If $distance < $closestDistance Then
			$closestDistance = $distance
			$startIndex = $i
		EndIf
	Next
	For $i = $startIndex To UBound($BARBAROUS_SHORE_PORTAL_PATH) - 2
		MoveTo($BARBAROUS_SHORE_PORTAL_PATH[$i][0], $BARBAROUS_SHORE_PORTAL_PATH[$i][1])
	Next
	Move($BARBAROUS_SHORE_PORTAL_PATH[UBound($BARBAROUS_SHORE_PORTAL_PATH) - 1][0], $BARBAROUS_SHORE_PORTAL_PATH[UBound($BARBAROUS_SHORE_PORTAL_PATH) - 1][1])
EndFunc


;~ Out and straight back in once, so every later resign respawns next to the Barbarous Shore portal
Func BarbarousShoreRezoneCampHojanu()
	BarbarousShoreWalkToPortal()
	RandomSleep(1500)
	If Not WaitMapLoading($ID_BARBAROUS_SHORE, 10000, 500) Then Return False

	Move($BARBAROUS_SHORE_OUTPOST_RETURN[0], $BARBAROUS_SHORE_OUTPOST_RETURN[1])
	RandomSleep(1500)
	If Not WaitMapLoading($ID_CAMP_HOJANU, 10000, 500) Then Return False
	Return SupportTeamStabilizeAfterTravel($ID_CAMP_HOJANU, 10000, 250)
EndFunc


Func ResetBarbarousShoreHeroSupportScheduler()
	$barbarous_shore_next_mh_tick = 0
	$barbarous_shore_next_cautery_tick = 0
	$barbarous_shore_mh_rotation_index = 0
	$barbarous_shore_cautery_rotation_index = 0
EndFunc


Func FlagBarbarousShoreSupportHeroesAtPortal()
	If Not $barbarous_shore_support_enabled Then Return
	If GetMapID() <> $ID_BARBAROUS_SHORE Then Return

	Local $flagX = $barbarous_shore_portal_anchor_x
	Local $flagY = $barbarous_shore_portal_anchor_y
	If $flagX == 0 And $flagY == 0 Then
		CaptureBarbarousShorePortalAnchor()
		$flagX = $barbarous_shore_portal_anchor_x
		$flagY = $barbarous_shore_portal_anchor_y
	EndIf

	SupportTeamDebug($BARBAROUS_SHORE_SUPPORT_DEBUG_VERBOSE, 'Barbarous support: flag heroes at portal X=' & $flagX & ' Y=' & $flagY)
	For $i = 1 To $BARBAROUS_SHORE_PORTAL_FLAG_MAX_RETRIES
		BarbarousShoreCommandAllSupportHeroesTo($flagX, $flagY)
		RandomSleep(140)
		If BarbarousShoreAreAllSupportHeroesAt($flagX, $flagY, $BARBAROUS_SHORE_PORTAL_FLAG_VERIFY_RANGE) Then Return
	Next
	Warn('Barbarous support: not all heroes reached portal flag before run start')
EndFunc


Func CaptureBarbarousShorePortalAnchor()
	If GetMapID() <> $ID_BARBAROUS_SHORE Then Return
	Local $me = GetMyAgent()
	If $me == Null Then Return
	$barbarous_shore_portal_anchor_x = Int(DllStructGetData($me, 'X'))
	$barbarous_shore_portal_anchor_y = Int(DllStructGetData($me, 'Y'))
	SupportTeamDebug($BARBAROUS_SHORE_SUPPORT_DEBUG_VERBOSE, 'Barbarous support: captured portal anchor X=' & $barbarous_shore_portal_anchor_x & ' Y=' & $barbarous_shore_portal_anchor_y)
EndFunc


Func BarbarousShoreCommandAllSupportHeroesTo($x, $y)
	CommandHero($barbarous_shore_kahmu_index, $x, $y)
	CommandHero($barbarous_shore_melonni_index, $x, $y)
	CommandHero($barbarous_shore_mox_index, $x, $y)
	CommandHero($barbarous_shore_tahlkora_index, $x, $y)
	CommandHero($barbarous_shore_morgahn_index, $x, $y)
	CommandHero($barbarous_shore_mow_index, $x, $y)
	CommandHero($barbarous_shore_olias_index, $x, $y)
EndFunc


Func BarbarousShoreAreAllSupportHeroesAt($x, $y, $maxDist)
	If Not BarbarousShoreIsHeroAtFlag($barbarous_shore_kahmu_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreIsHeroAtFlag($barbarous_shore_melonni_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreIsHeroAtFlag($barbarous_shore_mox_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreIsHeroAtFlag($barbarous_shore_tahlkora_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreIsHeroAtFlag($barbarous_shore_morgahn_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreIsHeroAtFlag($barbarous_shore_mow_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreIsHeroAtFlag($barbarous_shore_olias_index, $x, $y, $maxDist) Then Return False
	Return True
EndFunc


Func BarbarousShoreIsHeroAtFlag($heroIndex, $x, $y, $maxDist)
	If $heroIndex <= 0 Then Return False
	Local $heroAgent = GetAgentByID(GetHeroID($heroIndex))
	If $heroAgent == Null Then Return False
	Return GetDistanceToPoint($heroAgent, $x, $y) <= $maxDist
EndFunc


Func TickBarbarousShoreHeroSupportCasts()
	If Not $barbarous_shore_support_enabled Then Return
	If GetMapID() <> $ID_BARBAROUS_SHORE Then Return
	Local $mhOrder[] = [$barbarous_shore_melonni_index, $barbarous_shore_kahmu_index, $barbarous_shore_mox_index, $barbarous_shore_tahlkora_index]
	Local $cauteryOrder[] = [$barbarous_shore_morgahn_index, $barbarous_shore_mow_index, $barbarous_shore_olias_index]

	If $barbarous_shore_next_mh_tick == 0 Or TimerDiff($barbarous_shore_next_mh_tick) >= $BARBAROUS_SHORE_MH_CAST_INTERVAL_MS Then
		Local $mhCount = UBound($mhOrder)
		For $i = 0 To $mhCount - 1
			Local $mhPos = Mod($barbarous_shore_mh_rotation_index + $i, $mhCount)
			Local $mhHero = $mhOrder[$mhPos]
			If IsRecharged($BARBAROUS_SHORE_HERO_SUPPORT_SKILL, $mhHero) Then
				SupportTeamDebug($BARBAROUS_SHORE_SUPPORT_DEBUG_VERBOSE, 'Barbarous support: MH cast hero index=' & $mhHero)
				UseHeroSkill($mhHero, $BARBAROUS_SHORE_HERO_SUPPORT_SKILL)
				$barbarous_shore_mh_rotation_index = Mod($mhPos + 1, $mhCount)
				$barbarous_shore_next_mh_tick = TimerInit()
				ExitLoop
			EndIf
		Next
	EndIf

	If $barbarous_shore_next_cautery_tick == 0 Or TimerDiff($barbarous_shore_next_cautery_tick) >= $BARBAROUS_SHORE_CAUTERY_CAST_INTERVAL_MS Then
		Local $cauteryCount = UBound($cauteryOrder)
		For $i = 0 To $cauteryCount - 1
			Local $cauteryPos = Mod($barbarous_shore_cautery_rotation_index + $i, $cauteryCount)
			Local $cauteryHero = $cauteryOrder[$cauteryPos]
			If IsRecharged($BARBAROUS_SHORE_HERO_SUPPORT_SKILL, $cauteryHero) Then
				SupportTeamDebug($BARBAROUS_SHORE_SUPPORT_DEBUG_VERBOSE, 'Barbarous support: Cautery cast hero index=' & $cauteryHero)
				UseHeroSkill($cauteryHero, $BARBAROUS_SHORE_HERO_SUPPORT_SKILL)
				$barbarous_shore_cautery_rotation_index = Mod($cauteryPos + 1, $cauteryCount)
				$barbarous_shore_next_cautery_tick = TimerInit()
				ExitLoop
			EndIf
		Next
	EndIf
EndFunc


;~ One chest spot only: run the recorded approach, loot the chest if it spawned, otherwise let the farm resign
Func BarbarousShoreChestFarmLoop()
	If FindInInventory($ID_LOCKPICK)[0] == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf
	If GetMapID() <> $ID_BARBAROUS_SHORE Then Return $FAIL

	Info('Starting chest farm run')
	ClearChestsMap()
	FlagBarbarousShoreSupportHeroesAtPortal()
	ResetBarbarousShoreHeroSupportScheduler()

	If BarbarousShoreRunToChestSpot() == $FAIL Then Return IsPlayerAlive() ? $SUCCESS : $FAIL

	If FindAndOpenChests($BARBAROUS_SHORE_CHEST_OPEN_RANGE, DefendWhileOpeningChestsBarbarousShore) Then
		Info('Opened the chest at the single spot')
	Else
		Notice('No chest at the single spot - resigning for the next attempt')
	EndIf
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Recorded approach from the Camp Hojanu portal to the chest spot
Func BarbarousShoreRunToChestSpot()
	Local $approachTimer = TimerInit()
	Local $waypointCount = UBound($BARBAROUS_SHORE_APPROACH_WAYPOINTS)
	For $i = 0 To $waypointCount - 1
		If IsPlayerDead() Then Return $FAIL
		If TimerDiff($approachTimer) > $BARBAROUS_SHORE_APPROACH_TIMEOUT_MS Then
			Warn('Barbarous run: approach timed out before reaching the chest spot')
			Return $FAIL
		EndIf
		Info('Running to approach point ' & ($i + 1) & '/' & $waypointCount)
		If BarbarousShoreRunTo($BARBAROUS_SHORE_APPROACH_WAYPOINTS[$i][0], $BARBAROUS_SHORE_APPROACH_WAYPOINTS[$i][1]) == $FAIL Then Return $FAIL
	Next
	Return $SUCCESS
EndFunc


;~ Walk to a point while keeping the four important skills up
Func BarbarousShoreRunTo($x, $y)
	Local $me = GetMyAgent()
	If $me == Null Then Return $FAIL
	Local $moveTimer = TimerInit()
	Local $blockedCounter = 0
	Move($x, $y)
	While IsPlayerAlive() And GetDistanceToPoint($me, $x, $y) > $BARBAROUS_SHORE_WAYPOINT_REACH_RANGE
		If TimerDiff($moveTimer) > $BARBAROUS_SHORE_WAYPOINT_TIMEOUT_MS Then
			Warn('Barbarous run: point ' & Int($x) & ',' & Int($y) & ' not reached in time')
			Return $FAIL
		EndIf

		BarbarousShoreMaintainBuffs()
		TickBarbarousShoreHeroSupportCasts()

		If Not IsPlayerMoving() Then
			$blockedCounter += 1
			Move($x, $y)
		Else
			$blockedCounter = 0
		EndIf

		If $blockedCounter >= $BARBAROUS_SHORE_BLOCKED_TICKS_BEFORE_UNSTUCK Then
			$blockedCounter = 0
			If BarbarousShoreTryBreakBodyblock($x, $y) Then Move($x, $y)
		EndIf

		RandomSleep(250)
		$me = GetMyAgent()
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Perma Shadow Form: request Shadow Form and slip Deadly Paradox into its cast time
Func BarbarousShoreMaintainShadowForm()
	Local Static $sfQueueTimer = 0
	If IsRecharged($BARBAROUS_SHORE_SHADOWFORM) And GetEnergy() >= $BARBAROUS_SHORE_SF_DP_MIN_ENERGY _
		And ($sfQueueTimer == 0 Or TimerDiff($sfQueueTimer) > $BARBAROUS_SHORE_SF_QUEUE_RETRY_MS) Then
		UseSkill($BARBAROUS_SHORE_SHADOWFORM)
		$sfQueueTimer = TimerInit()
		Local $dpTimer = TimerInit()
		While IsPlayerAlive() And TimerDiff($dpTimer) < $BARBAROUS_SHORE_DP_AFTER_SF_DELAY_MS
			Sleep(10)
		WEnd
		If IsRecharged($BARBAROUS_SHORE_DEADLY_PARADOX) Then
			UseSkill($BARBAROUS_SHORE_DEADLY_PARADOX)
			BarbarousShoreLogSF('dp_cast', GetEffectTimeRemaining($ID_SHADOW_FORM), GetEnergy(), 'ctx=move')
		Else
			BarbarousShoreLogSF('dp_skip_recharge', GetEffectTimeRemaining($ID_SHADOW_FORM), GetEnergy(), 'ctx=move')
		EndIf
	EndIf
	Return GetEffect($ID_SHADOW_FORM) <> Null
EndFunc


;~ Shadow Form, Dwarven Stability, Dark Escape and the cripple cleaner; skills 6 to 8 are backup only
Func BarbarousShoreMaintainBuffs()
	If IsPlayerDead() Then Return
	If Not BarbarousShoreMaintainShadowForm() Then Return

	;~ Dwarven Stability stretches the stance but needs a 0.5s cast, so let it land before touching the stance
	If GetEffect($ID_DWARVEN_STABILITY) == Null And IsRecharged($BARBAROUS_SHORE_DWARVEN_STABILITY) And GetEnergy() >= 5 Then
		UseSkill($BARBAROUS_SHORE_DWARVEN_STABILITY)
		Local $stabilityTimer = TimerInit()
		While GetEffect($ID_DWARVEN_STABILITY) == Null And TimerDiff($stabilityTimer) < $BARBAROUS_SHORE_DWARVEN_STABILITY_CAST_MS
			Sleep(20)
		WEnd
	EndIf

	;~ Only one stance can run at a time, so Dash fills the Dark Escape cooldown and never overlaps it
	If GetEffect($ID_DARK_ESCAPE) == Null And GetEffect($ID_DASH) == Null Then
		If IsRecharged($BARBAROUS_SHORE_DARK_ESCAPE) Then
			If GetEnergy() >= 5 Then UseSkill($BARBAROUS_SHORE_DARK_ESCAPE)
		ElseIf IsRecharged($BARBAROUS_SHORE_DASH) And GetEnergy() >= 5 Then
			UseSkill($BARBAROUS_SHORE_DASH)
		EndIf
	EndIf

	If GetEffect($ID_CRIPPLED) <> Null And IsRecharged($BARBAROUS_SHORE_I_AM_UNSTOPPABLE) _
		And GetEnergy() >= $BARBAROUS_SHORE_IAU_MIN_ENERGY Then
		UseSkill($BARBAROUS_SHORE_I_AM_UNSTOPPABLE)
	EndIf
EndFunc


Func DefendWhileOpeningChestsBarbarousShore()
	TickBarbarousShoreHeroSupportCasts()
	BarbarousShoreMaintainBuffs()
EndFunc


;~ Bodyblock escape: Heart of Shadow teleports off the block, Deaths Charge hops forward, then a side step
Func BarbarousShoreTryBreakBodyblock($targetX, $targetY)
	Local $me = GetMyAgent()
	If $me == Null Then Return False
	Local $startX = DllStructGetData($me, 'X')
	Local $startY = DllStructGetData($me, 'Y')

	If IsRecharged($BARBAROUS_SHORE_HEART_OF_SHADOW) And GetEnergy() >= 5 Then
		Local $npc = GetNPCInTheBackBarbarousShore($targetX, $targetY)
		If $npc == Null Then $npc = $me
		UseSkill($BARBAROUS_SHORE_HEART_OF_SHADOW, $npc)
		RandomSleep(100)
	EndIf
	If IsRecharged($BARBAROUS_SHORE_DEATHS_CHARGE) And GetEnergy() >= 5 Then
		Local $chargeTarget = GetTargetForDeathsChargeBarbarousShore($targetX, $targetY)
		If $chargeTarget <> Null Then
			UseSkill($BARBAROUS_SHORE_DEATHS_CHARGE, $chargeTarget)
			RandomSleep(100)
		EndIf
	EndIf

	Local $dx = $targetX - $startX
	Local $dy = $targetY - $startY
	Local $len = Sqrt(($dx * $dx) + ($dy * $dy))
	If $len >= 1 Then
		Local $rightX = $dy / $len
		Local $rightY = -$dx / $len
		Move($startX + ($rightX * $BARBAROUS_SHORE_BYPASS_SIDE_STEP), $startY + ($rightY * $BARBAROUS_SHORE_BYPASS_SIDE_STEP))
		RandomSleep(100)
	EndIf
	Move($targetX, $targetY)
	RandomSleep(100)

	$me = GetMyAgent()
	If $me == Null Then Return False
	Return ComputeDistance($startX, $startY, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y')) >= 120
EndFunc


Func GetNPCInTheBackBarbarousShore($x, $y)
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST)
	If Not IsArray($foes) Or UBound($foes) <= 0 Then Return Null

	Local $moveX = $x - $myX
	Local $moveY = $y - $myY
	Local $moveLength = Sqrt(($moveX * $moveX) + ($moveY * $moveY))
	If $moveLength == 0 Then Return Null
	$moveX /= $moveLength
	$moveY /= $moveLength

	Local $bestFoe = Null
	Local $minDot = 1
	For $foe In $foes
		Local $foeX = DllStructGetData($foe, 'X') - $myX
		Local $foeY = DllStructGetData($foe, 'Y') - $myY
		Local $foeLength = Sqrt(($foeX * $foeX) + ($foeY * $foeY))
		If $foeLength == 0 Then ContinueLoop
		Local $dot = (($foeX / $foeLength) * $moveX) + (($foeY / $foeLength) * $moveY)
		If $dot < $minDot Then
			$minDot = $dot
			$bestFoe = $foe
		EndIf
	Next
	Return $bestFoe
EndFunc


Func GetTargetForDeathsChargeBarbarousShore($x, $y, $leadDistance = 700)
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST)
	If Not IsArray($foes) Or UBound($foes) <= 0 Then Return Null
	For $foe In $foes
		If (GetDistanceToPoint($me, $x, $y) - GetDistanceToPoint($foe, $x, $y)) > $leadDistance Then Return $foe
	Next
	Return Null
EndFunc
