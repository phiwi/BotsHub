#CS ===========================================================================
; Author: GitHub Copilot (FeathersSin prototype)
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

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $AE_FEATHERS_SIN_SKILLBAR = 'OwZTgGF/5R6rzOgIDfxuInNMAA'
Global Const $FEATHERS_SIN_FARM_DURATION = (8 * 60 + 20) * 1000

Global Const $FEATHERS_SIN_GLYPH_SWIFTNESS = 1
Global Const $FEATHERS_SIN_SHADOW_FORM = 2
Global Const $FEATHERS_SIN_SHROUD = 3
Global Const $FEATHERS_SIN_GLYPH_LESSER = 4
Global Const $FEATHERS_SIN_MARK = 5
Global Const $FEATHERS_SIN_METEOR = 6
Global Const $FEATHERS_SIN_BED_OF_COALS = 7
Global Const $FEATHERS_SIN_LAVA_FONT = 8
Global Const $FEATHERS_SIN_MORGAHN_ENDURING_HARMONY = 5
Global Const $FEATHERS_SIN_MORGAHN_MAKE_HASTE = 7

Global Const $FEATHERS_SIN_MODELID_SENSALI_CLAW = 3995
Global Const $FEATHERS_SIN_MODELID_SENSALI_DARKFEATHER = 3997
Global Const $FEATHERS_SIN_MODELID_SENSALI_CUTTER = 3999
Global Const $FEATHERS_SIN_POST_KILL_WAIT_MS = 10000
Global Const $FEATHERS_SIN_MIN_SF_FOR_CHOREO_MS = 7000
Global Const $FEATHERS_SIN_COMBO_BUDGET_MS = 6500
Global Const $FEATHERS_SIN_EXTRA_SF_MARGIN_MS = 1000
Global Const $FEATHERS_SIN_SF_RECAST_MAX_MS = 21000
Global Const $FEATHERS_SIN_SF_RECAST_THRESHOLD_MS = 8000
Global Const $FEATHERS_SIN_SF_REFRESH_BUFFER_MS = 4500
Global Const $FEATHERS_SIN_SF_EARLY_OFFSET_MS = 1000
Global Const $FEATHERS_SIN_SF_PRECAST_GOS_MS = 3000
Global Const $FEATHERS_SIN_AGGRO_RANGE = 1200
Global Const $FEATHERS_SIN_ENERGY_RESERVE = 10
Global Const $FEATHERS_SIN_OFFENSE_MIN_ENERGY = 20
Global Const $FEATHERS_SIN_MIN_ENERGY_FOR_COMBO = 30

Global $feathers_sin_farm_setup = False
Global $feathers_sin_sf_cycle_timer = TimerInit()
Global $feathers_sin_csv_timer = TimerInit()
Global $feathers_sin_csv_file = ''
Global $feathers_sin_csv_handle = -1
Global $feathers_sin_run_number = 0
Global $feathers_sin_combo_active = False
Global $feathers_sin_csv_heartbeat_timer = TimerInit()
Global $feathers_sin_morgahn_index_cache = 0


Func FeathersFarmSin()
	If Not $feathers_sin_farm_setup And SetupFeathersSinFarm() == $FAIL Then Return $PAUSE

	$feathers_sin_sf_cycle_timer = TimerInit()
	$feathers_sin_run_number += 1
	FeathersSinCsvInit()
	FeathersSinCsvWrite('run_start', 'run=' & $feathers_sin_run_number)
	FeathersSinGoToJayaBluffs()
	Local $result = FeathersSinFarmLoop()
	FeathersSinCsvWrite('run_end', 'result=' & $result)
	FeathersSinCsvClose()
	ResignAndReturnToOutpost($ID_SEITUNG_HARBOR)
	Return $result
EndFunc


