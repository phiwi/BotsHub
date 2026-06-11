#CS ===========================================================================
; Author: GitHub Copilot (training scaffold for UW Plains project)
; Copyright 2026
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
#include '../utilities/PathActionRecorder.au3'

Opt('MustDeclareVars', True)


; ==== Constants ====
; Training-only scaffold for iterating on Plains logic without paying UW entry.
Global Const $UWPT_RUN_MODE_PHASE1_CHAMBER = 'phase1_chamber'
Global Const $UWPT_RUN_MODE_TARGET_LOOP = 'target_loop'
Global Const $UWPT_RUN_MODE = $UWPT_RUN_MODE_PHASE1_CHAMBER
Global Const $UWPT_AUTO_RECORDING = True

Global Const $UWPT_RUN_TIMEOUT_MS = 7 * 60 * 1000
Global Const $UWPT_TARGET_LOOP_DURATION_MS = 3 * 60 * 1000
Global Const $UWPT_LOOP_TRAIN_WINDOW_MS = 3 * 60 * 1000
Global Const $UWPT_DRY_RUN_MODE = False
Global Const $UWPT_SAFE_PACKET_ISOLATION_MODE = False
Global Const $UWPT_SAFE_ISOLATION_NO_SKILLS = False
Global Const $UWPT_DIAGNOSTIC_SKIP_SETUP_ACTIONS = False
Global Const $UWPT_SKIP_PLAYER_BUILD_SETUP_DEBUG = False
Global Const $UWPT_PLAYER_SKILLBAR = 'Owpl8xjWaqSrGxjozcAVDiJ29Ze1AB'

; Isle of the Nameless map IDs (different variants depending on entry path).
Global Const $UWPT_TRAINING_MAP_1 = $ID_ISLE_OF_THE_NAMELESS_1
Global Const $UWPT_TRAINING_MAP_2 = $ID_ISLE_OF_THE_NAMELESS_2

; Skill slots for template: Owpl8xjWaqSrGxjozcAVDiJ29Ze1AB (A/D)
Global Const $UWPT_DEADLY_PARADOX = 1
Global Const $UWPT_SHADOW_FORM = 2
Global Const $UWPT_SHROUD_OF_DISTRESS = 3
Global Const $UWPT_CRITICAL_AGILITY = 4
Global Const $UWPT_SIGNET_OF_MYSTIC_SPEED = 5
Global Const $UWPT_GRENTHS_AURA = 6
Global Const $UWPT_SAND_SHARDS = 7
Global Const $UWPT_DARK_ESCAPE = 8

; Weapon-set policy for this trainer:
; - Set 1 before run (Spear + Shield)
; - Set 4 in active combat windows (Scythe)
Global Const $UWPT_WEAPON_SET_PRE_RUN = 3
Global Const $UWPT_WEAPON_SET_POST_SAFE = 4

Global Const $UWPT_SPECTRE_BALL_MIN = 3
Global Const $UWPT_SPECTRE_BALL_IDEAL = 10
Global Const $UWPT_SAFE_SPOT_APPROACH_RANGE = 2600

; Timing knobs for SF chain and combat rhythm.
Global Const $UWPT_SF_RECAST_THRESHOLD_MS = 2600
Global Const $UWPT_SF_MIN_SAFE_WINDOW_MS = 7000
Global Const $UWPT_SOD_REFRESH_THRESHOLD_MS = 2500
Global Const $UWPT_DPS_ENCHANT_REFRESH_MS = 2500
Global Const $UWPT_CA_REFRESH_MS = 2000
Global Const $UWPT_SF_CHAIN_ENERGY_MIN = 15
Global Const $UWPT_SF_SOFT_RESERVE = 8
Global Const $UWPT_UTILITY_ENERGY_BUFFER = 2
Global Const $UWPT_COST_SHROUD_OF_DISTRESS = 5
Global Const $UWPT_COST_CRITICAL_AGILITY = 5
Global Const $UWPT_COST_GRENTHS_AURA = 10
Global Const $UWPT_COST_SAND_SHARDS = 10
Global Const $UWPT_COMBAT_RANGE = 1350
Global Const $UWPT_ATTACK_COMMAND_CADENCE_MS = 650
Global Const $UWPT_RETARGET_CADENCE_MS = 850
Global Const $UWPT_PRE_RUN_ENERGY_MIN = 43
Global Const $UWPT_PRE_RUN_ENERGY_TARGET = 44

; Loop anchors in Chaos Plains from Underworld route (placeholder training dataset).
Global Const $UWPT_PLANES_ANCHOR_CENTER_X = 11160
Global Const $UWPT_PLANES_ANCHOR_CENTER_Y = -17710
Global Const $UWPT_PLANES_ANCHOR_RIGHT_X = 12211
Global Const $UWPT_PLANES_ANCHOR_RIGHT_Y = -17522
Global Const $UWPT_PLANES_ANCHOR_LEFT_X = 10550
Global Const $UWPT_PLANES_ANCHOR_LEFT_Y = -18575

; Recorded anchors used by the chamber-exit sprint and first plains setup.
Global Const $UWPT_CHAMBER_EXIT_FLAG_X = -3340
Global Const $UWPT_CHAMBER_EXIT_FLAG_Y = 2727
Global Const $UWPT_FIRST_SAFE_SPOT_X = 8928
Global Const $UWPT_FIRST_SAFE_SPOT_Y = -9935
Global Const $UWPT_FIRST_PLANES_ANCHOR_X = 10861
Global Const $UWPT_FIRST_PLANES_ANCHOR_Y = -10415
Global Const $UWPT_MOUNTAIN_GATE_PRE_X = 7905
Global Const $UWPT_MOUNTAIN_GATE_PRE_Y = 265
Global Const $UWPT_MOUNTAIN_GATE_POST_X = 8274
Global Const $UWPT_MOUNTAIN_GATE_POST_Y = -4431

; Recorder-derived temporary target model priorities in first plains spot.
Global Const $UWPT_MODEL_BANISHED_DREAM_RIDER = 2376
Global Const $UWPT_MODEL_WAILING_LORD = 2377
Global Const $UWPT_MODEL_SPECTRE = 2380

Global $uwpt_setup_done = False
Global $uwpt_loop_count = 0
Global $uwpt_perma_adlib_active = False


;~ Main entry point for the training script.
Func UnderworldPlainsTrainerFarm()
	If Not $uwpt_setup_done And UwPlainsTrainSetup() == $FAIL Then Return $PAUSE

	If $UWPT_RUN_MODE == $UWPT_RUN_MODE_PHASE1_CHAMBER Then
		Return UwPlainsTrainRunPhase1ChamberOnly()
	EndIf

	If UwPlainsTrainEnsureTrainingMap() == $FAIL Then Return $PAUSE
	Return UwPlainsTrainTargetLoopOnly()
