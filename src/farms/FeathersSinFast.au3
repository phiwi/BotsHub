#CS ===========================================================================
; Author: GitHub Copilot (Feathers Sin Fast — no-recovery variant)
; Based on: FeathersSin.au3
; Copyright 2026
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
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $FEATHERS_SIN_FAST_SKILLBAR = 'Owpk8djUKrq0AW1Vzl2W33BEBUNI'
Global Const $FEATHERS_SIN_FAST_FARM_DURATION = (8 * 60 + 20) * 1000
Global Const $FEATHERS_SIN_FAST_WEAPON_SET = 4
Global Const $FEATHERS_SIN_FAST_ONSLAUGHT_UPKEEP_BUFFER_MS = 1200
Global Const $FEATHERS_SIN_FAST_ONSLAUGHT_UPKEEP_TIMER_MS = 11000
Global Const $FEATHERS_SIN_FAST_ONSLAUGHT_LOG_THROTTLE_MS = 3000
Global Const $FEATHERS_SIN_FAST_UPKEEP_SOD_BUFFER_MS = 5000
Global Const $FEATHERS_SIN_FAST_UPKEEP_WOP_BUFFER_MS = 5000
Global Const $FEATHERS_SIN_FAST_FARM_INFORMATIONS = 'Feathers Sin Fast — no recovery between spots. Same route as Feathers Sin but skips HP/energy wait.' & @CRLF _
	& 'Uses Onslaught scythe pressure. Faster runs, slightly higher risk.'

; Skill slot mapping:
; 1 Chilling Victory
; 2 Grenths Fingers
; 3 Eremites Attack
; 4 Onslaught
; 5 Grenths Aura
; 6 Shroud of Distress
; 7 Way of Perfection
; 8 Critical Agility
Global Const $FEATHERS_SIN_FAST_CHILLING_VICTORY = 1
Global Const $FEATHERS_SIN_FAST_GRENTHS_FINGERS = 2
Global Const $FEATHERS_SIN_FAST_EREMITES_ATTACK = 3
Global Const $FEATHERS_SIN_FAST_ONSLAUGHT = 4
Global Const $FEATHERS_SIN_FAST_GRENTHS_AURA = 5
Global Const $FEATHERS_SIN_FAST_SHROUD_OF_DISTRESS = 6
Global Const $FEATHERS_SIN_FAST_WAY_OF_PERFECTION = 7
Global Const $FEATHERS_SIN_FAST_CRITICAL_AGILITY = 8

Global Const $FEATHERS_SIN_FAST_MODELID_SENSALI_CLAW = 3995
Global Const $FEATHERS_SIN_FAST_MODELID_SENSALI_DARKFEATHER = 3997
Global Const $FEATHERS_SIN_FAST_MODELID_SENSALI_CUTTER = 3999

Global $feathers_sin_fast_farm_setup = False
Global $feathers_sin_fast_upkeep_enabled = False
Global $feathers_sin_fast_first_spot_sprint_enabled = False
Global $feathers_sin_fast_first_spot_onslaught_casted_once = False
Global $feathers_sin_fast_first_spot_onslaught_timer = TimerInit()
Global $feathers_sin_fast_first_spot_onslaught_log_timer = TimerInit()
Global $feathers_sin_fast_first_spot_sprint_logged_start = False


Func FeathersFarmSinFast()
	If Not $feathers_sin_fast_farm_setup And SetupFeathersSinFastFarm() == $FAIL Then Return $PAUSE
	$feathers_sin_fast_upkeep_enabled = False
	$feathers_sin_fast_first_spot_sprint_enabled = True
	$feathers_sin_fast_first_spot_onslaught_casted_once = False
	$feathers_sin_fast_first_spot_onslaught_timer = TimerInit()
	$feathers_sin_fast_first_spot_onslaught_log_timer = TimerInit()
	$feathers_sin_fast_first_spot_sprint_logged_start = False

	FeathersSinFastGoToJayaBluffs()
	Local $result = FeathersSinFastFarmLoop()
	ResignAndReturnToOutpost($ID_SEITUNG_HARBOR)
	Return $result
EndFunc


