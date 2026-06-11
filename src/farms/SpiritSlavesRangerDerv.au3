#include-once

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; Original-dungeon-flow-inspired Ranger variant.
Global Const $SPIRIT_SLAVES_RANGER_DERV_SKILLBAR = 'Ogojchpr6SAH3kfXdfjhOXxl3lA'
Global Const $SPIRIT_SLAVES_RANGER_DERV_FARM_INFORMATIONS = 'Ranger variant that stays close to original Dervish Spirit Slaves flow'
Global Const $SPIRIT_SLAVES_RANGER_DERV_FARM_DURATION = 10 * 60 * 1000
Global Const $SSRD_LOG_TAG = '[SS-RangerDerv] '

Global Const $SSRD_ESCAPE = 1
Global Const $SSRD_YOU_ARE_ALL_WEAKLINGS = 2
Global Const $SSRD_MYSTIC_VIGOR = 3
Global Const $SSRD_GRENTHS_AURA = 4
Global Const $SSRD_CRIPPLING_VICTORY = 5
Global Const $SSRD_REAP_IMPURITIES = 6
Global Const $SSRD_MENTAL_BLOCK = 7
Global Const $SSRD_DWARVEN_STABILITY = 8

Global Const $SSRD_SKILLS_ARRAY = [$SSRD_ESCAPE, $SSRD_YOU_ARE_ALL_WEAKLINGS, $SSRD_MYSTIC_VIGOR, $SSRD_GRENTHS_AURA, $SSRD_CRIPPLING_VICTORY, $SSRD_REAP_IMPURITIES, $SSRD_MENTAL_BLOCK, $SSRD_DWARVEN_STABILITY]
Global Const $SSRD_SKILLS_COSTS_ARRAY = [5, 5, 5, 10, 6, 5, 10, 5]
Global Const $SSRD_SKILL_COSTS_MAP = MapFromArrays($SSRD_SKILLS_ARRAY, $SSRD_SKILLS_COSTS_ARRAY)
Global Const $SSRD_CHAIN_MIN_ADREN5 = 6
Global Const $SSRD_CHAIN_MIN_ADREN6 = 5
Global Const $SSRD_NORTH_CENTER_X = -8598
Global Const $SSRD_NORTH_CENTER_Y = -5810
Global Const $SSRD_NORTH_CLEAR_RETRY_MAX = 2
Global Const $SSRD_SOUTH_WAIT_MAX_MS = 120000
Global Const $SSRD_ENERGY_WAIT_MAX_MS = 25000
Global Const $SSRD_REENGAGE_MIN_HP = 0.99
Global Const $SSRD_REENGAGE_MIN_ENERGY = 0.99
Global Const $SSRD_REENGAGE_WAIT_MAX_MS = 20000

Global $spirit_slaves_ranger_derv_farm_setup = False
Global $spirit_slaves_ranger_derv_build_setup = False
Global $spirit_slaves_ranger_derv_center_started = False


Func SpiritSlavesRangerDervLogInfo($message)
	Info($SSRD_LOG_TAG & $message)
EndFunc


Func SpiritSlavesRangerDervLogWarn($message)
	Warn($SSRD_LOG_TAG & $message)
EndFunc


Func SpiritSlavesRangerDervLogDebug($message)
	Debug($SSRD_LOG_TAG & $message)
EndFunc


Func SpiritSlavesRangerDervFarm()
	If Not $spirit_slaves_ranger_derv_farm_setup And SetupSpiritSlavesRangerDervFarm() == $FAIL Then Return $PAUSE
	Return SpiritSlavesRangerDervFarmLoop()
EndFunc


