#CS ===========================================================================
; Author: GitHub Copilot (initial scaffold)
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
#include '../utilities/SupportTeam.au3'

Opt('MustDeclareVars', True)

Global Const $VSF_PERMA_TANK_SKILLBAR = 'OwZSg4PTSf6MHQ3lNQxl0kIQ'
Global Const $VSF_PERMA_TANK_FARM_INFORMATIONS = 'Voltaic Spear Farm (Run Part):' & @CRLF _
	& '- Sin Perma Tank from Umbral''s Grotto to Slaver''s Exile' & @CRLF _
	& '- keeps SF chain (1+2) and core sustain/mobility up' & @CRLF _
	& '- route is seeded from recording path_action_20260517_203320.csv'
Global Const $VSF_PERMA_TANK_FARM_DURATION = 4 * 60 * 1000
Global Const $VSF_PORTAL_X = 25729
Global Const $VSF_PORTAL_Y = -9360
Global Const $VSF_UMBRAL_PORTAL_FLAG_FALLBACK_X = -22020
Global Const $VSF_UMBRAL_PORTAL_FLAG_FALLBACK_Y = 6138
Global Const $VSF_WAIT_AFTER_SLAVERS_ENTRY = False
Global Const $VSF_ENABLE_SLAVERS_LVL1_PART = True

Global Const $VSF_SLAVERS_INNER_PORTAL_X = -18020
Global Const $VSF_SLAVERS_INNER_PORTAL_Y = 12512
Global Const $VSF_SLAVERS_HERO_WALL_X = -13520
Global Const $VSF_SLAVERS_HERO_WALL_Y = -16160
Global Const $VSF_SLAVERS_BRIDGE_PREP_X = -11757
Global Const $VSF_SLAVERS_BRIDGE_PREP_Y = -15111
Global Const $VSF_SLAVERS_KITE_X = -18587
Global Const $VSF_SLAVERS_KITE_Y = -9992
Global Const $VSF_SLAVERS_ANCHOR_X = -14464
Global Const $VSF_SLAVERS_ANCHOR_Y = -15512
Global Const $VSF_SLAVERS_FINAL_X = -14283
Global Const $VSF_SLAVERS_FINAL_Y = -15740
Global Const $VSF_SLAVERS_CALL_INTERVAL_MS = 1800
Global Const $VSF_SLAVERS_HERO_REFLAG_MS = 8000
Global Const $VSF_SLAVERS_SURVIVE_WINDOW_MS = 90000
Global Const $VSF_BRIDGE_OPEN_RETREAT_MAX_ATTEMPTS = 8
Global Const $VSF_BRIDGE_OPEN_CHECK_RANGE = 1150
Global Const $VSF_BRIDGE_OPEN_NEAR_MIN = 1180
Global Const $VSF_BRIDGE_OPEN_NEAR_MAX = 1320
Global Const $VSF_BRIDGE_OPEN_NEAR_TOLERANCE = 40
Global Const $VSF_BRIDGE_OPEN_STEP_UNITS = 150

Global Const $VSF_MONK_MODEL_PRIO_1 = $ID_STONE_SUMMIT_PRIEST
Global Const $VSF_MONK_MODEL_PRIO_2 = $ID_STONE_SUMMIT_DREAMER
Global Const $VSF_MONK_MODEL_PRIO_3 = $ID_STONE_SUMMIT_DEFENDER

Global Const $VSF_HERO_NORGU_TEMPLATE = 'OQBDArwjNngcw0z0VEwpZAiA'
Global Const $VSF_HERO_GWEN_TEMPLATE = 'OQBDAqoTNhwpXO4mOEMdZglP'
Global Const $VSF_HERO_RAZAH_TEMPLATE = 'OQBDArwjNngcw0z0VEwpZAiA'
Global Const $VSF_HERO_XANDRA_TEMPLATE = 'OAKkghgb4QuD20694CnQTnp186A'
Global Const $VSF_HERO_LIVIA_TEMPLATE = 'OAhkQIG4BHqTNbyNOtDCNp5wU4B'
Global Const $VSF_HERO_MOW_TEMPLATE = 'OANDY4xvOXiAS94uqFbJV1aC'
Global Const $VSF_HERO_OLIAS_TEMPLATE = 'OABDQqhHPPVXIcoTsvGaV13A'
Global Const $VSF_XANDRA_FROZEN_SOIL_SLOT = 8
Global Const $VSF_XANDRA_FROZEN_SOIL_INTERVAL_MS = 60000

; Skill slots
Global Const $VSF_SKILL_GLYPH_OF_SWIFTNESS = 1
Global Const $VSF_SKILL_SHADOW_FORM = 2
Global Const $VSF_SKILL_SHROUD_OF_DISTRESS = 3
Global Const $VSF_SKILL_DWARVEN_STABILITY = 4
Global Const $VSF_SKILL_DARK_ESCAPE = 5
Global Const $VSF_SKILL_MENTAL_BLOCK = 6
Global Const $VSF_SKILL_I_AM_UNSTOPPABLE = 7
Global Const $VSF_SKILL_HEART_OF_SHADOW = 8

Global Const $VSF_REFRESH_GOS_MS = 12000
Global Const $VSF_REFRESH_SF_MS = 11000
Global Const $VSF_REFRESH_SOD_MS = 38000
Global Const $VSF_REFRESH_DS_MS = 22000
Global Const $VSF_REFRESH_DE_MS = 9000
Global Const $VSF_SF_RECAST_BUFFER_MS = 2200
Global Const $VSF_SF_GOS_PRECAST_MS = 2000
Global Const $VSF_SF_FIRST_SLAVERS_PRECAST_AT_MS = 19800
Global Const $VSF_GOS_TO_SF_DELAY_MS = 80
Global Const $VSF_IAU_RECAST_ENABLED = True
Global Const $VSF_SF_GOS_PRECAST_TIMER_MS = 14500
Global Const $VSF_SF_RECAST_TIMER_MS = 16500
Global Const $VSF_SF_PRECAST_AT_MS = 20500
Global Const $VSF_DE_SECOND_EXPIRE_PRECAST_MS = 11000
Global Const $VSF_TROLL_BRIDGE_X = 18850
Global Const $VSF_TROLL_BRIDGE_Y = -3500
Global Const $VSF_TROLL_BRIDGE_RADIUS = 2600
Global Const $VSF_BRIDGE_DETOUR_COOLDOWN_MS = 7000
Global Const $VSF_PREBRIDGE_STUCK_X = 12000
Global Const $VSF_PREBRIDGE_STUCK_Y = -4950
Global Const $VSF_PREBRIDGE_STUCK_RADIUS = 3000
Global Const $VSF_PREBRIDGE_ARC_COOLDOWN_MS = 7000
Global Const $VSF_TROLL_PINCH_X = 12650
Global Const $VSF_TROLL_PINCH_Y = -5085
Global Const $VSF_TROLL_PINCH_RADIUS = 1200
Global Const $VSF_TROLL_PINCH_COOLDOWN_MS = 7000
Global Const $VSF_HOS_SURVIVAL_HP_PCT = 0.38
Global Const $VSF_HOS_SURVIVAL_COOLDOWN_MS = 4500
Global Const $VSF_BRIDGE_ZONE_MIN_X = 9300
Global Const $VSF_BRIDGE_ZONE_MAX_X = 22000
Global Const $VSF_BRIDGE_ZONE_MIN_Y = -6700
Global Const $VSF_BRIDGE_ZONE_MAX_Y = -1900
Global Const $VSF_DS_HANDOVER_WINDOW_MS = 2200
Global Const $VSF_DEBUG_LOG_ENABLED = True
Global Const $VSF_DEBUG_HEARTBEAT_MS = 350
Global Const $VSF_STUCK_HOOK_TRIGGER_MS = 1600
Global Const $VSF_STUCK_HOOK_COOLDOWN_MS = 1800
Global Const $VSF_STUCK_HOOK_COOLDOWN_BRIDGE_MS = 700
Global Const $VSF_STUCK_HOOK_SIDE_UNITS = 100
Global Const $VSF_STUCK_HOOK_FORWARD_UNITS = 280
Global Const $VSF_STUCK_HOOK_MIN_DISPLACEMENT = 80
Global Const $VSF_BRIDGE_EARLY_HOOK_TRIGGER_MS = 900
Global Const $VSF_BRIDGE_HOOK_ONLY_WINDOW_MS = 9000

