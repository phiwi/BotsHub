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

Opt('MustDeclareVars', True)


; ==== Constants ====
Global Const $BRIGHTCLAW_PLAYER_SKILLBAR = 'OwhjAyi84QVTXTlTnNfT+gNQylA'
Global Const $BRIGHTCLAW_HERO_SKILLBAR = 'OQijEqmMKO84bMAAAAAAAAAAAA'
Global Const $BRIGHTCLAW_FARM_DURATION = 5 * 60 * 1000

Global Const $BRIGHTCLAW_OUTPOST_ID = $ID_JADE_FLATS_KURZICK ; 390
Global Const $BRIGHTCLAW_EXPLO_ID = $ID_MELANDRUS_HOPE ; 201
Global Const $BRIGHTCLAW_BOSS_MODEL_ID = 2038

Global Const $BRIGHTCLAW_HERO_PARTY_ID = $ID_GENERAL_MORGAHN
Global Const $BRIGHTCLAW_HERO_INDEX = 1

; Hero skills on BRIGHTCLAW_HERO_SKILLBAR
Global Const $BRIGHTCLAW_HERO_SPEED_1 = 1
Global Const $BRIGHTCLAW_HERO_SPEED_2 = 2

; Player skill slots
Global Const $BRIGHT_PAINFUL_BOND = 1
Global Const $BRIGHT_SOS = 2
Global Const $BRIGHT_BLOODSONG = 3
Global Const $BRIGHT_SHADOWSONG = 4
Global Const $BRIGHT_PAIN = 5
Global Const $BRIGHT_ARMOR_UNFEEL = 6
Global Const $BRIGHT_DARK_ESCAPE = 7
Global Const $BRIGHT_PAIN_INVERTER = 8
Global Const $BRIGHT_PAINFUL_BOND_MIN_ENERGY = 15
Global Const $BRIGHT_PAIN_INVERTER_MIN_ENERGY = 10

Global Const $BRIGHTCLAW_PORTAL_X = 14624
Global Const $BRIGHTCLAW_PORTAL_Y = 20973
Global Const $BRIGHTCLAW_HERO_RETREAT_X = 14051
Global Const $BRIGHTCLAW_HERO_RETREAT_Y = 20994
Global Const $BRIGHTCLAW_NEST_X = 3115
Global Const $BRIGHTCLAW_NEST_Y = 18499
Global Const $BRIGHTCLAW_NEST_STEP_RIGHT_X = 3140
Global Const $BRIGHTCLAW_NEST_STEP_RIGHT_Y = 18520
Global Const $BRIGHTCLAW_PULL_SPOT_X = 3700
Global Const $BRIGHTCLAW_PULL_SPOT_Y = 18583
Global Const $BRIGHTCLAW_DEBUG_COORDS = True
Global Const $BRIGHTCLAW_MANUAL_TUNE_MODE = False
Global Const $BRIGHTCLAW_DISABLE_RESIGN_FOR_TESTS = True
Global Const $BRIGHTCLAW_RECORDER_INTERVAL_MS = 200
Global Const $BRIGHTCLAW_RECORDER_FILE = @ScriptDir & '\\doc\\brightclaw_manual_recorder.log'

Global $brightclaw_farm_setup = False
Global $brightclaw_recorder_active = False
Global $brightclaw_recorder_handle = -1
Global $brightclaw_last_logged_skill = -1
Global $brightclaw_recorder_start_timer = Null
Global $brightclaw_last_boss_death_x = 0
Global $brightclaw_last_boss_death_y = 0
Global $brightclaw_last_recast_block_log = Null


;~ Main method to farm Chkkr Brightclaw
Func BrightclawFarm()
	If Not $brightclaw_farm_setup And SetupBrightclawFarm() == $FAIL Then Return $PAUSE
	If GoToMelandrusHope() == $FAIL Then Return $FAIL

	Local $result = BrightclawFarmLoop()
	If $result == $PAUSE Then Return $PAUSE
	StopBrightclawRecorder()
	If Not $BRIGHTCLAW_DISABLE_RESIGN_FOR_TESTS Then ResignAndReturnToOutpost($BRIGHTCLAW_OUTPOST_ID)
	Return $result
