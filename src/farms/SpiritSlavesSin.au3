#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Contributor: Gahais, phiwi
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
#include '../../lib/GWA2_ID_Items.au3'
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID_Skills.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'


; ==== Constants ====
Global Const $SSS_SIN_SKILLBAR = 'Owpl8djVaqqrJdTOG6c9t19dARTWDC'
Global Const $SSS_FARM_INFORMATIONS = 'Spirit Slaves Assassin — Vow of Strength + I Am Unstoppable! (defensive).' & @CRLF _
	& '- Zealous Scythe of Enchanting (20% longer enchantments duration)' & @CRLF _
	& '- +1+3 Scythe Mastery Rune' & @CRLF _
	& '- +1 Critical Strikes Rune' & @CRLF _
	& '- +1 Shadow Arts Rune' & @CRLF _
	& '- +50 HP Rune, +2 Energy Rune' & @CRLF _
	& '- Windwalker or blessed insignias' & @CRLF _
	& '- The quest Destroy the Ungrateful Slaves not completed'
Global Const $SSS_FARM_DURATION = 10 * 60 * 1000

; Assassin skill slots
Global Const $SSS_YOU_ARE_ALL_WEAKLINGS	= 1
Global Const $SSS_CRIPPLING_VICTORY		= 2
Global Const $SSS_REAP_IMPURITIES		= 3
Global Const $SSS_VOW_OF_STRENGTH		= 4
Global Const $SSS_GRENTHS_AURA			= 5
Global Const $SSS_SHROUD_OF_DISTRESS	= 6
Global Const $SSS_I_AM_UNSTOPPABLE		= 7
Global Const $SSS_CRITICAL_AGILITY		= 8

Global Const $SSS_CV_ADREN = 6
Global Const $SSS_RI_ADREN = 5
Global Const $SSS_WEAPON_SET = 4
Global Const $SSS_COMBAT_TIMEOUT_MS = 10 * 60 * 1000
Global Const $SSS_UPKEEP_SOD_BUFFER_MS = 5000

Global Const $SSS_DEBUG_LOG = True ; Set to True to enable CSV debug logging

Global $spirit_slaves_sin_farm_setup = False
Global $sss_log_handle = -1
Global $sss_log_timer = 0
Global $sss_log_run = 0


;~ Main loop of the farm
Func SpiritSlavesSinFarm()
	If Not $spirit_slaves_sin_farm_setup And SetupSpiritSlavesSinFarm() == $FAIL Then Return $PAUSE
	Return SpiritSlavesSinFarmLoop()
EndFunc


;~ Farm setup : going to the Shattered Ravines
Func SetupSpiritSlavesSinFarm()
	If GetMapID() <> $ID_THE_SHATTERED_RAVINES Then
		If TravelToOutpost($ID_BONE_PALACE, $district_name) == $FAIL Then Return $FAIL
		SwitchMode($ID_HARD_MODE)
		SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)

		If SetupPlayerSpiritSlavesSinFarm() == $FAIL Then Return $FAIL
		LeaveParty()
		While Not $spirit_slaves_sin_farm_setup
			If SSSRunToShatteredRavines() == $FAIL Then ContinueLoop
			$spirit_slaves_sin_farm_setup = True
		WEnd
	Else
		; Already in Shattered Ravines — at rez shrine from a previous run.
		; Skip the Bone Palace travel, just rezone and go.
		Info('Already in Shattered Ravines — rezoning from shrine')
		SSSRezoneToTheShatteredRavines()
		$spirit_slaves_sin_farm_setup = True
	EndIf
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerSpiritSlavesSinFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
		If HeroHasTemplate(0, $SSS_SIN_SKILLBAR) Then
			Info('Spirit Slaves Sin : template already loaded, skipping')
		Else
			LoadSkillTemplate($SSS_SIN_SKILLBAR)
			RandomSleep(250)
		EndIf
	Else
		Warn('Should run this farm as an assassin')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func SSSRunToShatteredRavines()
	TravelToOutpost($ID_BONE_PALACE, $district_name)
	; Exiting to Jokos Domain (no IMS in this build — just walk)
	MoveTo(-14500, 6000)
	Move(-14800, 3400)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_JOKOS_DOMAIN) Then Return $FAIL

	RandomSleep(500)
	MoveTo(-12650, 2600)
	MoveTo(-10950, 4250)
	; Going to wurms spoor
	ChangeTarget(GetNearestSignpostToCoords(-10950, 4250))
	RandomSleep(500)
	Info('Taking wurm')
	TargetNearestItem()
	ActionInteract()
	RandomSleep(1500)
	UseSkillEx(5)
	MoveTo(-8255, 5320)

	; Starting from there, there might be enemies on the way
	Local $me = GetMyAgent()
	If (CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 0) Then UseSkillEx(5)
	MoveTo(-8600, 10600)
	$me = GetMyAgent()
	If (CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 0) Then UseSkillEx(5)
	MoveTo(-8250, 12800)
	Move(-3850, 19200)
	$me = GetMyAgent()
	While IsPlayerMoving()
		If (CountFoesInRangeOfAgent($me, $RANGE_NEARBY) > 0 And IsRecharged(5)) Then UseSkillEx(5)
		RandomSleep(500)
		$me = GetMyAgent()
		If IsPlayerDead() Then Return $FAIL
	WEnd
	MoveTo(-4500, 19700)
	RandomSleep(3000)
	MoveTo(-4500, 19700)
	If IsPlayerDead() Then Return $FAIL

	; Entering The Shattered Ravines
	Info('Entering The Shattered Ravines : careful')
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_THE_SHATTERED_RAVINES, 10000, 2000) Then Return $FAIL
	; Hurry up before dying
	MoveTo(-9700, -10750)
	MoveTo(-7900, -10550)
	Return $SUCCESS
