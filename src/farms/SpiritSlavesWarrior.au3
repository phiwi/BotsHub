#include-once

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; Original-dungeon-flow-inspired Warrior variant.
Global Const $SPIRIT_SLAVES_WARRIOR_SKILLBAR = 'OQMT00IKZSpYHE8hv6mMX0fYkAA'
Global Const $SPIRIT_SLAVES_WARRIOR_FARM_INFORMATIONS = 'Warrior variant that stays close to Spirit Slaves Ranger flow'
Global Const $SPIRIT_SLAVES_WARRIOR_FARM_DURATION = 10 * 60 * 1000
Global Const $SSW_LOG_TAG = '[SS-Warrior] '

Global Const $SSW_CYCLONE_AXE = 1
Global Const $SSW_WHIRLWIND_ATTACK = 2
Global Const $SSW_TRIPLE_CHOP = 3
Global Const $SSW_FLAIL = 4
Global Const $SSW_YOU_ARE_ALL_WEAKLINGS = 5
Global Const $SSW_EBON_BATTLE_STANDARD_OF_HONOR = 6
Global Const $SSW_VIGOROUS_SPIRIT = 7
Global Const $SSW_LIVE_VICARIOUSLY = 8

Global Const $SSW_SKILLS_ARRAY = [$SSW_CYCLONE_AXE, $SSW_WHIRLWIND_ATTACK, $SSW_TRIPLE_CHOP, $SSW_FLAIL, $SSW_YOU_ARE_ALL_WEAKLINGS, $SSW_EBON_BATTLE_STANDARD_OF_HONOR, $SSW_VIGOROUS_SPIRIT, $SSW_LIVE_VICARIOUSLY]
Global Const $SSW_SKILLS_COSTS_ARRAY = [5, 0, 5, 0, 5, 10, 5, 1]
Global Const $SSW_SKILL_COSTS_MAP = MapFromArrays($SSW_SKILLS_ARRAY, $SSW_SKILLS_COSTS_ARRAY)
Global Const $SSW_CHAIN_MIN_ADREN2 = 6
Global Const $SSW_NORTH_CENTER_X = -8598
Global Const $SSW_NORTH_CENTER_Y = -5810
Global Const $SSW_NORTH_CLEAR_RETRY_MAX = 2
Global Const $SSW_SOUTH_WAIT_MAX_MS = 120000
Global Const $SSW_ENERGY_WAIT_MAX_MS = 25000
Global Const $SSW_REENGAGE_MIN_HP = 0.99
Global Const $SSW_REENGAGE_MIN_ENERGY = 0.99
Global Const $SSW_REENGAGE_WAIT_MAX_MS = 20000

Global $spirit_slaves_warrior_farm_setup = False
Global $spirit_slaves_warrior_build_setup = False
Global $spirit_slaves_warrior_center_started = False
Global $spirit_slaves_warrior_live_vicariously_primed = False


Func SpiritSlavesWarriorLogInfo($message)
	Info($SSW_LOG_TAG & $message)
EndFunc


Func SpiritSlavesWarriorLogWarn($message)
	Warn($SSW_LOG_TAG & $message)
EndFunc


Func SpiritSlavesWarriorLogDebug($message)
	Debug($SSW_LOG_TAG & $message)
EndFunc


Func SpiritSlavesWarriorFarm()
	If Not $spirit_slaves_warrior_farm_setup And SetupSpiritSlavesWarriorFarm() == $FAIL Then Return $PAUSE
	Return SpiritSlavesWarriorFarmLoop()
EndFunc


