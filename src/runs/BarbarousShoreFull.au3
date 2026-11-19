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
Global Const $BARBAROUS_SHORE_FULL_CHESTRUNNER_SKILLBAR = 'OwBj4xf84Q8I6M3lNQ0kTQ4OIQA'
Global Const $BARBAROUS_SHORE_FULL_CHESTRUN_INFORMATIONS = 'Assassin Barbarous Shore chest run variant.' & @CRLF _
	& 'Walks the whole recorded route spot by spot and resigns at the end' & @CRLF _
	& 'Permanent cover:' & @CRLF _
	& '- 1 Deadly Paradox + 2 Shadow Form for spell immunity' & @CRLF _
	& '- 3 Dwarven Stability as stance upkeep' & @CRLF _
	& '- 4 Dark Escape only after a fresh Deadly Paradox + Shadow Form cycle' & @CRLF _
	& '- 7 Death''s Charge and 8 Heart of Shadow for emergency healing'
Global Const $BARBAROUS_SHORE_FULL_FARM_DURATION = (20 * 60) * 1000

; Skill numbers
Global Const $BARBAROUS_SHORE_FULL_DEADLY_PARADOX = 1
Global Const $BARBAROUS_SHORE_FULL_SHADOWFORM = 2
Global Const $BARBAROUS_SHORE_FULL_DWARVEN_STABILITY = 3
Global Const $BARBAROUS_SHORE_FULL_DARK_ESCAPE = 4
Global Const $BARBAROUS_SHORE_FULL_I_AM_UNSTOPPABLE = 5
Global Const $BARBAROUS_SHORE_FULL_DEATHS_CHARGE = 7
Global Const $BARBAROUS_SHORE_FULL_HEART_OF_SHADOW = 8

Global Const $BARBAROUS_SHORE_FULL_ID_KAHMU = $ID_KAHMU
Global Const $BARBAROUS_SHORE_FULL_ID_MELONNI = $ID_MELONNI
Global Const $BARBAROUS_SHORE_FULL_ID_MOX = $ID_MOX
Global Const $BARBAROUS_SHORE_FULL_ID_TAHLKORA = $ID_TAHLKORA
Global Const $BARBAROUS_SHORE_FULL_ID_MORGAHN = $ID_GENERAL_MORGAHN
Global Const $BARBAROUS_SHORE_FULL_ID_MOW = $ID_MASTER_OF_WHISPERS
Global Const $BARBAROUS_SHORE_FULL_ID_OLIAS = $ID_OLIAS

Global Const $BARBAROUS_SHORE_FULL_KAHMU_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_FULL_MELONNI_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_FULL_MOX_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_FULL_TAHLKORA_TEMPLATE = 'Owohoyz9FAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_FULL_MORGAHN_TEMPLATE = 'OQijEqmMKO0YAAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_FULL_MOW_TEMPLATE = 'OAlkUwG4RZmDNGAAAAAAAAAAAAA'
Global Const $BARBAROUS_SHORE_FULL_OLIAS_TEMPLATE = 'OAlkUwG4RZmDNGAAAAAAAAAAAAA'

Global Const $BARBAROUS_SHORE_FULL_HERO_KAHMU_INDEX = 1
Global Const $BARBAROUS_SHORE_FULL_HERO_MELONNI_INDEX = 2
Global Const $BARBAROUS_SHORE_FULL_HERO_MOX_INDEX = 3
Global Const $BARBAROUS_SHORE_FULL_HERO_TAHLKORA_INDEX = 4
Global Const $BARBAROUS_SHORE_FULL_HERO_MORGAHN_INDEX = 5
Global Const $BARBAROUS_SHORE_FULL_HERO_MOW_INDEX = 6
Global Const $BARBAROUS_SHORE_FULL_HERO_OLIAS_INDEX = 7
Global Const $BARBAROUS_SHORE_FULL_HERO_SUPPORT_SKILL = 1

Global Const $BARBAROUS_SHORE_FULL_PORTAL_FLAG_VERIFY_RANGE = 380
Global Const $BARBAROUS_SHORE_FULL_PORTAL_FLAG_MAX_RETRIES = 10
Global Const $BARBAROUS_SHORE_FULL_MH_CAST_INTERVAL_MS = 1000
Global Const $BARBAROUS_SHORE_FULL_CAUTERY_CAST_INTERVAL_MS = 5000
Global Const $BARBAROUS_SHORE_FULL_SUPPORT_DEBUG_VERBOSE = False
Global Const $BARBAROUS_SHORE_FULL_SF_LOGGING = True

;~ Perma Shadow Form, same rhythm as Focus Hanaku: request Shadow Form, then slip Deadly Paradox into its cast time
Global Const $BARBAROUS_SHORE_FULL_SF_DP_MIN_ENERGY = 20
Global Const $BARBAROUS_SHORE_FULL_SF_QUEUE_RETRY_MS = 250
Global Const $BARBAROUS_SHORE_FULL_IAU_MIN_ENERGY = 5
Global Const $BARBAROUS_SHORE_FULL_DWARVEN_STABILITY_CAST_MS = 800

;~ Single chest spot taken from the 2026-11-16 recording, plus the approach that was recorded
Global Const $BARBAROUS_SHORE_FULL_CHEST_OPEN_RANGE = $RANGE_COMPASS + 300
Global Const $BARBAROUS_SHORE_FULL_WAYPOINT_REACH_RANGE = 100
Global Const $BARBAROUS_SHORE_FULL_WAYPOINT_TIMEOUT_MS = 45000
Global Const $BARBAROUS_SHORE_FULL_ROUTE_TIMEOUT_MS = 25 * 60 * 1000
Global Const $BARBAROUS_SHORE_FULL_BLOCKED_TICKS_BEFORE_UNSTUCK = 3
Global Const $BARBAROUS_SHORE_FULL_BYPASS_SIDE_STEP = 520
Global Const $BARBAROUS_SHORE_FULL_TIMING_LOG = True
Global Const $BARBAROUS_SHORE_FULL_SKIP_HERO_TEMPLATE_LOAD = False
Global Const $BARBAROUS_SHORE_FULL_EXPAND_HERO_PANELS = True