Func SetupSpiritSlavesRangerDervFarm()
	If GetMapID() <> $ID_THE_SHATTERED_RAVINES Then
		If TravelToOutpost($ID_BONE_PALACE, $district_name) == $FAIL Then Return $FAIL
		SwitchMode($ID_HARD_MODE)
		SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)

		If SetupPlayerSpiritSlavesRangerDervFarm() == $FAIL Then Return $FAIL
		LeaveParty()
		While Not $spirit_slaves_ranger_derv_farm_setup
			If SpiritSlavesRangerDervRunToShatteredRavines() == $FAIL Then ContinueLoop
			$spirit_slaves_ranger_derv_farm_setup = True
		WEnd
	EndIf
	SpiritSlavesRangerDervLogInfo('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerSpiritSlavesRangerDervFarm()
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_RANGER Then
		SpiritSlavesRangerDervLogWarn('Should run this farm as ranger')
		Return $FAIL
	EndIf

	If Not $spirit_slaves_ranger_derv_build_setup Then
		SpiritSlavesRangerDervLogInfo('Setting up player build skill bar')
		LoadSkillTemplate($SPIRIT_SLAVES_RANGER_DERV_SKILLBAR)
		RandomSleep(250)
		$spirit_slaves_ranger_derv_build_setup = True
	Else
		SpiritSlavesRangerDervLogInfo('Player build already configured: skipping skillbar reload')
	EndIf

	SpiritSlavesRangerDervEnsureWeaponSet3('setup')
	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerDervEnsureWeaponSet3($reason = '')
	SpiritSlavesRangerDervLogInfo('Weapon set enforcement -> 3' & ($reason <> '' ? ' (' & $reason & ')' : ''))
	ChangeWeaponSet(3)
	RandomSleep(120)
EndFunc


Func SpiritSlavesRangerDervEnsureWeaponSet1($reason = '')
	SpiritSlavesRangerDervLogInfo('Weapon set enforcement -> 1' & ($reason <> '' ? ' (' & $reason & ')' : ''))
	ChangeWeaponSet(1)
	RandomSleep(120)
EndFunc


Func SpiritSlavesRangerDervRunToShatteredRavines()
	TravelToOutpost($ID_BONE_PALACE, $district_name)
	MoveTo(-14520, 6009)
	Move(-14820, 3400)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_JOKOS_DOMAIN) Then Return $FAIL
	RandomSleep(500)
	MoveTo(-12657, 2609)
	SpiritSlavesRangerDervEnsureWeaponSet3('run-to-ravines')
	MoveTo(-10938, 4254)
	ChangeTarget(GetNearestSignpostToCoords(-10938, 4254))
	RandomSleep(500)
	SpiritSlavesRangerDervLogInfo('Taking wurm')
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

	SpiritSlavesRangerDervEnsureWeaponSet3('before-ravines-entry')
	SpiritSlavesRangerDervLogInfo('Entering The Shattered Ravines : careful')
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_THE_SHATTERED_RAVINES, 10000, 2000) Then Return $FAIL
	MoveTo(-9714, -10767)
	MoveTo(-7919, -10530)
	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerDervFarmLoop()
	SpiritSlavesRangerDervEnsureWeaponSet3('farm-loop-start')
	UseConsumable($ID_SLICE_OF_PUMPKIN_PIE)

	SpiritSlavesRangerDervLogInfo('Killing group 1 @ North')
	If SpiritSlavesRangerDervFarmNorthGroup() == $FAIL Then Return SpiritSlavesRangerDervRestartAfterDeath()
	SpiritSlavesRangerDervEnsureWeaponSet1('between-wave-1-and-2-energy-recovery')
	SpiritSlavesRangerDervLogInfo('Killing group 2 @ South')
	If SpiritSlavesRangerDervFarmSouthGroup() == $FAIL Then Return SpiritSlavesRangerDervRestartAfterDeath()
	SpiritSlavesRangerDervLogInfo('Killing group 3 @ South')
	If SpiritSlavesRangerDervFarmSouthGroup() == $FAIL Then Return SpiritSlavesRangerDervRestartAfterDeath()
	SpiritSlavesRangerDervLogInfo('Killing group 4 @ North')
	If SpiritSlavesRangerDervFarmNorthGroup() == $FAIL Then Return SpiritSlavesRangerDervRestartAfterDeath()
	SpiritSlavesRangerDervLogInfo('Killing group 5 @ North')
	If SpiritSlavesRangerDervFarmNorthGroup() == $FAIL Then Return SpiritSlavesRangerDervRestartAfterDeath()

	SpiritSlavesRangerDervLogInfo('Moving out of the zone and back again')
	Move(-7735, -8380)
	SpiritSlavesRangerDervRezoneToTheShatteredRavines()

	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerDervRezoneToTheShatteredRavines()
	SpiritSlavesRangerDervLogInfo('Rezoning')
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