Func SetupSpiritSlavesWarriorFarm()
	If GetMapID() <> $ID_THE_SHATTERED_RAVINES Then
		If TravelToOutpost($ID_BONE_PALACE, $district_name) == $FAIL Then Return $FAIL
		SwitchMode($ID_HARD_MODE)
		SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)

		If SetupPlayerSpiritSlavesWarriorFarm() == $FAIL Then Return $FAIL
		LeaveParty()
		While Not $spirit_slaves_warrior_farm_setup
			If SpiritSlavesWarriorRunToShatteredRavines() == $FAIL Then ContinueLoop
			$spirit_slaves_warrior_farm_setup = True
		WEnd
	EndIf
	SpiritSlavesWarriorLogInfo('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerSpiritSlavesWarriorFarm()
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_WARRIOR Then
		SpiritSlavesWarriorLogWarn('Should run this farm as warrior')
		Return $FAIL
	EndIf

	If Not $spirit_slaves_warrior_build_setup Then
		SpiritSlavesWarriorLogInfo('Setting up player build skill bar')
		LoadSkillTemplate($SPIRIT_SLAVES_WARRIOR_SKILLBAR)
		RandomSleep(250)
		$spirit_slaves_warrior_build_setup = True
	Else
		SpiritSlavesWarriorLogInfo('Player build already configured: skipping skillbar reload')
	EndIf

	SpiritSlavesWarriorEnsureWeaponSet3('setup')
	Return $SUCCESS
EndFunc


Func SpiritSlavesWarriorEnsureWeaponSet3($reason = '')
	SpiritSlavesWarriorLogInfo('Weapon set enforcement -> 3' & ($reason <> '' ? ' (' & $reason & ')' : ''))
	ChangeWeaponSet(3)
	RandomSleep(120)
EndFunc


Func SpiritSlavesWarriorEnsureWeaponSet1($reason = '')
	SpiritSlavesWarriorLogInfo('Weapon set enforcement -> 1' & ($reason <> '' ? ' (' & $reason & ')' : ''))
	ChangeWeaponSet(1)
	RandomSleep(120)
EndFunc


Func SpiritSlavesWarriorRunToShatteredRavines()
	TravelToOutpost($ID_BONE_PALACE, $district_name)
	MoveTo(-14520, 6009)
	Move(-14820, 3400)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_JOKOS_DOMAIN) Then Return $FAIL
	RandomSleep(500)
	MoveTo(-12657, 2609)
	SpiritSlavesWarriorEnsureWeaponSet3('run-to-ravines')
	MoveTo(-10938, 4254)
	ChangeTarget(GetNearestSignpostToCoords(-10938, 4254))
	RandomSleep(500)
	SpiritSlavesWarriorLogInfo('Taking wurm')
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

	SpiritSlavesWarriorEnsureWeaponSet3('before-ravines-entry')
	SpiritSlavesWarriorLogInfo('Entering The Shattered Ravines : careful')
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_THE_SHATTERED_RAVINES, 10000, 2000) Then Return $FAIL
	MoveTo(-9714, -10767)
	MoveTo(-7919, -10530)
	Return $SUCCESS
EndFunc


Func SpiritSlavesWarriorFarmLoop()
	SpiritSlavesWarriorEnsureWeaponSet3('farm-loop-start')
	UseConsumable($ID_SLICE_OF_PUMPKIN_PIE)

	SpiritSlavesWarriorLogInfo('Killing group 1 @ North')
	If SpiritSlavesWarriorFarmNorthGroup() == $FAIL Then Return SpiritSlavesWarriorRestartAfterDeath()
	SpiritSlavesWarriorEnsureWeaponSet1('between-wave-1-and-2-energy-recovery')
	SpiritSlavesWarriorLogInfo('Killing group 2 @ South')
	If SpiritSlavesWarriorFarmSouthGroup() == $FAIL Then Return SpiritSlavesWarriorRestartAfterDeath()
	SpiritSlavesWarriorLogInfo('Killing group 3 @ South')
	If SpiritSlavesWarriorFarmSouthGroup() == $FAIL Then Return SpiritSlavesWarriorRestartAfterDeath()
	SpiritSlavesWarriorLogInfo('Killing group 4 @ North')
	If SpiritSlavesWarriorFarmNorthGroup() == $FAIL Then Return SpiritSlavesWarriorRestartAfterDeath()
	SpiritSlavesWarriorLogInfo('Killing group 5 @ North')
	If SpiritSlavesWarriorFarmNorthGroup() == $FAIL Then Return SpiritSlavesWarriorRestartAfterDeath()

	SpiritSlavesWarriorLogInfo('Moving out of the zone and back again')
	Move(-7735, -8380)
	SpiritSlavesWarriorRezoneToTheShatteredRavines()

	Return $SUCCESS