Global Const $BARBAROUS_SHORE_FULL_ROUTE_WAYPOINTS[][] = [ _
	[-12830, 17372], _
	[-12174, 16706], _
	[-11841, 15849], _
	[-11915, 14928], _
	[-12225, 14039], _
	[-12654, 13212], _
	[-13033, 12350], _
	[-13080, 11439], _
	[-13673, 10698], _
	[-14066, 9837], _
	[-14366, 8944], _
	[-14628, 8037], _
	[-14546, 7110], _
	[-14722, 6186], _
	[-15056, 5278], _
	[-15467, 4407], _
	[-15857, 3538], _
	[-16184, 2609], _
	[-16384, 1673], _
	[-15826, 924], _
	[-15055, 408], _
	[-14477, -284], _
	[-14154, -1183], _
	[-13858, -2084], _
	[-13483, -2955], _
	[-13021, -3736], _
	[-12623, -4587], _
	[-12304, -5457], _
	[-12095, -6334], _
	[-11850, -7245], _
	[-11599, -8123], _
	[-11805, -9048], _
	[-11919, -9971], _
	[-12099, -10862], _
	[-11432, -11471], _
	[-10552, -11716], _
	[-9773, -11179], _
	[-9269, -10375], _
	[-8897, -9507], _
	[-8498, -8621], _
	[-7968, -7893], _
	[-7114, -7519], _
	[-6162, -7374], _
	[-5249, -7177], _
	[-4629, -6517], _
	[-4578, -5352], _
	[-3841, -4784], _
	[-3891, -3884], _
	[-4602, -3268], _
	[-4501, -2326], _
	[-3563, -2429], _
	[-3046, -3194], _
	[-2250, -3709], _
	[-1748, -4481], _
	[-886, -4183], _
	[-383, -3423], _
	[221, -2742], _
	[1161, -2832], _
	[1778, -3528], _
	[2194, -4361], _
	[2483, -5270], _
	[3077, -5996], _
	[3908, -6461], _
	[4683, -6958], _
	[5346, -7622], _
	[6273, -7526], _
	[6608, -6641], _
	[6987, -5777], _
	[7636, -5105], _
	[8462, -4704], _
	[9399, -4668], _
	[10192, -5148], _
	[11111, -5174], _
	[12081, -5030], _
	[12958, -4768], _
	[13705, -4241], _
	[14607, -4518], _
	[15446, -4962], _
	[15386, -4024], _
	[15441, -3078], _
	[14807, -2381], _
	[14100, -1727], _
	[13363, -1103], _
	[13281, -179], _
	[12734, 567], _
	[12045, 1197], _
	[11843, 2090], _
	[10941, 2119], _
	[10207, 2664], _
	[9740, 3474], _
	[9700, 4428], _
	[9490, 5343], _
	[9976, 6147], _
	[10533, 6895], _
	[11126, 7640], _
	[11323, 8565], _
	[10915, 9422], _
	[10319, 10138], _
	[9703, 10871], _
	[9093, 11571], _
	[8456, 12283], _
	[7610, 12699], _
	[6692, 12562], _
	[6166, 11780], _
	[5659, 10995], _
	[5126, 10233], _
	[4333, 9785], _
	[3470, 9464], _
	[2540, 9517], _
	[1645, 9755], _
	[814, 9378], _
	[343, 8594], _
	[-238, 7831], _
	[-1090, 7444], _
	[-1991, 7328], _
	[-2913, 7197], _
	[-3768, 7603], _
	[-4097, 8501], _
	[-3938, 9388], _
	[-3636, 10283], _
	[-2991, 10971], _
	[-2271, 11587], _
	[-1522, 12195], _
	[-748, 12698], _
	[-326, 13556], _
	[34, 14400], _
	[429, 15254], _
	[-154, 16004], _
	[-919, 16512], _
	[-1836, 16696], _
	[-2761, 16876], _
	[-3668, 17042], _
	[-4616, 16965] _
]

Global Const $BARBAROUS_SHORE_FULL_PORTAL_PATH[][] = [ _
	[-17236, 17474], _
	[-15948, 18021], _
	[-14576, 18262], _
	[-14012, 18242] _
]

Global Const $BARBAROUS_SHORE_FULL_OUTPOST_RETURN[2] = [-14062, 18220]
Global Const $BARBAROUS_SHORE_FULL_REZONE_DEEP[2] = [-14500, 18540]
Global Const $BARBAROUS_SHORE_FULL_REZONE_ATTEMPTS = 3

Global $barbarous_shore_full_dark_escape_pending = False
Global Const $BARBAROUS_SHORE_FULL_LOG_HEARTBEAT_MS = 1000
Global $barbarous_shore_full_log_file = ''
Global $barbarous_shore_full_log_handle = -1
Global $barbarous_shore_full_log_timer = 0
Global $barbarous_shore_full_log_heartbeat_timer = 0

Global $barbarous_shore_full_farm_setup = False
Global $barbarous_shore_full_support_enabled = False
Global $barbarous_shore_full_next_mh_tick = 0
Global $barbarous_shore_full_next_cautery_tick = 0
Global $barbarous_shore_full_mh_rotation_index = 0
Global $barbarous_shore_full_cautery_rotation_index = 0
Global $barbarous_shore_full_kahmu_index = $BARBAROUS_SHORE_FULL_HERO_KAHMU_INDEX
Global $barbarous_shore_full_melonni_index = $BARBAROUS_SHORE_FULL_HERO_MELONNI_INDEX
Global $barbarous_shore_full_mox_index = $BARBAROUS_SHORE_FULL_HERO_MOX_INDEX
Global $barbarous_shore_full_tahlkora_index = $BARBAROUS_SHORE_FULL_HERO_TAHLKORA_INDEX
Global $barbarous_shore_full_morgahn_index = $BARBAROUS_SHORE_FULL_HERO_MORGAHN_INDEX
Global $barbarous_shore_full_mow_index = $BARBAROUS_SHORE_FULL_HERO_MOW_INDEX
Global $barbarous_shore_full_olias_index = $BARBAROUS_SHORE_FULL_HERO_OLIAS_INDEX
Global $barbarous_shore_full_portal_anchor_x = 0
Global $barbarous_shore_full_portal_anchor_y = 0


