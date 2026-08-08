#include-once

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; Ranger variant with Lightning Reflexes (gwpvx Build:R/D Escape Farmer).
; LR is a Stance like Escape — they cancel each other. LR has priority (IAS).
; Choreo: DwS + Escape to engage -> cancel into LR -> when LR expires, bridge with Escape -> switch back to LR.
Global Const $SPIRIT_SLAVES_RANGER_LR_SKILLBAR = 'Ogojchpr6SAHFH3kdfjhOXxl3lA'
Global Const $SPIRIT_SLAVES_RANGER_LR_FARM_INFORMATIONS = 'Ranger LR variant: Lightning Reflexes (IAS) with Escape (IMS/block) stance-swapping.'
Global Const $SPIRIT_SLAVES_RANGER_LR_FARM_DURATION = 10 * 60 * 1000
Global Const $SSRL_LOG_TAG = '[SS-RangerLR] '

Global Const $SSRL_ESCAPE = 1
Global Const $SSRL_LIGHTNING_REFLEXES = 2
Global Const $SSRL_YOU_ARE_ALL_WEAKLINGS = 3
Global Const $SSRL_GRENTHS_AURA = 4
Global Const $SSRL_CRIPPLING_VICTORY = 5
Global Const $SSRL_REAP_IMPURITIES = 6
Global Const $SSRL_MENTAL_BLOCK = 7
Global Const $SSRL_DWARVEN_STABILITY = 8

Global Const $SSRL_SKILLS_ARRAY = [$SSRL_ESCAPE, $SSRL_LIGHTNING_REFLEXES, $SSRL_YOU_ARE_ALL_WEAKLINGS, $SSRL_GRENTHS_AURA, $SSRL_CRIPPLING_VICTORY, $SSRL_REAP_IMPURITIES, $SSRL_MENTAL_BLOCK, $SSRL_DWARVEN_STABILITY]
Global Const $SSRL_SKILLS_COSTS_ARRAY = [5, 10, 5, 10, 6, 5, 10, 5]
Global Const $SSRL_SKILL_COSTS_MAP = MapFromArrays($SSRL_SKILLS_ARRAY, $SSRL_SKILLS_COSTS_ARRAY)
Global Const $SSRL_CHAIN_MIN_ADREN5 = 6
Global Const $SSRL_CHAIN_MIN_ADREN6 = 5

Global $spirit_slaves_ranger_lr_farm_setup = False
Global $spirit_slaves_ranger_lr_build_setup = False
Global $ssrl_log_handle = -1
Global $ssrl_log_timer = 0
Global $ssrl_log_run = 0


Func SpiritSlavesRangerLRLogInfo($message)
	Info($SSRL_LOG_TAG & $message)
EndFunc


Func SpiritSlavesRangerLRLogWarn($message)
	Warn($SSRL_LOG_TAG & $message)
EndFunc


Func SpiritSlavesRangerLRLogDebug($message)
	Debug($SSRL_LOG_TAG & $message)
EndFunc


Func SpiritSlavesRangerLRFarm()
	$ssrl_log_run += 1
	SSRLLogInit()
	SSRLLogWrite('run_start')

	If Not $spirit_slaves_ranger_lr_farm_setup And SetupSpiritSlavesRangerLRFarm() == $FAIL Then
		SSRLLogWrite('run_end', 'result=fail;reason=setup')
		SSRLLogClose()
		Return $PAUSE
	EndIf
	Local $result = SpiritSlavesRangerLRFarmLoop()
	SSRLLogWrite('run_end', 'result=' & $result)
	SSRLLogClose()
	Return $result
EndFunc


