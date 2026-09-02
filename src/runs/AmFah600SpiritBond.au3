#include-once

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

Global Const $AMFAH600_SB_SKILLBAR = 'Owgk4gPKkEyU9gWEuoFzuI+g+g8A'
Global Const $AMFAH600_SB_FARM_INFORMATIONS = 'Mo/Rt Spirit Bond Am Fah q8 from Nahpui Quarter to Wajjun Bazaar'
Global Const $AMFAH600_SB_FARM_DURATION = 6 * 60 * 1000

Global Const $AMFAH600_PROTECTIVE_SPIRIT = 1
Global Const $AMFAH600_SPIRIT_BOND = 2
Global Const $AMFAH600_EBON_WISDOM = 3
Global Const $AMFAH600_VWK = 4
Global Const $AMFAH600_EVAS = 5
Global Const $AMFAH600_RETRIBUTION = 6
Global Const $AMFAH600_ESSENCE_BOND = 7
Global Const $AMFAH600_BALTHAZARS_SPIRIT = 8

Global Const $AMFAH600_SKILLS_ARRAY = [$AMFAH600_PROTECTIVE_SPIRIT, $AMFAH600_SPIRIT_BOND, $AMFAH600_EBON_WISDOM, $AMFAH600_VWK, $AMFAH600_EVAS, $AMFAH600_RETRIBUTION, $AMFAH600_ESSENCE_BOND, $AMFAH600_BALTHAZARS_SPIRIT]
Global Const $AMFAH600_SKILLS_COSTS_ARRAY = [10, 10, 10, 5, 15, 1, 1, 1]
Global Const $AMFAH600_SKILL_COSTS_MAP = MapFromArrays($AMFAH600_SKILLS_ARRAY, $AMFAH600_SKILLS_COSTS_ARRAY)

Global Const $AMFAH600_MORGAHN_TEMPLATE = 'OQijEymM6M84dsJ+GTvrx+4hNA'
Global Const $AMFAH600_MORGAHN_FLAG_X = 12656
Global Const $AMFAH600_MORGAHN_FLAG_Y = -5164
Global Const $AMFAH600_SPOT2_X = 14337
Global Const $AMFAH600_SPOT2_Y = -7157
Global Const $AMFAH600_PRECAST_RECAST_EARLY_MS = 1000

Global Const $AMFAH600_TOSAI_X = 15790
Global Const $AMFAH600_TOSAI_Y = -14951
; Second-group pull target (from 2026-08-18 17:37 recording): after activating
; Refuse to Drink at Tosai, walk TOWARD this point to lure the second Am Fah
; group. In that recording group 2 sat at the same spot as group 1, but it is
; not always the case — this point still triggers it ~95% of the time.
; We do NOT walk all the way in: the Marksmen there knock the 600hp monk down
; and interrupt casts (the last run died at dist=276 to a healer). We stop as
; soon as group 2 is at aggro range, and never closer than the stop radius.
Global Const $AMFAH600_SECOND_GROUP_PULL_X = 15410
Global Const $AMFAH600_SECOND_GROUP_PULL_Y = -13349
; Never walk closer than this to the recorded group-2 spot (~aggro range, so
; the group chases us instead of us standing in the middle of it).
Global Const $AMFAH600_PULL_STOP_RADIUS = 1000
; Stop the pull walk as soon as a group-2 foe ahead of us is within this range.
Global Const $AMFAH600_PULL_AGGRO_STOP_DIST = 1000
; Ignore chasing group-1 members closer than this (they trail right behind us).
Global Const $AMFAH600_PULL_MIN_CANDIDATE_DIST = 500
; EVAS (Ebon Vanguard Assassin) is the only targeted cast during the fight.
; GW's client auto-approaches toward an out-of-range target, so we only target
; Necromancers inside EVAS' real cast range (~1200). This lets the monk hit the
; Necros that hover just outside the aggro bubble (~1000-1200) and still keep
; her standing at the anchor — she never chases far ones across the compass.
Global Const $AMFAH600_EVAS_CAST_RANGE = 1200
Global Const $AMFAH600_HEALER_MODEL_ID = 4258
Global Const $AMFAH600_NECROMANCER_MODEL_ID = 4257

Global Const $AMFAH600_TOSAI_APPROACH_TIMEOUT_MS = 90000
Global Const $AMFAH600_FIRST_PULL_TIMEOUT_MS = 120000
; When only Necromancers remain in the first fight, keep fighting up to this
; long so EVAS assassins can finish them — otherwise a surviving Necro hexes
; the monk to death on the trek to Spot 2.
Global Const $AMFAH600_NECRO_CLEANUP_TIMEOUT_MS = 45000
Global Const $AMFAH600_RAMP_PULL_TIMEOUT_MS = 150000
Global Const $AMFAH600_ENERGY_WAIT_TIMEOUT_MS = 90000
Global Const $AMFAH600_MORGAHN_SEND_VERIFY_MS = 9000
Global Const $AMFAH600_MORGAHN_SPEED_INTERVAL_MS = 10000
Global Const $AMFAH600_DIALOG_ACCEPT_REFUSE_TO_DRINK = 0x814F01
Global Const $AMFAH600_DIALOG_PROGRESS_REFUSE_TO_DRINK = 0x814F05