EndFunc


Func UwPlainsTrainRunPhase1ChamberOnly()
	Info('Trainer mode: phase 1 only (Temple -> UW entry -> Clear the Chamber -> stop)')
	ChangeWeaponSet($UWPT_WEAPON_SET_PRE_RUN)
	UwPlainsTrainStartAutoRecording()
	Local $alreadyInUW = (GetMapID() == $ID_THE_UNDERWORLD)

	If Not $alreadyInUW Then
		If TravelToOutpost($ID_TEMPLE_OF_THE_AGES, $district_name) == $FAIL Then
			UwPlainsTrainStopAutoRecording('UWPT_RUN_ABORT travel_to_toa_failed')
			Return $PAUSE
		EndIf
		If UwPlainsTrainEnsureTemplateLoadedInOutpost() == $FAIL Then
			UwPlainsTrainStopAutoRecording('UWPT_RUN_ABORT template_load_failed')
			Return $PAUSE
		EndIf

		Local $enterResult = EnterUnderworld()
		If $enterResult <> $SUCCESS Then
			UwPlainsTrainStopAutoRecording('UWPT_RUN_ABORT enter_uw_failed result=' & $enterResult)
			Return $PAUSE
		EndIf
	Else
		Info('Already in Underworld: skipping ToA travel and re-entry cost')
	EndIf

	UwPlainsTrainStartPermaMaintenanceAdlib()
	Local $result = $SUCCESS
	If IsQuestReward($ID_QUEST_CLEAR_THE_CHAMBER) Then
		Info('Clear the Chamber already rewarded. Resuming directly with chamber-exit/plains run')
		$result = UwPlainsTrainRunPlainsFromChamberExit()
	Else
		$result = UwPlainsTrainClearTheChamberFastStart()
		If $result == $SUCCESS Then $result = UwPlainsTrainRunPlainsFromChamberExit()
	EndIf
	UwPlainsTrainStopPermaMaintenanceAdlib()

	If $result == $SUCCESS Then
		Info('Phase-1 chamber + first plains setup completed. Ending trainer run')
	Else
		Warn('Phase-1 trainer failed during chamber/plains setup sequence')
	EndIf

	UwPlainsTrainStopAutoRecording('UWPT_RUN_END result=' & $result)
	Info('No forced ToA return: staying in current map for manual debug control')

	; During debugging do not auto-chain into a paid re-entry run.
	If $result <> $SUCCESS Then Return $PAUSE
	Return $SUCCESS
EndFunc


Func UwPlainsTrainTargetLoopOnly()
	Info('Trainer mode: target-loop only (no chamber/mountain phases)')
	If $UWPT_SAFE_PACKET_ISOLATION_MODE Then
		Info('Safety mode active: target/attack packets disabled')
		If $UWPT_SAFE_ISOLATION_NO_SKILLS Then Info('Diagnostic isolation: skill casts disabled (read-only loop)')
		Return UwPlainsTrainSelfBuffIsolationLoop()
	EndIf

	Local $target = UwPlainsTrainGetInitialTarget()
	If $target == Null Then
		Warn('No valid target selected. Select/approach a dummy, then press start (pausing to avoid fail loop)')
		Return $PAUSE
	EndIf

	Local $targetID = DllStructGetData($target, 'ID')
	Info('Starting loop on target id=' & $targetID)
	Local $lastAttackCommand = TimerInit()
	Local $lastRetarget = TimerInit()

	Local $timer = TimerInit()
	While TimerDiff($timer) < $UWPT_TARGET_LOOP_DURATION_MS And IsPlayerAlive()
		UwPlainsTrainMaintainSFTick(True, False)

		If Not UwPlainsTrainIsValidCombatTarget($target) Then
			$target = UwPlainsTrainGetInitialTarget()
			If $target == Null Then
				Sleep(160)
				ContinueLoop
			EndIf
			$targetID = DllStructGetData($target, 'ID')
			Info('Switched loop target to id=' & $targetID)
		EndIf

		Local $distance = GetDistance(GetMyAgent(), $target)
		If $distance > ($RANGE_ADJACENT + 80) Then
			Local $tx = DllStructGetData($target, 'X')
			Local $ty = DllStructGetData($target, 'Y')
			MoveTo($tx, $ty, 20, 0)
		EndIf

		If TimerDiff($lastRetarget) > $UWPT_RETARGET_CADENCE_MS Then
			Local $currentTarget = GetCurrentTarget()
			If $currentTarget == Null Or DllStructGetData($currentTarget, 'ID') <> $targetID Then ChangeTarget($target)
			$lastRetarget = TimerInit()
		EndIf

		If TimerDiff($lastAttackCommand) > $UWPT_ATTACK_COMMAND_CADENCE_MS Then
			Attack($target)
			$lastAttackCommand = TimerInit()
		EndIf

		; Utility policy: strict reserve near SF expiry, relaxed reserve when SF window is healthy.
		Local $sfRemaining = UwPlainsTrainGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP)
		Local $energyNow = GetEnergy()
		Local $reserve = ($sfRemaining <= $UWPT_SF_MIN_SAFE_WINDOW_MS) ? ($UWPT_SF_CHAIN_ENERGY_MIN + $UWPT_UTILITY_ENERGY_BUFFER) : $UWPT_SF_SOFT_RESERVE

		Local $gaDue = GetEffectTimeRemaining($ID_GRENTHS_AURA) <= $UWPT_DPS_ENCHANT_REFRESH_MS
		Local $ssDue = GetEffectTimeRemaining($ID_SAND_SHARDS) <= $UWPT_DPS_ENCHANT_REFRESH_MS

		If $gaDue And $energyNow >= ($reserve + $UWPT_COST_GRENTHS_AURA) Then
			If UwPlainsTrainTryUseSkillSafe($UWPT_GRENTHS_AURA) Then $energyNow -= $UWPT_COST_GRENTHS_AURA
		EndIf

		If $ssDue And $energyNow >= ($reserve + $UWPT_COST_SAND_SHARDS) Then
			UwPlainsTrainTryUseSkillSafe($UWPT_SAND_SHARDS)
		EndIf

		Sleep(120)
	WEnd

	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func UwPlainsTrainSelfBuffIsolationLoop()
	Local $timer = TimerInit()
	While TimerDiff($timer) < $UWPT_TARGET_LOOP_DURATION_MS And IsPlayerAlive()
		; Hard isolation mode: no combat packets and optionally no skill packets.
		If Not $UWPT_SAFE_ISOLATION_NO_SKILLS Then UwPlainsTrainMaintainSFTick(False, False)
		Sleep(180)
	WEnd

	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func UwPlainsTrainGetInitialTarget()
	Local $target = GetCurrentTarget()
	If UwPlainsTrainIsValidCombatTarget($target) Then Return $target

	$target = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_EARSHOT * 2)
	If UwPlainsTrainIsValidCombatTarget($target) Then Return $target

	$target = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_COMPASS)
	If UwPlainsTrainIsValidCombatTarget($target) Then Return $target

	Return Null
