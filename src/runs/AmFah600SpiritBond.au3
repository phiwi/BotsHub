#include-once

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

Global Const $AMFAH600_SB_SKILLBAR = 'Owgk4gPKkEyU9gWEuoFTMJ+g+g8A'
Global Const $AMFAH600_SB_FARM_INFORMATIONS = 'Mo/Rt Spirit Bond Am Fah q8 from Nahpui Quarter to Wajjun Bazaar'
Global Const $AMFAH600_SB_FARM_DURATION = 6 * 60 * 1000

Global Const $AMFAH600_PROTECTIVE_SPIRIT = 1
Global Const $AMFAH600_SPIRIT_BOND = 2
Global Const $AMFAH600_EBON_WISDOM = 3
Global Const $AMFAH600_VWK = 4
Global Const $AMFAH600_FINISH_HIM = 5
Global Const $AMFAH600_RETRIBUTION = 6
Global Const $AMFAH600_ESSENCE_BOND = 7
Global Const $AMFAH600_BALTHAZARS_SPIRIT = 8

Global Const $AMFAH600_SKILLS_ARRAY = [$AMFAH600_PROTECTIVE_SPIRIT, $AMFAH600_SPIRIT_BOND, $AMFAH600_EBON_WISDOM, $AMFAH600_VWK, $AMFAH600_FINISH_HIM, $AMFAH600_RETRIBUTION, $AMFAH600_ESSENCE_BOND, $AMFAH600_BALTHAZARS_SPIRIT]
Global Const $AMFAH600_SKILLS_COSTS_ARRAY = [10, 10, 10, 5, 10, 1, 1, 1]
Global Const $AMFAH600_SKILL_COSTS_MAP = MapFromArrays($AMFAH600_SKILLS_ARRAY, $AMFAH600_SKILLS_COSTS_ARRAY)

Global Const $AMFAH600_MORGAHN_TEMPLATE = 'OQijEymM6M84dsJ+GTvrx+4hNA'
Global Const $AMFAH600_MORGAHN_FLAG_X = 10121
Global Const $AMFAH600_MORGAHN_FLAG_Y = -11890
Global Const $AMFAH600_PRECAST_RECAST_EARLY_MS = 1000

Global Const $AMFAH600_TOSAI_X = 15790
Global Const $AMFAH600_TOSAI_Y = -14951
Global Const $AMFAH600_HEALER_MODEL_ID = 4258

Global Const $AMFAH600_TOSAI_APPROACH_TIMEOUT_MS = 90000
Global Const $AMFAH600_FIRST_PULL_TIMEOUT_MS = 120000
Global Const $AMFAH600_RAMP_PULL_TIMEOUT_MS = 150000
Global Const $AMFAH600_ENERGY_WAIT_TIMEOUT_MS = 90000
Global Const $AMFAH600_MORGAHN_SEND_VERIFY_MS = 9000
Global Const $AMFAH600_DIALOG_ACCEPT_REFUSE_TO_DRINK = 0x814F01
Global Const $AMFAH600_DIALOG_PROGRESS_REFUSE_TO_DRINK = 0x814F05

Global $amfah600_sb_setup_done = False
Global $amfah600_sb_maintained_precast_done = False
Global $amfah600_sb_precast7_done = False
Global $amfah600_sb_precast8_done = False
Global $amfah600_sb_morgahn_flagged_this_cycle = False


Func AmFah600SpiritBondRun()
	If Not $amfah600_sb_setup_done And SetupAmFah600SpiritBondRun() == $FAIL Then Return $PAUSE
	If GetMapID() <> $ID_WAJJUN_BAZAAR Then
		Switch GetMapID()
			Case $ID_NAHPUI_QUARTER
				If GoToWajjunBazarFromNahpuiQuarter() == $FAIL Then Return $FAIL
			Case $ID_THE_UNDERCITY
				If GoToWajjunBazarFromUndercity() == $FAIL Then Return $FAIL
			Case Else
				; Unknown start map for this run: reset to canonical outpost route.
				If TravelToOutpost($ID_NAHPUI_QUARTER, $district_name) == $FAIL Then Return $FAIL
				If GoToWajjunBazarFromNahpuiQuarter() == $FAIL Then Return $FAIL
		EndSwitch
	EndIf

	Local $result = AmFah600SpiritBondRunLoop()
	If IsPlayerDead() Then
		Warn('Am Fah 600 SB debug mode: player dead, pausing at rez shrine for recording')
		Return $PAUSE
	EndIf
	Return $result