EndFunc


;~ Setup player and hero for Brightclaw farm
Func SetupBrightclawFarm()
	Info('Setting up farm')
	If TravelToOutpost($BRIGHTCLAW_OUTPOST_ID, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)

	If SetupPlayerBrightclawFarm() == $FAIL Then Return $FAIL
	If SetupTeamBrightclawFarm() == $FAIL Then Return $FAIL

	$brightclaw_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerBrightclawFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
		LoadSkillTemplate($BRIGHTCLAW_PLAYER_SKILLBAR)
	Else
		Warn('Should run this farm as assassin')
		Return $FAIL
	EndIf
	RandomSleep(250)
	Return $SUCCESS
EndFunc


Func SetupTeamBrightclawFarm()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up team')
	LeaveParty()
	RandomSleep(500)
	AddHero($BRIGHTCLAW_HERO_PARTY_ID)
	RandomSleep(250)
	LoadSkillTemplate($BRIGHTCLAW_HERO_SKILLBAR, $BRIGHTCLAW_HERO_INDEX)
	RandomSleep(250)
	DisableAllHeroSkills($BRIGHTCLAW_HERO_INDEX)
	RandomSleep(500)

	If GetPartySize() <> 2 Then
		Warn('Could not set up party correctly. Team size different than 2')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Melandru's Hope
Func GoToMelandrusHope()
	TravelToOutpost($BRIGHTCLAW_OUTPOST_ID, $district_name)
	While GetMapID() <> $BRIGHTCLAW_EXPLO_ID
		Info('Moving to Melandru''s Hope')
		MoveTo(-4069, -9535)
		If WaitForPlayerNearPoint(-4069, -9535, 250, 12000) == $FAIL Then Return $FAIL

		MoveTo(-6600, -10257)
		If WaitForPlayerNearPoint(-6600, -10257, 250, 12000) == $FAIL Then Return $FAIL

		Move(-7200, -10600)
		If Not WaitMapLoading($BRIGHTCLAW_EXPLO_ID, 15000, 1000) Then Return $FAIL
	WEnd
	Return $SUCCESS
EndFunc


;~ Brightclaw run logic in explorable
Func BrightclawFarmLoop()
	If GetMapID() <> $BRIGHTCLAW_EXPLO_ID Then Return $FAIL

	Info('Melandru''s Hope reached')
	If FollowPathToBrightclaw() == $FAIL Then Return $FAIL
	If PullBrightclaw() == $FAIL Then Return $FAIL

	If $BRIGHTCLAW_MANUAL_TUNE_MODE Then
		StartBrightclawRecorder()
		Info('Manual tune mode active. Control character manually now')
		Info('Recorder file: ' & $BRIGHTCLAW_RECORDER_FILE)
		Info('Bot paused after pull. Disable manual mode when tuning is done')
		Return $PAUSE
	EndIf

	If KillBrightclaw() == $FAIL Then Return $FAIL
	If LootBrightclawFast() == $FAIL Then Return $FAIL
	StopBrightclawRecorder()
	Return $SUCCESS
EndFunc