Func SetupFeathersSinFarm()
	Info('Setting up Feathers Sin farm')
	If TravelToOutpost($ID_SEITUNG_HARBOR, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerFeathersSinFarm() == $FAIL Then Return $FAIL
	LeaveParty()
	$feathers_sin_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerFeathersSinFarm()
	Info('Setting up A/E player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_ASSASSIN Then
		Warn('Should run this farm as assassin')
		Return $FAIL
	EndIf
	; Build is configured manually by user; keep auto-load disabled.
	; LoadSkillTemplate($AE_FEATHERS_SIN_SKILLBAR)
	RandomSleep(250)
	Return $SUCCESS
EndFunc


Func FeathersSinGoToJayaBluffs()
	TravelToOutpost($ID_SEITUNG_HARBOR, $district_name)
	While GetMapID() <> $ID_JAYA_BLUFFS
		Info('Moving to Jaya Bluffs')
		Local $me = GetMyAgent()
		If GetDistanceToPoint($me, 17300, 17300) > 5000 Then MoveTo(17000, 12400)
		If GetDistanceToPoint($me, 17300, 17300) > 4400 Then MoveTo(19000, 13450)
		If GetDistanceToPoint($me, 17300, 17300) > 1800 Then MoveTo(18750, 16000)
		MoveTo(17300, 17300)
		Move(16800, 17550)
		RandomSleep(1000)
		WaitMapLoading($ID_JAYA_BLUFFS, 10000, 2000)
	WEnd
EndFunc


Func FeathersSinFarmLoop()
	If GetMapID() <> $ID_JAYA_BLUFFS Then Return $FAIL
	FeathersSinApplyMorgahnStartBoost()

	Info('Running to Sensali.')
	UseConsumable($ID_BIRTHDAY_CUPCAKE)
	MoveTo(9000, -12680)
	MoveTo(7588, -10609)
	MoveTo(2900, -9700)
	MoveTo(1540, -6995)

	Info('Farming Sensali (A/E)')
	If FeathersSinMoveKill(-472, -4342, False) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-1536, -1686) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(586, -76) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-1556, 2786) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-2229, -815, True, 2 * 60 * 1000) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-5247, -3290) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-6994, -2273) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-5042, -6638) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-11040, -8577) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-10860, -2840) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-14900, -3000) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-12200, 150) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-12500, 4000) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-12111, 1690) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-10303, 4110) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-10500, 5500) == $FAIL Then Return $FAIL
	If FeathersSinMoveKill(-9700, 2400) == $FAIL Then Return $FAIL

	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func FeathersSinApplyMorgahnStartBoost()
	Local $heroIndex = FeathersSinGetMorgahnIndex()
	If $heroIndex == 0 Then
		FeathersSinCsvWrite('morgahn_boost_skip', 'reason=hero_not_found')
		Return
	EndIf

	Local $me = GetMyAgent()
	FeathersSinCsvWrite('morgahn_boost_start', 'hero=' & $heroIndex)

	CancelHero($heroIndex)
	RandomSleep(120)

	If IsRecharged($FEATHERS_SIN_MORGAHN_ENDURING_HARMONY, $heroIndex) Then
		UseHeroSkill($heroIndex, $FEATHERS_SIN_MORGAHN_ENDURING_HARMONY, $me)
		RandomSleep(220)
	EndIf

	If IsRecharged($FEATHERS_SIN_MORGAHN_MAKE_HASTE, $heroIndex) Then
		UseHeroSkill($heroIndex, $FEATHERS_SIN_MORGAHN_MAKE_HASTE, $me)
		RandomSleep(260)
	EndIf

	$me = GetMyAgent()
	CommandHero($heroIndex, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'))
	FeathersSinCsvWrite('morgahn_boost_done', 'hero=' & $heroIndex)
EndFunc


Func FeathersSinGetMorgahnIndex()
	Local $heroCount = GetHeroCount()
	If $heroCount <= 0 Then Return 0

	If $feathers_sin_morgahn_index_cache >= 1 And $feathers_sin_morgahn_index_cache <= $heroCount Then
		Local $cachedS5 = GetSkillbarSkillID($FEATHERS_SIN_MORGAHN_ENDURING_HARMONY, $feathers_sin_morgahn_index_cache)
		Local $cachedS7 = GetSkillbarSkillID($FEATHERS_SIN_MORGAHN_MAKE_HASTE, $feathers_sin_morgahn_index_cache)
		If $cachedS5 == $ID_ENDURING_HARMONY And $cachedS7 == $ID_MAKE_HASTE Then Return $feathers_sin_morgahn_index_cache
	EndIf

	For $i = 1 To $heroCount
		Local $s5 = GetSkillbarSkillID($FEATHERS_SIN_MORGAHN_ENDURING_HARMONY, $i)
		Local $s7 = GetSkillbarSkillID($FEATHERS_SIN_MORGAHN_MAKE_HASTE, $i)
		If $s5 == $ID_ENDURING_HARMONY And $s7 == $ID_MAKE_HASTE Then
			$feathers_sin_morgahn_index_cache = $i
			Return $i
		EndIf
	Next

	Return 0
EndFunc


Func FeathersSinMoveKill($x, $y, $waitForSettle = True, $timeout = 5 * 60 * 1000)
	Local $angle = 0
	Local $stuckCount = 0
	Local $blocked = 0
	Local $deadlock = TimerInit()

	Move($x, $y)
	Local $me = GetMyAgent()
	While GetDistanceToPoint($me, $x, $y) > 250
		If TimerDiff($deadlock) > $timeout Then
			Resign()
			Sleep(3000)
			$deadlock = TimerInit()
			While IsPlayerAlive() And TimerDiff($deadlock) < 30000
				Sleep(3000)
				If TimerDiff($deadlock) > 15000 Then Resign()
			WEnd
		EndIf
		If IsPlayerDead() Then Return $FAIL

		FeathersSinMaintainPerma()
		$me = GetMyAgent()

		$me = GetMyAgent()
		If Not IsPlayerMoving() Then
			$blocked += 1
			If $blocked <= 5 Then
				Move($x, $y)
			Else
				$angle += 40
				Move(DllStructGetData($me, 'X') + 300 * Sin($angle), DllStructGetData($me, 'Y') + 300 * Cos($angle))
				Sleep(1500)
				Move($x, $y)
			EndIf
		EndIf

		$stuckCount += 1
		If $stuckCount > 25 Then
			$stuckCount = 0
			CheckAndSendStuckCommand()
		EndIf
		RandomSleep(220)
		$me = GetMyAgent()
	WEnd

	; Fight only after arriving at the intended spot.
	If IsPlayerDead() Then Return $FAIL
	$me = GetMyAgent()
	If FeathersSinCountCombatFoes($me) > 0 Then
		Sleep(1200)
		If FeathersSinKill($waitForSettle, $x, $y) == $FAIL Then Return $FAIL
		If FeathersSinPostKillWait() == $FAIL Then Return $FAIL

		; Do not leave this spot until the extended aggro bubble is clean.
		Local $clearTimer = TimerInit()
		While FeathersSinHasFightTargets($x, $y) And IsPlayerAlive() And TimerDiff($clearTimer) < 90000
			FeathersSinCsvWrite('spot_not_clear', 'foes=' & FeathersSinCountSpotFoesAt($x, $y, $FEATHERS_SIN_AGGRO_RANGE) & ';local=' & FeathersSinCountCombatFoes(GetMyAgent()))
			Move($x, $y)
			If FeathersSinKill(False, $x, $y) == $FAIL Then Return $FAIL
			If FeathersSinPostKillWait() == $FAIL Then Return $FAIL
		WEnd

		; Final filtered pickup pass after spot-clear confirmation.
		FeathersSinCsvWrite('spot_final_loot')
		FeathersSinLootBurst()
	EndIf
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func FeathersSinKill($waitForSettle = True, $spotX = 0, $spotY = 0)
	Local $deadlock
	Local $timeout = 2 * 60 * 1000
	FeathersSinCsvWrite('kill_start', 'waitForSettle=' & $waitForSettle)

	CheckAndSendStuckCommand()
	If $waitForSettle Then
		If Not FeathersSinWaitForSettle() Then
			; Do not abort the run if settle check is flaky, continue with direct engage.
			FeathersSinCsvWrite('kill_settle_skipped')
		EndIf
	EndIf

	Local $target = FeathersSinGetDarkfeatherTarget($FEATHERS_SIN_AGGRO_RANGE)
	If $target == Null Then $target = FeathersSinGetNearestAggroTarget()
	If $target <> Null Then ChangeTarget($target)

	; Ball around darkfeather by auto-attacking with caster sword for 6s.
	Local $ballTimer = TimerInit()
	While TimerDiff($ballTimer) < 6000 And IsPlayerAlive()
		FeathersSinMaintainPerma()
		If $target <> Null Then Attack($target)
		FeathersSinCsvHeartbeat('balling')
		Sleep(140)
	WEnd

	FeathersSinTrySpike($target, 'first')
	FeathersSinMaintainPerma()
	If FeathersSinChillAndRecover(2200) == $FAIL Then Return $FAIL
	$deadlock = TimerInit()
	While FeathersSinHasFightTargets($spotX, $spotY)
		FeathersSinCsvHeartbeat('kill_loop')
		If TimerDiff($deadlock) > $timeout Then
			FeathersSinCsvWrite('kill_timeout')
			Return $FAIL
		EndIf
		If IsPlayerDead() Then
			FeathersSinCsvWrite('kill_fail_dead')
			Return $FAIL
		EndIf

		FeathersSinMaintainPerma()
		$target = FeathersSinGetDarkfeatherTarget($FEATHERS_SIN_AGGRO_RANGE)
		If $target == Null Then $target = FeathersSinGetNearestAggroTarget()
		If $target <> Null Then
			ChangeTarget($target)
			Attack($target)
		ElseIf $spotX <> 0 Or $spotY <> 0 Then
			Move($spotX, $spotY)
		EndIf

		FeathersSinTrySpike($target, 'loop')
		FeathersSinMaintainPerma()
		If FeathersSinChillAndRecover(2200) == $FAIL Then Return $FAIL
		Sleep(180)
	WEnd

	; Never start looting while any target is still in local aggro or anchored spot range.
	Local $lootGuard = TimerInit()
	While FeathersSinHasFightTargets($spotX, $spotY) And IsPlayerAlive() And TimerDiff($lootGuard) < 12000
		FeathersSinCsvWrite('loot_blocked_combat', 'spot=' & FeathersSinCountKillFoes($spotX, $spotY) & ';local=' & FeathersSinCountCombatFoes(GetMyAgent()))
		FeathersSinMaintainPerma()
		$target = FeathersSinGetDarkfeatherTarget($FEATHERS_SIN_AGGRO_RANGE)
		If $target == Null Then $target = FeathersSinGetNearestAggroTarget()
		If $target <> Null Then
			ChangeTarget($target)
			Attack($target)
		EndIf
		Sleep(160)
	WEnd
	If FeathersSinStabilizePermaBeforeLoot(5000) == $FAIL Then Return $FAIL

	RandomSleep(500)
	FeathersSinCsvWrite('loot_start')
	Info('Looting')
	FeathersSinLootBurst()
	FindAndOpenChests()
	FeathersSinCsvWrite('loot_end')
	FeathersSinCsvWrite('kill_end')
	Return $SUCCESS
EndFunc


Func FeathersSinCastCombo($target)
	If IsPlayerDead() Then Return
	If Not FeathersSinIsFullComboReady() Then
		FeathersSinCsvWrite('combo_abort_not_ready')
		Return
	EndIf
	If FeathersSinCountSensaliAggro() == 0 Then
		FeathersSinCsvWrite('combo_abort_no_sensali')
		Return
	EndIf
	; Strict order requested: 4,5,6,7,8.
	$feathers_sin_combo_active = True
	If $target == Null Then $target = FeathersSinGetNearestAggroTarget()
	If $target <> Null Then
		ChangeTarget($target)
		Attack($target)
	Else
		FeathersSinCsvWrite('combo_target_missing')
		$feathers_sin_combo_active = False
		Return
	EndIf
	If Not FeathersSinWaitSkillReady($FEATHERS_SIN_GLYPH_LESSER, 900) Then
		$feathers_sin_combo_active = False
		FeathersSinCsvWrite('combo_abort_step', 'step=4')
		Return
	EndIf
	UseSkillEx($FEATHERS_SIN_GLYPH_LESSER)
	RandomSleep(120)
	If $target == Null Then $target = FeathersSinGetNearestAggroTarget()
	If $target <> Null Then ChangeTarget($target)
	If Not FeathersSinWaitSkillReady($FEATHERS_SIN_MARK, 900) Then
		$feathers_sin_combo_active = False
		FeathersSinCsvWrite('combo_abort_step', 'step=5')
		Return
	EndIf
	UseSkillEx($FEATHERS_SIN_MARK, $target)
	RandomSleep(120)
	If Not FeathersSinWaitSkillReady($FEATHERS_SIN_METEOR, 900) Then
		$feathers_sin_combo_active = False
		FeathersSinCsvWrite('combo_abort_step', 'step=6')
		Return
	EndIf
	UseSkillEx($FEATHERS_SIN_METEOR, $target)
	RandomSleep(120)
	If Not FeathersSinWaitSkillReady($FEATHERS_SIN_BED_OF_COALS, 900) Then
		$feathers_sin_combo_active = False
		FeathersSinCsvWrite('combo_abort_step', 'step=7')
		Return
	EndIf
	UseSkillEx($FEATHERS_SIN_BED_OF_COALS, $target)
	RandomSleep(120)
	If Not FeathersSinWaitSkillReady($FEATHERS_SIN_LAVA_FONT, 900) Then
		$feathers_sin_combo_active = False
		FeathersSinCsvWrite('combo_abort_step', 'step=8')
		Return
	EndIf
	UseSkillEx($FEATHERS_SIN_LAVA_FONT, $target)
	If $target <> Null Then Attack($target)
	$feathers_sin_combo_active = False
EndFunc


Func FeathersSinCanRunCombo()
	If FeathersSinCountSensaliAggro() == 0 Then Return False
	Local $sfRemaining = FeathersSinEstimatedSfRemainingMs()
	If $sfRemaining < FeathersSinRequiredSfForCombo() Then Return False
	If GetEnergy() < $FEATHERS_SIN_MIN_ENERGY_FOR_COMBO Then Return False
	If Not FeathersSinIsFullComboReady() Then Return False
	Return True
EndFunc


Func FeathersSinIsFullComboReady()
	Return IsRecharged($FEATHERS_SIN_GLYPH_LESSER) _
		And IsRecharged($FEATHERS_SIN_MARK) _
		And IsRecharged($FEATHERS_SIN_METEOR) _
		And IsRecharged($FEATHERS_SIN_BED_OF_COALS) _
		And IsRecharged($FEATHERS_SIN_LAVA_FONT)
EndFunc


Func FeathersSinRequiredSfForCombo()
	Local $required = $FEATHERS_SIN_MIN_SF_FOR_CHOREO_MS
	If $FEATHERS_SIN_COMBO_BUDGET_MS > $required Then $required = $FEATHERS_SIN_COMBO_BUDGET_MS
	$required += $FEATHERS_SIN_EXTRA_SF_MARGIN_MS
	Return $required
EndFunc


Func FeathersSinTrySpike($target, $phase)
	If IsPlayerDead() Then Return
	If FeathersSinCountSensaliAggro() == 0 Then
		FeathersSinCsvWrite('spike_skip_no_sensali', 'phase=' & $phase)
		Return
	EndIf

	Local $timer = TimerInit()
	Local $maxWait = 7000
	While Not FeathersSinCanRunCombo() And IsPlayerAlive() And TimerDiff($timer) < $maxWait
		FeathersSinCsvWrite('combo_gate_waiting', 'phase=' & $phase & ';e=' & GetEnergy())
		FeathersSinMaintainPerma()

		; Never cast GoS alone here. Only pair it with SF when SF is ready.
		If IsRecharged($FEATHERS_SIN_SHADOW_FORM) Then
			If IsRecharged($FEATHERS_SIN_GLYPH_SWIFTNESS) Then UseSkillEx($FEATHERS_SIN_GLYPH_SWIFTNESS)
			RandomSleep(60)
			UseSkillEx($FEATHERS_SIN_SHADOW_FORM)
			FeathersSinSyncSfCycleTimer()
			FeathersSinCsvWrite('sf_recast_done', 'source=pre_spike')
		EndIf

		If $target == Null Then $target = FeathersSinGetNearestAggroTarget()
		If $target <> Null Then
			ChangeTarget($target)
			Attack($target)
		EndIf
		Sleep(140)
	WEnd

	If FeathersSinCanRunCombo() Then
		FeathersSinCsvWrite('combo_start', 'phase=' & $phase)
		FeathersSinCastCombo($target)
		FeathersSinCsvWrite('combo_end', 'phase=' & $phase)
	Else
		Local $sfNow = FeathersSinEstimatedSfRemainingMs()
		Local $sfNeed = FeathersSinRequiredSfForCombo()
		FeathersSinCsvWrite('combo_gate_wait', 'phase=' & $phase & ';sf=' & $sfNow & ';required=' & $sfNeed & ';e=' & GetEnergy())
	EndIf
EndFunc


Func FeathersSinCleanupDamage($target)
	; Disabled by design: simplified run uses only perma loop and full combo spike.
 	Return
EndFunc


Func FeathersSinCountCombatFoes($me)
	If $me == Null Then $me = GetMyAgent()
	Local $sensali = CountFoesInRangeOfAgent($me, 1200, FeathersSinIsSensali)
	If $sensali > 0 Then Return $sensali
	Return CountFoesInRangeOfAgent($me, 1200)
EndFunc


Func FeathersSinCountSpotFoes($range = 1600)
	Local $me = GetMyAgent()
	Local $sensali = CountFoesInRangeOfAgent($me, $range, FeathersSinIsSensali)
	If $sensali > 0 Then Return $sensali
	Return CountFoesInRangeOfAgent($me, $range)
EndFunc


Func FeathersSinCountSpotFoesAt($x, $y, $range = $FEATHERS_SIN_AGGRO_RANGE)
	Local $me = GetMyAgent()
	Local $count = 0
	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop
		If Not FeathersSinIsSensali($agent) Then ContinueLoop
		If GetDistanceToPoint($agent, $x, $y) > $range Then ContinueLoop
		$count += 1
	Next
	If $count > 0 Then Return $count
	; Fallback in case model IDs are missing for rare foes near spot.
	If GetDistanceToPoint($me, $x, $y) <= $range Then Return CountFoesInRangeOfAgent($me, $range)
	Return 0
EndFunc


Func FeathersSinCountKillFoes($spotX, $spotY)
	If $spotX <> 0 Or $spotY <> 0 Then Return FeathersSinCountSpotFoesAt($spotX, $spotY, $FEATHERS_SIN_AGGRO_RANGE)
	Return FeathersSinCountCombatFoes(GetMyAgent())
EndFunc


Func FeathersSinHasFightTargets($spotX = 0, $spotY = 0)
	; User-expected behavior: only keep fighting while Sensali are in current aggro bubble.
	Return FeathersSinCountSensaliAggro() > 0
EndFunc


Func FeathersSinCountSensaliAggro($range = $FEATHERS_SIN_AGGRO_RANGE)
	Return CountFoesInRangeOfAgent(GetMyAgent(), $range, FeathersSinIsSensali)
EndFunc


Func FeathersSinChillAndRecover($waitMs = 2200)
	Local $timer = TimerInit()
	FeathersSinCsvWrite('recover_start', 'wait=' & $waitMs)
	Local $sfRemaining = FeathersSinEstimatedSfRemainingMs()
	If $sfRemaining <= ($FEATHERS_SIN_SF_RECAST_THRESHOLD_MS + 1000) Then
		FeathersSinCsvWrite('recover_skip_sf_guard', 'sf=' & $sfRemaining)
		Return IsPlayerAlive() ? $SUCCESS : $FAIL
	EndIf
	While TimerDiff($timer) < $waitMs And IsPlayerAlive()
		FeathersSinMaintainPerma()
		FeathersSinCsvHeartbeat('recover')
		$sfRemaining = FeathersSinEstimatedSfRemainingMs()
		If $sfRemaining <= ($FEATHERS_SIN_SF_RECAST_THRESHOLD_MS + 1000) Then ExitLoop
		If CountFoesInRangeOfAgent(GetMyAgent(), 1200, FeathersSinIsSensali) == 0 Then ExitLoop
		If GetEnergy() >= $FEATHERS_SIN_ENERGY_RESERVE Then ExitLoop
		Sleep(140)
	WEnd
	FeathersSinCsvWrite('recover_end')
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func FeathersSinPostKillWait()
	Local $timer = TimerInit()
	While TimerDiff($timer) < $FEATHERS_SIN_POST_KILL_WAIT_MS And IsPlayerAlive()
		FeathersSinMaintainPerma()
		If CountFoesInRangeOfAgent(GetMyAgent(), 1200, FeathersSinIsSensali) > 0 Then
			; New adds entered bubble; stop waiting and continue normal logic.
			Return $SUCCESS
		EndIf
		Sleep(200)
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func FeathersSinLootBurst()
 	For $i = 1 To 7
		FeathersSinMaintainPerma()
		PickUpItems()
		RandomSleep(180)
	Next
	FeathersSinMaintainPerma()
	PickUpItems()
EndFunc


Func FeathersSinMaintainPerma()
	If IsPlayerDead() Then Return
	Local $cycleAge = TimerDiff($feathers_sin_sf_cycle_timer)
	If $feathers_sin_combo_active And $cycleAge < ($FEATHERS_SIN_SF_RECAST_MAX_MS - 6500) Then Return
	Local $sfReady = IsRecharged($FEATHERS_SIN_SHADOW_FORM)
	Local $sfRemaining = FeathersSinEstimatedSfRemainingMs()
	Local $forceSfRefresh = ($sfReady And $sfRemaining <= $FEATHERS_SIN_SF_REFRESH_BUFFER_MS)
	Local $sfEffectRemaining = FeathersSinGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP)
	If $sfReady And $sfEffectRemaining > 0 And $sfEffectRemaining <= 1800 Then $forceSfRefresh = True

	; Pre-cast GoS shortly before SF is recharged so SF can fire immediately when ready.
	If (Not $sfReady) And $sfRemaining <= $FEATHERS_SIN_SF_PRECAST_GOS_MS And IsRecharged($FEATHERS_SIN_GLYPH_SWIFTNESS) Then
		UseSkillEx($FEATHERS_SIN_GLYPH_SWIFTNESS)
		FeathersSinCsvWrite('gos_precast', 'sf=' & $sfRemaining)
	EndIf

	If $sfReady And $forceSfRefresh Then
		FeathersSinCsvWrite('sf_recast_start', 'force=' & $forceSfRefresh & ';sf=' & $sfRemaining)
		If IsRecharged($FEATHERS_SIN_GLYPH_SWIFTNESS) And $sfRemaining > 900 Then UseSkillEx($FEATHERS_SIN_GLYPH_SWIFTNESS)
		RandomSleep(60)
		UseSkillEx($FEATHERS_SIN_SHADOW_FORM)
		FeathersSinSyncSfCycleTimer()
		FeathersSinCsvWrite('sf_recast_done')
	EndIf

	Local $sodRemaining = FeathersSinGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)
	If $sodRemaining <= 2500 Or DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.6 Then
		If IsRecharged($FEATHERS_SIN_SHROUD) Then UseSkillEx($FEATHERS_SIN_SHROUD)
	EndIf