EndFunc


Func SpiritSlavesWarriorRezoneToTheShatteredRavines()
	SpiritSlavesWarriorLogInfo('Rezoning')
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


Func SpiritSlavesWarriorFarmNorthGroup()
	MoveTo(-7375, -7767)
	SpiritSlavesWarriorWaitForFoesBall()
	If SpiritSlavesWarriorWaitForEnergy() == $FAIL Then Return $FAIL
	Local $targetFoe = GetNearestNPCInRangeOfCoords($SSW_NORTH_CENTER_X, $SSW_NORTH_CENTER_Y, $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe)
	SpiritSlavesWarriorEnsureWeaponSet3('north-group')
	SpiritSlavesWarriorStartUpkeepSequence($targetFoe)
	SpiritSlavesWarriorMaintainUpkeep($targetFoe)
	RandomSleep(150)
	If IsPlayerDead() Then Return $FAIL

	Local $positionToGo = FindMiddleOfFoes($SSW_NORTH_CENTER_X, $SSW_NORTH_CENTER_Y, $RANGE_AREA)
	MoveTo($positionToGo[0], $positionToGo[1])
	RandomSleep(120)
	SpiritSlavesWarriorMaintainUpkeep($targetFoe)

	If IsPlayerDead() Then Return $FAIL
	If SpiritSlavesWarriorKillSequence() == $FAIL Then Return $FAIL
	If SpiritSlavesWarriorEnsureNorthGroupCleared() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func SpiritSlavesWarriorEnsureNorthGroupCleared()
	Local $attempt = 0
	Local $remaining = CountFoesInRangeOfCoords($SSW_NORTH_CENTER_X, $SSW_NORTH_CENTER_Y, $RANGE_EARSHOT)
	While IsPlayerAlive() And $remaining > 0 And $attempt < $SSW_NORTH_CLEAR_RETRY_MAX
		$attempt += 1
		SpiritSlavesWarriorLogWarn('North group still has ' & $remaining & ' foes; cleanup pass ' & $attempt)
		Local $positionToGo = FindMiddleOfFoes($SSW_NORTH_CENTER_X, $SSW_NORTH_CENTER_Y, $RANGE_AREA)
		MoveTo($positionToGo[0], $positionToGo[1])
		RandomSleep(120)
		If SpiritSlavesWarriorKillSequence() == $FAIL Then Return $FAIL
		$remaining = CountFoesInRangeOfCoords($SSW_NORTH_CENTER_X, $SSW_NORTH_CENTER_Y, $RANGE_EARSHOT)
	WEnd
	If IsPlayerDead() Then Return $FAIL
	If $remaining > 0 Then
		SpiritSlavesWarriorLogWarn('North group not fully cleared; aborting progression with ' & $remaining & ' foes still present')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func SpiritSlavesWarriorFarmSouthGroup()
	$spirit_slaves_warrior_center_started = False
	Local $forceImmediateEngage = False
	SpiritSlavesWarriorEnsureWeaponSet1('south-staging-energy-recovery')
	SpiritSlavesWarriorCleanseFromCripple()
	MoveTo(-7830, -7860)
	SpiritSlavesWarriorCleanseFromCripple()
	Local $nearbyNow = CountFoesInRangeOfAgent(GetMyAgent(), 950)
	If $nearbyNow >= 3 Then
		$forceImmediateEngage = True
		SpiritSlavesWarriorLogInfo('South staging: nearby aggro detected (' & $nearbyNow & '), forcing immediate engage')
	EndIf
	Local $foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, SpiritSlavesWarriorIsPastAggroLine)
	Local $deadlock = TimerInit()
	While IsPlayerAlive() And Not $forceImmediateEngage And $foesCount < 8 And TimerDiff($deadlock) < $SSW_SOUTH_WAIT_MAX_MS
		RandomSleep(100)
		$foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, SpiritSlavesWarriorIsPastAggroLine)
		SpiritSlavesWarriorCleanseFromCripple()
		$nearbyNow = CountFoesInRangeOfAgent(GetMyAgent(), 950)
		If $nearbyNow >= 3 Then
			$forceImmediateEngage = True
			SpiritSlavesWarriorLogInfo('South staging: aggro arrived during wait (' & $nearbyNow & '), engaging now')
		EndIf
	WEnd
	If Not $forceImmediateEngage And TimerDiff($deadlock) >= $SSW_SOUTH_WAIT_MAX_MS And $foesCount < 8 Then
		SpiritSlavesWarriorLogWarn('South staging timeout: mobs did not pass aggro line in time')
		Return $FAIL
	EndIf
	SpiritSlavesWarriorCleanseFromCripple()
	If Not $forceImmediateEngage Then
		Move(-7735, -8380)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 950)
		$deadlock = TimerInit()
		While IsPlayerAlive() And $foesCount == 0 And TimerDiff($deadlock) < $SSW_SOUTH_WAIT_MAX_MS
			RandomSleep(100)
			$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 950)
		WEnd
		If TimerDiff($deadlock) >= $SSW_SOUTH_WAIT_MAX_MS And $foesCount == 0 Then
			SpiritSlavesWarriorLogWarn('South staging timeout: no aggro acquired near hold spot')
			Return $FAIL
		EndIf
	EndIf
	If IsPlayerDead() Then Return $FAIL
	If $forceImmediateEngage Then
		SpiritSlavesWarriorLogInfo('South staging: waiting for HP/energy recovery before engage')
		If SpiritSlavesWarriorWaitForReengageReadiness() == $FAIL Then
			SpiritSlavesWarriorLogWarn('South staging timeout: HP/energy did not recover enough for safe engage')
			Return $FAIL
		EndIf
	Else
		If SpiritSlavesWarriorWaitForEnergy() == $FAIL Then
			SpiritSlavesWarriorLogWarn('South staging timeout: energy did not recover to 20 in time')
			Return $FAIL
		EndIf
	EndIf

	SpiritSlavesWarriorEnsureWeaponSet3('south-group')
	MoveTo(-7800, -7680)
	Local $targetFoe = GetNearestEnemyToAgent(GetMyAgent())
	SpiritSlavesWarriorStartUpkeepSequence($targetFoe)
	SpiritSlavesWarriorMaintainUpkeep($targetFoe)
	RandomSleep(150)

	If IsPlayerDead() Then Return $FAIL

	Local $positionToGo = FindMiddleOfFoes(-8055, -9250, $RANGE_NEARBY)
	MoveTo($positionToGo[0], $positionToGo[1])
	RandomSleep(120)
	$targetFoe = GetNearestEnemyToAgent(GetMyAgent())
	SpiritSlavesWarriorMaintainUpkeep($targetFoe)

	If IsPlayerDead() Then Return $FAIL
	If SpiritSlavesWarriorKillSequence() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func SpiritSlavesWarriorStartUpkeepSequence($target = Null)
	If Not $spirit_slaves_warrior_live_vicariously_primed And IsRecharged($SSW_LIVE_VICARIOUSLY) And GetEnergy() >= $SSW_SKILL_COSTS_MAP[$SSW_LIVE_VICARIOUSLY] Then
		UseSkillEx($SSW_LIVE_VICARIOUSLY, GetMyAgent())
		$spirit_slaves_warrior_live_vicariously_primed = True
	EndIf
	SpiritSlavesWarriorMaintainUpkeep($target)