Global $vsf_setup_done = False
Global $vsf_last_gos_timer = 0
Global $vsf_last_sf_timer = 0
Global $vsf_last_sod_timer = 0
Global $vsf_last_ds_timer = 0
Global $vsf_last_de_timer = 0
Global $vsf_dark_escape_casts_for_current_ds = 0
Global $vsf_gos_precast_for_current_sf = False
Global $vsf_debug_log_handle = -1
Global $vsf_debug_log_timer = 0
Global $vsf_debug_heartbeat_timer = 0
Global $vsf_run_number = 0
Global $vsf_last_bridge_detour_timer = 0
Global $vsf_last_prebridge_arc_timer = 0
Global $vsf_last_troll_pinch_timer = 0
Global $vsf_last_survival_hos_timer = 0
Global $vsf_total_dark_escape_casts = 0
Global $vsf_iau_recast_mode = False
Global $vsf_part2_first_sf_recast_pending = False
Global $vsf_part2_sf_dodge_enabled = False
Global $vsf_part2_use_pcons = True
Global $vsf_part2_opening_phase = False
Global $vsf_last_stuck_hook_timer = 0
Global $vsf_stuck_hook_fail_streak = 0
Global $vsf_wait_mode_from_thommis = False


Func VSFPermaTankFarm()
	$vsf_run_number += 1
	VSFDebugLogInit()
	VSFDebugLogSnapshot('run_start')

	If Not $vsf_setup_done Then
		If SetupVSFPermaTankFarm() == $FAIL Then
			VSFDebugLogSnapshot('setup_fail', 'result=pause')
			VSFDebugLogClose()
			Return $PAUSE
		EndIf
	EndIf

	Local $result = VSFPermaTankRunLoop()
	VSFDebugLogSnapshot('run_end', 'result=' & $result)
	VSFDebugLogClose()
	Return $result
EndFunc


Func SetupVSFPermaTankFarm()
	Info('Setting up VSF Perma Tank run')
	VSFDebugLogSnapshot('setup_start')
	If TravelToOutpost($ID_UMBRAL_GROTTO, $district_name) == $FAIL Then Return $FAIL
	SwitchToHardModeIfEnabled()
	SetDisplayedTitle($ID_NORN_TITLE)

	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_ASSASSIN Then
		Warn('VSF Perma Tank was designed for Assassin primary. Continuing anyway.')
	EndIf

	LoadSkillTemplate($VSF_PERMA_TANK_SKILLBAR)
	RandomSleep(250)
	VSFDebugLogSnapshot('setup_player_loaded', 'template=' & $VSF_PERMA_TANK_SKILLBAR)

	; Debug: team setup intentionally disabled.
	If SetupVSFTeamFromMinisterialCommendations() == $FAIL Then
		Warn('VSF: could not apply Ministerial team setup')
		Return $FAIL
	EndIf

	VSFResetBuffTimers()

	$vsf_setup_done = True
	Info('VSF Perma Tank setup complete')
	VSFDebugLogSnapshot('setup_done')
	Return $SUCCESS
EndFunc


Func VSFPermaTankRunLoop()
	$vsf_wait_mode_from_thommis = False
	Info('VSF run: travelling to Umbral and entering Verdant Cascades')
	If TravelToOutpost($ID_UMBRAL_GROTTO, $district_name) == $FAIL Then Return $FAIL

	MoveTo(-23200, 7100)
	Move(-22735, 6339)
	RandomSleep(800)
	If Not WaitMapLoading($ID_VERDANT_CASCADES, 12000, 1000) Then
		Warn('VSF run: failed to zone into Verdant Cascades')
		Return $FAIL
	EndIf
	; Re-open 1->2 after zone: pre-zone casts can be stripped by map transition.
	VSFResetBuffTimers()
	VSFTankMaintainCoreBuffs(True)
	VSFFlagSupportHeroesAtPortal()

	Info('VSF run: following recording-seeded route to Slaver''s Exile')
	If VSFMoveToWithUpkeep(-22020, 6138, 'R1') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(-18545, 5693, 'R2') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(-14268, 4803, 'R3') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(-10689, 3093, 'R4') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(-6900, 893, 'R5') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(-4112, -2102, 'R6') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(-714, -4605, 'R7') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(2910, -4565, 'R8') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(6002, -1876, 'R9') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(9778, -3600, 'R10') == $FAIL Then Return $FAIL
	; Recording-based bridge line (path_action_20260519_190849): straight/right entry, then left pass at troll.
	If VSFMoveToWithUpkeep(10002, -5389, 'R11a') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(10715, -6556, 'R11b') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(11869, -6143, 'R11c') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(12641, -5099, 'R12a') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(13459, -3897, 'R12b') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(14359, -3042, 'R12c') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(15212, -2231, 'R12d') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(20132, -3774, 'R13') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(22425, -7102, 'R14') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(24526, -10364, 'R15') == $FAIL Then Return $FAIL

	; Same Slaver portal approach used by existing Voltaic logic.
	If VSFMoveToWithUpkeep($VSF_PORTAL_X, $VSF_PORTAL_Y, 'Portal') == $FAIL Then Return $FAIL
	Move($VSF_PORTAL_X, $VSF_PORTAL_Y)
	RandomSleep(800)
	If Not WaitMapLoading($ID_SLAVERS_EXILE, 12000, 1000) Then
		Warn('VSF run: failed to zone into Slaver''s Exile')
		Return $FAIL
	EndIf

	Info('VSF run part complete: arrived in Slaver''s Exile')
	If $VSF_ENABLE_SLAVERS_LVL1_PART Then Return VSFRunSlaversLevel1Part()

	If $VSF_WAIT_AFTER_SLAVERS_ENTRY Then
		Info('VSF hold mode active: waiting in Slaver''s Exile for manual stop')
		VSFDebugLogSnapshot('hold_after_slavers_entry', 'reason=manual_recording_window')
		While True
			Sleep(1000)
		WEnd
	EndIf
	Return $SUCCESS
EndFunc


Func VSFRunSlaversLevel1Part()
	Info('VSF part 2: entering Justiciar Thommis wing')
	If GetMapID() == $ID_SLAVERS_EXILE Then
		If Not VSFTryEnterThommisWing() Then
			Warn('VSF part 2: failed to zone into Slaver''s Exile level 1')
			Return $FAIL
		EndIf
	EndIf

	If GetMapID() <> $ID_SLAVERS_EXILE_LVL_1 Then
		Warn('VSF part 2: unexpected map ' & GetMapID())
		Return $FAIL
	EndIf

	$vsf_wait_mode_from_thommis = True
	Info('VSF part 2: Thommis wait-mode enabled (deaths now switch to manual hold)')

	Info('VSF part 2: flagging support heroes on wall')
	If VSFMoveToWithUpkeep($VSF_SLAVERS_HERO_WALL_X, $VSF_SLAVERS_HERO_WALL_Y, 'T1_wall', False) == $FAIL Then Return $FAIL
	VSFFlagAllCurrentHeroes($VSF_SLAVERS_HERO_WALL_X, $VSF_SLAVERS_HERO_WALL_Y)
	VSFDebugLogSnapshot('heroes_flagged', 'reason=slavers_wall_hold;x=' & $VSF_SLAVERS_HERO_WALL_X & ';y=' & $VSF_SLAVERS_HERO_WALL_Y)
	RandomSleep(300)

	Info('VSF part 2: moving to bridge prep and using pcons')
	If VSFMoveToWithUpkeep($VSF_SLAVERS_BRIDGE_PREP_X, $VSF_SLAVERS_BRIDGE_PREP_Y, 'T2_bridge', False) == $FAIL Then Return $FAIL
	If $vsf_part2_use_pcons Then VSFUseSecondPartPCons()
	$vsf_part2_opening_phase = True
	; Aggro-edge stabilization disabled: causes stuck-on-bridge-railing loop and run fail.
	;If Not VSFEnsureAggroFreeBeforeBridgeOpen() Then
	;	Warn('VSF part 2: could not stabilize near aggro-edge before initial bridge cast chain')
	;	$vsf_part2_opening_phase = False
	;	Return $FAIL
	;EndIf
	VSFCastFixedChainOpen()
	$vsf_part2_first_sf_recast_pending = True
	$vsf_part2_sf_dodge_enabled = True

	Info('VSF part 2: sprint to kite spot')
	If VSFMoveToWithUpkeep(-11547, -13364, 'T3a_kite') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(-13529, -11087, 'T3b_kite') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(-14341, -8564, 'T3c_kite') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(-17100, -7936, 'T3d_kite') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep($VSF_SLAVERS_KITE_X, $VSF_SLAVERS_KITE_Y, 'T3e_kite') == $FAIL Then Return $FAIL
	$vsf_part2_opening_phase = False
	VSFCastSkillIfReady($VSF_SKILL_GLYPH_OF_SWIFTNESS, 't3_refresh_1')
	VSFCastSkillIfReady($VSF_SKILL_SHADOW_FORM, 't3_refresh_2')
	VSFCastSkillIfReady($VSF_SKILL_I_AM_UNSTOPPABLE, 't3_refresh_7')
	VSFCastSkillIfReady($VSF_SKILL_DARK_ESCAPE, 't3_refresh_5')

	Info('VSF part 2: moving to anchor spot')
	If VSFMoveToWithUpkeep(-17953, -11478, 'T4a_anchor') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(-16539, -14094, 'T4b_anchor') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep(-14494, -15488, 'T4c_anchor') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep($VSF_SLAVERS_ANCHOR_X, $VSF_SLAVERS_ANCHOR_Y, 'T4d_anchor') == $FAIL Then Return $FAIL
	VSFCastSkillIfReady($VSF_SKILL_GLYPH_OF_SWIFTNESS, 't4_refresh_1')
	VSFCastSkillIfReady($VSF_SKILL_SHADOW_FORM, 't4_refresh_2')
	VSFCastSkillIfReady($VSF_SKILL_SHROUD_OF_DISTRESS, 't4_refresh_3')
	VSFCastSkillIfReady($VSF_SKILL_DWARVEN_STABILITY, 't4_refresh_4')
	VSFCastSkillIfReady($VSF_SKILL_DARK_ESCAPE, 't4_refresh_5')
	VSFCastSkillIfReady($VSF_SKILL_I_AM_UNSTOPPABLE, 't4_refresh_7')

	Info('VSF part 2: moving to final wall spot and holding with monk-calls')
	If VSFMoveToWithUpkeep(-14321, -15813, 'T5a_final') == $FAIL Then Return $FAIL
	If VSFMoveToWithUpkeep($VSF_SLAVERS_FINAL_X, $VSF_SLAVERS_FINAL_Y, 'T5_final') == $FAIL Then Return $FAIL
	Return VSFHoldFinalWallAndCallMonks()