EndFunc


;~ Farm loop — 5 waves, VoS + CV/Reap combat
Func SpiritSlavesSinFarmLoop()
	$sss_log_run += 1
	SSSLogInit()
	SSSLogWrite('run_start')

	Local $bottomPosition = [-8500, -6400]
	Local $topPosition = [-8900, -4600]
	; 5 Groups to kill
	For $group = 1 To 5
		If $group <> 4 Then MoveTo(-7465, -7900, 0)
		; For the first group, we need the allies to die first
		If $group == 1 Then SSSWaitForAlliesDead()
		Local $balled = True
		; The bottom group comes only the first three times
		If $group >= 1 And $group <= 3 Then $balled = SSSWaitForFoesBall($bottomPosition)
		; The top group comes twice
		If $group == 2 Or $group == 5 Then $balled = SSSWaitForFoesBall($topPosition)
		If IsPlayerDead() Then Return SSSRestartAfterDeath()
		Info('Killing group ' & $group)
		If ($balled ? FarmGroupSin() : QuickFarmGroupSin()) == $FAIL Then Return SSSRestartAfterDeath()
	Next

	Info('Moving out of the zone and back again')
	SSSRezoneToTheShatteredRavines()
	SSSLogWrite('run_end', 'result=0')
	SSSLogClose()
	Return $SUCCESS
EndFunc


;~ Wait for all enemies to be balled
Func SSSWaitForFoesBall($position)
	Local $deadlock = TimerInit()
	Local $target = Null
	Local $foesCount = 0
	Local $validation = 0
	Local $me = GetMyAgent()
	Local $nearestFoe = GetNearestEnemyToAgent($me)
	While IsPlayerAlive() And $foesCount < 8 And $validation < 2 And TimerDiff($deadlock) < 120000
		If $foesCount == 8 Then $validation += 1
		RandomSleep(1000)
		$target = GetNearestNPCInRangeOfCoords($position[0], $position[1], $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT)
		If $target <> Null Then $foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
		$me = GetMyAgent()
		$nearestFoe = GetNearestEnemyToAgent($me)
		Debug('foes: ' & $foesCount & '/8')
		If GetDistance($me, $nearestFoe) <= $MOB_AGGRO_RANGE Then Return False
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Warn('Timed out waiting for mobs to ball')
	Return True
EndFunc