EndFunc


Func SpiritSlavesWarriorMaintainUpkeep($target = Null)
	If IsRecharged($SSW_FLAIL) And GetEffectTimeRemaining(GetEffect($ID_FLAIL)) == 0 Then UseSkillEx($SSW_FLAIL)
	If IsRecharged($SSW_EBON_BATTLE_STANDARD_OF_HONOR) And GetEnergy() >= $SSW_SKILL_COSTS_MAP[$SSW_EBON_BATTLE_STANDARD_OF_HONOR] Then UseSkillEx($SSW_EBON_BATTLE_STANDARD_OF_HONOR)
	If IsRecharged($SSW_VIGOROUS_SPIRIT) And GetEffectTimeRemaining(GetEffect($ID_VIGOROUS_SPIRIT)) == 0 And GetEnergy() >= $SSW_SKILL_COSTS_MAP[$SSW_VIGOROUS_SPIRIT] Then UseSkillEx($SSW_VIGOROUS_SPIRIT, GetMyAgent())
	If $spirit_slaves_warrior_center_started Then
		If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY) == 0 Then Return
		If $target == Null Then $target = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_COMPASS)
		If $target <> Null And IsRecharged($SSW_YOU_ARE_ALL_WEAKLINGS) And GetEnergy() >= $SSW_SKILL_COSTS_MAP[$SSW_YOU_ARE_ALL_WEAKLINGS] Then UseSkillEx($SSW_YOU_ARE_ALL_WEAKLINGS, $target)
	EndIf