EndFunc


Func SetupAmFah600SpiritBondRun()
	Info('Setting up Am Fah 600 Spirit Bond run')
	Local $mapID = GetMapID()
	If $mapID <> $ID_NAHPUI_QUARTER And $mapID <> $ID_WAJJUN_BAZAAR And $mapID <> $ID_THE_UNDERCITY Then
		If TravelToOutpost($ID_NAHPUI_QUARTER, $district_name) == $FAIL Then Return $FAIL
	ElseIf $mapID == $ID_THE_UNDERCITY Then
		Info('Am Fah setup: starting from Undercity, keeping current location')
	EndIf
	SwitchMode($ID_HARD_MODE)

	If SetupPlayerAmFah600SpiritBondRun() == $FAIL Then Return $FAIL
	If GetMapType() == $ID_OUTPOST Then
		If SetupTeamAmFah600SpiritBondRun() == $FAIL Then Return $FAIL
	Else
		Info('Am Fah setup: skipping team setup outside outpost (using current party state)')
	EndIf

	If GetMapID() <> $ID_WAJJUN_BAZAAR Then
		Switch GetMapID()
			Case $ID_NAHPUI_QUARTER
				If GoToWajjunBazarFromNahpuiQuarter() == $FAIL Then Return $FAIL
			Case $ID_THE_UNDERCITY
				If GoToWajjunBazarFromUndercity() == $FAIL Then Return $FAIL
			Case Else
				If GoToWajjunBazarFromNahpuiQuarter() == $FAIL Then Return $FAIL
		EndSwitch
	EndIf

	$amfah600_sb_setup_done = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerAmFah600SpiritBondRun()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_MONK Then
		Warn('Should run this farm as monk primary')
		Return $FAIL
	EndIf

	; Debug: skip player build load to reduce setup time.
	; LoadSkillTemplate($AMFAH600_SB_SKILLBAR)
	RandomSleep(250)
	ChangeWeaponSet(1)
	RandomSleep(120)
	$amfah600_sb_maintained_precast_done = False
	$amfah600_sb_precast7_done = False
	$amfah600_sb_precast8_done = False
	Return $SUCCESS
EndFunc


Func SetupTeamAmFah600SpiritBondRun()
	If IsTeamAutoSetup() Then Return $SUCCESS

	If AmFah600SpiritBondEnsureSoloParty() == $FAIL Then Return $FAIL
	If AddRequiredHero($ID_GENERAL_MORGAHN) == $FAIL Then
		Warn('Could not add General Morgahn for approach speed support')
		Return $FAIL
	EndIf
	; Debug: skip hero build load to reduce setup time.
	; LoadSkillTemplate($AMFAH600_MORGAHN_TEMPLATE, 1)
	RandomSleep(150)
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondEnsureSoloParty($maxWaitMs = 9000)
	Local $timer = TimerInit()
	KickAllHeroes()
	LeaveParty(False)
	While TimerDiff($timer) < $maxWaitMs
		If GetPartySize() <= 1 And GetHeroCount() == 0 Then Return $SUCCESS
		KickAllHeroes()
		LeaveParty(False)
		RandomSleep(320)
	WEnd
	Warn('Am Fah 600 SB: party reset timeout. Party=' & GetPartySize() & ', heroes=' & GetHeroCount())
	Return $FAIL
EndFunc


Func GoToWajjunBazarFromNahpuiQuarter()
	TravelToOutpost($ID_NAHPUI_QUARTER, $district_name)
	While GetMapID() <> $ID_WAJJUN_BAZAAR
		Info('Moving to Wajjun Bazaar from Nahpui Quarter')
		MoveTo(-22000, 12500)
		Move(-21750, 14500)
		RandomSleep(1000)
		If WaitMapLoading($ID_WAJJUN_BAZAAR, 10000, 2000) Then ExitLoop
		TravelToOutpost($ID_NAHPUI_QUARTER, $district_name)
	WEnd
	Return GetMapID() == $ID_WAJJUN_BAZAAR ? $SUCCESS : $FAIL
