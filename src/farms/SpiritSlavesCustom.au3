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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $SPIRIT_SLAVES_CUSTOM_ELE_SKILLBAR = 'OgVDMZycSfV5ipOZDuCugmARAA'
Global Const $SPIRIT_SLAVES_CUSTOM_RANGER_SKILLBAR = 'Ogojchpr6SAH3kfXdfjhOXxl3lA'
Global Const $SPIRIT_SLAVES_CUSTOM_FARM_INFORMATIONS = 'Custom Spirit Slaves supports Elementalist and Ranger:' & @CRLF _
	& '- keeps routing and pull logic from the original run' & @CRLF _
	& '- Elementalist: upkeep 1,2,6,7,8 and combat 3 -> 4 -> 5' & @CRLF _
	& '- Ranger: upkeep start 8,7,1,2,3,4 and combat 5 -> 6 (adrenaline-based)'
Global Const $SPIRIT_SLAVES_CUSTOM_FARM_DURATION = 10 * 60 * 1000

Global Const $SSC_MODE_ELEMENTALIST = 'elementalist'
Global Const $SSC_MODE_RANGER = 'ranger'

; Skill numbers declared to make the code WAY more readable (UseSkill($SKILL_CONVICTION is better than UseSkill(1))
; Ranger bar
Global Const $SSC_ESCAPE = 1
Global Const $SSC_YOU_ARE_ALL_WEAKLINGS = 2
Global Const $SSC_MYSTIC_VIGOR = 3
Global Const $SSC_GRENTHS_AURA = 4
Global Const $SSC_CRIPPLING_VICTORY = 5
Global Const $SSC_REAP_IMPURITIES = 6
Global Const $SSC_MENTAL_BLOCK = 7
Global Const $SSC_DWARVEN_STABILITY = 8

; Elementalist bar
Global Const $SSC_ELE_STONEFLESH_AURA = 1
Global Const $SSC_ELE_EBON_BATTLE_STANDARD_OF_HONOR = 2
Global Const $SSC_ELE_AFTERSHOCK = 3
Global Const $SSC_ELE_SHOCKWAVE = 4
Global Const $SSC_ELE_CRYSTAL_WAVE = 5
Global Const $SSC_ELE_ELEMENTAL_LORD = 6
Global Const $SSC_ELE_CHANNELING = 7
Global Const $SSC_ELE_MANTRA_OF_RESOLVE = 8

; Reduction from mysticism (50%) and increase from spirit (30%) are included
Global Const $SSC_SKILLS_ARRAY = [$SSC_ESCAPE, $SSC_YOU_ARE_ALL_WEAKLINGS, $SSC_MYSTIC_VIGOR, $SSC_GRENTHS_AURA, $SSC_CRIPPLING_VICTORY, $SSC_REAP_IMPURITIES, $SSC_MENTAL_BLOCK, $SSC_DWARVEN_STABILITY]
Global Const $SSC_SKILLS_COSTS_ARRAY = [5, 5, 5, 10, 6, 5, 10, 5]
Global Const $SSC_SKILL_COSTS_MAP = MapFromArrays($SSC_SKILLS_ARRAY, $SSC_SKILLS_COSTS_ARRAY)

Global Const $SSC_ELE_SKILLS_ARRAY = [$SSC_ELE_STONEFLESH_AURA, $SSC_ELE_EBON_BATTLE_STANDARD_OF_HONOR, $SSC_ELE_AFTERSHOCK, $SSC_ELE_SHOCKWAVE, $SSC_ELE_CRYSTAL_WAVE, $SSC_ELE_ELEMENTAL_LORD, $SSC_ELE_CHANNELING, $SSC_ELE_MANTRA_OF_RESOLVE]
Global Const $SSC_ELE_SKILLS_COSTS_ARRAY = [10, 10, 10, 10, 15, 5, 5, 10]
Global Const $SSC_ELE_SKILL_COSTS_MAP = MapFromArrays($SSC_ELE_SKILLS_ARRAY, $SSC_ELE_SKILLS_COSTS_ARRAY)
Global Const $SSC_RANGER_CHAIN_MIN_ADREN5 = 6
Global Const $SSC_RANGER_CHAIN_MIN_ADREN6 = 5
Global Const $SSC_RANGER_CHAIN_RETRY_MS = 220

Global $spirit_slaves_custom_farm_setup = False
Global $spirit_slaves_custom_mode = ''
Global $spirit_slaves_custom_ranger_center_started = False
Global $spirit_slaves_custom_runtime_timer = 0
Global $spirit_slaves_custom_rod_seen[]
Global $spirit_slaves_custom_last_priority_target_id = 0
Global $spirit_slaves_custom_last_priority_reason = ''
Global $spirit_slaves_custom_last_combat_target_id = 0
Global $spirit_slaves_custom_monk_lock_target_id = 0
Global $spirit_slaves_custom_monk_lock_until_ms = 0
Global Const $SSC_MONK_LOCK_DURATION_MS = 9000
Global Const $SSC_MONK_STICK_MAX_DIST = 1600
Global Const $SSC_RANGER_TAIL_CLEANUP_MAX_DIST = 1400
Global Const $SSC_ELE_TAIL_CLEANUP_MAX_DIST = 1400
Global $spirit_slaves_custom_in_kill_sequence = False

;~ Main loop of the farm
Func SpiritSlavesCustomFarm()
	; Safety guard: if we are not in the farming map, force full setup again.
	If GetMapID() <> $ID_THE_SHATTERED_RAVINES Then
		If $spirit_slaves_custom_farm_setup Then Info('Map guard: outside The Shattered Ravines, forcing setup reset')
		$spirit_slaves_custom_farm_setup = False
		$spirit_slaves_custom_in_kill_sequence = False
		$spirit_slaves_custom_ranger_center_started = False
		$spirit_slaves_custom_last_combat_target_id = 0
		SpiritSlavesCustomClearMonkLock()
	EndIf

	If Not $spirit_slaves_custom_farm_setup And SetupSpiritSlavesCustomFarm() == $FAIL Then Return $PAUSE
	Return SpiritSlavesCustomFarmLoop()
EndFunc


Func SpiritSlavesCustomNewEmptyMap()
	Local $map[]
	Return $map
EndFunc


;~ Farm setup : going to the Shattered Ravines
Func SetupSpiritSlavesCustomFarm()
	If GetMapID() <> $ID_THE_SHATTERED_RAVINES Then
		If TravelToOutpost($ID_BONE_PALACE, $district_name) == $FAIL Then Return $FAIL
		SwitchMode($ID_HARD_MODE)
		SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)
		$spirit_slaves_custom_runtime_timer = TimerInit()
		$spirit_slaves_custom_rod_seen = SpiritSlavesCustomNewEmptyMap()
		$spirit_slaves_custom_last_priority_target_id = 0
		$spirit_slaves_custom_last_priority_reason = ''
		$spirit_slaves_custom_last_combat_target_id = 0
		$spirit_slaves_custom_monk_lock_target_id = 0
		$spirit_slaves_custom_monk_lock_until_ms = 0
		$spirit_slaves_custom_in_kill_sequence = False

		If SetupPlayerSpiritSlavesCustomFarm() == $FAIL Then Return $FAIL
		LeaveParty()
		While Not $spirit_slaves_custom_farm_setup
			If SpiritSlavesCustomRunToShatteredRavines() == $FAIL Then ContinueLoop
			$spirit_slaves_custom_farm_setup = True
		WEnd
	EndIf
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerSpiritSlavesCustomFarm()
	Info('Setting up player build skill bar')
	Local $primary = DllStructGetData(GetMyAgent(), 'Primary')
	If $primary == $ID_ELEMENTALIST Then
		$spirit_slaves_custom_mode = $SSC_MODE_ELEMENTALIST
		Info('Spirit Slaves Custom mode: Elementalist')
		LoadSkillTemplate($SPIRIT_SLAVES_CUSTOM_ELE_SKILLBAR)
		RandomSleep(250)
		SpiritSlavesCustomEnsureWeaponSet3('setup-ele')
	ElseIf $primary == $ID_RANGER Then
		$spirit_slaves_custom_mode = $SSC_MODE_RANGER
		Info('Spirit Slaves Custom mode: Ranger')
		LoadSkillTemplate($SPIRIT_SLAVES_CUSTOM_RANGER_SKILLBAR)
		RandomSleep(250)
		SpiritSlavesCustomEnsureWeaponSet3('setup-ranger')
	Else
		Warn('Should run this farm as elementalist or ranger')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func SpiritSlavesCustomEnsureWeaponSet3($reason = '')
	Info('Weapon set enforcement -> 3' & ($reason <> '' ? ' (' & $reason & ')' : ''))
	ChangeWeaponSet(3)
	RandomSleep(120)