Func SpiritSlavesRangerDervFarmNorthGroup()
	MoveTo(-7375, -7767)
	SpiritSlavesRangerDervWaitForFoesBall()
	If SpiritSlavesRangerDervWaitForEnergy() == $FAIL Then Return $FAIL
	Local $targetFoe = GetNearestNPCInRangeOfCoords($SSRD_NORTH_CENTER_X, $SSRD_NORTH_CENTER_Y, $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe)
	SpiritSlavesRangerDervEnsureWeaponSet3('north-group')
	SpiritSlavesRangerDervStartUpkeepSequence($targetFoe)
	SpiritSlavesRangerDervMaintainUpkeep($targetFoe)
	RandomSleep(150)
	If IsPlayerDead() Then Return $FAIL

	Local $positionToGo = FindMiddleOfFoes($SSRD_NORTH_CENTER_X, $SSRD_NORTH_CENTER_Y, $RANGE_AREA)
	MoveTo($positionToGo[0], $positionToGo[1])
	RandomSleep(120)
	SpiritSlavesRangerDervMaintainUpkeep($targetFoe)

	If IsPlayerDead() Then Return $FAIL
	If SpiritSlavesRangerDervKillSequence() == $FAIL Then Return $FAIL
	If SpiritSlavesRangerDervEnsureNorthGroupCleared() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerDervEnsureNorthGroupCleared()
	Local $attempt = 0
	Local $remaining = CountFoesInRangeOfCoords($SSRD_NORTH_CENTER_X, $SSRD_NORTH_CENTER_Y, $RANGE_EARSHOT)
	While IsPlayerAlive() And $remaining > 0 And $attempt < $SSRD_NORTH_CLEAR_RETRY_MAX
		$attempt += 1
		SpiritSlavesRangerDervLogWarn('North group still has ' & $remaining & ' foes; cleanup pass ' & $attempt)
		Local $positionToGo = FindMiddleOfFoes($SSRD_NORTH_CENTER_X, $SSRD_NORTH_CENTER_Y, $RANGE_AREA)
		MoveTo($positionToGo[0], $positionToGo[1])
		RandomSleep(120)
		If SpiritSlavesRangerDervKillSequence() == $FAIL Then Return $FAIL
		$remaining = CountFoesInRangeOfCoords($SSRD_NORTH_CENTER_X, $SSRD_NORTH_CENTER_Y, $RANGE_EARSHOT)
	WEnd
	If IsPlayerDead() Then Return $FAIL
	If $remaining > 0 Then
		SpiritSlavesRangerDervLogWarn('North group not fully cleared; aborting progression with ' & $remaining & ' foes still present')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerDervFarmSouthGroup()
	$spirit_slaves_ranger_derv_center_started = False
	Local $forceImmediateEngage = False
	SpiritSlavesRangerDervEnsureWeaponSet1('south-staging-energy-recovery')
	SpiritSlavesRangerDervCleanseFromCripple()
	MoveTo(-7830, -7860)
	SpiritSlavesRangerDervCleanseFromCripple()
	Local $nearbyNow = CountFoesInRangeOfAgent(GetMyAgent(), 950)
	If $nearbyNow >= 3 Then
		$forceImmediateEngage = True
		SpiritSlavesRangerDervLogInfo('South staging: nearby aggro detected (' & $nearbyNow & '), forcing immediate engage')
	EndIf
	Local $foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, SpiritSlavesRangerDervIsPastAggroLine)
	Local $deadlock = TimerInit()
	While IsPlayerAlive() And Not $forceImmediateEngage And $foesCount < 8 And TimerDiff($deadlock) < $SSRD_SOUTH_WAIT_MAX_MS
		RandomSleep(100)
		$foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, SpiritSlavesRangerDervIsPastAggroLine)
		SpiritSlavesRangerDervCleanseFromCripple()
		$nearbyNow = CountFoesInRangeOfAgent(GetMyAgent(), 950)
		If $nearbyNow >= 3 Then
			$forceImmediateEngage = True
			SpiritSlavesRangerDervLogInfo('South staging: aggro arrived during wait (' & $nearbyNow & '), engaging now')
		EndIf
	WEnd
	If Not $forceImmediateEngage And TimerDiff($deadlock) >= $SSRD_SOUTH_WAIT_MAX_MS And $foesCount < 8 Then
		SpiritSlavesRangerDervLogWarn('South staging timeout: mobs did not pass aggro line in time')
		Return $FAIL
	EndIf
	SpiritSlavesRangerDervCleanseFromCripple()
	If Not $forceImmediateEngage Then
		Move(-7735, -8380)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 950)
		$deadlock = TimerInit()
		While IsPlayerAlive() And $foesCount == 0 And TimerDiff($deadlock) < $SSRD_SOUTH_WAIT_MAX_MS
			RandomSleep(100)
			$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 950)
		WEnd
		If TimerDiff($deadlock) >= $SSRD_SOUTH_WAIT_MAX_MS And $foesCount == 0 Then
			SpiritSlavesRangerDervLogWarn('South staging timeout: no aggro acquired near hold spot')
			Return $FAIL
		EndIf
	EndIf
	If IsPlayerDead() Then Return $FAIL
	If $forceImmediateEngage Then
		SpiritSlavesRangerDervLogInfo('South staging: waiting for HP/energy recovery before engage')
		If SpiritSlavesRangerDervWaitForReengageReadiness() == $FAIL Then
			SpiritSlavesRangerDervLogWarn('South staging timeout: HP/energy did not recover enough for safe engage')
			Return $FAIL
		EndIf
	Else
		If SpiritSlavesRangerDervWaitForEnergy() == $FAIL Then
			SpiritSlavesRangerDervLogWarn('South staging timeout: energy did not recover to 20 in time')
			Return $FAIL
		EndIf
	EndIf

	SpiritSlavesRangerDervEnsureWeaponSet3('south-group')
	MoveTo(-7800, -7680)
	Local $targetFoe = GetNearestEnemyToAgent(GetMyAgent())
	SpiritSlavesRangerDervStartUpkeepSequence($targetFoe)
	SpiritSlavesRangerDervMaintainUpkeep($targetFoe)
	RandomSleep(150)

	If IsPlayerDead() Then Return $FAIL

	Local $positionToGo = FindMiddleOfFoes(-8055, -9250, $RANGE_NEARBY)
	MoveTo($positionToGo[0], $positionToGo[1])
	RandomSleep(120)
	$targetFoe = GetNearestEnemyToAgent(GetMyAgent())
	SpiritSlavesRangerDervMaintainUpkeep($targetFoe)

	If IsPlayerDead() Then Return $FAIL
	If SpiritSlavesRangerDervKillSequence() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerDervStartUpkeepSequence($target = Null)
	SpiritSlavesRangerDervMaintainDefensiveUpkeep()