EndFunc


Func GoToWajjunBazarFromUndercity()
	Info('Moving to Wajjun Bazaar from The Undercity')
	Local $mapLoaded = False
	For $i = 1 To 4
		MoveTo(-16309, -6894)
		Move(-16580, -6900)
		RandomSleep(1000)
		$mapLoaded = WaitMapLoading($ID_WAJJUN_BAZAAR, 8000, 1500)
		If $mapLoaded Then ExitLoop
	Next
	Return GetMapID() == $ID_WAJJUN_BAZAAR ? $SUCCESS : $FAIL
EndFunc


Func AmFah600SpiritBondRunLoop()
	If GetMapID() <> $ID_WAJJUN_BAZAAR Then Return $FAIL
	While IsPlayerAlive()
		If GetMapID() <> $ID_WAJJUN_BAZAAR Then Return $FAIL
		$amfah600_sb_morgahn_flagged_this_cycle = False
		If AmFah600SpiritBondCastMaintainedPrebuffs() == $FAIL Then Return $FAIL
		If AmFah600SpiritBondGoToBrotherTosai() == $FAIL Then Return $FAIL
		AmFah600SpiritBondSendMorgahnToDesert()
		If AmFah600SpiritBondPrepareBeforeQuestTrigger() == $FAIL Then Return $FAIL
		If AmFah600SpiritBondActivateQuest() == $FAIL Then Return $FAIL
		If AmFah600SpiritBondPullInitialHealer() == $FAIL Then Return $FAIL

		; Requested loop: win first fight, then rezone and repeat until death.
		If AmFah600SpiritBondFightFirstTwoGroups() == $FAIL Then Return $FAIL
		If AmFah600SpiritBondRezoneViaUndercity() == $FAIL Then Return $FAIL
	WEnd
	Return $FAIL
EndFunc