Global $amfah600_sb_setup_done = False
Global $amfah600_sb_maintained_precast_done = False
Global $amfah600_sb_precast3_done = False
Global $amfah600_sb_precast4_done = False
Global $amfah600_sb_precast7_done = False
Global $amfah600_sb_precast8_done = False
Global $amfah600_sb_morgahn_flagged_this_cycle = False
Global $amfah600_sb_morgahn_last_speed_timer = 0
Global $amfah600_sb_morgahn_last_speed_skill = 0 ; 0=none, 1=Incoming, 2=Fall Back


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

	If HeroHasTemplate(0, $AMFAH600_SB_SKILLBAR) Then
		Info('Am Fah 600 player: template already loaded, skipping')
	Else
		LoadSkillTemplate($AMFAH600_SB_SKILLBAR)
		RandomSleep(250)
	EndIf
	ChangeWeaponSet(1)
	RandomSleep(120)
	$amfah600_sb_maintained_precast_done = False
	$amfah600_sb_precast3_done = False
	$amfah600_sb_precast4_done = False
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
	If HeroHasTemplate(1, $AMFAH600_MORGAHN_TEMPLATE) Then
		Info('Am Fah 600 Morgahn: template already loaded, skipping')
	Else
		LoadSkillTemplate($AMFAH600_MORGAHN_TEMPLATE, 1)
		RandomSleep(150)
	EndIf
	DisableHeroSkillSlot(1, 4) ; Disable Make Haste — only Incoming (1) + Fall Back (2) for speed
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
		$amfah600_sb_morgahn_last_speed_timer = 0
		$amfah600_sb_morgahn_last_speed_skill = 0
		If AmFah600SpiritBondCastMaintainedPrebuffs() == $FAIL Then Return $FAIL
		If AmFah600SpiritBondGoToBrotherTosai() == $FAIL Then Return $FAIL
		AmFah600SpiritBondSendMorgahnToDesert()
		If AmFah600SpiritBondPrepareBeforeQuestTrigger() == $FAIL Then Return $FAIL
		If AmFah600SpiritBondActivateQuest() == $FAIL Then Return $FAIL
		; Walk from Tosai to the recorded pull point to lure the second group
		; into aggro range (maintenance keeps the 600hp build alive on the way).
		If AmFah600SpiritBondPullSecondGroup() == $FAIL Then Return $FAIL

		; Spot 1: Brother Tosai — fight first two groups. FightWindow already
		; returns only when all foes are dead or only Necromancers remain, so
		; there is nothing left to re-engage here (ContinueLoop would re-approach
		; Tosai and kill us).
		If AmFah600SpiritBondFightFirstTwoGroups() == $FAIL Then Return $FAIL
		PickUpItems()
		; Spot 2: Marksman group (Morgahn flag location).
		If AmFah600SpiritBondGoToSpot2() == $FAIL Then Return $FAIL
		If AmFah600SpiritBondFightSpot2() == $FAIL Then Return $FAIL
		PickUpItems()
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
		AmFah600SpiritBondTryMorgahnSpeedBoost()
		; Flag Morgahn to his desert off-spot ~5 waypoints before arrival so he
		; is well clear of the aggro zone by the time we trigger the quest.
		If $i == UBound($waypoints) - 5 Then AmFah600SpiritBondTryFlagMorgahnAtRecordedSpot('pre-arrival')
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
		Return
	EndIf

	If Not $amfah600_sb_precast3_done Then
		If IsRecharged($AMFAH600_EBON_WISDOM) And GetEnergy() >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_EBON_WISDOM] Then
			Info('Movement prebuff: cast 3 (Ebon Wisdom)')
			UseSkillEx($AMFAH600_EBON_WISDOM)
			$amfah600_sb_precast3_done = True
			RandomSleep(90)
			AmFah600SpiritBondSyncPrebuffState()
		EndIf
		Return
	EndIf

	If Not $amfah600_sb_precast4_done Then
		If IsRecharged($AMFAH600_VWK) And GetEnergy() >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_VWK] Then
			Info('Movement prebuff: cast 4 (Vengeful Was Khanhei)')
			UseSkillEx($AMFAH600_VWK)
			$amfah600_sb_precast4_done = True
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
	$amfah600_sb_precast3_done = GetEffectTimeRemaining(GetEffect($ID_EBON_BATTLE_STANDARD_OF_WISDOM)) > 0
	$amfah600_sb_precast4_done = GetEffectTimeRemaining(GetEffect($ID_VENGEFUL_WAS_KHANHEI)) > 0
	$amfah600_sb_precast7_done = GetEffectTimeRemaining(GetEffect($ID_ESSENCE_BOND)) > 0
	$amfah600_sb_precast8_done = GetEffectTimeRemaining(GetEffect($ID_BALTHAZARS_SPIRIT)) > 0
	$amfah600_sb_maintained_precast_done = AmFah600SpiritBondAllPrebuffsActive()
EndFunc


