#CS ===========================================================================
; Author: GitHub Copilot
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
#include '../../lib/Utils-Agents.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $OUTCAST_HALCYON_SKILLBAR = 'OgQTUYLfHSNI4B4C6gucX8GclBA'
Global Const $OUTCAST_HALCYON_FARM_INFORMATIONS = 'R/N Outcast farmer in Boreas Seabed based on Protect the Halcyon.' & @CRLF _
	& 'Core behavior:' & @CRLF _
	& '- Never take quest reward, always abandon and retake from Captain Lexis' & @CRLF _
	& '- Travel: Cavalon -> Zos Shivros Channel -> Boreas Seabed explorable' & @CRLF _
	& '- Sprint to Rion, open event, hold farm spot, clear 4 waves, loot, resign' & @CRLF _
	& '- Build code: ' & $OUTCAST_HALCYON_SKILLBAR
Global Const $OUTCAST_HALCYON_FARM_DURATION = 12 * 60 * 1000
Global Const $OUTCAST_WAVES_TO_CLEAR = 4
Global Const $OUTCAST_MAX_WAVE_CYCLES = 10
Global Const $OUTCAST_MAX_CHOREO_ATTEMPTS = 4
Global Const $OUTCAST_FAST_MODE = True
Global Const $OUTCAST_FAST_PERSIST_W1_MS = 12000
Global Const $OUTCAST_FAST_PERSIST_OTHER_MS = 9000
Global Const $OUTCAST_FAST_CALM_W1_MS = 7000
Global Const $OUTCAST_FAST_CALM_OTHER_MS = 5500

Global Const $OUTCAST_ROTTING_FLESH = 1
Global Const $OUTCAST_LACERATE = 2
Global Const $OUTCAST_TOXICITY = 3
Global Const $OUTCAST_EDGE_OF_EXTINCTION = 4
Global Const $OUTCAST_EBON_ESCAPE = 5
Global Const $OUTCAST_EVAS = 6
Global Const $OUTCAST_NECROSIS = 7
Global Const $OUTCAST_RUN_AS_ONE = 8

Global Const $OUTCAST_QUEST_ID = $ID_QUEST_PROTECT_THE_HALCYON
Global Const $OUTCAST_QUEST_OBJECTIVE_BYTES = 128
Global Const $OUTCAST_LEXIS_X = 7244
Global Const $OUTCAST_LEXIS_Y = -1439
Global Const $OUTCAST_LEXIS_MODEL_ID = 3654
Global Const $OUTCAST_RION_X = 10631
Global Const $OUTCAST_RION_Y = -3441
Global Const $OUTCAST_RION_MODEL_ID = 3215
Global Const $OUTCAST_DISPLACEMENT_MODEL_ID = 4268
Global Const $OUTCAST_RION_INTERACT_ATTEMPTS = 1
Global Const $OUTCAST_RION_FINAL_STANDOFF_DIST = 160
Global Const $OUTCAST_RION_MOUSE_CLICK_TRIES = 2
Global Const $OUTCAST_HOLD_X = 9334
Global Const $OUTCAST_HOLD_Y = -6175
Global Const $OUTCAST_HUG_SHIP_X = 10577
Global Const $OUTCAST_HUG_SHIP_Y = -4982
Global Const $OUTCAST_SCAN_SHIP_X = 11186
Global Const $OUTCAST_SCAN_SHIP_Y = -5218
Global Const $OUTCAST_WAVE_CENTER_X = 9726
Global Const $OUTCAST_WAVE_CENTER_Y = -6197
Global Const $OUTCAST_HUG_TRIGGER_HP = 0.10
Global Const $OUTCAST_GENERAL_CHOREO_MAX_MS = 95000
Global Const $OUTCAST_GENERAL_RF_RECAST_HP_DELTA = 0.03
Global Const $OUTCAST_GENERAL_RF_RECAST_ARM_HP = 0.70
Global Const $OUTCAST_GENERAL_RF_RECAST_MIN_INTERVAL_MS = 2800
Global Const $OUTCAST_GENERAL_NO_PROGRESS_RECYCLE_MS = 9000
Global Const $OUTCAST_GENERAL_HP_STALL_HIGH = 0.95
Global Const $OUTCAST_GENERAL_HP_HARD_RESET_DELTA = 0.20
Global Const $OUTCAST_GENERAL_NO_DROP_RESTART_WINDOW_MS = 9000
Global Const $OUTCAST_GENERAL_NO_DROP_WAIT_MS = 60000
Global Const $OUTCAST_POST_HUG_NEXT_WAVE_FOE_MIN = 4
Global Const $OUTCAST_POST_HUG_NEXT_WAVE_STABLE_MS = 12000
Global Const $OUTCAST_AUTO_RECORD_FIRST_TEST = True
Global Const $OUTCAST_QUICKTEST_MODE = True
Global Const $OUTCAST_DEBUG_START_AT_ZOS = $OUTCAST_QUICKTEST_MODE
Global Const $OUTCAST_DEBUG_ALWAYS_REFRESH_QUEST = False
Global Const $OUTCAST_DISABLE_RESIGN_FOR_TESTS = $OUTCAST_QUICKTEST_MODE
Global Const $OUTCAST_DRYRUN_SPIRIT_TARGET_PROBE = False
Global Const $OUTCAST_KEEP_AWAKE = True

Global Const $OUTCAST_ES_SYSTEM_REQUIRED = 0x00000001
Global Const $OUTCAST_ES_DISPLAY_REQUIRED = 0x00000002
Global Const $OUTCAST_ES_CONTINUOUS = 0x80000000

Global $outcast_halcyon_farm_setup = False
Global $outcast_started_recorder = False
Global $outcast_rion_model_deathhand = 0
Global $outcast_rion_model_ritualist = 0


Func OutcastHalcyonFarm()
	If Not $outcast_halcyon_farm_setup And SetupOutcastHalcyonFarm() == $FAIL Then Return $PAUSE

	OutcastTryStartRecorder()
	OutcastMark('OH_RUN_START')
	Local $result = OutcastHalcyonFarmLoop()
	OutcastMark('OH_RUN_END_' & ($result == $SUCCESS ? 'SUCCESS' : 'FAIL'))
	OutcastTryStopRecorder()
	If Not $OUTCAST_DISABLE_RESIGN_FOR_TESTS Then
		ResignAndReturnToOutpost($ID_CAVALON)
	Else
		OutcastMark('OH_DEBUG_RESIGN_SKIPPED')
	EndIf
	Return $result
EndFunc


Func SetupOutcastHalcyonFarm()
	Info('Setting up Outcast Halcyon farm')
	OutcastEnableKeepAwake()
	If $OUTCAST_QUICKTEST_MODE Then
		Info('Debug start enabled: travelling directly to Zos Shivros Channel')
		If TravelToOutpost($ID_ZOS_SHIVROS_CHANNEL, $district_name) == $FAIL Then Return $FAIL
	Else
		If TravelToOutpost($ID_CAVALON, $district_name) == $FAIL Then Return $FAIL
	EndIf
	SwitchToHardModeIfEnabled()

	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_RANGER Then
		Warn('Outcast Halcyon should run as Ranger primary')
		Return $FAIL
	EndIf

	LoadSkillTemplate($OUTCAST_HALCYON_SKILLBAR)
	RandomSleep(400)
	LeaveParty()
	RandomSleep(300)

	$outcast_halcyon_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func OutcastEnableKeepAwake()
	If Not $OUTCAST_KEEP_AWAKE Then Return
	; Prevent idle display/system sleep during long unattended runs.
	Local $r = DllCall('kernel32.dll', 'dword', 'SetThreadExecutionState', 'dword', BitOR($OUTCAST_ES_CONTINUOUS, $OUTCAST_ES_SYSTEM_REQUIRED, $OUTCAST_ES_DISPLAY_REQUIRED))
	If @error Or Not IsArray($r) Or $r[0] == 0 Then
		OutcastMark('OH_KEEP_AWAKE_SET_FAIL')
	Else
		OutcastMark('OH_KEEP_AWAKE_SET')
	EndIf
EndFunc


Func OutcastHalcyonFarmLoop()
	Info('Starting Outcast Halcyon run')
	If Not $OUTCAST_QUICKTEST_MODE Then
		OutcastMark('OH_QUEST_CHECK_BEGIN')
		If OutcastEnsureQuestResetAtRunStart() == $FAIL Then Return $FAIL
		OutcastMark('OH_QUEST_CHECK_DONE')

		OutcastMark('OH_TRAVEL_CAVALON')
		If TravelToOutpost($ID_CAVALON, $district_name) == $FAIL Then Return $FAIL

		OutcastMark('OH_QUEST_TAKE_BEGIN')
		If OutcastRefreshProtectHalcyonQuest() == $FAIL Then Return $FAIL
		OutcastMark('OH_QUEST_TAKE_DONE')
	Else
		OutcastMark('OH_DEBUG_SKIP_QUEST_FLOW')
		Local $debugQuest = GetQuestByID($OUTCAST_QUEST_ID)
		Local $debugState = -1
		If $debugQuest <> Null Then $debugState = DllStructGetData($debugQuest, 'LogState')

		; In debug mode we start in Zos, but Lexis (quest giver) is in Cavalon.
		; Optional hard refresh keeps quest state deterministic across repeated tests.
		If $OUTCAST_DEBUG_ALWAYS_REFRESH_QUEST Or $debugState <> $ID_QUEST_ACTIVE Then
			OutcastMark('OH_DEBUG_QUEST_REFRESH_BEGIN')
			OutcastMark('OH_DEBUG_QUEST_REFRESH_TRAVEL_CAVALON')
			If TravelToOutpost($ID_CAVALON, $district_name) == $FAIL Then Return $FAIL
			If OutcastEnsureQuestResetAtRunStart() == $FAIL Then Return $FAIL
			If OutcastRefreshProtectHalcyonQuest() == $FAIL Then Return $FAIL
			OutcastMark('OH_DEBUG_QUEST_REFRESH_TRAVEL_ZOS')
			If TravelToOutpost($ID_ZOS_SHIVROS_CHANNEL, $district_name) == $FAIL Then Return $FAIL
			OutcastMark('OH_DEBUG_QUEST_REFRESH_DONE')
		Else
			OutcastMark('OH_DEBUG_QUEST_ACTIVE')
		EndIf
	EndIf

	OutcastMark('OH_TRAVEL_ZOS_BEGIN')
	If OutcastTravelToBoreasExplorable() == $FAIL Then
		OutcastMark('OH_FAIL_TRAVEL_BOREAS')
		OutcastMarkFailureContext('OH_FAIL_CTX_TRAVEL_BOREAS')
		Return $FAIL
	EndIf
	OutcastMark('OH_TRAVEL_ZOS_DONE')
	If $OUTCAST_DRYRUN_SPIRIT_TARGET_PROBE Then
		OutcastMark('OH_DRYRUN_SPIRIT_PROBE_MODE')
		Return OutcastDryRunSpiritTargetProbe()
	EndIf

	OutcastMark('OH_RION_PHASE_BEGIN')
	If OutcastOpenRionPhase() == $FAIL Then
		OutcastMark('OH_FAIL_RION_PHASE')
		OutcastMarkFailureContext('OH_FAIL_CTX_RION_PHASE')
		Return $FAIL
	EndIf
	OutcastMark('OH_RION_PHASE_DONE')

	OutcastMark('OH_HOLD_MOVE_BEGIN')
	If OutcastMoveToHoldSpot() == $FAIL Then
		OutcastMark('OH_FAIL_HOLD_MOVE')
		OutcastMarkFailureContext('OH_FAIL_CTX_HOLD_MOVE')
		Return $FAIL
	EndIf
	OutcastMark('OH_HOLD_MOVE_DONE')

	Local $cycle = 1
	Local $readyToLoot = False
	While $cycle <= $OUTCAST_MAX_WAVE_CYCLES And IsPlayerAlive()
		OutcastMark('OH_CYCLE_' & $cycle & '_BEGIN')
		Info('Handling fight cycle #' & $cycle)
		OutcastMark('OH_CYCLE_' & $cycle & '_WAIT_BALL_BEGIN')
		If OutcastWaitForWaveStack($cycle) == $FAIL Then
			OutcastMark('OH_FAIL_CYCLE_' & $cycle & '_WAIT_BALL')
			OutcastMarkFailureContext('OH_FAIL_CTX_CYCLE_' & $cycle & '_WAIT_BALL')
			Return $FAIL
		EndIf
		OutcastMark('OH_CYCLE_' & $cycle & '_WAIT_BALL_DONE')

		If OutcastExecuteWaveChoreography($cycle) == $FAIL Then
			OutcastMark('OH_FAIL_CYCLE_' & $cycle & '_FIGHT')
			OutcastMarkFailureContext('OH_FAIL_CTX_CYCLE_' & $cycle & '_FIGHT')
			Return $FAIL
		EndIf
		OutcastMark('OH_CYCLE_' & $cycle & '_FIGHT_DONE')

		; After Hug->Hold, loot only when no outcasts are present for a full minute.
		OutcastMark('OH_CYCLE_' & $cycle & '_POST_HUG_CLEAR_WAIT_BEGIN')
		Local $waitStart = TimerInit()
		Local $noFoeSince = 0
		Local $nextWaveSince = 0
		Local $clearHeartbeat = TimerInit()
		While TimerDiff($waitStart) < 90000 And IsPlayerAlive()
			Local $foesNow = OutcastCountActiveWaveFoes()
			If $foesNow <= 0 Then
				If $noFoeSince == 0 Then
					$noFoeSince = TimerInit()
					OutcastMark('OH_CYCLE_' & $cycle & '_CLEAR_NO_FOE_TIMER_START')
				EndIf
				$nextWaveSince = 0
				If TimerDiff($noFoeSince) >= 60000 Then
					OutcastMark('OH_CYCLE_' & $cycle & '_CLEAR_60S_NO_FOES')
					$readyToLoot = True
					ExitLoop
				EndIf
			Else
				$noFoeSince = 0
				If $foesNow >= $OUTCAST_POST_HUG_NEXT_WAVE_FOE_MIN Then
					If $nextWaveSince == 0 Then
						$nextWaveSince = TimerInit()
						OutcastMark('OH_CYCLE_' & $cycle & '_NEXT_WAVE_TIMER_START_FOES_' & $foesNow)
					ElseIf TimerDiff($nextWaveSince) >= $OUTCAST_POST_HUG_NEXT_WAVE_STABLE_MS Then
						OutcastMark('OH_CYCLE_' & $cycle & '_NEXT_WAVE_STABLE_CONTINUE_FOES_' & $foesNow)
						ExitLoop
					EndIf
				Else
					$nextWaveSince = 0
				EndIf
			EndIf

			If TimerDiff($clearHeartbeat) >= 9000 Then
				OutcastMark('OH_CYCLE_' & $cycle & '_POST_HUG_FOES_' & $foesNow)
				$clearHeartbeat = TimerInit()
			EndIf
			RandomSleep(350)
		WEnd

		If Not IsPlayerAlive() Then
			OutcastMark('OH_FAIL_CYCLE_' & $cycle & '_DEAD_POST_HUG_WAIT')
			OutcastMarkFailureContext('OH_FAIL_CTX_CYCLE_' & $cycle & '_POST_HUG_WAIT')
			Return $FAIL
		EndIf

		If $readyToLoot Then ExitLoop
		OutcastMark('OH_CYCLE_' & $cycle & '_POST_HUG_WAIT_TIMEOUT_CONTINUE')
		$cycle += 1
	WEnd

	If Not $readyToLoot Then
		OutcastMark('OH_FAIL_NO_CLEAR_FOR_LOOT')
		OutcastMarkFailureContext('OH_FAIL_CTX_NO_CLEAR_FOR_LOOT')
		Return $FAIL
	EndIf

	OutcastMark('OH_LOOT_BEGIN')
	If OutcastLootDeck() == $FAIL Then
		OutcastMark('OH_FAIL_LOOT')
		OutcastMarkFailureContext('OH_FAIL_CTX_LOOT')
		Return $FAIL
	EndIf
	OutcastMark('OH_LOOT_DONE')
	Info('Outcast Halcyon run complete')
	Return $SUCCESS
EndFunc