EndFunc


Func SpiritSlavesCustomEnsureWeaponSet1($reason = '')
	Info('Weapon set enforcement -> 1' & ($reason <> '' ? ' (' & $reason & ')' : ''))
	ChangeWeaponSet(1)
	RandomSleep(120)
EndFunc


Func SpiritSlavesCustomRefreshReversalCasterMemory($me, $scanRange = $RANGE_COMPASS)
	If $spirit_slaves_custom_runtime_timer == 0 Then $spirit_slaves_custom_runtime_timer = TimerInit()
	Local $nowMs = TimerDiff($spirit_slaves_custom_runtime_timer)
	Local $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	For $agent In $agents
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then ContinueLoop
		If GetIsDead($agent) Or DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If DllStructGetData($agent, 'TypeMap') == $ID_TYPEMAP_IDLE_MINION Then ContinueLoop
		If GetDistance($me, $agent) > $scanRange Then ContinueLoop
		If IsCasting($agent) And DllStructGetData($agent, 'Skill') == $ID_REVERSAL_OF_DAMAGE Then
			$spirit_slaves_custom_rod_seen[DllStructGetData($agent, 'ID')] = $nowMs
		EndIf
	Next
EndFunc


Func SpiritSlavesCustomClearMonkLock()
	$spirit_slaves_custom_monk_lock_target_id = 0
	$spirit_slaves_custom_monk_lock_until_ms = 0
EndFunc


Func SpiritSlavesCustomTryGetMonkLockTarget($me, $range, $nowMs)
	If $spirit_slaves_custom_monk_lock_target_id <= 0 Then Return Null
	If $nowMs > $spirit_slaves_custom_monk_lock_until_ms Then
		SpiritSlavesCustomClearMonkLock()
		Return Null
	EndIf
	If Not GetAgentExists($spirit_slaves_custom_monk_lock_target_id) Then
		SpiritSlavesCustomClearMonkLock()
		Return Null
	EndIf

	Local $locked = GetAgentByID($spirit_slaves_custom_monk_lock_target_id)
	If $locked == Null Then
		SpiritSlavesCustomClearMonkLock()
		Return Null
	EndIf
	If DllStructGetData($locked, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then
		SpiritSlavesCustomClearMonkLock()
		Return Null
	EndIf
	If GetIsDead($locked) Or DllStructGetData($locked, 'HealthPercent') <= 0 Then
		SpiritSlavesCustomClearMonkLock()
		Return Null
	EndIf
	If DllStructGetData($locked, 'TypeMap') == $ID_TYPEMAP_IDLE_MINION Then
		SpiritSlavesCustomClearMonkLock()
		Return Null
	EndIf
	; Keep lock alive even if temporarily out of this query range. Another call with wider
	; range (combat targeting) can still consume it before timeout.
	If GetDistance($me, $locked) > $range Then Return Null

	Return $locked
EndFunc


Func SpiritSlavesCustomLockMonkTarget($targetID, $nowMs)
	$spirit_slaves_custom_monk_lock_target_id = $targetID
	$spirit_slaves_custom_monk_lock_until_ms = $nowMs + $SSC_MONK_LOCK_DURATION_MS
EndFunc


Func SpiritSlavesCustomGetPriorityFoe($me, $range = $RANGE_COMPASS, $preferLockedEvenIfFar = False)
	SpiritSlavesCustomRefreshReversalCasterMemory($me, $range)
	Local $nowMs = TimerDiff($spirit_slaves_custom_runtime_timer)
	Local $rodMemoryMs = 12000
	Local $lockedTarget = SpiritSlavesCustomTryGetMonkLockTarget($me, $range, $nowMs)
	If $lockedTarget == Null And $preferLockedEvenIfFar Then
		; Keep pressure on current monk lock target instead of bouncing to a fallback target.
		Local $farLocked = SpiritSlavesCustomTryGetMonkLockTarget($me, 1000000, $nowMs)
		If $farLocked <> Null Then
			Local $farDist = GetDistance($me, $farLocked)
			If $farDist <= $SSC_MONK_STICK_MAX_DIST Then
				$lockedTarget = $farLocked
			Else
				SpiritSlavesCustomClearMonkLock()
			EndIf
		EndIf
	EndIf
	If $lockedTarget <> Null Then
		Local $lockedID = DllStructGetData($lockedTarget, 'ID')
		If $spirit_slaves_custom_last_priority_reason <> 'monk_lock' Or $spirit_slaves_custom_last_priority_target_id <> $lockedID Then
			Info('priority_monk_lock_target=' & $lockedID)
			$spirit_slaves_custom_last_priority_reason = 'monk_lock'
			$spirit_slaves_custom_last_priority_target_id = $lockedID
		EndIf
		Return $lockedTarget
	EndIf

	Local $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	Local $bestCastingRod = Null
	Local $bestCastingRodDist = 100000000
	Local $bestMonk = Null
	Local $bestMonkHealth = 101
	Local $bestMonkDist = 100000000
	Local $bestRod = Null
	Local $bestRodDist = 100000000

	For $agent In $agents
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then ContinueLoop
		If GetIsDead($agent) Or DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If DllStructGetData($agent, 'TypeMap') == $ID_TYPEMAP_IDLE_MINION Then ContinueLoop
		Local $dist = GetDistance($me, $agent)
		If $dist > $range Then ContinueLoop

		Local $agentID = DllStructGetData($agent, 'ID')
		Local $seenAt = $spirit_slaves_custom_rod_seen[$agentID]
		Local $isRecentRod = $seenAt <> Null And ($nowMs - $seenAt) <= $rodMemoryMs
		Local $isCastingRodNow = IsCasting($agent) And DllStructGetData($agent, 'Skill') == $ID_REVERSAL_OF_DAMAGE
		Local $isMonk = DllStructGetData($agent, 'Primary') == $ID_MONK
		Local $hp = DllStructGetData($agent, 'HealthPercent')

		If $isCastingRodNow Then
			If $dist < $bestCastingRodDist Then
				$bestCastingRod = $agent
				$bestCastingRodDist = $dist
			EndIf
		EndIf

		If $isMonk Then
			If $hp < $bestMonkHealth Or ($hp == $bestMonkHealth And $dist < $bestMonkDist) Then
				$bestMonk = $agent
				$bestMonkHealth = $hp
				$bestMonkDist = $dist
			EndIf
		EndIf

		If $isRecentRod Or $isCastingRodNow Then
			If $dist < $bestRodDist Then
				$bestRod = $agent
				$bestRodDist = $dist
			EndIf
		EndIf
	Next

	If $bestCastingRod <> Null Then
		Local $castingID = DllStructGetData($bestCastingRod, 'ID')
		SpiritSlavesCustomLockMonkTarget($castingID, $nowMs)
		If $spirit_slaves_custom_last_priority_reason <> 'rod_cast' Or $spirit_slaves_custom_last_priority_target_id <> $castingID Then
			Info('priority_rod_cast_target=' & $castingID & ' dist=' & Round($bestCastingRodDist, 0))
			$spirit_slaves_custom_last_priority_reason = 'rod_cast'
			$spirit_slaves_custom_last_priority_target_id = $castingID
		EndIf
		Return $bestCastingRod
	EndIf

	If $bestMonk <> Null Then
		Local $monkID = DllStructGetData($bestMonk, 'ID')
		SpiritSlavesCustomLockMonkTarget($monkID, $nowMs)
		If $spirit_slaves_custom_last_priority_reason <> 'monk_primary' Or $spirit_slaves_custom_last_priority_target_id <> $monkID Then
			Info('priority_monk_primary_target=' & $monkID & ' hp=' & Round($bestMonkHealth, 2) & ' dist=' & Round($bestMonkDist, 0))
			$spirit_slaves_custom_last_priority_reason = 'monk_primary'
			$spirit_slaves_custom_last_priority_target_id = $monkID
		EndIf
		Return $bestMonk
	EndIf

	If $bestRod <> Null Then
		Local $priorityID = DllStructGetData($bestRod, 'ID')
		SpiritSlavesCustomLockMonkTarget($priorityID, $nowMs)
		If $spirit_slaves_custom_last_priority_reason <> 'rod' Or $spirit_slaves_custom_last_priority_target_id <> $priorityID Then
			Info('priority_rod_target=' & $priorityID & ' dist=' & Round($bestRodDist, 0))
			$spirit_slaves_custom_last_priority_reason = 'rod'
			$spirit_slaves_custom_last_priority_target_id = $priorityID
		EndIf
		Return $bestRod
	EndIf

	Local $fallback = GetNearestEnemyToAgent($me, $range)
	If $fallback <> Null Then
		Local $fallbackID = DllStructGetData($fallback, 'ID')
		If $spirit_slaves_custom_last_priority_reason <> 'fallback' Or $spirit_slaves_custom_last_priority_target_id <> $fallbackID Then
			Info('priority_fallback_target=' & $fallbackID)
			$spirit_slaves_custom_last_priority_reason = 'fallback'
			$spirit_slaves_custom_last_priority_target_id = $fallbackID
		EndIf
	ElseIf $spirit_slaves_custom_last_priority_reason <> 'none' Then
		Info('priority_fallback_target=none')
		$spirit_slaves_custom_last_priority_reason = 'none'
		$spirit_slaves_custom_last_priority_target_id = 0
	EndIf

	Return $fallback
EndFunc


Func SpiritSlavesCustomRunToShatteredRavines()
	TravelToOutpost($ID_BONE_PALACE, $district_name)
	; Exiting to Joko's Domain
	MoveTo(-14520, 6009)
	Move(-14820, 3400)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_JOKOS_DOMAIN) Then Return $FAIL
	RandomSleep(500)
	MoveTo(-12657, 2609)
	SpiritSlavesCustomEnsureWeaponSet3('run-to-ravines')
	MoveTo(-10938, 4254)
	; Going to wurm's spoor
	ChangeTarget(GetNearestSignpostToCoords(-10938, 4254))
	RandomSleep(500)
	Info('Taking wurm')
	TargetNearestItem()
	ActionInteract()
	RandomSleep(1500)
	UseSkillEx(5)
	; Starting from there there might be enemies on the way
	MoveTo(-8255, 5320)
	Local $me = GetMyAgent()
	If (CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 0) Then UseSkillEx(5)
	MoveTo(-8624, 10636)
	$me = GetMyAgent()
	If (CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 0) Then UseSkillEx(5)
	MoveTo(-8261, 12808)
	Move(-3838, 19196)
	$me = GetMyAgent()
	While IsPlayerAlive() And IsPlayerMoving()
		If (CountFoesInRangeOfAgent($me, $RANGE_NEARBY) > 0 And IsRecharged(5)) Then UseSkillEx(5)
		RandomSleep(500)
		$me = GetMyAgent()
	WEnd

	; If dead it is not worth rezzing better just restart running
	If IsPlayerDead() Then Return $FAIL

	MoveTo(-4486, 19700)
	RandomSleep(3000)
	MoveTo(-4486, 19700)

	; If dead it is not worth rezzing better just restart running
	If IsPlayerDead() Then Return $FAIL

	; Entering The Shattered Ravines
	SpiritSlavesCustomEnsureWeaponSet3('before-ravines-entry')
	Info('Entering The Shattered Ravines : careful')
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_THE_SHATTERED_RAVINES, 10000, 2000) Then Return $FAIL
	; Hurry up before dying
	MoveTo(-9714, -10767)
	MoveTo(-7919, -10530)
	Return $SUCCESS
