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
#include '../utilities/SupportTeam.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $WARDEN_PLAYER_SKILLBAR = 'OQMT844QZqe4ualIXsvgmcHUeAA'
Global Const $WARDEN_MORGAHN_SKILLBAR = 'OQijEqmMKODbe8O2Efjrx0bWMA'
Global Const $WARDEN_FARM_INFORMATIONS = 'Warden Farm (Arborstone explorables) for W/Me.' & @CRLF _
	& 'Flow:' & @CRLF _
	& '- Altrumm Ruins -> Arborstone explorables' & @CRLF _
	& '- Maintain Protective Spirit on recharge' & @CRLF _
	& '- Alternate Shield of Absorption / Shielding Hands while kiting' & @CRLF _
	& '- Pull and split Warden Warriors/Casters then spike with EBSOH + Hundred Blades + Whirlwind'
Global Const $WARDEN_FARM_DURATION = 3 * 60 * 1000
Global Const $WARDEN_MAX_CLEAR_MS = 105000
Global Const $WARDEN_MAX_MOVE_MS = 45000
Global Const $WARDEN_MIN_STACK_FOES = 7
Global Const $WARDEN_FIRST_STACK_LEAD_FOES = 3
Global Const $WARDEN_THIRD_GROUP_MIN_FOES = 10
Global Const $WARDEN_THIRD_GROUP_WAIT_MS = 12000
Global Const $WARDEN_THIRD_GROUP_PULSE_MS = 850
Global Const $WARDEN_THIRD_GROUP_RETREAT_MS = 2800
Global Const $WARDEN_THIRD_GROUP_SPIKE_DELTA = 2
Global Const $WARDEN_THIRD_GROUP_CONFIRM_TICKS = 3
Global Const $WARDEN_WAIT_STACK_MS = 18000
Global Const $WARDEN_PS_RECAST_BUFFER_MS = 1000
Global Const $WARDEN_SHIELD_RECAST_BUFFER_MS = 1900
Global Const $WARDEN_PS_DURATION_MS = 22800
Global Const $WARDEN_SOA_DURATION_MS = 7200
Global Const $WARDEN_SH_DURATION_MS = 9600
Global Const $WARDEN_CAST_MIN_GAP_MS = 450
Global Const $WARDEN_SHIELD_EXPIRE_GRACE_MS = 350
Global Const $WARDEN_IAU_RECAST_AT_MS = 1
Global Const $WARDEN_IAU_RECAST_LATE_MS = 1
Global Const $WARDEN_PS_URGENT_MS = 1400
Global Const $WARDEN_SHIELD_URGENT_MS = 900
Global Const $WARDEN_DEBUG_LOOP_LOG_ENABLED = True
Global Const $WARDEN_DEBUG_HEARTBEAT_MS = 250

Global Const $WARDEN_PROTECTIVE_SPIRIT = 1
Global Const $WARDEN_SHIELD_OF_ABSORPTION = 2
Global Const $WARDEN_SHIELDING_HANDS = 3
Global Const $WARDEN_EBSOH = 4
Global Const $WARDEN_HUNDRED_BLADES = 5
Global Const $WARDEN_IAU = 6
Global Const $WARDEN_WHIRLWIND = 7
Global Const $WARDEN_BALTHAZARS = 8

Global Const $WARDEN_MORGAHN_INCOMING = 2
Global Const $WARDEN_MORGAHN_ENDURING = 4

Global Const $WARDEN_HERO_PARTY_ID = $ID_GENERAL_MORGAHN
Global Const $WARDEN_PORTAL_X = 5994
Global Const $WARDEN_PORTAL_Y = 7232
Global Const $WARDEN_BOOST_HERO_X = 9530
Global Const $WARDEN_BOOST_HERO_Y = -19900
Global Const $WARDEN_TURN_BREAKOUT_1_X = 10380
Global Const $WARDEN_TURN_BREAKOUT_1_Y = -16980
Global Const $WARDEN_TURN_BREAKOUT_2_X = 11240
Global Const $WARDEN_TURN_BREAKOUT_2_Y = -16240
Global Const $WARDEN_TURN_BREAKOUT_3_X = 12244
Global Const $WARDEN_TURN_BREAKOUT_3_Y = -15386
Global Const $WARDEN_TURN_BREAKOUT_2_ALT1_X = 11040
Global Const $WARDEN_TURN_BREAKOUT_2_ALT1_Y = -16680
Global Const $WARDEN_TURN_BREAKOUT_2_ALT2_X = 11460
Global Const $WARDEN_TURN_BREAKOUT_2_ALT2_Y = -16510
Global Const $WARDEN_TURN_BREAKOUT_2_ALT3_X = 11280
Global Const $WARDEN_TURN_BREAKOUT_2_ALT3_Y = -15980
Global Const $WARDEN_CASTER_CHOREO_X = 12558
Global Const $WARDEN_CASTER_CHOREO_Y = -15160
Global Const $WARDEN_CASTER_CHOREO_ENEMY_DIST = 230
Global Const $WARDEN_CASTER_CHOREO_SPOT_RADIUS = 180

Global $warden_farm_setup = False
Global $warden_shield_active_slot = 0
Global $warden_defense_loop_active = False
Global $warden_morgahn_index_cache = 0
Global $warden_iau_last_cast_timer = 0
Global $warden_ps_last_cast_timer = 0
Global $warden_shield_last_cast_timer = 0
Global $warden_debug_log_handle = -1
Global $warden_debug_log_timer = 0
Global $warden_debug_heartbeat_timer = 0
Global $warden_debug_run_number = 0
Global $warden_gap_ps_active = False
Global $warden_gap_shield_active = False