Func SetupSpiritSlavesRangerLRFarm()
	If GetMapID() <> $ID_THE_SHATTERED_RAVINES Then
		If TravelToOutpost($ID_BONE_PALACE, $district_name) == $FAIL Then Return $FAIL
		SwitchMode($ID_HARD_MODE)
		SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)

		If SetupPlayerSpiritSlavesRangerLRFarm() == $FAIL Then Return $FAIL
		LeaveParty()
		While Not $spirit_slaves_ranger_lr_farm_setup
			If SpiritSlavesRangerLRRunToShatteredRavines() == $FAIL Then ContinueLoop
			$spirit_slaves_ranger_lr_farm_setup = True
		WEnd
	Else
		; Already in Shattered Ravines — at rez shrine from a previous run.
		; Skip the Bone Palace travel, just rezone and go.
		SpiritSlavesRangerLRLogInfo('Already in Shattered Ravines — rezoning from shrine')
		SpiritSlavesRangerLREnsureWeaponSet3('shrine-recovery')
		SpiritSlavesRangerLRRezoneToTheShatteredRavines()
		$spirit_slaves_ranger_lr_farm_setup = True
	EndIf
	SpiritSlavesRangerLRLogInfo('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerSpiritSlavesRangerLRFarm()
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_RANGER Then
		SpiritSlavesRangerLRLogWarn('Should run this farm as ranger')
		Return $FAIL
	EndIf

	If Not $spirit_slaves_ranger_lr_build_setup Then
		SpiritSlavesRangerLRLogInfo('Setting up player build skill bar')
		If HeroHasTemplate(0, $SPIRIT_SLAVES_RANGER_LR_SKILLBAR) Then
			SpiritSlavesRangerLRLogInfo('Player build already on bar, skipping template load')
		Else
			LoadSkillTemplate($SPIRIT_SLAVES_RANGER_LR_SKILLBAR)
			RandomSleep(250)
		EndIf
		$spirit_slaves_ranger_lr_build_setup = True
	Else
		SpiritSlavesRangerLRLogInfo('Player build already configured: skipping skillbar reload')
	EndIf

	SpiritSlavesRangerLREnsureWeaponSet3('setup')
	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerLREnsureWeaponSet3($reason = '')
	SpiritSlavesRangerLRLogInfo('Weapon set enforcement -> 3' & ($reason <> '' ? ' (' & $reason & ')' : ''))
	ChangeWeaponSet(3)
	RandomSleep(120)
EndFunc


Func SpiritSlavesRangerLRRunToShatteredRavines()
	TravelToOutpost($ID_BONE_PALACE, $district_name)
	MoveTo(-14520, 6009)
	Move(-14820, 3400)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_JOKOS_DOMAIN) Then Return $FAIL
	RandomSleep(500)
	MoveTo(-12657, 2609)
	SpiritSlavesRangerLREnsureWeaponSet3('run-to-ravines')
	MoveTo(-10938, 4254)
	ChangeTarget(GetNearestSignpostToCoords(-10938, 4254))
	RandomSleep(500)
	SpiritSlavesRangerLRLogInfo('Taking wurm')
	TargetNearestItem()
	ActionInteract()
	RandomSleep(1500)
	UseSkillEx(5)
	MoveTo(-8255, 5320)
	Local $me = GetMyAgent()
	If (CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 0) Then UseSkillEx(5)
	; Escape for IMS + 75% block during the long wurm sprint
	If IsRecharged($SSRL_ESCAPE) And GetEnergy() >= $SSRL_SKILL_COSTS_MAP[$SSRL_ESCAPE] Then UseSkillEx($SSRL_ESCAPE)
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

	SpiritSlavesRangerLREnsureWeaponSet3('before-ravines-entry')
	SpiritSlavesRangerLRLogInfo('Entering The Shattered Ravines : careful')
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_THE_SHATTERED_RAVINES, 10000, 2000) Then Return $FAIL
	MoveTo(-9714, -10767)
	MoveTo(-7919, -10530)
	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerLRFarmLoop()
	SpiritSlavesRangerLREnsureWeaponSet3('farm-loop-start')
	UseConsumable($ID_SLICE_OF_PUMPKIN_PIE)

	Local $bottomPosition = [-8500, -6400]
	Local $topPosition = [-8900, -4600]
	; 5 Groups — identical wave pattern to original Spirit Slaves
	For $group = 1 To 5
		If $group <> 4 Then MoveTo(-7465, -7900, 0)
		If $group == 1 Then SpiritSlavesRangerLRWaitForAlliesDead()
		Local $balled = True
		If $group >= 1 And $group <= 3 Then $balled = SpiritSlavesRangerLRWaitForFoesBall($bottomPosition)
		If $group == 2 Or $group == 5 Then $balled = SpiritSlavesRangerLRWaitForFoesBall($topPosition)
		If IsPlayerDead() Then Return SpiritSlavesRangerLRRestartAfterDeath()
		SpiritSlavesRangerLRLogInfo('Killing group ' & $group)
		If ($balled ? SpiritSlavesRangerLRFarmGroup() : SpiritSlavesRangerLRQuickFarmGroup()) == $FAIL Then Return SpiritSlavesRangerLRRestartAfterDeath()
	Next

	SpiritSlavesRangerLRLogInfo('Moving out of the zone and back again')
	SpiritSlavesRangerLRRezoneToTheShatteredRavines()
	Return $SUCCESS