EndFunc


Func SpiritSlavesWarriorHasAdrenaline($skillSlot, $requiredStrikes)
	Return GetSkillbarSkillAdrenaline($skillSlot) >= $requiredStrikes
EndFunc


Func SpiritSlavesWarriorCleanupSmallTail($maxMs = 12000)
	Local $nextKillSkill = $SSW_CYCLONE_AXE
	Local $timer = TimerInit()
	While IsPlayerAlive() And TimerDiff($timer) < $maxMs
		Local $me = GetMyAgent()
		Local $nearestFoe = GetNearestEnemyToAgent($me)
		If $nearestFoe == Null Then ExitLoop
		If GetDistance($me, $nearestFoe) > ($RANGE_AREA + 88) Then ExitLoop

		SpiritSlavesWarriorMaintainUpkeep($nearestFoe)
		ChangeTarget($nearestFoe)
		Attack($nearestFoe)
		SpiritSlavesWarriorUseKillRotation($nearestFoe, $nextKillSkill)
		RandomSleep(250)

		If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) == 0 Then ExitLoop
	WEnd
EndFunc


Func SpiritSlavesWarriorUseKillRotation($target, ByRef $nextSkill)
	If $target == Null Then Return

	If $nextSkill == $SSW_CYCLONE_AXE And IsRecharged($SSW_CYCLONE_AXE) And GetEnergy() >= $SSW_SKILL_COSTS_MAP[$SSW_CYCLONE_AXE] Then
		UseSkillEx($SSW_CYCLONE_AXE, $target)
		$nextSkill = $SSW_WHIRLWIND_ATTACK
		Return
	EndIf

	If $nextSkill == $SSW_WHIRLWIND_ATTACK And IsRecharged($SSW_WHIRLWIND_ATTACK) And SpiritSlavesWarriorHasAdrenaline($SSW_WHIRLWIND_ATTACK, $SSW_CHAIN_MIN_ADREN2) Then
		UseSkillEx($SSW_WHIRLWIND_ATTACK, $target)
		$nextSkill = $SSW_TRIPLE_CHOP
		Return
	EndIf

	If $nextSkill == $SSW_TRIPLE_CHOP And IsRecharged($SSW_TRIPLE_CHOP) And GetEnergy() >= $SSW_SKILL_COSTS_MAP[$SSW_TRIPLE_CHOP] Then
		UseSkillEx($SSW_TRIPLE_CHOP, $target)
		$nextSkill = $SSW_WHIRLWIND_ATTACK
		Return
	EndIf

	If IsRecharged($SSW_WHIRLWIND_ATTACK) And SpiritSlavesWarriorHasAdrenaline($SSW_WHIRLWIND_ATTACK, $SSW_CHAIN_MIN_ADREN2) Then
		UseSkillEx($SSW_WHIRLWIND_ATTACK, $target)
		$nextSkill = $SSW_TRIPLE_CHOP
		Return
	EndIf

	If IsRecharged($SSW_CYCLONE_AXE) And GetEnergy() >= $SSW_SKILL_COSTS_MAP[$SSW_CYCLONE_AXE] Then
		UseSkillEx($SSW_CYCLONE_AXE, $target)
		$nextSkill = $SSW_WHIRLWIND_ATTACK
		Return
	EndIf

	If IsRecharged($SSW_TRIPLE_CHOP) And GetEnergy() >= $SSW_SKILL_COSTS_MAP[$SSW_TRIPLE_CHOP] Then
		UseSkillEx($SSW_TRIPLE_CHOP, $target)
		$nextSkill = $SSW_WHIRLWIND_ATTACK
	EndIf