; ============================================================
; VoS combat — balled group
; ============================================================
Func FarmGroupSin()
	Local $target = GetNearestNPCInRangeOfCoords(-8850, -5500, $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT * 2)
	GetAlmostInRangeOfAgent($target)

	; Pre-combat: cast enchants/stance at edge of aggro bubble
	SSSPreCombat()

	; Aggro foes — rush in
	Move(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'))
	RandomSleep(1000)
	SSSLogWrite('combat_enter', 'balled=1')

	SSSKill()
	If IsPlayerDead() Then Return $FAIL

	SSSCleanseFromCripple()
	PickUpItems()
	Return $SUCCESS
EndFunc


; ============================================================
; VoS combat — unballed group (speed variant)
; ============================================================
Func QuickFarmGroupSin()
	MoveTo(-7475, -8040)

	; Pre-combat: cast enchants/stance before engaging
	SSSPreCombat()

	SSSLogWrite('combat_enter', 'balled=0')

	SSSKill()
	If IsPlayerDead() Then Return $FAIL

	SSSCleanseFromCripple()
	PickUpItems()
	Return $SUCCESS
EndFunc


;~ Pre-combat preparation — cast enchants/stance at edge of aggro
Func SSSPreCombat()
	; Wait for enough energy
	Local $waitCount = 0
	While GetEnergy() < 25 And $waitCount < 15
		Sleep(1000)
		$waitCount += 1
		If IsPlayerDead() Then Return
	WEnd

	; Shroud of Distress — mandatory defense
	If IsRecharged($SSS_SHROUD_OF_DISTRESS) And GetEnergy() >= 10 Then
		UseSkillEx($SSS_SHROUD_OF_DISTRESS)
		RandomSleep(80)
	EndIf

	; Vow of Strength — elite, AoE slashing on scythe hit
	If IsRecharged($SSS_VOW_OF_STRENGTH) And GetEnergy() >= 5 Then
		UseSkillEx($SSS_VOW_OF_STRENGTH)
		RandomSleep(80)
	EndIf

	; Mystic Vigor removed — YaaW in slot 1,  in slot 7 (see SSSMaintainDefense)

	; Critical Agility — IAS + armor
	If IsRecharged($SSS_CRITICAL_AGILITY) And GetEnergy() >= 5 Then
		UseSkillEx($SSS_CRITICAL_AGILITY)
		RandomSleep(80)
	EndIf

	If $SSS_DEBUG_LOG Then SSSLogWrite('pre_combat', 'e=' & Int(GetEnergy()) & ';sod=' & IsRecharged($SSS_SHROUD_OF_DISTRESS) & ';vos=' & IsRecharged($SSS_VOW_OF_STRENGTH))
EndFunc


;~ VoS + CV/Reap kill loop (adrenal chain pattern)
Func SSSKill()
	CheckAndSendStuckCommand()
	SSSMaintainDefense(True)
	ChangeWeaponSet($SSS_WEAPON_SET)

	; Pre-cast IAS before engaging
	If IsRecharged($SSS_CRITICAL_AGILITY) Then
		UseSkillEx($SSS_CRITICAL_AGILITY)
		RandomSleep(120)
	EndIf
	SSSMaintainDefense()

	Local $combatTimer = TimerInit()
	Local $clock = False
	Local $stuckCount = 0
	Local $target
	Local $currentFoes
	Local $repositionTarget = Null ; When set, commit to reaching this cluster before attacking
	Local $reposStuckCount = 0     ; Bail out of repositioning if bodyblocked too long
	Local $reposCooldown = 0       ; Don't retry repositioning immediately after timeout

	While True
		$currentFoes = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST + 200)
		; Exit only when no foes in spellcast range AND not currently repositioning to a known cluster
		If $currentFoes == 0 And $repositionTarget == Null Then ExitLoop

		If TimerDiff($combatTimer) >= $SSS_COMBAT_TIMEOUT_MS Then
			SSSLogWrite('combat_timeout', 'elapsed_ms=' & Int(TimerDiff($combatTimer)))
			Warn('Spirit Slaves Sin : combat timeout after ' & Int(TimerDiff($combatTimer) / 1000) & 's')
			ExitLoop
		EndIf
		If IsPlayerDead() Then Return $FAIL

		; Repositioning mode: advance toward cluster — NO ATTACKS, pure movement only.
		If $repositionTarget <> Null Then
			If GetIsDead($repositionTarget) Then
				$repositionTarget = Null
				$reposStuckCount = 0
			Else
				Local $clusterDist = GetDistance(GetMyAgent(), $repositionTarget)
				If $clusterDist > $RANGE_ADJACENT Then
					$reposStuckCount += 1
					SSSMaintainDefense()
					; Timeout after ~1.4s (7 iterations) — give up, fight where we are, and don't retry immediately
					If $reposStuckCount > 6 Then
						SSSLogWrite('repos_timeout', 'stuck=' & $reposStuckCount & ';dist=' & Int($clusterDist))
						$repositionTarget = Null
						$reposStuckCount = 0
						$reposCooldown = 20   ; ~4s cooldown before retrying reposition
						Sleep(10)
						ContinueLoop
					EndIf
					; Sidestep hooks at stuck 2/4 — slip past bodyblock without attacking
					If $reposStuckCount == 2 Or $reposStuckCount == 4 Then
						Local $me = GetMyAgent()
						Local $tx = DllStructGetData($repositionTarget, 'X')
						Local $ty = DllStructGetData($repositionTarget, 'Y')
						Local $mx = DllStructGetData($me, 'X')
						Local $my = DllStructGetData($me, 'Y')
						Local $dx = $tx - $mx, $dy = $ty - $my
						Local $sign = ($reposStuckCount == 2) ? -1 : 1
						Local $strafeX = $mx - $dy * 0.7 * $sign
						Local $strafeY = $my + $dx * 0.7 * $sign
						SSSLogWrite('repos_hook', 'dir=' & ($sign < 0 ? 'L' : 'R') & ';stuck=' & $reposStuckCount & ';dist=' & Int($clusterDist))
						Move($strafeX, $strafeY)
						Sleep(10)
						ContinueLoop
					EndIf
					; All other iterations: just move toward cluster center
					Move(DllStructGetData($repositionTarget, 'X'), DllStructGetData($repositionTarget, 'Y'))
					Sleep(10)
					ContinueLoop
				EndIf
				; Reached the cluster — resume normal combat
				SSSLogWrite('repos_arrive', 'dist=' & Int($clusterDist))
				$repositionTarget = Null
				$reposStuckCount = 0
			EndIf
		EndIf

		; Normal mode: target acquisition FIRST — instant switch after each kill
		Local $iterStart = TimerInit()
		$target = GetNearestEnemyToAgent(GetMyAgent())
		If $target == Null Then ExitLoop
		ChangeTarget($target)

		Local $dist = GetDistance(GetMyAgent(), $target)
		If $SSS_DEBUG_LOG Then SSSLogWrite('tick', 'dist=' & Int($dist) & ';hp=' & StringFormat('%.2f', DllStructGetData(GetMyAgent(), 'HealthPercent')) & ';e=' & Int(GetEnergy()) & ';foes=' & $currentFoes)

		; If target is out of melee range, close distance fast, then attack same iteration
		If $dist > $RANGE_ADJACENT Then
			Move(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'))
			Sleep(10)
			ContinueLoop
		EndIf

		; In melee range — attack first, then maintain defense
		Attack($target)

		; Strict CV→RI order: CV applies Crippled, RI strips it for AoE holy damage.
		; Never cast RI before CV — RI would strip Weakness (YaaW) instead, killing our defense.
		; Use UseSkill (non-blocking) for attack skills — their ~1.5s swing time must not block the loop.
		If Not $clock Then
			If IsRecharged($SSS_CRIPPLING_VICTORY) And SSSHasAdrenaline($SSS_CRIPPLING_VICTORY, $SSS_CV_ADREN) Then
				SSSLogWrite('cv_cast')
				UseSkill($SSS_CRIPPLING_VICTORY, $target)
				$clock = True
			Else
				Sleep(10)
			EndIf
		Else
			If IsRecharged($SSS_REAP_IMPURITIES) And SSSHasAdrenaline($SSS_REAP_IMPURITIES, $SSS_RI_ADREN) Then
				SSSLogWrite('ri_cast')
				UseSkill($SSS_REAP_IMPURITIES, $target)
				$clock = False
			Else
				Sleep(10)
			EndIf
		EndIf

		Local $defStart = TimerInit()
		SSSMaintainDefense()
		Local $defElapsed = TimerDiff($defStart)
		If $defElapsed > 500 Then Debug('SSSMaintainDefense took ' & Int($defElapsed) & 'ms')

		$stuckCount += 1
		If $stuckCount > 100 Then
			$stuckCount = 0
			CheckAndSendStuckCommand()
		EndIf

		; Reposition to densest enemy cluster when ≤2 foes in melee range.
		; If the best cluster is already adjacent, stay put — no need to move.
		; After a timeout, cooldown prevents immediate retry to avoid death-loops.
		If $reposCooldown > 0 Then
			$reposCooldown -= 1
		ElseIf $repositionTarget == Null And CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_ADJACENT) <= 2 Then
			Local $clusterStart = TimerInit()
			Local $candidate = SSSFindDensestCluster()
			Local $clusterElapsed = TimerDiff($clusterStart)
			If $clusterElapsed > 500 Then Debug('SSSFindDensestCluster took ' & Int($clusterElapsed) & 'ms')
			If $candidate <> Null Then
				Local $candDist = GetDistance(GetMyAgent(), $candidate)
				Local $adjForLog = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_ADJACENT)
				Local $farForLog = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST + 200)
				If $candDist <= $RANGE_ADJACENT Then
					; Best cluster is already right here — nothing to reposition to
					SSSLogWrite('repos_skip', 'adj=' & $adjForLog & ';far=' & $farForLog & ';clusterDist=' & Int($candDist))
				Else
					$repositionTarget = $candidate
					SSSLogWrite('repos_start', 'adj=' & $adjForLog & ';far=' & $farForLog & ';clusterDist=' & Int($candDist))
					$reposStuckCount = 0
				EndIf
			EndIf
		EndIf

		Local $iterElapsed = TimerDiff($iterStart)
		If $iterElapsed > 2000 Then Debug('SLOW iteration: ' & Int($iterElapsed) & 'ms | foes=' & $currentFoes & ' clock=' & $clock & ' dist=' & Int($dist))
		Sleep(10)
	WEnd

	RandomSleep(500)
	ChangeWeaponSet($SSS_WEAPON_SET)