EndFunc


Func SpiritSlavesRangerLRRezoneToTheShatteredRavines()
	SpiritSlavesRangerLRLogInfo('Rezoning')
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


;~ Farm group — balled enemies, Ranger LR combat choreography
;~ Pre-cast DwS + Escape to engage, then switch to LR (IAS) once in melee.
Func SpiritSlavesRangerLRFarmGroup()
	Local $targetFoe = GetNearestNPCInRangeOfCoords(-8850, -5500, $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT * 2)
	GetAlmostInRangeOfAgent($targetFoe)
	SpiritSlavesRangerLREnsureWeaponSet3('farm-group')

	; Ranger choreography: DwS(8) -> MB(7) -> Escape(1) before engaging
	If IsRecharged($SSRL_DWARVEN_STABILITY) Then UseSkillEx($SSRL_DWARVEN_STABILITY)
	RandomSleep(50)
	If IsRecharged($SSRL_MENTAL_BLOCK) And GetEnergy() >= $SSRL_SKILL_COSTS_MAP[$SSRL_MENTAL_BLOCK] Then UseSkillEx($SSRL_MENTAL_BLOCK)
	RandomSleep(50)
	If IsRecharged($SSRL_ESCAPE) And GetEnergy() >= $SSRL_SKILL_COSTS_MAP[$SSRL_ESCAPE] Then UseSkillEx($SSRL_ESCAPE)

	; Move directly to the target — same pattern as the original Dervish.
	Move(DllStructGetData($targetFoe, 'X'), DllStructGetData($targetFoe, 'Y'))
	RandomSleep(100)
	$targetFoe = GetNearestEnemyToAgent(GetMyAgent())
	If $targetFoe == Null Then Return $SUCCESS

	If IsPlayerDead() Then Return $FAIL
	If SpiritSlavesRangerLRKillSequence() == $FAIL Then Return $FAIL
	SpiritSlavesRangerLRCleanseFromCripple()
	PickUpItems(SpiritSlavesRangerLRMaintainDefensiveUpkeep)
	Return $SUCCESS
EndFunc


;~ Quick farm group — enemies not balled, caught off guard
Func SpiritSlavesRangerLRQuickFarmGroup()
	MoveTo(-7475, -8040)
	SpiritSlavesRangerLREnsureWeaponSet3('quick-farm-group')

	; Ranger choreography: DwS(8) -> MB(7) -> Escape(1) before engaging
	If IsRecharged($SSRL_DWARVEN_STABILITY) Then UseSkillEx($SSRL_DWARVEN_STABILITY)
	RandomSleep(50)
	If IsRecharged($SSRL_MENTAL_BLOCK) And GetEnergy() >= $SSRL_SKILL_COSTS_MAP[$SSRL_MENTAL_BLOCK] Then UseSkillEx($SSRL_MENTAL_BLOCK)
	RandomSleep(50)
	If IsRecharged($SSRL_ESCAPE) And GetEnergy() >= $SSRL_SKILL_COSTS_MAP[$SSRL_ESCAPE] Then UseSkillEx($SSRL_ESCAPE)

	Local $targetFoe = GetNearestEnemyToAgent(GetMyAgent())
	If $targetFoe == Null Then Return $SUCCESS

	If IsPlayerDead() Then Return $FAIL
	If SpiritSlavesRangerLRKillSequence() == $FAIL Then Return $FAIL
	SpiritSlavesRangerLRCleanseFromCripple()
	PickUpItems(SpiritSlavesRangerLRMaintainDefensiveUpkeep)
	Return $SUCCESS