EndFunc


Func SpiritSlavesWarriorKillSequence()
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	Local $casterFoesMap[]
	Local $nextKillSkill = $SSW_CYCLONE_AXE
	SpiritSlavesWarriorEnsureWeaponSet3('kill-sequence-start')
	SpiritSlavesWarriorLogInfo('Warrior kill sequence start: foes(area)=' & $foesCount)
	$spirit_slaves_warrior_center_started = False

	While IsPlayerAlive() And $foesCount > 0 And TimerDiff($deadlock) < 100000
		SpiritSlavesWarriorMaintainUpkeep()
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
				If Not $spirit_slaves_warrior_center_started Then
					If IsRecharged($SSW_YOU_ARE_ALL_WEAKLINGS) And GetEnergy() >= $SSW_SKILL_COSTS_MAP[$SSW_YOU_ARE_ALL_WEAKLINGS] Then UseSkillEx($SSW_YOU_ARE_ALL_WEAKLINGS, $nearestFoe)
					$spirit_slaves_warrior_center_started = True
				EndIf
				ChangeTarget($nearestFoe)
				Attack($nearestFoe)
				SpiritSlavesWarriorUseKillRotation($nearestFoe, $nextKillSkill)
			EndIf
			RandomSleep(1000)
		EndIf
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
	WEnd
	Local $remainingFoes = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)

	If IsPlayerDead() Then Return $FAIL
	If $remainingFoes > 0 Then
		If $remainingFoes <= 3 Then
			SpiritSlavesWarriorLogWarn('Kill sequence timeout with small tail (' & $remainingFoes & ' foes); trying one cleanup pass')
			SpiritSlavesWarriorCleanupSmallTail()
			$remainingFoes = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
			If IsPlayerDead() Then Return $FAIL
		EndIf
	EndIf
	If $remainingFoes > 0 Then
		SpiritSlavesWarriorLogWarn('Kill sequence timeout/abort with ' & $remainingFoes & ' foes remaining; forcing safe run reset')
		SpiritSlavesWarriorEnsureWeaponSet3('kill-sequence-abort')
		SpiritSlavesWarriorMaintainUpkeep()
		If $remainingFoes <= 3 Then
			SpiritSlavesWarriorLogInfo('Small tail abort: attempting one quick loot pass before reset')
			PickUpItems(SpiritSlavesWarriorMaintainUpkeep)
		EndIf
		Return $FAIL
	EndIf
	SpiritSlavesWarriorEnsureWeaponSet3('kill-sequence-end')
	$spirit_slaves_warrior_center_started = False
	SpiritSlavesWarriorMaintainUpkeep()
	RandomSleep(1000)
	PickUpItems(SpiritSlavesWarriorMaintainUpkeep)
	Return $SUCCESS