EndFunc


;~ Farm loop
Func SpiritSlavesCustomFarmLoop()
	SpiritSlavesCustomEnsureWeaponSet3('farm-loop-start')
	UseConsumable($ID_SLICE_OF_PUMPKIN_PIE)

	Info('Killing group 1 @ North')
	If SpiritSlavesCustomFarmNorthGroup() == $FAIL Then Return SpiritSlavesCustomRestartAfterDeath()
	If $spirit_slaves_custom_mode == $SSC_MODE_RANGER Then SpiritSlavesCustomEnsureWeaponSet1('between-wave-1-and-2-energy-recovery')
	Info('Killing group 2 @ South')
	If SpiritSlavesCustomFarmSouthGroup() == $FAIL Then Return SpiritSlavesCustomRestartAfterDeath()
	Info('Killing group 3 @ South')
	If SpiritSlavesCustomFarmSouthGroup() == $FAIL Then Return SpiritSlavesCustomRestartAfterDeath()
	Info('Killing group 4 @ North')
	If SpiritSlavesCustomFarmNorthGroup() == $FAIL Then Return SpiritSlavesCustomRestartAfterDeath()
	Info('Killing group 5 @ North')
	If SpiritSlavesCustomFarmNorthGroup() == $FAIL Then Return SpiritSlavesCustomRestartAfterDeath()

	Info('Moving out of the zone and back again')
	Move(-7735, -8380)
	SpiritSlavesCustomRezoneToTheShatteredRavines()

	Return $SUCCESS
EndFunc


;~ Rezoning to reset the farm
Func SpiritSlavesCustomRezoneToTheShatteredRavines()
	Info('Rezoning')
	; Exiting to Jokos Domain
	MoveTo(-7800, -10250)
	MoveTo(-9000, -10900)
	MoveTo(-10500, -11000)
	Move(-10656, -11293)
	RandomSleep(1000)
	WaitMapLoading($ID_JOKOS_DOMAIN)
	RandomSleep(500)
	; Reentering The Shattered Ravines
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	WaitMapLoading($ID_THE_SHATTERED_RAVINES, 10000, 2000)
	; Hurry up before dying
	MoveTo(-9714, -10767)
	MoveTo(-7919, -10530)
EndFunc