Func FollowPathToBrightclaw()
	Local $path[22][2] = [ _
		[14624, 20973], [14051, 20994], [13486, 20933], [12926, 20768], _
		[12481, 20405], [12088, 19977], [11694, 19547], [11310, 19110], _
		[10925, 18670], [10488, 18290], [9943, 18114], [9360, 18123], _
		[8781, 18177], [8205, 18264], [7636, 18392], [7070, 18518], _
		[6492, 18477], [5923, 18349], [5356, 18217], [4774, 18223], _
		[4202, 18332], [3699, 18600] _
	]

	Local $runTimer = TimerInit()
	Local $heroRetreated = False
	Local $midPointIndex = 10

	InitializeHeroSpeedSupport()
	ChangeWeaponSet(1)

	For $i = 0 To UBound($path) - 1
		If IsPlayerDead() Then Return $FAIL
		MoveTo($path[$i][0], $path[$i][1], 25, 0)

		Local $waypointTimer = TimerInit()
		While GetDistanceToPoint(GetMyAgent(), $path[$i][0], $path[$i][1]) > 350
			If IsPlayerDead() Then Return $FAIL

			If TimerDiff($waypointTimer) > 10000 Then
				MoveTo($path[$i][0], $path[$i][1], 25, 0)
				$waypointTimer = TimerInit()
			EndIf

			Sleep(250)
		WEnd

		; Let hero naturally follow until path midpoint, then boost once more and retreat.
		If Not $heroRetreated And $i >= $midPointIndex Then
			If TimerDiff($runTimer) >= 10000 Then
				Info('Path midpoint reached. Morgahn casts Make Haste and retreats')
				UseHeroSkill($BRIGHTCLAW_HERO_INDEX, $BRIGHTCLAW_HERO_SPEED_2, GetMyAgent())
				RandomSleep(200)
				CommandHero($BRIGHTCLAW_HERO_INDEX, $BRIGHTCLAW_HERO_RETREAT_X, $BRIGHTCLAW_HERO_RETREAT_Y)
				$heroRetreated = True
			EndIf
		EndIf
	Next

	If Not $heroRetreated Then
		UseHeroSkill($BRIGHTCLAW_HERO_INDEX, $BRIGHTCLAW_HERO_SPEED_2, GetMyAgent())
		RandomSleep(200)
		CommandHero($BRIGHTCLAW_HERO_INDEX, $BRIGHTCLAW_HERO_RETREAT_X, $BRIGHTCLAW_HERO_RETREAT_Y)
	EndIf
	Return $SUCCESS
EndFunc


Func InitializeHeroSpeedSupport()
	CancelHero($BRIGHTCLAW_HERO_INDEX)
	RandomSleep(250)
	UseHeroSkill($BRIGHTCLAW_HERO_INDEX, $BRIGHTCLAW_HERO_SPEED_1, GetMyAgent())
	RandomSleep(250)
	UseHeroSkill($BRIGHTCLAW_HERO_INDEX, $BRIGHTCLAW_HERO_SPEED_2, GetMyAgent())
EndFunc


Func ParkHeroAtPortal()
	Info('10 seconds reached. Parking Morgahn at portal')
	UseHeroSkill($BRIGHTCLAW_HERO_INDEX, $BRIGHTCLAW_HERO_SPEED_2, GetMyAgent())
	RandomSleep(300)
	CommandHero($BRIGHTCLAW_HERO_INDEX, $BRIGHTCLAW_PORTAL_X, $BRIGHTCLAW_PORTAL_Y)
EndFunc


Func PullBrightclaw()
	Info('Targeting Brightclaw')
	ChangeWeaponSet(1)
	MoveTo($BRIGHTCLAW_PULL_SPOT_X, $BRIGHTCLAW_PULL_SPOT_Y, 25, 0)
	If WaitForPlayerNearPoint($BRIGHTCLAW_PULL_SPOT_X, $BRIGHTCLAW_PULL_SPOT_Y, 260, 7000) == $FAIL Then Return $FAIL
	LogOwnPosition('Pull spot reached')

	Local $boss = Null
	For $attempt = 1 To 4
		$boss = GetBossForPull()
		If $boss <> Null Then ExitLoop

		; Small nudges improve agent refresh when boss is just outside loaded bubble.
		MoveTo($BRIGHTCLAW_PULL_SPOT_X + 50 * $attempt, $BRIGHTCLAW_PULL_SPOT_Y - 30 * $attempt, 25, 0)
		WaitForPlayerNearPoint($BRIGHTCLAW_PULL_SPOT_X + 50 * $attempt, $BRIGHTCLAW_PULL_SPOT_Y - 30 * $attempt, 220, 2000)
		Sleep(200)
	Next

	If $boss == Null Then
		Warn('Brightclaw not found for pull')
		Return $FAIL
	EndIf

	RandomSleep(250)
	Attack($boss)
	RandomSleep(2500)

	If $BRIGHTCLAW_MANUAL_TUNE_MODE Then
		Info('Bow pull done. Skipping automatic nest movement (manual tune mode)')
		Return $SUCCESS
	EndIf

	Info('Retreating to nest')
	MoveTo($BRIGHTCLAW_NEST_X, $BRIGHTCLAW_NEST_Y)
	If WaitForPlayerNearPoint($BRIGHTCLAW_NEST_X, $BRIGHTCLAW_NEST_Y, 250, 12000) == $FAIL Then Return $FAIL
	LogOwnPosition('Nest entry reached')
	RandomSleep(700)
	Return $SUCCESS