EndFunc


Func SpiritSlavesRangerDervMaintainDefensiveUpkeep()
	If IsRecharged($SSRD_DWARVEN_STABILITY) And GetEffectTimeRemaining(GetEffect($ID_DWARVEN_STABILITY)) == 0 And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_DWARVEN_STABILITY] Then UseSkillEx($SSRD_DWARVEN_STABILITY)
	If IsRecharged($SSRD_MENTAL_BLOCK) And GetEffectTimeRemaining(GetEffect($ID_MENTAL_BLOCK)) == 0 And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_MENTAL_BLOCK] Then UseSkillEx($SSRD_MENTAL_BLOCK)
	If IsRecharged($SSRD_ESCAPE) And GetEffectTimeRemaining(GetEffect($ID_ESCAPE)) == 0 And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_ESCAPE] Then UseSkillEx($SSRD_ESCAPE)
	If IsRecharged($SSRD_MYSTIC_VIGOR) And GetEffectTimeRemaining(GetEffect($ID_MYSTIC_VIGOR)) == 0 And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_MYSTIC_VIGOR] Then UseSkillEx($SSRD_MYSTIC_VIGOR)
EndFunc


Func SpiritSlavesRangerDervMaintainUpkeep($target = Null)
	; Prioritize Grenth's Aura before other upkeep so it is not starved by defensive recasts.
	If IsRecharged($SSRD_GRENTHS_AURA) And GetEnergy() > 20 Then UseSkillEx($SSRD_GRENTHS_AURA)
	SpiritSlavesRangerDervMaintainDefensiveUpkeep()
	If $spirit_slaves_ranger_derv_center_started Then
		If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY) == 0 Then Return
		If $target == Null Then $target = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_COMPASS)
		If $target <> Null And IsRecharged($SSRD_YOU_ARE_ALL_WEAKLINGS) And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_YOU_ARE_ALL_WEAKLINGS] Then UseSkillEx($SSRD_YOU_ARE_ALL_WEAKLINGS, $target)
	EndIf