EndFunc


Func VSFTryEnterThommisWing()
	If GetMapID() == $ID_SLAVERS_EXILE_LVL_1 Then Return True
	If GetMapID() <> $ID_SLAVERS_EXILE Then Return False

	; Slaver -> Thommis portal can fail on tiny offsets; use repeated approach and zone retries.
	For $attempt = 1 To 4
		If VSFMoveToWithUpkeep(-16797, 9251, 'T0a_portal_' & $attempt, False) == $FAIL Then Return False
		If VSFMoveToWithUpkeep(-17835, 12524, 'T0b_portal_' & $attempt, False) == $FAIL Then Return False

		Move(-18300, 12527)
		VSFDebugLogSnapshot('zone_try', 'reason=thommis_wing;attempt=' & $attempt)
		If WaitMapLoading($ID_SLAVERS_EXILE_LVL_1, 6000 + ($attempt * 1500), 250) Then Return True

		; Nudge position to break collision/stuck-at-threshold before retrying.
		If Mod($attempt, 2) == 0 Then
			Move(-18140, 12390)
		Else
			Move(-18480, 12670)
		EndIf
		Sleep(350)
	Next

	Return GetMapID() == $ID_SLAVERS_EXILE_LVL_1
EndFunc


Func VSFUseSecondPartPCons()
	VSFUseItemByModelID($ID_BIRTHDAY_CUPCAKE, 'Birthday Cupcake')
	Sleep(180)
	VSFUseItemByModelID($ID_HARD_APPLE_CIDER, 'Hard Apple Cider')
EndFunc


Func VSFUseItemByModelID($modelID, $itemName)
	Local $item = GetItemByModelID($modelID)
	If $item == Null Then
		Warn('VSF part 2: could not find ' & $itemName & ' in inventory')
		VSFDebugLogSnapshot('pcon_missing', 'item=' & $itemName & ';model=' & $modelID)
		Return False
	EndIf

	UseItem($item)
	VSFDebugLogSnapshot('pcon_used', 'item=' & $itemName & ';model=' & $modelID)
	Sleep(GetPing() + 120)
	Return True
EndFunc


Func VSFCastFixedChainOpen()
	VSFCastSkillIfReady($VSF_SKILL_GLYPH_OF_SWIFTNESS, 't2_chain_1', True)
	VSFCastSkillIfReady($VSF_SKILL_SHADOW_FORM, 't2_chain_2', True)
	VSFCastSkillIfReady($VSF_SKILL_SHROUD_OF_DISTRESS, 't2_chain_3', True)
	VSFCastSkillIfReady($VSF_SKILL_DWARVEN_STABILITY, 't2_chain_4', True)
	VSFCastSkillIfReady($VSF_SKILL_DARK_ESCAPE, 't2_chain_5', True)
EndFunc


Func VSFEnsureAggroFreeBeforeBridgeOpen()
	Local $lastDist = -1
	Local $sameDistStreak = 0
	For $attempt = 1 To 20
		Local $nearestHostile = VSFGetNearestHostileFoeOrSpiritInRange(2200)
		If $nearestHostile == Null Then
			VSFBridgeOpenPulseStep(+1)
			Sleep(160)
			ContinueLoop
		EndIf

		Local $dist = Int(GetDistance(GetMyAgent(), $nearestHostile))
		If $dist >= $VSF_BRIDGE_OPEN_NEAR_MIN And $dist <= ($VSF_BRIDGE_OPEN_NEAR_MAX + $VSF_BRIDGE_OPEN_NEAR_TOLERANCE) Then
			VSFDebugLogSnapshot('aggro_near_ready', 'attempt=' & $attempt & ';dist=' & $dist)
			Return True
		EndIf

		If $dist == $lastDist Then
			$sameDistStreak += 1
		Else
			$sameDistStreak = 0
		EndIf
		$lastDist = $dist

		Warn('VSF part 2: hostile aggro before opening chain (count=1, nearest=' & $dist & ') - stepping ' & ($dist > $VSF_BRIDGE_OPEN_NEAR_MAX ? 'forward' : 'back'))
		VSFDebugLogSnapshot('aggro_block', 'reason=t2_open_chain;attempt=' & $attempt & ';count=1;nearest=' & $dist)

		If $sameDistStreak >= 3 Then
			; Distance not changing: do a corrective pulse to break micro-stall, then continue.
			VSFBridgeOpenPulseStep(-1)
			Sleep(120)
			VSFBridgeOpenPulseStep(+1)
		ElseIf $dist > $VSF_BRIDGE_OPEN_NEAR_MAX Then
			VSFBridgeOpenPulseStep(+1)
		Else
			VSFBridgeOpenPulseStep(-1)
		EndIf
		Sleep(170)
	Next

	Return False
EndFunc


Func VSFCountHostileFoesAndSpiritsInRange($range, ByRef $nearestDist)
	$nearestDist = 0
	Local $me = GetMyAgent()
	If $me == Null Then Return 0
	Local $myTeam = DllStructGetData($me, 'Team')

	Local $count = 0
	Local $nearest = 99999999
	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		Local $allegiance = DllStructGetData($agent, 'Allegiance')
		Local $isHostile = False
		If $allegiance == $ID_ALLEGIANCE_FOE Then
			$isHostile = True
		ElseIf $allegiance == $ID_ALLEGIANCE_SPIRIT And DllStructGetData($agent, 'Team') <> $myTeam Then
			$isHostile = True
		EndIf
		If Not $isHostile Then ContinueLoop
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop

		Local $dist = GetDistance($me, $agent)
		If $dist > $range Then ContinueLoop

		$count += 1
		If $dist < $nearest Then $nearest = $dist
	Next

	If $count > 0 Then $nearestDist = Int($nearest)
	Return $count
EndFunc


Func VSFMoveToPointNoSkills($x, $y, $label = '', $timeoutMs = 8000)
	Local $timer = TimerInit()
	Move($x, $y)
	While GetDistanceToPoint(GetMyAgent(), $x, $y) > 250
		If IsPlayerDead() Then
			If $vsf_wait_mode_from_thommis Then
				VSFEnterManualWaitOnDeath('segment_' & $label)
			Else
				Warn('VSF death before Thommis at ' & $label & ': failing run for normal resign/restart')
			EndIf
			Return False
		EndIf

		If TimerDiff($timer) > $timeoutMs Then
			Warn('VSF no-skill move timeout at ' & $label & ' (' & $x & ',' & $y & ')')
			Return False
		EndIf

		Move($x, $y)
		Sleep(180)
	WEnd
	Return True