EndFunc


Func UwPlainsTrainIsValidCombatTarget($agent)
	If $agent == Null Then Return False
	If GetIsDead($agent) Then Return False
	If DllStructGetData($agent, 'HealthPercent') <= 0 Then Return False
	If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then Return False
	Return True
EndFunc


Func UwPlainsTrainSetup()
	Info('Setting up UW Plains trainer scaffold')

	If $UWPT_DIAGNOSTIC_SKIP_SETUP_ACTIONS Then
		Info('Diagnostic mode: skipping all setup actions (including template load)')
		$uwpt_setup_done = True
		Info('UW Plains trainer scaffold ready')
		Return $SUCCESS
	EndIf

	; Keep setup non-blocking. Template load is performed later in ToA before UW entry.
	If $UWPT_SKIP_PLAYER_BUILD_SETUP_DEBUG Then Info('Debug mode: skipping player template load')

	$uwpt_setup_done = True
	Info('UW Plains trainer scaffold ready')
	Return $SUCCESS
EndFunc


Func UwPlainsTrainEnsureTemplateLoadedInOutpost()
	If GetMapType() <> $ID_OUTPOST Then
		Info('Skipping template load: currently in explorable area (templates can only be loaded in outposts)')
		Return $SUCCESS
	EndIf

	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_ASSASSIN Then
		Warn('UW Plains trainer requires Assassin primary profession')
		Return $FAIL
	EndIf

	LoadSkillTemplate($UWPT_PLAYER_SKILLBAR)
	RandomSleep(250)
	Info('Loaded trainer template: Owpl8xjWaqSrGxjozcAVDiJ29Ze1AB')
	Return $SUCCESS
EndFunc


Func UwPlainsTrainEnsureTrainingMap()
	Local $mapID = GetMapID()
	If $mapID == $UWPT_TRAINING_MAP_1 Or $mapID == $UWPT_TRAINING_MAP_2 Then
		Return $SUCCESS
	EndIf

	If $mapID == $ID_GREAT_TEMPLE_OF_BALTHAZAR Then
		Warn('You are in Great Temple of Balthazar. Enter Isle of the Nameless first, then press start again')
		Return $FAIL
	EndIf

	Warn('Training map mismatch. Move to Isle of the Nameless before running this trainer')
	Return $FAIL
EndFunc


Func UwPlainsTrainMainLoop()
	Local $runTimer = TimerInit()

	If UwPlainsTrainPhaseChamberGate() == $FAIL Then Return $FAIL
	If UwPlainsTrainPhaseTwinSerpentSprint() == $FAIL Then Return $FAIL
	If UwPlainsTrainPhaseSetUpLoop() == $FAIL Then Return $FAIL
	If UwPlainsTrainPhaseBallAndKillEngine() == $FAIL Then Return $FAIL

	If TimerDiff($runTimer) > $UWPT_RUN_TIMEOUT_MS Then
		Warn('UW Plains trainer timed out')
		Return $FAIL
	EndIf

	Info('UW Plains trainer cycle complete')
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Phase 1: placeholder for "Clear the Chamber" gate with heroes.
Func UwPlainsTrainPhaseChamberGate()
	Info('Phase 1/4: Clear the Chamber (Underworld route unchanged)')

	; On Isle training maps we skip chamber pathing and start recorder-relevant work after this phase.
	Local $mapID = GetMapID()
	If $mapID == $UWPT_TRAINING_MAP_1 Or $mapID == $UWPT_TRAINING_MAP_2 Then
		Info('Training map detected: skipping UW chamber path and continuing to mountain-run phase')
		Return $SUCCESS
	EndIf

	If $mapID <> $ID_THE_UNDERWORLD Then
		Warn('Chamber clear requires Underworld map. Current map: ' & $mapID)
		Return $FAIL
	EndIf

	UwPlainsTrainStartPermaMaintenanceAdlib()
	Local $result = UwPlainsTrainClearTheChamberUnchanged()
	UwPlainsTrainStopPermaMaintenanceAdlib()
	Return $result
EndFunc


;~ Phase 2: sprint route placeholder. Replace points using recorder exports.
Func UwPlainsTrainPhaseTwinSerpentSprint()
	Info('Phase 2/4: Twin Serpent sprint training')
	Info('Recorder start point: first change begins here (after chamber clear)')

	Local $sprintPath[4][2] = [ _
		[9500, -9200], [10200, -9800], [10800, -10600], [11200, -11400] _
	]

	If UwPlainsTrainFollowPath($sprintPath, 280, 9000, 'sprint', True) == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Phase 3: setup loop movement before sustained ball + kill sequence.
Func UwPlainsTrainPhaseSetUpLoop()
	Info('Phase 3/4: setup loop in Plains')
	$uwpt_loop_count += 1

	; Step A: pre-spawn cleanup pattern (2 Banished Dream Riders + 1 Wailing Lord in UW target flow).
	If UwPlainsTrainMoveAndEngage($UWPT_PLANES_ANCHOR_RIGHT_X, $UWPT_PLANES_ANCHOR_RIGHT_Y, 'pre-spawn right') == $FAIL Then Return $FAIL
	If UwPlainsTrainMoveAndEngage($UWPT_PLANES_ANCHOR_CENTER_X, $UWPT_PLANES_ANCHOR_CENTER_Y, 'pre-spawn center') == $FAIL Then Return $FAIL
	If UwPlainsTrainMoveAndEngage($UWPT_PLANES_ANCHOR_LEFT_X, $UWPT_PLANES_ANCHOR_LEFT_Y, 'pre-spawn left') == $FAIL Then Return $FAIL

	; Step B: recurring loop points. Replace with recorder-fed corners where spectres cluster/ball.
	Local $loopPath[6][2] = [ _
		[$UWPT_PLANES_ANCHOR_CENTER_X, $UWPT_PLANES_ANCHOR_CENTER_Y], _
		[$UWPT_PLANES_ANCHOR_RIGHT_X, $UWPT_PLANES_ANCHOR_RIGHT_Y], _
		[$UWPT_PLANES_ANCHOR_CENTER_X, $UWPT_PLANES_ANCHOR_CENTER_Y], _
		[$UWPT_PLANES_ANCHOR_LEFT_X, $UWPT_PLANES_ANCHOR_LEFT_Y], _
		[$UWPT_PLANES_ANCHOR_CENTER_X, $UWPT_PLANES_ANCHOR_CENTER_Y], _
		[$UWPT_PLANES_ANCHOR_RIGHT_X, $UWPT_PLANES_ANCHOR_RIGHT_Y] _
	]

	If UwPlainsTrainFollowPath($loopPath, 260, 7000, 'setup-loop-' & $uwpt_loop_count, False) == $FAIL Then Return $FAIL
	If UwPlainsTrainWaitAndMaintain(1400, $UWPT_PLANES_ANCHOR_CENTER_X, $UWPT_PLANES_ANCHOR_CENTER_Y) == $FAIL Then Return $FAIL

	Info('Completed setup loop #' & $uwpt_loop_count)
	Return $SUCCESS