Func SetupFeathersSinFastFarm()
	Info('Setting up Feathers Sin Fast farm')
	If TravelToOutpost($ID_SEITUNG_HARBOR, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerFeathersSinFastFarm() == $FAIL Then Return $FAIL
	LeaveParty()

	Info('Entering Jaya Bluffs')
	UseCitySpeedBoost()
	Local $me = GetMyAgent()
	If GetDistanceToPoint($me, 17300, 17300) > 5000 Then MoveTo(17000, 12400)
	If GetDistanceToPoint($me, 17300, 17300) > 4400 Then MoveTo(19000, 13450)
	If GetDistanceToPoint($me, 17300, 17300) > 1800 Then MoveTo(18750, 16000)

	FeathersSinFastGoToJayaBluffs()
	MoveTo(10500, -13100)
	Move(10970, -13360)
	RandomSleep(1000)
	WaitMapLoading($ID_SEITUNG_HARBOR, 10000, 2000)
	$feathers_sin_fast_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerFeathersSinFastFarm()
	Info('Setting up Sin/Derv player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_ASSASSIN Then
		Error('Should run this farm as assassin')
		Return $FAIL
	EndIf

	If HeroHasTemplate(0, $FEATHERS_SIN_FAST_SKILLBAR) Then
		Info('Feathers Sin Fast player: template already loaded, skipping')
	Else
		LoadSkillTemplate($FEATHERS_SIN_FAST_SKILLBAR)
		RandomSleep(250)
	EndIf
	ChangeWeaponSet($FEATHERS_SIN_FAST_WEAPON_SET)
	RandomSleep(120)
	Return $SUCCESS
EndFunc


Func FeathersSinFastGoToJayaBluffs()
	TravelToOutpost($ID_SEITUNG_HARBOR, $district_name)
	While GetMapID() <> $ID_JAYA_BLUFFS
		Info('Moving to Jaya Bluffs')
		MoveTo(17300, 17300)
		Move(16800, 17550)
		RandomSleep(1000)
		WaitMapLoading($ID_JAYA_BLUFFS, 10000, 2000)
	WEnd
EndFunc


Func FeathersSinFastFarmLoop()
	If GetMapID() <> $ID_JAYA_BLUFFS Then Return $FAIL

	Info('Running to Sensali.')
	UseConsumable($ID_BIRTHDAY_CUPCAKE)
	FeathersSinFastMaintainFirstSpotSprint('route_1')
	FeathersSinFastSprintMoveTo(9000, -12680)
	FeathersSinFastSprintMoveTo(7588, -10609)
	FeathersSinFastSprintMoveTo(2900, -9700)
	FeathersSinFastSprintMoveTo(1540, -6995)
	Info('Farming Sensali (Sin Fast).')
	If FeathersSinFastRunSpot(-472, -4342, False, 5 * 60 * 1000) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-1536, -1686) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(586, -76) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-1556, 2786) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-2229, -815, True, 2 * 60 * 1000) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-5247, -3290) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-6994, -2273) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-5042, -6638) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-11040, -8577) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-10860, -2840) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-14900, -3000) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-12200, 150) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-12500, 4000) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-12111, 1690) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-10303, 4110) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-10500, 5500) == $FAIL Then Return $FAIL
	If FeathersSinFastRunSpot(-9700, 2400) == $FAIL Then Return $FAIL

	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


; Move to target while continuously maintaining Onslaught sprint (first-spot only).
Func FeathersSinFastSprintMoveTo($x, $y)
	Move($x, $y)
	Local $me = GetMyAgent()
	While GetDistanceToPoint($me, $x, $y) > 250
		If IsPlayerDead() Then Return
		FeathersSinFastMaintainFirstSpotSprint('sprint_move')
		Sleep(250)
		$me = GetMyAgent()
	WEnd
EndFunc


; Unlike Feathers Sin, this variant does NOT wait for HP/energy recovery between spots.
Func FeathersSinFastRunSpot($x, $y, $waitForSettle = True, $timeout = 5 * 60 * 1000)
	Return FeathersSinFastMoveKill($x, $y, $waitForSettle, $timeout)
EndFunc