EndFunc


Func SpiritSlavesWarriorWaitForFoesBall()
	SpiritSlavesWarriorWaitForAlliesDead()

	Local $deadlock = TimerInit()
	Local $target = GetNearestEnemyToCoords(-8598, -5810)
	Local $foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
	Local $validation = 0

	While IsPlayerAlive() And $foesCount < 8 And $validation < 2 And TimerDiff($deadlock) < 120000
		If $foesCount == 8 Then $validation += 1
		RandomSleep(3000)
		$target = GetNearestEnemyToCoords(-8598, -5810)
		$foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
		SpiritSlavesWarriorLogDebug('foes: ' & $foesCount & '/8')
	WEnd
	If (TimerDiff($deadlock) > 120000) Then SpiritSlavesWarriorLogInfo('Timed out waiting for mobs to ball')
EndFunc


Func SpiritSlavesWarriorWaitForAlliesDead()
	Local $deadlock = TimerInit()
	Local $target = GetNearestNPCToCoords(-8598, -5810)

	While GetDistanceToPoint($target, -8598, -5810) < $RANGE_EARSHOT And TimerDiff($deadlock) < 120000
		RandomSleep(5000)
		$target = GetNearestNPCToCoords(-8598, -5810)
	WEnd
	If (TimerDiff($deadlock) > 120000) Then SpiritSlavesWarriorLogInfo('Timed out waiting for allies to be dead')
EndFunc


Func SpiritSlavesWarriorRestartAfterDeath()
	If Not IsPlayerDead() Then
		SpiritSlavesWarriorLogInfo('Restart requested after kill-timeout/abort: rezoning now')
		SpiritSlavesWarriorRezoneToTheShatteredRavines()
		Return $FAIL
	EndIf

	Local $deadlockTimer = TimerInit()
	SpiritSlavesWarriorLogInfo('Waiting for resurrection')
	While IsPlayerDead()
		RandomSleep(1000)
		If TimerDiff($deadlockTimer) > 60000 Then
			$spirit_slaves_warrior_farm_setup = False
			SpiritSlavesWarriorLogInfo('Travelling to Bone Palace')
			TravelToOutpost($ID_BONE_PALACE, $district_name)
			Return $FAIL
		EndIf
	WEnd
	SpiritSlavesWarriorRezoneToTheShatteredRavines()
	Return $FAIL
EndFunc


Func SpiritSlavesWarriorWaitForEnergy()
	Local $timer = TimerInit()
	While (GetEnergy() < 20) And IsPlayerAlive() And TimerDiff($timer) < $SSW_ENERGY_WAIT_MAX_MS
		RandomSleep(1000)
	WEnd
	If IsPlayerDead() Then Return $FAIL
	If GetEnergy() < 20 Then Return $FAIL
	Return $SUCCESS
EndFunc


Func SpiritSlavesWarriorWaitForReengageReadiness($maxMs = $SSW_REENGAGE_WAIT_MAX_MS)
	Local $timer = TimerInit()
	While IsPlayerAlive() And TimerDiff($timer) < $maxMs
		SpiritSlavesWarriorMaintainUpkeep()
		Local $me = GetMyAgent()
		If DllStructGetData($me, 'HealthPercent') >= $SSW_REENGAGE_MIN_HP And DllStructGetData($me, 'EnergyPercent') >= $SSW_REENGAGE_MIN_ENERGY Then Return $SUCCESS
		RandomSleep(250)
	WEnd
	If IsPlayerDead() Then Return $FAIL
	Return $FAIL
EndFunc


Func SpiritSlavesWarriorCleanseFromCripple()
	Return
EndFunc


Func SpiritSlavesWarriorIsPastAggroLine($agent)
	Return Not IsOverLine(1, 0, 6750, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
EndFunc