Func OutcastEnsureQuestResetAtRunStart()
	OutcastMarkQuestState('OH_QUEST_STATE_PRECHECK')
	; Hard rule for this farm: start by checking the quest and abandoning it if present.
	Local $quest = GetQuestByID($OUTCAST_QUEST_ID)
	If $quest == Null Then Return $SUCCESS

	Info('Run-start quest reset: quest present, abandoning first')
	OutcastMark('OH_QUEST_ABANDON_START')
	For $i = 1 To 4
		AbandonQuest($OUTCAST_QUEST_ID)
		RandomSleep(300)
		If GetQuestByID($OUTCAST_QUEST_ID) == Null Then
			OutcastMark('OH_QUEST_ABANDON_DONE')
			Return $SUCCESS
		EndIf
	Next

	Warn('Quest reset failed: quest still present after abandon attempts')
	OutcastMark('OH_QUEST_ABANDON_FAIL')
	OutcastMarkQuestState('OH_QUEST_STATE_AFTER_ABANDON_FAIL')
	Return $FAIL
EndFunc


Func OutcastRefreshProtectHalcyonQuest()
	Local $existingQuest = GetQuestByID($OUTCAST_QUEST_ID)
	If $existingQuest <> Null Then
		Info('Abandoning Protect the Halcyon before retake')
		OutcastMark('OH_PRETAKE_ABANDON')
		AbandonQuest($OUTCAST_QUEST_ID)
		RandomSleep(400)
	EndIf

	Info('Taking Protect the Halcyon from Captain Lexis')
	OutcastWaitForLexisAgentData(5000)
	OutcastMarkQuestState('OH_QUEST_STATE_PRETAKE')
	For $i = 1 To 4
		OutcastMoveNearLexis()
		OutcastWaitForLexisAgentData(2500)
		Local $lexis = OutcastGetLexisNPC()
		If $lexis == Null Then
			Warn('Could not locate Captain Lexis NPC (model 3654). Quest might be unavailable for this character.')
			OutcastMark('OH_QUEST_TAKE_NPC_NOT_FOUND')
			OutcastMarkLexisNearbyNPCs()
			RandomSleep(450)
			ExitLoop
		EndIf

		Local $lexisModel = DllStructGetData($lexis, 'ModelID')
		Local $lexisDist = Int(GetDistanceToPoint($lexis, $OUTCAST_LEXIS_X, $OUTCAST_LEXIS_Y))
		OutcastMark('OH_QUEST_TAKE_DIST_' & $lexisDist)
		If $lexisModel == 1 Then OutcastMark('OH_QUEST_TAKE_MODEL_UNRESOLVED_1')
		If $lexisModel <> $OUTCAST_LEXIS_MODEL_ID And $lexisModel <> 1 Then OutcastMark('OH_QUEST_TAKE_WRONG_MODEL_' & $lexisModel)
		ChangeTarget($lexis)
		GoToNPC($lexis)
		RandomSleep(350)
		Dialog(0x84)
		RandomSleep(250)
		OutcastMark('OH_QUEST_TAKE_DIALOG_84')
		OutcastMark('OH_QUEST_TAKE_ATTEMPT_' & $i & '_MODEL_' & $lexisModel)
		AcceptQuest($OUTCAST_QUEST_ID)
		RandomSleep(550)
		If IsQuestActive($OUTCAST_QUEST_ID) Then
			OutcastMark('OH_QUEST_ACTIVE')
			Return $SUCCESS
		EndIf
		OutcastMarkQuestState('OH_QUEST_STATE_AFTER_ATTEMPT_' & $i)
	Next

	Warn('Could not take Protect the Halcyon quest')
	Return $FAIL
EndFunc


Func OutcastTravelToBoreasExplorable()
	If TravelToOutpost($ID_ZOS_SHIVROS_CHANNEL, $district_name) == $FAIL Then Return $FAIL

	Info('Moving from Zos Shivros Channel to Boreas Seabed explorable')
	Local $pathToPortal[4][2] = [[3746, 5272], [3543, 5561], [3462, 6014], [3472, 7340]]
	If OutcastFollowPath($pathToPortal, 40000) == $FAIL Then Return $FAIL

	Local $timer = TimerInit()
	While GetMapID() <> $ID_BOREAS_SEABED_EXPLORABLE
		If TimerDiff($timer) > 80000 Then
			Warn('Could not zone to Boreas Seabed explorable')
			Return $FAIL
		EndIf
		Move(3478, 7425)
		RandomSleep(1400)
		WaitMapLoading($ID_BOREAS_SEABED_EXPLORABLE, 8000, 500)
	WEnd
	OutcastMark('OH_MAP_BOREAS_EXPLORABLE')
	Return $SUCCESS
EndFunc


Func OutcastOpenRionPhase()
	Info('Sprinting to Rion phase')
	Local $rionPath[4][2] = [[13414, -9681], [12314, -7676], [11382, -4629], [11117, -4161]]
	If OutcastFollowPath($rionPath, 120000) == $FAIL Then Return $FAIL
	OutcastMark('OH_RION_PULL_POS')

	Info('Clearing Rion guard from safe pull spot')
	Local $guard = OutcastGetRionGuardTarget()
	If $guard == Null Then
		For $i = 1 To 9
			ClearTarget()
			RandomSleep(100)
			TargetNextEnemy()
			RandomSleep(180)
			$guard = GetCurrentTarget()
			If OutcastIsValidRionGuard($guard) Then ExitLoop
			$guard = OutcastGetRionGuardTarget()
			If $guard <> Null Then ExitLoop
			If $i == 4 Then MoveTo(11040, -4020, 100, 0)
			If $i == 7 Then MoveTo(10930, -3860, 100, 0)
		Next
	EndIf

	If Not OutcastIsValidRionGuard($guard) Then
		Warn('No Rion guard found in range')
		OutcastMark('OH_RION_GUARD_NOT_FOUND')
		Return $FAIL
	EndIf

	OutcastMark('OH_RION_GUARD_ENGAGE')
	ChangeTarget($guard)
	Local $guardModelInit = DllStructGetData($guard, 'ModelID')
	OutcastMark('OH_RION_GUARD_MODEL_' & $guardModelInit)
	Local $ritualistRottingDone = False
	Local $guardPrimaryInit = DllStructGetData($guard, 'Primary')
	Local $guardSecondaryInit = DllStructGetData($guard, 'Secondary')
	OutcastMark('OH_RION_GUARD_PROF_INIT_P' & $guardPrimaryInit & '_S' & $guardSecondaryInit)
	If IsRecharged($OUTCAST_EVAS) Then
		UseSkillEx($OUTCAST_EVAS, $guard)
		OutcastMark('OH_RION_EVAS_1')
		RandomSleep(220)
	EndIf

	Local $mode = 'UNKNOWN'
	Local $lastEnemySkill = 0
	Local $lastLoggedEnemySkill = -1
	Local $lastLoggedPrimary = -1
	Local $lastLoggedSecondary = -1
	Local $seenUfAtLeastOnce = False
	Local $modeDecisionStart = TimerInit()
	Local $ufWindowActive = False
	Local $ufNecrosisDone = False
	Local $ritualistSpiritVotes = 0
	Local $lastNecrosisAt = 0
	Local $lastEvasAt = 0
	Local $lastCombatTickAt = 0
	Local $engagedGuardID = DllStructGetData($guard, 'ID')
	Local $outOfRangeSince = 0
	If $outcast_rion_model_deathhand <> 0 And $guardModelInit == $outcast_rion_model_deathhand Then
		$mode = 'DEATHHAND'
		$seenUfAtLeastOnce = True
		OutcastMark('OH_RION_MODE_DEATHHAND_BY_MODEL')
	ElseIf $outcast_rion_model_ritualist <> 0 And $guardModelInit == $outcast_rion_model_ritualist Then
		$mode = 'RITUALIST'
		OutcastMark('OH_RION_MODE_RITUALIST_BY_MODEL')
	EndIf
	Local $killTimer = TimerInit()
	While TimerDiff($killTimer) < 70000 And IsPlayerAlive()
		$guard = GetAgentByID($engagedGuardID)
		If Not OutcastIsAttackableFoe($guard) Then
			; Lost current target handle: try to reacquire the closest valid guard.
			Local $reacquired = OutcastGetRionGuardTarget()
			If OutcastIsValidRionGuard($reacquired) Then
				$engagedGuardID = DllStructGetData($reacquired, 'ID')
				$guard = $reacquired
				OutcastMark('OH_RION_GUARD_REACQUIRED')
			Else
				ExitLoop
			EndIf
		EndIf

		Local $guardDist = GetDistance(GetMyAgent(), $guard)
		If $guardDist > $RANGE_SPELLCAST + 200 Then
			OutcastMark('OH_RION_GUARD_OUT_OF_RANGE')
			If $outOfRangeSince == 0 Then $outOfRangeSince = TimerInit()
			MoveTo(DllStructGetData($guard, 'X'), DllStructGetData($guard, 'Y'), 70, 0)
			GoNPC($guard)
			If TimerDiff($outOfRangeSince) > 9000 Then
				Local $fallbackGuard = OutcastGetRionGuardTarget()
				If OutcastIsValidRionGuard($fallbackGuard) Then
					$engagedGuardID = DllStructGetData($fallbackGuard, 'ID')
					$guard = $fallbackGuard
					OutcastMark('OH_RION_GUARD_REACQUIRED_FALLBACK')
				EndIf
				$outOfRangeSince = TimerInit()
			EndIf
			RandomSleep(220)
			ContinueLoop
		EndIf
		$outOfRangeSince = 0

		ChangeTarget($guard)
		If TimerDiff($lastCombatTickAt) > 3500 Then
			Local $hpRaw = DllStructGetData($guard, 'HealthPercent')
			Local $hpPct = Int($hpRaw)
			If $hpRaw >= 0 And $hpRaw <= 1.5 Then $hpPct = Int($hpRaw * 100)
			If $hpPct < 0 Then $hpPct = 0
			If $hpPct > 100 Then $hpPct = 100
			Local $dist = Int(GetDistance(GetMyAgent(), $guard))
			OutcastMark('OH_RION_COMBAT_TICK_HP_' & $hpPct & '_DIST_' & $dist)
			$lastCombatTickAt = TimerInit()
		EndIf

		Local $guardPrimary = DllStructGetData($guard, 'Primary')
		Local $guardSecondary = DllStructGetData($guard, 'Secondary')
		If $guardPrimary <> $lastLoggedPrimary Or $guardSecondary <> $lastLoggedSecondary Then
			OutcastMark('OH_RION_GUARD_PROF_P' & $guardPrimary & '_S' & $guardSecondary)
			$lastLoggedPrimary = $guardPrimary
			$lastLoggedSecondary = $guardSecondary
		EndIf
		Local $isRitualistGuard = ($guardPrimary == $ID_RITUALIST Or $guardSecondary == $ID_RITUALIST)
		If $mode == 'UNKNOWN' And $isRitualistGuard And TimerDiff($modeDecisionStart) > 1500 And Not $seenUfAtLeastOnce Then
			OutcastMark('OH_RION_MODE_RITUALIST_TENTATIVE')
		EndIf
		If IsRecharged($OUTCAST_EVAS) And TimerDiff($lastEvasAt) > 1000 Then
			UseSkillEx($OUTCAST_EVAS, $guard)
			OutcastMark('OH_RION_EVAS_RECAST')
			$lastEvasAt = TimerInit()
			If $mode == 'RITUALIST' And Not $seenUfAtLeastOnce And Not $ritualistRottingDone And IsRecharged($OUTCAST_ROTTING_FLESH) Then
				UseSkillEx($OUTCAST_ROTTING_FLESH, $guard)
				OutcastMark('OH_RION_ROTTING_AFTER_EVAS')
				$ritualistRottingDone = True
			EndIf
		EndIf

		Local $enemySkill = DllStructGetData($guard, 'Skill')
		If $enemySkill <> $lastLoggedEnemySkill Then
			OutcastMark('OH_RION_ENEMY_SKILL_' & $enemySkill)
			$lastLoggedEnemySkill = $enemySkill
		EndIf
		If $mode == 'UNKNOWN' And Not $seenUfAtLeastOnce And OutcastIsRitualistSignatureSkill($enemySkill) Then
			$mode = 'RITUALIST'
			OutcastMark('OH_RION_MODE_RITUALIST_BY_SKILL_' & $enemySkill)
			OutcastMark('OH_RION_MODE_RITUALIST_LOCK')
			Local $guardModelSkill = DllStructGetData($guard, 'ModelID')
			If $guardModelSkill > 0 And $guardModelSkill <> $outcast_rion_model_deathhand And $outcast_rion_model_ritualist <> $guardModelSkill Then
				$outcast_rion_model_ritualist = $guardModelSkill
				OutcastMark('OH_RION_MODEL_LEARN_RITUALIST_' & $guardModelSkill)
			EndIf
			If Not $seenUfAtLeastOnce And Not $ritualistRottingDone And IsRecharged($OUTCAST_ROTTING_FLESH) Then
				UseSkillEx($OUTCAST_ROTTING_FLESH, $guard)
				OutcastMark('OH_RION_ROTTING_CAST')
				$ritualistRottingDone = True
			EndIf
		EndIf
		If $enemySkill == $ID_UNHOLY_FEAST Or $enemySkill == $ID_UNHOLY_FEAST_PVP Then
			If $mode <> 'DEATHHAND' Then OutcastMark('OH_RION_MODE_DEATHHAND')
			If $mode <> 'DEATHHAND' Then OutcastMark('OH_RION_MODE_DEATHHAND_LOCK')
			$mode = 'DEATHHAND'
			$seenUfAtLeastOnce = True
			Local $guardModel = DllStructGetData($guard, 'ModelID')
			If $guardModel > 0 Then
				If $outcast_rion_model_ritualist == $guardModel Then
					$outcast_rion_model_ritualist = 0
					OutcastMark('OH_RION_MODEL_RITUALIST_RESET_CONFLICT_' & $guardModel)
				EndIf
				If $outcast_rion_model_deathhand <> $guardModel Then
					$outcast_rion_model_deathhand = $guardModel
					OutcastMark('OH_RION_MODEL_LEARN_DEATHHAND_' & $guardModel)
				EndIf
			EndIf
			If Not $ufWindowActive Then
				$ufWindowActive = True
				$ufNecrosisDone = False
				OutcastMark('OH_RION_UF_SEEN')
			EndIf

			; Cast Necrosis once per UF window; if not ready at UF start, cast later while UF is still active.
			If Not $ufNecrosisDone Then
				If IsRecharged($OUTCAST_NECROSIS) And TimerDiff($lastNecrosisAt) > 450 Then
					UseSkillEx($OUTCAST_NECROSIS, $guard)
					OutcastMark('OH_RION_NECROSIS_ON_UF')
					$lastNecrosisAt = TimerInit()
					$ufNecrosisDone = True
				ElseIf $lastEnemySkill <> $ID_UNHOLY_FEAST And $lastEnemySkill <> $ID_UNHOLY_FEAST_PVP Then
					OutcastMark('OH_RION_NECROSIS_NOT_READY_ON_UF')
				EndIf
			EndIf
		Else
			If $ufWindowActive Then
				If Not $ufNecrosisDone Then OutcastMark('OH_RION_UF_WINDOW_MISSED_NECROSIS')
				$ufWindowActive = False
				$ufNecrosisDone = False
			EndIf

			; Ritualist fallback signal when profession field is unreliable:
			; repeated hostile spirit presence near Rion guard while no UF has been observed.
			If $mode == 'UNKNOWN' And Not $seenUfAtLeastOnce Then
				Local $spiritNearRion = OutcastGetBlockingSpiritNearRion()
				If $spiritNearRion <> Null Then
					$ritualistSpiritVotes += 1
					If $ritualistSpiritVotes == 1 Then OutcastMark('OH_RION_SPIRIT_SIGNAL_SEEN')
					If $ritualistSpiritVotes >= 3 And TimerDiff($modeDecisionStart) > 3500 Then
						$mode = 'RITUALIST'
						OutcastMark('OH_RION_MODE_RITUALIST_BY_SPIRIT')
						OutcastMark('OH_RION_MODE_RITUALIST_LOCK')
						Local $guardModel = DllStructGetData($guard, 'ModelID')
						If $guardModel > 0 And $guardModel <> $outcast_rion_model_deathhand And $outcast_rion_model_ritualist <> $guardModel Then
							$outcast_rion_model_ritualist = $guardModel
							OutcastMark('OH_RION_MODEL_LEARN_RITUALIST_' & $guardModel)
						EndIf
						If Not $seenUfAtLeastOnce And Not $ritualistRottingDone And IsRecharged($OUTCAST_ROTTING_FLESH) Then
							UseSkillEx($OUTCAST_ROTTING_FLESH, $guard)
							OutcastMark('OH_RION_ROTTING_CAST')
							$ritualistRottingDone = True
						EndIf
					EndIf
				EndIf
			EndIf

			; Fallback classifier if profession lookup did not resolve mode yet.
			If $mode == 'UNKNOWN' And Not $seenUfAtLeastOnce And $isRitualistGuard And TimerDiff($modeDecisionStart) > 10000 Then
				$mode = 'RITUALIST'
				OutcastMark('OH_RION_MODE_RITUALIST')
				OutcastMark('OH_RION_MODE_RITUALIST_LOCK')
				Local $guardModel = DllStructGetData($guard, 'ModelID')
				If $guardModel > 0 And $guardModel <> $outcast_rion_model_deathhand And $outcast_rion_model_ritualist <> $guardModel Then
					$outcast_rion_model_ritualist = $guardModel
					OutcastMark('OH_RION_MODEL_LEARN_RITUALIST_' & $guardModel)
				EndIf
				If Not $seenUfAtLeastOnce And Not $ritualistRottingDone And IsRecharged($OUTCAST_ROTTING_FLESH) Then
					UseSkillEx($OUTCAST_ROTTING_FLESH, $guard)
					OutcastMark('OH_RION_ROTTING_CAST')
					$ritualistRottingDone = True
				EndIf
			EndIf
		EndIf
		$lastEnemySkill = $enemySkill

		If $mode == 'RITUALIST' Then
			; Controlled fallback pressure in Ritualist mode only.
			If Not $seenUfAtLeastOnce And IsRecharged($OUTCAST_NECROSIS) And TimerDiff($lastNecrosisAt) > 900 Then
				UseSkillEx($OUTCAST_NECROSIS, $guard)
				OutcastMark('OH_RION_NECROSIS_RITUALIST')
				$lastNecrosisAt = TimerInit()
			EndIf
			; Do NOT spam Necrosis in Ritualist mode.
			; For Deathhand, Necrosis must only fire on UF windows (handled in the UF branch above).
		EndIf

		RandomSleep(170)
	WEnd

	$guard = GetAgentByID($engagedGuardID)
	If Not OutcastIsAttackableFoe($guard) Then
		; Final safety check: if another valid guard is still present near Rion, do not continue.
		Local $remainingGuard = OutcastGetRionGuardTarget()
		If OutcastIsValidRionGuard($remainingGuard) Then
			Warn('Rion guard still present after target loss, aborting interaction')
			OutcastMark('OH_RION_GUARD_STILL_PRESENT_AFTER_LOSS')
			Return $FAIL
		EndIf
	EndIf
	If OutcastIsAttackableFoe($guard) Then
		Warn('Rion guard still alive, not interacting with Rion yet')
		OutcastMark('OH_RION_GUARD_STILL_ALIVE')
		Return $FAIL
	EndIf
	OutcastMark('OH_RION_GUARD_DEAD_CONFIRMED')

	; Hard requirement: do not talk to Rion until area is truly clear and stable.
	If OutcastEnsureRionAreaClear(30000, 3500) == $FAIL Then
		OutcastMark('OH_RION_AREA_NOT_CLEAR')
		Return $FAIL
	EndIf

	Local $preLogState = -1
	Local $preObjective = GetQuestEncryptedObjectives($OUTCAST_QUEST_ID, $OUTCAST_QUEST_OBJECTIVE_BYTES)
	Local $questBefore = GetQuestByID($OUTCAST_QUEST_ID)
	If $questBefore <> Null Then
		$preLogState = DllStructGetData($questBefore, 'LogState')
		OutcastMark('OH_RION_QUEST_STATE_PRE_LOGSTATE_' & $preLogState)
		If $preObjective <> Null Then OutcastMark('OH_RION_QUEST_OBJECTIVE_PRE_' & StringLeft($preObjective, 16))
	Else
		OutcastMark('OH_RION_QUEST_STATE_PRE_NOT_FOUND')
	EndIf
	If $preLogState <> $ID_QUEST_ACTIVE Then
		Warn('Quest state before Rion interaction is unexpected (LogState=' & $preLogState & '), continuing anyway')
		OutcastMark('OH_RION_QUEST_STATE_UNEXPECTED_CONTINUE')
	EndIf

	Info('Activating Rion interaction')
	Local $maxAttempts = $OUTCAST_RION_INTERACT_ATTEMPTS
	For $i = 1 To $maxAttempts
		; Re-check local safety in case a spirit popped during interaction prep.
		If OutcastEnsureRionAreaClear(12000, 1500) == $FAIL Then
			OutcastMark('OH_RION_AREA_NOT_CLEAR_ATTEMPT_' & $i)
			ContinueLoop
		EndIf

		OutcastMark('OH_RION_INTERACT_ATTEMPT_' & $i)
		Local $rionNpc = OutcastGetRionNPC()
		If $rionNpc == Null Then
			OutcastMark('OH_RION_NPC_NOT_FOUND')
			MoveTo($OUTCAST_RION_X, $OUTCAST_RION_Y, 120, 0)
			RandomSleep(300)
			ContinueLoop
		EndIf

		Local $rionDist = Int(GetDistanceToPoint($rionNpc, $OUTCAST_RION_X, $OUTCAST_RION_Y))
		Local $rionModel = DllStructGetData($rionNpc, 'ModelID')
		OutcastMark('OH_RION_INTERACT_DIST_' & $rionDist)
		OutcastMark('OH_RION_NPC_MODEL_' & $rionModel)
		If $rionModel <> $OUTCAST_RION_MODEL_ID Then
			OutcastMark('OH_RION_WRONG_NPC_MODEL_' & $rionModel)
			RandomSleep(300)
			ContinueLoop
		EndIf
		ChangeTarget($rionNpc)
		GoToNPC($rionNpc)
		Sleep(1000 + GetPing())

		; Ensure we are in reliable interaction range before opening the dialog UI.
		Local $approachTimer = TimerInit()
		Local $playerNpcDist = 99999
		While TimerDiff($approachTimer) < 6000 And IsPlayerAlive()
			$playerNpcDist = Int(GetDistance(GetMyAgent(), $rionNpc))
			If $playerNpcDist <= 170 Then ExitLoop
			MoveTo(DllStructGetData($rionNpc, 'X'), DllStructGetData($rionNpc, 'Y'), 40, 0)
			GoNPC($rionNpc)
			RandomSleep(180)
		WEnd
		OutcastMark('OH_RION_PLAYER_NPC_DIST_' & $playerNpcDist)
		If $playerNpcDist > 220 Then
			OutcastMark('OH_RION_TOO_FAR_FOR_DIALOG')
			ContinueLoop
		EndIf

		Local $eventStartedByMouse = OutcastStartRionEventByPhysicalMouseClick($rionNpc, $preLogState, $preObjective)
		If Not $eventStartedByMouse Then
			OutcastMark('OH_RION_MOUSE_NO_EVENT')
			ContinueLoop
		EndIf
		; Do not block at Rion: proceed to hold spot immediately after click.
		; Wave gate (with OH_WAVE_1_NO_FOES_FAIL) remains the authoritative spawn validation.
		OutcastMark('OH_RION_FAST_PROCEED_AFTER_CLICK')
		OutcastMark('OH_RION_INTERACT_OK')
		Return $SUCCESS
	Next

	Warn('Rion interaction failed after retries')
	OutcastMark('OH_RION_INTERACT_FAIL')
	Return $FAIL