EndFunc


;~ Stance-swapping defensive upkeep: LR has priority (IAS). Escape bridges when LR is on cooldown.
;~ Both are Stances so they cancel each other — only one active at a time.
Func SpiritSlavesRangerLRMaintainDefensiveUpkeep()
	Local $lrEffect = GetEffect($ID_LIGHTNING_REFLEXES)
	Local $escapeEffect = GetEffect($ID_ESCAPE)
	Local $hasLR = ($lrEffect <> Null And GetEffectTimeRemaining($lrEffect) > 0)
	Local $hasEscape = ($escapeEffect <> Null And GetEffectTimeRemaining($escapeEffect) > 0)

	; LR always has priority — cast it whenever it's ready (cancels Escape if active)
	If IsRecharged($SSRL_LIGHTNING_REFLEXES) And GetEnergy() >= $SSRL_SKILL_COSTS_MAP[$SSRL_LIGHTNING_REFLEXES] Then
		If Not $hasLR Then
			UseSkillEx($SSRL_LIGHTNING_REFLEXES)
			SSRLLogWrite('cast_lr')
		EndIf
		; Don't Return — let cheap skills (DwS, MB, YaAW) also cast in same tick
	EndIf

	; LR is not ready — use Escape as bridge if no stance is active
	If Not $hasLR And Not $hasEscape Then
		If IsRecharged($SSRL_ESCAPE) And GetEnergy() >= $SSRL_SKILL_COSTS_MAP[$SSRL_ESCAPE] Then
			UseSkillEx($SSRL_ESCAPE)
			SSRLLogWrite('cast_escape')
		EndIf
	EndIf

	; Dwarven Stability — extends stance duration, cheap (5e)
	If IsRecharged($SSRL_DWARVEN_STABILITY) And GetEffectTimeRemaining(GetEffect($ID_DWARVEN_STABILITY)) == 0 And GetEnergy() >= $SSRL_SKILL_COSTS_MAP[$SSRL_DWARVEN_STABILITY] Then
		UseSkillEx($SSRL_DWARVEN_STABILITY)
		SSRLLogWrite('cast_dws')
	EndIf
	; Mental Block — 50% block, self-reapplies on hit
	If IsRecharged($SSRL_MENTAL_BLOCK) And GetEffectTimeRemaining(GetEffect($ID_MENTAL_BLOCK)) == 0 And GetEnergy() >= $SSRL_SKILL_COSTS_MAP[$SSRL_MENTAL_BLOCK] Then
		UseSkillEx($SSRL_MENTAL_BLOCK)
		SSRLLogWrite('cast_mb')
	EndIf
EndFunc


Func SpiritSlavesRangerLRMaintainUpkeep($target = Null)
	; Only cast during combat (foes in range) to avoid wasting energy during staging/looting.
	If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY) == 0 Then Return
	SpiritSlavesRangerLRMaintainDefensiveUpkeep()
	; YaAW — cheap (5e), AoE weakness, top priority for damage mitigation + amplification
	If IsRecharged($SSRL_YOU_ARE_ALL_WEAKLINGS) And GetEnergy() >= $SSRL_SKILL_COSTS_MAP[$SSRL_YOU_ARE_ALL_WEAKLINGS] Then
		If $target == Null Then $target = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_COMPASS)
		If $target <> Null Then
			UseSkillEx($SSRL_YOU_ARE_ALL_WEAKLINGS, $target)
			SSRLLogWrite('cast_yaaw')
		EndIf
	EndIf
	; Grenth's Aura — sustain + AoE life steal on cast. Cast when HP dropping.
	If IsRecharged($SSRL_GRENTHS_AURA) And GetEnergy() >= $SSRL_SKILL_COSTS_MAP[$SSRL_GRENTHS_AURA] And DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.90 Then
		UseSkillEx($SSRL_GRENTHS_AURA)
		SSRLLogWrite('cast_ga')
	EndIf