Func AmFah600SpiritBondCastMaintainedPrebuffs()
	If IsPlayerDead() Then Return $FAIL
	AmFah600SpiritBondSyncPrebuffState()
	If $amfah600_sb_maintained_precast_done Then Return $SUCCESS

	If GetEffectTimeRemaining(GetEffect($ID_RETRIBUTION)) == 0 Then
		If AmFah600SpiritBondCastSkillChecked($AMFAH600_RETRIBUTION) == $FAIL Then Return $FAIL
	EndIf

	AmFah600SpiritBondSyncPrebuffState()
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondGoToBrotherTosai()
	Local $waypointsNahpui[][2] = [[9032, -19395], [7606, -18046], [5777, -17714], [4299, -17071], [2942, -16271], [2673, -15746], [2818, -14502], [4041, -14150], [6489, -14511], [8938, -14764], [10087, -12923], [11230, -12575], [12378, -11805], [14019, -11786], [14966, -12071], [15388, -13325], [15790, -14951]]
	; Recorded route from Undercity-side Wajjun spawn to Tosai.
	Local $waypointsUndercity[][2] = [[16510, -9978], [16003, -9806], [15366, -9579], [15016, -9361], [14922, -9667], [14750, -10262], [14555, -11019], [14070, -11765], [14644, -11884], [14983, -12371], [15213, -12930], [15480, -13655], [15667, -14321], [15797, -14954]]

	Local $me = GetMyAgent()
	Local $fromUndercitySide = GetDistanceToPoint($me, 16510, -9978) < 2200
	Local $waypoints = $fromUndercitySide ? $waypointsUndercity : $waypointsNahpui
	Info('Approach Tosai from ' & ($fromUndercitySide ? 'Undercity-side spawn' : 'Nahpui-side spawn'))
	If $fromUndercitySide Then
		AmFah600SpiritBondFlagMorgahnAtRecordedSpotVerified('spawn-pass', 5000)
	ElseIf GetDistanceToPoint($me, $AMFAH600_MORGAHN_FLAG_X, $AMFAH600_MORGAHN_FLAG_Y) < 1600 Then
		AmFah600SpiritBondTryFlagMorgahnAtRecordedSpot('spawn-pass')
	EndIf

	Local $timer = TimerInit()
	For $i = 0 To UBound($waypoints) - 1
		If TimerDiff($timer) > $AMFAH600_TOSAI_APPROACH_TIMEOUT_MS Then Return $FAIL
		If IsPlayerDead() Then Return $FAIL
		AmFah600SpiritBondTryMovementPrebuffCast()
		MoveTo($waypoints[$i][0], $waypoints[$i][1])
		AmFah600SpiritBondTryMovementPrebuffCast()
		RandomSleep(120)
	Next

	Local $precastTimer = TimerInit()
	While IsPlayerAlive() And TimerDiff($precastTimer) < $AMFAH600_ENERGY_WAIT_TIMEOUT_MS
		If AmFah600SpiritBondAllPrebuffsActive() Then ExitLoop
		AmFah600SpiritBondTryMovementPrebuffCast()
		RandomSleep(120)
	WEnd
	If Not AmFah600SpiritBondAllPrebuffsActive() Then
		Warn('Could not finish movement prebuffs (6/7/8) before Tosai')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondTryMovementPrebuffCast()
	Local $me = GetMyAgent()
	Local $maxEnergy = DllStructGetData($me, 'MaxEnergy')
	If GetEnergy($me) < ($maxEnergy - 0.2) Then Return

	AmFah600SpiritBondSyncPrebuffState()

	If GetEffectTimeRemaining(GetEffect($ID_RETRIBUTION)) == 0 Then
		If IsRecharged($AMFAH600_RETRIBUTION) And GetEnergy() >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_RETRIBUTION] Then
			Info('Movement prebuff: cast 6 (Retribution)')
			UseSkillEx($AMFAH600_RETRIBUTION)
			RandomSleep(90)
			AmFah600SpiritBondSyncPrebuffState()
			Return
		EndIf
	EndIf

	If Not $amfah600_sb_precast7_done Then
		If IsRecharged($AMFAH600_ESSENCE_BOND) And GetEnergy() >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_ESSENCE_BOND] Then
			Info('Movement prebuff: cast 7 (Essence Bond)')
			UseSkillEx($AMFAH600_ESSENCE_BOND)
			$amfah600_sb_precast7_done = True
			RandomSleep(90)
			AmFah600SpiritBondSyncPrebuffState()
		EndIf
		Return
	EndIf

	If Not $amfah600_sb_precast8_done Then
		If IsRecharged($AMFAH600_BALTHAZARS_SPIRIT) And GetEnergy() >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_BALTHAZARS_SPIRIT] Then
			Info('Movement prebuff: cast 8 (Balthazar''s Spirit)')
			UseSkillEx($AMFAH600_BALTHAZARS_SPIRIT)
			$amfah600_sb_precast8_done = True
			RandomSleep(90)
			AmFah600SpiritBondSyncPrebuffState()
		EndIf
	EndIf
EndFunc


Func AmFah600SpiritBondAllPrebuffsActive()
	Return GetEffectTimeRemaining(GetEffect($ID_RETRIBUTION)) > 0 _
		And GetEffectTimeRemaining(GetEffect($ID_ESSENCE_BOND)) > 0 _
		And GetEffectTimeRemaining(GetEffect($ID_BALTHAZARS_SPIRIT)) > 0
EndFunc


Func AmFah600SpiritBondSyncPrebuffState()
	$amfah600_sb_precast7_done = GetEffectTimeRemaining(GetEffect($ID_ESSENCE_BOND)) > 0
	$amfah600_sb_precast8_done = GetEffectTimeRemaining(GetEffect($ID_BALTHAZARS_SPIRIT)) > 0
	$amfah600_sb_maintained_precast_done = AmFah600SpiritBondAllPrebuffsActive()
EndFunc