Func FeathersSinFastMoveKill($x, $y, $waitForSettle = True, $timeout = 5 * 60 * 1000)
	Local $angle = 0
	Local $stuckCount = 0
	Local $blocked = 0
	Local $deadlock = TimerInit()

	Move($x, $y)
	Local $me = GetMyAgent()
	While GetDistanceToPoint($me, $x, $y) > 250
		If TimerDiff($deadlock) > $timeout Then
			Resign()
			Sleep(3000)
			$deadlock = TimerInit()
			While IsPlayerAlive() And TimerDiff($deadlock) < 30000
				Sleep(3000)
				If TimerDiff($deadlock) > 15000 Then Resign()
			WEnd
		EndIf
		If IsPlayerDead() Then Return $FAIL

		FeathersSinFastMaintainFirstSpotSprint('move_to_spot')

		If $feathers_sin_fast_upkeep_enabled Then FeathersSinFastMaintainDefense()

		$me = GetMyAgent()
		If DllStructGetData($me, 'HealthPercent') < 0.9 Then
			FeathersSinFastMaintainDefense(True)
		EndIf

		$me = GetMyAgent()
		If CountFoesInRangeOfAgent($me, 1200, FeathersSinFastIsSensali) > 0 Then
			FeathersSinFastKill(False)
		EndIf

		$me = GetMyAgent()
		If Not IsPlayerMoving() Then
			$blocked += 1
			If $blocked <= 5 Then
				Move($x, $y)
			Else
				$me = GetMyAgent()
				$angle += 40
				Move(DllStructGetData($me, 'X') + 300 * Sin($angle), DllStructGetData($me, 'Y') + 300 * Cos($angle))
				Sleep(2000)
				Move($x, $y)
			EndIf
		EndIf

		$stuckCount += 1
		If $stuckCount > 25 Then
			$stuckCount = 0
			CheckAndSendStuckCommand()
		EndIf
		RandomSleep(250)
		$me = GetMyAgent()
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func FeathersSinFastKill($waitForSettle = True)
	Local $deadlock
	Local $timeout = 2 * 60 * 1000
	Local $stuckCount = 0

	CheckAndSendStuckCommand()

	If $waitForSettle Then
		If Not FeathersSinFastWaitForSettle() Then Return $FAIL
	EndIf

	CheckAndSendStuckCommand()
	$feathers_sin_fast_upkeep_enabled = True
	FeathersSinFastMaintainDefense(True)
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	ChangeWeaponSet($FEATHERS_SIN_FAST_WEAPON_SET)

	If IsRecharged($FEATHERS_SIN_FAST_CRITICAL_AGILITY) Then
		UseSkillEx($FEATHERS_SIN_FAST_CRITICAL_AGILITY)
		RandomSleep(120)
	EndIf
	If IsRecharged($FEATHERS_SIN_FAST_ONSLAUGHT) Then UseSkillEx($FEATHERS_SIN_FAST_ONSLAUGHT)
	FeathersSinFastMaintainDefense()

	If GetEnergy() >= 5 Then
		UseSkillEx($FEATHERS_SIN_FAST_EREMITES_ATTACK, $target)
	EndIf

	$deadlock = TimerInit()
	While CountFoesInRangeOfAgent(GetMyAgent(), 900, FeathersSinFastIsSensali) > 0
		If TimerDiff($deadlock) > $timeout Then
			Resign()
			Sleep(3000)
			$deadlock = TimerInit()
			While IsPlayerAlive() And TimerDiff($deadlock) < 30000
				Sleep(3000)
				If TimerDiff($deadlock) > 15000 Then Resign()
			WEnd
		EndIf
		If IsPlayerDead() Then Return $FAIL

		$target = GetNearestEnemyToAgent(GetMyAgent())
		Attack($target)
		FeathersSinFastMaintainDefense()
		If IsRecharged($FEATHERS_SIN_FAST_GRENTHS_AURA) Then UseSkillEx($FEATHERS_SIN_FAST_GRENTHS_AURA)
		If IsRecharged($FEATHERS_SIN_FAST_GRENTHS_FINGERS) And CountFoesInRangeOfAgent(GetMyAgent(), 300, FeathersSinFastIsSensali) > 1 Then UseSkillEx($FEATHERS_SIN_FAST_GRENTHS_FINGERS)
		If IsRecharged($FEATHERS_SIN_FAST_ONSLAUGHT) Then UseSkillEx($FEATHERS_SIN_FAST_ONSLAUGHT)

		If GetEnergy() >= 5 Then
			UseSkillEx($FEATHERS_SIN_FAST_CHILLING_VICTORY, $target)
			UseSkillEx($FEATHERS_SIN_FAST_EREMITES_ATTACK, $target)
		EndIf

		$stuckCount += 1
		If $stuckCount > 100 Then
			$stuckCount = 0
			CheckAndSendStuckCommand()
		EndIf

		Sleep(250)
	WEnd

	RandomSleep(500)
	Info('Looting')
	PickUpItems()
	FindAndOpenChests()
	ChangeWeaponSet($FEATHERS_SIN_FAST_WEAPON_SET)
	Return $SUCCESS
EndFunc


Func FeathersSinFastWaitForSettle($timeout = 10000)
	Local $me = GetMyAgent()
	Local $target
	Local $deadlock = TimerInit()

	While CountFoesInRangeOfAgent(-2, 900) == 0 And (TimerDiff($deadlock) < 5000)
		If IsPlayerDead() Then Return False
		If DllStructGetData($me, 'HealthPercent') < 0.7 Then Return True
		FeathersSinFastMaintainDefense()
		Sleep(250)
		$me = GetMyAgent()
		$target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
	WEnd

	If CountFoesInRangeOfAgent($me, 900) == 0 Then Return False

	$deadlock = TimerInit()
	While (GetDistance($me, $target) > $RANGE_NEARBY) And (TimerDiff($deadlock) < $timeout)
		If IsPlayerDead() Then Return False
		If DllStructGetData($me, 'HealthPercent') < 0.7 Then Return True
		FeathersSinFastMaintainDefense()
		Sleep(250)
		$me = GetMyAgent()
		$target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
	WEnd
	Return True