EndFunc


;~ Phase 4: 3-minute training cycle for balling behavior and kill engine timing.
Func UwPlainsTrainPhaseBallAndKillEngine()
	Info('Phase 4/4: ball + kill engine training')

	Local $timer = TimerInit()
	While TimerDiff($timer) < $UWPT_LOOP_TRAIN_WINDOW_MS And IsPlayerAlive()
		If UwPlainsTrainMoveAndEngage($UWPT_PLANES_ANCHOR_RIGHT_X, $UWPT_PLANES_ANCHOR_RIGHT_Y, 'ball-right') == $FAIL Then Return $FAIL
		If UwPlainsTrainMoveAndEngage($UWPT_PLANES_ANCHOR_CENTER_X, $UWPT_PLANES_ANCHOR_CENTER_Y, 'ball-center') == $FAIL Then Return $FAIL
		If UwPlainsTrainMoveAndEngage($UWPT_PLANES_ANCHOR_LEFT_X, $UWPT_PLANES_ANCHOR_LEFT_Y, 'ball-left') == $FAIL Then Return $FAIL
	WEnd

	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func UwPlainsTrainFollowPath(ByRef $path, $arrivalRange, $timeoutPerPoint, $pathTag, $allowDarkEscape = False)
	For $i = 0 To UBound($path) - 1
		If IsPlayerDead() Then Return $FAIL
		If UwPlainsTrainMoveToPointRobust($path[$i][0], $path[$i][1], $arrivalRange, $timeoutPerPoint, $pathTag & '-p' & ($i + 1), $allowDarkEscape) == $FAIL Then Return $FAIL
	Next
	Return $SUCCESS
EndFunc


Func UwPlainsTrainMoveAndEngage($x, $y, $label)
	Info('Moving to ' & $label & ' at (' & $x & ', ' & $y & ')')
	If UwPlainsTrainMoveToPointRobust($x, $y, 260, 9000, $label, False) == $FAIL Then Return $FAIL

	If $UWPT_DRY_RUN_MODE Then
		If UwPlainsTrainWaitAndMaintain(550, $x, $y) == $FAIL Then Return $FAIL
		Return $SUCCESS
	EndIf

	If UwPlainsTrainKillEngineTick(8500) == $FAIL Then Return $FAIL
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func UwPlainsTrainMoveToPointRobust($x, $y, $range, $timeout, $stepLabel, $allowDarkEscape)
	Local $timer = TimerInit()
	Local $reissueTimer = TimerInit()
	MoveTo($x, $y, 25, 0)

	While GetDistanceToPoint(GetMyAgent(), $x, $y) > $range
		If IsPlayerDead() Then Return $FAIL
		UwPlainsTrainTryPermaResync($allowDarkEscape)
		UwPlainsTrainMaintainSFTick(False, $allowDarkEscape)

		If TimerDiff($timer) > $timeout Then
			Warn('Trainer move timeout at ' & $stepLabel & ' (' & $x & ', ' & $y & ')')
			Return $FAIL
		EndIf

		If TimerDiff($reissueTimer) > 3000 Then
			MoveTo($x, $y, 25, 0)
			$reissueTimer = TimerInit()
		EndIf

		Sleep(200)
	WEnd

	Return $SUCCESS
EndFunc


Func UwPlainsTrainKillEngineTick($windowMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $windowMs And IsPlayerAlive()
		UwPlainsTrainMaintainSFTick(True, False)

		Local $target = GetNearestEnemyToAgent(GetMyAgent(), $UWPT_COMBAT_RANGE)
		If $target <> Null Then
			ChangeTarget($target)
			Attack($target)

			Local $caMs = GetEffectTimeRemaining($ID_CRITICAL_AGILITY)
			If $caMs <= $UWPT_CA_REFRESH_MS And IsRecharged($UWPT_CRITICAL_AGILITY) Then UseSkillEx($UWPT_CRITICAL_AGILITY)

			Local $gaMs = GetEffectTimeRemaining($ID_GRENTHS_AURA)
			If $gaMs <= $UWPT_DPS_ENCHANT_REFRESH_MS And IsRecharged($UWPT_GRENTHS_AURA) Then UseSkillEx($UWPT_GRENTHS_AURA)

			Local $ssMs = GetEffectTimeRemaining($ID_SAND_SHARDS)
			If $ssMs <= $UWPT_DPS_ENCHANT_REFRESH_MS And IsRecharged($UWPT_SAND_SHARDS) Then UseSkillEx($UWPT_SAND_SHARDS)
		EndIf

		Sleep(100)
	WEnd

	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func UwPlainsTrainMaintainSFTick($allowCombatCasts = False, $allowDarkEscape = False)
	If IsPlayerDead() Then Return

	Local $sfRemaining = UwPlainsTrainGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP)
	Local $sodRemaining = UwPlainsTrainGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)
	If UwPlainsTrainTryPermaResync($allowDarkEscape) Then Return

	If IsRecharged($UWPT_SHADOW_FORM) And GetEnergy() >= $UWPT_SF_CHAIN_ENERGY_MIN And $sfRemaining <= $UWPT_SF_RECAST_THRESHOLD_MS Then
		; Your requested anti-interrupt chain: SoMS -> DP -> SF, and SoD refresh if needed.
		If IsRecharged($UWPT_SIGNET_OF_MYSTIC_SPEED) Then
			UseSkillEx($UWPT_SIGNET_OF_MYSTIC_SPEED)
			Sleep(90)
		EndIf

		If IsRecharged($UWPT_DEADLY_PARADOX) Then
			UseSkillEx($UWPT_DEADLY_PARADOX)
			Sleep(90)
		EndIf

		UseSkillEx($UWPT_SHADOW_FORM)
		Sleep(120)

		If IsRecharged($UWPT_SHROUD_OF_DISTRESS) And $sodRemaining <= $UWPT_SOD_REFRESH_THRESHOLD_MS Then
			UseSkillEx($UWPT_SHROUD_OF_DISTRESS)
			Sleep(90)
		EndIf

		If $allowDarkEscape And IsRecharged($UWPT_DARK_ESCAPE) Then
			UseSkillEx($UWPT_DARK_ESCAPE)
			Sleep(70)
		EndIf
		Return
	EndIf

	If $sodRemaining <= $UWPT_SOD_REFRESH_THRESHOLD_MS And IsRecharged($UWPT_SHROUD_OF_DISTRESS) Then
		If UwPlainsTrainCanSpendEnergy($UWPT_COST_SHROUD_OF_DISTRESS) Then UwPlainsTrainTryUseSkillSafe($UWPT_SHROUD_OF_DISTRESS)
		Sleep(70)
	EndIf

	If $allowDarkEscape And IsRecharged($UWPT_DARK_ESCAPE) Then
		UseSkillEx($UWPT_DARK_ESCAPE)
		Sleep(70)
	EndIf

	If Not $allowCombatCasts Then Return

	; Critical Agility should be maintained only in fight windows.
	Local $target = GetNearestEnemyToAgent(GetMyAgent(), $UWPT_COMBAT_RANGE)
	If $target <> Null Then
		If GetEffectTimeRemaining($ID_CRITICAL_AGILITY) <= $UWPT_CA_REFRESH_MS Then
			If UwPlainsTrainCanSpendEnergy($UWPT_COST_CRITICAL_AGILITY) Then UwPlainsTrainTryUseSkillSafe($UWPT_CRITICAL_AGILITY)
		EndIf

		; Keep offensive enchants flowing in real combat while preserving SF reserve.
		Local $sfRemainCombat = UwPlainsTrainGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP)
		Local $energyCombat = GetEnergy()
		Local $combatReserve = ($sfRemainCombat <= $UWPT_SF_MIN_SAFE_WINDOW_MS) ? ($UWPT_SF_CHAIN_ENERGY_MIN + $UWPT_UTILITY_ENERGY_BUFFER) : $UWPT_SF_SOFT_RESERVE

		If GetEffectTimeRemaining($ID_GRENTHS_AURA) <= $UWPT_DPS_ENCHANT_REFRESH_MS Then
			If $energyCombat >= ($combatReserve + $UWPT_COST_GRENTHS_AURA) Then
				If UwPlainsTrainTryUseSkillSafe($UWPT_GRENTHS_AURA) Then $energyCombat -= $UWPT_COST_GRENTHS_AURA
			EndIf
		EndIf

		If GetEffectTimeRemaining($ID_SAND_SHARDS) <= $UWPT_DPS_ENCHANT_REFRESH_MS Then
			If $energyCombat >= ($combatReserve + $UWPT_COST_SAND_SHARDS) Then UwPlainsTrainTryUseSkillSafe($UWPT_SAND_SHARDS)
		EndIf
	EndIf