EndFunc


Func FeathersSinGetBestEffectTimeRemaining($skillID1, $skillID2 = 0)
	Local $v1 = FeathersSinNormalizeEffectTimeMs(GetEffectTimeRemaining($skillID1))
	If $skillID2 == 0 Then Return $v1
	Local $v2 = FeathersSinNormalizeEffectTimeMs(GetEffectTimeRemaining($skillID2))
	Return $v2 > $v1 ? $v2 : $v1
EndFunc


Func FeathersSinNormalizeEffectTimeMs($value)
	If $value <= 0 Then Return 0
	; Some APIs report effect time in seconds; normalize to milliseconds for all gating constants.
	If $value < 100 Then Return Int($value * 1000)
	Return Int($value)
EndFunc


Func FeathersSinCsvInit()
	Local $timestamp = @YEAR & @MON & @MDAY & '_' & @HOUR & @MIN & @SEC
	$feathers_sin_csv_file = @ScriptDir & '/logs/feathers_sin_debug-' & GetCharacterName() & '-run' & $feathers_sin_run_number & '-' & $timestamp & '.csv'
	$feathers_sin_csv_handle = FileOpen($feathers_sin_csv_file, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	$feathers_sin_csv_timer = TimerInit()
	$feathers_sin_csv_heartbeat_timer = TimerInit()
	Info('FeathersSin CSV: ' & $feathers_sin_csv_file)
	If $feathers_sin_csv_handle == -1 Then Return
	FileWriteLine($feathers_sin_csv_handle, 'time_ms;run;event;sf_ms;sod_ms;cycle_ms;energy;hp;map_id;foes_total;foes_sensali;darkfeather;claw;cutter;darkfeather_dist;s1_ready;s2_ready;s3_ready;s4_ready;s5_ready;s6_ready;s7_ready;s8_ready;x;y;note')
EndFunc


Func FeathersSinCsvClose()
	If $feathers_sin_csv_handle == -1 Then Return
	FileClose($feathers_sin_csv_handle)
	$feathers_sin_csv_handle = -1
EndFunc


Func FeathersSinCsvWrite($eventName, $note = '')
	If $feathers_sin_csv_handle == -1 Then Return
	Local $timeMs = Int(TimerDiff($feathers_sin_csv_timer))
	Local $sfRemaining = FeathersSinEstimatedSfRemainingMs()
	Local $sodRemaining = FeathersSinGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)
	Local $cycleAge = Int(TimerDiff($feathers_sin_sf_cycle_timer))
	Local $me = GetMyAgent()
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')
	Local $energy = GetEnergy()
	Local $hp = DllStructGetData($me, 'HealthPercent')
	Local $mapID = GetMapID()
	Local $foesTotal = CountFoesInRangeOfAgent($me, 1200)
	Local $foesSensali = CountFoesInRangeOfAgent($me, 1200, FeathersSinIsSensali)
	Local $darkfeatherCount = FeathersSinCountFoesByModel($me, $FEATHERS_SIN_MODELID_SENSALI_DARKFEATHER)
	Local $clawCount = FeathersSinCountFoesByModel($me, $FEATHERS_SIN_MODELID_SENSALI_CLAW)
	Local $cutterCount = FeathersSinCountFoesByModel($me, $FEATHERS_SIN_MODELID_SENSALI_CUTTER)
	Local $darkfeather = FeathersSinGetDarkfeatherTarget()
	Local $darkfeatherDistance = -1
	If $darkfeather <> Null Then $darkfeatherDistance = Int(GetDistance($me, $darkfeather))
	Local $s1 = IsRecharged($FEATHERS_SIN_GLYPH_SWIFTNESS)
	Local $s2 = IsRecharged($FEATHERS_SIN_SHADOW_FORM)
	Local $s3 = IsRecharged($FEATHERS_SIN_SHROUD)
	Local $s4 = IsRecharged($FEATHERS_SIN_GLYPH_LESSER)
	Local $s5 = IsRecharged($FEATHERS_SIN_MARK)
	Local $s6 = IsRecharged($FEATHERS_SIN_METEOR)
	Local $s7 = IsRecharged($FEATHERS_SIN_BED_OF_COALS)
	Local $s8 = IsRecharged($FEATHERS_SIN_LAVA_FONT)
	Local $safeNote = StringReplace($note, ';', ',')
	FileWriteLine($feathers_sin_csv_handle, $timeMs & ';' & $feathers_sin_run_number & ';' & $eventName & ';' & $sfRemaining & ';' & $sodRemaining & ';' & $cycleAge & ';' & $energy & ';' & $hp & ';' & $mapID & ';' & $foesTotal & ';' & $foesSensali & ';' & $darkfeatherCount & ';' & $clawCount & ';' & $cutterCount & ';' & $darkfeatherDistance & ';' & $s1 & ';' & $s2 & ';' & $s3 & ';' & $s4 & ';' & $s5 & ';' & $s6 & ';' & $s7 & ';' & $s8 & ';' & $x & ';' & $y & ';' & $safeNote)