Func AmFah600SpiritBondPrepareBeforeQuestTrigger()
	If AmFah600SpiritBondCastSkillChecked($AMFAH600_PROTECTIVE_SPIRIT) == $FAIL Then Return $FAIL
	RandomSleep(70)
	If AmFah600SpiritBondCastSkillChecked($AMFAH600_SPIRIT_BOND) == $FAIL Then Return $FAIL
	AmFah600SpiritBondCsvLog('PrepareBeforeQuest', 'ps=' & (GetEffect($ID_PROTECTIVE_SPIRIT) <> Null ? 'ok' : 'fail') & ' sb=' & (GetEffect($ID_SPIRIT_BOND) <> Null ? 'ok' : 'fail'))
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondActivateQuest()
	Info('Starting Refuse to Drink at Brother Tosai')
	If IsQuestActive($ID_QUEST_REFUSE_TO_DRINK) Then
		Info('Refuse to Drink already active')
		Return $SUCCESS
	EndIf

	; Abandon any stale quest state from previous failed attempts.
	; Partial activation (Dialog+AcceptQuest may make enemies hostile without
	; the quest registering as 'active') poisons the next run — the approach
	; waypoints don't maintain PS/SB and the player dies during movement.
	If Not IsQuestNotFound($ID_QUEST_REFUSE_TO_DRINK) Then
		Warn('Refuse to Drink quest in non-active state — abandoning to reset')
		AbandonQuest($ID_QUEST_REFUSE_TO_DRINK)
		PingSleep(500)
	EndIf

	; Cast fresh defensive enchants NOW — don't rely on PrepareBeforeQuestTrigger's
	; casts which may have expired during the approach to Tosai.
	AmFah600SpiritBondMaintainCoreUpkeep()

	; Only PS (1) + SB (2) need to be up before the first dialog; EBW (3) and
	; VWK (4) are cast on-combat. This keeps energy full for the fight start.
	Local $prebuffTimer = TimerInit()
	While IsPlayerAlive() And TimerDiff($prebuffTimer) < 5000
		If GetEffect($ID_PROTECTIVE_SPIRIT) <> Null _
			And GetEffect($ID_SPIRIT_BOND) <> Null Then ExitLoop
		AmFah600SpiritBondMaintainCoreUpkeep()
		RandomSleep(80)
	WEnd
	If IsPlayerDead() Then
		AmFah600SpiritBondCsvLog('ActivateQuest', 'dead_during_prebuff')
		Return $FAIL
	EndIf

	Local $timerQuest = TimerInit()
	Local $attempt = 0
	While Not IsQuestActive($ID_QUEST_REFUSE_TO_DRINK)
		If IsPlayerDead() Then
			AmFah600SpiritBondCsvLog('ActivateQuest', 'dead_in_loop')
			Return $FAIL
		EndIf
		If TimerDiff($timerQuest) > 30000 Then
			Warn('Could not activate Refuse to Drink quest after 30s')
			AmFah600SpiritBondCsvLog('ActivateQuest', 'timeout_30s')
			; Abandon to reset enemies that may have become hostile via partial
			; activation — otherwise the next run dies during approach.
			If Not IsQuestNotFound($ID_QUEST_REFUSE_TO_DRINK) Then
				AbandonQuest($ID_QUEST_REFUSE_TO_DRINK)
			EndIf
			Return $FAIL
		EndIf
		$attempt += 1
		AmFah600SpiritBondCsvLog('ActivateQuest_attempt', $attempt)

		; Refresh NPC reference each iteration — GW may recycle agent IDs.
		Local $tosai = GetNearestNPCToCoords($AMFAH600_TOSAI_X, $AMFAH600_TOSAI_Y)
		GoToNPC($tosai)
		PingSleep(500)
		; ⚠️ If the quest became active during the approach (e.g. from a
		; previous attempt that partially succeeded), stop talking to Tosai
		; immediately — re-entering dialogs will delay SB maintenance.
		If IsQuestActive($ID_QUEST_REFUSE_TO_DRINK) Then ExitLoop
		Dialog(0x84)
		PingSleep(500)
		Dialog($AMFAH600_DIALOG_ACCEPT_REFUSE_TO_DRINK)
		PingSleep(250)

		; AcceptQuest turns both Ambush groups HOSTILE immediately.
		; MUST refresh PS+SB+4 NOW — the 1.75 s of dialogs above may have let
		; enchantments tick dangerously low.  Do multiple passes so that if PS
		; is cast first, SB is caught on the next pass.
		AcceptQuest($ID_QUEST_REFUSE_TO_DRINK)
		For $postAccept = 1 To 10
			AmFah600SpiritBondMaintainCoreUpkeep()
			RandomSleep(25)
		Next
		AmFah600SpiritBondCsvLog('ActivateQuest_post_accept', 'hp=' & Round(DllStructGetData(GetMyAgent(), 'HealthPercent') * 100) & '% sb=' & (GetEffect($ID_SPIRIT_BOND) <> Null ? 'on' : 'off') & ' ps=' & (GetEffect($ID_PROTECTIVE_SPIRIT) <> Null ? 'on' : 'off'))

		PingSleep(500)
		Dialog($AMFAH600_DIALOG_PROGRESS_REFUSE_TO_DRINK)
		PingSleep(250)

		; The progress dialog turns the Am Fah hostile. Maintain PS/SB while
		; giving them a short window to appear, then break out once any foe is
		; in earshot - the quest may not report 'active' even though it has
		; effectively started. This avoids re-running dialogs under fire.
		Local $foeWaitTimer = TimerInit()
		While IsPlayerAlive() And TimerDiff($foeWaitTimer) < 2500
			AmFah600SpiritBondMaintainCoreUpkeep()
			If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) > 0 Then ExitLoop
			RandomSleep(50)
		WEnd

		If IsQuestActive($ID_QUEST_REFUSE_TO_DRINK) Or CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) > 0 Then ExitLoop
	WEnd

	Info('Refuse to Drink is active - entering high-pressure guard')
	; Both Ambush groups are already hostile; keep 1/2/4 tight. Cast EVAS here
	; too — this early high-pressure phase still has full energy, so we get an
	; assassin on a Necro as early as possible.
	Local $timerGuard = TimerInit()
	Local $guardLoops = 0
	While IsPlayerAlive() And TimerDiff($timerGuard) < 3000
		AmFah600SpiritBondMaintainCoreUpkeep()
		AmFah600SpiritBondTryCastEvasOnNecromancer()
		RandomSleep(50)
		$guardLoops += 1
	WEnd
	AmFah600SpiritBondCsvLog('ActivateQuest_guard', 'loops=' & $guardLoops & ' alive=' & IsPlayerAlive())
	If IsPlayerDead() Then Return $FAIL
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondPullSecondGroup()
	Info('Pulling second Am Fah group (stop at aggro range, never into the group)')
	; The quest already made both ambush groups hostile. Walk from Tosai toward
	; the second group, but STOP at aggro range — never walk into the middle of
	; it, because its Marksmen knock the 600hp monk down and interrupt casts
	; (that killed the last run at dist=276 to a healer). Group 1 chases behind
	; us; group 2 sits ahead in the pull direction, so we stop as soon as a foe
	; ahead is within aggro range and never past the stop radius.
	Local $timer = TimerInit()
	Local $blockedCount = 0
	While IsPlayerAlive() And TimerDiff($timer) < 60000
		AmFah600SpiritBondPullTick()
		Local $me = GetMyAgent()
		If AmFah600SpiritBondPullShouldStop($me) Then ExitLoop
		Move($AMFAH600_SECOND_GROUP_PULL_X, $AMFAH600_SECOND_GROUP_PULL_Y)
		RandomSleep(100)
		; Body-blocked by the chasing first group — nudge around like MoveTo does.
		If Not IsPlayerMoving() Then
			$blockedCount += 1
			If $blockedCount > 3 Then
				MoveRadial($AMFAH600_SECOND_GROUP_PULL_X, $AMFAH600_SECOND_GROUP_PULL_Y, $RANGE_AREA * 1.5)
				Sleep(1000)
			EndIf
		EndIf
	WEnd
	If IsPlayerDead() Then Return $FAIL

	AmFah600SpiritBondMaintainCoreUpkeep()
	Local $me = GetMyAgent()
	AmFah600SpiritBondCsvLog('PullSecondGroup_stop', 'distToSpot=' & Round(GetDistanceToPoint($me, $AMFAH600_SECOND_GROUP_PULL_X, $AMFAH600_SECOND_GROUP_PULL_Y)) & ' x=' & Round(DllStructGetData($me, 'X')) & ' y=' & Round(DllStructGetData($me, 'Y')))
	Local $healer = AmFah600SpiritBondGetNearestHealerInRange($RANGE_COMPASS)
	If $healer <> Null Then
		Info('Second group pulled: healer model=' & DllStructGetData($healer, 'ModelID') & ', dist=' & Round(GetDistance($me, $healer)))
		ChangeTarget($healer)
	Else
		Info('No Am Fah Healer in compass yet; holding at stop point for aggro')
	EndIf
	Return $SUCCESS