EndFunc


Func SpiritSlavesRangerDervHasAdrenaline($skillSlot, $requiredStrikes)
	Return GetSkillbarSkillAdrenaline($skillSlot) >= $requiredStrikes
EndFunc


Func SpiritSlavesRangerDervCleanupSmallTail($maxMs = 12000)
	Local $timer = TimerInit()
	While IsPlayerAlive() And TimerDiff($timer) < $maxMs
		Local $me = GetMyAgent()
		Local $nearestFoe = GetNearestEnemyToAgent($me)
		If $nearestFoe == Null Then ExitLoop
		If GetDistance($me, $nearestFoe) > ($RANGE_AREA + 88) Then ExitLoop

		SpiritSlavesRangerDervMaintainUpkeep($nearestFoe)
		ChangeTarget($nearestFoe)
		Attack($nearestFoe)
		If IsRecharged($SSRD_CRIPPLING_VICTORY) And SpiritSlavesRangerDervHasAdrenaline($SSRD_CRIPPLING_VICTORY, $SSRD_CHAIN_MIN_ADREN5) Then UseSkillEx($SSRD_CRIPPLING_VICTORY, $nearestFoe)
		If IsRecharged($SSRD_REAP_IMPURITIES) And SpiritSlavesRangerDervHasAdrenaline($SSRD_REAP_IMPURITIES, $SSRD_CHAIN_MIN_ADREN6) Then UseSkillEx($SSRD_REAP_IMPURITIES, $nearestFoe)
		RandomSleep(250)

		If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) == 0 Then ExitLoop
	WEnd
EndFunc


