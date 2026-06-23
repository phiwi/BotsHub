#CS ===========================================================================
; Author: GitHub Copilot (Feathers Sin/Derv prototype)
; Based on: Feathers.au3 original route/flow
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
Global Const $FEATHERS_SIN_DERV_SKILLBAR = 'Owpk8djUKrq0AW1Vzl2W33BEBUNI'
Global Const $FEATHERS_SIN_DERV_FARM_DURATION = (8 * 60 + 20) * 1000
Global Const $FEATHERS_SIN_DERV_WEAPON_SET = 4
Global Const $FEATHERS_SIN_DERV_RECOVER_TARGET_ENERGY = 37
Global Const $FEATHERS_SIN_DERV_RECOVER_TARGET_HP = 455
Global Const $FEATHERS_SIN_DERV_RECOVER_TIMEOUT_MS = 30000
Global Const $FEATHERS_SIN_DERV_ONSLAUGHT_UPKEEP_BUFFER_MS = 1200
Global Const $FEATHERS_SIN_DERV_ONSLAUGHT_UPKEEP_TIMER_MS = 11000
Global Const $FEATHERS_SIN_DERV_ONSLAUGHT_LOG_THROTTLE_MS = 3000
Global Const $FEATHERS_SIN_DERV_UPKEEP_SOD_BUFFER_MS = 5000
Global Const $FEATHERS_SIN_DERV_UPKEEP_WOP_BUFFER_MS = 5000
Global Const $FEATHERS_SIN_DERV_UPKEEP_CA_BUFFER_MS = 3500
Global Const $FEATHERS_SIN_DERV_FARM_INFORMATIONS = 'Feathers Sin/Derv prototype based on original Derv route.' & @CRLF _
	& 'Uses Onslaught scythe pressure with minimal logic changes from original Feathers.'

; Skill slot mapping for current Sin/Derv build:
; 1 Chilling Victory
; 2 Grenths Fingers
; 3 Eremites Attack
; 4 Onslaught
; 5 Grenths Aura
; 6 Shroud of Distress
; 7 Way of Perfection
; 8 Critical Agility
Global Const $FEATHERS_SIN_DERV_CHILLING_VICTORY = 1
Global Const $FEATHERS_SIN_DERV_GRENTHS_FINGERS = 2
Global Const $FEATHERS_SIN_DERV_EREMITES_ATTACK = 3
Global Const $FEATHERS_SIN_DERV_ONSLAUGHT = 4
Global Const $FEATHERS_SIN_DERV_GRENTHS_AURA = 5
Global Const $FEATHERS_SIN_DERV_SHROUD_OF_DISTRESS = 6
Global Const $FEATHERS_SIN_DERV_WAY_OF_PERFECTION = 7
Global Const $FEATHERS_SIN_DERV_CRITICAL_AGILITY = 8

Global Const $FEATHERS_SIN_DERV_MODELID_SENSALI_CLAW = 3995
Global Const $FEATHERS_SIN_DERV_MODELID_SENSALI_DARKFEATHER = 3997
Global Const $FEATHERS_SIN_DERV_MODELID_SENSALI_CUTTER = 3999

Global $feathers_sin_derv_farm_setup = False
Global $feathers_sin_derv_upkeep_enabled = False
Global $feathers_sin_derv_first_spot_sprint_enabled = False
Global $feathers_sin_derv_first_spot_onslaught_casted_once = False
Global $feathers_sin_derv_first_spot_onslaught_timer = TimerInit()
Global $feathers_sin_derv_first_spot_onslaught_log_timer = TimerInit()
Global $feathers_sin_derv_first_spot_sprint_logged_start = False


Func FeathersFarmSinDerv()
	If Not $feathers_sin_derv_farm_setup And SetupFeathersSinDervFarm() == $FAIL Then Return $PAUSE
	$feathers_sin_derv_upkeep_enabled = False
	$feathers_sin_derv_first_spot_sprint_enabled = True
	$feathers_sin_derv_first_spot_onslaught_casted_once = False
	$feathers_sin_derv_first_spot_onslaught_timer = TimerInit()
	$feathers_sin_derv_first_spot_onslaught_log_timer = TimerInit()
	$feathers_sin_derv_first_spot_sprint_logged_start = False

	FeathersSinDervGoToJayaBluffs()
	Local $result = FeathersSinDervFarmLoop()
	ResignAndReturnToOutpost($ID_SEITUNG_HARBOR)
	Return $result
EndFunc