EndFunc


Func UwPlainsTrainTryPermaResync($allowDarkEscape = False)
	Local $sfRemaining = UwPlainsTrainGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP)
	Local $sodRemaining = UwPlainsTrainGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)
	Local $hpPct = DllStructGetData(GetMyAgent(), 'HealthPercent') * 100

	; If chain is gone or near expiry and SF is ready, rebuild exactly: SoMS -> DP -> SF -> SoD.
	If IsRecharged($UWPT_SHADOW_FORM) And GetEnergy() >= $UWPT_SF_CHAIN_ENERGY_MIN And $sfRemaining <= $UWPT_SF_RECAST_THRESHOLD_MS Then
		If IsRecharged($UWPT_SIGNET_OF_MYSTIC_SPEED) Then
			UseSkillEx($UWPT_SIGNET_OF_MYSTIC_SPEED)
			Sleep(90)
		EndIf

		If IsRecharged($UWPT_DEADLY_PARADOX) Then
			UseSkillEx($UWPT_DEADLY_PARADOX)
			Sleep(90)
		EndIf

		UseSkillEx($UWPT_SHADOW_FORM)
		Sleep(130)

		If IsRecharged($UWPT_SHROUD_OF_DISTRESS) And $sodRemaining <= $UWPT_SOD_REFRESH_THRESHOLD_MS Then
			UseSkillEx($UWPT_SHROUD_OF_DISTRESS)
			Sleep(80)
		EndIf

		If $allowDarkEscape And IsRecharged($UWPT_DARK_ESCAPE) Then
			UseSkillEx($UWPT_DARK_ESCAPE)
			Sleep(70)
		EndIf

		Return True
	EndIf

	; Movement mode: keep DE pressure high for speed and aggro-drop potential.
	If $allowDarkEscape And IsRecharged($UWPT_DARK_ESCAPE) And ($sfRemaining <= 1500 Or $hpPct <= 75) Then
		UseSkillEx($UWPT_DARK_ESCAPE)
		Sleep(70)
	EndIf

	Return False
EndFunc


Func UwPlainsTrainWaitAndMaintain($waitMs, $anchorX = Null, $anchorY = Null)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $waitMs And IsPlayerAlive()
		UwPlainsTrainMaintainSFTick(False, False)
		If $anchorX <> Null And $anchorY <> Null Then
			If Not IsPlayerMoving() And GetDistanceToPoint(GetMyAgent(), $anchorX, $anchorY) > 180 Then Move($anchorX, $anchorY, 0)
		EndIf
		Sleep(90)
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func UwPlainsTrainGetBestEffectTimeRemaining($skillID1, $skillID2 = 0)
	Local $v1 = UwPlainsTrainNormalizeEffectMs(GetEffectTimeRemaining($skillID1))
	If $skillID2 == 0 Then Return $v1
	Local $v2 = UwPlainsTrainNormalizeEffectMs(GetEffectTimeRemaining($skillID2))
	Return $v2 > $v1 ? $v2 : $v1
EndFunc


Func UwPlainsTrainNormalizeEffectMs($ms)
	; Guard against unstable/garbage effect values observed in recorder status snapshots.
	If $ms < 0 Then Return 0
	If $ms > 120000 Then Return 0
	Return $ms
EndFunc


Func UwPlainsTrainCanSpendEnergy($cost)
	Return GetEnergy() >= ($UWPT_SF_CHAIN_ENERGY_MIN + $cost + $UWPT_UTILITY_ENERGY_BUFFER)
EndFunc


Func UwPlainsTrainTryUseSkillSafe($skillSlot)
	If IsPlayerDead() Then Return False
	If IsCasting(GetMyAgent()) Then Return False
	If Not IsRecharged($skillSlot) Then Return False
	UseSkillEx($skillSlot)
	Return True
EndFunc


Func UwPlainsTrainStartPermaMaintenanceAdlib()
	If $uwpt_perma_adlib_active Then Return
	AdlibRegister('UwPlainsTrainMaintainPermaAdlibTick', 120)
	$uwpt_perma_adlib_active = True
EndFunc


Func UwPlainsTrainStopPermaMaintenanceAdlib()
	If Not $uwpt_perma_adlib_active Then Return
	AdlibUnRegister('UwPlainsTrainMaintainPermaAdlibTick')
	$uwpt_perma_adlib_active = False
EndFunc