;~ Farm the north group (group 1, 4 and 5)
Func SpiritSlavesCustomFarmNorthGroup()
	MoveTo(-7375, -7767)
	SpiritSlavesCustomWaitForFoesBall()
	SpiritSlavesCustomWaitForEnergy()
	Local $targetFoe = GetNearestNPCInRangeOfCoords(-8598, -5810, $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe)
	SpiritSlavesCustomEnsureWeaponSet3('north-group')
	If $spirit_slaves_custom_mode == $SSC_MODE_ELEMENTALIST Then
		; Requested order: precast 6/7/8 first, keep 1 for just-before-engage.
		SpiritSlavesCustomMaintainUpkeepEleNoStoneflesh()
		SpiritSlavesCustomEleStabilizeCoreUpkeep(1800)
	Else
		SpiritSlavesCustomStartUpkeepSequence($targetFoe)
		SpiritSlavesCustomMaintainUpkeep($targetFoe)
	EndIf
	RandomSleep(150)
	If IsPlayerDead() Then Return $FAIL

	Local $positionToGo = FindMiddleOfFoes(-8598, -5810, $RANGE_AREA)
	If $spirit_slaves_custom_mode == $SSC_MODE_ELEMENTALIST Then
		; Cast Stoneflesh right before entering the center.
		If IsRecharged($SSC_ELE_STONEFLESH_AURA) And GetEffectTimeRemaining(GetEffect($ID_STONEFLESH_AURA)) == 0 And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_STONEFLESH_AURA] Then UseSkillEx($SSC_ELE_STONEFLESH_AURA)
		RandomSleep(120)
	EndIf
	If $spirit_slaves_custom_mode == $SSC_MODE_ELEMENTALIST Then
		SpiritSlavesCustomEleMoveToCenterOrEngage($positionToGo[0], $positionToGo[1])
	Else
		MoveTo($positionToGo[0], $positionToGo[1])
		RandomSleep(120)
	EndIf
	If $spirit_slaves_custom_mode == $SSC_MODE_ELEMENTALIST Then
		; Chain handles strict 2 -> 3 -> 4 -> 5 cadence.
	Else
		SpiritSlavesCustomMaintainUpkeep($targetFoe)
	EndIf

	If IsPlayerDead() Then Return $FAIL
	If SpiritSlavesCustomKillSequence() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Farm the south group (group 2 and 3)
Func SpiritSlavesCustomFarmSouthGroup()
	If $spirit_slaves_custom_mode == $SSC_MODE_RANGER Then SpiritSlavesCustomEnsureWeaponSet1('south-staging-energy-recovery')
	SpiritSlavesCustomCleanseFromCripple()
	MoveTo(-7830, -7860)
	SpiritSlavesCustomCleanseFromCripple()
	; Wait until an enemy is past the correct aggro line
	Local $foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, SpiritSlavesCustomIsPastAggroLine)
	Local $deadlock = TimerInit()
	While IsPlayerAlive() And $foesCount < 8 And TimerDiff($deadlock) < 120000
		RandomSleep(100)
		$foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, SpiritSlavesCustomIsPastAggroLine)
		SpiritSlavesCustomCleanseFromCripple()
	WEnd
	SpiritSlavesCustomCleanseFromCripple()
	; We want foes between -8055,-9200 and -8055,-9300
	Move(-7735, -8380)
	$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 950)
	$deadlock = TimerInit()
	; Wait until an enemy is aggroed
	While IsPlayerAlive() And $foesCount == 0 And TimerDiff($deadlock) < 120000
		RandomSleep(100)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 950)
	WEnd
	If IsPlayerDead() Then Return $FAIL
	SpiritSlavesCustomWaitForEnergy()

	SpiritSlavesCustomEnsureWeaponSet3('south-group')
	MoveTo(-7800, -7680)
	Local $targetFoe = GetNearestEnemyToAgent(GetMyAgent())
	If $targetFoe == Null Then $targetFoe = GetNearestEnemyToCoords(-8055, -9250)
	If $spirit_slaves_custom_mode == $SSC_MODE_ELEMENTALIST Then
		; Requested order: precast 6/7/8 first, keep 1 for just-before-engage.
		SpiritSlavesCustomMaintainUpkeepEleNoStoneflesh()
		SpiritSlavesCustomEleStabilizeCoreUpkeep(1800)
	Else
		SpiritSlavesCustomStartUpkeepSequence($targetFoe)
		SpiritSlavesCustomMaintainUpkeep($targetFoe)
	EndIf
	If $spirit_slaves_custom_mode == $SSC_MODE_RANGER Then
		; South pulls are spike-heavy: do not commit until core defense is genuinely up.
		Local $stable = SpiritSlavesCustomRangerStabilizeCoreDefense($targetFoe, 2400)
		If Not $stable Then
			Info('ranger_south_precommit_unstable holding_position')
			SpiritSlavesCustomRangerStabilizeCoreDefense($targetFoe, 1200)
		EndIf
	EndIf
	RandomSleep(150)

	If IsPlayerDead() Then Return $FAIL

	Local $positionToGo = FindMiddleOfFoes(-8055, -9250, $RANGE_NEARBY)
	If $spirit_slaves_custom_mode == $SSC_MODE_ELEMENTALIST Then
		; Cast Stoneflesh right before entering the center.
		If IsRecharged($SSC_ELE_STONEFLESH_AURA) And GetEffectTimeRemaining(GetEffect($ID_STONEFLESH_AURA)) == 0 And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_STONEFLESH_AURA] Then UseSkillEx($SSC_ELE_STONEFLESH_AURA)
		RandomSleep(120)
	EndIf
	If $spirit_slaves_custom_mode == $SSC_MODE_ELEMENTALIST Then
		SpiritSlavesCustomEleMoveToCenterOrEngage($positionToGo[0], $positionToGo[1])
	Else
		MoveTo($positionToGo[0], $positionToGo[1])
		RandomSleep(120)
	EndIf
	$targetFoe = GetNearestEnemyToAgent(GetMyAgent())
	If $spirit_slaves_custom_mode == $SSC_MODE_ELEMENTALIST Then
		; Chain handles strict 2 -> 3 -> 4 -> 5 cadence.
	Else
		SpiritSlavesCustomMaintainUpkeep($targetFoe)
	EndIf

	If IsPlayerDead() Then Return $FAIL
	If SpiritSlavesCustomKillSequence() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func SpiritSlavesCustomStartUpkeepSequence($target = Null)
	If $spirit_slaves_custom_mode == $SSC_MODE_ELEMENTALIST Then
		SpiritSlavesCustomMaintainUpkeepEle($target)
		Return
	EndIf

	If IsRecharged($SSC_DWARVEN_STABILITY) And GetEffectTimeRemaining(GetEffect($ID_DWARVEN_STABILITY)) == 0 And GetEnergy() >= $SSC_SKILL_COSTS_MAP[$SSC_DWARVEN_STABILITY] Then UseSkillEx($SSC_DWARVEN_STABILITY)
	If IsRecharged($SSC_MENTAL_BLOCK) And GetEffectTimeRemaining(GetEffect($ID_MENTAL_BLOCK)) == 0 And GetEnergy() >= $SSC_SKILL_COSTS_MAP[$SSC_MENTAL_BLOCK] Then UseSkillEx($SSC_MENTAL_BLOCK)
	If IsRecharged($SSC_ESCAPE) And GetEffectTimeRemaining(GetEffect($ID_ESCAPE)) == 0 And GetEnergy() >= $SSC_SKILL_COSTS_MAP[$SSC_ESCAPE] Then UseSkillEx($SSC_ESCAPE)
	If IsRecharged($SSC_MYSTIC_VIGOR) And GetEffectTimeRemaining(GetEffect($ID_MYSTIC_VIGOR)) == 0 And GetEnergy() >= $SSC_SKILL_COSTS_MAP[$SSC_MYSTIC_VIGOR] Then UseSkillEx($SSC_MYSTIC_VIGOR)
EndFunc