EndFunc


Func SSSHasAdrenaline($skillSlot, $requiredStrikes)
	Return GetSkillbarSkillAdrenaline($skillSlot) >= $requiredStrikes
EndFunc


;~ Find the densest cluster among living enemies — returns the foe with most neighbors within $RANGE_AREA.
;~ Used for repositioning when ≤2 foes are in melee range, to keep damage propagation effective.
Func SSSFindDensestCluster()
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_EARSHOT)
	If Not IsArray($foes) Then Return Null
	If UBound($foes) == 0 Then Return Null

	Local $bestFoe = Null
	Local $bestCount = 0
	Local $bestDistance = 0

	For $i = 0 To UBound($foes) - 1
		Local $foe = $foes[$i]
		If GetIsDead($foe) Then ContinueLoop
		Local $count = 0
		For $j = 0 To UBound($foes) - 1
			If $i == $j Then ContinueLoop
			If GetIsDead($foes[$j]) Then ContinueLoop
			If GetDistance($foe, $foes[$j]) <= $RANGE_AREA Then $count += 1
		Next
		; Prefer enemy with most neighbors; break ties by furthest distance from us (casters)
		Local $dist = GetDistance($me, $foe)
		If $count > $bestCount Or ($count == $bestCount And $dist > $bestDistance) Then
			$bestCount = $count
			$bestDistance = $dist
			$bestFoe = $foe
		EndIf
	Next

	Return $bestFoe