Func UwPlainsTrainMaintainPermaAdlibTick()
	If Not IsPlayerAlive() Then Return
	UwPlainsTrainMaintainSFTick(False, False)
EndFunc


Func UwPlainsTrainStartAutoRecording()
	If Not $UWPT_AUTO_RECORDING Then Return
	If $path_action_recorder_active Then Return

	StartPathActionRecorder()
	If $path_action_recorder_active Then PathActionRecorderMark('UWPT_RUN_START')
EndFunc


Func UwPlainsTrainStopAutoRecording($endNote = 'UWPT_RUN_END')
	If Not $UWPT_AUTO_RECORDING Then Return
	If Not $path_action_recorder_active Then Return

	PathActionRecorderMark($endNote)
	StopPathActionRecorder()
EndFunc


Func UwPlainsTrainRunPlainsFromChamberExit()
	Info('Continuing after chamber clear: chamber exit -> run clockwork -> mountains -> first plains safe spot')

	Local $chamberExitPath[12][2] = [ _
		[-1207, 6524], _
		[-2020, 5836], _
		[-2894, 4956], _
		[-3138, 3798], _
		[-3105, 3253], _
		[-3402, 2211], _
		[-3519, 1212], _
		[-2547, 1475], _
		[-1432, 1779], _
		[-391, 1687], _
		[897, 1816], _
		[1943, 2835] _
	]

	If UwPlainsTrainFollowPath($chamberExitPath, 310, 22000, 'chamber-exit', True) == $FAIL Then Return $FAIL

	Info('Preparing solo run: force pre-run set, fill energy, and start stable chain clockwork')
	ChangeWeaponSet($UWPT_WEAPON_SET_PRE_RUN)
	PathActionRecorderMark('UWPT_SET_PRE_RUN')
	Sleep(200)
	ChangeWeaponSet($UWPT_WEAPON_SET_PRE_RUN)
	If UwPlainsTrainWaitForRunStartReadiness(12000) == $FAIL Then Return $FAIL
	If UwPlainsTrainPrimeRunClockwork(6500) == $FAIL Then Return $FAIL

	Info('Heroes remain unflagged during run for natural support/speed')
	CancelAllHeroes()
	RandomSleep(350)

	Local $safeRunPath[4][2] = [ _
		[3017, 2140], _
		[6290, 1341], _
		[6732, 1744], _
		[7905, 265] _
	]

	Local $safeSpotSecured = False
	If GetDistanceToPoint(GetMyAgent(), $UWPT_FIRST_SAFE_SPOT_X, $UWPT_FIRST_SAFE_SPOT_Y) <= 320 Then
		$safeSpotSecured = True
	Else
		If UwPlainsTrainFollowPath($safeRunPath, 310, 22000, 'safe-run', True) == $SUCCESS Then
			If UwPlainsTrainExecuteMountainShockGate() == $SUCCESS Then
				Local $postGatePath[3][2] = [ _
					[8380, -6554], _
					[7798, -7798], _
					[8873, -8096] _
				]

				If UwPlainsTrainFollowPath($postGatePath, 320, 17000, 'safe-run-post-gate', True) == $SUCCESS Then
					If UwPlainsTrainSprintIntoFirstSafeSpot() == $SUCCESS Then $safeSpotSecured = True
				EndIf
			EndIf
		EndIf
	EndIf

	If $safeSpotSecured Then
		Info('Reached first safe spot. Switching to scythe and preparing first target choreography')
		ChangeWeaponSet($UWPT_WEAPON_SET_POST_SAFE)
		PathActionRecorderMark('UWPT_SET_POST_SAFE')
		If UwPlainsTrainWaitAndMaintain(12000, $UWPT_FIRST_SAFE_SPOT_X, $UWPT_FIRST_SAFE_SPOT_Y) == $FAIL Then Return $FAIL
	Else
		Warn('Safe spot was not secured from sprint path; aborting before first plains fight')
		Return $FAIL
	EndIf

	Info('Moving to next Underworld plains spot (spot 2 anchor)')
	If UwPlainsTrainMoveToPointRobust($UWPT_FIRST_PLANES_ANCHOR_X, $UWPT_FIRST_PLANES_ANCHOR_Y, 260, 12000, 'spot2-anchor', True) == $FAIL Then Return $FAIL

	Info('Spot 2 kill order: Banished Dream Riders + Wailing Lords, then Spectres via pull')
	If UwPlainsTrainClearSpotTwoPrioritized() == $FAIL Then Return $FAIL

	Return $SUCCESS
EndFunc


Func UwPlainsTrainWaitForRunStartReadiness($maxWaitMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs
		If Not IsPlayerAlive() Then Return $FAIL

		UwPlainsTrainMaintainSFTick(False, False)
		Local $sfRemaining = UwPlainsTrainGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP)
		Local $sodRemaining = UwPlainsTrainGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)
		Local $energyNow = GetEnergy()

		If $energyNow >= $UWPT_PRE_RUN_ENERGY_MIN And $sfRemaining > 2500 And $sodRemaining > 1200 Then
			Return $SUCCESS
		EndIf

		Sleep(120)
	WEnd

	Warn('Run-start readiness timeout: proceeding with current state')
	Return $SUCCESS
EndFunc


Func UwPlainsTrainPrimeRunClockwork($maxWaitMs)
	Local $timer = TimerInit()

	While TimerDiff($timer) < $maxWaitMs
		If Not IsPlayerAlive() Then Return $FAIL

		ChangeWeaponSet($UWPT_WEAPON_SET_PRE_RUN)
		UwPlainsTrainMaintainSFTick(False, False)

		Local $energyNow = GetEnergy()
		Local $sfRemaining = UwPlainsTrainGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP)
		Local $sodRemaining = UwPlainsTrainGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)

		If $energyNow >= $UWPT_PRE_RUN_ENERGY_TARGET Then
			; Freshen the chain right before run: SoMS -> DP -> SF -> SoD.
			If IsRecharged($UWPT_SIGNET_OF_MYSTIC_SPEED) Then
				UseSkillEx($UWPT_SIGNET_OF_MYSTIC_SPEED)
				Sleep(90)
			EndIf

			If IsRecharged($UWPT_DEADLY_PARADOX) Then
				UseSkillEx($UWPT_DEADLY_PARADOX)
				Sleep(90)
			EndIf

			If IsRecharged($UWPT_SHADOW_FORM) Then
				UseSkillEx($UWPT_SHADOW_FORM)
				Sleep(120)
			EndIf

			If IsRecharged($UWPT_SHROUD_OF_DISTRESS) And UwPlainsTrainCanSpendEnergy($UWPT_COST_SHROUD_OF_DISTRESS) Then
				UseSkillEx($UWPT_SHROUD_OF_DISTRESS)
				Sleep(80)
			EndIf

			$sfRemaining = UwPlainsTrainGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP)
			$sodRemaining = UwPlainsTrainGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)
			If $sfRemaining > 2500 And $sodRemaining > 1200 Then
				PathActionRecorderMark('UWPT_CLOCKWORK_PRIME_DONE')
				Return $SUCCESS
			EndIf
		EndIf

		Sleep(120)
	WEnd

	Warn('Run clockwork prime timeout; continuing with current chain state')
	Return $SUCCESS
