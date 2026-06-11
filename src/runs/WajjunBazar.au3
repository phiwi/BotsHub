#include-once

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

Global Const $WAJJUN_BAZAR_SKILLBAR = 'Ogojchpr6SAHFH3kdfjhOXxl3lA'
Global Const $WAJJUN_BAZAR_FARM_INFORMATIONS = 'Simple Wajjun Bazar run from The Marketplace with Ranger upkeep/kill choreography'
Global Const $WAJJUN_BAZAR_FARM_DURATION = 4 * 60 * 1000

Global Const $WBZ_ESCAPE = 1
Global Const $WBZ_LIGHTNING_REFLEXES = 2
Global Const $WBZ_YOU_ARE_ALL_WEAKLINGS = 3
Global Const $WBZ_GRENTHS_AURA = 4
Global Const $WBZ_CRIPPLING_VICTORY = 5
Global Const $WBZ_REAP_IMPURITIES = 6
Global Const $WBZ_MENTAL_BLOCK = 7
Global Const $WBZ_DWARVEN_STABILITY = 8

Global Const $WBZ_SKILLS_ARRAY = [$WBZ_ESCAPE, $WBZ_LIGHTNING_REFLEXES, $WBZ_YOU_ARE_ALL_WEAKLINGS, $WBZ_GRENTHS_AURA, $WBZ_CRIPPLING_VICTORY, $WBZ_REAP_IMPURITIES, $WBZ_MENTAL_BLOCK, $WBZ_DWARVEN_STABILITY]
Global Const $WBZ_SKILLS_COSTS_ARRAY = [5, 10, 5, 10, 6, 5, 10, 5]
Global Const $WBZ_SKILL_COSTS_MAP = MapFromArrays($WBZ_SKILLS_ARRAY, $WBZ_SKILLS_COSTS_ARRAY)
Global Const $WBZ_CHAIN_MIN_ADREN5 = 6
Global Const $WBZ_CHAIN_MIN_ADREN6 = 5
Global Const $WBZ_KILL_TIMEOUT = 120000

Global $wajjun_bazar_run_setup = False
Global $wajjun_bazar_active_stance = $WBZ_ESCAPE


Func WajjunBazarRun()
	If Not $wajjun_bazar_run_setup And SetupWajjunBazarRun() == $FAIL Then Return $PAUSE
	If GetMapID() <> $ID_WAJJUN_BAZAAR And GoToWajjunBazarFromMarketPlace() == $FAIL Then Return $FAIL

	Local $result = WajjunBazarRunLoop()
	If $result == $SUCCESS Then ResignAndReturnToOutpost($ID_THE_MARKETPLACE)
	Return $result
EndFunc


Func SetupWajjunBazarRun()
	Info('Setting up Wajjun Bazar run')
	If TravelToOutpost($ID_THE_MARKETPLACE, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_HARD_MODE)

	If SetupPlayerWajjunBazarRun() == $FAIL Then Return $FAIL
	LeaveParty()

	If GoToWajjunBazarFromMarketPlace() == $FAIL Then Return $FAIL
	$wajjun_bazar_run_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerWajjunBazarRun()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_RANGER Then
		Warn('Should run this farm as ranger')
		Return $FAIL
	EndIf

	LoadSkillTemplate($WAJJUN_BAZAR_SKILLBAR)
	RandomSleep(250)
	ChangeWeaponSet(3)
	RandomSleep(120)
	Return $SUCCESS
EndFunc


Func GoToWajjunBazarFromMarketPlace()
	TravelToOutpost($ID_THE_MARKETPLACE, $district_name)
	While GetMapID() <> $ID_WAJJUN_BAZAAR
		Info('Moving to Wajjun Bazar')
		MoveTo(13359, 16665)
		MoveTo(12895, 16466)
		MoveTo(12303, 16005)
		MoveTo(11839, 15560)
		MoveTo(11575, 15328)
		Move(11350, 15100)
		RandomSleep(1000)
		If WaitMapLoading($ID_WAJJUN_BAZAAR, 10000, 2000) Then ExitLoop
		TravelToOutpost($ID_THE_MARKETPLACE, $district_name)
	WEnd
	Return GetMapID() == $ID_WAJJUN_BAZAAR ? $SUCCESS : $FAIL
EndFunc


Func WajjunBazarRunLoop()
	If GetMapID() <> $ID_WAJJUN_BAZAAR Then Return $FAIL

	WajjunBazarCastOutsidePrep()
	If WajjunBazarLureToQuayEdge() == $FAIL Then Return $FAIL
	If WajjunBazarKillChoreography() == $FAIL Then Return $FAIL

	PickUpItems()
	Return $SUCCESS
EndFunc


Func WajjunBazarCastOutsidePrep()
	If IsRecharged($WBZ_DWARVEN_STABILITY) And GetEffectTimeRemaining(GetEffect($ID_DWARVEN_STABILITY)) == 0 And GetEnergy() >= $WBZ_SKILL_COSTS_MAP[$WBZ_DWARVEN_STABILITY] Then UseSkillEx($WBZ_DWARVEN_STABILITY)
	RandomSleep(80)
	If IsRecharged($WBZ_MENTAL_BLOCK) And GetEffectTimeRemaining(GetEffect($ID_MENTAL_BLOCK)) == 0 And GetEnergy() >= $WBZ_SKILL_COSTS_MAP[$WBZ_MENTAL_BLOCK] Then UseSkillEx($WBZ_MENTAL_BLOCK)
	RandomSleep(80)
	If IsRecharged($WBZ_ESCAPE) And GetEffectTimeRemaining(GetEffect($ID_ESCAPE)) == 0 And GetEnergy() >= $WBZ_SKILL_COSTS_MAP[$WBZ_ESCAPE] Then
		UseSkillEx($WBZ_ESCAPE)
		$wajjun_bazar_active_stance = $WBZ_ESCAPE
	EndIf
	RandomSleep(80)