EndFunc


Func OutcastStartRionEventByPhysicalMouseClick($rionNpc, $preLogState, $preObjective)
	If $rionNpc == Null Then Return False

	Info('Rion erreicht. Physischer Maus-Klick-Versuch...')
	Local $rx = DllStructGetData($rionNpc, 'X')
	Local $ry = DllStructGetData($rionNpc, 'Y')
	MoveTo($rx, $ry, 30, 0)

	Local $distTimer = TimerInit()
	While GetDistance(GetMyAgent(), $rionNpc) > $OUTCAST_RION_FINAL_STANDOFF_DIST
		If IsPlayerDead() Then Return False
		If TimerDiff($distTimer) > 8000 Then ExitLoop
		Sleep(100)
	WEnd

	CancelAction()
	Sleep(1500 + GetPing())

	Local $hWnd = WinGetHandle('[CLASS:ArenaNet_Dx_Window_Class]')
	If @error Or $hWnd == '' Then $hWnd = WinGetHandle('[TITLE:Guild Wars]')
	If @error Or $hWnd == '' Then
		OutcastMark('OH_RION_MOUSE_WINDOW_NOT_FOUND')
		Return False
	EndIf
	WinActivate($hWnd)
	WinWaitActive($hWnd, '', 3)

	ChangeTarget($rionNpc)
	Sleep(500 + GetPing())
	ActionInteract()
	Sleep(1500 + GetPing())
	Send('{SPACE}')
	Sleep(1000 + GetPing())

	For $clickTry = 1 To $OUTCAST_RION_MOUSE_CLICK_TRIES
		If Not OutcastClickRionDialogOptionUI($clickTry) Then
			OutcastMark('OH_RION_MOUSE_CLICK_FAIL_' & $clickTry)
			ContinueLoop
		EndIf
		OutcastMark('OH_RION_MOUSE_CLICK_SENT_' & $clickTry)
		If OutcastDetectRionStartSignalFast($preLogState, $preObjective, 3500) Then
			OutcastMark('OH_RION_MOUSE_CLICK_SUCCESS_' & $clickTry)
			If OutcastHasHalcyonUpdateSignal($preLogState, $preObjective) Then
				OutcastMark('OH_RION_MOUSE_QUEST_DELTA_' & $clickTry)
			EndIf
			Return True
		EndIf
	Next

	Return False
EndFunc