Func BarbarousShoreFullChestFarm()
	If Not $barbarous_shore_full_farm_setup Then SetupBarbarousShoreFullChestFarm()
	BarbarousShoreFullLogInit()

	GoToBarbarousShoreFull()
	Local $result = BarbarousShoreFullChestFarmLoop()
	BarbarousShoreFullLogClose()
	ResignAndReturnToOutpost($ID_CAMP_HOJANU)
	Return $result
EndFunc


Func SetupBarbarousShoreFullChestFarm()
	Info('Setting up Barbarous Shore Full farm')
	Local $setupTimer = TimerInit()
	Local $stepTimer = TimerInit()
	TravelToOutpost($ID_CAMP_HOJANU, $district_name)
	BarbarousShoreFullLogTiming('setup.travel_to_outpost', $stepTimer)

	$stepTimer = TimerInit()
	SetupPlayerBarbarousShoreFullChestFarm()
	BarbarousShoreFullLogTiming('setup.player_build', $stepTimer)
	$stepTimer = TimerInit()
	SetupTeamBarbarousShoreFullChestFarm()
	BarbarousShoreFullLogTiming('setup.team_build', $stepTimer)

	$stepTimer = TimerInit()
	SwitchMode($ID_NORMAL_MODE)
	BarbarousShoreFullLogTiming('setup.switch_mode', $stepTimer)

	$stepTimer = TimerInit()
	If BarbarousShoreFullRezoneCampHojanu() Then
		BarbarousShoreFullLogTiming('setup.rezone', $stepTimer)
	Else
		Warn('Barbarous rezone failed - runs will start from the far outpost spawn')
	EndIf

	$barbarous_shore_full_farm_setup = True
	BarbarousShoreFullLogTiming('setup.total', $setupTimer)
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerBarbarousShoreFullChestFarm()
	Info('Setting up player build skill bar')
	Local $timer = TimerInit()
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
		If BarbarousShoreFullHasExpectedPlayerBuild() Then
			BarbarousShoreFullLogTiming('setup.player_build.skip_template_already_loaded', $timer)
		Else
			LoadSkillTemplate($BARBAROUS_SHORE_FULL_CHESTRUNNER_SKILLBAR)
			RandomSleep(250)
			BarbarousShoreFullLogTiming('setup.player_build.load_template', $timer)
		EndIf
	Else
		Warn('Should run this farm as assassin')
		BarbarousShoreFullLogTiming('setup.player_build.invalid_profession', $timer)
	EndIf
EndFunc


Func BarbarousShoreFullHasExpectedPlayerBuild()
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