EndFunc


Func FeathersSinCsvHeartbeat($context, $intervalMs = 500)
	If TimerDiff($feathers_sin_csv_heartbeat_timer) < $intervalMs Then Return
	FeathersSinCsvWrite('state', $context)
	$feathers_sin_csv_heartbeat_timer = TimerInit()
EndFunc


Func FeathersSinCountFoesByModel($me, $modelID, $range = 1200)
	Local $count = 0
	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop
		If DllStructGetData($agent, 'ModelID') <> $modelID Then ContinueLoop
		If GetDistance($me, $agent) > $range Then ContinueLoop
		$count += 1
	Next
	Return $count
EndFunc


Func FeathersSinWaitForSettle($timeout = 9000)
	Local $me = GetMyAgent()
	Local $target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
	Local $deadlock = TimerInit()

	While CountFoesInRangeOfAgent($me, 900, FeathersSinIsSensali) == 0 And TimerDiff($deadlock) < 5000
		If IsPlayerDead() Then Return False
		FeathersSinMaintainPerma()
		Sleep(200)
		$me = GetMyAgent()
		$target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
	WEnd

	If CountFoesInRangeOfAgent($me, 900, FeathersSinIsSensali) == 0 Then Return False

	$deadlock = TimerInit()
	While $target <> Null And GetDistance($me, $target) > $RANGE_NEARBY And TimerDiff($deadlock) < $timeout
		If IsPlayerDead() Then Return False
		FeathersSinMaintainPerma()
		Sleep(200)
		$me = GetMyAgent()
		$target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
	WEnd
	Return True