Func WardenFarm()
	$warden_debug_run_number += 1
	WardenDebugLogInit()
	WardenDebugLog('run_start')

	If Not $warden_farm_setup And SetupWardenFarm() == $FAIL Then Return $PAUSE

	If GoToArborstoneExplorable() == $FAIL Then
		WardenDebugLog('run_end', 'result=fail;reason=zone_in')
		WardenDebugLogClose()
		Return $FAIL
	EndIf
	Local $result = WardenFarmLoop()
	WardenDebugLog('run_end', 'result=' & $result)
	WardenDebugLogClose()
	ResignAndReturnToOutpost($ID_ALTRUMM_RUINS)
	Return $result
EndFunc


Func SetupWardenFarm()
	Info('Setting up Warden Farm')
	If TravelToOutpost($ID_ALTRUMM_RUINS, $district_name) == $FAIL Then Return $FAIL
	SwitchToHardModeIfEnabled()
	; Debug mode: keep manual player/hero setup and skip auto setup.
	;If SetupPlayerWardenFarm() == $FAIL Then Return $FAIL
	;If SetupTeamWardenFarm() == $FAIL Then Return $FAIL
	$warden_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerWardenFarm()
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_WARRIOR Then
		Warn('Warden Farm should run as Warrior primary')
		Return $FAIL
	EndIf
	LoadSkillTemplate($WARDEN_PLAYER_SKILLBAR)
	RandomSleep(250)
	Return $SUCCESS
EndFunc


Func SetupTeamWardenFarm()
	If IsTeamAutoSetup() Then Return $SUCCESS

	If WardenEnsureSoloParty() == $FAIL Then Return $FAIL
	$warden_morgahn_index_cache = 0
	If AddHeroByProfession($ID_PARAGON, $WARDEN_HERO_PARTY_ID) == $FAIL Then
		Warn('Could not add General Morgahn to team')
		Return $FAIL
	EndIf
	RandomSleep(250)
	LoadSkillTemplate($WARDEN_MORGAHN_SKILLBAR, 1)
	RandomSleep(250)
	DisableAllHeroSkills(1)
	RandomSleep(200)

	If GetPartySize() <> 2 Then
		Warn('Warden team setup failed. Team size=' & GetPartySize())
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func WardenEnsureSoloParty($maxWaitMs = 9000)
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
	Warn('Warden team setup: party reset timeout. Party=' & GetPartySize() & ', heroes=' & GetHeroCount())
	Return $FAIL
EndFunc


Func GoToArborstoneExplorable()
	If TravelToOutpost($ID_ALTRUMM_RUINS, $district_name) == $FAIL Then Return $FAIL
	While GetMapID() <> $ID_ARBORSTONE_EXPLORABLE
		Info('Moving to Arborstone explorable')
		MoveTo(5600, 7000)
		Move($WARDEN_PORTAL_X, $WARDEN_PORTAL_Y)
		RandomSleep(1500)
		If WaitMapLoading($ID_ARBORSTONE_EXPLORABLE, 10000, 1500) Then ExitLoop
	WEnd
	Return GetMapID() == $ID_ARBORSTONE_EXPLORABLE ? $SUCCESS : $FAIL
EndFunc


Func WardenFarmLoop()
	If GetMapID() <> $ID_ARBORSTONE_EXPLORABLE Then Return $FAIL

	$warden_defense_loop_active = False
	$warden_shield_active_slot = 0
	$warden_iau_last_cast_timer = 0
	$warden_ps_last_cast_timer = 0
	$warden_shield_last_cast_timer = 0
	WardenApplyMorgahnBoost()

	; Entry cast from the successful recording.
	If WardenCastOpeningBalthazarSpirit() == $FAIL Then Return $FAIL

	If WardenMoveMaintainingDefense(10933, -16717, 55000, False) == $FAIL Then Return $FAIL
	If WardenWaitForFirstStack() == $FAIL Then Return $FAIL

	UseSkillEx($WARDEN_PROTECTIVE_SPIRIT, GetMyAgent())
	WardenDebugLog('cast_ps', 'reason=opening')
	$warden_ps_last_cast_timer = TimerInit()
	RandomSleep(120)
	UseSkillEx($WARDEN_SHIELD_OF_ABSORPTION, GetMyAgent())
	WardenDebugLog('cast_soa', 'reason=opening')
	$warden_shield_last_cast_timer = TimerInit()
	RandomSleep(120)
	UseSkillEx($WARDEN_IAU)
	WardenDebugLog('cast_iau', 'reason=opening')
	$warden_iau_last_cast_timer = TimerInit()
	RandomSleep(120)
	$warden_shield_active_slot = $WARDEN_SHIELD_OF_ABSORPTION
	$warden_defense_loop_active = True
	$warden_gap_ps_active = False
	$warden_gap_shield_active = False

	If WardenGatherThirdGroupAndPreventBodyblock() == $FAIL Then Return $FAIL
	If WardenBreakOutToTurnSpot() == $FAIL Then Return $FAIL
	If WardenMoveMaintainingDefense(13895, -14531, $WARDEN_MAX_MOVE_MS) == $FAIL Then Return $FAIL
	If WardenMoveMaintainingDefense(12806, -14954, $WARDEN_MAX_MOVE_MS) == $FAIL Then Return $FAIL
	If WardenRepositionForCasterChoreo() == $FAIL Then Return $FAIL
	If WardenPrimeFreshShieldAtKillSpot() == $FAIL Then Return $FAIL

	If WardenUseKillChoreography() == $FAIL Then Return $FAIL
	If WardenFightUntilClear($WARDEN_MAX_CLEAR_MS) == $FAIL Then Return $FAIL

	RandomSleep(500)
	PickUpItems()
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func WardenCastOpeningBalthazarSpirit()
	Local $me = GetMyAgent()
	If $me == Null Then Return $FAIL

	For $attempt = 1 To 4
		If IsRecharged($WARDEN_BALTHAZARS) Then
			UseSkillEx($WARDEN_BALTHAZARS, $me)
			WardenDebugLog('cast_balthazar', 'reason=opening')
			RandomSleep(220)
		EndIf

		If GetEffect($ID_BALTHAZARS_SPIRIT) <> Null Then Return $SUCCESS
		RandomSleep(140)
	Next

	Warn('Warden opening: could not apply Balthazar''s Spirit before movement')
	Return $FAIL