EndFunc


;~ Find the furthest living enemy within spellcast range.
;~ Used to break through bodyblock when the densest cluster center is adjacent but unreachable.
Func SSSFindFurthestFoe()
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST + 200)
	If Not IsArray($foes) Then Return Null
	If UBound($foes) == 0 Then Return Null

	Local $bestFoe = Null
	Local $bestDistance = 0

	For $i = 0 To UBound($foes) - 1
		Local $foe = $foes[$i]
		If GetIsDead($foe) Then ContinueLoop
		Local $dist = GetDistance($me, $foe)
		If $dist > $bestDistance Then
			$bestDistance = $dist
			$bestFoe = $foe
		EndIf
	Next

	Return $bestFoe
EndFunc


;~ Maintain defense + utility: SoD, VoS, IaU, GA, Critical Agility
Func SSSMaintainDefense($forceShroud = False)
	Local $nearbyFoes = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
	Local $sodRemaining = SSSGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)
	; Shroud of Distress — 75% block under 50% HP
	If $forceShroud Or $sodRemaining <= $SSS_UPKEEP_SOD_BUFFER_MS Then
		If IsRecharged($SSS_SHROUD_OF_DISTRESS) Then UseSkillEx($SSS_SHROUD_OF_DISTRESS)
	EndIf

	; Vow of Strength — elite enchantment, AoE slashing on scythe hit. Cast on recharge.
	If $nearbyFoes > 0 And IsRecharged($SSS_VOW_OF_STRENGTH) And GetEnergy() >= 5 Then
		SSSLogWrite('vos_cast')
		UseSkillEx($SSS_VOW_OF_STRENGTH)
	EndIf

	; YaaW — AoE Weakness, 66% damage reduction. Spam on recharge during combat.
	If $nearbyFoes > 0 And IsRecharged($SSS_YOU_ARE_ALL_WEAKLINGS) Then
		Local $yaawTarget = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_COMPASS)
		If $yaawTarget <> Null Then
			SSSLogWrite('yaaw_cast')
			UseSkillEx($SSS_YOU_ARE_ALL_WEAKLINGS, $yaawTarget)
		EndIf
	EndIf

	; I Am Unstoppable! — +24 armor, anti-KD/anti-cripple. Cast on recharge during combat.
	If $nearbyFoes > 0 And IsRecharged($SSS_I_AM_UNSTOPPABLE) Then
		SSSLogWrite('iau_cast')
		UseSkillEx($SSS_I_AM_UNSTOPPABLE)
	EndIf

	; Grenth's Aura — lifesteal on hit, sustain. Only during combat to save energy.
	If $nearbyFoes > 0 And IsRecharged($SSS_GRENTHS_AURA) And DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.90 Then
		SSSLogWrite('ga_cast')
		UseSkillEx($SSS_GRENTHS_AURA)
	EndIf

	; Critical Agility — perma-IAS, self-renews on crit. Only during combat to save energy.
	If $nearbyFoes > 0 And IsRecharged($SSS_CRITICAL_AGILITY) And GetEnergy() > 12 Then
		If SSSGetBestEffectTimeRemaining($ID_CRITICAL_AGILITY) <= 500 Then
			SSSLogWrite('ca_cast')
			UseSkillEx($SSS_CRITICAL_AGILITY)
		EndIf
	EndIf