Func SpiritSlavesCustomMaintainUpkeep($target = Null)
	If $spirit_slaves_custom_mode == $SSC_MODE_ELEMENTALIST Then
		SpiritSlavesCustomMaintainUpkeepEle($target)
		Return
	EndIf

	If IsRecharged($SSC_DWARVEN_STABILITY) And GetEffectTimeRemaining(GetEffect($ID_DWARVEN_STABILITY)) == 0 And GetEnergy() >= $SSC_SKILL_COSTS_MAP[$SSC_DWARVEN_STABILITY] Then UseSkillEx($SSC_DWARVEN_STABILITY)
	If IsRecharged($SSC_MENTAL_BLOCK) And GetEffectTimeRemaining(GetEffect($ID_MENTAL_BLOCK)) == 0 And GetEnergy() >= $SSC_SKILL_COSTS_MAP[$SSC_MENTAL_BLOCK] Then UseSkillEx($SSC_MENTAL_BLOCK)
	If IsRecharged($SSC_ESCAPE) And GetEffectTimeRemaining(GetEffect($ID_ESCAPE)) == 0 And GetEnergy() >= $SSC_SKILL_COSTS_MAP[$SSC_ESCAPE] Then UseSkillEx($SSC_ESCAPE)
	If IsRecharged($SSC_MYSTIC_VIGOR) And GetEffectTimeRemaining(GetEffect($ID_MYSTIC_VIGOR)) == 0 And GetEnergy() >= $SSC_SKILL_COSTS_MAP[$SSC_MYSTIC_VIGOR] Then UseSkillEx($SSC_MYSTIC_VIGOR)
	If IsRecharged($SSC_GRENTHS_AURA) And GetEnergy() > 20 And ($spirit_slaves_custom_in_kill_sequence Or CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY) > 0) Then UseSkillEx($SSC_GRENTHS_AURA)
	If $spirit_slaves_custom_ranger_center_started Then
		; Outside kill sequence (routing/loot callbacks), do not auto-acquire combat targets.
		If $target == Null And $spirit_slaves_custom_in_kill_sequence Then $target = SpiritSlavesCustomGetPriorityFoe(GetMyAgent(), $RANGE_COMPASS)
		If $target <> Null And IsRecharged($SSC_YOU_ARE_ALL_WEAKLINGS) And GetEnergy() >= $SSC_SKILL_COSTS_MAP[$SSC_YOU_ARE_ALL_WEAKLINGS] Then UseSkillEx($SSC_YOU_ARE_ALL_WEAKLINGS, $target)
	EndIf
EndFunc


Func SpiritSlavesCustomRangerHasCoreDefenseUp()
	If GetEffectTimeRemaining(GetEffect($ID_DWARVEN_STABILITY)) == 0 Then Return False
	If GetEffectTimeRemaining(GetEffect($ID_MENTAL_BLOCK)) == 0 Then Return False
	If GetEffectTimeRemaining(GetEffect($ID_ESCAPE)) == 0 Then Return False
	If GetEffectTimeRemaining(GetEffect($ID_MYSTIC_VIGOR)) == 0 Then Return False
	Return True
EndFunc


Func SpiritSlavesCustomRangerStabilizeCoreDefense($target = Null, $maxWaitMs = 2200)
	Local $stabilize = TimerInit()
	While IsPlayerAlive() And TimerDiff($stabilize) < $maxWaitMs
		SpiritSlavesCustomMaintainUpkeep($target)
		If SpiritSlavesCustomRangerHasCoreDefenseUp() And DllStructGetData(GetMyAgent(), 'HealthPercent') >= 0.65 Then Return True
		RandomSleep(120)
	WEnd
	Return SpiritSlavesCustomRangerHasCoreDefenseUp()
EndFunc


Func SpiritSlavesCustomMaintainUpkeepEle($target = Null)
	Local $stonefleshMissing = GetEffectTimeRemaining(GetEffect($ID_STONEFLESH_AURA)) == 0
	; Absolute priority: if Stoneflesh is down, do not spend energy on other upkeep.
	If $stonefleshMissing Then
		If IsRecharged($SSC_ELE_STONEFLESH_AURA) And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_STONEFLESH_AURA] Then UseSkillEx($SSC_ELE_STONEFLESH_AURA)
		Return
	EndIf

	If IsRecharged($SSC_ELE_ELEMENTAL_LORD) And GetEffectTimeRemaining(GetEffect($ID_ELEMENTAL_LORD_LUXON)) == 0 And GetEffectTimeRemaining(GetEffect($ID_ELEMENTAL_LORD_KURZICK)) == 0 And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_ELEMENTAL_LORD] Then UseSkillEx($SSC_ELE_ELEMENTAL_LORD)
	If IsRecharged($SSC_ELE_CHANNELING) And GetEffectTimeRemaining(GetEffect($ID_CHANNELING)) == 0 And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_CHANNELING] Then UseSkillEx($SSC_ELE_CHANNELING)
	If IsRecharged($SSC_ELE_MANTRA_OF_RESOLVE) And GetEffectTimeRemaining(GetEffect($ID_MANTRA_OF_RESOLVE)) == 0 And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_MANTRA_OF_RESOLVE] Then UseSkillEx($SSC_ELE_MANTRA_OF_RESOLVE)
	; Keep Stoneflesh fresher by casting it after 6/7/8 are settled.
	If IsRecharged($SSC_ELE_STONEFLESH_AURA) And GetEffectTimeRemaining(GetEffect($ID_STONEFLESH_AURA)) == 0 And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_STONEFLESH_AURA] Then UseSkillEx($SSC_ELE_STONEFLESH_AURA)
	If IsRecharged($SSC_ELE_EBON_BATTLE_STANDARD_OF_HONOR) And GetEffectTimeRemaining(GetEffect($ID_EBON_BATTLE_STANDARD_OF_HONOR)) == 0 And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_EBON_BATTLE_STANDARD_OF_HONOR] Then UseSkillEx($SSC_ELE_EBON_BATTLE_STANDARD_OF_HONOR)
EndFunc


Func SpiritSlavesCustomMaintainUpkeepEleNoStoneflesh()
	; Pre-combat variant: intentionally skip Stoneflesh so it can be cast right before center commit.
	If IsRecharged($SSC_ELE_ELEMENTAL_LORD) And GetEffectTimeRemaining(GetEffect($ID_ELEMENTAL_LORD_LUXON)) == 0 And GetEffectTimeRemaining(GetEffect($ID_ELEMENTAL_LORD_KURZICK)) == 0 And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_ELEMENTAL_LORD] Then UseSkillEx($SSC_ELE_ELEMENTAL_LORD)
	If IsRecharged($SSC_ELE_CHANNELING) And GetEffectTimeRemaining(GetEffect($ID_CHANNELING)) == 0 And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_CHANNELING] Then UseSkillEx($SSC_ELE_CHANNELING)
	If IsRecharged($SSC_ELE_MANTRA_OF_RESOLVE) And GetEffectTimeRemaining(GetEffect($ID_MANTRA_OF_RESOLVE)) == 0 And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_MANTRA_OF_RESOLVE] Then UseSkillEx($SSC_ELE_MANTRA_OF_RESOLVE)
EndFunc


Func SpiritSlavesCustomEleHasCoreUpkeep()
	If GetEffectTimeRemaining(GetEffect($ID_ELEMENTAL_LORD_LUXON)) == 0 And GetEffectTimeRemaining(GetEffect($ID_ELEMENTAL_LORD_KURZICK)) == 0 Then Return False
	If GetEffectTimeRemaining(GetEffect($ID_CHANNELING)) == 0 Then Return False
	If GetEffectTimeRemaining(GetEffect($ID_MANTRA_OF_RESOLVE)) == 0 Then Return False
	Return True
EndFunc


Func SpiritSlavesCustomEleStabilizeCoreUpkeep($maxWaitMs = 1600)
	Local $stabilize = TimerInit()
	While IsPlayerAlive() And TimerDiff($stabilize) < $maxWaitMs
		If SpiritSlavesCustomEleHasCoreUpkeep() Then Return True
		SpiritSlavesCustomMaintainUpkeepEleNoStoneflesh()
		RandomSleep(120)
	WEnd
	Return SpiritSlavesCustomEleHasCoreUpkeep()
EndFunc


Func SpiritSlavesCustomEleMoveToCenterOrEngage($centerX, $centerY, $maxMs = 1800)
	Local $me = GetMyAgent()
	Local $previousDist = GetDistanceToPoint($me, $centerX, $centerY)
	Local $stuckTicks = 0
	Local $t = TimerInit()

	While IsPlayerAlive() And TimerDiff($t) < $maxMs
		If $previousDist <= $RANGE_ADJACENT Then ExitLoop
		Move($centerX, $centerY)
		RandomSleep(90)
		$me = GetMyAgent()
		Local $dist = GetDistanceToPoint($me, $centerX, $centerY)
		If ($previousDist - $dist) < 45 Then
			$stuckTicks += 1
		Else
			$stuckTicks = 0
		EndIf
		$previousDist = $dist
		If $stuckTicks >= 4 Then
			Info('ele_center_blocked_fastcast dist=' & Round($dist, 0))
			ExitLoop
		EndIf
	WEnd
EndFunc


Func SpiritSlavesCustomHasAdrenaline($skillSlot, $requiredStrikes)
	; GW returns adrenaline in strike units here, not in a 0..100 gauge.
	Return GetSkillbarSkillAdrenaline($skillSlot) >= $requiredStrikes
EndFunc


Func SpiritSlavesCustomTryUseAdrenalineSkill($skillSlot, $target)
	Local $beforeAdren = GetSkillbarSkillAdrenaline($skillSlot)
	UseSkillEx($skillSlot, $target)
	Local $accepted = False
	Local $t = TimerInit()
	While TimerDiff($t) < 250
		If Not IsRecharged($skillSlot) Then
			$accepted = True
			ExitLoop
		EndIf
		If GetSkillbarSkillAdrenaline($skillSlot) < $beforeAdren Then
			$accepted = True
			ExitLoop
		EndIf
		RandomSleep(20)
	WEnd
	Return $accepted
EndFunc


Func SpiritSlavesCustomCastAttackChain($target, $reset = False)
	Static $chainStage = 1
	Static $chainTimer = 0
	Static $nextDelayMs = 0
	Static $lastSkill5Attempt = 0
	Static $lastSkill6Attempt = 0

	If $reset Then
		$chainStage = 1
		$chainTimer = TimerInit()
		$nextDelayMs = 0
		$lastSkill5Attempt = TimerInit()
		$lastSkill6Attempt = TimerInit()
		Return
	EndIf

	If $target == Null Then Return
	If $chainTimer <> 0 And TimerDiff($chainTimer) < $nextDelayMs Then Return

	If $spirit_slaves_custom_mode == $SSC_MODE_ELEMENTALIST Then
		; Never burn the 3/4/5 window while Stoneflesh is down.
		If GetEffectTimeRemaining(GetEffect($ID_STONEFLESH_AURA)) == 0 Then Return

		Switch $chainStage
			Case 1
				If IsRecharged($SSC_ELE_EBON_BATTLE_STANDARD_OF_HONOR) And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_EBON_BATTLE_STANDARD_OF_HONOR] Then
					UseSkillEx($SSC_ELE_EBON_BATTLE_STANDARD_OF_HONOR)
					$chainStage = 2
					$chainTimer = TimerInit()
					$nextDelayMs = 1000
				EndIf
			Case 2
				If IsRecharged($SSC_ELE_AFTERSHOCK) And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_AFTERSHOCK] Then
					UseSkillEx($SSC_ELE_AFTERSHOCK, $target)
					$chainStage = 3
					$chainTimer = TimerInit()
					$nextDelayMs = 1000
				EndIf
			Case 3
				If IsRecharged($SSC_ELE_SHOCKWAVE) And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_SHOCKWAVE] Then
					UseSkillEx($SSC_ELE_SHOCKWAVE, $target)
					$chainStage = 4
					$chainTimer = TimerInit()
					$nextDelayMs = 1000
				EndIf
			Case 4
				If IsRecharged($SSC_ELE_CRYSTAL_WAVE) And GetEnergy() >= $SSC_ELE_SKILL_COSTS_MAP[$SSC_ELE_CRYSTAL_WAVE] Then
					UseSkillEx($SSC_ELE_CRYSTAL_WAVE, $target)
					$chainStage = 1
					$chainTimer = TimerInit()
					$nextDelayMs = 1000
				EndIf
		EndSwitch
	Else
		; Ranger: strict order 5 -> 6 with adrenaline gates.
		Attack($target)
		If $chainStage == 1 Then
			If TimerDiff($lastSkill5Attempt) >= $SSC_RANGER_CHAIN_RETRY_MS And IsRecharged($SSC_CRIPPLING_VICTORY) And SpiritSlavesCustomHasAdrenaline($SSC_CRIPPLING_VICTORY, $SSC_RANGER_CHAIN_MIN_ADREN5) Then
				Local $s5Adren = GetSkillbarSkillAdrenaline($SSC_CRIPPLING_VICTORY)
				Local $s5Accepted = SpiritSlavesCustomTryUseAdrenalineSkill($SSC_CRIPPLING_VICTORY, $target)
				If Not $s5Accepted Then
					RandomSleep(70)
					If IsRecharged($SSC_CRIPPLING_VICTORY) And SpiritSlavesCustomHasAdrenaline($SSC_CRIPPLING_VICTORY, $SSC_RANGER_CHAIN_MIN_ADREN5) Then
						$s5Accepted = SpiritSlavesCustomTryUseAdrenalineSkill($SSC_CRIPPLING_VICTORY, $target)
					EndIf
				EndIf
				If $s5Accepted Then
					If Not $spirit_slaves_custom_ranger_center_started Then
						$spirit_slaves_custom_ranger_center_started = True
						Info('Ranger center reached: enabling skills 2 and 4')
					EndIf
					Info('ranger_s5_ok adren=' & $s5Adren)
					$chainStage = 2
					$chainTimer = TimerInit()
					$nextDelayMs = 120
				EndIf
				$lastSkill5Attempt = TimerInit()
			EndIf
		Else
			If TimerDiff($lastSkill6Attempt) >= $SSC_RANGER_CHAIN_RETRY_MS And IsRecharged($SSC_REAP_IMPURITIES) And SpiritSlavesCustomHasAdrenaline($SSC_REAP_IMPURITIES, $SSC_RANGER_CHAIN_MIN_ADREN6) Then
				Local $s6Adren = GetSkillbarSkillAdrenaline($SSC_REAP_IMPURITIES)
				If SpiritSlavesCustomTryUseAdrenalineSkill($SSC_REAP_IMPURITIES, $target) Then
					Info('ranger_s6_ok adren=' & $s6Adren)
					$chainStage = 1
					$chainTimer = TimerInit()
					$nextDelayMs = 120
				EndIf
				$lastSkill6Attempt = TimerInit()
			EndIf
		EndIf
	EndIf
EndFunc