EndFunc

Func WardenTryRecastIaU($reason = 'recast_cycle')
	If Not $warden_defense_loop_active Then Return False
	If $warden_iau_last_cast_timer == 0 Then Return False
	If TimerDiff($warden_iau_last_cast_timer) < $WARDEN_IAU_RECAST_AT_MS Then Return False
	If Not WardenIsSkillReadyNow($WARDEN_IAU) Then Return False

	; IaU is a shout: fire non-blocking so defensive casts never stall this recast.
	If Not WardenUseSkillInstant($WARDEN_IAU) Then Return False
	WardenDebugLog('cast_iau', 'reason=' & $reason & ';mode=instant')
	$warden_iau_last_cast_timer = TimerInit()
	Return True
EndFunc


Func WardenUseSkillInstant($skillSlot, $target = Null)
	If IsPlayerDead() Then Return False
	If Not WardenIsSkillReadyNow($skillSlot) Then Return False

	Local $skillID = GetSkillbarSkillID($skillSlot)
	If $skillID == 0 Then Return False

	Local $skill = GetSkillByID($skillID)
	Local $energy = StringReplace(StringReplace(StringReplace(StringMid(DllStructGetData($skill, 'Unknown4'), 6, 1), 'C', '25'), 'B', '15'), 'A', '10')
	If GetEnergy() < $energy Then Return False

	UseSkill($skillSlot, $target)
	Return True
EndFunc


Func WardenIsSkillReadyNow($skillSlot)
	Local $skillbar = GetSkillbar()
	If $skillbar == Null Then Return False

	Local $recharge = DllStructGetData($skillbar, 'Recharge' & $skillSlot)
	If $recharge == 0 Then Return True
	Return ($recharge - GetSkillTimer()) <= 0
EndFunc


Func WardenWaitForFirstStack()
	Local $timer = TimerInit()
	Local $triggerFoes = $WARDEN_MIN_STACK_FOES - $WARDEN_FIRST_STACK_LEAD_FOES
	If $triggerFoes < 1 Then $triggerFoes = 1
	While TimerDiff($timer) < $WARDEN_WAIT_STACK_MS
		If IsPlayerDead() Then Return $FAIL
		WardenMaintainDefense()
		If CountFoesInRangeOfAgent(GetMyAgent(), 1200) >= $triggerFoes Then Return $SUCCESS
		WardenSleepWithIaUPulse(120)
	WEnd
	; Continue with whatever aggro we have to avoid deadlocks.
	Return $SUCCESS
EndFunc


Func WardenGatherThirdGroupAndPreventBodyblock()
	Local $timer = TimerInit()
	Local $pulseTimer = 0
	Local $stepToggle = False
	Local $baseFoes = CountFoesInRangeOfAgent(GetMyAgent(), 1300)
	Local $peakFoes = $baseFoes
	Local $spikeConfirmTicks = 0

	; First seconds: enforce short retreat/side pulses so first two groups cannot clamp the player.
	While TimerDiff($timer) < $WARDEN_THIRD_GROUP_RETREAT_MS
		If IsPlayerDead() Then Return $FAIL
		WardenMaintainDefense()

		If $pulseTimer == 0 Or TimerDiff($pulseTimer) >= $WARDEN_THIRD_GROUP_PULSE_MS Then
			If $stepToggle Then
				Move(10480, -16860)
			Else
				Move(10820, -16520)
			EndIf
			$stepToggle = Not $stepToggle
			$pulseTimer = TimerInit()
		EndIf

		WardenSleepWithIaUPulse(110)
	WEnd

	While TimerDiff($timer) < $WARDEN_THIRD_GROUP_WAIT_MS
		If IsPlayerDead() Then Return $FAIL
		WardenMaintainDefense()

		Local $foes = CountFoesInRangeOfAgent(GetMyAgent(), 1300)
		If $foes > $peakFoes Then $peakFoes = $foes

		; Only a sustained spike over initial aggro counts as third-group arrival.
		If $foes >= ($baseFoes + $WARDEN_THIRD_GROUP_SPIKE_DELTA) Then
			$spikeConfirmTicks += 1
		Else
			$spikeConfirmTicks = 0
		EndIf

		If $spikeConfirmTicks >= $WARDEN_THIRD_GROUP_CONFIRM_TICKS Then
			Info('Third group reached aggro range (foes=' & $foes & ', base=' & $baseFoes & ', ticks=' & $spikeConfirmTicks & '). Starting turn-run now')
			Return $SUCCESS
		EndIf

		If $pulseTimer == 0 Or TimerDiff($pulseTimer) >= $WARDEN_THIRD_GROUP_PULSE_MS Then
			If $stepToggle Then
				; Keep a slight retreat rhythm to avoid getting boxed in.
				Move(10540, -16720)
			Else
				; Small forward pulse toward third-group approach line.
				Move(11180, -16260)
			EndIf
			$stepToggle = Not $stepToggle
			$pulseTimer = TimerInit()
		EndIf

		WardenSleepWithIaUPulse(110)
	WEnd

	Info('Third-group wait timed out (base=' & $baseFoes & ', peak=' & $peakFoes & '), proceeding to turn-run anyway')
	; Continue even if third group count wasn't fully observed; avoids deadlock.
	Return $SUCCESS
EndFunc