EndFunc


Func UwPlainsTrainSprintIntoFirstSafeSpot()
	If GetDistanceToPoint(GetMyAgent(), $UWPT_FIRST_SAFE_SPOT_X, $UWPT_FIRST_SAFE_SPOT_Y) > $UWPT_SAFE_SPOT_APPROACH_RANGE Then Return $FAIL

	ChangeWeaponSet($UWPT_WEAPON_SET_PRE_RUN)
	If IsRecharged($UWPT_DARK_ESCAPE) Then
		UseSkillEx($UWPT_DARK_ESCAPE)
		Sleep(90)
	EndIf

	Return UwPlainsTrainMoveToPointRobust($UWPT_FIRST_SAFE_SPOT_X, $UWPT_FIRST_SAFE_SPOT_Y, 260, 7000, 'safe-spot-de-hop', False)
EndFunc


Func UwPlainsTrainForcePrecastBeforeDanger()
	ChangeWeaponSet($UWPT_WEAPON_SET_PRE_RUN)

	; Force a fresh defensive chain before the mountain shock gauntlet.
	If IsRecharged($UWPT_SIGNET_OF_MYSTIC_SPEED) Then
		UseSkillEx($UWPT_SIGNET_OF_MYSTIC_SPEED)
		Sleep(90)
	EndIf

	If IsRecharged($UWPT_DEADLY_PARADOX) Then
		UseSkillEx($UWPT_DEADLY_PARADOX)
		Sleep(90)
	EndIf

	If IsRecharged($UWPT_SHADOW_FORM) And GetEnergy() >= $UWPT_SF_CHAIN_ENERGY_MIN Then
		UseSkillEx($UWPT_SHADOW_FORM)
		Sleep(110)
	EndIf

	If IsRecharged($UWPT_SHROUD_OF_DISTRESS) And UwPlainsTrainCanSpendEnergy($UWPT_COST_SHROUD_OF_DISTRESS) Then
		UseSkillEx($UWPT_SHROUD_OF_DISTRESS)
		Sleep(80)
	EndIf

	Return $SUCCESS
EndFunc


Func UwPlainsTrainExecuteMountainShockGate()
	If UwPlainsTrainMoveToPointRobust($UWPT_MOUNTAIN_GATE_PRE_X, $UWPT_MOUNTAIN_GATE_PRE_Y, 250, 9000, 'mountain-gate-pre', True) == $FAIL Then Return $FAIL

	PathActionRecorderMark('UWPT_MOUNTAIN_GATE_PRECAST')
	If UwPlainsTrainForcePrecastBeforeDanger() == $FAIL Then Return $FAIL

	PathActionRecorderMark('UWPT_MOUNTAIN_GATE_DE_SPRINT')
	If IsRecharged($UWPT_DARK_ESCAPE) Then
		UseSkillEx($UWPT_DARK_ESCAPE)
		Sleep(90)
	EndIf

	Local $shockGatePath[4][2] = [ _
		[8021, -275], _
		[8824, -1125], _
		[8385, -2335], _
		[$UWPT_MOUNTAIN_GATE_POST_X, $UWPT_MOUNTAIN_GATE_POST_Y] _
	]

	Return UwPlainsTrainFollowPath($shockGatePath, 340, 14000, 'mountain-shock-gate', True)
EndFunc


Func UwPlainsTrainClearSpotTwoPrioritized()
	If UwPlainsTrainPullAndKillByModel($UWPT_MODEL_BANISHED_DREAM_RIDER, $UWPT_FIRST_PLANES_ANCHOR_X, $UWPT_FIRST_PLANES_ANCHOR_Y, 4) == $FAIL Then Return $FAIL
	If UwPlainsTrainPullAndKillByModel($UWPT_MODEL_WAILING_LORD, $UWPT_FIRST_PLANES_ANCHOR_X, $UWPT_FIRST_PLANES_ANCHOR_Y, 4) == $FAIL Then Return $FAIL
	If UwPlainsTrainPullAndKillByModel($UWPT_MODEL_SPECTRE, $UWPT_FIRST_PLANES_ANCHOR_X, $UWPT_FIRST_PLANES_ANCHOR_Y, 7) == $FAIL Then Return $FAIL

	; Safety sweep in case model IDs were partial or mixed in this pull window.
	Return UwPlainsTrainKillEngineTick(9000)
EndFunc


Func UwPlainsTrainPullAndKillByModel($modelID, $anchorX, $anchorY, $maxPasses)
	For $i = 1 To $maxPasses
		If Not IsPlayerAlive() Then Return $FAIL

		Local $target = UwPlainsTrainGetNearestFoeByModel($modelID, 6000)
		If $target == Null Then ExitLoop

		; Balling movement on set 1 for better energy recovery.
		ChangeWeaponSet($UWPT_WEAPON_SET_PRE_RUN)
		ChangeTarget($target)
		Attack($target)

		Local $tx = DllStructGetData($target, 'X')
		Local $ty = DllStructGetData($target, 'Y')
		If UwPlainsTrainMoveToPointRobust($tx, $ty, 380, 4500, 'pull-model-' & $modelID, True) == $FAIL Then Return $FAIL

		; Pull back to anchor and kill in controlled position.
		ChangeWeaponSet($UWPT_WEAPON_SET_PRE_RUN)
		If UwPlainsTrainMoveToPointRobust($anchorX, $anchorY, 260, 7000, 'pull-anchor-' & $modelID, True) == $FAIL Then Return $FAIL

		Local $killWindow = 5500
		If $modelID == $UWPT_MODEL_SPECTRE Then
			Local $spectreBallCount = UwPlainsTrainCountFoesByModelInRange($UWPT_MODEL_SPECTRE, 1200)
			Info('Spectre ball at anchor: ' & $spectreBallCount)

			If $spectreBallCount < $UWPT_SPECTRE_BALL_MIN And $i < $maxPasses Then
				; Keep luring if we do not have enough stacked targets yet.
				ContinueLoop
			EndIf

			$killWindow = ($spectreBallCount >= $UWPT_SPECTRE_BALL_IDEAL) ? 8500 : 7000
		EndIf

		; Swap to scythe only for the actual fight window.
		ChangeWeaponSet($UWPT_WEAPON_SET_POST_SAFE)
		If UwPlainsTrainKillEngineTick($killWindow) == $FAIL Then Return $FAIL
	Next

	Return $SUCCESS
EndFunc