EndFunc


Func KillBrightclaw()
	ChangeWeaponSet(3)
	RandomSleep(800)

	Info('Holding nest while Brightclaw approaches')
	Local $approachTimer = TimerInit()
	Local $approachTimeoutMs = 8000
	Local $boss = GetBossByModelID($BRIGHTCLAW_BOSS_MODEL_ID)
	While IsPlayerAlive() And TimerDiff($approachTimer) < $approachTimeoutMs
		If $boss <> Null And GetDistance(GetMyAgent(), $boss) < 1400 Then ExitLoop
		Sleep(250)
		$boss = GetBossByModelID($BRIGHTCLAW_BOSS_MODEL_ID)
	WEnd

	Info('Setting spirits')
	UseSkillEx($BRIGHT_SOS)
	UseSkillEx($BRIGHT_BLOODSONG)
	UseSkillEx($BRIGHT_SHADOWSONG)
	UseSkillEx($BRIGHT_PAIN)
	UseSkillEx($BRIGHT_ARMOR_UNFEEL)

	Local $fightTimer = TimerInit()
	Local $engageTimer = TimerInit()
	Local $hadEngaged = False
	Local $sidestepDone = False
	Local $bossAgentID = 0
	Local $confirmedBossDead = False
	Local $lastHexPressureTry = TimerInit()
	$boss = ForceOpenWithHexes(10000)
	If $boss <> Null Then
		$hadEngaged = True
		$bossAgentID = DllStructGetData($boss, 'ID')
		DoTinySafetyStep()
		LogOwnPosition('Nest sidestep right reached')
		$sidestepDone = True
	Else
		Warn('Could not apply opening hexes after spirit setup')
	EndIf

	While IsPlayerAlive() And TimerDiff($fightTimer) < 90000
		; Prefer tracked boss ID once engaged, fallback to model search otherwise.
		$boss = Null
		If $bossAgentID <> 0 Then
			$boss = GetAgentByID($bossAgentID)
		EndIf
		If $boss == Null Then
			$boss = GetBossByModelID($BRIGHTCLAW_BOSS_MODEL_ID)
			If $boss <> Null Then $bossAgentID = DllStructGetData($boss, 'ID')
		EndIf

		If $boss == Null Then
			; Keep helping with auto-attacks even if boss snapshot is momentarily unavailable.
			Local $fallbackTarget = GetNearestEnemyToAgent(GetMyAgent(), 1500)
			If $fallbackTarget <> Null Then Attack($fallbackTarget)
			Sleep(200)
			ContinueLoop
		EndIf

		If GetIsDead($boss) Or DllStructGetData($boss, 'HealthPercent') <= 0 Then
			$brightclaw_last_boss_death_x = DllStructGetData($boss, 'X')
			$brightclaw_last_boss_death_y = DllStructGetData($boss, 'Y')
			$confirmedBossDead = True
			ExitLoop
		EndIf

		Local $distance = GetDistance(GetMyAgent(), $boss)
		If $distance < 1200 Then
			$hadEngaged = True
			If TimerDiff($lastHexPressureTry) > 300 Then
				RecastPressureHexesIfReady($boss)
				$lastHexPressureTry = TimerInit()
			EndIf
		ElseIf Not $sidestepDone Then
			; Fallback if first sidestep did not complete for any reason.
			DoTinySafetyStep()
			LogOwnPosition('Nest sidestep fallback reached')
			$sidestepDone = True
		ElseIf Not $hadEngaged And TimerDiff($engageTimer) > 25000 Then
			Warn('Brightclaw did not enter engagement range in time')
			Return $FAIL
		EndIf
		; No need to recast Summon Spirits in this short fight.

		Attack($boss)
		Sleep(350)
	WEnd

	If IsPlayerDead() Then Return $FAIL
	If Not $hadEngaged Then
		Warn('Brightclaw was never engaged')
		Return $FAIL
	EndIf
	If Not $confirmedBossDead Then
		$boss = ($bossAgentID <> 0) ? GetAgentByID($bossAgentID) : GetBossByModelID($BRIGHTCLAW_BOSS_MODEL_ID)
		If $boss <> Null And Not GetIsDead($boss) And DllStructGetData($boss, 'HealthPercent') > 0 Then
			Warn('Brightclaw fight timed out')
			Return $FAIL
		EndIf
	EndIf
	If Not $confirmedBossDead Then
		Warn('Brightclaw fight timed out')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func RecastPressureHexesIfReady($target)
	If $target == Null Then Return
	Local $distance = GetDistance(GetMyAgent(), $target)
	If $distance > ($RANGE_SPELLCAST + 60) Then
		Debug('Recast skipped: target out of spell range (' & Int($distance) & ')')
		Return
	EndIf

	Local $energy = GetEnergy()
	Local $cost1 = $BRIGHT_PAINFUL_BOND_MIN_ENERGY
	Local $cost8 = $BRIGHT_PAIN_INVERTER_MIN_ENERGY
	If $brightclaw_last_recast_block_log == Null Then $brightclaw_last_recast_block_log = TimerInit()

	; Prefer Painful Bond first, then Pain Inverter when resources allow.
	If IsRecharged($BRIGHT_PAINFUL_BOND) And $energy >= $cost1 Then
		Local $cast1 = TryManualLikeSkillCastStrict($BRIGHT_PAINFUL_BOND, $target, 2)
		Debug('Recast skill 1 attempt: success=' & $cast1 & ', energy=' & Round($energy, 1))
		$energy = GetEnergy()
	ElseIf IsRecharged($BRIGHT_PAINFUL_BOND) Then
		If TimerDiff($brightclaw_last_recast_block_log) > 2000 Then
			Debug('Recast skill 1 blocked: low energy (' & Round($energy, 1) & '/' & $cost1 & ')')
			$brightclaw_last_recast_block_log = TimerInit()
		EndIf
	EndIf
	If IsRecharged($BRIGHT_PAIN_INVERTER) And $energy >= $cost8 Then
		Local $cast8 = TryManualLikeSkillCastStrict($BRIGHT_PAIN_INVERTER, $target, 2)
		Debug('Recast skill 8 attempt: success=' & $cast8 & ', energy=' & Round($energy, 1))
	ElseIf IsRecharged($BRIGHT_PAIN_INVERTER) Then
		If TimerDiff($brightclaw_last_recast_block_log) > 2000 Then
			Debug('Recast skill 8 blocked: low energy (' & Round($energy, 1) & '/' & $cost8 & ')')
			$brightclaw_last_recast_block_log = TimerInit()
		EndIf
	EndIf