EndFunc


Func VSFDoShortBridgeRetreatStep($attempt)
	Local $me = GetMyAgent()
	If $me == Null Then Return False

	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $stepUnits = 180 + (($attempt - 1) * 70)
	If $stepUnits > 520 Then $stepUnits = 520

	; Prefer retreating away from the nearest hostile to leave aggro quickly without drifting to heroes.
	Local $nearestHostile = VSFGetNearestHostileFoeOrSpiritInRange(1800)
	Local $retreatDirX = 0
	Local $retreatDirY = 0
	If $nearestHostile <> Null Then
		$retreatDirX = $myX - DllStructGetData($nearestHostile, 'X')
		$retreatDirY = $myY - DllStructGetData($nearestHostile, 'Y')
	Else
		$retreatDirX = $VSF_SLAVERS_HERO_WALL_X - $myX
		$retreatDirY = $VSF_SLAVERS_HERO_WALL_Y - $myY
	EndIf

	Local $len = Sqrt(($retreatDirX * $retreatDirX) + ($retreatDirY * $retreatDirY))
	If $len < 1 Then Return True

	Local $stepX = Int($myX + (($retreatDirX / $len) * $stepUnits))
	Local $stepY = Int($myY + (($retreatDirY / $len) * $stepUnits))
	VSFDebugLogSnapshot('aggro_step', 'attempt=' & $attempt & ';x=' & $stepX & ';y=' & $stepY & ';step=' & $stepUnits)

	; Deliberately short pulse move: avoid pathing all the way back and avoid retry timeouts on tight bridge geometry.
	Move($stepX, $stepY)
	Sleep(520)
	Return True
EndFunc


Func VSFBridgeOpenPulseStep($direction)
	Local $me = GetMyAgent()
	If $me == Null Then Return

	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $laneX = -11547 - $myX
	Local $laneY = -13364 - $myY
	Local $len = Sqrt(($laneX * $laneX) + ($laneY * $laneY))
	If $len < 1 Then Return

	Local $nx = Int($myX + (($laneX / $len) * $VSF_BRIDGE_OPEN_STEP_UNITS * $direction))
	Local $ny = Int($myY + (($laneY / $len) * $VSF_BRIDGE_OPEN_STEP_UNITS * $direction))
	VSFDebugLogSnapshot('aggro_step', 'dir=' & $direction & ';x=' & $nx & ';y=' & $ny & ';step=' & $VSF_BRIDGE_OPEN_STEP_UNITS)
	Move($nx, $ny)
	Sleep(330)
EndFunc


Func VSFGetNearestHostileFoeOrSpiritInRange($range)
	Local $me = GetMyAgent()
	If $me == Null Then Return Null
	Local $myTeam = DllStructGetData($me, 'Team')

	Local $nearest = Null
	Local $nearestDist = 99999999
	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop

		Local $allegiance = DllStructGetData($agent, 'Allegiance')
		Local $isHostile = False
		If $allegiance == $ID_ALLEGIANCE_FOE Then
			$isHostile = True
		ElseIf $allegiance == $ID_ALLEGIANCE_SPIRIT And DllStructGetData($agent, 'Team') <> $myTeam Then
			$isHostile = True
		EndIf
		If Not $isHostile Then ContinueLoop

		Local $dist = GetDistance($me, $agent)
		If $dist > $range Then ContinueLoop
		If $dist < $nearestDist Then
			$nearest = $agent
			$nearestDist = $dist
		EndIf
	Next

	Return $nearest
EndFunc


Func VSFCastSkillIfReady($skillSlot, $reason, $waitCastFinish = False)
	If Not IsRecharged($skillSlot) Then Return False
	UseSkillEx($skillSlot)
	Switch $skillSlot
		Case $VSF_SKILL_GLYPH_OF_SWIFTNESS
			$vsf_last_gos_timer = TimerInit()
			$vsf_gos_precast_for_current_sf = True
		Case $VSF_SKILL_SHADOW_FORM
			$vsf_last_sf_timer = TimerInit()
			$vsf_gos_precast_for_current_sf = False
		Case $VSF_SKILL_SHROUD_OF_DISTRESS
			$vsf_last_sod_timer = TimerInit()
		Case $VSF_SKILL_DWARVEN_STABILITY
			$vsf_last_ds_timer = TimerInit()
		Case $VSF_SKILL_DARK_ESCAPE
			$vsf_last_de_timer = TimerInit()
			$vsf_dark_escape_casts_for_current_ds += 1
			$vsf_total_dark_escape_casts += 1
		Case $VSF_SKILL_I_AM_UNSTOPPABLE
			$vsf_iau_recast_mode = True
	EndSwitch
	VSFDebugLogSnapshot('cast_manual', 'reason=' & $reason & ';slot=' & $skillSlot)
	Sleep(GetPing() + 80)

	If $waitCastFinish Then
		Local $timer = TimerInit()
		Local $me = GetMyAgent()
		While $me <> Null And IsCasting($me) And TimerDiff($timer) < 2600
			Sleep(40)
		WEnd
	EndIf
	Return True
EndFunc


Func VSFHoldFinalWallAndCallMonks()
	Local $callTimer = 0
	Local $refLagTimer = 0
	Local $frozenSoilTimer = 0
	Local $holdTimer = TimerInit()
	$vsf_iau_recast_mode = False
	$vsf_part2_sf_dodge_enabled = False

	VSFTryCastXandraFrozenSoil('hold_start')
	$frozenSoilTimer = TimerInit()

	While TimerDiff($holdTimer) < $VSF_SLAVERS_SURVIVE_WINDOW_MS
		If IsPlayerDead() Then
			If $vsf_wait_mode_from_thommis Then
				VSFEnterManualWaitOnDeath('final_hold')
				Return $PAUSE
			EndIf
			Warn('VSF death outside Thommis wait window at final_hold: failing run for normal resign/restart')
			Return $FAIL
		EndIf

		VSFTankMaintainCoreBuffs(False)

		If $refLagTimer == 0 Or TimerDiff($refLagTimer) >= $VSF_SLAVERS_HERO_REFLAG_MS Then
			VSFFlagAllCurrentHeroes($VSF_SLAVERS_HERO_WALL_X, $VSF_SLAVERS_HERO_WALL_Y)
			$refLagTimer = TimerInit()
		EndIf

		If $callTimer == 0 Or TimerDiff($callTimer) >= $VSF_SLAVERS_CALL_INTERVAL_MS Then
			Local $target = VSFPickPriorityCallTarget()
			If $target <> Null Then
				CallTargetOnce($target)
				For $heroIndex = 1 To GetHeroCount()
					LockHeroTarget($heroIndex, DllStructGetData($target, 'ID'))
				Next
				VSFDebugLogSnapshot('target_call', 'model=' & DllStructGetData($target, 'ModelID') & ';id=' & DllStructGetData($target, 'ID'))
			EndIf
			$callTimer = TimerInit()
		EndIf

		If $frozenSoilTimer == 0 Or TimerDiff($frozenSoilTimer) >= $VSF_XANDRA_FROZEN_SOIL_INTERVAL_MS Then
			If VSFTryCastXandraFrozenSoil('hold_recast') Then $frozenSoilTimer = TimerInit()
		EndIf

		If CountFoesInRangeOfCoords($VSF_SLAVERS_HERO_WALL_X, $VSF_SLAVERS_HERO_WALL_Y, 1400) <= 0 _
			And CountFoesInRangeOfAgent(GetMyAgent(), 1200) <= 0 Then
			Info('VSF part 2: hold complete, enemies cleared near wall')
			Return $SUCCESS
		EndIf

		Sleep(180)
	WEnd

	Warn('VSF part 2: hold timeout reached')
	Return IsPlayerDead() ? $FAIL : $SUCCESS
EndFunc


Func VSFTryCastXandraFrozenSoil($reason)
	If GetHeroCount() < 7 Then Return False
	Local $xandraIndex = GetHeroNumberByHeroID($ID_XANDRA)
	If $xandraIndex == Null Or $xandraIndex <= 0 Then Return False
	If Not IsRecharged($VSF_XANDRA_FROZEN_SOIL_SLOT, $xandraIndex) Then Return False

	UseHeroSkill($xandraIndex, $VSF_XANDRA_FROZEN_SOIL_SLOT)
	VSFDebugLogSnapshot('hero_cast', 'hero=xandra;index=' & $xandraIndex & ';slot=' & $VSF_XANDRA_FROZEN_SOIL_SLOT & ';reason=' & $reason)
	Sleep(GetPing() + 40)
	Return True
