#include-once

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; Original-dungeon-flow-inspired Ranger variant.
Global Const $SPIRIT_SLAVES_RANGER_SKILLBAR = 'Ogojchpr6SAH3kfXdfjhOXxl3lA'
Global Const $SPIRIT_SLAVES_RANGER_FARM_INFORMATIONS = 'Ranger variant that stays close to original Dervish Spirit Slaves flow'
Global Const $SPIRIT_SLAVES_RANGER_FARM_DURATION = 10 * 60 * 1000
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

Global $spirit_slaves_ranger_farm_setup = False
Global $spirit_slaves_ranger_build_setup = False
Global $spirit_slaves_ranger_center_started = False


Func SpiritSlavesRangerLogInfo($message)
	Info($SSRD_LOG_TAG & $message)
EndFunc


Func SpiritSlavesRangerLogWarn($message)
	Warn($SSRD_LOG_TAG & $message)
EndFunc


Func SpiritSlavesRangerLogDebug($message)
	Debug($SSRD_LOG_TAG & $message)
EndFunc


Func SpiritSlavesRangerFarm()
	If Not $spirit_slaves_ranger_farm_setup And SetupSpiritSlavesRangerFarm() == $FAIL Then Return $PAUSE
	Return SpiritSlavesRangerFarmLoop()
EndFunc


Func SetupSpiritSlavesRangerFarm()
	If GetMapID() <> $ID_THE_SHATTERED_RAVINES Then
		If TravelToOutpost($ID_BONE_PALACE, $district_name) == $FAIL Then Return $FAIL
		SwitchMode($ID_HARD_MODE)
		SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)

		If SetupPlayerSpiritSlavesRangerFarm() == $FAIL Then Return $FAIL
		LeaveParty()
		While Not $spirit_slaves_ranger_farm_setup
			If SpiritSlavesRangerRunToShatteredRavines() == $FAIL Then ContinueLoop
			$spirit_slaves_ranger_farm_setup = True
		WEnd
	EndIf
	SpiritSlavesRangerLogInfo('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerSpiritSlavesRangerFarm()
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_RANGER Then
		SpiritSlavesRangerLogWarn('Should run this farm as ranger')
		Return $FAIL
	EndIf

	If Not $spirit_slaves_ranger_build_setup Then
		SpiritSlavesRangerLogInfo('Setting up player build skill bar')
		If HeroHasTemplate(0, $SPIRIT_SLAVES_RANGER_SKILLBAR) Then
			SpiritSlavesRangerLogInfo('Player build already on bar, skipping template load')
		Else
			LoadSkillTemplate($SPIRIT_SLAVES_RANGER_SKILLBAR)
			RandomSleep(250)
		EndIf
		$spirit_slaves_ranger_build_setup = True
	Else
		SpiritSlavesRangerLogInfo('Player build already configured: skipping skillbar reload')
	EndIf

	SpiritSlavesRangerEnsureWeaponSet3('setup')
	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerEnsureWeaponSet3($reason = '')
	SpiritSlavesRangerLogInfo('Weapon set enforcement -> 3' & ($reason <> '' ? ' (' & $reason & ')' : ''))
	ChangeWeaponSet(3)
	RandomSleep(120)
EndFunc


Func SpiritSlavesRangerRunToShatteredRavines()
	TravelToOutpost($ID_BONE_PALACE, $district_name)
	MoveTo(-14520, 6009)
	Move(-14820, 3400)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_JOKOS_DOMAIN) Then Return $FAIL
	RandomSleep(500)
	MoveTo(-12657, 2609)
	SpiritSlavesRangerEnsureWeaponSet3('run-to-ravines')
	MoveTo(-10938, 4254)
	ChangeTarget(GetNearestSignpostToCoords(-10938, 4254))
	RandomSleep(500)
	SpiritSlavesRangerLogInfo('Taking wurm')
	TargetNearestItem()
	ActionInteract()
	RandomSleep(1500)
	UseSkillEx(5)
	MoveTo(-8255, 5320)
	Local $me = GetMyAgent()
	If (CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 0) Then UseSkillEx(5)
	; Escape for IMS + 75% block during the long wurm sprint
	If IsRecharged($SSRD_ESCAPE) And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_ESCAPE] Then UseSkillEx($SSRD_ESCAPE)
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

	SpiritSlavesRangerEnsureWeaponSet3('before-ravines-entry')
	SpiritSlavesRangerLogInfo('Entering The Shattered Ravines : careful')
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_THE_SHATTERED_RAVINES, 10000, 2000) Then Return $FAIL
	MoveTo(-9714, -10767)
	MoveTo(-7919, -10530)
	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerFarmLoop()
	SpiritSlavesRangerEnsureWeaponSet3('farm-loop-start')
	UseConsumable($ID_SLICE_OF_PUMPKIN_PIE)

	Local $bottomPosition = [-8500, -6400]
	Local $topPosition = [-8900, -4600]
	; 5 Groups — identical wave pattern to original Spirit Slaves
	For $group = 1 To 5
		If $group <> 4 Then MoveTo(-7465, -7900, 0)
		If $group == 1 Then SpiritSlavesRangerWaitForAlliesDead()
		Local $balled = True
		If $group >= 1 And $group <= 3 Then $balled = SpiritSlavesRangerWaitForFoesBall($bottomPosition)
		If $group == 2 Or $group == 5 Then $balled = SpiritSlavesRangerWaitForFoesBall($topPosition)
		If IsPlayerDead() Then Return SpiritSlavesRangerRestartAfterDeath()
		SpiritSlavesRangerLogInfo('Killing group ' & $group)
		If ($balled ? SpiritSlavesRangerFarmGroup() : SpiritSlavesRangerQuickFarmGroup()) == $FAIL Then Return SpiritSlavesRangerRestartAfterDeath()
	Next

	SpiritSlavesRangerLogInfo('Moving out of the zone and back again')
	SpiritSlavesRangerRezoneToTheShatteredRavines()
	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerRezoneToTheShatteredRavines()
	SpiritSlavesRangerLogInfo('Rezoning')
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