Func WardenBreakOutToTurnSpot()
	; Forced short breakout pulses before the long turn run to avoid getting stuck in a clamp.
	If WardenMoveMaintainingDefense($WARDEN_TURN_BREAKOUT_1_X, $WARDEN_TURN_BREAKOUT_1_Y, 5000, False) == $FAIL Then Return $FAIL
	If WardenMoveWithFallbacks($WARDEN_TURN_BREAKOUT_2_X, $WARDEN_TURN_BREAKOUT_2_Y, 6000, False) == $FAIL Then Return $FAIL
	If WardenMoveMaintainingDefense($WARDEN_TURN_BREAKOUT_3_X, $WARDEN_TURN_BREAKOUT_3_Y, 6000, False) == $FAIL Then Return $FAIL
	Return WardenMoveMaintainingDefense($WARDEN_CASTER_CHOREO_X, $WARDEN_CASTER_CHOREO_Y, $WARDEN_MAX_MOVE_MS)
EndFunc


Func WardenMoveWithFallbacks($primaryX, $primaryY, $timeoutMs, $requireAggro)
	If WardenMoveMaintainingDefense($primaryX, $primaryY, $timeoutMs, $requireAggro) == $SUCCESS Then Return $SUCCESS

	WardenDebugLog('breakout_fallback', 'stage=2;target=alt1')
	If WardenMoveMaintainingDefense($WARDEN_TURN_BREAKOUT_2_ALT1_X, $WARDEN_TURN_BREAKOUT_2_ALT1_Y, 5200, False) == $SUCCESS Then Return $SUCCESS

	WardenDebugLog('breakout_fallback', 'stage=2;target=alt2')
	If WardenMoveMaintainingDefense($WARDEN_TURN_BREAKOUT_2_ALT2_X, $WARDEN_TURN_BREAKOUT_2_ALT2_Y, 5200, False) == $SUCCESS Then Return $SUCCESS

	WardenDebugLog('breakout_fallback', 'stage=2;target=alt3')
	If WardenMoveMaintainingDefense($WARDEN_TURN_BREAKOUT_2_ALT3_X, $WARDEN_TURN_BREAKOUT_2_ALT3_Y, 5200, False) == $SUCCESS Then Return $SUCCESS

	Return $FAIL
EndFunc


Func WardenRepositionForCasterChoreo($timeoutMs = 9000)
	Local $timer = TimerInit()
	Local $lastMovePulse = 0
	Local $atAnchor = False

	While TimerDiff($timer) < $timeoutMs
		If IsPlayerDead() Then Return $FAIL
		WardenMaintainDefense()

		If Not $atAnchor Then
			If GetDistanceToPoint(GetMyAgent(), $WARDEN_CASTER_CHOREO_X, $WARDEN_CASTER_CHOREO_Y) <= $WARDEN_CASTER_CHOREO_SPOT_RADIUS Then
				$atAnchor = True
			Else
				If $lastMovePulse == 0 Or TimerDiff($lastMovePulse) >= 450 Then
					Move($WARDEN_CASTER_CHOREO_X, $WARDEN_CASTER_CHOREO_Y)
					$lastMovePulse = TimerInit()
				EndIf
				WardenSleepWithIaUPulse(100)
				ContinueLoop
			EndIf
		EndIf

		Local $target = GetNearestEnemyToAgent(GetMyAgent())
		If $target <> Null And GetDistance(GetMyAgent(), $target) <= $WARDEN_CASTER_CHOREO_ENEMY_DIST Then
			WardenDebugLog('choreo_anchor_ready', 'distSpot=' & Int(GetDistanceToPoint(GetMyAgent(), $WARDEN_CASTER_CHOREO_X, $WARDEN_CASTER_CHOREO_Y)) & ';enemy=' & Int(GetDistance(GetMyAgent(), $target)))
			Return $SUCCESS
		EndIf

		If $lastMovePulse == 0 Or TimerDiff($lastMovePulse) >= 650 Then
			Move($WARDEN_CASTER_CHOREO_X, $WARDEN_CASTER_CHOREO_Y)
			$lastMovePulse = TimerInit()
		EndIf

		WardenSleepWithIaUPulse(110)
	WEnd

	Warn('Warden: could not get close enemy front for choreography start in time')
	Return $FAIL
EndFunc


Func WardenWaitForNextShieldRecastBeforeChoreo($timeoutMs = 10000)
	Local $timer = TimerInit()
	Local $startShieldSlot = $warden_shield_active_slot
	Local $startShieldCastMarker = $warden_shield_last_cast_timer

	While TimerDiff($timer) < $timeoutMs
		If IsPlayerDead() Then Return $FAIL
		WardenMaintainDefense()

		; Recast happened if shield cast marker changed or active shield swapped.
		If ($warden_shield_last_cast_timer <> 0 And $startShieldCastMarker <> 0 And $warden_shield_last_cast_timer <> $startShieldCastMarker) _
			Or ($startShieldSlot <> 0 And $warden_shield_active_slot <> $startShieldSlot) Then
			WardenDebugLog('choreo_wait_shield_ok', 'startSlot=' & $startShieldSlot & ';newSlot=' & $warden_shield_active_slot)
			Return $SUCCESS
		EndIf

		WardenSleepWithIaUPulse(90)
	WEnd

	Warn('Warden: timed out waiting for next 2/3 recast before choreography')
	WardenDebugLog('choreo_wait_shield_timeout', 'startSlot=' & $startShieldSlot)
	Return $FAIL
EndFunc