EndFunc


Func SSSGetBestEffectTimeRemaining($skillID1, $skillID2 = 0)
	Local $v1 = SSSNormalizeEffectTimeMs(GetEffectTimeRemaining($skillID1))
	If $skillID2 == 0 Then Return $v1
	Local $v2 = SSSNormalizeEffectTimeMs(GetEffectTimeRemaining($skillID2))
	Return $v2 > $v1 ? $v2 : $v1
EndFunc


Func SSSNormalizeEffectTimeMs($value)
	If $value <= 0 Then Return 0
	If $value < 100 Then Return Int($value * 1000)
	Return Int($value)
EndFunc


;~ Wait for allies to be dead
Func SSSWaitForAlliesDead()
	Local $deadlock = TimerInit()
	Local $target = GetNearestNPCToCoords(-8600, -5810)

	Local $distance = GetDistanceToPoint($target, -8600, -5810)
	While $distance < $RANGE_EARSHOT And TimerDiff($deadlock) < 120000 And IsPlayerAlive()
		RandomSleep(2000)
		$target = GetNearestNPCToCoords(-8600, -5810)
		$distance = GetDistanceToPoint($target, -8600, -5810)
		Debug('Target: ' & $distance)
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Warn('Timed out waiting for allies to be dead')
EndFunc


;~ Respawn and rezone if we die
Func SSSRestartAfterDeath()
	Local $deadlockTimer = TimerInit()
	SSSLogWrite('death')
	Info('Waiting for resurrection')
	While IsPlayerDead()
		RandomSleep(1000)
		If TimerDiff($deadlockTimer) > 60000 Then
			$spirit_slaves_sin_farm_setup = False
			Info('Travelling to Bone Palace')
			DistrictTravel($ID_BONE_PALACE, $district_name)
			Return $FAIL
		EndIf
	WEnd
	SSSRezoneToTheShatteredRavines()
	Return $FAIL