EndFunc


;~ Returns True when the pull walk should stop. Primary: a group-2 foe ahead of
;~ us is already within aggro range, so it chases us instead of us walking into
;~ its knockdown range. Fallback: never get closer than the stop radius to the
;~ recorded group-2 spot (~aggro range, half the recorded Tosai→group distance).
Func AmFah600SpiritBondPullShouldStop($me)
	If $me == Null Then Return True
	Local $mx = DllStructGetData($me, 'X')
	Local $my = DllStructGetData($me, 'Y')

	; Fallback cap: stay at aggro range of the recorded group-2 spot.
	Local $distToSpot = GetDistanceToPoint($me, $AMFAH600_SECOND_GROUP_PULL_X, $AMFAH600_SECOND_GROUP_PULL_Y)
	If $distToSpot <= $AMFAH600_PULL_STOP_RADIUS Then
		Info('Pull stop: reached ring around recorded spot (dist=' & Round($distToSpot) & ')')
		Return True
	EndIf

	; Direction toward the recorded group-2 spot.
	Local $dirX = $AMFAH600_SECOND_GROUP_PULL_X - $mx
	Local $dirY = $AMFAH600_SECOND_GROUP_PULL_Y - $my
	Local $dirLen = Sqrt($dirX * $dirX + $dirY * $dirY)
	If $dirLen < 1 Then Return True

	; A foe ahead of us at aggro range = group 2 pulling (group 1 trails behind).
	Local $foes = GetFoesInRangeOfAgent($me, $AMFAH600_PULL_AGGRO_STOP_DIST + 300)
	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If GetIsDead($foe) Then ContinueLoop
		Local $fx = DllStructGetData($foe, 'X') - $mx
		Local $fy = DllStructGetData($foe, 'Y') - $my
		Local $dist = Sqrt($fx * $fx + $fy * $fy)
		If $dist < $AMFAH600_PULL_MIN_CANDIDATE_DIST Then ContinueLoop
		Local $dot = ($fx * $dirX + $fy * $dirY) / ($dirLen * $dist)
		If $dot < 0.5 Then ContinueLoop
		If $dist <= $AMFAH600_PULL_AGGRO_STOP_DIST Then
			Info('Pull stop: group 2 at aggro range (model=' & DllStructGetData($foe, 'ModelID') & ', dist=' & Round($dist) & ')')
			Return True
		EndIf
	Next
	Return False