EndFunc


;~ During the first seconds after spirit setup, repeatedly try to land 1/8 as soon as Brightclaw is in range.
Func EngageBrightclawAfterSpiritSetup($windowMs = 10000)
	Local $timer = TimerInit()
	Local $lastLog = TimerInit()

	While IsPlayerAlive() And TimerDiff($timer) < $windowMs
		Local $boss = GetBossByModelID($BRIGHTCLAW_BOSS_MODEL_ID)
		If $boss == Null Then
			Sleep(150)
			ContinueLoop
		EndIf

		Local $distance = GetDistance(GetMyAgent(), $boss)
		If $distance <= ($RANGE_SPELLCAST + 60) Then
			Local $casted = CastBrightclawHexCombo($boss, 1200)
			If $casted Then Return $boss
		ElseIf TimerDiff($lastLog) > 1500 Then
			Info('Waiting for Brightclaw hex range: ' & Int($distance))
			$lastLog = TimerInit()
		EndIf

		Sleep(150)
	WEnd

	Return Null
EndFunc


;~ Hard fallback: mimic manual behavior by repeatedly locking nearest target and firing 1+8.
Func ForceOpenWithHexes($windowMs = 10000)
	Local $timer = TimerInit()
	Local $lastLog = TimerInit()
	Local $hasBond = False
	Local $hasInverter = False

	While IsPlayerAlive() And TimerDiff($timer) < $windowMs
		Local $boss = GetBossByModelID($BRIGHTCLAW_BOSS_MODEL_ID)
		Local $target = $boss
		If $target == Null Then $target = GetNearestEnemyToAgent(GetMyAgent(), 2200)
		If $target == Null Then
			Sleep(120)
			ContinueLoop
		EndIf

		Local $distance = GetDistance(GetMyAgent(), $target)
		If $distance > ($RANGE_SPELLCAST + 100) Then
			If TimerDiff($lastLog) > 1500 Then
				Info('Hex opener waiting range: ' & Int($distance))
				$lastLog = TimerInit()
			EndIf
			Sleep(120)
			ContinueLoop
		EndIf

		Attack($target)
		Sleep(80)

		If Not $hasBond Then
			$hasBond = TryManualLikeSkillCastStrict($BRIGHT_PAINFUL_BOND, $target, 4)
		EndIf
		If Not $hasInverter Then
			$hasInverter = TryManualLikeSkillCastStrict($BRIGHT_PAIN_INVERTER, $target, 4)
		EndIf

		If $hasBond And $hasInverter Then
			Info('Hex opener success: 1=True, 8=True')
			Return $target
		ElseIf TimerDiff($lastLog) > 1200 Then
			Info('Hex opener progress: 1=' & $hasBond & ', 8=' & $hasInverter & ', energy=' & Round(GetEnergy(), 1))
			$lastLog = TimerInit()
		EndIf

		Sleep(120)
	WEnd

	Return Null