Func AmFah600SpiritBondPrepareBeforeQuestTrigger()
	If AmFah600SpiritBondCastSkillChecked($AMFAH600_PROTECTIVE_SPIRIT) == $FAIL Then Return $FAIL
	RandomSleep(70)
	If AmFah600SpiritBondCastSkillChecked($AMFAH600_SPIRIT_BOND) == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondActivateQuest()
	Info('Starting Refuse to Drink at Brother Tosai')
	If IsQuestActive($ID_QUEST_REFUSE_TO_DRINK) Then
		Info('Refuse to Drink already active')
		Return $SUCCESS
	EndIf

	Local $questNPC = GetNearestNPCToCoords($AMFAH600_TOSAI_X, $AMFAH600_TOSAI_Y)
	If $questNPC == Null Then
		Warn('Quest trigger failed: Brother Tosai not found near expected coords')
		Return $FAIL
	EndIf

	Info('Quest state before trigger: refuse(active=' & IsQuestActive($ID_QUEST_REFUSE_TO_DRINK) & ', reward=' & IsQuestReward($ID_QUEST_REFUSE_TO_DRINK) & ', notfound=' & IsQuestNotFound($ID_QUEST_REFUSE_TO_DRINK) & '), drink(active=' & IsQuestActive($ID_QUEST_DRINK_FROM_THE_CHALICE_OF_CORRUPTION) & ', notfound=' & IsQuestNotFound($ID_QUEST_DRINK_FROM_THE_CHALICE_OF_CORRUPTION) & '), seek(active=' & IsQuestActive($ID_QUEST_SEEK_OUT_BROTHER_TOSAI) & ', notfound=' & IsQuestNotFound($ID_QUEST_SEEK_OUT_BROTHER_TOSAI) & ')')
	; Proven path: accept + immediate soft-button progression.
	For $i = 1 To 2
		GoToNPC($questNPC)
		RandomSleep(300 + GetPing())
		Dialog(0x84)
		RandomSleep(220 + GetPing())
		Dialog($AMFAH600_DIALOG_ACCEPT_REFUSE_TO_DRINK)
		RandomSleep(220 + GetPing())
		AcceptQuest($ID_QUEST_REFUSE_TO_DRINK)
		RandomSleep(220 + GetPing())
		Dialog($AMFAH600_DIALOG_PROGRESS_REFUSE_TO_DRINK)
		RandomSleep(450 + GetPing())
		If IsQuestActive($ID_QUEST_REFUSE_TO_DRINK) Then
			Info('Refuse to Drink is active (fast opener)')
			AmFah600SpiritBondMaintainCoreUpkeep()
			Return $SUCCESS
		EndIf
	Next

	; Some runs become hostile even when quest flag reads late/incorrectly.
	Warn('Quest flag did not activate after fast opener; continuing to combat pull')
	AmFah600SpiritBondMaintainCoreUpkeep()
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondPullInitialHealer()
	Info('Skipping healer pull: hold position and start choreography')
	AmFah600SpiritBondMaintainCoreUpkeep()
	Local $healer = AmFah600SpiritBondGetNearestHealerInRange($RANGE_COMPASS)
	If $healer <> Null Then
		Info('Initial healer in compass: model=' & DllStructGetData($healer, 'PlayerNumber') & ', dist=' & Round(GetDistance(GetMyAgent(), $healer)))
		ChangeTarget($healer)
	Else
		Info('No Am Fah Healer in compass yet; waiting in place for aggro')
	EndIf
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondFightFirstTwoGroups()
	Info('Fighting first two Am Fah groups')
	Return AmFah600SpiritBondFightWindow('First two groups', $AMFAH600_FIRST_PULL_TIMEOUT_MS)
EndFunc


Func AmFah600SpiritBondFightRampThreeGroups()
	Info('Fighting ramp-side three groups')
	Return AmFah600SpiritBondFightWindow('Ramp three groups', $AMFAH600_RAMP_PULL_TIMEOUT_MS)
EndFunc


Func AmFah600SpiritBondFightWindow($label, $timeoutMs)
	Local $timer = TimerInit()
	Local $me = GetMyAgent()
	Local $anchorX = DllStructGetData($me, 'X')
	Local $anchorY = DllStructGetData($me, 'Y')
	Move($anchorX, $anchorY)
	While IsPlayerAlive() And TimerDiff($timer) < $timeoutMs
		; Keep 1/2 as tight as possible before doing any target or finisher logic.
		AmFah600SpiritBondMaintainCoreUpkeep()

		$me = GetMyAgent()
		Local $foes = CountFoesInRangeOfAgent($me, $RANGE_EARSHOT)
		If $label == 'First two groups' Then
			If AmFah600SpiritBondShouldEndFirstFight() Then
				Info('First-fight stop condition met (only necromancers or only monks remain)')
				Return $SUCCESS
			EndIf
		Else
			If $foes == 0 And TimerDiff($timer) > 5000 Then Return $SUCCESS
		EndIf
		AmFah600SpiritBondHoldPosition($anchorX, $anchorY)

		Local $target = AmFah600SpiritBondGetNearestHealerInRange($RANGE_EARSHOT)
		If $target == Null Then $target = GetNearestEnemyToAgent($me, $RANGE_EARSHOT)
		If $target <> Null Then ChangeTarget($target)

		; Prioritize finisher on low-HP healer before optional 3/4 upkeep.
		If AmFah600SpiritBondTryFinishHimOnLowHealerHp($target) Then
			RandomSleep(60)
			ContinueLoop
		EndIf

		RandomSleep(25)
	WEnd

	Warn('Am Fah 600 SB timeout in phase: ' & $label)
	Return $FAIL