Func WardenPrimeFreshShieldAtKillSpot($timeoutMs = 2800)
	Local $timer = TimerInit()
	Local $me = GetMyAgent()

	While TimerDiff($timer) < $timeoutMs
		If IsPlayerDead() Then Return $FAIL
		WardenMaintainDefense()
		$me = GetMyAgent()
		Local $psMs = WardenGetEffectMs($ID_PROTECTIVE_SPIRIT)
		Local $soaMs = WardenGetEffectMs($ID_SHIELD_OF_ABSORPTION)
		Local $handsMs = WardenGetEffectMs($ID_SHIELDING_HANDS)

		; If a shield was just cast very recently, accept and proceed.
		If $warden_shield_last_cast_timer <> 0 And TimerDiff($warden_shield_last_cast_timer) <= 550 Then
			WardenDebugLog('kill_spot_shield_ok', 'reason=recent;slot=' & $warden_shield_active_slot & ';age=' & Int(TimerDiff($warden_shield_last_cast_timer)))
			Return $SUCCESS
		EndIf

		; If core defense is already stable, don't stall choreography waiting for a perfect extra recast.
		If $psMs > $WARDEN_PS_URGENT_MS And ($soaMs > 0 Or $handsMs > 0) Then
			WardenDebugLog('kill_spot_shield_ok', 'reason=covered;ps=' & $psMs & ';soa=' & $soaMs & ';sh=' & $handsMs)
			Return $SUCCESS
		EndIf

		; PS must stay highest priority while we prime shield at kill spot.
		If $psMs <= $WARDEN_PS_URGENT_MS Then
			If WardenUseSkillInstant($WARDEN_PROTECTIVE_SPIRIT, $me) Then
				WardenDebugLog('cast_ps', 'reason=kill_spot_prime')
				$warden_ps_last_cast_timer = TimerInit()
			EndIf
		EndIf

		If $warden_shield_active_slot == 0 Then $warden_shield_active_slot = $WARDEN_SHIELD_OF_ABSORPTION
		Local $nextShield = $warden_shield_active_slot == $WARDEN_SHIELD_OF_ABSORPTION ? $WARDEN_SHIELDING_HANDS : $WARDEN_SHIELD_OF_ABSORPTION
		Local $activeShield = $warden_shield_active_slot

		; Prefer deterministic alternation (cast the opposite shield first).
		If WardenUseSkillInstant($nextShield, $me) Then
			WardenDebugLog('cast_shield', 'reason=kill_spot_prime;slot=' & $nextShield)
			$warden_shield_active_slot = $nextShield
			$warden_shield_last_cast_timer = TimerInit()
			WardenTryRecastIaU('post_kill_spot_prime')
			WardenSleepWithIaUPulse(40)
			Return $SUCCESS
		EndIf

		; Fallback: if opposite isn't ready yet, refresh the current shield to enter choreo covered.
		If WardenUseSkillInstant($activeShield, $me) Then
			WardenDebugLog('cast_shield', 'reason=kill_spot_prime_fallback;slot=' & $activeShield)
			$warden_shield_active_slot = $activeShield
			$warden_shield_last_cast_timer = TimerInit()
			WardenTryRecastIaU('post_kill_spot_prime_fallback')
			WardenSleepWithIaUPulse(40)
			Return $SUCCESS
		EndIf

		WardenSleepWithIaUPulse(40)
	WEnd

	Local $psMsFinal = WardenGetEffectMs($ID_PROTECTIVE_SPIRIT)
	Local $soaMsFinal = WardenGetEffectMs($ID_SHIELD_OF_ABSORPTION)
	Local $handsMsFinal = WardenGetEffectMs($ID_SHIELDING_HANDS)
	If $psMsFinal > 0 And ($soaMsFinal > 0 Or $handsMsFinal > 0) Then
		WardenDebugLog('kill_spot_shield_ok', 'reason=timeout_covered;ps=' & $psMsFinal & ';soa=' & $soaMsFinal & ';sh=' & $handsMsFinal)
		Return $SUCCESS
	EndIf

	Warn('Warden: could not prime reliable defense at kill spot in time')
	WardenDebugLog('kill_spot_shield_timeout', 'ps=' & $psMsFinal & ';soa=' & $soaMsFinal & ';sh=' & $handsMsFinal)
	Return $FAIL
EndFunc


Func WardenMoveMaintainingDefense($x, $y, $timeoutMs, $requireAggro = True)
	Local $timer = TimerInit()
	Move($x, $y)
	Local $lastPulse = TimerInit()
	Local $me = GetMyAgent()
	Local $stuckTimer = TimerInit()
	Local $lastDistance = 999999
	Local $unstuckAttempts = 0
	While GetDistanceToPoint($me, $x, $y) > 220
		If IsPlayerDead() Then Return $FAIL
		If TimerDiff($timer) > $timeoutMs Then
			If $unstuckAttempts < 4 Then
				$unstuckAttempts += 1
				WardenDebugLog('move_timeout_retry', 'x=' & $x & ';y=' & $y & ';attempt=' & $unstuckAttempts)
				If WardenTryBreakBodyblock($x, $y) Then
					$timer = TimerInit()
					$stuckTimer = TimerInit()
					ContinueLoop
				EndIf
			EndIf
			Warn('Warden move timeout to ' & $x & ',' & $y)
			Return $FAIL
		EndIf

		WardenMaintainDefense()
		$me = GetMyAgent()
		Local $distance = GetDistanceToPoint($me, $x, $y)
		If $distance < ($lastDistance - 35) Then
			$stuckTimer = TimerInit()
			$unstuckAttempts = 0
		EndIf
		$lastDistance = $distance

		If TimerDiff($stuckTimer) > 1700 And $unstuckAttempts < 5 Then
			$unstuckAttempts += 1
			WardenDebugLog('move_unstuck', 'x=' & $x & ';y=' & $y & ';attempt=' & $unstuckAttempts & ';dist=' & Int($distance))
			If WardenTryBreakBodyblock($x, $y) Then
				$stuckTimer = TimerInit()
				ContinueLoop
			EndIf
		EndIf

		If TimerDiff($lastPulse) > 1300 Then
			Move($x, $y)
			$lastPulse = TimerInit()
		EndIf

		If $requireAggro And CountFoesInRangeOfAgent($me, 1250) <= 0 And TimerDiff($timer) > 7000 Then
			Warn('Lost aggro while moving to waypoint')
			Return $FAIL
		EndIf
		RandomSleep(120)
		$me = GetMyAgent()
	WEnd
	Return $SUCCESS