EndFunc


Func CastBrightclawHexCombo($boss, $timeoutMs = 4000)
	If $boss == Null Then Return False

	Local $timer = TimerInit()
	Local $casted = False
	While TimerDiff($timer) < $timeoutMs And IsPlayerAlive()
		$boss = GetBossByModelID($BRIGHTCLAW_BOSS_MODEL_ID)
		If $boss == Null Then Return $casted

		; Keep hex casts in true spell range and pin current target first.
		Local $distance = GetDistance(GetMyAgent(), $boss)
		If $distance > ($RANGE_SPELLCAST + 80) Then
			Sleep(150)
			ContinueLoop
		EndIf
		Attack($boss)
		Sleep(100)

		; Use direct skill trigger to mimic manual key press behavior.
		If TryManualLikeSkillCastStrict($BRIGHT_PAINFUL_BOND, $boss, 3) Then
			$casted = True
		EndIf
		If TryManualLikeSkillCastStrict($BRIGHT_PAIN_INVERTER, $boss, 3) Then
			$casted = True
		EndIf

		If $casted Then Return True
		Sleep(150)
	WEnd

	Return $casted
EndFunc


Func DoTinySafetyStep()
	Local $me = GetMyAgent()
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')
	; Small left/back correction from current position to avoid running up stairs.
	MoveTo($x - 45, $y + 20, 20, 0)
EndFunc


Func TryManualLikeSkillCast($skillSlot, $target, $attempts = 3)
	If $target == Null Then Return False
	For $i = 1 To $attempts
		If IsPlayerDead() Then Return False
		UseSkill($skillSlot, $target)
		Sleep(120)
		; Any of these signs indicates the skill command was accepted.
		If Not IsRecharged($skillSlot) Then Return True
		If IsCasting(GetMyAgent()) Then Return True
		If DllStructGetData(GetMyAgent(), 'Skill') <> 0 Then Return True
	Next
	Return False