EndFunc


Func FeathersSinFastIsSensali($agent)
	Local $modelID = DllStructGetData($agent, 'ModelID')
	Return $modelID == $FEATHERS_SIN_FAST_MODELID_SENSALI_CLAW _
		Or $modelID == $FEATHERS_SIN_FAST_MODELID_SENSALI_DARKFEATHER _
		Or $modelID == $FEATHERS_SIN_FAST_MODELID_SENSALI_CUTTER
EndFunc


Func FeathersSinFastMaintainDefense($forceShroud = False)
	If Not $feathers_sin_fast_upkeep_enabled Then Return
	$feathers_sin_fast_first_spot_sprint_enabled = False

	Local $sodRemaining = FeathersSinFastGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)
	Local $wopRemaining = FeathersSinFastGetBestEffectTimeRemaining($ID_WAY_OF_PERFECTION)

	If $forceShroud Or $sodRemaining <= $FEATHERS_SIN_FAST_UPKEEP_SOD_BUFFER_MS Then
		If IsRecharged($FEATHERS_SIN_FAST_SHROUD_OF_DISTRESS) Then UseSkillEx($FEATHERS_SIN_FAST_SHROUD_OF_DISTRESS)
	EndIf

	If $wopRemaining <= $FEATHERS_SIN_FAST_UPKEEP_WOP_BUFFER_MS Then
		If IsRecharged($FEATHERS_SIN_FAST_WAY_OF_PERFECTION) Then UseSkillEx($FEATHERS_SIN_FAST_WAY_OF_PERFECTION)
	EndIf
EndFunc


Func FeathersSinFastMaintainFirstSpotSprint($context = '')
	If Not $feathers_sin_fast_first_spot_sprint_enabled Then Return

	If Not $feathers_sin_fast_first_spot_sprint_logged_start Then
		Info('First-spot sprint active: maintaining Onslaught until upkeep starts')
		$feathers_sin_fast_first_spot_sprint_logged_start = True
	EndIf

	Local $onslaughtRemaining = FeathersSinFastGetBestEffectTimeRemaining($ID_ONSLAUGHT, $ID_ONSLAUGHT_PVP)
	Local $needOnslaught = False
	If Not $feathers_sin_fast_first_spot_onslaught_casted_once Then
		$needOnslaught = True
	ElseIf $onslaughtRemaining <= $FEATHERS_SIN_FAST_ONSLAUGHT_UPKEEP_BUFFER_MS Then
		$needOnslaught = True
	ElseIf TimerDiff($feathers_sin_fast_first_spot_onslaught_timer) >= $FEATHERS_SIN_FAST_ONSLAUGHT_UPKEEP_TIMER_MS Then
		$needOnslaught = True
	EndIf

	If Not $needOnslaught Then Return

	If IsRecharged($FEATHERS_SIN_FAST_ONSLAUGHT) Then
		Info('First-spot sprint: casting Onslaught' & ($context == '' ? '' : ' (' & $context & ')'))
		UseSkillEx($FEATHERS_SIN_FAST_ONSLAUGHT)
		$feathers_sin_fast_first_spot_onslaught_casted_once = True
		$feathers_sin_fast_first_spot_onslaught_timer = TimerInit()
		$feathers_sin_fast_first_spot_onslaught_log_timer = TimerInit()
	ElseIf TimerDiff($feathers_sin_fast_first_spot_onslaught_log_timer) >= $FEATHERS_SIN_FAST_ONSLAUGHT_LOG_THROTTLE_MS Then
		Info('First-spot sprint: Onslaught not recharged yet' & ($context == '' ? '' : ' (' & $context & ')'))
		$feathers_sin_fast_first_spot_onslaught_log_timer = TimerInit()
	EndIf
EndFunc


Func FeathersSinFastGetBestEffectTimeRemaining($skillID1, $skillID2 = 0)
	Local $v1 = FeathersSinFastNormalizeEffectTimeMs(GetEffectTimeRemaining($skillID1))
	If $skillID2 == 0 Then Return $v1
	Local $v2 = FeathersSinFastNormalizeEffectTimeMs(GetEffectTimeRemaining($skillID2))
	Return $v2 > $v1 ? $v2 : $v1
EndFunc


Func FeathersSinFastNormalizeEffectTimeMs($value)
	If $value <= 0 Then Return 0
	If $value < 100 Then Return Int($value * 1000)
	Return Int($value)
EndFunc