;~ Farm group — balled enemies, Ranger combat choreography
;~ Pre-cast Dwarven Stability + Escape + Mystic Vigor before engaging (Escape gives IMS + 75% block).
Func SpiritSlavesRangerFarmGroup()
	$spirit_slaves_ranger_center_started = False
	Local $targetFoe = GetNearestNPCInRangeOfCoords(-8850, -5500, $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT * 2)
	GetAlmostInRangeOfAgent($targetFoe)
	SpiritSlavesRangerEnsureWeaponSet3('farm-group')

	; Ranger choreography: Dwarven Stability -> Escape -> Mystic Vigor before engaging
	If IsRecharged($SSRD_DWARVEN_STABILITY) Then UseSkillEx($SSRD_DWARVEN_STABILITY)
	RandomSleep(50)
	If IsRecharged($SSRD_ESCAPE) And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_ESCAPE] Then UseSkillEx($SSRD_ESCAPE)
	RandomSleep(50)
	If IsRecharged($SSRD_MYSTIC_VIGOR) And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_MYSTIC_VIGOR] Then UseSkillEx($SSRD_MYSTIC_VIGOR)

	; Move directly to the target — same pattern as the original Dervish.
	Move(DllStructGetData($targetFoe, 'X'), DllStructGetData($targetFoe, 'Y'))
	RandomSleep(100)
	$targetFoe = GetNearestEnemyToAgent(GetMyAgent())
	If $targetFoe == Null Then Return $SUCCESS

	If IsPlayerDead() Then Return $FAIL
	If SpiritSlavesRangerKillSequence() == $FAIL Then Return $FAIL
	SpiritSlavesRangerCleanseFromCripple()
	PickUpItems(SpiritSlavesRangerMaintainDefensiveUpkeep)
	Return $SUCCESS
EndFunc