EndFunc


Func VSFPickPriorityCallTarget()
	Local $t = VSFGetNearestEnemyByModel($VSF_MONK_MODEL_PRIO_1)
	If $t <> Null Then Return $t
	$t = VSFGetNearestEnemyByModel($VSF_MONK_MODEL_PRIO_2)
	If $t <> Null Then Return $t
	$t = VSFGetNearestEnemyByModel($VSF_MONK_MODEL_PRIO_3)
	If $t <> Null Then Return $t
	Return GetNearestEnemyToAgent(GetMyAgent())
EndFunc


Func VSFGetNearestEnemyByModel($modelID)
	Local $me = GetMyAgent()
	If $me == Null Then Return Null

	Local $nearest = Null
	Local $nearestDist = 99999999
	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		If DllStructGetData($agent, 'ModelID') <> $modelID Then ContinueLoop
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then ContinueLoop
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop

		Local $dist = GetDistance($me, $agent)
		If $dist < $nearestDist Then
			$nearestDist = $dist
			$nearest = $agent
		EndIf
	Next
	Return $nearest
EndFunc


Func SetupVSFTeamFromMinisterialCommendations()
	Info('VSF team: Norgu, Gwen, Razah, Xandra, Master of Whispers, Livia, Olias')

	If VSFEnsureSoloParty() == $FAIL Then Return $FAIL

	If VSFTryAddHero($ID_NORGU, 'Norgu', 2) == $FAIL _
		Or VSFTryAddHero($ID_GWEN, 'Gwen', 3) == $FAIL _
		Or VSFTryAddHero($ID_RAZAH, 'Razah', 4) == $FAIL _
		Or VSFTryAddHero($ID_XANDRA, 'Xandra', 5) == $FAIL _
		Or VSFTryAddHero($ID_MASTER_OF_WHISPERS, 'Master of Whispers', 6) == $FAIL _
		Or VSFTryAddHero($ID_LIVIA, 'Livia', 7) == $FAIL _
		Or VSFTryAddHero($ID_OLIAS, 'Olias', 8) == $FAIL Then
		Warn('VSF Ministerial team assembly failed')
		Return $FAIL
	EndIf

	If GetHeroNumberByHeroID($ID_NORGU) <> 1 Then Return $FAIL
	If GetHeroNumberByHeroID($ID_GWEN) <> 2 Then Return $FAIL
	If GetHeroNumberByHeroID($ID_RAZAH) <> 3 Then Return $FAIL
	If GetHeroNumberByHeroID($ID_XANDRA) <> 4 Then Return $FAIL
	If GetHeroNumberByHeroID($ID_MASTER_OF_WHISPERS) <> 5 Then Return $FAIL
	If GetHeroNumberByHeroID($ID_LIVIA) <> 6 Then Return $FAIL
	If GetHeroNumberByHeroID($ID_OLIAS) <> 7 Then Return $FAIL

	LoadSkillTemplate($VSF_HERO_NORGU_TEMPLATE, 1)
	RandomSleep(150)
	LoadSkillTemplate($VSF_HERO_GWEN_TEMPLATE, 2)
	RandomSleep(150)
	LoadSkillTemplate($VSF_HERO_RAZAH_TEMPLATE, 3)
	RandomSleep(150)
	LoadSkillTemplate($VSF_HERO_XANDRA_TEMPLATE, 4)
	RandomSleep(150)
	LoadSkillTemplate($VSF_HERO_MOW_TEMPLATE, 5)
	RandomSleep(150)
	LoadSkillTemplate($VSF_HERO_LIVIA_TEMPLATE, 6)
	RandomSleep(150)
	LoadSkillTemplate($VSF_HERO_OLIAS_TEMPLATE, 7)

	RandomSleep(250)

	ClearPartyCommands()
	CancelAllHeroes()
	SupportTeamOpenHeroPanels('VSF Perma Tank')
	Return $SUCCESS
EndFunc


Func VSFEnsureSoloParty($maxWaitMs = 9000)
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
	Warn('VSF Sin team: party reset timeout. Party=' & GetPartySize() & ', heroes=' & GetHeroCount())
	Return $FAIL
EndFunc


Func VSFTryAddHero($heroID, $heroName, $expectedSize)
	For $i = 1 To 6
		If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
		AddHero($heroID)
		RandomSleep(350)
		If GetPartySize() >= $expectedSize Then Return $SUCCESS
	Next
	Warn('Could not add VSF hero ' & $heroName & ' (party=' & GetPartySize() & ')')
	Return $FAIL
EndFunc


Func VSFFlagSupportHeroesAtPortal()
	If GetMapID() <> $ID_VERDANT_CASCADES Then Return

	Local $flagX = $VSF_UMBRAL_PORTAL_FLAG_FALLBACK_X
	Local $flagY = $VSF_UMBRAL_PORTAL_FLAG_FALLBACK_Y
	Local $didFlag = False

	; After zoning, hero list can lag briefly. Retry so flags always stick.
	For $i = 1 To 10
		If GetHeroCount() > 0 Then
			VSFFlagAllCurrentHeroes($flagX, $flagY)
			$didFlag = True
		EndIf
		RandomSleep(180)
	Next

	If Not $didFlag Then Warn('VSF: no heroes available to flag at Umbral exit right after zone')
	VSFDebugLogSnapshot('heroes_flagged', 'reason=umbral_portal_hold_fixed;x=' & $flagX & ';y=' & $flagY & ';ok=' & $didFlag)
EndFunc


Func VSFFlagAllCurrentHeroes($x, $y)
	Local $heroCount = GetHeroCount()
	If $heroCount <= 0 Then Return

	For $heroIndex = 1 To $heroCount
		If GetHeroID($heroIndex) <> 0 Then CommandHero($heroIndex, $x, $y)
	Next
EndFunc


Func VSFMoveToWithUpkeep($x, $y, $label = '', $maintainUpkeep = True)
	Local $runTimer = TimerInit()
	Local $stuckTimer = TimerInit()
	Local $lastDistance = 999999
	Local $isBridgeApproach = VSFIsBridgeApproachLabel($label)
	Local $hookTriggerMs = $isBridgeApproach ? $VSF_BRIDGE_EARLY_HOOK_TRIGGER_MS : $VSF_STUCK_HOOK_TRIGGER_MS

	Move($x, $y)
	While GetDistanceToPoint(GetMyAgent(), $x, $y) > 250
		If IsPlayerDead() Then
			If $vsf_wait_mode_from_thommis Then
				VSFEnterManualWaitOnDeath('segment_' & $label)
				Return $PAUSE
			EndIf
			Warn('VSF death before Thommis at ' & $label & ': failing run for normal resign/restart')
			Return $FAIL
		EndIf

		If $maintainUpkeep Then VSFTankMaintainCoreBuffs(False)

		Local $distance = GetDistanceToPoint(GetMyAgent(), $x, $y)
		If $distance < $lastDistance - 30 Then
			$stuckTimer = TimerInit()
			$vsf_stuck_hook_fail_streak = 0
		EndIf
		$lastDistance = $distance

		If TimerDiff($stuckTimer) > $hookTriggerMs Then
			If VSFTryRightLeftHookUnblock($x, $y, $label) Then
				$stuckTimer = TimerInit()
				Sleep(120)
				ContinueLoop
			EndIf
		EndIf

		If TimerDiff($stuckTimer) > 4500 Then
			If $isBridgeApproach And TimerDiff($runTimer) < $VSF_BRIDGE_HOOK_ONLY_WINDOW_MS Then
				VSFDebugLogSnapshot('bridge_unblock', 'reason=hook_only_window;label=' & $label)
				If VSFTryRightLeftHookUnblock($x, $y, $label) Then
					$stuckTimer = TimerInit()
					Sleep(120)
					ContinueLoop
				EndIf
				Move($x, $y)
				Sleep(120)
				ContinueLoop
			EndIf

			If VSFTryTrollPinchLeftPassUnblock($x, $y) Then
				$stuckTimer = TimerInit()
				Sleep(120)
				ContinueLoop
			EndIf

			If VSFTryPreBridgeRightArcUnblock($x, $y) Then
				$stuckTimer = TimerInit()
				Sleep(120)
				ContinueLoop
			EndIf

			If VSFTryBridgeHoSUnblock() Then
				$stuckTimer = TimerInit()
				Sleep(120)
				ContinueLoop
			EndIf

			VSFTryEmergencyUnblock()
			$stuckTimer = TimerInit()
		EndIf

		If TimerDiff($runTimer) > 45000 Then
			Warn('VSF segment timeout at ' & $label & ' (' & $x & ',' & $y & ')')
			Return $FAIL
		EndIf

		Move($x, $y)
		Sleep(220)
	WEnd

	Return $SUCCESS