Func OutcastDetectRionStartSignalFast($preLogState, $preObjective, $maxWaitMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs And IsPlayerAlive()
		If OutcastHasHalcyonUpdateSignal($preLogState, $preObjective) Then Return True
		RandomSleep(180)
	WEnd
	Return False
EndFunc


Func OutcastClickRionDialogOptionUI($burst)
	Local $hwnd = WinGetHandle('[CLASS:ArenaNet_Dx_Window_Class]')
	If @error Or $hwnd == '' Then $hwnd = WinGetHandle('[TITLE:Guild Wars]')
	If @error Or $hwnd == '' Then Return False

	WinActivate($hwnd)
	WinWaitActive($hwnd, '', 2)

	Local $winPos = WinGetPos($hwnd)
	If @error Or UBound($winPos) < 4 Then Return False

	; Borderless mode: use window bounds as clickable game area.
	Local $clientLeft = $winPos[0]
	Local $clientTop = $winPos[1]
	Local $clientWidth = $winPos[2]
	Local $clientHeight = $winPos[3]
	If $clientWidth < 640 Or $clientHeight < 480 Then Return False

	; Exact user calibration points from Ctrl+Alt+7 markers (borderless 2560x1392), used as ratios.
	Local $xRatios[2] = [0.5100, 0.5170]
	Local $yRatios[2] = [0.5300, 0.5450]
	Local $idx = Mod($burst - 1, UBound($xRatios))
	Local $clickX = Int($clientLeft + ($clientWidth * $xRatios[$idx]))
	Local $clickY = Int($clientTop + ($clientHeight * $yRatios[$idx]))
	MouseMove($clickX, $clickY, 2)
	Sleep(180)
	MouseClick('left', $clickX, $clickY, 1, 8)
	Sleep(220 + GetPing())

	Return True
EndFunc


Func OutcastDetectHalcyonEventStart($maxWaitMs = 30000)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs And IsPlayerAlive()
		Local $foesAtWave = CountFoesInRangeOfCoords($OUTCAST_WAVE_CENTER_X, $OUTCAST_WAVE_CENTER_Y, 1700)
		If $foesAtWave >= 4 Then
			OutcastMark('OH_RION_EVENT_SIGNAL_WAVE_FOES_' & $foesAtWave)
			Return True
		EndIf

		Local $foesNearRion = CountFoesInRangeOfCoords($OUTCAST_RION_X, $OUTCAST_RION_Y, 1700)
		If $foesNearRion >= 4 Then
			OutcastMark('OH_RION_EVENT_SIGNAL_RION_FOES_' & $foesNearRion)
			Return True
		EndIf
		RandomSleep(250)
	WEnd
	OutcastMark('OH_RION_EVENT_SIGNAL_NONE')
	Return False
EndFunc


Func OutcastIsValidRionGuard($agent)
	If $agent == Null Then Return False
	If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then Return False
	If GetIsDead($agent) Then Return False
	If DllStructGetData($agent, 'HealthPercent') <= 0 Then Return False
	Local $model = DllStructGetData($agent, 'ModelID')
	If ($MAP_SPIRIT_TYPES[DllStructGetData($agent, 'TypeMap')] <> Null) Or ($model == $OUTCAST_DISPLACEMENT_MODEL_ID) Then Return False
	If GetDistanceToPoint($agent, $OUTCAST_RION_X, $OUTCAST_RION_Y) > 1400 Then Return False
	Return True
EndFunc


Func OutcastIsAttackableFoe($agent)
	If $agent == Null Then Return False
	If DllStructGetData($agent, 'ID') == 0 Then Return False
	If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then Return False
	If GetIsDead($agent) Then Return False
	If DllStructGetData($agent, 'HealthPercent') <= 0 Then Return False
	Return True
EndFunc


Func OutcastIsRitualistSignatureSkill($skillId)
	; Deterministic Ritualist signal seen in logs: Vengeful Was Khanhei.
	Return $skillId == $ID_VENGEFUL_WAS_KHANHEI
EndFunc


Func OutcastGetRionGuardTarget()
	Local $foes = GetFoesInRangeOfCoords($OUTCAST_RION_X, $OUTCAST_RION_Y, 1400)
	If UBound($foes) == 0 Then Return Null

	Local $candidate = Null
	Local $candidateDist = 99999999
	For $foe In $foes
		If Not OutcastIsValidRionGuard($foe) Then ContinueLoop
		Local $dist = GetDistanceToPoint($foe, $OUTCAST_RION_X, $OUTCAST_RION_Y)
		If $dist < $candidateDist Then
			$candidate = $foe
			$candidateDist = $dist
		EndIf
	Next
	Return $candidate
EndFunc


Func OutcastClearRionBlockingSpirits()
	Local $timer = TimerInit()
	While TimerDiff($timer) < 25000 And IsPlayerAlive()
		Local $spirit = OutcastGetBlockingSpiritNearRion()
		If $spirit == Null Then
			OutcastMark('OH_RION_SPIRIT_CLEAR_DONE')
			Return $SUCCESS
		EndIf

		OutcastMark('OH_RION_SPIRIT_BLOCKING')
		ChangeTarget($spirit)
		If IsRecharged($OUTCAST_EVAS) Then
			UseSkillEx($OUTCAST_EVAS, $spirit)
			OutcastMark('OH_RION_EVAS_SPIRIT')
		EndIf
		RandomSleep(250)
	WEnd

	Warn('Blocking spirit near Rion was not cleared in time')
	Return $FAIL
EndFunc


Func OutcastGetBlockingSpiritNearRion()
	Local $me = GetMyAgent()
	Local $myTeam = DllStructGetData($me, 'Team')
	Local $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	Local $best = Null
	Local $bestDist = 99999999
	For $agent In $agents
		; Spirits are filtered out by generic NPC helpers, so inspect raw NPC agents here.
		If $MAP_SPIRIT_TYPES[DllStructGetData($agent, 'TypeMap')] == Null Then ContinueLoop
		If DllStructGetData($agent, 'Team') == $myTeam Then ContinueLoop
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE And DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_SPIRIT Then ContinueLoop
		If GetIsDead($agent) Or DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		Local $dist = GetDistanceToPoint($agent, $OUTCAST_RION_X, $OUTCAST_RION_Y)
		If $dist > 900 Then ContinueLoop
		If $dist < $bestDist Then
			$best = $agent
			$bestDist = $dist
		EndIf
	Next
	Return $best
EndFunc


Func OutcastHasHalcyonEventSignal()
	Local $foesAtWave = CountFoesInRangeOfCoords($OUTCAST_WAVE_CENTER_X, $OUTCAST_WAVE_CENTER_Y, 1700)
	Return $foesAtWave >= 4
EndFunc


Func OutcastHasHalcyonUpdateSignal($preLogState, $preObjective)
	If OutcastHasHalcyonEventSignal() Then Return True

	Local $foesNearRion = CountFoesInRangeOfCoords($OUTCAST_RION_X, $OUTCAST_RION_Y, 1700)
	If $foesNearRion >= 4 Then
		OutcastMark('OH_RION_EVENT_SIGNAL_RION_FOES_' & $foesNearRion)
		Return True
	EndIf

	Local $questAfter = GetQuestByID($OUTCAST_QUEST_ID)
	If $questAfter <> Null Then
		Local $postLogState = DllStructGetData($questAfter, 'LogState')
		If $preLogState <> -1 And $postLogState > $preLogState Then
			OutcastMark('OH_RION_LOGSTATE_DELTA_SIGNAL')
			Return True
		EndIf
	EndIf

	Local $postObjective = GetQuestEncryptedObjectives($OUTCAST_QUEST_ID, $OUTCAST_QUEST_OBJECTIVE_BYTES)
	If $preObjective <> Null And $postObjective <> Null And $postObjective <> $preObjective Then
		OutcastMark('OH_RION_OBJECTIVE_DELTA_SIGNAL')
		Return True
	EndIf

	Return False
EndFunc


Func OutcastClearRionNearbyFoes()
	Local $timer = TimerInit()
	While TimerDiff($timer) < 30000 And IsPlayerAlive()
		If OutcastHasHalcyonEventSignal() Then
			OutcastMark('OH_RION_NEARBY_CLEAR_DONE')
			Return $SUCCESS
		EndIf

		Local $foe = GetNearestEnemyToCoords($OUTCAST_RION_X, $OUTCAST_RION_Y)
		If $foe == Null Or GetDistanceToPoint($foe, $OUTCAST_RION_X, $OUTCAST_RION_Y) > 900 Then
			OutcastMark('OH_RION_NEARBY_CLEAR_DONE')
			Return $SUCCESS
		EndIf

		If Not OutcastIsAttackableFoe($foe) Then
			RandomSleep(150)
			ContinueLoop
		EndIf

		OutcastMark('OH_RION_NEARBY_CLEAR_TARGET')
		ChangeTarget($foe)
		Local $foeModel = DllStructGetData($foe, 'ModelID')
		Local $isSpiritThreat = ($MAP_SPIRIT_TYPES[DllStructGetData($foe, 'TypeMap')] <> Null) Or ($foeModel == $OUTCAST_DISPLACEMENT_MODEL_ID)
		If IsRecharged($OUTCAST_EVAS) Then
			UseSkillEx($OUTCAST_EVAS, $foe)
			OutcastMark('OH_RION_NEARBY_CLEAR_EVAS')
		EndIf
		If Not $isSpiritThreat And IsRecharged($OUTCAST_NECROSIS) Then
			UseSkillEx($OUTCAST_NECROSIS, $foe)
			OutcastMark('OH_RION_NEARBY_CLEAR_NECROSIS')
		EndIf
		If Not $isSpiritThreat Then Attack($foe)
		RandomSleep(250)
	WEnd

	Return $FAIL
EndFunc


Func OutcastEnsureRionAreaClear($timeoutMs = 30000, $stableMs = 2000)
	Local $timer = TimerInit()
	Local $clearSince = 0
	While TimerDiff($timer) < $timeoutMs And IsPlayerAlive()
		Local $threat = OutcastGetNearestRionThreat()
		If $threat == Null Then
			If $clearSince == 0 Then
				$clearSince = TimerInit()
				OutcastMark('OH_RION_AREA_CLEAR_PENDING')
			EndIf
			If TimerDiff($clearSince) >= $stableMs Then
				OutcastMark('OH_RION_AREA_CLEAR_READY')
				Return $SUCCESS
			EndIf
			RandomSleep(180)
			ContinueLoop
		EndIf

		$clearSince = 0
		OutcastMark('OH_RION_THREAT_PRESENT_' & DllStructGetData($threat, 'ModelID'))
		ChangeTarget($threat)
		Local $threatModel = DllStructGetData($threat, 'ModelID')
		Local $isSpiritThreat = ($MAP_SPIRIT_TYPES[DllStructGetData($threat, 'TypeMap')] <> Null) Or ($threatModel == $OUTCAST_DISPLACEMENT_MODEL_ID)
		If $isSpiritThreat Then
			If IsRecharged($OUTCAST_EVAS) Then
				UseSkillEx($OUTCAST_EVAS, $threat)
				OutcastMark('OH_RION_THREAT_EVAS')
			EndIf
		Else
			If IsRecharged($OUTCAST_EVAS) Then
				UseSkillEx($OUTCAST_EVAS, $threat)
				OutcastMark('OH_RION_THREAT_EVAS')
			ElseIf IsRecharged($OUTCAST_NECROSIS) Then
				UseSkillEx($OUTCAST_NECROSIS, $threat)
				OutcastMark('OH_RION_THREAT_NECROSIS')
			EndIf
			Attack($threat)
		EndIf
		RandomSleep(220)
	WEnd
	Return $FAIL
EndFunc


Func OutcastGetNearestRionThreat()
	Local $me = GetMyAgent()
	Local $myTeam = DllStructGetData($me, 'Team')
	Local $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	Local $best = Null
	Local $bestDist = 99999999
	For $agent In $agents
		If DllStructGetData($agent, 'ID') == DllStructGetData($me, 'ID') Then ContinueLoop
		If GetIsDead($agent) Or DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		Local $dist = GetDistanceToPoint($agent, $OUTCAST_RION_X, $OUTCAST_RION_Y)
		If $dist > 900 Then ContinueLoop

		Local $allegiance = DllStructGetData($agent, 'Allegiance')
		Local $model = DllStructGetData($agent, 'ModelID')
		Local $isSpirit = ($MAP_SPIRIT_TYPES[DllStructGetData($agent, 'TypeMap')] <> Null)
		Local $isKnownSpiritModel = ($model == $OUTCAST_DISPLACEMENT_MODEL_ID)
		Local $hostileSpirit = ($isSpirit Or $isKnownSpiritModel) And DllStructGetData($agent, 'Team') <> $myTeam
		If $allegiance <> $ID_ALLEGIANCE_FOE And Not $hostileSpirit Then ContinueLoop

		If $dist < $bestDist Then
			$best = $agent
			$bestDist = $dist
		EndIf
	Next
	Return $best
EndFunc


Func OutcastGetRionNPC()
	Local $rion = GetAgentByModelID($OUTCAST_RION_MODEL_ID)
	If $rion <> Null And IsNPCAgentType($rion) Then
		If GetDistanceToPoint($rion, $OUTCAST_RION_X, $OUTCAST_RION_Y) <= 900 Then Return $rion
	EndIf

	Local $npcs = GetNPCsInRangeOfCoords($OUTCAST_RION_X, $OUTCAST_RION_Y, Null, 900)
	For $npc In $npcs
		If Not IsNPCAgentType($npc) Then ContinueLoop
		If DllStructGetData($npc, 'ModelID') == $OUTCAST_RION_MODEL_ID Then Return $npc
	Next

	Return Null
EndFunc


Func OutcastMoveToHoldSpot()
	Info('Moving to hold spot')
	Local $holdPath[3][2] = [[10351, -6043], [9666, -6225], [$OUTCAST_HOLD_X, $OUTCAST_HOLD_Y]]
	If OutcastFollowPath($holdPath, 90000) == $FAIL Then Return $FAIL
	Return GetDistanceToPoint(GetMyAgent(), $OUTCAST_HOLD_X, $OUTCAST_HOLD_Y) <= 260 ? $SUCCESS : $FAIL
EndFunc


Func OutcastWaitForWaveStack($waveIndex)
	Local $minimumWait = 0
	If $waveIndex == 2 Then
		$minimumWait = 52000
	ElseIf $waveIndex >= 3 Then
		$minimumWait = 65000
	EndIf
	; Wave 1 can legitimately present as a stable 3-foe micro-pack near ship center.
	; Requiring 4+ keeps the gate waiting forever and can abort before first choreography.
	Local $minFoesForStackEval = ($waveIndex == 1) ? 3 : 4
	Local $packedSpreadLimit = ($waveIndex == 1) ? 500 : 540
	Local $packedTicksRequired = ($waveIndex == 1) ? 5 : 4
	Local $stableSpreadLimit = ($waveIndex == 1) ? 620 : 650
	Local $maximumWait = ($waveIndex == 1) ? 230000 : 170000
	Local $timer = TimerInit()
	Local $heartbeat = TimerInit()
	Local $stableTicks = 0
	Local $packedTicks = 0
	Local $settledTicks = 0
	Local $maxFoesSeen = 0
	Local $prevCount = -1
	Local $prevCx = 0
	Local $prevCy = 0
	Local $prevSpread = 999999

	While TimerDiff($timer) < $maximumWait And IsPlayerAlive()
		Local $foeAgentsWave = GetFoesInRangeOfCoords($OUTCAST_WAVE_CENTER_X, $OUTCAST_WAVE_CENTER_Y, 1700)
		Local $foeAgentsHold = GetFoesInRangeOfCoords($OUTCAST_HOLD_X, $OUTCAST_HOLD_Y, 1700)
		Local $foeAgentsShip = GetFoesInRangeOfCoords($OUTCAST_SCAN_SHIP_X, $OUTCAST_SCAN_SHIP_Y, 1700)

		Local $foeAgents = $foeAgentsWave
		If UBound($foeAgentsHold) > UBound($foeAgents) Then $foeAgents = $foeAgentsHold
		If UBound($foeAgentsShip) > UBound($foeAgents) Then $foeAgents = $foeAgentsShip
		Local $foes = UBound($foeAgents)
		If $foes > $maxFoesSeen Then $maxFoesSeen = $foes

		If TimerDiff($timer) < $minimumWait Then
			; If next wave is already materially present, do not sit in a blind min-wait gate.
			If $waveIndex >= 2 And $foes >= 5 Then
				OutcastMark('OH_WAVE_' & $waveIndex & '_MINWAIT_BYPASS_FOES_' & $foes)
				$minimumWait = 0
			Else
			If TimerDiff($heartbeat) >= 10000 Then
				OutcastMark('OH_WAVE_' & $waveIndex & '_MINWAIT_' & Int($minimumWait - TimerDiff($timer)))
				$heartbeat = TimerInit()
			EndIf
			RandomSleep(1400)
			ContinueLoop
			EndIf
		EndIf

		If $foes < $minFoesForStackEval Then
			If $waveIndex == 1 And $maxFoesSeen == 0 And TimerDiff($timer) > 90000 Then
				OutcastMark('OH_WAVE_1_NO_FOES_FAIL')
				Return $FAIL
			EndIf
			If TimerDiff($heartbeat) >= 10000 Then
				OutcastMark('OH_WAVE_' & $waveIndex & '_WAIT_HEARTBEAT')
				OutcastMark('OH_WAVE_' & $waveIndex & '_FOES_MAX_' & $foes)
				$heartbeat = TimerInit()
			EndIf
			RandomSleep(1400)
			ContinueLoop
		EndIf

		Local $sampleCount = (UBound($foeAgents) < 18) ? UBound($foeAgents) : 18
		Local $sumX = 0
		Local $sumY = 0
		For $k = 0 To $sampleCount - 1
			$sumX += DllStructGetData($foeAgents[$k], 'X')
			$sumY += DllStructGetData($foeAgents[$k], 'Y')
		Next
		Local $cx = Int($sumX / $sampleCount)
		Local $cy = Int($sumY / $sampleCount)

		Local $sumSpread = 0
		For $k = 0 To $sampleCount - 1
			Local $ax = DllStructGetData($foeAgents[$k], 'X')
			Local $ay = DllStructGetData($foeAgents[$k], 'Y')
			$sumSpread += Sqrt((($ax - $cx) * ($ax - $cx)) + (($ay - $cy) * ($ay - $cy)))
		Next
		Local $avgSpread = Int($sumSpread / $sampleCount)

		If TimerDiff($heartbeat) >= 10000 Then
			OutcastMark('OH_WAVE_' & $waveIndex & '_WAIT_HEARTBEAT')
			OutcastMark('OH_WAVE_' & $waveIndex & '_FOES_MAX_' & $foes)
			OutcastMark('OH_WAVE_' & $waveIndex & '_SPREAD_' & $avgSpread)
			$heartbeat = TimerInit()
		EndIf

		If Abs($foes - $prevCount) <= 2 And Abs($cx - $prevCx) < 35 And Abs($cy - $prevCy) < 35 And Abs($avgSpread - $prevSpread) < 45 Then
			$stableTicks += 1
		Else
			$stableTicks = 0
		EndIf

		If $foes >= 8 And $avgSpread <= $packedSpreadLimit Then
			$packedTicks += 1
		Else
			$packedTicks = 0
		EndIf

		Local $stackCandidate = ($stableTicks >= 5 And $avgSpread <= $stableSpreadLimit) Or ($packedTicks >= $packedTicksRequired)
		If $stackCandidate And Abs($foes - $prevCount) <= 1 And Abs($cx - $prevCx) < 18 And Abs($cy - $prevCy) < 18 And Abs($avgSpread - $prevSpread) < 20 Then
			$settledTicks += 1
		Else
			$settledTicks = 0
		EndIf

		$prevCount = $foes
		$prevCx = $cx
		$prevCy = $cy
		$prevSpread = $avgSpread

		If $settledTicks >= 3 Then
			OutcastMark('OH_WAVE_' & $waveIndex & '_STACKED_SETTLED')
			Return $SUCCESS
		EndIf
		RandomSleep(1500)
	WEnd

	If Not IsPlayerAlive() Then
		Warn('Wave stack wait aborted: player died')
		OutcastMark('OH_WAVE_' & $waveIndex & '_WAIT_ABORT_DEAD')
		OutcastMarkFailureContext('OH_FAIL_CTX_W' & $waveIndex & '_WAIT_DEAD')
	Else
		If $waveIndex == 1 And $maxFoesSeen >= 3 Then
			Warn('Wave 1 stack wait timeout, but stable micro-pack seen; proceeding with degraded start')
			OutcastMark('OH_WAVE_1_STACK_TIMEOUT_PROCEED_F_' & $maxFoesSeen)
			Return $SUCCESS
		EndIf
		Warn('Wave stack wait timeout without settled stack, aborting run for safety')
		OutcastMark('OH_WAVE_' & $waveIndex & '_STACK_TIMEOUT_FAIL')
		OutcastMarkFailureContext('OH_FAIL_CTX_W' & $waveIndex & '_STACK_TIMEOUT')
	EndIf
	Return $FAIL
EndFunc


Func OutcastExecuteWaveChoreography($waveIndex)
	For $attempt = 1 To $OUTCAST_MAX_CHOREO_ATTEMPTS
		OutcastMark('OH_WAVE_' & $waveIndex & '_CHOREO_ATTEMPT_' & $attempt)
		If $attempt == 1 Then
			OutcastCastSpiritCore()
		Else
			OutcastMark('OH_SPIRITS_CAST_SKIP_RETRY_ATTEMPT_' & $attempt)
		EndIf
		If OutcastRottingEscapeCycle() == $FAIL Then
			OutcastMark('OH_ROTTING_RETRY_1')
			Sleep(900)
			If OutcastRottingEscapeCycle() == $FAIL Then
				OutcastMark('OH_WARN_WAVE_' & $waveIndex & '_ROTTING_OPEN_RETRY_ATTEMPT')
				OutcastMarkFailureContext('OH_WARN_CTX_W' & $waveIndex & '_RF1_ATTEMPT_' & $attempt)
				; Transient opener miss: retry full choreography attempt instead of killing the run.
				ContinueLoop
			EndIf
		EndIf

		Local $primary = OutcastGetNearestPreferredRfFoe($OUTCAST_HOLD_X, $OUTCAST_HOLD_Y, 2200)
		If $primary == Null Then $primary = OutcastGetNearestPreferredRfFoe($OUTCAST_WAVE_CENTER_X, $OUTCAST_WAVE_CENTER_Y, 2200)
		If $primary == Null Then
			OutcastMark('OH_WARN_WAVE_' & $waveIndex & '_PRIMARY_NONE_RETRY_ATTEMPT')
			OutcastMarkFailureContext('OH_WARN_CTX_W' & $waveIndex & '_PRIMARY_NONE_ATTEMPT_' & $attempt)
			RandomSleep(600)
			ContinueLoop
		EndIf

		Local $primaryID = DllStructGetData($primary, 'ID')
		Local $lastHp = DllStructGetData($primary, 'HealthPercent')
		Local $initialHp = $lastHp
		Local $minHpSeen = $lastHp
		Local $noDropAnchor = $lastHp
		Local $noDropTimer = TimerInit()
		Local $didSecondLacerate = False
		Local $didSecondRotting = False
		Local $secondRottingArmTimer = TimerInit()
		Local $hugRequested = False
		Local $choreoTimer = TimerInit()
		Local $heartbeat = TimerInit()

		OutcastMark('OH_GENERAL_PRIMARY_MODEL_' & DllStructGetData($primary, 'ModelID'))

		While TimerDiff($choreoTimer) < $OUTCAST_GENERAL_CHOREO_MAX_MS And IsPlayerAlive()
			$primary = GetAgentByID($primaryID)
			If $primary == Null Or Not OutcastIsValidRfTarget($primary) Then
				$primary = OutcastGetNearestPreferredRfFoe($OUTCAST_HOLD_X, $OUTCAST_HOLD_Y, 2200)
				If $primary == Null Then $primary = OutcastGetNearestPreferredRfFoe($OUTCAST_WAVE_CENTER_X, $OUTCAST_WAVE_CENTER_Y, 2200)
				If $primary == Null Then
					OutcastMark('OH_GENERAL_PRIMARY_REACQUIRE_NONE')
					RandomSleep(250)
					ContinueLoop
				EndIf
				$primaryID = DllStructGetData($primary, 'ID')
				OutcastMark('OH_GENERAL_PRIMARY_REACQUIRE_MODEL_' & DllStructGetData($primary, 'ModelID'))
				$lastHp = DllStructGetData($primary, 'HealthPercent')
				$initialHp = $lastHp
				$minHpSeen = $lastHp
				$noDropAnchor = $lastHp
				$noDropTimer = TimerInit()
			EndIf

			Local $hp = DllStructGetData($primary, 'HealthPercent')
			If OutcastShouldTriggerHugNow($primary) Then
				$hugRequested = True
				OutcastMark('OH_GENERAL_HUG_TRIGGER_HP_' & Int($hp * 100))
				ExitLoop
			EndIf

			If $hp <= ($noDropAnchor - 0.01) Then
				$noDropAnchor = $hp
				$noDropTimer = TimerInit()
			EndIf
			If $hp < $minHpSeen Then $minHpSeen = $hp

			If Not $didSecondLacerate And $hp <= 0.82 And $hp >= 0.72 And IsRecharged($OUTCAST_LACERATE) Then
				OutcastMark('OH_LACERATE_SECOND_CAST')
				UseSkillEx($OUTCAST_LACERATE)
				$didSecondLacerate = True
				Sleep(250)
			EndIf

			; Deterministic second RF+EE: trigger once in deeper red health, not too early.
			If $didSecondRotting And $hp >= 0.72 Then
				$didSecondRotting = False
				$secondRottingArmTimer = TimerInit()
				OutcastMark('OH_GENERAL_RF_RECAST_REARM_HP_' & Int($hp * 100))
			EndIf
			If Not $didSecondRotting And $hp <= 0.60 And TimerDiff($secondRottingArmTimer) >= 2500 And IsRecharged($OUTCAST_ROTTING_FLESH) Then
				OutcastMark('OH_GENERAL_RF_RECAST_HP_' & Int($hp * 100))
				If OutcastRottingEscapeCycle() == $FAIL Then
					OutcastMark('OH_GENERAL_RF_RECAST_MISS')
				Else
					$didSecondRotting = True
				EndIf
			EndIf

			If TimerDiff($noDropTimer) >= $OUTCAST_GENERAL_NO_DROP_RESTART_WINDOW_MS Then
				; On no-drop starts/rebound stalls, keep pressure immediately (RF/EE loop) instead of waiting 60s.
				Local $dropFromStart = $initialHp - $minHpSeen
				Local $isEarlyNoProgress = ($minHpSeen >= 0.90 And $dropFromStart < 0.08)
				Local $isReboundStall = ($hp >= ($minHpSeen + 0.08) And $hp > 0.15)
				If $isEarlyNoProgress Or $isReboundStall Then
					OutcastMark('OH_GENERAL_NO_DROP_PRESSURE_START_HP_' & Int($hp * 100))
					If OutcastRunNoDropPressureLoop($waveIndex, $primaryID, $minHpSeen, $noDropAnchor, $noDropTimer, $hugRequested) == $FAIL Then
						OutcastMark('OH_FAIL_WAVE_' & $waveIndex & '_NO_DROP_PRESSURE_LOOP')
						OutcastMarkFailureContext('OH_FAIL_CTX_W' & $waveIndex & '_NO_DROP_PRESSURE_LOOP')
						Return $FAIL
					EndIf
					If $hugRequested Then ExitLoop
					ContinueLoop
				Else
					OutcastMark('OH_GENERAL_NO_DROP_SKIP_PROGRESS_HP_' & Int($hp * 100))
					$noDropAnchor = $hp
					$noDropTimer = TimerInit()
				EndIf
			EndIf

			$lastHp = $hp

			If TimerDiff($heartbeat) >= 9000 Then
				OutcastMark('OH_GENERAL_HEARTBEAT_HP_' & Int($hp * 100))
				$heartbeat = TimerInit()
			EndIf

			RandomSleep(240)
		WEnd

		If Not IsPlayerAlive() Then
			OutcastMark('OH_FAIL_WAVE_' & $waveIndex & '_DEAD_DURING_GENERAL')
			OutcastMarkFailureContext('OH_FAIL_CTX_W' & $waveIndex & '_DEAD_DURING_GENERAL')
			Return $FAIL
		EndIf

		If Not $hugRequested Then OutcastMark('OH_GENERAL_TIMEOUT_BEFORE_HUG')

		Local $foesBeforeHug = OutcastCountActiveWaveFoes()
		OutcastMark('OH_WAVE_' & $waveIndex & '_FOES_BEFORE_HUG_' & $foesBeforeHug)
		If $hugRequested Then
			; Hug was already triggered by HP in the choreo loop: execute movement immediately,
			; do not re-validate enemy HP here or we can miss the loot window.
			If OutcastHugShipAtLowEnemyHealth(4000, True) == $FAIL Then OutcastMark('OH_HUG_TRIGGER_TIMEOUT')
		EndIf
		If Not IsPlayerAlive() Then
			OutcastMark('OH_FAIL_WAVE_' & $waveIndex & '_DEAD_POST_HUG')
			OutcastMarkFailureContext('OH_FAIL_CTX_W' & $waveIndex & '_DEAD_POST_HUG')
			Return $FAIL
		EndIf

		Local $cleanupTimer = TimerInit()
		Local $cleanupHeartbeat = TimerInit()
		While TimerDiff($cleanupTimer) < 45000 And IsPlayerAlive()
			Local $foesNow = OutcastCountActiveWaveFoes()
			If $foesNow <= 2 Then ExitLoop

			If IsRecharged($OUTCAST_ROTTING_FLESH) Then
				OutcastMark('OH_WAVE_' & $waveIndex & '_CLEANUP_RF_PRESSURE')
				If OutcastRottingEscapeCycle() == $FAIL Then OutcastMark('OH_WAVE_' & $waveIndex & '_CLEANUP_RF_PRESSURE_MISS')
			EndIf

			If TimerDiff($cleanupHeartbeat) >= 8000 Then
				OutcastMark('OH_WAVE_' & $waveIndex & '_CLEANUP_FOES_' & $foesNow)
				$cleanupHeartbeat = TimerInit()
			EndIf
			RandomSleep(900)
		WEnd
		Local $foesLeft = OutcastCountActiveWaveFoes()
		If $foesLeft > 2 Then OutcastMark('OH_WAVE_' & $waveIndex & '_CLEANUP_TIMEOUT_FOES_' & $foesLeft)

		If Not OutcastHasHalcyonQuestSucceeded() Then
			If OutcastMoveTo($OUTCAST_HOLD_X, $OUTCAST_HOLD_Y, 35000) == $FAIL Then
				OutcastMark('OH_WARN_WAVE_' & $waveIndex & '_RETURN_HOLD_MOVE_RETRY_ATTEMPT')
				OutcastMarkFailureContext('OH_WARN_CTX_W' & $waveIndex & '_RETURN_HOLD_ATTEMPT_' & $attempt)
				ContinueLoop
			EndIf
		EndIf
		If Not IsPlayerAlive() Then
			OutcastMark('OH_FAIL_WAVE_' & $waveIndex & '_DEAD_FINAL')
			OutcastMarkFailureContext('OH_FAIL_CTX_W' & $waveIndex & '_DEAD_FINAL')
			Return $FAIL
		EndIf
		Return $SUCCESS
	Next

	OutcastMark('OH_FAIL_WAVE_' & $waveIndex & '_CHOREO_ATTEMPTS_EXHAUSTED')
	OutcastMarkFailureContext('OH_FAIL_CTX_W' & $waveIndex & '_CHOREO_ATTEMPTS')
	Return $FAIL
EndFunc


Func OutcastAnySpiritCoreRecharged()
	Return IsRecharged($OUTCAST_LACERATE) Or IsRecharged($OUTCAST_TOXICITY) Or IsRecharged($OUTCAST_EDGE_OF_EXTINCTION)
EndFunc


Func OutcastRunNoDropPressureLoop($waveIndex, ByRef $primaryID, ByRef $minHpSeen, ByRef $noDropAnchor, ByRef $noDropTimer, ByRef $hugRequested)
	OutcastMark('OH_GENERAL_NO_DROP_PRESSURE_LOOP_BEGIN')
	Local $energyHeartbeat = TimerInit()

	While IsPlayerAlive()
		Local $primary = GetAgentByID($primaryID)
		If $primary == Null Or Not OutcastIsValidRfTarget($primary) Then
			$primary = OutcastGetNearestPreferredRfFoe($OUTCAST_HOLD_X, $OUTCAST_HOLD_Y, 2200)
			If $primary == Null Then $primary = OutcastGetNearestPreferredRfFoe($OUTCAST_WAVE_CENTER_X, $OUTCAST_WAVE_CENTER_Y, 2200)
			If $primary == Null Then
				OutcastMark('OH_GENERAL_NO_DROP_PRESSURE_TARGET_NONE_WAIT')
				RandomSleep(260)
				ContinueLoop
			EndIf
			$primaryID = DllStructGetData($primary, 'ID')
			OutcastMark('OH_GENERAL_NO_DROP_PRESSURE_TARGET_REACQUIRE_MODEL_' & DllStructGetData($primary, 'ModelID'))
		EndIf

		Local $hp = DllStructGetData($primary, 'HealthPercent')
		If $hp < $minHpSeen Then $minHpSeen = $hp
		If OutcastShouldTriggerHugNow($primary) Then
			$hugRequested = True
			OutcastMark('OH_GENERAL_HUG_TRIGGER_HP_' & Int($hp * 100))
			OutcastMark('OH_GENERAL_NO_DROP_PRESSURE_LOOP_HUG_BREAK')
			$noDropAnchor = $hp
			$noDropTimer = TimerInit()
			Return $SUCCESS
		EndIf

		If OutcastAnySpiritCoreRecharged() Then
			OutcastMark('OH_GENERAL_NO_DROP_PRESSURE_RECAST_READY_SPIRITS')
			OutcastRecastReadySpiritCore()
		EndIf

		While GetEnergy() < 25 And IsPlayerAlive()
			If TimerDiff($energyHeartbeat) >= 2500 Then
				OutcastMark('OH_GENERAL_NO_DROP_PRESSURE_WAIT_EN_' & Int(GetEnergy()))
				$energyHeartbeat = TimerInit()
			EndIf

			$primary = GetAgentByID($primaryID)
			If $primary <> Null And OutcastIsValidRfTarget($primary) Then
				$hp = DllStructGetData($primary, 'HealthPercent')
				If $hp < $minHpSeen Then $minHpSeen = $hp
				If OutcastShouldTriggerHugNow($primary) Then
					$hugRequested = True
					OutcastMark('OH_GENERAL_HUG_TRIGGER_HP_' & Int($hp * 100))
					OutcastMark('OH_GENERAL_NO_DROP_PRESSURE_LOOP_HUG_BREAK')
					$noDropAnchor = $hp
					$noDropTimer = TimerInit()
					Return $SUCCESS
				EndIf
			EndIf

			RandomSleep(220)
		WEnd
		If Not IsPlayerAlive() Then Return $FAIL

		OutcastMark('OH_GENERAL_NO_DROP_PRESSURE_RFEE_EN_' & Int(GetEnergy()))
		If OutcastRottingEscapeCycle() == $FAIL Then
			OutcastMark('OH_GENERAL_NO_DROP_PRESSURE_RFEE_MISS')
		EndIf

		RandomSleep(700)
		$primary = GetAgentByID($primaryID)
		If $primary == Null Or Not OutcastIsValidRfTarget($primary) Then
			OutcastMark('OH_GENERAL_NO_DROP_PRESSURE_PROGRESS_TARGET_LOST')
			$noDropTimer = TimerInit()
			Return $SUCCESS
		EndIf

		$hp = DllStructGetData($primary, 'HealthPercent')
		If $hp < $minHpSeen Then $minHpSeen = $hp
		If $hp <= ($noDropAnchor - 0.01) Then
			OutcastMark('OH_GENERAL_NO_DROP_PRESSURE_PROGRESS_HP_' & Int($hp * 100))
			$noDropAnchor = $hp
			$noDropTimer = TimerInit()
			Return $SUCCESS
		EndIf

		OutcastMark('OH_GENERAL_NO_DROP_PRESSURE_RETRY_HP_' & Int($hp * 100))
	WEnd

	Return $FAIL
EndFunc


Func OutcastCountActiveWaveFoes()
	; Robust wave-state count: use the maximum around wave center, hold spot and current player position.
	Local $foesWave = CountFoesInRangeOfCoords($OUTCAST_WAVE_CENTER_X, $OUTCAST_WAVE_CENTER_Y, 1800)
	Local $foesHold = CountFoesInRangeOfCoords($OUTCAST_HOLD_X, $OUTCAST_HOLD_Y, 1800)
	Local $foesPlayer = 0

	Local $me = GetMyAgent()
	If $me <> Null Then
		Local $mx = DllStructGetData($me, 'X')
		Local $my = DllStructGetData($me, 'Y')
		$foesPlayer = CountFoesInRangeOfCoords($mx, $my, 1800)
	EndIf

	Local $maxFoes = $foesWave
	If $foesHold > $maxFoes Then $maxFoes = $foesHold
	If $foesPlayer > $maxFoes Then $maxFoes = $foesPlayer
	Return $maxFoes
EndFunc


Func OutcastGetNearestNonSpiritFoe($centerX, $centerY, $range = 1700)
	Local $foes = GetFoesInRangeOfCoords($centerX, $centerY, $range)
	If UBound($foes) == 0 Then Return Null

	Local $best = Null
	Local $bestDist = 99999999
	For $foe In $foes
		If Not OutcastIsAttackableFoe($foe) Then ContinueLoop
		If OutcastIsSpiritThreat($foe) Then ContinueLoop

		Local $dist = GetDistanceToPoint($foe, $centerX, $centerY)
		If $dist < $bestDist Then
			$best = $foe
			$bestDist = $dist
		EndIf
	Next

	Return $best
EndFunc


Func OutcastGetNearestPreferredRfFoe($centerX, $centerY, $range = 1700)
	; Spirit spot targeting: always use the directly nearest valid non-spirit foe.
	Return OutcastGetNearestNonSpiritFoe($centerX, $centerY, $range)
EndFunc


Func OutcastIsSpiritThreat($agent)
	If $agent == Null Then Return False
	Local $model = DllStructGetData($agent, 'ModelID')
	; Keep this strict and minimal for RF targeting: only true spirit allegiance or known displacement model.
	Return (DllStructGetData($agent, 'Allegiance') == $ID_ALLEGIANCE_SPIRIT) Or ($model == $OUTCAST_DISPLACEMENT_MODEL_ID)
EndFunc


Func OutcastIsValidRfTarget($agent)
	If Not OutcastIsAttackableFoe($agent) Then Return False
	If OutcastIsSpiritThreat($agent) Then Return False
	Return True
EndFunc


Func OutcastIsRitualistOutcast($agent)
	If $agent == Null Then Return False
	Local $model = DllStructGetData($agent, 'ModelID')
	If $outcast_rion_model_ritualist <> 0 And $model == $outcast_rion_model_ritualist Then Return True

	Local $primary = DllStructGetData($agent, 'Primary')
	Local $secondary = DllStructGetData($agent, 'Secondary')
	Return ($primary == $ID_RITUALIST Or $secondary == $ID_RITUALIST)
EndFunc


Func OutcastIsPreferredRfTarget($agent)
	Return OutcastIsValidRfTarget($agent)
EndFunc


Func OutcastAcquireRfTargetByTargetCycle()
	; Direct nearest-target acquisition without profession analysis.
	ClearTarget()
	Sleep(80)
	TargetNearestEnemy()
	Sleep(150)

	Local $candidate = GetCurrentTarget()
	If OutcastIsValidRfTarget($candidate) Then
		Local $me = GetMyAgent()
		If $me == Null Then Return Null
		Local $dist = GetDistance($me, $candidate)
		If $dist > ($RANGE_SPELLCAST + 120) Then
			OutcastMark('OH_ROTTING_TARGET_C_OUT_OF_RANGE_' & Int($dist))
			Return Null
		EndIf
		OutcastMark('OH_ROTTING_TARGET_BY_C_NEAREST')
		Return $candidate
	EndIf
	If $candidate <> Null And OutcastIsSpiritThreat($candidate) Then OutcastMark('OH_ROTTING_TARGET_C_SKIP_SPIRIT')
	Return Null
EndFunc


Func OutcastCastSpiritCore()
	OutcastMark('OH_SPIRITS_CAST_BEGIN')
	If IsRecharged($OUTCAST_LACERATE) Then
		UseSkillEx($OUTCAST_LACERATE)
		Sleep(3600)
	EndIf
	If IsRecharged($OUTCAST_TOXICITY) Then
		UseSkillEx($OUTCAST_TOXICITY)
		Sleep(3600)
	EndIf
	If IsRecharged($OUTCAST_EDGE_OF_EXTINCTION) Then
		UseSkillEx($OUTCAST_EDGE_OF_EXTINCTION)
		Sleep(3600)
	EndIf
	OutcastMark('OH_SPIRITS_CAST_DONE')
EndFunc


Func OutcastRecastReadySpiritCore()
	OutcastMark('OH_SPIRITS_RECAST_READY_BEGIN')
	If IsRecharged($OUTCAST_LACERATE) Then
		OutcastMark('OH_SPIRITS_RECAST_LACERATE')
		UseSkillEx($OUTCAST_LACERATE)
		Sleep(3600)
	EndIf
	If IsRecharged($OUTCAST_TOXICITY) Then
		OutcastMark('OH_SPIRITS_RECAST_TOXICITY')
		UseSkillEx($OUTCAST_TOXICITY)
		Sleep(3600)
	EndIf
	If IsRecharged($OUTCAST_EDGE_OF_EXTINCTION) Then
		OutcastMark('OH_SPIRITS_RECAST_EOE')
		UseSkillEx($OUTCAST_EDGE_OF_EXTINCTION)
		Sleep(3600)
	EndIf
	OutcastMark('OH_SPIRITS_RECAST_READY_DONE')
EndFunc


Func OutcastRottingEscapeCycle($telemetryPrefix = '')
	Local $target = Null
	Local $seek = TimerInit()
	While TimerDiff($seek) < 12000 And IsPlayerAlive()
		$target = OutcastAcquireRfTargetByTargetCycle()
		If $target <> Null Then ExitLoop

		Local $me = GetMyAgent()
		If $me <> Null Then
			Local $mx = DllStructGetData($me, 'X')
			Local $my = DllStructGetData($me, 'Y')
			$target = OutcastGetNearestPreferredRfFoe($mx, $my, 1900)
		EndIf
		If $target == Null Then $target = OutcastGetNearestPreferredRfFoe($OUTCAST_WAVE_CENTER_X, $OUTCAST_WAVE_CENTER_Y, 1900)
		If $target == Null Then $target = OutcastGetNearestPreferredRfFoe($OUTCAST_HOLD_X, $OUTCAST_HOLD_Y, 1900)
		If $target <> Null Then ExitLoop
		Sleep(140)
	WEnd
	If $target == Null Then
		If $telemetryPrefix <> '' Then OutcastMarkWaveBallSnapshot($telemetryPrefix & '_TARGET_NONE')
		OutcastMark('OH_ROTTING_TARGET_NONE')
		Return $FAIL
	EndIf

	If $telemetryPrefix <> '' Then
		Local $hpRaw = DllStructGetData($target, 'HealthPercent')
		Local $hpPct = Int($hpRaw * 100)
		If $hpPct < 0 Then $hpPct = 0
		If $hpPct > 100 Then $hpPct = 100
		Local $dist = 0
		Local $me = GetMyAgent()
		If $me <> Null Then $dist = Int(GetDistance($me, $target))
		OutcastMark($telemetryPrefix & '_TARGET_M_' & DllStructGetData($target, 'ModelID') & '_HP_' & $hpPct & '_D_' & $dist)
		OutcastMarkWaveBallSnapshot($telemetryPrefix & '_PRE')
	EndIf
	OutcastMark('OH_ROTTING_TARGET_MODEL_' & DllStructGetData($target, 'ModelID'))
	Local $me = GetMyAgent()
	If $me <> Null Then
		Local $distToTarget = GetDistance($me, $target)
		If $distToTarget > ($RANGE_SPELLCAST - 30) Then
			OutcastMark('OH_ROTTING_WAIT_IN_RANGE_BEGIN_D_' & Int($distToTarget))
			Local $inRangeTimer = TimerInit()
			While TimerDiff($inRangeTimer) < 7000 And IsPlayerAlive()
				$me = GetMyAgent()
				If $me == Null Then ExitLoop

				; Reacquire nearest valid foe around player while staying at hold spot.
				Local $near = OutcastGetNearestPreferredRfFoe(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_SPELLCAST + 140)
				If $near <> Null Then
					$target = $near
					$distToTarget = GetDistance($me, $target)
					If $distToTarget <= ($RANGE_SPELLCAST - 30) Then ExitLoop
				EndIf

				RandomSleep(120)
			WEnd
			$me = GetMyAgent()
			If $me <> Null Then
				$distToTarget = GetDistance($me, $target)
				OutcastMark('OH_ROTTING_WAIT_IN_RANGE_END_D_' & Int($distToTarget))
				If $distToTarget > ($RANGE_SPELLCAST - 30) Then
					OutcastMark('OH_ROTTING_TARGET_STILL_OUT_OF_RANGE')
				EndIf
			EndIf
		EndIf
	EndIf
	ChangeTarget($target)
	OutcastMark('OH_ROTTING_CAST')
	UseSkillEx($OUTCAST_ROTTING_FLESH, $target)
	; EE must be queued only once RF is truly casting (not just blinking/queued).
	Local $rfCastStarted = OutcastWaitForRfCommit(7000)
	If Not $rfCastStarted Then
		OutcastMark('OH_EBON_QUEUE_SKIP_NO_RF_CAST')
	Else
		; Try queue once immediately in RF window, then press EE immediately if queue missed.
		If OutcastTryQueueEbonEscapeDuringRf($target, 400) Then
			OutcastMark('OH_EBON_ESCAPE_QUEUE_HIT')
		Else
			OutcastMark('OH_EBON_ESCAPE_QUEUE_MISS')
			Local $spiritNow = OutcastGetBacklineAllySpirit($target, $RANGE_SPIRIT)
			If $spiritNow == Null Then $spiritNow = OutcastGetNearestAllySpirit($RANGE_SPIRIT)
			If $spiritNow <> Null Then
				If OutcastTryEbonEscapeImmediate($spiritNow) Then
					OutcastMark('OH_EBON_ESCAPE_IMMEDIATE_AFTER_RF_HIT')
				Else
					OutcastMark('OH_EBON_ESCAPE_IMMEDIATE_AFTER_RF_FAIL')
				EndIf
			Else
				OutcastMark('OH_EBON_ESCAPE_IMMEDIATE_AFTER_RF_NO_SPIRIT')
			EndIf
		EndIf
	EndIf
	Sleep(350)
	If $telemetryPrefix <> '' Then OutcastMarkWaveBallSnapshot($telemetryPrefix & '_POST')
	Return $SUCCESS
EndFunc


Func OutcastWaitForRfCommit($maxWaitMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs And IsPlayerAlive()
		If Not IsRecharged($OUTCAST_ROTTING_FLESH) Then
			OutcastMark('OH_ROTTING_QUEUE_CONFIRMED')
			OutcastMark('OH_ROTTING_CAST_CONFIRMED')
			Return True
		EndIf
		Sleep(80)
	WEnd
	OutcastMark('OH_ROTTING_CAST_NOT_CONFIRMED')
	Return False
EndFunc


Func OutcastHasHalcyonQuestSucceeded($markPrefix = '')
	Local $quest = GetQuestByID($OUTCAST_QUEST_ID)
	If $quest == Null Then
		If $markPrefix <> '' Then OutcastMark($markPrefix & '_NOT_FOUND')
		Return True
	EndIf

	Local $logState = DllStructGetData($quest, 'LogState')
	If $markPrefix <> '' Then OutcastMark($markPrefix & '_LOGSTATE_' & $logState)

	If BitAND($logState, $ID_QUEST_REWARD) <> 0 Then
		If $markPrefix <> '' Then OutcastMark($markPrefix & '_REWARD')
		Return True
	EndIf

	If $logState == $ID_QUEST_NOT_FOUND Then
		If $markPrefix <> '' Then OutcastMark($markPrefix & '_COMPLETED')
		Return True
	EndIf

	Return False
EndFunc


Func OutcastTryQueueEbonEscapeDuringRf($rfTarget, $queueWindowMs)
	Local $spirit = OutcastGetBacklineAllySpirit($rfTarget, $RANGE_SPIRIT)
	If $spirit == Null Then $spirit = OutcastGetNearestAllySpirit($RANGE_SPIRIT)
	If $spirit == Null Then
		OutcastMark('OH_EBON_SPIRIT_NONE')
		Return False
	EndIf

	Local $spiritID = DllStructGetData($spirit, 'ID')
	OutcastMark('OH_EBON_ESCAPE_QUEUE_SPIRIT_' & $spiritID)
	If Not IsRecharged($OUTCAST_EBON_ESCAPE) Then Return True
	If GetEnergy() < 5 Then
		OutcastMark('OH_EBON_QUEUE_ABORT_LOW_ENERGY')
		Return False
	EndIf

	; Single queue click only, during active RF cast window.
	ChangeTarget($spirit)
	Sleep(60)
	UseSkill($OUTCAST_EBON_ESCAPE, $spirit)
	OutcastMark('OH_EBON_ESCAPE_QUEUE_CLICKED_ONCE')
	Sleep(220)
	Return Not IsRecharged($OUTCAST_EBON_ESCAPE)
EndFunc


Func OutcastShouldTriggerHugNow($primary)
	If $primary <> Null Then
		If DllStructGetData($primary, 'HealthPercent') <= $OUTCAST_HUG_TRIGGER_HP Then Return True
	EndIf

	Local $nearest = GetNearestEnemyToCoords($OUTCAST_WAVE_CENTER_X, $OUTCAST_WAVE_CENTER_Y)
	If $nearest <> Null And OutcastIsValidRfTarget($nearest) Then
		If DllStructGetData($nearest, 'HealthPercent') <= $OUTCAST_HUG_TRIGGER_HP Then
			OutcastMark('OH_GENERAL_HUG_TRIGGER_NEAREST_WAVE_FOE')
			Return True
		EndIf
	EndIf
	Return False
EndFunc


Func OutcastTryEbonEscapeImmediate($spirit)
	If $spirit == Null Then Return False
	If Not IsPlayerAlive() Then Return False
	If Not IsRecharged($OUTCAST_EBON_ESCAPE) Then
		OutcastMark('OH_EBON_ESCAPE_FALLBACK_ALREADY_RECHARGING')
		Return True
	EndIf
	If GetEnergy() < 5 Then Return False

	; Single fallback click only: never spam EE.
	UseSkillEx($OUTCAST_EBON_ESCAPE, $spirit)
	OutcastMark('OH_EBON_ESCAPE_FALLBACK_CLICKED_ONCE')
	Sleep(220)
	Return Not IsRecharged($OUTCAST_EBON_ESCAPE)
EndFunc


Func OutcastHugShipAtLowEnemyHealth($maxWaitMs = 30000, $forceImmediate = False)
	Local $timer = TimerInit()
	Local $hugTriggeredByLowHp = $forceImmediate
	Local $lastObservedHpPct = -1
	Local $lastObservedModel = 0
	If $forceImmediate Then
		OutcastMark('OH_HUG_TRIGGER_FORCED_FROM_CHOREO')
	Else
		While TimerDiff($timer) < $maxWaitMs And IsPlayerAlive()
		Local $target = GetNearestEnemyToCoords($OUTCAST_WAVE_CENTER_X, $OUTCAST_WAVE_CENTER_Y)
		If $target <> Null Then
			$lastObservedHpPct = Int(DllStructGetData($target, 'HealthPercent') * 100)
			$lastObservedModel = DllStructGetData($target, 'ModelID')
			If DllStructGetData($target, 'HealthPercent') <= $OUTCAST_HUG_TRIGGER_HP Then
				$hugTriggeredByLowHp = True
				OutcastMark('OH_HUG_TRIGGER_LOW_HP')
				OutcastMark('OH_HUG_TRIGGER_MODEL_' & $lastObservedModel & '_HP_' & $lastObservedHpPct)
				ExitLoop
			EndIf
		EndIf
		RandomSleep(350)
		WEnd
	EndIf
	If Not $hugTriggeredByLowHp Then
		OutcastMark('OH_HUG_TRIGGER_TIMEOUT')
		If $lastObservedModel > 0 Then OutcastMark('OH_HUG_TIMEOUT_LAST_MODEL_' & $lastObservedModel & '_HP_' & $lastObservedHpPct)
		Return $FAIL
	EndIf

	; Hug behavior must be movement-only: do not cast offensive skills here.
	CancelAction()
	ClearTarget()
	If OutcastMoveTo($OUTCAST_HUG_SHIP_X, $OUTCAST_HUG_SHIP_Y, 12000) == $FAIL Then OutcastMark('OH_HUG_SHIP_MOVE_FAIL')
	OutcastMark('OH_HUG_SHIP')
	OutcastMark('OH_HUG_SHIP_MOVE_ONLY')
	Sleep(3000)
	If OutcastMoveTo($OUTCAST_HOLD_X, $OUTCAST_HOLD_Y, 15000) == $FAIL Then
		OutcastMark('OH_HUG_RETURN_HOLD_MOVE_FAIL')
	Else
		OutcastMark('OH_HUG_RETURN_HOLD')
	EndIf
	Return $SUCCESS
EndFunc


Func OutcastGetBacklineAllySpirit($rfTarget, $range)
	Local $me = GetMyAgent()
	If $me == Null Then Return Null
	If $rfTarget == Null Then Return Null

	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $targetX = DllStructGetData($rfTarget, 'X')
	Local $targetY = DllStructGetData($rfTarget, 'Y')

	Local $dirX = $targetX - $myX
	Local $dirY = $targetY - $myY
	Local $dirLen = Sqrt(($dirX * $dirX) + ($dirY * $dirY))
	If $dirLen <= 0 Then Return Null
	$dirX /= $dirLen
	$dirY /= $dirLen

	Local $myID = GetMyID()
	Local $myTeam = DllStructGetData($me, 'Team')
	Local $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	Local $best = Null
	Local $bestDot = 1.1
	Local $bestDist = 99999999

	For $ally In $agents
		If GetIsDead($ally) Or DllStructGetData($ally, 'HealthPercent') <= 0 Then ContinueLoop
		Local $dist = GetDistance($me, $ally)
		If $dist > $range Then ContinueLoop

		Local $owner = DllStructGetData($ally, 'Owner')
		Local $team = DllStructGetData($ally, 'Team')
		Local $allegiance = DllStructGetData($ally, 'Allegiance')
		Local $isSpiritByAllegiance = ($allegiance == $ID_ALLEGIANCE_SPIRIT)
		Local $isSpiritByTypeMap = ($MAP_SPIRIT_TYPES[DllStructGetData($ally, 'TypeMap')] <> Null)
		Local $isOwnedFallback = ($owner == $myID And $team == $myTeam)
		Local $isTeamSpirit = ($team == $myTeam) And ($isSpiritByAllegiance Or $isSpiritByTypeMap Or $isOwnedFallback)
		If Not $isTeamSpirit Then ContinueLoop

		Local $vx = DllStructGetData($ally, 'X') - $myX
		Local $vy = DllStructGetData($ally, 'Y') - $myY
		Local $vLen = Sqrt(($vx * $vx) + ($vy * $vy))
		If $vLen <= 0 Then ContinueLoop
		$vx /= $vLen
		$vy /= $vLen

		Local $dot = ($vx * $dirX) + ($vy * $dirY)
		If $dot < $bestDot Or ($dot == $bestDot And $dist < $bestDist) Then
			$best = $ally
			$bestDot = $dot
			$bestDist = $dist
		EndIf
	Next

	If $best <> Null Then OutcastMark('OH_EBON_BACKLINE_SPIRIT_DOT_' & Int($bestDot * 100))
	Return $best
EndFunc


Func OutcastWaitForSpiritCoreReady($maxWaitMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs And IsPlayerAlive()
		If IsRecharged($OUTCAST_LACERATE) And IsRecharged($OUTCAST_TOXICITY) And IsRecharged($OUTCAST_EDGE_OF_EXTINCTION) Then
			OutcastMark('OH_SPIRITS_READY_FOR_RESTART')
			Return $SUCCESS
		EndIf
		RandomSleep(220)
	WEnd
	OutcastMark('OH_SPIRITS_NOT_READY_FOR_RESTART')
	Return $FAIL
EndFunc


Func OutcastLootDeck()
	Info('Wave clear done, looting upper deck')
	Local $lootPath[3][2] = [[10983, -4670], [11133, -4897], [11251, -4984]]
	If OutcastFollowPath($lootPath, 35000) == $FAIL Then
		OutcastMark('OH_LOOT_PATH_FAIL')
		Return $FAIL
	EndIf
	OutcastMark('OH_LOOT_PATH_DONE')
	RandomSleep(900)
	PickUpItems()
	If Not IsPlayerAlive() Then
		OutcastMark('OH_LOOT_DEAD')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func OutcastWaitForTargetHpBand($target, $minPct, $maxPct, $maxWaitMs)
	If $target == Null Then Return $FAIL
	Local $targetID = DllStructGetData($target, 'ID')
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs And IsPlayerAlive()
		Local $refreshed = GetAgentByID($targetID)
		If $refreshed == Null Then Return $FAIL
		Local $hpPct = DllStructGetData($refreshed, 'HealthPercent')
		If $hpPct >= $minPct And $hpPct <= $maxPct Then Return $SUCCESS
		RandomSleep(220)
	WEnd
	Return $FAIL
EndFunc


Func OutcastWaitForAnyTargetHpBand($minPct, $maxPct, $maxWaitMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs And IsPlayerAlive()
		Local $me = GetMyAgent()
		Local $candidate = Null
		If $me <> Null Then
			Local $mx = DllStructGetData($me, 'X')
			Local $my = DllStructGetData($me, 'Y')
			$candidate = OutcastGetNearestPreferredRfFoe($mx, $my, 1900)
		EndIf
		If $candidate == Null Then $candidate = OutcastGetNearestPreferredRfFoe($OUTCAST_WAVE_CENTER_X, $OUTCAST_WAVE_CENTER_Y, 1900)
		If $candidate == Null Then $candidate = OutcastGetNearestPreferredRfFoe($OUTCAST_HOLD_X, $OUTCAST_HOLD_Y, 1900)

		If $candidate <> Null Then
			Local $id = DllStructGetData($candidate, 'ID')
			Local $refreshed = GetAgentByID($id)
			If $refreshed <> Null And OutcastIsValidRfTarget($refreshed) Then
				Local $hpPct = DllStructGetData($refreshed, 'HealthPercent')
				If $hpPct >= $minPct And $hpPct <= $maxPct Then Return $SUCCESS
			EndIf
		EndIf

		RandomSleep(220)
	WEnd
	Return $FAIL
EndFunc


Func OutcastWaitForBleedNotPoison($target, $maxWaitMs)
	If $target == Null Then Return $FAIL
	Local $targetID = DllStructGetData($target, 'ID')
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs And IsPlayerAlive()
		Local $refreshed = GetAgentByID($targetID)
		If $refreshed == Null Then Return $FAIL
		If GetIsBleeding($refreshed) And Not GetIsPoisoned($refreshed) Then Return $SUCCESS
		RandomSleep(220)
	WEnd
	Return $FAIL
EndFunc


Func OutcastWaitForAnyBleedNotPoison($maxWaitMs)
	Local $timer = TimerInit()
	Local $sawCandidate = False
	Local $sawBleedingOnly = False
	Local $sawPoisoned = False
	While TimerDiff($timer) < $maxWaitMs And IsPlayerAlive()
		Local $me = GetMyAgent()
		Local $candidate = Null
		If $me <> Null Then
			Local $mx = DllStructGetData($me, 'X')
			Local $my = DllStructGetData($me, 'Y')
			$candidate = OutcastGetNearestPreferredRfFoe($mx, $my, 1900)
		EndIf
		If $candidate == Null Then $candidate = OutcastGetNearestPreferredRfFoe($OUTCAST_WAVE_CENTER_X, $OUTCAST_WAVE_CENTER_Y, 1900)
		If $candidate == Null Then $candidate = OutcastGetNearestPreferredRfFoe($OUTCAST_HOLD_X, $OUTCAST_HOLD_Y, 1900)

		If $candidate <> Null Then
			$sawCandidate = True
			Local $id = DllStructGetData($candidate, 'ID')
			Local $refreshed = GetAgentByID($id)
			If $refreshed <> Null And OutcastIsValidRfTarget($refreshed) Then
				If GetIsBleeding($refreshed) And Not GetIsPoisoned($refreshed) Then
					OutcastMark('OH_ROTTING_SECOND_READY')
					Return $SUCCESS
				EndIf
				If GetIsBleeding($refreshed) Then
					$sawBleedingOnly = True
					If GetIsPoisoned($refreshed) Then $sawPoisoned = True
				EndIf
			EndIf
		EndIf

		RandomSleep(220)
	WEnd
	If Not $sawCandidate Then
			OutcastMarkNearestWaveCandidateState('OH_ROTTING_SECOND_SKIP_STATE')
		OutcastMark('OH_ROTTING_SECOND_SKIP_NO_TARGET')
	ElseIf $sawBleedingOnly And $sawPoisoned Then
			OutcastMarkNearestWaveCandidateState('OH_ROTTING_SECOND_SKIP_STATE')
		OutcastMark('OH_ROTTING_SECOND_SKIP_BLEED_POISON')
	Else
			OutcastMarkNearestWaveCandidateState('OH_ROTTING_SECOND_SKIP_STATE')
		OutcastMark('OH_ROTTING_SECOND_SKIP_NO_BLEED_DETAIL')
	EndIf
	Return $FAIL
EndFunc


	Func OutcastMarkNearestWaveCandidateState($prefix)
		Local $candidate = Null
		Local $me = GetMyAgent()
		If $me <> Null Then
			Local $mx = DllStructGetData($me, 'X')
			Local $my = DllStructGetData($me, 'Y')
			$candidate = OutcastGetNearestNonSpiritFoe($mx, $my, 1900)
		EndIf
		If $candidate == Null Then $candidate = OutcastGetNearestNonSpiritFoe($OUTCAST_WAVE_CENTER_X, $OUTCAST_WAVE_CENTER_Y, 1900)
		If $candidate == Null Then $candidate = OutcastGetNearestNonSpiritFoe($OUTCAST_HOLD_X, $OUTCAST_HOLD_Y, 1900)
		If $candidate == Null Then
			OutcastMark($prefix & '_NONE')
			Return
		EndIf

		Local $id = DllStructGetData($candidate, 'ID')
		Local $refreshed = GetAgentByID($id)
		If $refreshed == Null Then
			OutcastMark($prefix & '_STALE')
			Return
		EndIf

		Local $hpRaw = DllStructGetData($refreshed, 'HealthPercent')
		Local $hpPct = Int($hpRaw)
		If $hpRaw >= 0 And $hpRaw <= 1.5 Then $hpPct = Int($hpRaw * 100)
		If $hpPct < 0 Then $hpPct = 0
		If $hpPct > 100 Then $hpPct = 100

		Local $dist = 0
		If $me <> Null Then $dist = Int(GetDistance($me, $refreshed))
		Local $model = DllStructGetData($refreshed, 'ModelID')
		Local $isBleeding = GetIsBleeding($refreshed) ? 1 : 0
		Local $isPoisoned = GetIsPoisoned($refreshed) ? 1 : 0
		OutcastMark($prefix & '_M_' & $model & '_HP_' & $hpPct & '_B_' & $isBleeding & '_P_' & $isPoisoned & '_D_' & $dist)
	EndFunc


Func OutcastGetWaveFoeStats(ByRef $foes, ByRef $cx, ByRef $cy, ByRef $avgSpread)
	Local $foeAgentsWave = GetFoesInRangeOfCoords($OUTCAST_WAVE_CENTER_X, $OUTCAST_WAVE_CENTER_Y, 1700)
	Local $foeAgentsHold = GetFoesInRangeOfCoords($OUTCAST_HOLD_X, $OUTCAST_HOLD_Y, 1700)
	Local $foeAgentsShip = GetFoesInRangeOfCoords($OUTCAST_SCAN_SHIP_X, $OUTCAST_SCAN_SHIP_Y, 1700)

	Local $foeAgents = $foeAgentsWave
	If UBound($foeAgentsHold) > UBound($foeAgents) Then $foeAgents = $foeAgentsHold
	If UBound($foeAgentsShip) > UBound($foeAgents) Then $foeAgents = $foeAgentsShip

	$foes = UBound($foeAgents)
	$cx = 0
	$cy = 0
	$avgSpread = 99999
	If $foes == 0 Then Return False

	Local $sampleCount = ($foes < 18) ? $foes : 18
	Local $sumX = 0
	Local $sumY = 0
	For $k = 0 To $sampleCount - 1
		$sumX += DllStructGetData($foeAgents[$k], 'X')
		$sumY += DllStructGetData($foeAgents[$k], 'Y')
	Next
	$cx = Int($sumX / $sampleCount)
	$cy = Int($sumY / $sampleCount)

	Local $sumSpread = 0
	For $k = 0 To $sampleCount - 1
		Local $ax = DllStructGetData($foeAgents[$k], 'X')
		Local $ay = DllStructGetData($foeAgents[$k], 'Y')
		$sumSpread += Sqrt((($ax - $cx) * ($ax - $cx)) + (($ay - $cy) * ($ay - $cy)))
	Next
	$avgSpread = Int($sumSpread / $sampleCount)
	Return True
EndFunc


Func OutcastMarkWaveBallSnapshot($prefix)
	Local $foes = 0, $cx = 0, $cy = 0, $spread = 99999
	If Not OutcastGetWaveFoeStats($foes, $cx, $cy, $spread) Then
		OutcastMark($prefix & '_NONE')
		Return
	EndIf
	OutcastMark($prefix & '_FOES_' & $foes)
	OutcastMark($prefix & '_SPREAD_' & $spread)
	OutcastMark($prefix & '_CX_' & $cx & '_CY_' & $cy)
EndFunc


Func OutcastMarkNearestFoeDistance($prefix)
	Local $me = GetMyAgent()
	If $me == Null Then
		OutcastMark($prefix & '_ME_NULL')
		Return
	EndIf

	Local $mx = DllStructGetData($me, 'X')
	Local $my = DllStructGetData($me, 'Y')
	Local $near = GetNearestEnemyToCoords($mx, $my)
	If $near == Null Then
		OutcastMark($prefix & '_NONE')
		Return
	EndIf

	Local $dist = Int(GetDistance($me, $near))
	Local $model = DllStructGetData($near, 'ModelID')
	Local $hpRaw = DllStructGetData($near, 'HealthPercent')
	Local $hpPct = Int($hpRaw)
	If $hpRaw >= 0 And $hpRaw <= 1.5 Then $hpPct = Int($hpRaw * 100)
	If $hpPct < 0 Then $hpPct = 0
	If $hpPct > 100 Then $hpPct = 100
	OutcastMark($prefix & '_M_' & $model & '_HP_' & $hpPct & '_D_' & $dist)
EndFunc


Func OutcastWaitForCalmBallBeforeSecondRotting($waveIndex, $maxWaitMs)
	OutcastMark('OH_ROTTING_SECOND_CALM_WAIT_BEGIN_W' & $waveIndex)
	Local $timer = TimerInit()
	Local $heartbeat = TimerInit()
	Local $settledTicks = 0
	Local $prevFoes = -1
	Local $prevCx = 0
	Local $prevCy = 0
	Local $prevSpread = 99999
	Local $stableSpreadLimit = ($waveIndex == 1) ? 520 : 600
	Local $requiredFoes = 5
	Local $requiredSettledTicks = 4
	If $OUTCAST_FAST_MODE Then
		$requiredFoes = 4
		$requiredSettledTicks = 2
		$stableSpreadLimit += 140
	EndIf

	While TimerDiff($timer) < $maxWaitMs And IsPlayerAlive()
		Local $foes = 0, $cx = 0, $cy = 0, $spread = 99999
		If Not OutcastGetWaveFoeStats($foes, $cx, $cy, $spread) Then
			$settledTicks = 0
			RandomSleep(350)
			ContinueLoop
		EndIf

		If TimerDiff($heartbeat) >= 8000 Then
			OutcastMark('OH_ROTTING_SECOND_CALM_FOES_' & $foes)
			OutcastMark('OH_ROTTING_SECOND_CALM_SPREAD_' & $spread)
			OutcastMarkNearestFoeDistance('OH_ROTTING_SECOND_CALM_NEAR_W' & $waveIndex)
			If $prevFoes >= 0 Then
				OutcastMark('OH_ROTTING_SECOND_CALM_DELTA_W' & $waveIndex & '_F_' & Abs($foes - $prevFoes) & '_CX_' & Abs($cx - $prevCx) & '_CY_' & Abs($cy - $prevCy) & '_S_' & Abs($spread - $prevSpread))
			EndIf
			$heartbeat = TimerInit()
		EndIf

		If $foes >= $requiredFoes And $spread <= $stableSpreadLimit And Abs($foes - $prevFoes) <= 1 And Abs($cx - $prevCx) < 28 And Abs($cy - $prevCy) < 28 And Abs($spread - $prevSpread) < 45 Then
			$settledTicks += 1
		Else
			$settledTicks = 0
		EndIf

		$prevFoes = $foes
		$prevCx = $cx
		$prevCy = $cy
		$prevSpread = $spread

		If $settledTicks >= $requiredSettledTicks Then
			OutcastMark('OH_ROTTING_SECOND_CALM_READY')
			Return $SUCCESS
		EndIf

		RandomSleep(380)
	WEnd

	If Not IsPlayerAlive() Then
		OutcastMark('OH_ROTTING_SECOND_CALM_ABORT_DEAD')
		OutcastMarkFailureContext('OH_FAIL_CTX_W' & $waveIndex & '_CALM_ABORT_DEAD')
	Else
		OutcastMark('OH_ROTTING_SECOND_CALM_TIMEOUT')
		If Not $OUTCAST_FAST_MODE Then OutcastMarkFailureContext('OH_FAIL_CTX_W' & $waveIndex & '_CALM_TIMEOUT')
	EndIf
	Return $FAIL
EndFunc


Func OutcastGetNearestAllySpirit($range)
	Local $me = GetMyAgent()
	If $me == Null Then Return Null

	Local $myID = GetMyID()
	Local $myTeam = DllStructGetData($me, 'Team')
	Local $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	Local $best = Null
	Local $bestScore = -99999999

	For $ally In $agents
		If GetIsDead($ally) Or DllStructGetData($ally, 'HealthPercent') <= 0 Then ContinueLoop
		Local $dist = GetDistance($me, $ally)
		If $dist > $range Then ContinueLoop

		Local $owner = DllStructGetData($ally, 'Owner')
		Local $team = DllStructGetData($ally, 'Team')
		Local $allegiance = DllStructGetData($ally, 'Allegiance')
		Local $isSpiritByAllegiance = ($allegiance == $ID_ALLEGIANCE_SPIRIT)
		Local $isSpiritByTypeMap = ($MAP_SPIRIT_TYPES[DllStructGetData($ally, 'TypeMap')] <> Null)
		Local $isOwnedFallback = ($owner == $myID And $team == $myTeam)
		Local $isTeamSpirit = ($team == $myTeam) And ($isSpiritByAllegiance Or $isSpiritByTypeMap Or $isOwnedFallback)
		If Not $isTeamSpirit Then ContinueLoop

		Local $score = 100000 - $dist
		If $isOwnedFallback Then $score += 100000
		$score += 50000
		If $isSpiritByAllegiance Then $score += 20000
		If $isSpiritByTypeMap Then $score += 5000

		If $score > $bestScore Then
			$best = $ally
			$bestScore = $score
		EndIf
	Next
	Return $best
EndFunc


Func OutcastTryDryrunSpiritCast($skillSlot, $castMarker)
	If Not IsRecharged($skillSlot) Then Return False

	For $i = 1 To 2
		UseSkillEx($skillSlot)
		Sleep(220)

		Local $wait = TimerInit()
		While TimerDiff($wait) < 2400
			If Not IsRecharged($skillSlot) Then
				OutcastMark($castMarker)
				Return True
			EndIf
			Sleep(100)
		WEnd
	Next

	OutcastMark($castMarker & '_NO_RECHARGE')
	Return False
EndFunc


Func OutcastMarkDryrunSpiritScan($range)
	Local $me = GetMyAgent()
	If $me == Null Then Return

	Local $myID = GetMyID()
	Local $myTeam = DllStructGetData($me, 'Team')
	Local $agents = GetAgentArray($ID_AGENT_TYPE_NPC)

	Local $nearCount = 0
	Local $spiritAllegianceCount = 0
	Local $spiritTypeMapCount = 0
	Local $ownedCandidateCount = 0

	For $agent In $agents
		If GetIsDead($agent) Or DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		Local $dist = GetDistance($me, $agent)
		If $dist > $range Then ContinueLoop
		$nearCount += 1

		Local $owner = DllStructGetData($agent, 'Owner')
		Local $team = DllStructGetData($agent, 'Team')
		Local $allegiance = DllStructGetData($agent, 'Allegiance')
		If $allegiance == $ID_ALLEGIANCE_SPIRIT Then $spiritAllegianceCount += 1
		If $MAP_SPIRIT_TYPES[DllStructGetData($agent, 'TypeMap')] <> Null Then $spiritTypeMapCount += 1
		If $owner == $myID And $team == $myTeam Then $ownedCandidateCount += 1
	Next

	OutcastMark('OH_DRYRUN_SPIRIT_SCAN_N_' & $nearCount & '_A_' & $spiritAllegianceCount & '_T_' & $spiritTypeMapCount & '_O_' & $ownedCandidateCount)
EndFunc


Func OutcastDryRunSpiritTargetProbe()
	Info('Dryrun: Spirit target probe in Boreas (no Rion/waves)')
	OutcastMark('OH_DRYRUN_SPIRIT_PROBE_BEGIN')
	OutcastMarkDryrunSpiritScan(1800)

	; Cast a guaranteed spirit skill first so we have a deterministic ally-spirit target.
	Local $casted = False
	If IsRecharged($OUTCAST_EDGE_OF_EXTINCTION) Then
		$casted = OutcastTryDryrunSpiritCast($OUTCAST_EDGE_OF_EXTINCTION, 'OH_DRYRUN_SPIRIT_CAST_EOE')
	ElseIf IsRecharged($OUTCAST_TOXICITY) Then
		$casted = OutcastTryDryrunSpiritCast($OUTCAST_TOXICITY, 'OH_DRYRUN_SPIRIT_CAST_TOXICITY')
	ElseIf IsRecharged($OUTCAST_LACERATE) Then
		$casted = OutcastTryDryrunSpiritCast($OUTCAST_LACERATE, 'OH_DRYRUN_SPIRIT_CAST_LACERATE')
	Else
		OutcastMark('OH_DRYRUN_SPIRIT_CAST_SKIPPED')
	EndIf

	If $casted Then
		Sleep(3800)
	Else
		OutcastMark('OH_DRYRUN_SPIRIT_CAST_UNCONFIRMED')
		Sleep(1200)
	EndIf

	Local $timer = TimerInit()
	Local $lastProbeSecond = -1
	While TimerDiff($timer) < 20000 And IsPlayerAlive()
		Local $spirit = OutcastGetNearestAllySpirit(1800)
		If $spirit == Null Then
			Local $sec = Int(TimerDiff($timer) / 1000)
			If Mod($sec, 5) == 0 And $sec <> $lastProbeSecond Then
				OutcastMark('OH_DRYRUN_SPIRIT_NONE')
				OutcastMarkDryrunSpiritScan(1800)
				$lastProbeSecond = $sec
			EndIf
			RandomSleep(200)
			ContinueLoop
		EndIf

		Local $spiritID = DllStructGetData($spirit, 'ID')
		Local $spiritModel = DllStructGetData($spirit, 'ModelID')
		OutcastMark('OH_DRYRUN_SPIRIT_FOUND_ID_' & $spiritID & '_M_' & $spiritModel)

		For $attempt = 1 To 5
			ChangeTarget($spirit)
			Sleep(170)
			Local $currentTarget = GetCurrentTarget()
			If $currentTarget <> Null And DllStructGetData($currentTarget, 'ID') == $spiritID Then
				OutcastMark('OH_DRYRUN_SPIRIT_TARGET_OK')
				Info('Dryrun target success: ally spirit can be targeted reliably')
				Return OutcastDryRunSpiritTeleportDemo($spirit)
			EndIf
			OutcastMark('OH_DRYRUN_SPIRIT_TARGET_MISS_' & $attempt)
			Sleep(120)
		Next
		RandomSleep(200)
	WEnd

	Warn('Dryrun failed: could not confirm ally spirit targeting')
	OutcastMark('OH_DRYRUN_SPIRIT_TARGET_FAIL')
	Return $FAIL
EndFunc


Func OutcastDryRunSpiritTeleportDemo($spirit)
	If $spirit == Null Then Return $FAIL

	Local $me = GetMyAgent()
	If $me == Null Then Return $FAIL

	Local $sx = DllStructGetData($spirit, 'X')
	Local $sy = DllStructGetData($spirit, 'Y')
	Local $mx = DllStructGetData($me, 'X')
	Local $my = DllStructGetData($me, 'Y')

	Local $startDist = GetDistanceToPoint($me, $sx, $sy)
	OutcastMark('OH_DRYRUN_TP_BEGIN_D_' & Int($startDist))

	; Move a bit farther from the spirit first, then verify Ebon return.
	Local $vx = $mx - $sx
	Local $vy = $my - $sy
	Local $vlen = Sqrt($vx * $vx + $vy * $vy)
	If $vlen < 1 Then
		$vx = 1
		$vy = 0
		$vlen = 1
	EndIf

	Local $walkDist = 420
	Local $walkX = $mx + ($vx / $vlen) * $walkDist
	Local $walkY = $my + ($vy / $vlen) * $walkDist
	Move($walkX, $walkY)

	Local $walkTimer = TimerInit()
	While TimerDiff($walkTimer) < 2400 And IsPlayerAlive()
		If GetDistanceToPoint(GetMyAgent(), $walkX, $walkY) <= 140 Then ExitLoop
		If Not IsPlayerMoving() Then Move($walkX, $walkY)
		Sleep(90)
	WEnd

	$me = GetMyAgent()
	If $me == Null Then Return $FAIL
	Local $beforeTpDist = GetDistanceToPoint($me, $sx, $sy)
	OutcastMark('OH_DRYRUN_TP_WALK_D_' & Int($beforeTpDist))

	If Not IsRecharged($OUTCAST_EBON_ESCAPE) Then
		OutcastMark('OH_DRYRUN_TP_EBON_NOT_READY')
		Return $FAIL
	EndIf
	If GetEnergy() < 5 Then
		OutcastMark('OH_DRYRUN_TP_EBON_LOW_ENERGY')
		Return $FAIL
	EndIf

	ChangeTarget($spirit)
	Sleep(120)
	OutcastMark('OH_DRYRUN_TP_EBON_CAST')
	UseSkillEx($OUTCAST_EBON_ESCAPE, $spirit)

	Local $tpTimer = TimerInit()
	While TimerDiff($tpTimer) < 2600 And IsPlayerAlive()
		$me = GetMyAgent()
		If $me == Null Then ExitLoop
		Local $afterTpDist = GetDistanceToPoint($me, $sx, $sy)
		If $afterTpDist <= 180 Then
			OutcastMark('OH_DRYRUN_TP_SUCCESS_D_' & Int($beforeTpDist) & '_' & Int($afterTpDist))
			Info('Dryrun teleport success: walked away then returned to spirit')
			Return $SUCCESS
		EndIf
		Sleep(90)
	WEnd

	$me = GetMyAgent()
	If $me == Null Then Return $FAIL
	OutcastMark('OH_DRYRUN_TP_FAIL_D_' & Int($beforeTpDist) & '_' & Int(GetDistanceToPoint($me, $sx, $sy)))
	Warn('Dryrun teleport failed: no return-to-spirit confirmation')
	Return $FAIL
EndFunc


Func OutcastFollowPath(ByRef $path, $timePerPoint = 30000)
	For $i = 0 To UBound($path) - 1
		If OutcastMoveTo($path[$i][0], $path[$i][1], $timePerPoint) == $FAIL Then Return $FAIL
	Next
	Return $SUCCESS
EndFunc


Func OutcastMoveTo($x, $y, $timeoutMs)
	Local $timer = TimerInit()
	Move($x, $y)

	While IsPlayerAlive() And GetDistanceToPoint(GetMyAgent(), $x, $y) > 240
		If TimerDiff($timer) > $timeoutMs Then
			Warn('Timed out moving to [' & $x & ',' & $y & ']')
			OutcastMarkFailureContext('OH_FAIL_CTX_MOVE_TIMEOUT_' & Int($x) & '_' & Int($y))
			Return $FAIL
		EndIf

		If IsRecharged($OUTCAST_RUN_AS_ONE) And GetEnergy() >= 5 Then UseSkillEx($OUTCAST_RUN_AS_ONE)
		If Not IsPlayerMoving() Then Move($x, $y)
		RandomSleep(220)
	WEnd

	If Not IsPlayerAlive() Then OutcastMarkFailureContext('OH_FAIL_CTX_MOVE_DEAD_' & Int($x) & '_' & Int($y))
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func OutcastTryStartRecorder()
	If Not $OUTCAST_AUTO_RECORD_FIRST_TEST Then Return
	If Not IsDeclared('path_action_recorder_active') Then Return
	If Eval('path_action_recorder_active') Then Return

	StartPathActionRecorder()
	RandomSleep(100)
	If Eval('path_action_recorder_active') Then $outcast_started_recorder = True
EndFunc


Func OutcastTryStopRecorder()
	If Not $outcast_started_recorder Then Return
	If Not IsDeclared('path_action_recorder_active') Then Return
	If Not Eval('path_action_recorder_active') Then Return

	StopPathActionRecorder()
	$outcast_started_recorder = False
EndFunc


Func OutcastMark($note)
	If Not IsDeclared('path_action_recorder_active') Then Return
	If Not Eval('path_action_recorder_active') Then Return
	PathActionRecorderMark($note)
EndFunc


Func OutcastMarkFailureContext($prefix)
	OutcastMark($prefix)

	Local $me = GetMyAgent()
	If $me == Null Then
		OutcastMark($prefix & '_ME_NULL')
		Return
	EndIf

	Local $mx = Int(DllStructGetData($me, 'X'))
	Local $my = Int(DllStructGetData($me, 'Y'))
	Local $hpRaw = DllStructGetData($me, 'HealthPercent')
	Local $hpPct = Int($hpRaw)
	If $hpRaw >= 0 And $hpRaw <= 1.5 Then $hpPct = Int($hpRaw * 100)
	If $hpPct < 0 Then $hpPct = 0
	If $hpPct > 100 Then $hpPct = 100
	Local $energy = Int(GetEnergy())
	OutcastMark($prefix & '_ME_HP_' & $hpPct & '_EN_' & $energy & '_X_' & $mx & '_Y_' & $my)

	Local $foes = 0, $cx = 0, $cy = 0, $spread = 99999
	If OutcastGetWaveFoeStats($foes, $cx, $cy, $spread) Then
		OutcastMark($prefix & '_BALL_F_' & $foes & '_S_' & $spread & '_CX_' & $cx & '_CY_' & $cy)
	Else
		OutcastMark($prefix & '_BALL_NONE')
	EndIf

	Local $target = GetCurrentTarget()
	If $target <> Null Then
		Local $tid = DllStructGetData($target, 'ID')
		Local $tmodel = DllStructGetData($target, 'ModelID')
		Local $thpRaw = DllStructGetData($target, 'HealthPercent')
		Local $thpPct = Int($thpRaw)
		If $thpRaw >= 0 And $thpRaw <= 1.5 Then $thpPct = Int($thpRaw * 100)
		If $thpPct < 0 Then $thpPct = 0
		If $thpPct > 100 Then $thpPct = 100
		Local $tdist = Int(GetDistance($me, $target))
		OutcastMark($prefix & '_TGT_ID_' & $tid & '_M_' & $tmodel & '_HP_' & $thpPct & '_D_' & $tdist)
	Else
		OutcastMark($prefix & '_TGT_NONE')
	EndIf

	Local $near = GetNearestEnemyToCoords($mx, $my)
	If $near <> Null Then
		Local $nmodel = DllStructGetData($near, 'ModelID')
		Local $nhpRaw = DllStructGetData($near, 'HealthPercent')
		Local $nhpPct = Int($nhpRaw)
		If $nhpRaw >= 0 And $nhpRaw <= 1.5 Then $nhpPct = Int($nhpRaw * 100)
		If $nhpPct < 0 Then $nhpPct = 0
		If $nhpPct > 100 Then $nhpPct = 100
		Local $ndist = Int(GetDistance($me, $near))
		OutcastMark($prefix & '_NEAR_M_' & $nmodel & '_HP_' & $nhpPct & '_D_' & $ndist)
	Else
		OutcastMark($prefix & '_NEAR_NONE')
	EndIf

	OutcastMarkQuestState($prefix & '_QUEST')
EndFunc


Func OutcastMarkQuestState($prefix)
	Local $quest = GetQuestByID($OUTCAST_QUEST_ID)
	If $quest == Null Then
		OutcastMark($prefix & '_NOT_FOUND')
		Return
	EndIf

	Local $logState = DllStructGetData($quest, 'LogState')
	OutcastMark($prefix & '_LOGSTATE_' & $logState)
EndFunc


Func OutcastGetLexisNPC()
	Local $lexis = GetAgentByModelID($OUTCAST_LEXIS_MODEL_ID)
	If $lexis <> Null And IsNPCAgentType($lexis) Then
		If GetDistanceToPoint($lexis, $OUTCAST_LEXIS_X, $OUTCAST_LEXIS_Y) <= $RANGE_COMPASS Then Return $lexis
	EndIf

	Local $nearNPCs = GetNPCsInRangeOfCoords($OUTCAST_LEXIS_X, $OUTCAST_LEXIS_Y, Null, $RANGE_COMPASS)
	Local $fallback = Null
	Local $fallbackDist = 99999999

	For $npc In $nearNPCs
		If Not IsNPCAgentType($npc) Then ContinueLoop
		Local $model = DllStructGetData($npc, 'ModelID')
		If $model == $OUTCAST_LEXIS_MODEL_ID Then Return $npc
		Local $dist = GetDistanceToPoint($npc, $OUTCAST_LEXIS_X, $OUTCAST_LEXIS_Y)
		If $dist < $fallbackDist Then
			$fallback = $npc
			$fallbackDist = $dist
		EndIf
	Next

	; Classic farm behavior: nearest NPC at quest coords as final fallback.
	If $fallback == Null Then $fallback = GetNearestNPCToCoords($OUTCAST_LEXIS_X, $OUTCAST_LEXIS_Y)
	Return $fallback
EndFunc


Func OutcastMoveNearLexis()
	; Stable approach path toward Lexis stairs/platform from common Cavalon spawn zone.
	MoveTo(7340, -2100, 220, 0)
	RandomSleep(120)
	MoveTo(7320, -1750, 220, 0)
	RandomSleep(120)
	MoveTo($OUTCAST_LEXIS_X, $OUTCAST_LEXIS_Y, 120, 0)
	RandomSleep(120)

	Local $timer = TimerInit()
	While TimerDiff($timer) < 10000 And IsPlayerAlive()
		Local $me = GetMyAgent()
		If GetDistanceToPoint($me, $OUTCAST_LEXIS_X, $OUTCAST_LEXIS_Y) <= 120 Then ExitLoop
		MoveTo($OUTCAST_LEXIS_X, $OUTCAST_LEXIS_Y, 220, 0)
		RandomSleep(160)
	WEnd
EndFunc


Func OutcastMarkLexisNearbyNPCs()
	Local $nearNPCs = GetNPCsInRangeOfCoords($OUTCAST_LEXIS_X, $OUTCAST_LEXIS_Y, Null, $RANGE_COMPASS)
	Local $maxMarks = (UBound($nearNPCs) < 8) ? UBound($nearNPCs) : 8
	For $i = 0 To $maxMarks - 1
		Local $npc = $nearNPCs[$i]
		Local $model = DllStructGetData($npc, 'ModelID')
		Local $dist = Int(GetDistanceToPoint($npc, $OUTCAST_LEXIS_X, $OUTCAST_LEXIS_Y))
		OutcastMark('OH_LEXIS_SCAN_MODEL_' & $model & '_D_' & $dist)
	Next
EndFunc


Func OutcastWaitForLexisAgentData($maxWaitMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs And IsPlayerAlive()
		Local $nearNPCs = GetNPCsInRangeOfCoords($OUTCAST_LEXIS_X, $OUTCAST_LEXIS_Y, Null, 1400)
		Local $knownModels = 0
		For $npc In $nearNPCs
			Local $model = DllStructGetData($npc, 'ModelID')
			If $model > 1 Then $knownModels += 1
			If $model == $OUTCAST_LEXIS_MODEL_ID Then Return
		Next
		; Avoid immediate false negative right after zoning when model IDs are still placeholders.
		If $knownModels >= 2 Then Return
		RandomSleep(150)
	WEnd
EndFunc