EndFunc


;~ Tick used during the second-group pull: keeps the 600hp build alive
;~ (PS/SB) and the fight choreography running (EBW/VWK once foes are in
;~ earshot) while the monk walks from Tosai to the pull point. Also fires EVAS
;~ as soon as a Necro comes into range — energy is full and HP is high here, so
;~ the first assassin starts on a Necro before the main fight even begins.
Func AmFah600SpiritBondPullTick()
	AmFah600SpiritBondMaintainCoreUpkeep()
	AmFah600SpiritBondTryCastEvasOnNecromancer()
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
		; Cast EVAS first — hit a Necro with an assassin while energy is still
		; high (right at fight start), before maintenance casts drain it. On
		; recharge it picks up the next Necro.
		If AmFah600SpiritBondTryCastEvasOnNecromancer() Then
			; EVAS cast is done — cancel any client auto-approach toward the
			; Necro and return the monk to the anchor (never drift toward Spot 2).
			Move($anchorX, $anchorY)
			RandomSleep(60)
			ContinueLoop
		EndIf

		; Keep 1/2 as tight as possible before doing any target or finisher logic.
		AmFah600SpiritBondMaintainCoreUpkeep()

		$me = GetMyAgent()
		; End/escape when all foes are dead or only Necromancers remain — checked
		; over the full compass area, so a leftover Marksman/Healer keeps us
		; fighting instead of walking off and dying.
		If TimerDiff($timer) > 8000 And AmFah600SpiritBondShouldEndFirstFight() Then
			Info('Only unkillable foes remain - escaping to Spot 2')
			Return $SUCCESS
		EndIf
		AmFah600SpiritBondHoldPosition($anchorX, $anchorY)

		Local $target = AmFah600SpiritBondGetNearestHealerInRange($RANGE_COMPASS)
		If $target == Null Then $target = AmFah600SpiritBondGetNearestNecromancerInRange($RANGE_COMPASS)
		If $target == Null Then $target = GetNearestEnemyToAgent($me, $RANGE_EARSHOT)
		If $target <> Null Then ChangeTarget($target)

		RandomSleep(25)
	WEnd

	Warn('Am Fah 600 SB timeout in phase: ' & $label)
	Return $FAIL
EndFunc


Func AmFah600SpiritBondShouldEndFirstFight()
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS)
	Local $killableFoes = 0
	Local $necros = 0
	Static $necroCleanupTimer = 0

	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If GetIsDead($foe) Then ContinueLoop
		; Necromancers out-heal our damage and give too little energy (7/8) to
		; sustain; every other type (assassin/marksman/healer) is killable.
		If AmFah600SpiritBondIsNecromancerAgent($foe) Then
			$necros += 1
		Else
			$killableFoes += 1
		EndIf
	Next

	; Stay while there is anything killable (assassin/marksman/healer).
	If $killableFoes > 0 Then
		$necroCleanupTimer = 0
		Return False
	EndIf

	; Only Necromancers remain. Give EVAS assassins a bounded window to finish
	; them, so none survive to hex the monk to death on the way to Spot 2.
	If $necros > 0 Then
		If $necroCleanupTimer == 0 Then
			$necroCleanupTimer = TimerInit()
		ElseIf TimerDiff($necroCleanupTimer) > $AMFAH600_NECRO_CLEANUP_TIMEOUT_MS Then
			Warn('Am Fah 600: necro cleanup timed out - escaping with ' & $necros & ' necro(s) alive')
			$necroCleanupTimer = 0
			Return True
		EndIf
		Return False
	EndIf

	; Everything is dead.
	$necroCleanupTimer = 0
	Return True
EndFunc