EndFunc


Func FeathersSinGetDarkfeatherTarget($maxRange = $FEATHERS_SIN_AGGRO_RANGE)
	Local $me = GetMyAgent()
	Local $nearest = Null
	Local $nearestDistance = 100000000
	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		If DllStructGetData($agent, 'ModelID') <> $FEATHERS_SIN_MODELID_SENSALI_DARKFEATHER Then ContinueLoop
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then ContinueLoop
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


Func FeathersSinGetNearestAggroTarget($maxRange = $FEATHERS_SIN_AGGRO_RANGE)
	Local $me = GetMyAgent()
	Local $nearest = Null
	Local $nearestDistance = 100000000
	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop
		If Not FeathersSinIsSensali($agent) Then ContinueLoop
		Local $distance = GetDistance($me, $agent)
		If $distance > $maxRange Then ContinueLoop
		If $distance < $nearestDistance Then
			$nearestDistance = $distance
			$nearest = $agent
		EndIf
	Next
	Return $nearest
EndFunc


Func FeathersSinIsSensali($agent)
	Local $modelID = DllStructGetData($agent, 'ModelID')
	Return $modelID == $FEATHERS_SIN_MODELID_SENSALI_CLAW _
		Or $modelID == $FEATHERS_SIN_MODELID_SENSALI_DARKFEATHER _
		Or $modelID == $FEATHERS_SIN_MODELID_SENSALI_CUTTER