EndFunc


Func WajjunBazarLureToQuayEdge()
	Local $waypoints[][2] = [[11042, 14763], [10359, 14269], [8532, 14243], [7331, 14461], [6074, 14491], [6411, 15012], [6956, 15410], [7001, 15437]]
	For $i = 0 To UBound($waypoints) - 1
		WajjunBazarMaintainAlternatingStances()
		MoveTo($waypoints[$i][0], $waypoints[$i][1])
		If IsPlayerDead() Then Return $FAIL
	Next
	Return $SUCCESS
EndFunc


Func WajjunBazarMaintainAlternatingStances()
	Local $escapeRemaining = GetEffectTimeRemaining(GetEffect($ID_ESCAPE))
	Local $lightningRemaining = GetEffectTimeRemaining(GetEffect($ID_LIGHTNING_REFLEXES))

	If $wajjun_bazar_active_stance == $WBZ_ESCAPE Then
		If $escapeRemaining > 0 Then Return
		If IsRecharged($WBZ_LIGHTNING_REFLEXES) And GetEnergy() >= $WBZ_SKILL_COSTS_MAP[$WBZ_LIGHTNING_REFLEXES] Then
			UseSkillEx($WBZ_LIGHTNING_REFLEXES)
			$wajjun_bazar_active_stance = $WBZ_LIGHTNING_REFLEXES
		EndIf
	Else
		If $lightningRemaining > 0 Then Return
		If IsRecharged($WBZ_ESCAPE) And GetEnergy() >= $WBZ_SKILL_COSTS_MAP[$WBZ_ESCAPE] Then
			UseSkillEx($WBZ_ESCAPE)
			$wajjun_bazar_active_stance = $WBZ_ESCAPE
		EndIf
	EndIf
EndFunc


Func WajjunBazarMaintainUpkeep($target = Null)
	If IsRecharged($WBZ_DWARVEN_STABILITY) And GetEffectTimeRemaining(GetEffect($ID_DWARVEN_STABILITY)) == 0 And GetEnergy() >= $WBZ_SKILL_COSTS_MAP[$WBZ_DWARVEN_STABILITY] Then UseSkillEx($WBZ_DWARVEN_STABILITY)
	If IsRecharged($WBZ_MENTAL_BLOCK) And GetEffectTimeRemaining(GetEffect($ID_MENTAL_BLOCK)) == 0 And GetEnergy() >= $WBZ_SKILL_COSTS_MAP[$WBZ_MENTAL_BLOCK] Then UseSkillEx($WBZ_MENTAL_BLOCK)
	If IsRecharged($WBZ_GRENTHS_AURA) And GetEnergy() >= $WBZ_SKILL_COSTS_MAP[$WBZ_GRENTHS_AURA] Then UseSkillEx($WBZ_GRENTHS_AURA)
	If $target <> Null And IsRecharged($WBZ_YOU_ARE_ALL_WEAKLINGS) And GetEnergy() >= $WBZ_SKILL_COSTS_MAP[$WBZ_YOU_ARE_ALL_WEAKLINGS] Then UseSkillEx($WBZ_YOU_ARE_ALL_WEAKLINGS, $target)
EndFunc


Func WajjunBazarHasAdrenaline($skillSlot, $requiredStrikes)
	Return GetSkillbarSkillAdrenaline($skillSlot) >= $requiredStrikes
EndFunc


Func WajjunBazarKillChoreography()
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)

	While IsPlayerAlive() And $foesCount > 0 And TimerDiff($deadlock) < $WBZ_KILL_TIMEOUT
		Local $me = GetMyAgent()
		Local $nearestFoe = GetNearestEnemyToAgent($me)
		If $nearestFoe <> Null Then
			WajjunBazarMaintainUpkeep($nearestFoe)
			ChangeTarget($nearestFoe)
			Attack($nearestFoe)
			WajjunBazarMaintainAlternatingStances()

			If IsRecharged($WBZ_CRIPPLING_VICTORY) And WajjunBazarHasAdrenaline($WBZ_CRIPPLING_VICTORY, $WBZ_CHAIN_MIN_ADREN5) Then
				UseSkillEx($WBZ_CRIPPLING_VICTORY, $nearestFoe)
				RandomSleep(60)
				If IsRecharged($WBZ_REAP_IMPURITIES) And WajjunBazarHasAdrenaline($WBZ_REAP_IMPURITIES, $WBZ_CHAIN_MIN_ADREN6) Then UseSkillEx($WBZ_REAP_IMPURITIES, $nearestFoe)
			EndIf
		EndIf

		RandomSleep(200)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
	WEnd

	If IsPlayerDead() Then Return $FAIL
	Return CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) == 0 ? $SUCCESS : $FAIL
EndFunc