EndFunc


;~ Rezoning to reset the farm (no IMS — just walk)
Func SSSRezoneToTheShatteredRavines()
	Info('Rezoning')
	; Exiting to Jokos Domain
	MoveTo(-7800, -10250)
	MoveTo(-9000, -10900)
	MoveTo(-10500, -11000)
	Move(-10650, -11300)
	RandomSleep(1000)
	WaitMapLoading($ID_JOKOS_DOMAIN)
	RandomSleep(500)
	; Reentering The Shattered Ravines
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	WaitMapLoading($ID_THE_SHATTERED_RAVINES, 10000, 2000)
	; Hurry up before dying
	MoveTo(-9700, -10750)
	MoveTo(-7900, -10550)
EndFunc


;~ Cleanse if the character has a condition (cripple)
Func SSSCleanseFromCripple()
	If (GetHasCondition(GetMyAgent()) And GetEffect($ID_CRIPPLED) <> Null) Then UseSkillEx(8)
EndFunc


; ------------------------------------------------------------
; Debug CSV logging (opt-in, disabled by default)
; ------------------------------------------------------------
Func SSSLogInit()
	If Not $SSS_DEBUG_LOG Then Return
	Local $timestamp = @YEAR & @MON & @MDAY & '_' & @HOUR & @MIN & @SEC
	Local $path = @ScriptDir & '/logs/sssin_debug-' & GetCharacterName() & '-run' & $sss_log_run & '-' & $timestamp & '.csv'
	$sss_log_handle = FileOpen($path, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	$sss_log_timer = TimerInit()
	If $sss_log_handle == -1 Then Return
	Info('Spirit Slaves Sin  CSV: ' & $path)
	FileWriteLine($sss_log_handle, 'time_ms;run;event;energy;hp;vos_ms;sod_ms;ca_ms;iau_ms;vos_ready;ga_ready;sod_ready;cv_ready;ri_ready;yaaw_ready;iau_ready;note')
EndFunc

Func SSSLogClose()
	If $sss_log_handle == -1 Then Return
	FileClose($sss_log_handle)
	$sss_log_handle = -1
EndFunc

Func SSSLogWrite($eventName, $note = '')
	If $sss_log_handle == -1 Then Return
	Local $timeMs = Int(TimerDiff($sss_log_timer))
	Local $me = GetMyAgent()
	Local $energy = GetEnergy()
	Local $hp = DllStructGetData($me, 'HealthPercent')
	Local $vosMs = GetEffectTimeRemaining($ID_VOW_OF_STRENGTH)
	Local $sodMs = GetEffectTimeRemaining($ID_SHROUD_OF_DISTRESS)
	Local $caMs = GetEffectTimeRemaining($ID_CRITICAL_AGILITY)
	Local $iauMs = GetEffectTimeRemaining($ID_I_AM_UNSTOPPABLE)
	Local $vosReady = IsRecharged($SSS_VOW_OF_STRENGTH)
	Local $gaReady = IsRecharged($SSS_GRENTHS_AURA)
	Local $sodReady = IsRecharged($SSS_SHROUD_OF_DISTRESS)
	Local $cvReady = IsRecharged($SSS_CRIPPLING_VICTORY)
	Local $riReady = IsRecharged($SSS_REAP_IMPURITIES)
	Local $yaawReady = IsRecharged($SSS_YOU_ARE_ALL_WEAKLINGS)
	Local $iauReady = IsRecharged($SSS_I_AM_UNSTOPPABLE)
	Local $safeNote = StringReplace($note, ';', ',')
	FileWriteLine($sss_log_handle, $timeMs & ';' & $sss_log_run & ';' & $eventName & ';' & $energy & ';' & $hp & ';' & $vosMs & ';' & $sodMs & ';' & $caMs & ';' & $iauMs & ';' & $vosReady & ';' & $gaReady & ';' & $sodReady & ';' & $cvReady & ';' & $riReady & ';' & $yaawReady & ';' & $iauReady & ';' & $safeNote)
EndFunc