EndFunc


Func WardenTryBreakBodyblock($targetX, $targetY)
	Local $me = GetMyAgent()
	If $me == Null Then Return False

	WardenMaintainDefense()
	WardenTryRecastIaU('unstuck')

	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')
	Local $dx = $targetX - $x
	Local $dy = $targetY - $y
	Local $len = Sqrt(($dx * $dx) + ($dy * $dy))
	If $len < 1 Then Return False

	Local $rightX = $dy / $len
	Local $rightY = -$dx / $len

	; Right-left hook with forward gain to break clamped melee rings.
	Move(Int($x + ($rightX * 240) + (($dx / $len) * 130)), Int($y + ($rightY * 240) + (($dy / $len) * 130)))
	Sleep(200)
	Move(Int($x - ($rightX * 220) + (($dx / $len) * 240)), Int($y - ($rightY * 220) + (($dy / $len) * 240)))
	Sleep(200)
	Move(Int($x + (($dx / $len) * 340)), Int($y + (($dy / $len) * 340)))
	Sleep(220)
	Move($targetX, $targetY)
	Sleep(180)

	Return True
EndFunc


Func WardenSleepWithIaUPulse($durationMs, $chunkMs = 15)
	If $durationMs <= 0 Then Return
	If $chunkMs < 1 Then $chunkMs = 1

	Local $timer = TimerInit()
	While TimerDiff($timer) < $durationMs
		WardenTryRecastIaU('sleep_pulse')
		Local $remaining = Int($durationMs - TimerDiff($timer))
		If $remaining <= 0 Then ExitLoop
		Local $sleepNow = $remaining < $chunkMs ? $remaining : $chunkMs
		If $sleepNow < 1 Then $sleepNow = 1
		Sleep($sleepNow)
	WEnd
EndFunc


Func WardenMaintainDefense()
	If IsPlayerDead() Then Return
	If Not $warden_defense_loop_active Then Return

	Local $me = GetMyAgent()
	Local $psMs = WardenGetEffectMs($ID_PROTECTIVE_SPIRIT)
	Local $soaMs = WardenGetEffectMs($ID_SHIELD_OF_ABSORPTION)
	Local $handsMs = WardenGetEffectMs($ID_SHIELDING_HANDS)
	WardenDebugCheckCoverageGaps($psMs, $soaMs, $handsMs)
	If $warden_debug_heartbeat_timer == 0 Or TimerDiff($warden_debug_heartbeat_timer) >= $WARDEN_DEBUG_HEARTBEAT_MS Then
		WardenDebugLog('tick')
		$warden_debug_heartbeat_timer = TimerInit()
	EndIf

	WardenTryRecastIaU('recast_cycle')
	If $warden_iau_last_cast_timer <> 0 And TimerDiff($warden_iau_last_cast_timer) >= $WARDEN_IAU_RECAST_LATE_MS And Not WardenIsSkillReadyNow($WARDEN_IAU) Then
		WardenDebugLog('iau_waiting_recharge', 'elapsed=' & Int(TimerDiff($warden_iau_last_cast_timer)))
	EndIf

	If $warden_ps_last_cast_timer <> 0 Then
		If TimerDiff($warden_ps_last_cast_timer) >= ($WARDEN_PS_DURATION_MS - $WARDEN_PS_RECAST_BUFFER_MS) Then
			If WardenUseSkillInstant($WARDEN_PROTECTIVE_SPIRIT, $me) Then
				WardenDebugLog('cast_ps', 'reason=timer_recast')
				$warden_ps_last_cast_timer = TimerInit()
			EndIf
		EndIf
	ElseIf WardenUseSkillInstant($WARDEN_PROTECTIVE_SPIRIT, $me) Then
		WardenDebugLog('cast_ps', 'reason=bootstrap')
		$warden_ps_last_cast_timer = TimerInit()
	EndIf

	If $warden_shield_active_slot == 0 Then $warden_shield_active_slot = $WARDEN_SHIELD_OF_ABSORPTION

	Local $activeDuration = $warden_shield_active_slot == $WARDEN_SHIELD_OF_ABSORPTION ? $WARDEN_SOA_DURATION_MS : $WARDEN_SH_DURATION_MS
	Local $nextShield = $warden_shield_active_slot == $WARDEN_SHIELD_OF_ABSORPTION ? $WARDEN_SHIELDING_HANDS : $WARDEN_SHIELD_OF_ABSORPTION
	Local $activeShield = $warden_shield_active_slot
	Local $elapsedShield = $warden_shield_last_cast_timer == 0 ? 0 : TimerDiff($warden_shield_last_cast_timer)
	If $warden_shield_last_cast_timer <> 0 Then
		If $elapsedShield >= ($activeDuration - $WARDEN_SHIELD_RECAST_BUFFER_MS) Then
			; Deterministic alternation: switch to the other shield at a fixed pre-expire point.
			If $elapsedShield >= $WARDEN_CAST_MIN_GAP_MS And WardenUseSkillInstant($nextShield, $me) Then
				WardenDebugLog('cast_shield', 'reason=swap;slot=' & $nextShield)
				$warden_shield_active_slot = $nextShield
				$warden_shield_last_cast_timer = TimerInit()
				WardenTryRecastIaU('post_shield_swap')
				Return
			EndIf
		EndIf

		; Safety if swap timing passed and we are near/after expiry: keep coverage by recasting anything ready.
		If $elapsedShield >= ($activeDuration + $WARDEN_SHIELD_EXPIRE_GRACE_MS) Then
			If WardenUseSkillInstant($nextShield, $me) Then
				WardenDebugLog('cast_shield', 'reason=late_swap;slot=' & $nextShield)
				$warden_shield_active_slot = $nextShield
				$warden_shield_last_cast_timer = TimerInit()
				WardenTryRecastIaU('post_shield_late_swap')
				Return
			ElseIf WardenUseSkillInstant($activeShield, $me) Then
				WardenDebugLog('cast_shield', 'reason=late_refresh;slot=' & $activeShield)
				$warden_shield_active_slot = $activeShield
				$warden_shield_last_cast_timer = TimerInit()
				WardenTryRecastIaU('post_shield_late_refresh')
				Return
			EndIf
		EndIf
	Else
		If WardenUseSkillInstant($WARDEN_SHIELD_OF_ABSORPTION, $me) Then
			WardenDebugLog('cast_shield', 'reason=bootstrap;slot=' & $WARDEN_SHIELD_OF_ABSORPTION)
			$warden_shield_active_slot = $WARDEN_SHIELD_OF_ABSORPTION
			$warden_shield_last_cast_timer = TimerInit()
			WardenTryRecastIaU('post_shield_bootstrap')
			Return
		EndIf
	EndIf

	; Fallback if effect was stripped: re-apply whichever shield is available.
	If $soaMs <= 0 And $handsMs <= 0 Then
		If WardenUseSkillInstant($WARDEN_SHIELD_OF_ABSORPTION, $me) Then
			WardenDebugLog('cast_shield', 'reason=fallback;slot=' & $WARDEN_SHIELD_OF_ABSORPTION)
			$warden_shield_active_slot = $WARDEN_SHIELD_OF_ABSORPTION
			$warden_shield_last_cast_timer = TimerInit()
		ElseIf WardenUseSkillInstant($WARDEN_SHIELDING_HANDS, $me) Then
			WardenDebugLog('cast_shield', 'reason=fallback;slot=' & $WARDEN_SHIELDING_HANDS)
			$warden_shield_active_slot = $WARDEN_SHIELDING_HANDS
			$warden_shield_last_cast_timer = TimerInit()
		EndIf
	EndIf