EndFunc


Func AmFah600SpiritBondShouldEndFirstFight()
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS)
	Local $livingFoes = 0
	Local $necroCount = 0
	Local $monkCount = 0
	Local $hasOther = False

	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If GetIsDead($foe) Then ContinueLoop
		$livingFoes += 1
		Local $primary = DllStructGetData($foe, 'Primary')
		If $primary == $ID_NECROMANCER Then
			$necroCount += 1
		ElseIf $primary == $ID_MONK Then
			$monkCount += 1
		Else
			$hasOther = True
		EndIf
	Next

	If $livingFoes == 0 Then Return True
	If $hasOther Then Return False
	If $necroCount > 0 And $monkCount == 0 And $necroCount <= 2 Then Return True
	If $monkCount > 0 And $necroCount == 0 And $monkCount <= 2 Then Return True
	Return False
EndFunc


Func AmFah600SpiritBondMaintainCoreUpkeep()
	If IsPlayerDead() Then Return
	Local $energy = GetEnergy()

	; Priority #1: keep Spirit Bond (2) up preemptively (<=1s) for tighter protection.
	If GetEffectTimeRemaining(GetEffect($ID_SPIRIT_BOND)) <= $AMFAH600_PRECAST_RECAST_EARLY_MS Then
		If IsRecharged($AMFAH600_SPIRIT_BOND) And $energy >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_SPIRIT_BOND] Then
			UseSkillEx($AMFAH600_SPIRIT_BOND)
			RandomSleep(25)
			Return
		EndIf
	EndIf

	; Priority #2: keep Protective Spirit (1) up preemptively (<=1s).
	If GetEffectTimeRemaining(GetEffect($ID_PROTECTIVE_SPIRIT)) <= $AMFAH600_PRECAST_RECAST_EARLY_MS And IsRecharged($AMFAH600_PROTECTIVE_SPIRIT) And $energy >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_PROTECTIVE_SPIRIT] Then
		UseSkillEx($AMFAH600_PROTECTIVE_SPIRIT)
		RandomSleep(25)
		Return
	EndIf

	; Priority #3 then #4: 3 -> 4 (3 only when energy > 20).
	If GetEffectTimeRemaining(GetEffect($ID_EBON_BATTLE_STANDARD_OF_WISDOM)) == 0 _
		And IsRecharged($AMFAH600_EBON_WISDOM) _
		And $energy > 25 _
		And $energy >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_EBON_WISDOM] Then
		UseSkillEx($AMFAH600_EBON_WISDOM)
		RandomSleep(25)
		$energy = GetEnergy()
	EndIf

	If GetEffectTimeRemaining(GetEffect($ID_VENGEFUL_WAS_KHANHEI)) == 0 _
		And IsRecharged($AMFAH600_VWK) _
		And $energy >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_VWK] Then
		UseSkillEx($AMFAH600_VWK)
		RandomSleep(25)
	EndIf
EndFunc


Func AmFah600SpiritBondTryFinishHimOnLowHealerHp($target = Null)
	If Not IsRecharged($AMFAH600_FINISH_HIM) Then Return False
	If GetEnergy() < $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_FINISH_HIM] Then Return False

	Local $healer = $target
	If $healer == Null Or Not AmFah600SpiritBondIsHealerAgent($healer) Then $healer = AmFah600SpiritBondGetNearestHealerInRange($RANGE_EARSHOT)
	If $healer == Null Then Return False

	Local $healerHp = DllStructGetData($healer, 'HP')
	If $healerHp > 0.40 Then
		; In the small endgame, keep pressuring healers with 5 until they drop.
		If Not AmFah600SpiritBondShouldForceFinishHimOnHealers() Then Return False
	EndIf

	UseSkillEx($AMFAH600_FINISH_HIM, $healer)
	Return True