Func UwPlainsTrainCountFoesByModelInRange($modelID, $range)
	Local $me = GetMyAgent()
	Local $count = 0

	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		If DllStructGetData($agent, 'ModelID') <> $modelID Then ContinueLoop
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then ContinueLoop
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop
		If GetDistance($me, $agent) > $range Then ContinueLoop
		$count += 1
	Next

	Return $count
EndFunc


Func UwPlainsTrainGetNearestFoeByModel($modelID, $maxRange = 100000)
	Local $me = GetMyAgent()
	Local $nearest = Null
	Local $nearestDistance = 100000000

	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		If DllStructGetData($agent, 'ModelID') <> $modelID Then ContinueLoop
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then ContinueLoop
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop

		Local $distance = GetDistance($me, $agent)
		If $distance > $maxRange Then ContinueLoop
		If $distance < $nearestDistance Then
			$nearestDistance = $distance
			$nearest = $agent
		EndIf
	Next

	Return $nearest
EndFunc


; Chamber fast-start variant for trainer use:
; stop after taking quest and clearing first required grasping darkness packs.
Func UwPlainsTrainClearTheChamberFastStart()
	Info('Moving to left of the stairs')
	MoveAggroAndKill(-495, 6509)
	MoveAggroAndKill(-2191, 5688)
	Info('Moving to the middle of the chamber')
	MoveAggroAndKill(-1371, 7179)
	MoveAggroAndKill(-1244, 7835)
	Info('Killing Pop-Up')
	MoveAggroAndKill(-862, 8923)
	Info('Going up Middle of chamber stairs')
	MoveAggroAndKill(-1669, 10631)

	Info('Going for skeletons')
	MoveAggroAndKill(-2706, 10149)
	Info('Killing skeletons')
	MoveAggroAndKill(-1767, 10583)
	MoveAggroAndKill(-694, 8957)

	Info('Moving to Aatxes at top right of stairs')
	MoveAggroAndKill(-106, 9116)
	MoveAggroAndKill(848, 9720)
	Info('Killing pop-up')
	MoveAggroAndKill(1204, 10380)

	Info('Bottom Stairs right side chamber')
	MoveAggroAndKill(1119, 12220)
	MoveAggroAndKill(1659, 12775)
	MoveAggroAndKill(2503, 13092)
	MoveAggroAndKill(3242, 12862)
	MoveAggroAndKill(2252, 13197)
	MoveAggroAndKill(1146, 12451)

	Info('Going back for quest')
	MoveAggroAndKill(1196, 10567)
	MoveAggroAndKill(461, 9219)
	MoveAggroAndKill(879, 7759)
	MoveAggroAndKill(910, 7115)
	MoveTo(378, 7209)

	Info('Taking Clear the Chamber Quest')
	Local $lostSoul = GetNearestNPCToCoords(246, 7177)
	TakeQuest($lostSoul, $ID_QUEST_CLEAR_THE_CHAMBER, 0x0806501)

	; Fast quest completion route: clear only until quest reward is done, then start run immediately.
	Local $questClearPath[8][2] = [ _
		[187, 6606], _
		[-1977, 5802], _
		[-1207, 6524], _
		[-1361, 7832], _
		[-805, 8886], _
		[553, 9338], _
		[-1495, 10562], _
		[-2824, 10222] _
	]

	For $i = 0 To UBound($questClearPath) - 1
		If IsQuestReward($ID_QUEST_CLEAR_THE_CHAMBER) Then
			Info('Clear the Chamber quest already complete, aborting extra packs and starting run')
			ExitLoop
		EndIf

		MoveAggroAndKill($questClearPath[$i][0], $questClearPath[$i][1])
	Next

	If Not IsQuestReward($ID_QUEST_CLEAR_THE_CHAMBER) Then
		Warn('Clear the Chamber quest reward not confirmed yet; continuing with run-start route anyway')
	EndIf

	Info('Fast chamber objective done, starting mountains/plains run now')
	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


; 1:1 sequence from Underworld ClearTheChamberUnderworld (route/coords/order unchanged).
Func UwPlainsTrainClearTheChamberUnchanged()
	Info('Moving to left of the stairs')
	MoveAggroAndKill(-495, 6509)
	MoveAggroAndKill(-2191, 5688)
	Info('Moving to the middle of the chamber')
	MoveAggroAndKill(-1371, 7179)
	MoveAggroAndKill(-1244, 7835)
	Info('Killing Pop-Up')
	MoveAggroAndKill(-862, 8923)
	Info('Going up Middle of chamber stairs')
	MoveAggroAndKill(-1669, 10631)

	Info('Going for skeletons')
	MoveAggroAndKill(-2706, 10149)
	Info('Killing skeletons')
	MoveAggroAndKill(-1767, 10583)
	MoveAggroAndKill(-694, 8957)

	Info('Moving to Aatxes at top right of stairs')
	MoveAggroAndKill(-106, 9116)
	MoveAggroAndKill(848, 9720)
	Info('Killing pop-up')
	MoveAggroAndKill(1204, 10380)

	Info('Bottom Stairs right side chamber')
	MoveAggroAndKill(1119, 12220)
	MoveAggroAndKill(1659, 12775)
	MoveAggroAndKill(2503, 13092)
	MoveAggroAndKill(3242, 12862)
	MoveAggroAndKill(2252, 13197)
	MoveAggroAndKill(1146, 12451)

	Info('Going back for quest')
	MoveAggroAndKill(1196, 10567)
	MoveAggroAndKill(461, 9219)
	MoveAggroAndKill(879, 7759)
	MoveAggroAndKill(910, 7115)
	MoveTo(378, 7209)

	Info('Taking Clear the Chamber Quest')
	Local $lostSoul = GetNearestNPCToCoords(246, 7177)
	TakeQuest($lostSoul, $ID_QUEST_CLEAR_THE_CHAMBER, 0x0806501)
	MoveAggroAndKill(187, 6606)
	MoveAggroAndKill(-1977, 5802)
	MoveAggroAndKill(-1207, 6524)
	MoveAggroAndKill(-1361, 7832)
	MoveAggroAndKill(-805, 8886)
	MoveAggroAndKill(553, 9338)
	Sleep(30000)
	MoveAggroAndKill(-1495, 10562)
	MoveAggroAndKill(-2824, 10222)
	MoveAggroAndKill(-4210, 11372)
	MoveAggroAndKill(-4675, 11733)
	MoveAggroAndKill(-4186, 12722)
	MoveAggroAndKill(-4050, 13182)
	MoveAggroAndKill(-5572, 13250)
	Info('Killing Terrorweb Dryders')
	MoveAggroAndKill(-5694, 12772)
	MoveAggroAndKill(-5922, 11468)
	MoveAggroAndKill(-5897, 12496)
	MoveAggroAndKill(-5694, 12772)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc
