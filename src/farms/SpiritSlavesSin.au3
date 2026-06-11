#include-once

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

Global Const $SPIRIT_SLAVES_SIN_SKILLBAR = 'OwNj0gd74SOMMMHMSQ4O+DDQ1gA'
Global Const $SPIRIT_SLAVES_SIN_FARM_INFORMATIONS = 'Original Assassin variant of Spirit Slaves'
Global Const $SPIRIT_SLAVES_SIN_FARM_DURATION = 10 * 60 * 1000

Global Const $SSS_JAGGED_STRIKE = 1
Global Const $SSS_FOX_FANGS = 2
Global Const $SSS_DEATH_BLOSSOM = 3
Global Const $SSS_FLASHING_BLADES = 4
Global Const $SSS_DEATHS_CHARGE = 5
Global Const $SSS_CRITICAL_DEFENSES = 6
Global Const $SSS_CRITICAL_AGILITY = 7
Global Const $SSS_VIGOROUS_SPIRIT = 8

Global Const $SSS_SKILLS_ARRAY = [$SSS_JAGGED_STRIKE, $SSS_FOX_FANGS, $SSS_DEATH_BLOSSOM, $SSS_FLASHING_BLADES, $SSS_DEATHS_CHARGE, $SSS_CRITICAL_DEFENSES, $SSS_CRITICAL_AGILITY, $SSS_VIGOROUS_SPIRIT]
Global Const $SSS_SKILLS_COSTS_ARRAY = [5, 5, 5, 10, 5, 10, 5, 5]
Global Const $SSS_SKILL_COSTS_MAP = MapFromArrays($SSS_SKILLS_ARRAY, $SSS_SKILLS_COSTS_ARRAY)
Global Const $SSS_MONK_LOCK_DURATION_MS = 9000
Global Const $SSS_MONK_STICK_MAX_DIST = 1600
Global Const $SSS_TAIL_CLEANUP_MAX_DIST = 1400

Global $spirit_slaves_sin_farm_setup = False
Global $spirit_slaves_sin_runtime_timer = 0
Global $spirit_slaves_sin_rod_seen
Global $spirit_slaves_sin_last_priority_target_id = 0
Global $spirit_slaves_sin_last_priority_reason = ''
Global $spirit_slaves_sin_last_combat_target_id = 0
Global $spirit_slaves_sin_monk_lock_target_id = 0
Global $spirit_slaves_sin_monk_lock_until_ms = 0
Global $spirit_slaves_sin_in_kill_sequence = False

Func SpiritSlavesSinFarm()
	; Safety guard: if we are not in the farming map, force full setup again.
	If GetMapID() <> $ID_THE_SHATTERED_RAVINES Then
		If $spirit_slaves_sin_farm_setup Then Info('Sin map guard: outside The Shattered Ravines, forcing setup reset')
		$spirit_slaves_sin_farm_setup = False
		$spirit_slaves_sin_in_kill_sequence = False
		$spirit_slaves_sin_last_combat_target_id = 0
		SpiritSlavesSinClearMonkLock()
	EndIf

	If Not $spirit_slaves_sin_farm_setup And SetupSpiritSlavesSinFarm() == $FAIL Then Return $PAUSE
	Return SpiritSlavesSinFarmLoop()
EndFunc


Func SpiritSlavesSinNewEmptyMap()
	Local $map[]
	Return $map
EndFunc


Func SpiritSlavesSinClearMonkLock()
	$spirit_slaves_sin_monk_lock_target_id = 0
	$spirit_slaves_sin_monk_lock_until_ms = 0
EndFunc


Func SpiritSlavesSinLockMonkTarget($targetID, $nowMs)
	$spirit_slaves_sin_monk_lock_target_id = $targetID
	$spirit_slaves_sin_monk_lock_until_ms = $nowMs + $SSS_MONK_LOCK_DURATION_MS
EndFunc


Func SpiritSlavesSinTryGetMonkLockTarget($me, $range, $nowMs)
	If $spirit_slaves_sin_monk_lock_target_id <= 0 Then Return Null
	If $nowMs > $spirit_slaves_sin_monk_lock_until_ms Then
		SpiritSlavesSinClearMonkLock()
		Return Null
	EndIf
	If Not GetAgentExists($spirit_slaves_sin_monk_lock_target_id) Then
		SpiritSlavesSinClearMonkLock()
		Return Null
	EndIf

	Local $locked = GetAgentByID($spirit_slaves_sin_monk_lock_target_id)
	If $locked == Null Then
		SpiritSlavesSinClearMonkLock()
		Return Null
	EndIf
	If DllStructGetData($locked, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then
		SpiritSlavesSinClearMonkLock()
		Return Null
	EndIf
	If GetIsDead($locked) Or DllStructGetData($locked, 'HealthPercent') <= 0 Then
		SpiritSlavesSinClearMonkLock()
		Return Null
	EndIf
	If DllStructGetData($locked, 'TypeMap') == $ID_TYPEMAP_IDLE_MINION Then
		SpiritSlavesSinClearMonkLock()
		Return Null
	EndIf
	If GetDistance($me, $locked) > $range Then Return Null

	Return $locked
EndFunc


Func SpiritSlavesSinRefreshReversalCasterMemory($me, $scanRange = $RANGE_COMPASS)
	If $spirit_slaves_sin_runtime_timer == 0 Then $spirit_slaves_sin_runtime_timer = TimerInit()
	Local $nowMs = TimerDiff($spirit_slaves_sin_runtime_timer)
	Local $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	For $agent In $agents
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then ContinueLoop
		If GetIsDead($agent) Or DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If DllStructGetData($agent, 'TypeMap') == $ID_TYPEMAP_IDLE_MINION Then ContinueLoop
		If GetDistance($me, $agent) > $scanRange Then ContinueLoop
		If IsCasting($agent) And DllStructGetData($agent, 'Skill') == $ID_REVERSAL_OF_DAMAGE Then
			$spirit_slaves_sin_rod_seen[DllStructGetData($agent, 'ID')] = $nowMs
		EndIf
	Next
EndFunc


Func SpiritSlavesSinGetPriorityFoe($me, $range = $RANGE_COMPASS, $preferLockedEvenIfFar = False)
	SpiritSlavesSinRefreshReversalCasterMemory($me, $range)
	Local $nowMs = TimerDiff($spirit_slaves_sin_runtime_timer)
	Local $rodMemoryMs = 12000
	Local $lockedTarget = SpiritSlavesSinTryGetMonkLockTarget($me, $range, $nowMs)
	If $lockedTarget == Null And $preferLockedEvenIfFar Then
		Local $farLocked = SpiritSlavesSinTryGetMonkLockTarget($me, 1000000, $nowMs)
		If $farLocked <> Null Then
			Local $farDist = GetDistance($me, $farLocked)
			If $farDist <= $SSS_MONK_STICK_MAX_DIST Then
				$lockedTarget = $farLocked
			Else
				SpiritSlavesSinClearMonkLock()
			EndIf
		EndIf
	EndIf

	If $lockedTarget <> Null Then
		Local $lockedID = DllStructGetData($lockedTarget, 'ID')
		If $spirit_slaves_sin_last_priority_reason <> 'monk_lock' Or $spirit_slaves_sin_last_priority_target_id <> $lockedID Then
			Info('sin_priority_monk_lock_target=' & $lockedID)
			$spirit_slaves_sin_last_priority_reason = 'monk_lock'
			$spirit_slaves_sin_last_priority_target_id = $lockedID
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
		Local $seenAt = $spirit_slaves_sin_rod_seen[$agentID]
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
		SpiritSlavesSinLockMonkTarget($castingID, $nowMs)
		If $spirit_slaves_sin_last_priority_reason <> 'rod_cast' Or $spirit_slaves_sin_last_priority_target_id <> $castingID Then
			Info('sin_priority_rod_cast_target=' & $castingID & ' dist=' & Round($bestCastingRodDist, 0))
			$spirit_slaves_sin_last_priority_reason = 'rod_cast'
			$spirit_slaves_sin_last_priority_target_id = $castingID
		EndIf
		Return $bestCastingRod
	EndIf

	If $bestMonk <> Null Then
		Local $monkID = DllStructGetData($bestMonk, 'ID')
		SpiritSlavesSinLockMonkTarget($monkID, $nowMs)
		If $spirit_slaves_sin_last_priority_reason <> 'monk_primary' Or $spirit_slaves_sin_last_priority_target_id <> $monkID Then
			Info('sin_priority_monk_primary_target=' & $monkID & ' hp=' & Round($bestMonkHealth, 2) & ' dist=' & Round($bestMonkDist, 0))
			$spirit_slaves_sin_last_priority_reason = 'monk_primary'
			$spirit_slaves_sin_last_priority_target_id = $monkID
		EndIf
		Return $bestMonk
	EndIf

	If $bestRod <> Null Then
		Local $priorityID = DllStructGetData($bestRod, 'ID')
		SpiritSlavesSinLockMonkTarget($priorityID, $nowMs)
		If $spirit_slaves_sin_last_priority_reason <> 'rod' Or $spirit_slaves_sin_last_priority_target_id <> $priorityID Then
			Info('sin_priority_rod_target=' & $priorityID & ' dist=' & Round($bestRodDist, 0))
			$spirit_slaves_sin_last_priority_reason = 'rod'
			$spirit_slaves_sin_last_priority_target_id = $priorityID
		EndIf
		Return $bestRod
	EndIf

	Local $fallback = GetNearestEnemyToAgent($me, $range)
	If $fallback <> Null Then
		Local $fallbackID = DllStructGetData($fallback, 'ID')
		If $spirit_slaves_sin_last_priority_reason <> 'fallback' Or $spirit_slaves_sin_last_priority_target_id <> $fallbackID Then
			Info('sin_priority_fallback_target=' & $fallbackID)
			$spirit_slaves_sin_last_priority_reason = 'fallback'
			$spirit_slaves_sin_last_priority_target_id = $fallbackID
		EndIf
	ElseIf $spirit_slaves_sin_last_priority_reason <> 'none' Then
		Info('sin_priority_fallback_target=none')
		$spirit_slaves_sin_last_priority_reason = 'none'
		$spirit_slaves_sin_last_priority_target_id = 0
	EndIf

	Return $fallback
EndFunc


Func SetupSpiritSlavesSinFarm()
	If $spirit_slaves_sin_runtime_timer == 0 Then $spirit_slaves_sin_runtime_timer = TimerInit()
	$spirit_slaves_sin_rod_seen = SpiritSlavesSinNewEmptyMap()
	$spirit_slaves_sin_last_priority_target_id = 0
	$spirit_slaves_sin_last_priority_reason = ''
	$spirit_slaves_sin_last_combat_target_id = 0
	SpiritSlavesSinClearMonkLock()
	$spirit_slaves_sin_in_kill_sequence = False

	If GetMapID() <> $ID_THE_SHATTERED_RAVINES Then
		If TravelToOutpost($ID_BONE_PALACE, $district_name) == $FAIL Then Return $FAIL
		SwitchMode($ID_HARD_MODE)
		SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)

		If SetupPlayerSpiritSlavesSinFarm() == $FAIL Then Return $FAIL
		LeaveParty()
		While Not $spirit_slaves_sin_farm_setup
			If SpiritSlavesSinRunToShatteredRavines() == $FAIL Then ContinueLoop
			$spirit_slaves_sin_farm_setup = True
		WEnd
	EndIf
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerSpiritSlavesSinFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
		LoadSkillTemplate($SPIRIT_SLAVES_SIN_SKILLBAR)
		RandomSleep(250)
		SpiritSlavesSinEnsureWeaponSet4('setup')
	Else
		Warn('Should run this farm as assassin')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func SpiritSlavesSinEnsureWeaponSet4($reason = '')
	Info('Weapon set enforcement -> 4' & ($reason <> '' ? ' (' & $reason & ')' : ''))
	ChangeWeaponSet(4)
	RandomSleep(120)
EndFunc


Func SpiritSlavesSinRunToShatteredRavines()
	TravelToOutpost($ID_BONE_PALACE, $district_name)
	MoveTo(-14520, 6009)
	Move(-14820, 3400)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_JOKOS_DOMAIN) Then Return $FAIL
	RandomSleep(500)
	MoveTo(-12657, 2609)
	SpiritSlavesSinEnsureWeaponSet4('run-to-ravines')
	MoveTo(-10938, 4254)
	ChangeTarget(GetNearestSignpostToCoords(-10938, 4254))
	RandomSleep(500)
	Info('Taking wurm')
	TargetNearestItem()
	ActionInteract()
	RandomSleep(1500)
	UseSkillEx(5)
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

	If IsPlayerDead() Then Return $FAIL

	MoveTo(-4486, 19700)
	RandomSleep(3000)
	MoveTo(-4486, 19700)

	If IsPlayerDead() Then Return $FAIL

	SpiritSlavesSinEnsureWeaponSet4('before-ravines-entry')
	Info('Entering The Shattered Ravines : careful')
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_THE_SHATTERED_RAVINES, 10000, 2000) Then Return $FAIL
	MoveTo(-9714, -10767)
	MoveTo(-7919, -10530)
	Return $SUCCESS
EndFunc


Func SpiritSlavesSinFarmLoop()
	SpiritSlavesSinEnsureWeaponSet4('farm-loop-start')
	UseConsumable($ID_SLICE_OF_PUMPKIN_PIE)

	Info('Killing group 1 @ North')
	If SpiritSlavesSinFarmNorthGroup() == $FAIL Then Return SpiritSlavesSinRestartAfterDeath()
	Info('Killing group 2 @ South')
	If SpiritSlavesSinFarmSouthGroup() == $FAIL Then Return SpiritSlavesSinRestartAfterDeath()
	Info('Killing group 3 @ South')
	If SpiritSlavesSinFarmSouthGroup() == $FAIL Then Return SpiritSlavesSinRestartAfterDeath()
	Info('Killing group 4 @ North')
	If SpiritSlavesSinFarmNorthGroup() == $FAIL Then Return SpiritSlavesSinRestartAfterDeath()
	Info('Killing group 5 @ North')
	If SpiritSlavesSinFarmNorthGroup() == $FAIL Then Return SpiritSlavesSinRestartAfterDeath()

	Info('Moving out of the zone and back again')
	Move(-7735, -8380)
	SpiritSlavesSinRezoneToTheShatteredRavines()

	Return $SUCCESS
EndFunc


Func SpiritSlavesSinRezoneToTheShatteredRavines()
	Info('Rezoning')
	MoveTo(-7800, -10250)
	MoveTo(-9000, -10900)
	MoveTo(-10500, -11000)
	Move(-10656, -11293)
	RandomSleep(1000)
	WaitMapLoading($ID_JOKOS_DOMAIN)
	RandomSleep(500)
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	WaitMapLoading($ID_THE_SHATTERED_RAVINES, 10000, 2000)
	MoveTo(-9714, -10767)
	MoveTo(-7919, -10530)
EndFunc


Func SpiritSlavesSinFarmNorthGroup()
	MoveTo(-7375, -7767)
	SpiritSlavesSinWaitForFoesBall()
	SpiritSlavesSinWaitForEnergy()
	SpiritSlavesSinWaitForDeathsCharge()
	Local $targetFoe = GetNearestNPCInRangeOfCoords(-8598, -5810, $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe)
	SpiritSlavesSinEnsureWeaponSet4('north-group')
	SpiritSlavesSinMaintainUpkeep()
	SpiritSlavesSinStabilizeCoreDefense(2200)
	RandomSleep(150)
	If IsPlayerDead() Then Return $FAIL

	Local $positionToGo = FindMiddleOfFoes(-8598, -5810, $RANGE_AREA)
	$targetFoe = BetterGetNearestNPCToCoords($ID_ALLEGIANCE_FOE, $positionToGo[0], $positionToGo[1], $RANGE_EARSHOT)
	UseSkillEx($SSS_DEATHS_CHARGE, $targetFoe)
	RandomSleep(120)
	SpiritSlavesSinMaintainUpkeep()

	If IsPlayerDead() Then Return $FAIL
	If SpiritSlavesSinKillSequence() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func SpiritSlavesSinFarmSouthGroup()
	SpiritSlavesSinCleanseFromCripple()
	MoveTo(-7830, -7860)
	SpiritSlavesSinCleanseFromCripple()
	Local $foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, SpiritSlavesSinIsPastAggroLine)
	Local $deadlock = TimerInit()
	While IsPlayerAlive() And $foesCount < 8 And TimerDiff($deadlock) < 120000
		RandomSleep(100)
		$foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, SpiritSlavesSinIsPastAggroLine)
		SpiritSlavesSinCleanseFromCripple()
	WEnd
	SpiritSlavesSinCleanseFromCripple()
	Move(-7735, -8380)
	$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 950)
	$deadlock = TimerInit()
	While IsPlayerAlive() And $foesCount == 0 And TimerDiff($deadlock) < 120000
		RandomSleep(100)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 950)
	WEnd
	If IsPlayerDead() Then Return $FAIL
	SpiritSlavesSinWaitForEnergy()

	SpiritSlavesSinEnsureWeaponSet4('south-group')
	MoveTo(-7800, -7680)
	SpiritSlavesSinMaintainUpkeep()
	SpiritSlavesSinStabilizeCoreDefense(2200)
	RandomSleep(150)

	If IsPlayerDead() Then Return $FAIL

	Local $positionToGo = FindMiddleOfFoes(-8055, -9250, $RANGE_NEARBY)
	Local $targetFoe = BetterGetNearestNPCToCoords($ID_ALLEGIANCE_FOE, $positionToGo[0], $positionToGo[1], $RANGE_SPELLCAST)
	UseSkillEx($SSS_DEATHS_CHARGE, $targetFoe)
	RandomSleep(120)
	SpiritSlavesSinMaintainUpkeep()

	If IsPlayerDead() Then Return $FAIL
	If SpiritSlavesSinKillSequence() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func SpiritSlavesSinMaintainUpkeep()
	If IsRecharged($SSS_FLASHING_BLADES) And GetEffectTimeRemaining(GetEffect($ID_FLASHING_BLADES)) == 0 And GetEnergy() >= $SSS_SKILL_COSTS_MAP[$SSS_FLASHING_BLADES] Then UseSkillEx($SSS_FLASHING_BLADES)
	If IsRecharged($SSS_CRITICAL_DEFENSES) And GetEffectTimeRemaining(GetEffect($ID_CRITICAL_DEFENSES)) == 0 And GetEnergy() >= $SSS_SKILL_COSTS_MAP[$SSS_CRITICAL_DEFENSES] Then UseSkillEx($SSS_CRITICAL_DEFENSES)
	If IsRecharged($SSS_CRITICAL_AGILITY) And GetEffectTimeRemaining(GetEffect($ID_CRITICAL_AGILITY)) == 0 And GetEnergy() >= $SSS_SKILL_COSTS_MAP[$SSS_CRITICAL_AGILITY] Then UseSkillEx($SSS_CRITICAL_AGILITY)
	If IsRecharged($SSS_VIGOROUS_SPIRIT) And GetEffectTimeRemaining(GetEffect($ID_VIGOROUS_SPIRIT)) == 0 And GetEnergy() >= $SSS_SKILL_COSTS_MAP[$SSS_VIGOROUS_SPIRIT] Then UseSkillEx($SSS_VIGOROUS_SPIRIT, GetMyAgent())
EndFunc


Func SpiritSlavesSinHasCoreDefenseUp()
	If GetEffectTimeRemaining(GetEffect($ID_FLASHING_BLADES)) == 0 Then Return False
	If GetEffectTimeRemaining(GetEffect($ID_CRITICAL_DEFENSES)) == 0 Then Return False
	If GetEffectTimeRemaining(GetEffect($ID_CRITICAL_AGILITY)) == 0 Then Return False
	If GetEffectTimeRemaining(GetEffect($ID_VIGOROUS_SPIRIT)) == 0 Then Return False
	Return True
EndFunc


Func SpiritSlavesSinStabilizeCoreDefense($maxWaitMs = 1800)
	Local $stabilize = TimerInit()
	While IsPlayerAlive() And TimerDiff($stabilize) < $maxWaitMs
		If SpiritSlavesSinHasCoreDefenseUp() Then Return True
		SpiritSlavesSinMaintainUpkeep()
		RandomSleep(120)
	WEnd
	Return SpiritSlavesSinHasCoreDefenseUp()
EndFunc


Func SpiritSlavesSinCastAttackChain($target, $reset = False)
	Static $chainStage = 1
	Static $chainTimer = 0
	Static $nextDelayMs = 0

	If $reset Then
		$chainStage = 1
		$chainTimer = TimerInit()
		$nextDelayMs = 0
		Return
	EndIf

	If $target == Null Then Return
	If $chainTimer <> 0 And TimerDiff($chainTimer) < $nextDelayMs Then Return

	Switch $chainStage
		Case 1
			If IsRecharged($SSS_JAGGED_STRIKE) And GetEnergy() >= $SSS_SKILL_COSTS_MAP[$SSS_JAGGED_STRIKE] Then
				UseSkillEx($SSS_JAGGED_STRIKE, $target)
				$chainStage = 2
				$chainTimer = TimerInit()
				$nextDelayMs = 1000
			EndIf
		Case 2
			If IsRecharged($SSS_FOX_FANGS) And GetEnergy() >= $SSS_SKILL_COSTS_MAP[$SSS_FOX_FANGS] Then
				UseSkillEx($SSS_FOX_FANGS, $target)
				$chainStage = 3
				$chainTimer = TimerInit()
				$nextDelayMs = 1000
			EndIf
		Case 3
			If IsRecharged($SSS_DEATH_BLOSSOM) And GetEnergy() >= $SSS_SKILL_COSTS_MAP[$SSS_DEATH_BLOSSOM] Then
				UseSkillEx($SSS_DEATH_BLOSSOM, $target)
				$chainStage = 1
				$chainTimer = TimerInit()
				$nextDelayMs = 2000
			EndIf
	EndSwitch
EndFunc


Func SpiritSlavesSinKillSequence()
	Local $deadlock = TimerInit()
	Local $foesCountArea = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	Local $foesCount = $foesCountArea
	Local $rangerTailCleanup = False
	Local $loopExitReason = 'unknown'
	; After rezone/death transitions, area count can momentarily read as 0.
	; Give it a short sync window to avoid skipping a live group.
	If $foesCountArea == 0 Then
		Local $syncTimer = TimerInit()
		While IsPlayerAlive() And $foesCountArea == 0 And TimerDiff($syncTimer) < 1800
			RandomSleep(120)
			$foesCountArea = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
			If $foesCountArea > 0 Then ExitLoop
			Local $syncTarget = SpiritSlavesSinGetPriorityFoe(GetMyAgent(), $RANGE_COMPASS, False)
			If $syncTarget <> Null And GetDistance(GetMyAgent(), $syncTarget) <= $RANGE_EARSHOT Then
				$foesCountArea = 1
				ExitLoop
			EndIf
		WEnd
		$foesCount = $foesCountArea
	EndIf

	$spirit_slaves_sin_last_combat_target_id = 0
	SpiritSlavesSinClearMonkLock()
	$spirit_slaves_sin_in_kill_sequence = True
	SpiritSlavesSinEnsureWeaponSet4('kill-sequence-start')
	Info('Sin kill sequence start: foes(area)=' & $foesCountArea)
	SpiritSlavesSinCastAttackChain(Null, True)
	While IsPlayerAlive() And $foesCount > 0 And TimerDiff($deadlock) < 100000
		SpiritSlavesSinMaintainUpkeep()
		Local $me = GetMyAgent()
		; In larger packs, do not insist on far monk lock yet; survive and cleave locally first.
		Local $preferFarLock = ($foesCount <= 4)
		Local $target = SpiritSlavesSinGetPriorityFoe($me, $RANGE_COMPASS, $preferFarLock)
		If $target <> Null Then
			Local $targetID = DllStructGetData($target, 'ID')
			Local $targetDist = GetDistance($me, $target)

			; In large packs, do not overchase distant monk/female targets.
			If $foesCount > 4 And $targetDist > $RANGE_EARSHOT Then
				Local $brawlTarget = GetNearestEnemyToAgent($me, $RANGE_EARSHOT)
				If $brawlTarget <> Null Then
					$target = $brawlTarget
					$targetID = DllStructGetData($target, 'ID')
					$targetDist = GetDistance($me, $target)
				EndIf
			EndIf

			If $spirit_slaves_sin_last_combat_target_id <> $targetID Then
				Info('sin_hardswitch_target=' & $targetID)
				$spirit_slaves_sin_last_combat_target_id = $targetID
				SpiritSlavesSinCastAttackChain(Null, True)
			EndIf

			If $foesCount <= 2 And $targetDist > $RANGE_ADJACENT Then
				Local $closeChaseTimer = TimerInit()
				While IsPlayerAlive() And GetDistance($me, $target) > $RANGE_ADJACENT And TimerDiff($closeChaseTimer) < 1200
					Move(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'))
					SpiritSlavesSinMaintainUpkeep()
					RandomSleep(80)
					$me = GetMyAgent()
				WEnd
				$targetDist = GetDistance($me, $target)
			ElseIf $targetDist > $RANGE_NEARBY Then
				Local $chaseTimer = TimerInit()
				While IsPlayerAlive() And GetDistance($me, $target) > $RANGE_NEARBY And TimerDiff($chaseTimer) < 900
					Move(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'))
					SpiritSlavesSinMaintainUpkeep()
					RandomSleep(80)
					$me = GetMyAgent()
				WEnd
				$targetDist = GetDistance($me, $target)
			EndIf

			ChangeTarget($target)
			Attack($target)
			If $targetDist < ($RANGE_AREA + 88) Then SpiritSlavesSinCastAttackChain($target)
		EndIf
		RandomSleep(220)
		$foesCountArea = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
		$foesCount = $foesCountArea
		If $foesCountArea == 0 Then
			Local $tailTarget = SpiritSlavesSinGetPriorityFoe(GetMyAgent(), $RANGE_COMPASS, True)
			If $tailTarget <> Null Then
				Local $tailDist = GetDistance(GetMyAgent(), $tailTarget)
				If $tailDist <= $SSS_TAIL_CLEANUP_MAX_DIST Then
					$foesCount = 1
					If Not $rangerTailCleanup Then
						Info('sin_tail_cleanup_target=' & DllStructGetData($tailTarget, 'ID') & ' dist=' & Round($tailDist, 0))
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
	ElseIf TimerDiff($deadlock) >= 100000 Then
		$loopExitReason = 'deadlock_timeout'
	ElseIf $foesCountArea <= 0 Then
		$loopExitReason = 'no_foes_in_area'
	Else
		$loopExitReason = 'loop_condition_changed'
	EndIf
	$spirit_slaves_sin_in_kill_sequence = False
	$spirit_slaves_sin_last_combat_target_id = 0
	SpiritSlavesSinClearMonkLock()
	Info('Sin kill sequence end: reason=' & $loopExitReason & ' foes(area)=' & CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA))

	If IsPlayerDead() Then Return $FAIL
	SpiritSlavesSinEnsureWeaponSet4('kill-sequence-end')
	SpiritSlavesSinCastAttackChain(Null, True)
	SpiritSlavesSinMaintainUpkeep()
	RandomSleep(1000)
	PickUpItems(SpiritSlavesSinMaintainUpkeep)
	Return $SUCCESS
EndFunc


Func SpiritSlavesSinWaitForFoesBall()
	SpiritSlavesSinWaitForAlliesDead()

	Local $deadlock = TimerInit()
	Local $target = GetNearestEnemyToCoords(-8598, -5810)
	Local $foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
	Local $validation = 0

	While IsPlayerAlive() And $foesCount < 8 And $validation < 2 And TimerDiff($deadlock) < 120000
		If $foesCount == 8 Then $validation += 1
		RandomSleep(3000)
		$target = GetNearestEnemyToCoords(-8598, -5810)
		$foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
		Debug('foes: ' & $foesCount & '/8')
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Info('Timed out waiting for mobs to ball')
EndFunc


Func SpiritSlavesSinWaitForAlliesDead()
	Local $deadlock = TimerInit()
	Local $target = GetNearestNPCToCoords(-8598, -5810)

	While GetDistanceToPoint($target, -8598, -5810) < $RANGE_EARSHOT And TimerDiff($deadlock) < 120000
		RandomSleep(5000)
		$target = GetNearestNPCToCoords(-8598, -5810)
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Info('Timed out waiting for allies to be dead')
EndFunc


Func SpiritSlavesSinRestartAfterDeath()
	Local $deadlockTimer = TimerInit()
	Info('Waiting for resurrection')
	While IsPlayerDead()
		RandomSleep(1000)
		If TimerDiff($deadlockTimer) > 60000 Then
			$spirit_slaves_sin_farm_setup = False
			$spirit_slaves_sin_in_kill_sequence = False
			$spirit_slaves_sin_last_combat_target_id = 0
			SpiritSlavesSinClearMonkLock()
			Info('Travelling to Bone Palace (sin reset state)')
			TravelToOutpost($ID_BONE_PALACE, $district_name)
			Return $FAIL
		EndIf
	WEnd
	SpiritSlavesSinRezoneToTheShatteredRavines()
	If GetMapID() <> $ID_THE_SHATTERED_RAVINES Then $spirit_slaves_sin_farm_setup = False
	Return $FAIL
EndFunc


Func SpiritSlavesSinWaitForEnergy()
	While (GetEnergy() < 20) And IsPlayerAlive()
		RandomSleep(1000)
	WEnd
EndFunc


Func SpiritSlavesSinWaitForDeathsCharge()
	While Not IsRecharged($SSS_DEATHS_CHARGE) And IsPlayerAlive()
		RandomSleep(1000)
	WEnd
EndFunc


Func SpiritSlavesSinCleanseFromCripple()
	SpiritSlavesSinMaintainUpkeep()
EndFunc


Func SpiritSlavesSinIsPastAggroLine($agent)
	Return Not IsOverLine(1, 0, 6750, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
EndFunc