EndFunc


Func AmFah600SpiritBondShouldForceFinishHimOnHealers()
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
	Local $living = 0
	Local $healers = 0

	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If GetIsDead($foe) Then ContinueLoop
		$living += 1
		If AmFah600SpiritBondIsHealerAgent($foe) Then $healers += 1
	Next

	If $living <= 3 And $healers > 0 Then Return True
	Return False
EndFunc


Func AmFah600SpiritBondHoldPosition($anchorX, $anchorY, $maxDrift = 140)
	Local $me = GetMyAgent()
	If GetDistanceToPoint($me, $anchorX, $anchorY) <= $maxDrift Then Return
	Move($anchorX, $anchorY)
	RandomSleep(30)
EndFunc


Func AmFah600SpiritBondSendMorgahnToDesert()
	If $amfah600_sb_morgahn_flagged_this_cycle Then
		Info('Morgahn already flagged at recorded spot during approach')
		Return
	EndIf
	If Not AmFah600SpiritBondFlagMorgahnAtRecordedSpotVerified('pre-tosai', $AMFAH600_MORGAHN_SEND_VERIFY_MS) Then _
		Warn('Morgahn flag not verified in time; continuing anyway')
EndFunc


Func AmFah600SpiritBondTryFlagMorgahnAtRecordedSpot($reason = 'approach')
	Local $slot = GetHeroNumberByHeroID($ID_GENERAL_MORGAHN)
	If $slot == Null Then Return

	Info('Flagging Morgahn at recorded spot (' & $reason & '): x=' & $AMFAH600_MORGAHN_FLAG_X & ', y=' & $AMFAH600_MORGAHN_FLAG_Y)
	CommandHero($slot, $AMFAH600_MORGAHN_FLAG_X, $AMFAH600_MORGAHN_FLAG_Y)
	RandomSleep(120)

	Local $heroAgent = GetAgentByID(GetHeroID($slot))
	If $heroAgent == Null Then Return
	Local $dist = GetDistanceToPoint($heroAgent, $AMFAH600_MORGAHN_FLAG_X, $AMFAH600_MORGAHN_FLAG_Y)
	If $dist < 320 Then
		$amfah600_sb_morgahn_flagged_this_cycle = True
		Info('Morgahn flag quick-verified at recorded spot: dist=' & Round($dist))
	EndIf
EndFunc


Func AmFah600SpiritBondFlagMorgahnAtRecordedSpotVerified($reason = 'approach', $maxWaitMs = 4500)
	Local $slot = GetHeroNumberByHeroID($ID_GENERAL_MORGAHN)
	If $slot == Null Then
		Warn('Morgahn flag skipped: General Morgahn not present')
		Return False
	EndIf

	Info('Flagging Morgahn at recorded spot (' & $reason & '): x=' & $AMFAH600_MORGAHN_FLAG_X & ', y=' & $AMFAH600_MORGAHN_FLAG_Y)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs
		CommandHero($slot, $AMFAH600_MORGAHN_FLAG_X, $AMFAH600_MORGAHN_FLAG_Y)
		RandomSleep(220)

		Local $heroAgent = GetAgentByID(GetHeroID($slot))
		If $heroAgent == Null Then ContinueLoop
		Local $dist = GetDistanceToPoint($heroAgent, $AMFAH600_MORGAHN_FLAG_X, $AMFAH600_MORGAHN_FLAG_Y)
		If $dist < 260 Then
			$amfah600_sb_morgahn_flagged_this_cycle = True
			Info('Morgahn flag verified at recorded point: x=' & Round(DllStructGetData($heroAgent, 'X')) & ', y=' & Round(DllStructGetData($heroAgent, 'Y')))
			Return True
		EndIf
	WEnd

	Warn('Morgahn flag verify timeout (' & $reason & ')')
	Return False
EndFunc