Func SetupFeathersSinDervFarm()
	Info('Setting up Feathers Sin/Derv farm')
	If TravelToOutpost($ID_SEITUNG_HARBOR, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerFeathersSinDervFarm() == $FAIL Then Return $FAIL
	LeaveParty()

	Info('Entering Jaya Bluffs')
	UseCitySpeedBoost()
	Local $me = GetMyAgent()
	If GetDistanceToPoint($me, 17300, 17300) > 5000 Then MoveTo(17000, 12400)
	If GetDistanceToPoint($me, 17300, 17300) > 4400 Then MoveTo(19000, 13450)
	If GetDistanceToPoint($me, 17300, 17300) > 1800 Then MoveTo(18750, 16000)

	FeathersSinDervGoToJayaBluffs()
	MoveTo(10500, -13100)
	Move(10970, -13360)
	RandomSleep(1000)
	WaitMapLoading($ID_SEITUNG_HARBOR, 10000, 2000)
	$feathers_sin_derv_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerFeathersSinDervFarm()
	Info('Setting up Sin/Derv player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_ASSASSIN Then
		Error('Should run this farm as assassin')
		Return $FAIL
	EndIf

	LoadSkillTemplate($FEATHERS_SIN_DERV_SKILLBAR)
	RandomSleep(250)
	ChangeWeaponSet($FEATHERS_SIN_DERV_WEAPON_SET)
	RandomSleep(120)
	Return $SUCCESS
EndFunc


Func FeathersSinDervGoToJayaBluffs()
	TravelToOutpost($ID_SEITUNG_HARBOR, $district_name)
	While GetMapID() <> $ID_JAYA_BLUFFS
		Info('Moving to Jaya Bluffs')
		MoveTo(17300, 17300)
		Move(16800, 17550)
		RandomSleep(1000)
		WaitMapLoading($ID_JAYA_BLUFFS, 10000, 2000)
	WEnd
EndFunc


Func FeathersSinDervFarmLoop()
	If GetMapID() <> $ID_JAYA_BLUFFS Then Return $FAIL

	Info('Running to Sensali.')
	UseConsumable($ID_BIRTHDAY_CUPCAKE)
	FeathersSinDervMaintainFirstSpotSprint('route_1')
	MoveTo(9000, -12680)
	FeathersSinDervMaintainFirstSpotSprint('route_2')
	MoveTo(7588, -10609)
	FeathersSinDervMaintainFirstSpotSprint('route_3')
	MoveTo(2900, -9700)
	FeathersSinDervMaintainFirstSpotSprint('route_4')
	MoveTo(1540, -6995)
	Info('Farming Sensali (Sin/Derv).')
	If FeathersSinDervRunSpot(-472, -4342, False, 5 * 60 * 1000, False) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-1536, -1686) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(586, -76) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-1556, 2786) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-2229, -815, True, 2 * 60 * 1000) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-5247, -3290) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-6994, -2273) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-5042, -6638) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-11040, -8577) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-10860, -2840) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-14900, -3000) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-12200, 150) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-12500, 4000) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-12111, 1690) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-10303, 4110) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-10500, 5500) == $FAIL Then Return $FAIL
	If FeathersSinDervRunSpot(-9700, 2400) == $FAIL Then Return $FAIL

	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func FeathersSinDervRunSpot($x, $y, $waitForSettle = True, $timeout = 5 * 60 * 1000, $recoverAfter = True)
	If FeathersSinDervMoveKill($x, $y, $waitForSettle, $timeout) == $FAIL Then Return $FAIL
	If $recoverAfter And FeathersSinDervRecoverBetweenSpots() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func FeathersSinDervRecoverBetweenSpots()
	If IsPlayerDead() Then Return $FAIL

	Local $me = GetMyAgent()
	If CountFoesInRangeOfAgent($me, 1200, FeathersSinDervIsSensali) > 0 Then Return $SUCCESS

	Local $previousUpkeep = $feathers_sin_derv_upkeep_enabled
	$feathers_sin_derv_upkeep_enabled = False

	Local $timer = TimerInit()
	While IsPlayerAlive() And TimerDiff($timer) < $FEATHERS_SIN_DERV_RECOVER_TIMEOUT_MS
		$me = GetMyAgent()
		Local $energy = GetEnergy()
		Local $hp = Int(DllStructGetData($me, 'HealthPercent') * DllStructGetData($me, 'MaxHealth'))
		If $energy >= $FEATHERS_SIN_DERV_RECOVER_TARGET_ENERGY And $hp >= $FEATHERS_SIN_DERV_RECOVER_TARGET_HP Then ExitLoop
		Sleep(250)
	WEnd

	$feathers_sin_derv_upkeep_enabled = $previousUpkeep
	If IsPlayerDead() Then Return $FAIL
	Return $SUCCESS
EndFunc