;~ Kill a mob group
Func SpiritSlavesCustomKillSequence()
	Local $deadlock = TimerInit()
	Local $foesCountArea = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	Local $foesCount = $foesCountArea
	Local $maxDeadlockMs = 100000
	If $spirit_slaves_custom_mode == $SSC_MODE_RANGER Then $maxDeadlockMs = 150000
	Local $rangerTailCleanup = False
	Local $loopExitReason = 'unknown'
	Local $rangerLastOffense = 0
	If $spirit_slaves_custom_mode == $SSC_MODE_RANGER Then $rangerLastOffense = TimerInit()
	; After blocked moves / transitions, area count can briefly read as 0.
	; Recover before deciding there is nothing to fight.
	If $foesCountArea == 0 Then
		Local $syncTimer = TimerInit()
		While IsPlayerAlive() And $foesCountArea == 0 And TimerDiff($syncTimer) < 1800
			RandomSleep(120)
			$foesCountArea = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
			If $foesCountArea > 0 Then
				Info('kill_start_sync_recovered foes(area)=' & $foesCountArea)
				ExitLoop
			EndIf
			Local $syncTarget = SpiritSlavesCustomGetPriorityFoe(GetMyAgent(), $RANGE_COMPASS)
			If $syncTarget <> Null And GetDistance(GetMyAgent(), $syncTarget) <= $RANGE_EARSHOT Then
				$foesCountArea = 1
				Info('kill_start_sync_target=' & DllStructGetData($syncTarget, 'ID'))
				ExitLoop
			EndIf
		WEnd
		$foesCount = $foesCountArea
	EndIf
	If $spirit_slaves_custom_mode == $SSC_MODE_RANGER Then $spirit_slaves_custom_ranger_center_started = False
	$spirit_slaves_custom_last_combat_target_id = 0
	SpiritSlavesCustomClearMonkLock()
	$spirit_slaves_custom_in_kill_sequence = True
	SpiritSlavesCustomEnsureWeaponSet3('kill-sequence-start')
	Info('Kill sequence start: foes(area)=' & $foesCountArea)
	SpiritSlavesCustomCastAttackChain(Null, True)
	While IsPlayerAlive() And $foesCount > 0 And TimerDiff($deadlock) < $maxDeadlockMs
		Local $me = GetMyAgent()
		Local $foesInEarshot = CountFoesInRangeOfAgent($me, $RANGE_EARSHOT)
		If $spirit_slaves_custom_mode == $SSC_MODE_ELEMENTALIST Then
			SpiritSlavesCustomMaintainUpkeep()
			If $foesInEarshot > 0 Then
				; If enemies are already in earshot, immediately cast on the nearest local target.
				; Reserve monk-priority for small remainders to avoid pathing ping-pong.
				Local $engageTarget = Null
				If $foesCount > 3 Then
					$engageTarget = GetNearestEnemyToAgent($me, $RANGE_EARSHOT)
				Else
					$engageTarget = SpiritSlavesCustomGetPriorityFoe($me, $RANGE_EARSHOT)
					If $engageTarget == Null Then $engageTarget = GetNearestEnemyToAgent($me, $RANGE_EARSHOT)
				EndIf
				If $engageTarget <> Null Then
					ChangeTarget($engageTarget)
					SpiritSlavesCustomCastAttackChain($engageTarget)
				EndIf
			Else
				; No local foe: step to the nearest target that is coming in and start casting ASAP.
				Local $nextFoe = GetNearestEnemyToAgent($me, $RANGE_COMPASS)
				If $foesCount <= 3 And $nextFoe == Null Then $nextFoe = SpiritSlavesCustomGetPriorityFoe($me, $RANGE_COMPASS)
				If $nextFoe <> Null Then
					Local $approachTimer = TimerInit()
					While IsPlayerAlive() And GetDistance($me, $nextFoe) > $RANGE_EARSHOT And TimerDiff($approachTimer) < 900
						Move(DllStructGetData($nextFoe, 'X'), DllStructGetData($nextFoe, 'Y'))
						SpiritSlavesCustomMaintainUpkeep()
						RandomSleep(90)
						$me = GetMyAgent()
					WEnd
					If GetDistance($me, $nextFoe) <= $RANGE_EARSHOT Then
						ChangeTarget($nextFoe)
						SpiritSlavesCustomCastAttackChain($nextFoe)
					EndIf
				EndIf
			EndIf
		Else
			; Ranger: stay on target and auto-attack to build adrenaline for 5 -> 6 choreography.
			Local $target = SpiritSlavesCustomGetPriorityFoe($me, $RANGE_COMPASS, True)
			If $target == Null Then $target = GetNearestEnemyToCoords(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'))
			SpiritSlavesCustomMaintainUpkeep($target)
			If $target <> Null Then
				Local $targetID = DllStructGetData($target, 'ID')
				Local $targetDist = GetDistance($me, $target)
				If $foesInEarshot > 0 And $targetDist > $RANGE_EARSHOT Then
					Local $localAggro = GetNearestEnemyToAgent($me, $RANGE_EARSHOT)
					If $localAggro <> Null Then
						$target = $localAggro
						$targetID = DllStructGetData($target, 'ID')
						$targetDist = GetDistance($me, $target)
						Info('ranger_local_aggro_override=' & $targetID)
					EndIf
				EndIf
				If $spirit_slaves_custom_last_combat_target_id <> $targetID Then
					Info('ranger_hardswitch_target=' & $targetID)
					$spirit_slaves_custom_last_combat_target_id = $targetID
					SpiritSlavesCustomCastAttackChain(Null, True)
				EndIf

				If $foesCount <= 2 And $targetDist > $RANGE_ADJACENT Then
					Local $closeChaseTimer = TimerInit()
					While IsPlayerAlive() And GetDistance($me, $target) > $RANGE_ADJACENT And TimerDiff($closeChaseTimer) < 1200
						Move(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'))
						SpiritSlavesCustomMaintainUpkeep($target)
						RandomSleep(80)
						$me = GetMyAgent()
					WEnd
					$targetDist = GetDistance($me, $target)
				ElseIf $targetDist > $RANGE_NEARBY Then
					Local $chaseTimer = TimerInit()
					While IsPlayerAlive() And GetDistance($me, $target) > $RANGE_NEARBY And TimerDiff($chaseTimer) < 900
						Move(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'))
						SpiritSlavesCustomMaintainUpkeep($target)
						RandomSleep(80)
						$me = GetMyAgent()
					WEnd
					$targetDist = GetDistance($me, $target)
				EndIf

				ChangeTarget($target)
				Attack($target)
				$rangerLastOffense = TimerInit()

				If $targetDist < $RANGE_EARSHOT Then
					If Not $spirit_slaves_custom_ranger_center_started Then
						Info('Ranger center reached: enabling skills 2 and 4')
						If IsRecharged($SSC_YOU_ARE_ALL_WEAKLINGS) And GetEnergy() >= $SSC_SKILL_COSTS_MAP[$SSC_YOU_ARE_ALL_WEAKLINGS] Then UseSkillEx($SSC_YOU_ARE_ALL_WEAKLINGS, $target)
						If IsRecharged($SSC_GRENTHS_AURA) And GetEffectTimeRemaining(GetEffect($ID_GRENTHS_AURA)) == 0 And GetEnergy() >= $SSC_SKILL_COSTS_MAP[$SSC_GRENTHS_AURA] Then UseSkillEx($SSC_GRENTHS_AURA)
						$spirit_slaves_custom_ranger_center_started = True
					EndIf
					SpiritSlavesCustomCastAttackChain($target)
					$rangerLastOffense = TimerInit()
				EndIf
			ElseIf TimerDiff($rangerLastOffense) > 1400 Then
				; Anti-idle fallback: force a fresh nearest target/attack when targeting stalls.
				Local $panic = GetNearestEnemyToCoords(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'))
				If $panic <> Null Then
					Info('ranger_offense_watchdog_retarget=' & DllStructGetData($panic, 'ID'))
					ChangeTarget($panic)
					Attack($panic)
					If GetDistance($me, $panic) > $RANGE_NEARBY Then Move(DllStructGetData($panic, 'X'), DllStructGetData($panic, 'Y'))
				EndIf
				$rangerLastOffense = TimerInit()
			EndIf
		EndIf
		RandomSleep(220)
		$foesCountArea = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
		$foesCount = $foesCountArea
		If $spirit_slaves_custom_mode == $SSC_MODE_RANGER And $foesCountArea == 0 Then
			Local $tailTarget = SpiritSlavesCustomGetPriorityFoe(GetMyAgent(), $RANGE_COMPASS, True)
			If $tailTarget <> Null Then
				Local $tailDist = GetDistance(GetMyAgent(), $tailTarget)
				If $tailDist <= $SSC_RANGER_TAIL_CLEANUP_MAX_DIST Then
					$foesCount = 1
					If Not $rangerTailCleanup Then
						Info('ranger_tail_cleanup_target=' & DllStructGetData($tailTarget, 'ID') & ' dist=' & Round($tailDist, 0))
						$rangerTailCleanup = True
					EndIf
				Else
					$rangerTailCleanup = False
				EndIf
			Else
				$rangerTailCleanup = False
			EndIf
		ElseIf $spirit_slaves_custom_mode == $SSC_MODE_ELEMENTALIST And $foesCountArea == 0 Then
			Local $eleTailTarget = SpiritSlavesCustomGetPriorityFoe(GetMyAgent(), $RANGE_COMPASS)
			If $eleTailTarget <> Null Then
				Local $eleTailDist = GetDistance(GetMyAgent(), $eleTailTarget)
				If $eleTailDist <= $SSC_ELE_TAIL_CLEANUP_MAX_DIST Then
					$foesCount = 1
					If Not $rangerTailCleanup Then
						Info('ele_tail_cleanup_target=' & DllStructGetData($eleTailTarget, 'ID') & ' dist=' & Round($eleTailDist, 0))
						$rangerTailCleanup = True
					EndIf
				Else
					$rangerTailCleanup = False
				EndIf
			Else
				$rangerTailCleanup = False
			EndIf
		Else
			$rangerTailCleanup = False
		EndIf
	WEnd
	If Not IsPlayerAlive() Then
		$loopExitReason = 'player_dead'
	ElseIf TimerDiff($deadlock) >= $maxDeadlockMs Then
		$loopExitReason = 'deadlock_timeout'
	ElseIf $foesCountArea <= 0 Then
		$loopExitReason = 'no_foes_in_area'
	Else
		$loopExitReason = 'loop_condition_changed'
	EndIf
	$spirit_slaves_custom_in_kill_sequence = False
	$spirit_slaves_custom_last_combat_target_id = 0
	SpiritSlavesCustomClearMonkLock()
	Info('Kill sequence end: reason=' & $loopExitReason & ' foes(area)=' & CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA))

	If IsPlayerDead() Then Return $FAIL
	SpiritSlavesCustomEnsureWeaponSet3('kill-sequence-end')
	SpiritSlavesCustomCastAttackChain(Null, True)
	SpiritSlavesCustomMaintainUpkeep()
	RandomSleep(1000)
	PickUpItems(SpiritSlavesCustomMaintainUpkeep)
	Return $SUCCESS
EndFunc


;~ Wait for all ennemies to be balled
Func SpiritSlavesCustomWaitForFoesBall()
	SpiritSlavesCustomWaitForAlliesDead()

	Local $deadlock = TimerInit()
	Local $target = GetNearestEnemyToCoords(-8598, -5810)
	Local $foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
	Local $validation = 0

	; Wait until all foes are balled
	While IsPlayerAlive() And $foesCount < 8 And $validation < 2 And TimerDiff($deadlock) < 120000
		If $foesCount == 8 Then $validation += 1
		RandomSleep(3000)
		$target = GetNearestEnemyToCoords(-8598, -5810)
		$foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
		Debug('foes: ' & $foesCount & '/8')
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Info('Timed out waiting for mobs to ball')
EndFunc


;~ Wait for all enemies to be balled and allies to be dead
Func SpiritSlavesCustomWaitForAlliesDead()
	Local $deadlock = TimerInit()
	Local $target = GetNearestNPCToCoords(-8598, -5810)

	; Wait until foes are in range of allies
	While GetDistanceToPoint($target, -8598, -5810) < $RANGE_EARSHOT And TimerDiff($deadlock) < 120000
		RandomSleep(5000)
		$target = GetNearestNPCToCoords(-8598, -5810)
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Info('Timed out waiting for allies to be dead')
EndFunc


;~ Respawn and rezone if we die
Func SpiritSlavesCustomRestartAfterDeath()
	Local $deadlockTimer = TimerInit()
	Info('Waiting for resurrection')
	While IsPlayerDead()
		RandomSleep(1000)
		; If game already moved us to outpost, force full setup on next iteration.
		If GetMapID() == $ID_BONE_PALACE Then
			$spirit_slaves_custom_farm_setup = False
			$spirit_slaves_custom_in_kill_sequence = False
			$spirit_slaves_custom_ranger_center_started = False
			$spirit_slaves_custom_last_combat_target_id = 0
			SpiritSlavesCustomClearMonkLock()
			Info('Death recovery reached Bone Palace: forcing full restart loop')
			Return $FAIL
		EndIf
		If TimerDiff($deadlockTimer) > 60000 Then
			; Full reset so next loop re-runs setup and outpost -> ravines travel.
			$spirit_slaves_custom_farm_setup = False
			$spirit_slaves_custom_in_kill_sequence = False
			$spirit_slaves_custom_ranger_center_started = False
			$spirit_slaves_custom_last_combat_target_id = 0
			SpiritSlavesCustomClearMonkLock()
			Info('Travelling to Bone Palace (reset state)')
			TravelToOutpost($ID_BONE_PALACE, $district_name)
			Return $FAIL
		EndIf
	WEnd

	; If resurrection happened outside the farm map, skip rezone and rebuild from setup.
	If GetMapID() <> $ID_THE_SHATTERED_RAVINES Then
		$spirit_slaves_custom_farm_setup = False
		$spirit_slaves_custom_in_kill_sequence = False
		$spirit_slaves_custom_ranger_center_started = False
		$spirit_slaves_custom_last_combat_target_id = 0
		SpiritSlavesCustomClearMonkLock()
		Info('Resurrected outside ravines: forcing full restart loop')
		Return $FAIL
	EndIf

	SpiritSlavesCustomRezoneToTheShatteredRavines()
	If GetMapID() <> $ID_THE_SHATTERED_RAVINES Then $spirit_slaves_custom_farm_setup = False
	Return $FAIL
EndFunc


;~ Wait to have enough energy before jumping into the next group
Func SpiritSlavesCustomWaitForEnergy()
	While (GetEnergy() < 20) And IsPlayerAlive()
		RandomSleep(1000)
	WEnd
EndFunc


;~ Cleanse if the character has a condition (cripple)
Func SpiritSlavesCustomCleanseFromCripple()
	If $spirit_slaves_custom_mode == $SSC_MODE_ELEMENTALIST And Not $spirit_slaves_custom_in_kill_sequence Then
		SpiritSlavesCustomMaintainUpkeepEleNoStoneflesh()
	Else
		SpiritSlavesCustomMaintainUpkeep()
	EndIf
EndFunc


;~ Give True if the given agent is past a specific line where we should take aggro
Func SpiritSlavesCustomIsPastAggroLine($agent)
	Return Not IsOverLine(1, 0, 6750, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
	; 6500 works too, but slightly too early, some mobs stay downstairs
	;Return Not IsOverLine(1, 0, 6500, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
	; 7000 works but is slightly too late, sometimes mobs do not get aggroed
	;Return Not IsOverLine(1, 0, 7000, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
EndFunc


;~ @Unused
;~ Unused but good learning practice ;)
Func SpiritSlavesCustomGetTemporaryPosition($startX, $startY, $endX, $endY)
	Local $distanceStartToEnd = ComputeDistance($startX, $startY, $endX, $endY)
	Local $xMovement = $endX - $startX
	Local $yMovement = $endY - $startY
	; To rotate a movement to the right: Y1 = -X0, X1 = Y0
	; That gives us the 90° movement, add it to the original and you get a 45° angle
	; Reduce it by 2 to have the correct length
	Local $xMove45degrees = ($xMovement + $yMovement) / 2
	Local $yMove45degrees = ($yMovement - $xMovement) / 2
	Local $temporaryPosition[] = [$startX + $xMove45degrees, $startY + $yMove45degrees]
	Return $temporaryPosition
EndFunc