EndFunc


Func WardenDebugCheckCoverageGaps($psMs, $soaMs, $handsMs)
	Local $psGap = $psMs <= 0
	If $psGap And Not $warden_gap_ps_active Then
		$warden_gap_ps_active = True
		WardenDebugLog('gap_ps_open')
	ElseIf Not $psGap And $warden_gap_ps_active Then
		$warden_gap_ps_active = False
		WardenDebugLog('gap_ps_closed')
	EndIf

	Local $shieldGap = ($soaMs <= 0 And $handsMs <= 0)
	If $shieldGap And Not $warden_gap_shield_active Then
		$warden_gap_shield_active = True
		WardenDebugLog('gap_shield_open')
	ElseIf Not $shieldGap And $warden_gap_shield_active Then
		$warden_gap_shield_active = False
		WardenDebugLog('gap_shield_closed')
	EndIf
EndFunc


Func WardenDebugLogInit()
	If Not $WARDEN_DEBUG_LOOP_LOG_ENABLED Then Return
	If $warden_debug_log_handle <> -1 Then WardenDebugLogClose()

	Local $character = GetCharacterName()
	If $character == '' Then $character = 'unknown'
	Local $timestamp = @YEAR & @MON & @MDAY & '_' & @HOUR & @MIN & @SEC
	Local $path = @ScriptDir & '/logs/warden_loop_debug-' & $character & '-run' & $warden_debug_run_number & '-' & $timestamp & '.csv'

	$warden_debug_log_handle = FileOpen($path, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	$warden_debug_log_timer = TimerInit()
	$warden_debug_heartbeat_timer = 0
	$warden_gap_ps_active = False
	$warden_gap_shield_active = False
	If $warden_debug_log_handle == -1 Then
		Warn('Warden debug log: could not open ' & $path)
		Return
	EndIf

	Info('Warden debug log: ' & $path)
	FileWriteLine($warden_debug_log_handle, 'time_ms;event;map_id;x;y;hp;foes1200;ps_ms;soa_ms;sh_ms;s1_ready;s2_ready;s3_ready;s6_ready;active_shield;note')
EndFunc


Func WardenDebugLogClose()
	If $warden_debug_log_handle == -1 Then Return
	FileClose($warden_debug_log_handle)
	$warden_debug_log_handle = -1
EndFunc


Func WardenDebugLog($event, $note = '')
	If Not $WARDEN_DEBUG_LOOP_LOG_ENABLED Then Return
	If $warden_debug_log_handle == -1 Then Return

	Local $me = GetMyAgent()
	Local $x = 0
	Local $y = 0
	Local $hp = 0
	If $me <> Null Then
		$x = Int(DllStructGetData($me, 'X'))
		$y = Int(DllStructGetData($me, 'Y'))
		$hp = Round(DllStructGetData($me, 'HealthPercent'), 3)
	EndIf

	Local $psMs = GetEffectTimeRemaining($ID_PROTECTIVE_SPIRIT)
	Local $soaMs = WardenGetEffectMs($ID_SHIELD_OF_ABSORPTION)
	Local $handsMs = WardenGetEffectMs($ID_SHIELDING_HANDS)
	$psMs = WardenNormalizeEffectMs($psMs)
	Local $foes = CountFoesInRangeOfAgent(GetMyAgent(), 1200)
	Local $safeNote = StringReplace($note, ';', ',')
	Local $timeMs = Int(TimerDiff($warden_debug_log_timer))

	FileWriteLine($warden_debug_log_handle, $timeMs & ';' & $event & ';' & GetMapID() & ';' & $x & ';' & $y & ';' & $hp & ';' & $foes & ';' & $psMs & ';' & $soaMs & ';' & $handsMs & ';' & _
		IsRecharged($WARDEN_PROTECTIVE_SPIRIT) & ';' & IsRecharged($WARDEN_SHIELD_OF_ABSORPTION) & ';' & IsRecharged($WARDEN_SHIELDING_HANDS) & ';' & IsRecharged($WARDEN_IAU) & ';' & _
		$warden_shield_active_slot & ';' & $safeNote)
EndFunc


Func WardenGetEffectMs($effectID)
	Return WardenNormalizeEffectMs(GetEffectTimeRemaining($effectID))
EndFunc


Func WardenNormalizeEffectMs($value)
	If $value <= 0 Then Return 0
	; Some APIs return seconds-like small values; normalize those to milliseconds.
	If $value < 100 Then Return Int($value * 1000)
	Return Int($value)
EndFunc


Func WardenUseKillChoreography()
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	If $target == Null Then Return $FAIL
	ChangeTarget($target)

	WardenMaintainDefense()
	If WardenIsDefenseUrgent() Then
		WardenDebugLog('defense_priority', 'phase=kill_choreo_pre')
		Return $SUCCESS
	EndIf

	If WardenUseSkillInstant($WARDEN_EBSOH) Then WardenDebugLog('cast_offense', 'skill=4;phase=kill_choreo')
	WardenMaintainDefense()
	WardenSleepWithIaUPulse(70)
	If WardenIsDefenseUrgent() Then
		WardenDebugLog('defense_priority', 'phase=kill_choreo_after_4')
		Return $SUCCESS
	EndIf

	If WardenUseSkillInstant($WARDEN_HUNDRED_BLADES) Then WardenDebugLog('cast_offense', 'skill=5;phase=kill_choreo')
	WardenMaintainDefense()
	WardenSleepWithIaUPulse(70)
	If WardenIsDefenseUrgent() Then
		WardenDebugLog('defense_priority', 'phase=kill_choreo_after_5')
		Return $SUCCESS
	EndIf

	If WardenUseSkillInstant($WARDEN_WHIRLWIND, $target) Then WardenDebugLog('cast_offense', 'skill=7;phase=kill_choreo')
	WardenMaintainDefense()
	WardenSleepWithIaUPulse(70)
	Return $SUCCESS
EndFunc


Func WardenFightUntilClear($timeoutMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $timeoutMs
		If IsPlayerDead() Then Return $FAIL

		Local $me = GetMyAgent()
		Local $foes = CountFoesInRangeOfAgent($me, 1350)
		If $foes <= 0 Then Return $SUCCESS

		WardenMaintainDefense()
		Local $target = GetNearestEnemyToAgent($me)
		If WardenIsDefenseUrgent() Then
			WardenDebugLog('defense_priority', 'phase=fight_loop')
			If $target <> Null Then
				ChangeTarget($target)
				Attack($target)
			EndIf
			WardenSleepWithIaUPulse(90)
			ContinueLoop
		EndIf

		If $target <> Null Then
			ChangeTarget($target)
			If WardenUseSkillInstant($WARDEN_WHIRLWIND, $target) Then WardenDebugLog('cast_offense', 'skill=7;phase=fight_loop')
			WardenMaintainDefense()
			If WardenIsDefenseUrgent() Then
				Attack($target)
				WardenSleepWithIaUPulse(90)
				ContinueLoop
			EndIf

			If WardenUseSkillInstant($WARDEN_HUNDRED_BLADES) Then WardenDebugLog('cast_offense', 'skill=5;phase=fight_loop')
			WardenMaintainDefense()
			Attack($target)
		EndIf
		WardenSleepWithIaUPulse(120)
	WEnd
	Warn('Warden clear timeout')
	Return $FAIL
EndFunc


Func WardenIsDefenseUrgent()
	Local $psMs = WardenGetEffectMs($ID_PROTECTIVE_SPIRIT)
	Local $soaMs = WardenGetEffectMs($ID_SHIELD_OF_ABSORPTION)
	Local $handsMs = WardenGetEffectMs($ID_SHIELDING_HANDS)

	; Treat urgency as a real coverage break, not an early timer threshold,
	; otherwise offense gets permanently starved in stacked melee.
	If $psMs <= 0 Then Return True
	If $soaMs <= 0 And $handsMs <= 0 Then Return True
	Return False
EndFunc


Func WardenApplyMorgahnBoost()
	Local $heroIndex = WardenGetMorgahnIndex()
	If $heroIndex == 0 Then
		Warn('Morgahn not found. Skipping support cast phase')
		Return
	EndIf

	CancelHero($heroIndex)
	CommandHero($heroIndex, $WARDEN_BOOST_HERO_X, $WARDEN_BOOST_HERO_Y)
	RandomSleep(180)

	Local $me = GetMyAgent()
	UseHeroSkill($heroIndex, $WARDEN_MORGAHN_ENDURING, $me)
	RandomSleep(260)
	UseHeroSkill($heroIndex, $WARDEN_MORGAHN_INCOMING, $me)
	RandomSleep(300)
EndFunc


Func WardenGetMorgahnIndex()
	Local $heroCount = GetHeroCount()
	If $heroCount <= 0 Then Return 0

	If $warden_morgahn_index_cache >= 1 And $warden_morgahn_index_cache <= $heroCount Then
		Local $cachedS4 = GetSkillbarSkillID($WARDEN_MORGAHN_ENDURING, $warden_morgahn_index_cache)
		Local $cachedS2 = GetSkillbarSkillID($WARDEN_MORGAHN_INCOMING, $warden_morgahn_index_cache)
		If $cachedS4 == $ID_ENDURING_HARMONY And $cachedS2 == $ID_INCOMING Then Return $warden_morgahn_index_cache
	EndIf

	For $i = 1 To $heroCount
		Local $s4 = GetSkillbarSkillID($WARDEN_MORGAHN_ENDURING, $i)
		Local $s2 = GetSkillbarSkillID($WARDEN_MORGAHN_INCOMING, $i)
		If $s4 == $ID_ENDURING_HARMONY And $s2 == $ID_INCOMING Then
			$warden_morgahn_index_cache = $i
			Return $i
		EndIf
	Next

	Return 0
EndFunc