Func FeathersSinDervMoveKill($x, $y, $waitForSettle = True, $timeout = 5 * 60 * 1000)
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

		FeathersSinDervMaintainFirstSpotSprint('move_to_spot')

		If $feathers_sin_derv_upkeep_enabled Then FeathersSinDervMaintainDefense()

		$me = GetMyAgent()
		If DllStructGetData($me, 'HealthPercent') < 0.9 Then
			FeathersSinDervMaintainDefense(True)
		EndIf

		$me = GetMyAgent()
		If CountFoesInRangeOfAgent($me, 1200, FeathersSinDervIsSensali) > 0 Then
			FeathersSinDervKill(False)
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


Func FeathersSinDervKill($waitForSettle = True)
	Local $deadlock
	Local $timeout = 2 * 60 * 1000
	Local $stuckCount = 0

	CheckAndSendStuckCommand()

	If $waitForSettle Then
		If Not FeathersSinDervWaitForSettle() Then Return $FAIL
	EndIf

	CheckAndSendStuckCommand()
	$feathers_sin_derv_upkeep_enabled = True
	FeathersSinDervMaintainDefense(True)
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	ChangeWeaponSet($FEATHERS_SIN_DERV_WEAPON_SET)

	If IsRecharged($FEATHERS_SIN_DERV_ONSLAUGHT) Then UseSkillEx($FEATHERS_SIN_DERV_ONSLAUGHT)
	If IsRecharged($FEATHERS_SIN_DERV_GRENTHS_AURA) Then UseSkillEx($FEATHERS_SIN_DERV_GRENTHS_AURA)
	FeathersSinDervMaintainDefense()

	If GetEnergy() >= 10 Then
		UseSkillEx($FEATHERS_SIN_DERV_CHILLING_VICTORY, $target)
		UseSkillEx($FEATHERS_SIN_DERV_EREMITES_ATTACK, $target)
	EndIf

	$deadlock = TimerInit()
	While CountFoesInRangeOfAgent(GetMyAgent(), 900, FeathersSinDervIsSensali) > 0
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
		FeathersSinDervMaintainDefense()
		If IsRecharged($FEATHERS_SIN_DERV_GRENTHS_AURA) Then UseSkillEx($FEATHERS_SIN_DERV_GRENTHS_AURA)
		If IsRecharged($FEATHERS_SIN_DERV_GRENTHS_FINGERS) And CountFoesInRangeOfAgent(GetMyAgent(), 300, FeathersSinDervIsSensali) > 1 Then UseSkillEx($FEATHERS_SIN_DERV_GRENTHS_FINGERS)
		If IsRecharged($FEATHERS_SIN_DERV_ONSLAUGHT) Then UseSkillEx($FEATHERS_SIN_DERV_ONSLAUGHT)

		If GetEnergy() >= 5 Then
			UseSkillEx($FEATHERS_SIN_DERV_CHILLING_VICTORY, $target)
			UseSkillEx($FEATHERS_SIN_DERV_EREMITES_ATTACK, $target)
		EndIf

		$stuckCount += 1
		If $stuckCount > 100 Then
			$stuckCount = 0
			CheckAndSendStuckCommand()
		EndIf

		Sleep(250)
		Attack($target)
	WEnd

	RandomSleep(500)
	Info('Looting')
	PickUpItems()
	FindAndOpenChests()
	ChangeWeaponSet($FEATHERS_SIN_DERV_WEAPON_SET)
	Return $SUCCESS
EndFunc


Func FeathersSinDervWaitForSettle($timeout = 10000)
	Local $me = GetMyAgent()
	Local $target
	Local $deadlock = TimerInit()

	While CountFoesInRangeOfAgent(-2, 900) == 0 And (TimerDiff($deadlock) < 5000)
		If IsPlayerDead() Then Return False
		If DllStructGetData($me, 'HealthPercent') < 0.7 Then Return True
		FeathersSinDervMaintainDefense()
		Sleep(250)
		$me = GetMyAgent()
		$target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
	WEnd

	If CountFoesInRangeOfAgent($me, 900) == 0 Then Return False

	$deadlock = TimerInit()
	While (GetDistance($me, $target) > $RANGE_NEARBY) And (TimerDiff($deadlock) < $timeout)
		If IsPlayerDead() Then Return False
		If DllStructGetData($me, 'HealthPercent') < 0.7 Then Return True
		FeathersSinDervMaintainDefense()
		Sleep(250)
		$me = GetMyAgent()
		$target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
	WEnd
	Return True
EndFunc