EndFunc


Func FeathersSinEstimatedSfRemainingMs()
	Local $remaining = Int($FEATHERS_SIN_SF_RECAST_MAX_MS - TimerDiff($feathers_sin_sf_cycle_timer) - $FEATHERS_SIN_SF_EARLY_OFFSET_MS)
	If $remaining < 0 Then Return 0
	Return $remaining
EndFunc


Func FeathersSinSyncSfCycleTimer()
	Local $t = TimerInit()
	While TimerDiff($t) < 1200 And IsPlayerAlive()
		If FeathersSinGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP) > 0 Then ExitLoop
		Sleep(40)
	WEnd
	$feathers_sin_sf_cycle_timer = TimerInit()
EndFunc


Func FeathersSinStabilizePermaBeforeLoot($maxWaitMs = 5000)
	Local $timer = TimerInit()
	While IsPlayerAlive() And TimerDiff($timer) < $maxWaitMs
		FeathersSinMaintainPerma()
		Local $sfRemaining = FeathersSinEstimatedSfRemainingMs()
		If $sfRemaining >= 12000 Then Return $SUCCESS
		Sleep(120)
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func FeathersSinWaitSkillReady($slot, $maxWaitMs = 900)
	Local $waitTimer = TimerInit()
	While Not IsRecharged($slot) And IsPlayerAlive() And TimerDiff($waitTimer) < $maxWaitMs
		FeathersSinMaintainPerma()
		Sleep(60)
	WEnd
	Return IsRecharged($slot)
EndFunc