Func AmFah600SpiritBondMaintainCoreUpkeep()
	If IsPlayerDead() Then Return
	Local $energy = GetEnergy()
	Local $me = GetMyAgent()
	; Cast EBW/VWK and pre-emptive PS/SB only once the Am Fah are hostile -
	; before that, only keep 1/2 alive so energy stays full for the fight.
	Local $foeCount = CountFoesInRangeOfAgent($me, $RANGE_EARSHOT)
	Local $inCombat = $foeCount > 0
	; With <= 3 foes left the Essence Bond energy income collapses, so we switch
	; to energy-saving mode: SB + VWK first, PS only if affordable on top, and
	; drop the luxury casts (Ebon Wisdom, pre-emptive SB recast) that starve us
	; against the last few Marksmen.
	Local $fewFoes = $foeCount <= 3

	; Read both remaining times first to avoid one blocking the other.
	Local $psRemaining = GetEffectTimeRemaining(GetEffect($ID_PROTECTIVE_SPIRIT))
	Local $sbRemaining = GetEffectTimeRemaining(GetEffect($ID_SPIRIT_BOND))

	; ---------------- Energy-saving mode: <= 3 foes left ----------------
	If $fewFoes Then
		; SB (the heal engine) always has top priority with scarce energy.
		If $sbRemaining == 0 And IsRecharged($AMFAH600_SPIRIT_BOND) And $energy >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_SPIRIT_BOND] Then
			UseSkillEx($AMFAH600_SPIRIT_BOND)
			RandomSleep(25)
			Return
		EndIf
		; VWK (the reflect kill engine) next — cheap and ends the fight.
		If $inCombat And GetEffectTimeRemaining(GetEffect($ID_VENGEFUL_WAS_KHANHEI)) == 0 _
			And IsRecharged($AMFAH600_VWK) _
			And $energy >= 12 Then
			UseSkillEx($AMFAH600_VWK)
			RandomSleep(25)
			Return
		EndIf
		; PS only if affordable on top — it caps damage so SB net-heals, but it
		; never competes with SB/VWK for the scarce energy.
		If $psRemaining == 0 And IsRecharged($AMFAH600_PROTECTIVE_SPIRIT) And $energy >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_PROTECTIVE_SPIRIT] Then
			UseSkillEx($AMFAH600_PROTECTIVE_SPIRIT)
			RandomSleep(25)
		EndIf
		Return
	EndIf

	; ---------------- Full mode: many foes, energy income is high ----------------
	Local $castAnything = False

	; Priority #1: Protective Spirit COMPLETELY expired — cast immediately or die.
	If $psRemaining == 0 And IsRecharged($AMFAH600_PROTECTIVE_SPIRIT) And $energy >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_PROTECTIVE_SPIRIT] Then
		UseSkillEx($AMFAH600_PROTECTIVE_SPIRIT)
		$castAnything = True
		$energy -= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_PROTECTIVE_SPIRIT]
		RandomSleep(25)
	EndIf

	; Priority #2: Spirit Bond COMPLETELY expired — cast immediately, this is the
	; active healing engine; without it the 600hp char has zero sustain.
	; ALSO cast if PS was just cast above (both were critical).
	If $sbRemaining == 0 And IsRecharged($AMFAH600_SPIRIT_BOND) And $energy >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_SPIRIT_BOND] Then
		UseSkillEx($AMFAH600_SPIRIT_BOND)
		$castAnything = True
		$energy -= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_SPIRIT_BOND]
		RandomSleep(25)
	EndIf

	If $castAnything Then Return

	; Priority #3: Pre-emptive Spirit Bond recast. SB has ~4s recharge and ~8s
	; duration, so recasting whenever recharged (energy permitting) keeps the
	; healing engine running without expiry gaps. Reserve 3 energy.
	If $inCombat And $sbRemaining > 0 And IsRecharged($AMFAH600_SPIRIT_BOND) And $energy >= ($AMFAH600_SKILL_COSTS_MAP[$AMFAH600_SPIRIT_BOND] + 3) Then
		UseSkillEx($AMFAH600_SPIRIT_BOND)
		$castAnything = True
		$energy -= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_SPIRIT_BOND]
		RandomSleep(25)
	EndIf

	If $castAnything Then Return

	; Priority #5: Ebon Wisdom (3) — 50 % faster recharge, cast before VWK so
	; VWK benefits from the recharge bonus.
	If $inCombat And GetEffectTimeRemaining(GetEffect($ID_EBON_BATTLE_STANDARD_OF_WISDOM)) == 0 _
		And IsRecharged($AMFAH600_EBON_WISDOM) _
		And $energy >= 20 Then
		UseSkillEx($AMFAH600_EBON_WISDOM)
		RandomSleep(25)
		Return
	EndIf

	; Priority #6: Vengeful Was Khanhei (4) — healing + damage.
	If $inCombat And GetEffectTimeRemaining(GetEffect($ID_VENGEFUL_WAS_KHANHEI)) == 0 _
		And IsRecharged($AMFAH600_VWK) _
		And $energy >= 12 Then
		UseSkillEx($AMFAH600_VWK)
		RandomSleep(25)
		Return
	EndIf
EndFunc