;~ Quick farm group — enemies not balled, caught off guard
Func SpiritSlavesRangerQuickFarmGroup()
	$spirit_slaves_ranger_center_started = False
	MoveTo(-7475, -8040)
	SpiritSlavesRangerEnsureWeaponSet3('quick-farm-group')

	; Ranger choreography: Dwarven Stability -> Escape -> Mystic Vigor before engaging
	If IsRecharged($SSRD_DWARVEN_STABILITY) Then UseSkillEx($SSRD_DWARVEN_STABILITY)
	RandomSleep(50)
	If IsRecharged($SSRD_ESCAPE) And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_ESCAPE] Then UseSkillEx($SSRD_ESCAPE)
	RandomSleep(50)
	If IsRecharged($SSRD_MYSTIC_VIGOR) And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_MYSTIC_VIGOR] Then UseSkillEx($SSRD_MYSTIC_VIGOR)

	Local $targetFoe = GetNearestEnemyToAgent(GetMyAgent())
	If $targetFoe == Null Then Return $SUCCESS

	If IsPlayerDead() Then Return $FAIL
	If SpiritSlavesRangerKillSequence() == $FAIL Then Return $FAIL
	SpiritSlavesRangerCleanseFromCripple()
	PickUpItems(SpiritSlavesRangerMaintainDefensiveUpkeep)
	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerMaintainDefensiveUpkeep()
	If IsRecharged($SSRD_DWARVEN_STABILITY) And GetEffectTimeRemaining(GetEffect($ID_DWARVEN_STABILITY)) == 0 And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_DWARVEN_STABILITY] Then UseSkillEx($SSRD_DWARVEN_STABILITY)
	If IsRecharged($SSRD_ESCAPE) And GetEffectTimeRemaining(GetEffect($ID_ESCAPE)) == 0 And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_ESCAPE] Then UseSkillEx($SSRD_ESCAPE)
	If IsRecharged($SSRD_MYSTIC_VIGOR) And GetEffectTimeRemaining(GetEffect($ID_MYSTIC_VIGOR)) == 0 And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_MYSTIC_VIGOR] Then UseSkillEx($SSRD_MYSTIC_VIGOR)
	; Mental Block — 50% block, self-reapplies on hit. Only when energy is comfortable.
	If IsRecharged($SSRD_MENTAL_BLOCK) And GetEffectTimeRemaining(GetEffect($ID_MENTAL_BLOCK)) == 0 And GetEnergy() > 15 Then UseSkillEx($SSRD_MENTAL_BLOCK)
EndFunc


Func SpiritSlavesRangerMaintainUpkeep($target = Null)
	; Only cast during combat (foes in range) to avoid wasting energy during staging/looting.
	If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY) == 0 Then Return
	SpiritSlavesRangerMaintainDefensiveUpkeep()
	; YaAW — cheap (5e), AoE weakness, top priority for damage mitigation + amplification
	If IsRecharged($SSRD_YOU_ARE_ALL_WEAKLINGS) And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_YOU_ARE_ALL_WEAKLINGS] Then
		If $target == Null Then $target = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_COMPASS)
		If $target <> Null Then UseSkillEx($SSRD_YOU_ARE_ALL_WEAKLINGS, $target)
	EndIf
	; Grenth's Aura — sustain, but expensive (10e). Only when energy is comfortable.
	If IsRecharged($SSRD_GRENTHS_AURA) And GetEnergy() >= 15 Then UseSkillEx($SSRD_GRENTHS_AURA)
EndFunc


Func SpiritSlavesRangerHasAdrenaline($skillSlot, $requiredStrikes)
	Return GetSkillbarSkillAdrenaline($skillSlot) >= $requiredStrikes
EndFunc


Func SpiritSlavesRangerKillSequence()
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST + 200)
	SpiritSlavesRangerEnsureWeaponSet3('kill-sequence-start')
	SpiritSlavesRangerLogInfo('Ranger Derv kill sequence start: foes(spellcast)=' & $foesCount)

	While IsPlayerAlive() And $foesCount > 0 And TimerDiff($deadlock) < 100000
		SpiritSlavesRangerMaintainUpkeep()
		Local $me = GetMyAgent()
		Local $nearestFoe = GetNearestEnemyToAgent($me)

		If $nearestFoe <> Null Then
			; Get in range of the nearest foe — same pattern as the original Dervish.
			If GetDistance($me, $nearestFoe) > $RANGE_ADJACENT Then
				Move(DllStructGetData($nearestFoe, 'X'), DllStructGetData($nearestFoe, 'Y'))
				RandomSleep(200)
			EndIf

			$me = GetMyAgent()
			$nearestFoe = GetNearestEnemyToAgent($me)
			If $nearestFoe <> Null And GetDistance($me, $nearestFoe) < ($RANGE_AREA + 88) Then
				ChangeTarget($nearestFoe)
				Attack($nearestFoe)
				If IsRecharged($SSRD_CRIPPLING_VICTORY) And SpiritSlavesRangerHasAdrenaline($SSRD_CRIPPLING_VICTORY, $SSRD_CHAIN_MIN_ADREN5) Then UseSkillEx($SSRD_CRIPPLING_VICTORY, $nearestFoe)
				If IsRecharged($SSRD_REAP_IMPURITIES) And SpiritSlavesRangerHasAdrenaline($SSRD_REAP_IMPURITIES, $SSRD_CHAIN_MIN_ADREN6) Then UseSkillEx($SSRD_REAP_IMPURITIES, $nearestFoe)
			EndIf
		EndIf
		Sleep(250)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST + 200)
		If IsPlayerDead() Then Return $FAIL
	WEnd

	If IsPlayerDead() Then Return $FAIL
	SpiritSlavesRangerEnsureWeaponSet3('kill-sequence-end')
	$spirit_slaves_ranger_center_started = False
	SpiritSlavesRangerMaintainDefensiveUpkeep()
	RandomSleep(1000)
	PickUpItems(SpiritSlavesRangerMaintainDefensiveUpkeep)
	Return $SUCCESS