Func SpiritSlavesRangerDervKillSequence()
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	Local $casterFoesMap[]
	SpiritSlavesRangerDervEnsureWeaponSet3('kill-sequence-start')
	SpiritSlavesRangerDervLogInfo('Ranger Derv kill sequence start: foes(area)=' & $foesCount)
	$spirit_slaves_ranger_derv_center_started = False

	While IsPlayerAlive() And $foesCount > 0 And TimerDiff($deadlock) < 100000
		SpiritSlavesRangerDervMaintainUpkeep()
		Local $me = GetMyAgent()
		$foesCount = CountFoesInRangeOfAgent($me, $RANGE_EARSHOT)
		If $foesCount > 0 Then
			Local $casterFoe = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, Null, Null, $RANGE_AREA + 88)
			Local $casterFoeID = DllStructGetData($casterFoe, 'ID')
			If $foesCount < 5 And GetDistance($me, $casterFoe) > $RANGE_ADJACENT Then
				If $casterFoesMap[$casterFoeID] == Null Then
					$casterFoesMap[$casterFoeID] = 0
				ElseIf $casterFoesMap[$casterFoeID] == 2 Then
					Local $timer = TimerInit()
					While IsPlayerAlive() And GetDistance($me, $casterFoe) > $RANGE_ADJACENT And TimerDiff($timer) < 1000
						Move(DllStructGetData($casterFoe, 'X'), DllStructGetData($casterFoe, 'Y'))
						RandomSleep(100)
						$me = GetMyAgent()
					WEnd
				EndIf
				$casterFoesMap[$casterFoeID] += 1
			EndIf

			$me = GetMyAgent()
			Local $nearestFoe = GetNearestEnemyToAgent($me)
			If $nearestFoe <> Null And GetDistance($me, $nearestFoe) < ($RANGE_AREA + 88) Then
				If Not $spirit_slaves_ranger_derv_center_started Then
					If IsRecharged($SSRD_YOU_ARE_ALL_WEAKLINGS) And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_YOU_ARE_ALL_WEAKLINGS] Then UseSkillEx($SSRD_YOU_ARE_ALL_WEAKLINGS, $nearestFoe)
					$spirit_slaves_ranger_derv_center_started = True
				EndIf
				ChangeTarget($nearestFoe)
				Attack($nearestFoe)
				If IsRecharged($SSRD_CRIPPLING_VICTORY) And SpiritSlavesRangerDervHasAdrenaline($SSRD_CRIPPLING_VICTORY, $SSRD_CHAIN_MIN_ADREN5) Then UseSkillEx($SSRD_CRIPPLING_VICTORY, $nearestFoe)
				If IsRecharged($SSRD_REAP_IMPURITIES) And SpiritSlavesRangerDervHasAdrenaline($SSRD_REAP_IMPURITIES, $SSRD_CHAIN_MIN_ADREN6) Then UseSkillEx($SSRD_REAP_IMPURITIES, $nearestFoe)
			EndIf
			RandomSleep(1000)
		EndIf
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
	WEnd
	Local $remainingFoes = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)

	If IsPlayerDead() Then Return $FAIL
	If $remainingFoes > 0 Then
		If $remainingFoes <= 3 Then
			SpiritSlavesRangerDervLogWarn('Kill sequence timeout with small tail (' & $remainingFoes & ' foes); trying one cleanup pass')
			SpiritSlavesRangerDervCleanupSmallTail()
			$remainingFoes = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
			If IsPlayerDead() Then Return $FAIL
		EndIf
	EndIf
	If $remainingFoes > 0 Then
		SpiritSlavesRangerDervLogWarn('Kill sequence timeout/abort with ' & $remainingFoes & ' foes remaining; forcing safe run reset')
		SpiritSlavesRangerDervEnsureWeaponSet3('kill-sequence-abort')
		SpiritSlavesRangerDervMaintainDefensiveUpkeep()
		If $remainingFoes <= 3 Then
			SpiritSlavesRangerDervLogInfo('Small tail abort: attempting one quick loot pass before reset')
			PickUpItems(SpiritSlavesRangerDervMaintainDefensiveUpkeep)
		EndIf
		Return $FAIL
	EndIf
	SpiritSlavesRangerDervEnsureWeaponSet3('kill-sequence-end')
	$spirit_slaves_ranger_derv_center_started = False
	SpiritSlavesRangerDervMaintainDefensiveUpkeep()
	RandomSleep(1000)
	PickUpItems(SpiritSlavesRangerDervMaintainDefensiveUpkeep)
	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerDervWaitForFoesBall()
	SpiritSlavesRangerDervWaitForAlliesDead()

	Local $deadlock = TimerInit()
	Local $target = GetNearestEnemyToCoords(-8598, -5810)
	Local $foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
	Local $validation = 0

	While IsPlayerAlive() And $foesCount < 8 And $validation < 2 And TimerDiff($deadlock) < 120000
		If $foesCount == 8 Then $validation += 1
		RandomSleep(3000)
		$target = GetNearestEnemyToCoords(-8598, -5810)
		$foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
		SpiritSlavesRangerDervLogDebug('foes: ' & $foesCount & '/8')
	WEnd
	If (TimerDiff($deadlock) > 120000) Then SpiritSlavesRangerDervLogInfo('Timed out waiting for mobs to ball')