EndFunc


Func VSFIsBridgeApproachLabel($label)
	Switch $label
		Case 'R11a', 'R11b', 'R11c', 'R12a', 'R12b', 'R12c', 'R12d'
			Return True
	EndSwitch
	Return False
EndFunc


Func VSFTryRightLeftHookUnblock($resumeX, $resumeY, $label = '')
	Local $hookCooldownMs = $VSF_STUCK_HOOK_COOLDOWN_MS
	If VSFIsBridgeApproachLabel($label) Then $hookCooldownMs = $VSF_STUCK_HOOK_COOLDOWN_BRIDGE_MS
	If $vsf_last_stuck_hook_timer <> 0 And TimerDiff($vsf_last_stuck_hook_timer) < $hookCooldownMs Then Return False

	Local $me = GetMyAgent()
	If $me == Null Then Return False

	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')
	Local $forwardX = $resumeX - $x
	Local $forwardY = $resumeY - $y
	Local $len = Sqrt(($forwardX * $forwardX) + ($forwardY * $forwardY))
	If $len < 1 Then Return False

	Local $rightX = $forwardY / $len
	Local $rightY = -$forwardX / $len
	Local $failScale = $vsf_stuck_hook_fail_streak
	If $failScale < 0 Then $failScale = 0
	If $failScale > 4 Then $failScale = 4
	Local $side = $VSF_STUCK_HOOK_SIDE_UNITS + ($failScale * 25)
	Local $forward = $VSF_STUCK_HOOK_FORWARD_UNITS + ($failScale * 40)
	If VSFIsBridgeApproachLabel($label) Then
		$side += 40
		$forward += 80
	EndIf
	Local $startX = $x
	Local $startY = $y

	$vsf_last_stuck_hook_timer = TimerInit()
	VSFDebugLogSnapshot('stuck_hook', 'label=' & $label & ';side=' & $side & ';forward=' & $forward & ';fails=' & $vsf_stuck_hook_fail_streak)

	; Right-left hook with forward gain to break bodyblock instead of oscillating in place.
	Move(Int($x + ($rightX * $side) + ($forwardX / $len * ($forward * 0.35))), Int($y + ($rightY * $side) + ($forwardY / $len * ($forward * 0.35))))
	Sleep(220)
	Move(Int($x - ($rightX * $side) + ($forwardX / $len * ($forward * 0.75))), Int($y - ($rightY * $side) + ($forwardY / $len * ($forward * 0.75))))
	Sleep(220)
	Move(Int($x + ($forwardX / $len * $forward)), Int($y + ($forwardY / $len * $forward)))
	Sleep(220)
	Move($resumeX, $resumeY)
	Sleep(220)

	$me = GetMyAgent()
	If $me == Null Then Return False
	Local $endX = DllStructGetData($me, 'X')
	Local $endY = DllStructGetData($me, 'Y')
	Local $moved = Sqrt((($endX - $startX) * ($endX - $startX)) + (($endY - $startY) * ($endY - $startY)))
	If $moved < $VSF_STUCK_HOOK_MIN_DISPLACEMENT Then
		$vsf_stuck_hook_fail_streak += 1
		VSFDebugLogSnapshot('stuck_hook_fail', 'label=' & $label & ';moved=' & Int($moved) & ';fails=' & $vsf_stuck_hook_fail_streak)
		Return False
	EndIf

	$vsf_stuck_hook_fail_streak = 0
	VSFDebugLogSnapshot('stuck_hook_ok', 'label=' & $label & ';moved=' & Int($moved))
	Return True
EndFunc


Func VSFEnterManualWaitOnDeath($reason = '')
	Warn('VSF death detected (' & $reason & '): switching to wait mode for manual takeover')
	VSFDebugLogSnapshot('death_wait', 'reason=' & $reason)
	While True
		Sleep(1000)
	WEnd
EndFunc


Func VSFTankMaintainCoreBuffs($forceOpening = False)
	If IsPlayerDead() Then Return
	If Not $vsf_part2_opening_phase Then
		If VSFTryCriticalHoS() Then Return
		If VSFTryBridgeSurvivalHoS() Then Return
	EndIf

	Local $sfRemaining = VSFGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP)
	Local $sfRechargeRemainingMs = VSFGetSkillRechargeRemainingMs($VSF_SKILL_SHADOW_FORM)
	Local $sfReady = ($sfRechargeRemainingMs <= 0)
	Local $sfCycleAge = ($vsf_last_sf_timer == 0) ? 999999 : TimerDiff($vsf_last_sf_timer)
	If $vsf_debug_heartbeat_timer == 0 Or TimerDiff($vsf_debug_heartbeat_timer) >= $VSF_DEBUG_HEARTBEAT_MS Then
		VSFDebugLogSnapshot('tick', 'sfRem=' & $sfRemaining & ';sfReady=' & $sfReady & ';sfCd=' & $sfRechargeRemainingMs & ';sfAge=' & Int($sfCycleAge) & ';gosPre=' & $vsf_gos_precast_for_current_sf)
		$vsf_debug_heartbeat_timer = TimerInit()
	EndIf

	; Opening chain keeps explicit 1 -> 2 order.
	If $forceOpening Then
		If IsRecharged($VSF_SKILL_GLYPH_OF_SWIFTNESS) Then
			UseSkillEx($VSF_SKILL_GLYPH_OF_SWIFTNESS)
			$vsf_last_gos_timer = TimerInit()
			$vsf_gos_precast_for_current_sf = True
			VSFDebugLogSnapshot('cast_gos', 'reason=opening')
			Sleep(GetPing() + $VSF_GOS_TO_SF_DELAY_MS)
		EndIf

		If IsRecharged($VSF_SKILL_SHADOW_FORM) Then
			UseSkillEx($VSF_SKILL_SHADOW_FORM)
			$vsf_last_sf_timer = TimerInit()
			$vsf_gos_precast_for_current_sf = False
			VSFDebugLogSnapshot('cast_sf', 'reason=opening')
			Sleep(GetPing() + 60)
			Return
		EndIf
	EndIf

	; Deterministic SF loop:
	; 1) Pre-cast GoS ~2s before SF expected expiry.
	; 2) Once pre-cast happened, cast only SF until it lands (no other skills in-between).
	Local $useSlaversFirstRecastFallback = $vsf_part2_first_sf_recast_pending And GetMapID() == $ID_SLAVERS_EXILE_LVL_1 And $sfCycleAge >= $VSF_SF_FIRST_SLAVERS_PRECAST_AT_MS
	Local $shouldPrecastByCycle = ($sfCycleAge >= $VSF_SF_PRECAST_AT_MS)
	If (Not $vsf_gos_precast_for_current_sf) And ($shouldPrecastByCycle Or $useSlaversFirstRecastFallback) Then
		If IsRecharged($VSF_SKILL_GLYPH_OF_SWIFTNESS) Then
			UseSkillEx($VSF_SKILL_GLYPH_OF_SWIFTNESS)
			$vsf_last_gos_timer = TimerInit()
			$vsf_gos_precast_for_current_sf = True
			Local $gosReason = $useSlaversFirstRecastFallback ? 'sf_first_slavers_precast' : 'sf_fixed_precast_cycle'
			VSFDebugLogSnapshot('cast_gos', 'reason=' & $gosReason & ';sfAge=' & Int($sfCycleAge) & ';sfCd=' & $sfRechargeRemainingMs)
			Sleep(GetPing() + $VSF_GOS_TO_SF_DELAY_MS)
		EndIf
	EndIf

	If $vsf_gos_precast_for_current_sf Then
		If $sfReady Then
			If $vsf_part2_sf_dodge_enabled And GetMapID() == $ID_SLAVERS_EXILE_LVL_1 Then VSFDoSmallSideStepForArrowDodge()
			UseSkillEx($VSF_SKILL_SHADOW_FORM)
			$vsf_last_sf_timer = TimerInit()
			$vsf_gos_precast_for_current_sf = False
			VSFDebugLogSnapshot('cast_sf', 'reason=sf_fixed_after_gos;sfAge=' & Int($sfCycleAge))
			If $vsf_part2_first_sf_recast_pending And GetMapID() == $ID_SLAVERS_EXILE_LVL_1 Then
				$vsf_part2_first_sf_recast_pending = False
				$vsf_iau_recast_mode = True
				VSFDebugLogSnapshot('cast_iau', 'reason=force_recast_mode_after_first_sf_recast')
				If $VSF_IAU_RECAST_ENABLED And IsRecharged($VSF_SKILL_I_AM_UNSTOPPABLE) Then
					UseSkillEx($VSF_SKILL_I_AM_UNSTOPPABLE)
					VSFDebugLogSnapshot('cast_iau', 'reason=first_sf_recast_immediate')
					Sleep(GetPing() + 40)
				EndIf
			EndIf
			Sleep(GetPing() + 60)
		EndIf
		Return
	EndIf

	Local $sodRemaining = VSFGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)
	Local $dsRemaining = VSFGetBestEffectTimeRemaining($ID_DWARVEN_STABILITY)
	Local $deRemaining = VSFGetBestEffectTimeRemaining($ID_DARK_ESCAPE)

	; 3 only when expired.
	If $sodRemaining <= 0 And IsRecharged($VSF_SKILL_SHROUD_OF_DISTRESS) Then
		UseSkillEx($VSF_SKILL_SHROUD_OF_DISTRESS)
		$vsf_last_sod_timer = TimerInit()
		VSFDebugLogSnapshot('cast_sod', 'reason=expired')
		Sleep(GetPing() + 50)
		Return
	EndIf

	; Fixed 4/5 choreography:
	; - 5 on expiry.
	; - Before every second 5, cast 4 exactly once ~1s before 5.
	If $deRemaining <= 0 Then
		If IsRecharged($VSF_SKILL_DARK_ESCAPE) Then
			Local $nextDeIndex = $vsf_total_dark_escape_casts + 1
			If Mod($nextDeIndex, 2) == 0 Then
				If Not IsRecharged($VSF_SKILL_DWARVEN_STABILITY) Then
					VSFDebugLogSnapshot('wait_ds', 'reason=before_even_de;deIdx=' & $nextDeIndex)
					Return
				EndIf

				UseSkillEx($VSF_SKILL_DWARVEN_STABILITY)
				$vsf_last_ds_timer = TimerInit()
				VSFDebugLogSnapshot('cast_ds', 'reason=fixed_before_even_de;deIdx=' & $nextDeIndex)
				Sleep(1000 + GetPing() + 40)
			EndIf

			UseSkillEx($VSF_SKILL_DARK_ESCAPE)
			$vsf_last_de_timer = TimerInit()
			$vsf_dark_escape_casts_for_current_ds += 1
			$vsf_total_dark_escape_casts += 1
			VSFDebugLogSnapshot('cast_de', 'reason=fixed_expired;deCount=' & $vsf_dark_escape_casts_for_current_ds & ';deIdx=' & $vsf_total_dark_escape_casts)
			Sleep(GetPing() + 50)
			Return
		EndIf
	EndIf

	If $VSF_IAU_RECAST_ENABLED And $vsf_iau_recast_mode And IsRecharged($VSF_SKILL_I_AM_UNSTOPPABLE) Then
		UseSkillEx($VSF_SKILL_I_AM_UNSTOPPABLE)
		VSFDebugLogSnapshot('cast_iau', 'reason=recast_mode')
		Sleep(GetPing() + 40)
		Return
	EndIf

	If GetEffect($ID_CRIPPLED) <> Null And IsRecharged($VSF_SKILL_I_AM_UNSTOPPABLE) Then
		UseSkillEx($VSF_SKILL_I_AM_UNSTOPPABLE)
		$vsf_iau_recast_mode = True
		VSFDebugLogSnapshot('cast_iau', 'reason=crippled')
		Sleep(GetPing() + 40)
	EndIf