EndFunc


;~ Wait for all enemies to be balled — same logic as original Spirit Slaves
Func SpiritSlavesRangerWaitForFoesBall($position)
	Local $deadlock = TimerInit()
	Local $target = Null
	Local $foesCount = 0
	Local $validation = 0
	; Wait until all foes are balled - as long as foes are not aggroed
	While IsPlayerAlive() And $foesCount < 8 And $validation < 2 And TimerDiff($deadlock) < 120000
		If $foesCount == 8 Then $validation += 1
		RandomSleep(1000)
		$target = GetNearestNPCInRangeOfCoords($position[0], $position[1], $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT)
		If $target <> Null Then $foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
		SpiritSlavesRangerLogDebug('foes: ' & $foesCount & '/8')
	WEnd
	If (TimerDiff($deadlock) > 120000) Then SpiritSlavesRangerLogWarn('Timed out waiting for mobs to ball')
	Return True
EndFunc


;~ Wait for allies to be dead — same logic as original
Func SpiritSlavesRangerWaitForAlliesDead()
	Local $deadlock = TimerInit()
	Local $target = GetNearestNPCToCoords(-8600, -5810)

	; Wait until foes are in range of allies
	Local $distance = GetDistanceToPoint($target, -8600, -5810)
	While $distance < $RANGE_EARSHOT And TimerDiff($deadlock) < 120000
		RandomSleep(2000)
		$target = GetNearestNPCToCoords(-8600, -5810)
		$distance = GetDistanceToPoint($target, -8600, -5810)
		SpiritSlavesRangerLogDebug('Target: ' & $distance)
	WEnd
	If (TimerDiff($deadlock) > 120000) Then SpiritSlavesRangerLogWarn('Timed out waiting for allies to be dead')
EndFunc


Func SpiritSlavesRangerRestartAfterDeath()
	If Not IsPlayerDead() Then
		SpiritSlavesRangerLogInfo('Restart requested after kill-timeout/abort: rezoning now')
		SpiritSlavesRangerRezoneToTheShatteredRavines()
		Return $FAIL
	EndIf

	Local $deadlockTimer = TimerInit()
	SpiritSlavesRangerLogInfo('Waiting for resurrection')
	While IsPlayerDead()
		RandomSleep(1000)
		If TimerDiff($deadlockTimer) > 60000 Then
			$spirit_slaves_ranger_farm_setup = False
			SpiritSlavesRangerLogInfo('Travelling to Bone Palace')
			TravelToOutpost($ID_BONE_PALACE, $district_name)
			Return $FAIL
		EndIf
	WEnd
	SpiritSlavesRangerRezoneToTheShatteredRavines()
	Return $FAIL
EndFunc


Func SpiritSlavesRangerCleanseFromCripple()
	If GetHasCondition(GetMyAgent()) And GetEffect($ID_CRIPPLED) <> Null Then
		If IsRecharged($SSRD_ESCAPE) And GetEnergy() >= $SSRD_SKILL_COSTS_MAP[$SSRD_ESCAPE] Then UseSkillEx($SSRD_ESCAPE)
	EndIf
EndFunc