Func AmFah600SpiritBondTryCastEvasOnNecromancer()
	If Not IsRecharged($AMFAH600_EVAS) Then Return False
	If GetEnergy() < 20 Then Return False
	; Don't summon during an HP emergency while many foes are beating on us —
	; EVAS has a cast time. With only a few foes left (e.g. the last Necro) the
	; 2s cast is safe even at low HP, and that is exactly when the assassin is
	; needed to finish them off.
	If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.5 And _
		CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) > 3 Then Return False

	; Only target Necromancers inside EVAS' cast range — targeting a far one
	; makes the GW client auto-approach (walk toward it, into walls). The monk
	; stays glued to the anchor and only summons on Necros already in range.
	; Prefer a Necro the previous assassin is NOT already on, so multiple Necros
	; each get their own assassin instead of stacking all of them on one.
	Static $lastEvasTargetId = 0
	Local $necromancer = AmFah600SpiritBondGetNearestNecromancerInRange($AMFAH600_EVAS_CAST_RANGE, $lastEvasTargetId)
	If $necromancer == Null Then $necromancer = AmFah600SpiritBondGetNearestNecromancerInRange($AMFAH600_EVAS_CAST_RANGE, 0)
	If $necromancer == Null Then Return False

	$lastEvasTargetId = DllStructGetData($necromancer, 'ID')
	Info('Am Fah 600: casting EVAS on necromancer (dist=' & Round(GetDistance(GetMyAgent(), $necromancer)) & ', id=' & $lastEvasTargetId & ')')
	UseSkillEx($AMFAH600_EVAS, $necromancer)
	Return True
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
		If $noneLogTimer == 0 Or TimerDiff($noneLogTimer) > 3000 Then
			Info('Am Fah 600: no healer in range=' & $range & ' (foes=' & UBound($foes) & ')')
			$noneLogTimer = TimerInit()
		EndIf
	Else
		$noneLogTimer = 0
		Static $lastHealerHp = -1
		Static $lastHealerDist = 0
		Static $lastHealerLogTime = 0
		Local $curHp = Round(DllStructGetData($nearest, 'HealthPercent') * 100)
		Local $hpChanged = Abs($curHp - $lastHealerHp) >= 15
		Local $distChanged = Abs($nearestDist - $lastHealerDist) >= 200
		If $hpChanged Or $distChanged Or TimerDiff($lastHealerLogTime) > 3000 Then
			Info('Am Fah 600: healer — found=' & $healerCount & ', dist=' & Round($nearestDist) & ', hp=' & $curHp & '%')
			$lastHealerHp = $curHp
			$lastHealerDist = $nearestDist
			$lastHealerLogTime = TimerInit()
		EndIf
	EndIf
	Return $nearest
EndFunc


Func AmFah600SpiritBondTryMorgahnSpeedBoost()
	Local $slot = GetHeroNumberByHeroID($ID_GENERAL_MORGAHN)
	If $slot == Null Then Return
	If $amfah600_sb_morgahn_last_speed_timer <> 0 And TimerDiff($amfah600_sb_morgahn_last_speed_timer) < $AMFAH600_MORGAHN_SPEED_INTERVAL_MS Then Return

	; Strict alternation: 1 → 10s → 2 → 10s → 1 → ...
	; Both skills have 10s duration / 20s cooldown, giving permanent speed.
	If $amfah600_sb_morgahn_last_speed_skill <> 1 Then
		If IsRecharged(1, $slot) Then
			Info('Am Fah 600: Morgahn using Incoming (1)')
			UseHeroSkill($slot, 1)
			$amfah600_sb_morgahn_last_speed_skill = 1
			$amfah600_sb_morgahn_last_speed_timer = TimerInit()
		EndIf
	Else
		If IsRecharged(2, $slot) Then
			Info('Am Fah 600: Morgahn using Fall Back (2)')
			UseHeroSkill($slot, 2)
			$amfah600_sb_morgahn_last_speed_skill = 2
			$amfah600_sb_morgahn_last_speed_timer = TimerInit()
		EndIf
	EndIf
EndFunc


Func AmFah600SpiritBondIsHealerAgent($agent)
	If $agent == Null Then Return False
	Return DllStructGetData($agent, 'ModelID') == $AMFAH600_HEALER_MODEL_ID
EndFunc


Func AmFah600SpiritBondIsNecromancerAgent($agent)
	If $agent == Null Then Return False
	Return DllStructGetData($agent, 'ModelID') == $AMFAH600_NECROMANCER_MODEL_ID
EndFunc


Func AmFah600SpiritBondCountLivingHealers()
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
	Local $count = 0
	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If GetIsDead($foe) Then ContinueLoop
		If AmFah600SpiritBondIsHealerAgent($foe) Then $count += 1
	Next
	Return $count
EndFunc