EndFunc


Func VSFGetSkillRechargeRemainingMs($skillSlot, $heroIndex = 0)
	Local $skillbar = GetSkillbar($heroIndex)
	If $skillbar == Null Then Return 0

	Local $rechargeUntil = DllStructGetData($skillbar, 'Recharge' & $skillSlot)
	If $rechargeUntil == 0 Then Return 0
	Local $skillTimer = GetSkillTimer()
	If $rechargeUntil <= $skillTimer Then Return 0

	Local $remaining = $rechargeUntil - $skillTimer
	If $remaining <= 0 Then Return 0
	; Guard against unsigned wrap artifacts (e.g. ~4.29e9) seen in live logs.
	If $remaining > 120000 Then Return 0
	Return $remaining
EndFunc


Func VSFTryCriticalHoS()
	If GetHealth() >= 100 Then Return False
	If Not IsRecharged($VSF_SKILL_HEART_OF_SHADOW) Then Return False

	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	If $target == Null Then $target = GetMyAgent()

	UseSkillEx($VSF_SKILL_HEART_OF_SHADOW, $target)
	VSFDebugLogSnapshot('cast_hos', 'reason=hp_lt_100;hp=' & GetHealth())
	Sleep(GetPing() + 40)
	Return True
EndFunc


Func VSFTryBridgeSurvivalHoS()
	Local $me = GetMyAgent()
	If $me == Null Then Return False

	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')
	If $x < $VSF_BRIDGE_ZONE_MIN_X Or $x > $VSF_BRIDGE_ZONE_MAX_X Then Return False
	If $y < $VSF_BRIDGE_ZONE_MIN_Y Or $y > $VSF_BRIDGE_ZONE_MAX_Y Then Return False

	If $vsf_last_survival_hos_timer <> 0 And TimerDiff($vsf_last_survival_hos_timer) < $VSF_HOS_SURVIVAL_COOLDOWN_MS Then Return False
	If DllStructGetData($me, 'HealthPercent') > $VSF_HOS_SURVIVAL_HP_PCT Then Return False
	If Not IsRecharged($VSF_SKILL_HEART_OF_SHADOW) Then Return False

	Local $target = GetNearestEnemyToAgent($me)
	If $target == Null Then $target = $me

	UseSkillEx($VSF_SKILL_HEART_OF_SHADOW, $target)
	$vsf_last_survival_hos_timer = TimerInit()
	VSFDebugLogSnapshot('cast_hos', 'reason=bridge_survival_hp;hpPct=' & Round(DllStructGetData($me, 'HealthPercent'), 3) & ';self=' & ($target == $me))
	Sleep(GetPing() + 40)
	Return True
EndFunc


Func VSFTryEmergencyUnblock()
	If IsRecharged($VSF_SKILL_I_AM_UNSTOPPABLE) Then UseSkillEx($VSF_SKILL_I_AM_UNSTOPPABLE)

	If DllStructGetData(GetMyAgent(), 'HealthPercent') < 45 And IsRecharged($VSF_SKILL_HEART_OF_SHADOW) Then
		Local $target = GetNearestEnemyToAgent(GetMyAgent())
		If $target <> Null Then UseSkillEx($VSF_SKILL_HEART_OF_SHADOW, $target)
	EndIf
EndFunc


Func VSFTryBridgeHoSUnblock()
	If GetDistanceToPoint(GetMyAgent(), $VSF_TROLL_BRIDGE_X, $VSF_TROLL_BRIDGE_Y) > $VSF_TROLL_BRIDGE_RADIUS Then Return False
	If $vsf_last_bridge_detour_timer <> 0 And TimerDiff($vsf_last_bridge_detour_timer) < $VSF_BRIDGE_DETOUR_COOLDOWN_MS Then Return False

	Local $me = GetMyAgent()
	If $me == Null Then Return False
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')

	; Run backward first (pull troll out of lane), then push forward over bridge while troll trails behind.
	If $x >= 16000 And $x <= 20800 And $y >= -5600 And $y <= -700 Then
		$vsf_last_bridge_detour_timer = TimerInit()
		VSFDebugLogSnapshot('bridge_unblock', 'reason=reverse_pull_start;x=' & Int($x) & ';y=' & Int($y))

		; Step 1: retreat to open space before bridge (away from choke).
		Move(17600, -2300)
		Sleep(380)
		Move(16800, -1500)
		Sleep(380)
		Move(16000, -800)
		Sleep(420)

		VSFDebugLogSnapshot('bridge_unblock', 'reason=reverse_pull_done')

		; Step 2: re-enter bridge on a clean forward line.
		Move(17650, -1200)
		Sleep(360)
		Move(19250, -1900)
		Sleep(360)
		Move(20650, -3200)
		Sleep(420)

		VSFDebugLogSnapshot('bridge_unblock', 'reason=forward_cross_done')
		Return True
	EndIf

	Return False
EndFunc