EndFunc


Func TryManualLikeSkillCastStrict($skillSlot, $target, $attempts = 3)
	If $target == Null Then Return False
	Local $requiredEnergy = GetSkillEnergyCost($skillSlot)
	For $i = 1 To $attempts
		If IsPlayerDead() Then Return False
		If GetEnergy() < $requiredEnergy Then
			Sleep(120)
			ContinueLoop
		EndIf

		Local $wasRecharged = IsRecharged($skillSlot)
		If Not $wasRecharged Then Return True

		UseSkill($skillSlot, $target)
		Sleep(140)
		If $wasRecharged And Not IsRecharged($skillSlot) Then Return True
	Next
	Return False
EndFunc


Func GetSkillEnergyCost($skillSlot)
	Local $skillID = GetSkillbarSkillID($skillSlot)
	If $skillID == 0 Then Return 999
	Local $skill = GetSkillByID($skillID)
	Return Number(StringReplace(StringReplace(StringReplace(StringMid(DllStructGetData($skill, 'Unknown4'), 6, 1), 'C', '25'), 'B', '15'), 'A', '10'))
EndFunc


Func WaitForBrightclawInRange($range, $timeoutMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $timeoutMs And IsPlayerAlive()
		Local $boss = GetBossByModelID($BRIGHTCLAW_BOSS_MODEL_ID)
		If $boss <> Null And GetDistance(GetMyAgent(), $boss) <= $range Then Return $boss
		Sleep(200)
	WEnd
	Return Null
EndFunc


Func IsBrightclawConfirmedDead($confirmWindowMs = 3000)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $confirmWindowMs
		Local $boss = GetBossByModelID($BRIGHTCLAW_BOSS_MODEL_ID)
		If $boss <> Null And Not GetIsDead($boss) And DllStructGetData($boss, 'HealthPercent') > 0 Then Return False
		Sleep(150)
	WEnd
	Return True
EndFunc


Func LootBrightclawFast()
	If IsPlayerDead() Then Return $FAIL

	Info('Boss dead. Rushing to loot spot')
	If IsRecharged($BRIGHT_DARK_ESCAPE) Then UseSkillEx($BRIGHT_DARK_ESCAPE)
	RandomSleep(50)
	ChangeWeaponSet(1)

	; Sprint straight to the recorded boss death location to avoid stair detours.
	If $brightclaw_last_boss_death_x <> 0 And $brightclaw_last_boss_death_y <> 0 Then
		MoveTo($brightclaw_last_boss_death_x, $brightclaw_last_boss_death_y, 20, 0)
		WaitForPlayerNearPoint($brightclaw_last_boss_death_x, $brightclaw_last_boss_death_y, 240, 5000)
	EndIf

	Info('Picking up loot quickly')
	PickUpItems()
	RandomSleep(350)
	PickUpItems()
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Return nearest alive foe that matches modelID
Func GetBossByModelID($modelID)
	Local $me = GetMyAgent()
	Local $nearestBoss = Null
	Local $nearestDistance = 100000000

	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		If DllStructGetData($agent, 'ModelID') <> $modelID Then ContinueLoop
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then ContinueLoop
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop

		Local $distance = GetDistance($me, $agent)
		If $distance < $nearestDistance Then
			$nearestDistance = $distance
			$nearestBoss = $agent
		EndIf
	Next
	Return $nearestBoss
EndFunc


;~ Pull target helper: strict boss match first, then loose model match, then nearest enemy fallback.
Func GetBossForPull()
	Local $target = GetBossByModelID($BRIGHTCLAW_BOSS_MODEL_ID)
	If $target <> Null Then Return $target

	$target = GetAgentByModelIDLoose($BRIGHTCLAW_BOSS_MODEL_ID)
	If $target <> Null Then Return $target

	$target = GetNearestEnemyToAgent(GetMyAgent(), 15000)
	Return $target
EndFunc


;~ Return nearest NPC matching modelID without alive/allegiance checks for long-range pull targeting.
Func GetAgentByModelIDLoose($modelID)
	Local $me = GetMyAgent()
	Local $nearestAgent = Null
	Local $nearestDistance = 100000000

	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		If DllStructGetData($agent, 'ModelID') <> $modelID Then ContinueLoop
		Local $distance = GetDistance($me, $agent)
		If $distance < $nearestDistance Then
			$nearestDistance = $distance
			$nearestAgent = $agent
		EndIf
	Next
	Return $nearestAgent
EndFunc


;~ Wait until player reaches point within range or timeout (ms)
Func WaitForPlayerNearPoint($x, $y, $range, $timeout)
	Local $timer = TimerInit()
	While GetDistanceToPoint(GetMyAgent(), $x, $y) > $range
		If IsPlayerDead() Then Return $FAIL
		If TimerDiff($timer) > $timeout Then Return $FAIL
		Sleep(250)
	WEnd
	Return $SUCCESS
EndFunc


Func LogOwnPosition($label)
	If Not $BRIGHTCLAW_DEBUG_COORDS Then Return
	Local $me = GetMyAgent()
	Local $x = Int(DllStructGetData($me, 'X'))
	Local $y = Int(DllStructGetData($me, 'Y'))
	Info($label & ': (' & $x & ', ' & $y & ')')
EndFunc


Func StartBrightclawRecorder()
	If $brightclaw_recorder_active Then Return
	$brightclaw_recorder_handle = FileOpen($BRIGHTCLAW_RECORDER_FILE, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	If $brightclaw_recorder_handle == -1 Then
		Warn('Could not open recorder file: ' & $BRIGHTCLAW_RECORDER_FILE)
		Return
	EndIf

	$brightclaw_last_logged_skill = -1
	$brightclaw_recorder_active = True
	$brightclaw_recorder_start_timer = TimerInit()
	FileWriteLine($brightclaw_recorder_handle, '=== Brightclaw manual recorder start ===')
	FileWriteLine($brightclaw_recorder_handle, 'time_ms;x;y;hp;energy;login_number;casting_skill_id')
	AdlibRegister('BrightclawRecorderTick', $BRIGHTCLAW_RECORDER_INTERVAL_MS)
EndFunc


Func StopBrightclawRecorder()
	If Not $brightclaw_recorder_active Then Return
	AdlibUnRegister('BrightclawRecorderTick')
	If $brightclaw_recorder_handle <> -1 Then
		FileWriteLine($brightclaw_recorder_handle, '=== Brightclaw manual recorder stop ===')
		FileClose($brightclaw_recorder_handle)
	EndIf
	$brightclaw_recorder_handle = -1
	$brightclaw_recorder_active = False
	$brightclaw_last_logged_skill = -1
	$brightclaw_recorder_start_timer = Null
EndFunc


Func BrightclawRecorderTick()
	If Not $brightclaw_recorder_active Or $brightclaw_recorder_handle == -1 Then Return

	Local $me = GetMyAgent()
	If $me == Null Then Return

	Local $x = Int(DllStructGetData($me, 'X'))
	Local $y = Int(DllStructGetData($me, 'Y'))
	Local $hp = Round(DllStructGetData($me, 'HealthPercent') * 100, 1)
	Local $energy = Round(GetEnergy($me), 1)
	Local $loginNumber = DllStructGetData($me, 'LoginNumber')
	Local $skillID = DllStructGetData($me, 'Skill')
	Local $timeMs = Round(TimerDiff($brightclaw_recorder_start_timer), 0)

	FileWriteLine($brightclaw_recorder_handle, $timeMs & ';' & $x & ';' & $y & ';' & $hp & ';' & $energy & ';' & $loginNumber & ';' & $skillID)

	If $skillID <> 0 And $skillID <> $brightclaw_last_logged_skill Then
		Info('Manual recorder: cast skill ID ' & $skillID & ' at (' & $x & ', ' & $y & ')')
		$brightclaw_last_logged_skill = $skillID
	ElseIf $skillID == 0 Then
		$brightclaw_last_logged_skill = 0
	EndIf
EndFunc