Func AmFah600SpiritBondGetNearestNecromancerInRange($range, $excludeId = 0)
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $range)
	Local $nearest = Null
	Local $nearestDist = 100000000
	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If GetIsDead($foe) Then ContinueLoop
		If Not AmFah600SpiritBondIsNecromancerAgent($foe) Then ContinueLoop
		; Skip the Necro the last EVAS assassin is already on, so we spread
		; assassins across multiple Necros instead of stacking on the nearest.
		If $excludeId <> 0 And DllStructGetData($foe, 'ID') == $excludeId Then ContinueLoop
		Local $dist = GetDistance($me, $foe)
		If $dist < $nearestDist Then
			$nearestDist = $dist
			$nearest = $foe
		EndIf
	Next
	Return $nearest
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
	$amfah600_sb_precast3_done = False
	$amfah600_sb_precast4_done = False
	$amfah600_sb_precast7_done = False
	$amfah600_sb_precast8_done = False
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondGoToSpot2()
	Info('Moving to Spot 2 (Marksman group)')
	; Direct route: north from Tosai, then the recorded path west to the Marksman
	; spot. Do NOT cast anything during the trek — energy must be saved for the
	; fight at Spot 2, so we run and hope to survive the crossing.
	Local $waypoints[][2] = [ _
		[15388, -13325], _   ; just north of Tosai
		[15280, -10900], _   ; north
		[15177, -8462],  _   ; recording start
		[14949, -8120],  _   ; recording path
		[14740, -7806],  _   ; recording path
		[14551, -7509],  _   ; recording path
		[14369, -7209],  _   ; recording path
		[$AMFAH600_SPOT2_X, $AMFAH600_SPOT2_Y] _  ; Spot 2
	]
	For $i = 0 To UBound($waypoints) - 1
		If IsPlayerDead() Then Return $FAIL
		MoveTo($waypoints[$i][0], $waypoints[$i][1])
		RandomSleep(120)
	Next
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondFightSpot2()
	Info('Fighting Spot 2 (Marksman group remnants)')
	Local $timer = TimerInit()
	Local $me = GetMyAgent()
	Local $anchorX = DllStructGetData($me, 'X')
	Local $anchorY = DllStructGetData($me, 'Y')
	Move($anchorX, $anchorY)
	Local $foesCleared = False
	While IsPlayerAlive() And TimerDiff($timer) < 90000
		; Cast EVAS first while energy is high, before maintenance drains it.
		If AmFah600SpiritBondTryCastEvasOnNecromancer() Then
			; EVAS cast is done — cancel any client auto-approach toward the
			; Necro and return the monk to the anchor.
			Move($anchorX, $anchorY)
			RandomSleep(60)
			ContinueLoop
		EndIf

		AmFah600SpiritBondMaintainCoreUpkeep()
		$me = GetMyAgent()

		; End when all foes in earshot are dead.
		If CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) == 0 And TimerDiff($timer) > 5000 Then
			$foesCleared = True
			ExitLoop
		EndIf

		; Hold position loosely — Spot 2 is smaller, less need for strict anchoring.
		If GetDistanceToPoint($me, $anchorX, $anchorY) > 250 Then
			Move($anchorX, $anchorY)
			RandomSleep(30)
		EndIf

		; Target: healer > necromancer > nearest enemy.
		Local $target = AmFah600SpiritBondGetNearestHealerInRange($RANGE_COMPASS)
		If $target == Null Then $target = AmFah600SpiritBondGetNearestNecromancerInRange($RANGE_COMPASS)
		If $target == Null Then $target = GetNearestEnemyToAgent($me, $RANGE_EARSHOT)
		If $target <> Null Then ChangeTarget($target)

		RandomSleep(25)
	WEnd

	Return $foesCleared ? $SUCCESS : $FAIL
EndFunc


Func AmFah600SpiritBondCsvLog($event, $detail = '')
	Local Static $csvHandle = Null
	If $csvHandle == Null Then
		Local $csvPath = @ScriptDir & '/logs/amfah600_sb_debug-' & GetCharacterName() & '.csv'
		$csvHandle = FileOpen($csvPath, $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
		If $csvHandle == -1 Then Return ; silently skip if file can't be opened
		FileWriteLine($csvHandle, 'timestamp,elapsed_ms,event,detail,map_id,player_hp%,quest_active,foes_earshot,ps_ms,sb_ms,energy')
	EndIf
	Local $elapsed = TimerDiff($run_timer)
	Local $hp = IsPlayerAlive() ? Round(DllStructGetData(GetMyAgent(), 'HealthPercent') * 100, 1) : 0
	Local $quest = IsQuestActive($ID_QUEST_REFUSE_TO_DRINK) ? 1 : 0
	Local $foes = IsPlayerAlive() ? CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) : 0
	Local $psMs = IsPlayerAlive() ? Round(GetEffectTimeRemaining(GetEffect($ID_PROTECTIVE_SPIRIT))) : 0
	Local $sbMs = IsPlayerAlive() ? Round(GetEffectTimeRemaining(GetEffect($ID_SPIRIT_BOND))) : 0
	Local $energy = IsPlayerAlive() ? Round(GetEnergy()) : 0
	Local $ts = @YEAR & '-' & @MON & '-' & @MDAY & ' ' & @HOUR & ':' & @MIN & ':' & @SEC
	FileWriteLine($csvHandle, $ts & ',' & Round($elapsed, 0) & ',' & $event & ',' & $detail & ',' & GetMapID() & ',' & $hp & ',' & $quest & ',' & $foes & ',' & $psMs & ',' & $sbMs & ',' & $energy)
EndFunc