Func FeathersSinDervIsSensali($agent)
	Local $modelID = DllStructGetData($agent, 'ModelID')
	Return $modelID == $FEATHERS_SIN_DERV_MODELID_SENSALI_CLAW _
		Or $modelID == $FEATHERS_SIN_DERV_MODELID_SENSALI_DARKFEATHER _
		Or $modelID == $FEATHERS_SIN_DERV_MODELID_SENSALI_CUTTER
EndFunc


Func FeathersSinDervMaintainDefense($forceShroud = False)
	If Not $feathers_sin_derv_upkeep_enabled Then Return
	$feathers_sin_derv_first_spot_sprint_enabled = False

	Local $sodRemaining = FeathersSinDervGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)
	Local $wopRemaining = FeathersSinDervGetBestEffectTimeRemaining($ID_WAY_OF_PERFECTION)
	Local $caRemaining = FeathersSinDervGetBestEffectTimeRemaining($ID_CRITICAL_AGILITY)

	If $forceShroud Or $sodRemaining <= $FEATHERS_SIN_DERV_UPKEEP_SOD_BUFFER_MS Then
		If IsRecharged($FEATHERS_SIN_DERV_SHROUD_OF_DISTRESS) Then UseSkillEx($FEATHERS_SIN_DERV_SHROUD_OF_DISTRESS)
	EndIf

	If $wopRemaining <= $FEATHERS_SIN_DERV_UPKEEP_WOP_BUFFER_MS Then
		If IsRecharged($FEATHERS_SIN_DERV_WAY_OF_PERFECTION) Then UseSkillEx($FEATHERS_SIN_DERV_WAY_OF_PERFECTION)
	EndIf

	If $caRemaining <= $FEATHERS_SIN_DERV_UPKEEP_CA_BUFFER_MS Then
		If IsRecharged($FEATHERS_SIN_DERV_CRITICAL_AGILITY) Then UseSkillEx($FEATHERS_SIN_DERV_CRITICAL_AGILITY)
	EndIf
EndFunc


Func FeathersSinDervMaintainFirstSpotSprint($context = '')
	If Not $feathers_sin_derv_first_spot_sprint_enabled Then Return

	If Not $feathers_sin_derv_first_spot_sprint_logged_start Then
		Info('First-spot sprint active: maintaining Onslaught until upkeep starts')
		$feathers_sin_derv_first_spot_sprint_logged_start = True
	EndIf

	Local $onslaughtRemaining = FeathersSinDervGetBestEffectTimeRemaining($ID_ONSLAUGHT, $ID_ONSLAUGHT_PVP)
	Local $needOnslaught = False
	If Not $feathers_sin_derv_first_spot_onslaught_casted_once Then
		$needOnslaught = True
	ElseIf $onslaughtRemaining <= $FEATHERS_SIN_DERV_ONSLAUGHT_UPKEEP_BUFFER_MS Then
		$needOnslaught = True
	ElseIf TimerDiff($feathers_sin_derv_first_spot_onslaught_timer) >= $FEATHERS_SIN_DERV_ONSLAUGHT_UPKEEP_TIMER_MS Then
		$needOnslaught = True
	EndIf

	If Not $needOnslaught Then Return

	If IsRecharged($FEATHERS_SIN_DERV_ONSLAUGHT) Then
		Info('First-spot sprint: casting Onslaught' & ($context == '' ? '' : ' (' & $context & ')'))
		UseSkillEx($FEATHERS_SIN_DERV_ONSLAUGHT)
		$feathers_sin_derv_first_spot_onslaught_casted_once = True
		$feathers_sin_derv_first_spot_onslaught_timer = TimerInit()
		$feathers_sin_derv_first_spot_onslaught_log_timer = TimerInit()
	ElseIf TimerDiff($feathers_sin_derv_first_spot_onslaught_log_timer) >= $FEATHERS_SIN_DERV_ONSLAUGHT_LOG_THROTTLE_MS Then
		Info('First-spot sprint: Onslaught not recharged yet' & ($context == '' ? '' : ' (' & $context & ')'))
		$feathers_sin_derv_first_spot_onslaught_log_timer = TimerInit()
	EndIf
EndFunc


Func FeathersSinDervGetBestEffectTimeRemaining($skillID1, $skillID2 = 0)
	Local $v1 = FeathersSinDervNormalizeEffectTimeMs(GetEffectTimeRemaining($skillID1))
	If $skillID2 == 0 Then Return $v1
	Local $v2 = FeathersSinDervNormalizeEffectTimeMs(GetEffectTimeRemaining($skillID2))
	Return $v2 > $v1 ? $v2 : $v1
EndFunc


Func FeathersSinDervNormalizeEffectTimeMs($value)
	If $value <= 0 Then Return 0
	If $value < 100 Then Return Int($value * 1000)
	Return Int($value)
EndFunc