Func VSFTryPreBridgeRightArcUnblock($resumeX, $resumeY)
	Local $me = GetMyAgent()
	If $me == Null Then Return False

	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')
	If GetDistanceToPoint($me, $VSF_PREBRIDGE_STUCK_X, $VSF_PREBRIDGE_STUCK_Y) > $VSF_PREBRIDGE_STUCK_RADIUS Then Return False
	If $vsf_last_prebridge_arc_timer <> 0 And TimerDiff($vsf_last_prebridge_arc_timer) < $VSF_PREBRIDGE_ARC_COOLDOWN_MS Then Return False

	$vsf_last_prebridge_arc_timer = TimerInit()
	VSFDebugLogSnapshot('bridge_unblock', 'reason=prebridge_right_arc_start;x=' & Int($x) & ';y=' & Int($y))

	; Clockwise 180-degree-ish escape arc to get out of bodyblock, then rejoin route.
	Move($x - 450, $y - 420)
	Sleep(350)
	Move($x - 220, $y - 930)
	Sleep(360)
	Move($x + 520, $y - 980)
	Sleep(360)
	Move($x + 980, $y - 420)
	Sleep(360)
	Move($x + 900, $y + 240)
	Sleep(360)
	Move($resumeX, $resumeY)
	Sleep(360)

	VSFDebugLogSnapshot('bridge_unblock', 'reason=prebridge_right_arc_done')
	Return True
EndFunc


Func VSFTryTrollPinchLeftPassUnblock($resumeX, $resumeY)
	Local $me = GetMyAgent()
	If $me == Null Then Return False
	If GetDistanceToPoint($me, $VSF_TROLL_PINCH_X, $VSF_TROLL_PINCH_Y) > $VSF_TROLL_PINCH_RADIUS Then Return False
	If $vsf_last_troll_pinch_timer <> 0 And TimerDiff($vsf_last_troll_pinch_timer) < $VSF_TROLL_PINCH_COOLDOWN_MS Then Return False

	$vsf_last_troll_pinch_timer = TimerInit()
	VSFDebugLogSnapshot('bridge_unblock', 'reason=troll_pinch_left_pass_start')

	; Pull slightly back-left, then force the left-side pass line around troll and rejoin.
	Move(12490, -5240)
	Sleep(360)
	Move(12597, -5151)
	Sleep(340)
	Move(12641, -5099)
	Sleep(340)
	Move(12677, -4801)
	Sleep(360)
	Move(12771, -4648)
	Sleep(360)
	Move(12951, -4422)
	Sleep(360)
	Move($resumeX, $resumeY)
	Sleep(360)

	VSFDebugLogSnapshot('bridge_unblock', 'reason=troll_pinch_left_pass_done')
	Return True
EndFunc


Func VSFShouldRefresh(ByRef $timerRef, $thresholdMs)
	If $timerRef == 0 Then Return True
	Return TimerDiff($timerRef) >= $thresholdMs
EndFunc


Func VSFGetBestEffectTimeRemaining($skillID1, $skillID2 = 0)
	Local $v1 = VSFNormalizeEffectTimeMs(GetEffectTimeRemaining($skillID1))
	If $skillID2 == 0 Then Return $v1
	Local $v2 = VSFNormalizeEffectTimeMs(GetEffectTimeRemaining($skillID2))
	Return $v2 > $v1 ? $v2 : $v1
EndFunc


Func VSFNormalizeEffectTimeMs($value)
	If $value <= 0 Then Return 0
	If $value < 100 Then Return Int($value * 1000)
	Return Int($value)
EndFunc


Func VSFDoSmallSideStepForArrowDodge()
	Local $me = GetMyAgent()
	If $me == Null Then Return

	Local $moveX = DllStructGetData($me, 'MoveX')
	Local $moveY = DllStructGetData($me, 'MoveY')
	Local $len = Sqrt(($moveX * $moveX) + ($moveY * $moveY))
	If $len < 0.05 Then Return

	; Left vector from current movement direction for tiny anti-arrow sidestep.
	Local $leftX = -$moveY / $len
	Local $leftY = $moveX / $len
	Local $step = 120
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')

	Move(Int($x + ($leftX * $step)), Int($y + ($leftY * $step)))
	Sleep(90)
	Move(Int($x + ($leftX * $step * 2)), Int($y + ($leftY * $step * 2)))
	Sleep(90)
	VSFDebugLogSnapshot('sf_dodge', 'step=' & $step & ';mx=' & Round($moveX, 3) & ';my=' & Round($moveY, 3))
EndFunc


Func VSFResetBuffTimers()
	$vsf_last_gos_timer = 0
	$vsf_last_sf_timer = 0
	$vsf_last_sod_timer = 0
	$vsf_last_ds_timer = 0
	$vsf_last_de_timer = 0
	$vsf_dark_escape_casts_for_current_ds = 0
	$vsf_gos_precast_for_current_sf = False
	$vsf_last_survival_hos_timer = 0
	$vsf_total_dark_escape_casts = 0
	$vsf_iau_recast_mode = False
	$vsf_part2_first_sf_recast_pending = False
	$vsf_part2_sf_dodge_enabled = False
	$vsf_part2_use_pcons = True
	$vsf_part2_opening_phase = False
	$vsf_last_stuck_hook_timer = 0
	$vsf_stuck_hook_fail_streak = 0
EndFunc


Func VSFDebugLogInit()
	If Not $VSF_DEBUG_LOG_ENABLED Then Return
	If $vsf_debug_log_handle <> -1 Then VSFDebugLogClose()

	Local $character = GetCharacterName()
	If $character == '' Then $character = 'unknown'
	Local $timestamp = @YEAR & @MON & @MDAY & '_' & @HOUR & @MIN & @SEC
	Local $path = @ScriptDir & '/logs/vsf_perma_debug-' & $character & '-run' & $vsf_run_number & '-' & $timestamp & '.csv'

	$vsf_debug_log_handle = FileOpen($path, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	$vsf_debug_log_timer = TimerInit()
	$vsf_debug_heartbeat_timer = 0
	If $vsf_debug_log_handle == -1 Then
		Warn('VSF debug log: could not open ' & $path)
		Return
	EndIf

	Info('VSF debug log: ' & $path)
	FileWriteLine($vsf_debug_log_handle, 'time_ms;event;map_id;x;y;hp;energy;sf_ms;sod_ms;ds_ms;de_ms;gos_ready;sf_ready;sod_ready;ds_ready;de_ready;de_count;gos_precast;note')
EndFunc


Func VSFDebugLogClose()
	If $vsf_debug_log_handle == -1 Then Return
	FileClose($vsf_debug_log_handle)
	$vsf_debug_log_handle = -1
EndFunc


Func VSFDebugLogSnapshot($event, $note = '')
	If Not $VSF_DEBUG_LOG_ENABLED Then Return
	If $vsf_debug_log_handle == -1 Then Return

	Local $me = GetMyAgent()
	Local $x = 0
	Local $y = 0
	Local $hp = 0
	If $me <> Null Then
		$x = Int(DllStructGetData($me, 'X'))
		$y = Int(DllStructGetData($me, 'Y'))
		$hp = Round(DllStructGetData($me, 'HealthPercent'), 3)
	EndIf

	Local $energy = Round(GetEnergy(), 3)
	Local $sfMs = VSFGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP)
	Local $sodMs = VSFGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)
	Local $dsMs = VSFGetBestEffectTimeRemaining($ID_DWARVEN_STABILITY)
	Local $deMs = VSFGetBestEffectTimeRemaining($ID_DARK_ESCAPE)
	Local $safeNote = StringReplace($note, ';', ',')
	Local $timeMs = Int(TimerDiff($vsf_debug_log_timer))

	FileWriteLine($vsf_debug_log_handle, $timeMs & ';' & $event & ';' & GetMapID() & ';' & $x & ';' & $y & ';' & $hp & ';' & $energy & ';' & $sfMs & ';' & $sodMs & ';' & $dsMs & ';' & $deMs & ';' & _
		IsRecharged($VSF_SKILL_GLYPH_OF_SWIFTNESS) & ';' & IsRecharged($VSF_SKILL_SHADOW_FORM) & ';' & IsRecharged($VSF_SKILL_SHROUD_OF_DISTRESS) & ';' & IsRecharged($VSF_SKILL_DWARVEN_STABILITY) & ';' & IsRecharged($VSF_SKILL_DARK_ESCAPE) & ';' & _
		$vsf_dark_escape_casts_for_current_ds & ';' & $vsf_gos_precast_for_current_sf & ';' & $safeNote)
EndFunc