Func SetupTeamBarbarousShoreFullChestFarm()
	If IsTeamAutoSetup() Then Return $SUCCESS
	Info('Setting up fixed support team for Barbarous Shore Full chest run')
	Local $stepTimer = TimerInit()
	Local $requiredHeroes[] = [$BARBAROUS_SHORE_FULL_ID_KAHMU, $BARBAROUS_SHORE_FULL_ID_MELONNI, $BARBAROUS_SHORE_FULL_ID_MOX, $BARBAROUS_SHORE_FULL_ID_TAHLKORA, $BARBAROUS_SHORE_FULL_ID_MORGAHN, $BARBAROUS_SHORE_FULL_ID_MOW, $BARBAROUS_SHORE_FULL_ID_OLIAS]
	If SupportTeamHasExactHeroes($requiredHeroes, 8) Then
		BarbarousShoreFullLogTiming('setup.team_build.party_already_set', $stepTimer)
	Else
		SupportTeamKickAllHeroesByIDSweep()
		LeaveParty()
		AddHero($BARBAROUS_SHORE_FULL_ID_KAHMU)
		AddHero($BARBAROUS_SHORE_FULL_ID_MELONNI)
		AddHero($BARBAROUS_SHORE_FULL_ID_MOX)
		AddHero($BARBAROUS_SHORE_FULL_ID_TAHLKORA)
		AddHero($BARBAROUS_SHORE_FULL_ID_MORGAHN)
		AddHero($BARBAROUS_SHORE_FULL_ID_MOW)
		AddHero($BARBAROUS_SHORE_FULL_ID_OLIAS)
		RandomSleep(500)
		BarbarousShoreFullLogTiming('setup.team_build.party_compose', $stepTimer)

		$stepTimer = TimerInit()
		If Not SupportTeamHasExactHeroes($requiredHeroes, 8) Then
			Warn('Party not set up correctly. Team size different than 8')
			$barbarous_shore_full_support_enabled = False
			Return $FAIL
		EndIf
		BarbarousShoreFullLogTiming('setup.team_build.verify_party', $stepTimer)
	EndIf

	$stepTimer = TimerInit()
	$barbarous_shore_full_kahmu_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_FULL_ID_KAHMU, $BARBAROUS_SHORE_FULL_HERO_KAHMU_INDEX)
	$barbarous_shore_full_melonni_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_FULL_ID_MELONNI, $BARBAROUS_SHORE_FULL_HERO_MELONNI_INDEX)
	$barbarous_shore_full_mox_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_FULL_ID_MOX, $BARBAROUS_SHORE_FULL_HERO_MOX_INDEX)
	$barbarous_shore_full_tahlkora_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_FULL_ID_TAHLKORA, $BARBAROUS_SHORE_FULL_HERO_TAHLKORA_INDEX)
	$barbarous_shore_full_morgahn_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_FULL_ID_MORGAHN, $BARBAROUS_SHORE_FULL_HERO_MORGAHN_INDEX)
	$barbarous_shore_full_mow_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_FULL_ID_MOW, $BARBAROUS_SHORE_FULL_HERO_MOW_INDEX)
	$barbarous_shore_full_olias_index = SupportTeamResolveHeroIndex($BARBAROUS_SHORE_FULL_ID_OLIAS, $BARBAROUS_SHORE_FULL_HERO_OLIAS_INDEX)
	BarbarousShoreFullLogTiming('setup.team_build.resolve_indexes', $stepTimer)

	$stepTimer = TimerInit()
	If $BARBAROUS_SHORE_FULL_SKIP_HERO_TEMPLATE_LOAD Then
		BarbarousShoreFullLogTiming('setup.team_build.skip_load_templates', $stepTimer)
	Else
		BarbarousShoreFullApplyHeroTemplate($barbarous_shore_full_kahmu_index, $BARBAROUS_SHORE_FULL_KAHMU_TEMPLATE)
		BarbarousShoreFullApplyHeroTemplate($barbarous_shore_full_melonni_index, $BARBAROUS_SHORE_FULL_MELONNI_TEMPLATE)
		BarbarousShoreFullApplyHeroTemplate($barbarous_shore_full_mox_index, $BARBAROUS_SHORE_FULL_MOX_TEMPLATE)
		BarbarousShoreFullApplyHeroTemplate($barbarous_shore_full_tahlkora_index, $BARBAROUS_SHORE_FULL_TAHLKORA_TEMPLATE)
		BarbarousShoreFullApplyHeroTemplate($barbarous_shore_full_morgahn_index, $BARBAROUS_SHORE_FULL_MORGAHN_TEMPLATE)
		BarbarousShoreFullApplyHeroTemplate($barbarous_shore_full_mow_index, $BARBAROUS_SHORE_FULL_MOW_TEMPLATE)
		BarbarousShoreFullApplyHeroTemplate($barbarous_shore_full_olias_index, $BARBAROUS_SHORE_FULL_OLIAS_TEMPLATE)
		RandomSleep(250)
		BarbarousShoreFullLogTiming('setup.team_build.load_templates', $stepTimer)
	EndIf

	$stepTimer = TimerInit()
	DisableAllHeroSkills($barbarous_shore_full_kahmu_index)
	DisableAllHeroSkills($barbarous_shore_full_melonni_index)
	DisableAllHeroSkills($barbarous_shore_full_mox_index)
	DisableAllHeroSkills($barbarous_shore_full_tahlkora_index)
	DisableAllHeroSkills($barbarous_shore_full_morgahn_index)
	DisableAllHeroSkills($barbarous_shore_full_mow_index)
	DisableAllHeroSkills($barbarous_shore_full_olias_index)
	EnableHeroSkillSlot($barbarous_shore_full_kahmu_index, $BARBAROUS_SHORE_FULL_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_full_melonni_index, $BARBAROUS_SHORE_FULL_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_full_mox_index, $BARBAROUS_SHORE_FULL_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_full_tahlkora_index, $BARBAROUS_SHORE_FULL_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_full_morgahn_index, $BARBAROUS_SHORE_FULL_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_full_mow_index, $BARBAROUS_SHORE_FULL_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($barbarous_shore_full_olias_index, $BARBAROUS_SHORE_FULL_HERO_SUPPORT_SKILL)
	BarbarousShoreFullLogTiming('setup.team_build.configure_skills', $stepTimer)

	$stepTimer = TimerInit()
	ResetBarbarousShoreFullHeroSupportScheduler()
	$barbarous_shore_full_support_enabled = True
	BarbarousShoreFullLogTiming('setup.team_build.finalize', $stepTimer)

	If $BARBAROUS_SHORE_FULL_EXPAND_HERO_PANELS Then
		$stepTimer = TimerInit()
		SupportTeamOpenHeroPanels('Barbarous Shore Full')
		BarbarousShoreFullLogTiming('setup.team_build.open_hero_panels', $stepTimer)
	EndIf
	Return $SUCCESS
EndFunc


Func BarbarousShoreFullApplyHeroTemplate($heroIndex, $templateCode)
	If HeroHasTemplate($heroIndex, $templateCode) Then Return
	LoadSkillTemplate($templateCode, $heroIndex)
	RandomSleep(150)
EndFunc


Func BarbarousShoreFullLogTiming($label, $timer)
	If Not $BARBAROUS_SHORE_FULL_TIMING_LOG Then Return
	Info('Barbarous timing: ' & $label & '=' & Int(TimerDiff($timer)) & 'ms')
EndFunc


;~ Skill state per event and per heartbeat, same shape as the Focus Hanaku log
Func BarbarousShoreFullLogInit()
	$barbarous_shore_full_log_file = @ScriptDir & '/logs/barbarous_full_debug-' & GetCharacterName() & '.csv'
	$barbarous_shore_full_log_handle = FileOpen($barbarous_shore_full_log_file, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	$barbarous_shore_full_log_timer = TimerInit()
	$barbarous_shore_full_log_heartbeat_timer = TimerInit()
	Info('BarbarousShoreFull CSV: ' & $barbarous_shore_full_log_file)
	If $barbarous_shore_full_log_handle == -1 Then Return
	FileWriteLine($barbarous_shore_full_log_handle, 'time_ms;event;energy;hp;x;y;sf_ms;sf_up;casting;dp_ms;de_ms;ds_ms;sf_ready;dp_ready;de_ready;ds_ready;note')
EndFunc


Func BarbarousShoreFullLogClose()
	If $barbarous_shore_full_log_handle == -1 Then Return
	FileClose($barbarous_shore_full_log_handle)
	$barbarous_shore_full_log_handle = -1
EndFunc


Func BarbarousShoreFullLogHeartbeat()
	If TimerDiff($barbarous_shore_full_log_heartbeat_timer) < $BARBAROUS_SHORE_FULL_LOG_HEARTBEAT_MS Then Return
	BarbarousShoreFullLogWrite('tick')
	$barbarous_shore_full_log_heartbeat_timer = TimerInit()
EndFunc


Func BarbarousShoreFullLogWrite($eventName, $note = '')
	If $barbarous_shore_full_log_handle == -1 Then Return
	Local $me = GetMyAgent()
	FileWriteLine($barbarous_shore_full_log_handle, Int(TimerDiff($barbarous_shore_full_log_timer)) & ';' & $eventName & ';' & Round(GetEnergy(), 1) & ';' & Round(DllStructGetData($me, 'HealthPercent')) & ';' & _
		Round(DllStructGetData($me, 'X')) & ';' & Round(DllStructGetData($me, 'Y')) & ';' & _
		GetEffectTimeRemaining($ID_SHADOW_FORM) & ';' & (GetEffect($ID_SHADOW_FORM) <> Null) & ';' & IsCasting($me) & ';' & _
		GetEffectTimeRemaining($ID_DEADLY_PARADOX) & ';' & _
		GetEffectTimeRemaining($ID_DARK_ESCAPE) & ';' & GetEffectTimeRemaining($ID_DWARVEN_STABILITY) & ';' & _
		IsRecharged($BARBAROUS_SHORE_FULL_SHADOWFORM) & ';' & IsRecharged($BARBAROUS_SHORE_FULL_DEADLY_PARADOX) & ';' & _
		IsRecharged($BARBAROUS_SHORE_FULL_DARK_ESCAPE) & ';' & IsRecharged($BARBAROUS_SHORE_FULL_DWARVEN_STABILITY) & ';' & $note)
	FileFlush($barbarous_shore_full_log_handle)
EndFunc


Func BarbarousShoreFullLogSF($eventName, $sfRemaining = -1, $energy = -1, $extra = '')
	BarbarousShoreFullLogWrite($eventName, $extra)
	If Not $BARBAROUS_SHORE_FULL_SF_LOGGING Then Return
	Local $msg = 'Barbarous SF: ' & $eventName
	If $sfRemaining >= 0 Then $msg &= ';sf=' & Int($sfRemaining)
	If $energy >= 0 Then $msg &= ';e=' & Round($energy, 1)
	If $extra <> '' Then $msg &= ';' & $extra
	Info($msg)
EndFunc


Func GoToBarbarousShoreFull()
	TravelToOutpost($ID_CAMP_HOJANU, $district_name)
	While GetMapID() <> $ID_BARBAROUS_SHORE
		Info('Moving to Barbarous Shore')
		BarbarousShoreFullWalkToPortal()
		RandomSleep(1000)
		WaitMapLoading($ID_BARBAROUS_SHORE, 10000, 2000)
	WEnd
	ClearChestsMap()
	CaptureBarbarousShoreFullPortalAnchor()
	FlagBarbarousShoreFullSupportHeroesAtPortal()
EndFunc


;~ The rezone moves the outpost spawn point next to the portal, so start the path at the closest waypoint
Func BarbarousShoreFullWalkToPortal()
	Local $me = GetMyAgent()
	Local $startIndex = 0
	Local $closestDistance = 1000000
	For $i = 0 To UBound($BARBAROUS_SHORE_FULL_PORTAL_PATH) - 1
		Local $distance = GetDistanceToPoint($me, $BARBAROUS_SHORE_FULL_PORTAL_PATH[$i][0], $BARBAROUS_SHORE_FULL_PORTAL_PATH[$i][1])
		If $distance < $closestDistance Then
			$closestDistance = $distance
			$startIndex = $i
		EndIf
	Next
	For $i = $startIndex To UBound($BARBAROUS_SHORE_FULL_PORTAL_PATH) - 2
		MoveTo($BARBAROUS_SHORE_FULL_PORTAL_PATH[$i][0], $BARBAROUS_SHORE_FULL_PORTAL_PATH[$i][1])
	Next
	Move($BARBAROUS_SHORE_FULL_PORTAL_PATH[UBound($BARBAROUS_SHORE_FULL_PORTAL_PATH) - 1][0], $BARBAROUS_SHORE_FULL_PORTAL_PATH[UBound($BARBAROUS_SHORE_FULL_PORTAL_PATH) - 1][1])
EndFunc


;~ Out and straight back in once, so every later resign respawns next to the Barbarous Shore portal
Func BarbarousShoreFullRezoneCampHojanu()
	BarbarousShoreFullWalkToPortal()
	RandomSleep(1500)
	If Not WaitMapLoading($ID_BARBAROUS_SHORE, 10000, 500) Then Return False

	MoveTo($BARBAROUS_SHORE_FULL_OUTPOST_RETURN[0], $BARBAROUS_SHORE_FULL_OUTPOST_RETURN[1])
	For $attempt = 1 To $BARBAROUS_SHORE_FULL_REZONE_ATTEMPTS
		MoveTo($BARBAROUS_SHORE_FULL_REZONE_DEEP[0], $BARBAROUS_SHORE_FULL_REZONE_DEEP[1])
		RandomSleep(500)
		If WaitMapLoading($ID_CAMP_HOJANU, 6000, 500) Then Return SupportTeamStabilizeAfterTravel($ID_CAMP_HOJANU, 10000, 250)
	Next
	Return False
EndFunc


Func ResetBarbarousShoreFullHeroSupportScheduler()
	$barbarous_shore_full_next_mh_tick = 0
	$barbarous_shore_full_next_cautery_tick = 0
	$barbarous_shore_full_mh_rotation_index = 0
	$barbarous_shore_full_cautery_rotation_index = 0
EndFunc


Func FlagBarbarousShoreFullSupportHeroesAtPortal()
	If Not $barbarous_shore_full_support_enabled Then Return
	If GetMapID() <> $ID_BARBAROUS_SHORE Then Return

	Local $flagX = $barbarous_shore_full_portal_anchor_x
	Local $flagY = $barbarous_shore_full_portal_anchor_y
	If $flagX == 0 And $flagY == 0 Then
		CaptureBarbarousShoreFullPortalAnchor()
		$flagX = $barbarous_shore_full_portal_anchor_x
		$flagY = $barbarous_shore_full_portal_anchor_y
	EndIf

	SupportTeamDebug($BARBAROUS_SHORE_FULL_SUPPORT_DEBUG_VERBOSE, 'Barbarous support: flag heroes at portal X=' & $flagX & ' Y=' & $flagY)
	For $i = 1 To $BARBAROUS_SHORE_FULL_PORTAL_FLAG_MAX_RETRIES
		BarbarousShoreFullCommandAllSupportHeroesTo($flagX, $flagY)
		RandomSleep(140)
		If BarbarousShoreFullAreAllSupportHeroesAt($flagX, $flagY, $BARBAROUS_SHORE_FULL_PORTAL_FLAG_VERIFY_RANGE) Then Return
	Next
	Warn('Barbarous support: not all heroes reached portal flag before run start')
EndFunc


Func CaptureBarbarousShoreFullPortalAnchor()
	If GetMapID() <> $ID_BARBAROUS_SHORE Then Return
	Local $me = GetMyAgent()
	If $me == Null Then Return
	$barbarous_shore_full_portal_anchor_x = Int(DllStructGetData($me, 'X'))
	$barbarous_shore_full_portal_anchor_y = Int(DllStructGetData($me, 'Y'))
	SupportTeamDebug($BARBAROUS_SHORE_FULL_SUPPORT_DEBUG_VERBOSE, 'Barbarous support: captured portal anchor X=' & $barbarous_shore_full_portal_anchor_x & ' Y=' & $barbarous_shore_full_portal_anchor_y)
EndFunc


Func BarbarousShoreFullCommandAllSupportHeroesTo($x, $y)
	CommandHero($barbarous_shore_full_kahmu_index, $x, $y)
	CommandHero($barbarous_shore_full_melonni_index, $x, $y)
	CommandHero($barbarous_shore_full_mox_index, $x, $y)
	CommandHero($barbarous_shore_full_tahlkora_index, $x, $y)
	CommandHero($barbarous_shore_full_morgahn_index, $x, $y)
	CommandHero($barbarous_shore_full_mow_index, $x, $y)
	CommandHero($barbarous_shore_full_olias_index, $x, $y)
EndFunc


Func BarbarousShoreFullAreAllSupportHeroesAt($x, $y, $maxDist)
	If Not BarbarousShoreFullIsHeroAtFlag($barbarous_shore_full_kahmu_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreFullIsHeroAtFlag($barbarous_shore_full_melonni_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreFullIsHeroAtFlag($barbarous_shore_full_mox_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreFullIsHeroAtFlag($barbarous_shore_full_tahlkora_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreFullIsHeroAtFlag($barbarous_shore_full_morgahn_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreFullIsHeroAtFlag($barbarous_shore_full_mow_index, $x, $y, $maxDist) Then Return False
	If Not BarbarousShoreFullIsHeroAtFlag($barbarous_shore_full_olias_index, $x, $y, $maxDist) Then Return False
	Return True
EndFunc


Func BarbarousShoreFullIsHeroAtFlag($heroIndex, $x, $y, $maxDist)
	If $heroIndex <= 0 Then Return False
	Local $heroAgent = GetAgentByID(GetHeroID($heroIndex))
	If $heroAgent == Null Then Return False
	Return GetDistanceToPoint($heroAgent, $x, $y) <= $maxDist
EndFunc


Func TickBarbarousShoreFullHeroSupportCasts()
	If Not $barbarous_shore_full_support_enabled Then Return
	If GetMapID() <> $ID_BARBAROUS_SHORE Then Return
	Local $mhOrder[] = [$barbarous_shore_full_melonni_index, $barbarous_shore_full_kahmu_index, $barbarous_shore_full_mox_index, $barbarous_shore_full_tahlkora_index]
	Local $cauteryOrder[] = [$barbarous_shore_full_morgahn_index, $barbarous_shore_full_mow_index, $barbarous_shore_full_olias_index]

	If $barbarous_shore_full_next_mh_tick == 0 Or TimerDiff($barbarous_shore_full_next_mh_tick) >= $BARBAROUS_SHORE_FULL_MH_CAST_INTERVAL_MS Then
		Local $mhCount = UBound($mhOrder)
		For $i = 0 To $mhCount - 1
			Local $mhPos = Mod($barbarous_shore_full_mh_rotation_index + $i, $mhCount)
			Local $mhHero = $mhOrder[$mhPos]
			If IsRecharged($BARBAROUS_SHORE_FULL_HERO_SUPPORT_SKILL, $mhHero) Then
				SupportTeamDebug($BARBAROUS_SHORE_FULL_SUPPORT_DEBUG_VERBOSE, 'Barbarous support: MH cast hero index=' & $mhHero)
				UseHeroSkill($mhHero, $BARBAROUS_SHORE_FULL_HERO_SUPPORT_SKILL)
				$barbarous_shore_full_mh_rotation_index = Mod($mhPos + 1, $mhCount)
				$barbarous_shore_full_next_mh_tick = TimerInit()
				ExitLoop
			EndIf
		Next
	EndIf

	If $barbarous_shore_full_next_cautery_tick == 0 Or TimerDiff($barbarous_shore_full_next_cautery_tick) >= $BARBAROUS_SHORE_FULL_CAUTERY_CAST_INTERVAL_MS Then
		Local $cauteryCount = UBound($cauteryOrder)
		For $i = 0 To $cauteryCount - 1
			Local $cauteryPos = Mod($barbarous_shore_full_cautery_rotation_index + $i, $cauteryCount)
			Local $cauteryHero = $cauteryOrder[$cauteryPos]
			If IsRecharged($BARBAROUS_SHORE_FULL_HERO_SUPPORT_SKILL, $cauteryHero) Then
				SupportTeamDebug($BARBAROUS_SHORE_FULL_SUPPORT_DEBUG_VERBOSE, 'Barbarous support: Cautery cast hero index=' & $cauteryHero)
				UseHeroSkill($cauteryHero, $BARBAROUS_SHORE_FULL_HERO_SUPPORT_SKILL)
				$barbarous_shore_full_cautery_rotation_index = Mod($cauteryPos + 1, $cauteryCount)
				$barbarous_shore_full_next_cautery_tick = TimerInit()
				ExitLoop
			EndIf
		Next
	EndIf
EndFunc


;~ One chest spot only: run the recorded approach, loot the chest if it spawned, otherwise let the farm resign
;~ Whole map: walk the recorded route spot by spot and open every chest on the way
Func BarbarousShoreFullChestFarmLoop()
	If FindInInventory($ID_LOCKPICK)[0] == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf
	If GetMapID() <> $ID_BARBAROUS_SHORE Then Return $FAIL

	Info('Starting full map chest run')
	ClearChestsMap()
	FlagBarbarousShoreFullSupportHeroesAtPortal()
	ResetBarbarousShoreFullHeroSupportScheduler()

	Local $openedChests = 0
	Local $spotCount = UBound($BARBAROUS_SHORE_FULL_ROUTE_WAYPOINTS)
	Local $routeTimer = TimerInit()
	For $i = 0 To $spotCount - 1
		If IsPlayerDead() Then
			Warn('Barbarous full run: player dead, aborting run for resign/restart')
			Return $FAIL
		EndIf
		If TimerDiff($routeTimer) > $BARBAROUS_SHORE_FULL_ROUTE_TIMEOUT_MS Then
			Warn('Barbarous full run: route budget exceeded at spot ' & ($i + 1) & '/' & $spotCount & ', resigning for a fresh attempt')
			ExitLoop
		EndIf

		Info('Running to spot ' & ($i + 1) & '/' & $spotCount)
		If BarbarousShoreFullRunTo($BARBAROUS_SHORE_FULL_ROUTE_WAYPOINTS[$i][0], $BARBAROUS_SHORE_FULL_ROUTE_WAYPOINTS[$i][1]) == $FAIL Then
			If IsPlayerDead() Then Return $FAIL
			Warn('Barbarous full run: spot ' & ($i + 1) & ' blocked, skipping it')
			ContinueLoop
		EndIf

		If FindAndOpenChests($BARBAROUS_SHORE_FULL_CHEST_OPEN_RANGE, DefendWhileOpeningChestsBarbarousShoreFull) Then
			$openedChests += 1
			Info('Opened chest #' & $openedChests & ' at spot ' & ($i + 1))
		EndIf
	Next

	Info('Opened ' & $openedChests & ' chest(s) on the full route')
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Walk to a point while keeping the four important skills up
Func BarbarousShoreFullRunTo($x, $y)
	Local $me = GetMyAgent()
	If $me == Null Then Return $FAIL
	Local $moveTimer = TimerInit()
	Local $blockedCounter = 0
	Move($x, $y)
	While IsPlayerAlive() And GetDistanceToPoint($me, $x, $y) > $BARBAROUS_SHORE_FULL_WAYPOINT_REACH_RANGE
		If TimerDiff($moveTimer) > $BARBAROUS_SHORE_FULL_WAYPOINT_TIMEOUT_MS Then
			Warn('Barbarous run: point ' & Int($x) & ',' & Int($y) & ' not reached in time')
			Return $FAIL
		EndIf

		BarbarousShoreFullMaintainBuffs()
		TickBarbarousShoreFullHeroSupportCasts()

		If Not IsPlayerMoving() Then
			$blockedCounter += 1
			Move($x, $y)
		Else
			$blockedCounter = 0
		EndIf

		If $blockedCounter >= $BARBAROUS_SHORE_FULL_BLOCKED_TICKS_BEFORE_UNSTUCK Then
			$blockedCounter = 0
			If BarbarousShoreFullTryBreakBodyblock($x, $y) Then Move($x, $y)
		EndIf

		RandomSleep(250)
		$me = GetMyAgent()
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Perma Shadow Form: request Shadow Form and slip Deadly Paradox into its cast time
Func BarbarousShoreFullMaintainShadowForm()
	Local Static $sfQueueTimer = 0
	If Not IsRecharged($BARBAROUS_SHORE_FULL_SHADOWFORM) Or GetEnergy() < $BARBAROUS_SHORE_FULL_SF_DP_MIN_ENERGY Then Return GetEffect($ID_SHADOW_FORM) <> Null
	If $sfQueueTimer <> 0 And TimerDiff($sfQueueTimer) <= $BARBAROUS_SHORE_FULL_SF_QUEUE_RETRY_MS Then Return GetEffect($ID_SHADOW_FORM) <> Null

	;~ Deadly Paradox first guarantees it is already up when Shadow Form finishes casting
	Local $paradoxReady = IsRecharged($BARBAROUS_SHORE_FULL_DEADLY_PARADOX)
	If $paradoxReady Then UseSkill($BARBAROUS_SHORE_FULL_DEADLY_PARADOX)
	UseSkill($BARBAROUS_SHORE_FULL_SHADOWFORM)
	$sfQueueTimer = TimerInit()
	;~ Dark Escape follows every Shadow Form cast, not only the ones Deadly Paradox could speed up
	$barbarous_shore_full_dark_escape_pending = True
	BarbarousShoreFullLogSF('dp_sf', -1, Round(GetEnergy(), 1), 'ctx=move;dp=' & ($paradoxReady ? 1 : 0))

	Return GetEffect($ID_SHADOW_FORM) <> Null
EndFunc


;~ Shadow Form, Dwarven Stability, Dark Escape and the cripple cleaner; skills 6 to 8 are backup only
Func BarbarousShoreFullMaintainBuffs()
	If IsPlayerDead() Then Return
	BarbarousShoreFullLogHeartbeat()
	If Not BarbarousShoreFullMaintainShadowForm() Then Return

	;~ Dwarven Stability stretches the stance but needs a 0.5s cast, so let it land before touching the stance
	If GetEffect($ID_DWARVEN_STABILITY) == Null And IsRecharged($BARBAROUS_SHORE_FULL_DWARVEN_STABILITY) And GetEnergy() >= 5 Then
		UseSkill($BARBAROUS_SHORE_FULL_DWARVEN_STABILITY)
		BarbarousShoreFullLogSF('ds_cast', -1, Round(GetEnergy(), 1), 'ctx=buff')
		Local $stabilityTimer = TimerInit()
		While GetEffect($ID_DWARVEN_STABILITY) == Null And TimerDiff($stabilityTimer) < $BARBAROUS_SHORE_FULL_DWARVEN_STABILITY_CAST_MS
			Sleep(20)
		WEnd
	EndIf

	;~ Dark Escape is a stance too: it may only take the slot once the Shadow Form and Dwarven Stability casts are done
	If $barbarous_shore_full_dark_escape_pending And Not IsCasting(GetMyAgent()) Then
		If Not IsRecharged($BARBAROUS_SHORE_FULL_DARK_ESCAPE) Then
			BarbarousShoreFullLogSF('de_skip_recharge', -1, Round(GetEnergy(), 1), 'ctx=buff')
			$barbarous_shore_full_dark_escape_pending = False
		ElseIf GetEnergy() >= 5 Then
			UseSkill($BARBAROUS_SHORE_FULL_DARK_ESCAPE)
			BarbarousShoreFullLogSF('de_cast', -1, Round(GetEnergy(), 1), 'ctx=buff')
			$barbarous_shore_full_dark_escape_pending = False
		Else
			BarbarousShoreFullLogSF('de_skip_energy', -1, Round(GetEnergy(), 1), 'ctx=buff')
		EndIf
	EndIf

	If GetEffect($ID_CRIPPLED) <> Null And IsRecharged($BARBAROUS_SHORE_FULL_I_AM_UNSTOPPABLE) _
		And GetEnergy() >= $BARBAROUS_SHORE_FULL_IAU_MIN_ENERGY Then
		UseSkill($BARBAROUS_SHORE_FULL_I_AM_UNSTOPPABLE)
	EndIf
EndFunc


Func DefendWhileOpeningChestsBarbarousShoreFull()
	TickBarbarousShoreFullHeroSupportCasts()
	BarbarousShoreFullMaintainBuffs()
EndFunc


;~ Bodyblock escape: Heart of Shadow teleports off the block, Deaths Charge hops forward, then a side step
Func BarbarousShoreFullTryBreakBodyblock($targetX, $targetY)
	Local $me = GetMyAgent()
	If $me == Null Then Return False
	Local $startX = DllStructGetData($me, 'X')
	Local $startY = DllStructGetData($me, 'Y')

	;~ Dark Escape only needs an instant and 5 energy, so it goes before the escape skills burn that energy
	If $barbarous_shore_full_dark_escape_pending And GetEnergy() >= 5 Then Return False

	If IsRecharged($BARBAROUS_SHORE_FULL_HEART_OF_SHADOW) And GetEnergy() >= 5 Then
		Local $npc = GetNPCInTheBackBarbarousShoreFull($targetX, $targetY)
		If $npc == Null Then $npc = $me
		UseSkill($BARBAROUS_SHORE_FULL_HEART_OF_SHADOW, $npc)
		BarbarousShoreFullLogWrite('hos_break')
		RandomSleep(100)
	EndIf
	If IsRecharged($BARBAROUS_SHORE_FULL_DEATHS_CHARGE) And GetEnergy() >= 5 Then
		Local $chargeTarget = GetTargetForDeathsChargeBarbarousShoreFull($targetX, $targetY)
		If $chargeTarget <> Null Then
			UseSkill($BARBAROUS_SHORE_FULL_DEATHS_CHARGE, $chargeTarget)
			BarbarousShoreFullLogWrite('dc_break')
			RandomSleep(100)
		Else
			BarbarousShoreFullLogWrite('dc_no_target')
		EndIf
	EndIf

	Local $dx = $targetX - $startX
	Local $dy = $targetY - $startY
	Local $len = Sqrt(($dx * $dx) + ($dy * $dy))
	If $len >= 1 Then
		Local $rightX = $dy / $len
		Local $rightY = -$dx / $len
		Move($startX + ($rightX * $BARBAROUS_SHORE_FULL_BYPASS_SIDE_STEP), $startY + ($rightY * $BARBAROUS_SHORE_FULL_BYPASS_SIDE_STEP))
		RandomSleep(100)
	EndIf
	Move($targetX, $targetY)
	RandomSleep(100)

	$me = GetMyAgent()
	If $me == Null Then Return False
	Local $freed = ComputeDistance($startX, $startY, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y')) >= 120
	If Not $freed Then BarbarousShoreFullLogWrite('break_failed')
	Return $freed
EndFunc


Func GetNPCInTheBackBarbarousShoreFull($x, $y)
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


;~ Farthest foe still inside teleport range that is meaningfully closer to the goal
Func GetTargetForDeathsChargeBarbarousShoreFull($x, $y, $leadDistance = 300)
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST)
	If Not IsArray($foes) Or UBound($foes) <= 0 Then Return Null
	Local $myDistanceToGoal = GetDistanceToPoint($me, $x, $y)
	Local $bestFoe = Null
	Local $bestDistance = 0
	For $foe In $foes
		If ($myDistanceToGoal - GetDistanceToPoint($foe, $x, $y)) < $leadDistance Then ContinueLoop
		Local $foeDistance = GetDistance($me, $foe)
		If $foeDistance > $bestDistance Then
			$bestDistance = $foeDistance
			$bestFoe = $foe
		EndIf
	Next
	Return $bestFoe
EndFunc