EndFunc


Func SpiritSlavesRangerDervWaitForAlliesDead()
	Local $deadlock = TimerInit()
	Local $target = GetNearestNPCToCoords(-8598, -5810)

	While GetDistanceToPoint($target, -8598, -5810) < $RANGE_EARSHOT And TimerDiff($deadlock) < 120000
		RandomSleep(5000)
		$target = GetNearestNPCToCoords(-8598, -5810)
	WEnd
	If (TimerDiff($deadlock) > 120000) Then SpiritSlavesRangerDervLogInfo('Timed out waiting for allies to be dead')
EndFunc


Func SpiritSlavesRangerDervRestartAfterDeath()
	If Not IsPlayerDead() Then
		SpiritSlavesRangerDervLogInfo('Restart requested after kill-timeout/abort: rezoning now')
		SpiritSlavesRangerDervRezoneToTheShatteredRavines()
		Return $FAIL
	EndIf

	Local $deadlockTimer = TimerInit()
	SpiritSlavesRangerDervLogInfo('Waiting for resurrection')
	While IsPlayerDead()
		RandomSleep(1000)
		If TimerDiff($deadlockTimer) > 60000 Then
			$spirit_slaves_ranger_derv_farm_setup = False
			SpiritSlavesRangerDervLogInfo('Travelling to Bone Palace')
			TravelToOutpost($ID_BONE_PALACE, $district_name)
			Return $FAIL
		EndIf
	WEnd
	SpiritSlavesRangerDervRezoneToTheShatteredRavines()
	Return $FAIL
EndFunc


Func SpiritSlavesRangerDervWaitForEnergy()
	Local $timer = TimerInit()
	While (GetEnergy() < 20) And IsPlayerAlive() And TimerDiff($timer) < $SSRD_ENERGY_WAIT_MAX_MS
		RandomSleep(1000)
	WEnd
	If IsPlayerDead() Then Return $FAIL
	If GetEnergy() < 20 Then Return $FAIL
	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerDervWaitForReengageReadiness($maxMs = $SSRD_REENGAGE_WAIT_MAX_MS)
	Local $timer = TimerInit()
	While IsPlayerAlive() And TimerDiff($timer) < $maxMs
		SpiritSlavesRangerDervMaintainDefensiveUpkeep()
		Local $me = GetMyAgent()
		If DllStructGetData($me, 'HealthPercent') >= $SSRD_REENGAGE_MIN_HP And DllStructGetData($me, 'EnergyPercent') >= $SSRD_REENGAGE_MIN_ENERGY Then Return $SUCCESS
		RandomSleep(250)
	WEnd
	If IsPlayerDead() Then Return $FAIL
	Return $FAIL
EndFunc


Func SpiritSlavesRangerDervCleanseFromCripple()
	If GetHasCondition(GetMyAgent()) And GetEffect($ID_CRIPPLED) <> Null Then
		If IsRecharged($SSRD_ESCAPE) And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_ESCAPE] Then UseSkillEx($SSRD_ESCAPE)
	EndIf
EndFunc


Func SpiritSlavesRangerDervIsPastAggroLine($agent)
	Return Not IsOverLine(1, 0, 6750, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
EndFunc