EndFunc


Func SpiritSlavesRangerLRHasAdrenaline($skillSlot, $requiredStrikes)
	Return GetSkillbarSkillAdrenaline($skillSlot) >= $requiredStrikes
EndFunc


Func SpiritSlavesRangerLRKillSequence()
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST + 200)
	SpiritSlavesRangerLREnsureWeaponSet3('kill-sequence-start')
	SpiritSlavesRangerLRLogInfo('Ranger LR kill sequence start: foes(spellcast)=' & $foesCount)

	While IsPlayerAlive() And $foesCount > 0 And TimerDiff($deadlock) < 100000
		SpiritSlavesRangerLRMaintainUpkeep()
		SSRLLogWrite('tick')
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
				If IsRecharged($SSRL_CRIPPLING_VICTORY) And SpiritSlavesRangerLRHasAdrenaline($SSRL_CRIPPLING_VICTORY, $SSRL_CHAIN_MIN_ADREN5) Then UseSkillEx($SSRL_CRIPPLING_VICTORY, $nearestFoe)
				If IsRecharged($SSRL_REAP_IMPURITIES) And SpiritSlavesRangerLRHasAdrenaline($SSRL_REAP_IMPURITIES, $SSRL_CHAIN_MIN_ADREN6) Then UseSkillEx($SSRL_REAP_IMPURITIES, $nearestFoe)
			EndIf
		EndIf
		Sleep(250)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST + 200)
		If IsPlayerDead() Then Return $FAIL
	WEnd

	If IsPlayerDead() Then Return $FAIL
	If $foesCount > 0 Then
		SpiritSlavesRangerLRLogWarn('Kill sequence deadlock: ' & $foesCount & ' foes still alive after timeout')
		Return $FAIL
	EndIf
	SpiritSlavesRangerLREnsureWeaponSet3('kill-sequence-end')
	SpiritSlavesRangerLRMaintainDefensiveUpkeep()
	RandomSleep(1000)
	PickUpItems(SpiritSlavesRangerLRMaintainDefensiveUpkeep)
	Return $SUCCESS
EndFunc


;~ Wait for all enemies to be balled — same logic as original Spirit Slaves
Func SpiritSlavesRangerLRWaitForFoesBall($position)
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
		SpiritSlavesRangerLRLogDebug('foes: ' & $foesCount & '/8')
	WEnd
	If (TimerDiff($deadlock) > 120000) Then SpiritSlavesRangerLRLogWarn('Timed out waiting for mobs to ball')
	Return True
EndFunc


;~ Wait for allies to be dead — same logic as original
Func SpiritSlavesRangerLRWaitForAlliesDead()
	Local $deadlock = TimerInit()
	Local $target = GetNearestNPCToCoords(-8600, -5810)

	; Wait until foes are in range of allies
	Local $distance = GetDistanceToPoint($target, -8600, -5810)
	While $distance < $RANGE_EARSHOT And TimerDiff($deadlock) < 120000
		RandomSleep(2000)
		$target = GetNearestNPCToCoords(-8600, -5810)
		$distance = GetDistanceToPoint($target, -8600, -5810)
		SpiritSlavesRangerLRLogDebug('Target: ' & $distance)
	WEnd
	If (TimerDiff($deadlock) > 120000) Then SpiritSlavesRangerLRLogWarn('Timed out waiting for allies to be dead')
EndFunc