Func AmFah600SpiritBondCastSkillAndWaitFullEnergy($skillSlot, $label)
	If AmFah600SpiritBondCastSkillChecked($skillSlot) == $FAIL Then
		Warn('Could not cast skill for ' & $label)
		Return $FAIL
	EndIf
	If AmFah600SpiritBondWaitForFullEnergy($label) == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondCastSkillChecked($skillSlot)
	Local $timer = TimerInit()
	While IsPlayerAlive() And TimerDiff($timer) < $AMFAH600_ENERGY_WAIT_TIMEOUT_MS
		If IsRecharged($skillSlot) And GetEnergy() >= $AMFAH600_SKILL_COSTS_MAP[$skillSlot] Then
			UseSkillEx($skillSlot)
			RandomSleep(90)
			Return $SUCCESS
		EndIf
		RandomSleep(80)
	WEnd
	Return $FAIL
EndFunc


Func AmFah600SpiritBondWaitForFullEnergy($label)
	Local $timer = TimerInit()
	While IsPlayerAlive() And TimerDiff($timer) < $AMFAH600_ENERGY_WAIT_TIMEOUT_MS
		Local $me = GetMyAgent()
		Local $maxEnergy = DllStructGetData($me, 'MaxEnergy')
		If GetEnergy($me) >= ($maxEnergy - 0.2) Then Return $SUCCESS
		RandomSleep(120)
	WEnd
	Warn('Energy did not refill to full in time: ' & $label)
	Return $FAIL
EndFunc


Func AmFah600SpiritBondGetNearestHealerInRange($range)
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $range)
	Local $nearest = Null
	Local $nearestDist = 100000000
	Local $healerCount = 0
	Static $noneLogTimer = 0
	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If Not AmFah600SpiritBondIsHealerAgent($foe) Then ContinueLoop
		$healerCount += 1
		Local $dist = GetDistance($me, $foe)
		If $dist < $nearestDist Then
			$nearestDist = $dist
			$nearest = $foe
		EndIf
	Next
	If $healerCount == 0 Then
		If $noneLogTimer == 0 Or TimerDiff($noneLogTimer) > 1500 Then
			Info('Healer scan: none in range=' & $range & ' (foes=' & UBound($foes) & ')')
			$noneLogTimer = TimerInit()
		EndIf
	Else
		$noneLogTimer = 0
		Info('Healer scan: found=' & $healerCount & ', nearestDist=' & Round($nearestDist))
	EndIf
	Return $nearest
EndFunc


Func AmFah600SpiritBondIsHealerAgent($agent)
	If $agent == Null Then Return False
	Return DllStructGetData($agent, 'PlayerNumber') == $AMFAH600_HEALER_MODEL_ID
EndFunc


Func AmFah600SpiritBondRezoneViaUndercity()
	Info('Rezoning loop: Tosai -> Undercity -> Wajjun Bazaar')

	; Reverse of recorded Wajjun -> Tosai segment to return to portal side.
	Local $toPortal[][2] = [[15732, -14770], [15645, -14477], [15485, -13729], [15213, -12930], [14983, -12371], [14765, -11976], [14468, -11228], [14639, -10557], [15016, -9361], [15556, -9894], [16147, -9862], [16510, -9978]]
	For $i = 0 To UBound($toPortal) - 1
		If IsPlayerDead() Then Return $FAIL
		MoveTo($toPortal[$i][0], $toPortal[$i][1])
		RandomSleep(100)
	Next

	Local $mapLoaded = False
	For $i = 1 To 4
		MoveTo(16510, -9978)
		Move(16720, -10010)
		RandomSleep(1000)
		$mapLoaded = WaitMapLoading($ID_THE_UNDERCITY, 8000, 1500)
		If $mapLoaded Then ExitLoop
	Next
	If Not $mapLoaded Then
		Warn('Could not enter The Undercity portal')
		Return $FAIL
	EndIf

	$mapLoaded = False
	For $i = 1 To 4
		MoveTo(-16309, -6894)
		Move(-16580, -6900)
		RandomSleep(1000)
		$mapLoaded = WaitMapLoading($ID_WAJJUN_BAZAAR, 8000, 1500)
		If $mapLoaded Then ExitLoop
	Next
	If Not $mapLoaded Then
		Warn('Could not return to Wajjun Bazaar')
		Return $FAIL
	EndIf

	$amfah600_sb_maintained_precast_done = False
	$amfah600_sb_precast7_done = False
	$amfah600_sb_precast8_done = False
	Return $SUCCESS
EndFunc