Func SpiritSlavesRangerLRRestartAfterDeath()
	If Not IsPlayerDead() Then
		SpiritSlavesRangerLRLogInfo('Restart requested after kill-timeout/abort: rezoning now')
		SpiritSlavesRangerLRRezoneToTheShatteredRavines()
		Return $FAIL
	EndIf

	Local $deadlockTimer = TimerInit()
	SpiritSlavesRangerLRLogInfo('Waiting for resurrection')
	While IsPlayerDead()
		RandomSleep(1000)
		If TimerDiff($deadlockTimer) > 60000 Then
			$spirit_slaves_ranger_lr_farm_setup = False
			SpiritSlavesRangerLRLogInfo('Travelling to Bone Palace')
			TravelToOutpost($ID_BONE_PALACE, $district_name)
			Return $FAIL
		EndIf
	WEnd
	SpiritSlavesRangerLRRezoneToTheShatteredRavines()
	Return $FAIL
EndFunc


Func SpiritSlavesRangerLRCleanseFromCripple()
	If (GetHasCondition(GetMyAgent()) And GetEffect($ID_CRIPPLED) <> Null) Then UseSkillEx(5)
EndFunc


#Region Debug CSV logging
Func SSRLLogInit()
	Local $timestamp = @YEAR & @MON & @MDAY & '_' & @HOUR & @MIN & @SEC
	Local $path = @ScriptDir & '/logs/ssrl_debug-' & GetCharacterName() & '-run' & $ssrl_log_run & '-' & $timestamp & '.csv'
	$ssrl_log_handle = FileOpen($path, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	$ssrl_log_timer = TimerInit()
	If $ssrl_log_handle == -1 Then Return
	Info('SS-RangerLR CSV: ' & $path)
	FileWriteLine($ssrl_log_handle, 'time_ms;run;event;energy;hp;lr_ms;esc_ms;dws_ms;mb_ms;ga_ms;lr_ready;esc_ready;dws_ready;mb_ready;yaaw_ready;ga_ready;cv_adr;ri_adr;note')
EndFunc

Func SSRLLogClose()
	If $ssrl_log_handle == -1 Then Return
	FileClose($ssrl_log_handle)
	$ssrl_log_handle = -1
EndFunc

Func SSRLLogWrite($eventName, $note = '')
	If $ssrl_log_handle == -1 Then Return
	Local $timeMs = Int(TimerDiff($ssrl_log_timer))
	Local $me = GetMyAgent()
	Local $energy = GetEnergy()
	Local $hp = DllStructGetData($me, 'HealthPercent')
	Local $lrMs = GetEffectTimeRemaining($ID_LIGHTNING_REFLEXES)
	Local $escMs = GetEffectTimeRemaining($ID_ESCAPE)
	Local $dwsMs = GetEffectTimeRemaining($ID_DWARVEN_STABILITY)
	Local $mbMs = GetEffectTimeRemaining($ID_MENTAL_BLOCK)
	Local $gaMs = GetEffectTimeRemaining($ID_GRENTHS_AURA)
	Local $lrReady = IsRecharged($SSRL_LIGHTNING_REFLEXES)
	Local $escReady = IsRecharged($SSRL_ESCAPE)
	Local $dwsReady = IsRecharged($SSRL_DWARVEN_STABILITY)
	Local $mbReady = IsRecharged($SSRL_MENTAL_BLOCK)
	Local $yaawReady = IsRecharged($SSRL_YOU_ARE_ALL_WEAKLINGS)
	Local $gaReady = IsRecharged($SSRL_GRENTHS_AURA)
	Local $cvAdr = GetSkillbarSkillAdrenaline($SSRL_CRIPPLING_VICTORY)
	Local $riAdr = GetSkillbarSkillAdrenaline($SSRL_REAP_IMPURITIES)
	Local $safeNote = StringReplace($note, ';', ',')
	FileWriteLine($ssrl_log_handle, $timeMs & ';' & $ssrl_log_run & ';' & $eventName & ';' & $energy & ';' & $hp & ';' & $lrMs & ';' & $escMs & ';' & $dwsMs & ';' & $mbMs & ';' & $gaMs & ';' & $lrReady & ';' & $escReady & ';' & $dwsReady & ';' & $mbReady & ';' & $yaawReady & ';' & $gaReady & ';' & $cvAdr & ';' & $riAdr & ';' & $safeNote)
EndFunc
#EndRegion Debug CSV logging
