#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Contributor: Gahais
; Adaptation: GitHub Copilot (Assassin variant)
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
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'
#include '../utilities/SupportTeam.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $PONGMEI_SIN_CHESTRUNNER_SKILLBAR = 'OwVkMYe7HPG0d5EUDEuDCENJPiOD'
Global Const $PONGMEI_SIN_CHESTRUN_INFORMATIONS = 'Assassin Pongmei chest run variant.' & @CRLF _
	& 'Skill 2/3 movement pattern:' & @CRLF _
	& '- Dash' & @CRLF _
	& '- ~3s later Dark Escape when ready' & @CRLF _
	& '- Then Dash again after Dark Escape movement window'
; Average duration ~ 4m20s
Global Const $PONGMEI_SIN_FARM_DURATION = (4 * 60 + 20) * 1000

; Skill numbers
Global Const $PONGMEI_SIN_DWARVEN_STABILITY = 1
Global Const $PONGMEI_SIN_DASH = 2
Global Const $PONGMEI_SIN_DARK_ESCAPE = 3
Global Const $PONGMEI_SIN_DEATHS_CHARGE = 4
Global Const $PONGMEI_SIN_HEART_OF_SHADOW = 5
Global Const $PONGMEI_SIN_I_AM_UNSTOPPABLE = 6
Global Const $PONGMEI_SIN_DEADLY_PARADOX = 7
Global Const $PONGMEI_SIN_SHADOWFORM = 8

Global Const $PONGMEI_SIN_ID_PARAGON_MERCENARY_HERO = $ID_MERCENARY_HERO_5
Global Const $PONGMEI_SIN_ID_KAHMU = $ID_KAHMU
Global Const $PONGMEI_SIN_ID_MELONNI = $ID_MELONNI
Global Const $PONGMEI_SIN_ID_MOX = $ID_MOX
Global Const $PONGMEI_SIN_ID_TAHLKORA = $ID_TAHLKORA
Global Const $PONGMEI_SIN_ID_MORGAHN = $ID_GENERAL_MORGAHN
Global Const $PONGMEI_SIN_ID_MOW = $ID_MASTER_OF_WHISPERS
Global Const $PONGMEI_SIN_ID_OLIAS = $ID_OLIAS

Global Const $PONGMEI_SIN_KAHMU_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $PONGMEI_SIN_MELONNI_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $PONGMEI_SIN_MOX_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $PONGMEI_SIN_TAHLKORA_TEMPLATE = 'Owohoyz9FAAAAAAAAAAAAA'
Global Const $PONGMEI_SIN_MORGAHN_TEMPLATE = 'OQijEqmMKO0YAAAAAAAAAAAAAA'
Global Const $PONGMEI_SIN_MOW_TEMPLATE = 'OAlkUwG4RZmDNGAAAAAAAAAAAAA'
Global Const $PONGMEI_SIN_OLIAS_TEMPLATE = 'OAlkUwG4RZmDNGAAAAAAAAAAAAA'

Global Const $PONGMEI_SIN_HERO_KAHMU_INDEX = 1
Global Const $PONGMEI_SIN_HERO_MELONNI_INDEX = 2
Global Const $PONGMEI_SIN_HERO_MOX_INDEX = 3
Global Const $PONGMEI_SIN_HERO_TAHLKORA_INDEX = 4
Global Const $PONGMEI_SIN_HERO_MORGAHN_INDEX = 5
Global Const $PONGMEI_SIN_HERO_MOW_INDEX = 6
Global Const $PONGMEI_SIN_HERO_OLIAS_INDEX = 7
Global Const $PONGMEI_SIN_HERO_SUPPORT_SKILL = 1

Global Const $PONGMEI_SIN_PORTAL_FLAG_X = 25366
Global Const $PONGMEI_SIN_PORTAL_FLAG_Y = 1524
Global Const $PONGMEI_SIN_PORTAL_FLAG_VERIFY_RANGE = 380
Global Const $PONGMEI_SIN_PORTAL_FLAG_MAX_RETRIES = 10
Global Const $PONGMEI_SIN_MH_CAST_INTERVAL_MS = 1000
Global Const $PONGMEI_SIN_CAUTERY_CAST_INTERVAL_MS = 5000
Global Const $PONGMEI_SIN_SUPPORT_DEBUG_VERBOSE = False

Global $pongmei_sin_farm_setup = False
Global $pongmei_sin_support_enabled = False
Global $pongmei_sin_next_mh_tick = 0
Global $pongmei_sin_next_cautery_tick = 0
Global $pongmei_sin_mh_rotation_index = 0
Global $pongmei_sin_cautery_rotation_index = 0
Global $pongmei_sin_kahmu_index = $PONGMEI_SIN_HERO_KAHMU_INDEX
Global $pongmei_sin_melonni_index = $PONGMEI_SIN_HERO_MELONNI_INDEX
Global $pongmei_sin_mox_index = $PONGMEI_SIN_HERO_MOX_INDEX
Global $pongmei_sin_tahlkora_index = $PONGMEI_SIN_HERO_TAHLKORA_INDEX
Global $pongmei_sin_morgahn_index = $PONGMEI_SIN_HERO_MORGAHN_INDEX
Global $pongmei_sin_mow_index = $PONGMEI_SIN_HERO_MOW_INDEX
Global $pongmei_sin_olias_index = $PONGMEI_SIN_HERO_OLIAS_INDEX
Global $pongmei_sin_portal_anchor_x = 0
Global $pongmei_sin_portal_anchor_y = 0


Func PongmeiSinChestFarm()
	If Not $pongmei_sin_farm_setup Then SetupPongmeiSinChestFarm()

	GoToPongmeiValleySin()
	Local $result = PongmeiSinChestFarmLoop()
	ResignAndReturnToOutpost($ID_BOREAS_SEABED)
	Return $result
EndFunc


Func SetupPongmeiSinChestFarm()
	Info('Setting up Sin farm')
	TravelToOutpost($ID_BOREAS_SEABED, $district_name)

	SetupPlayerPongmeiSinChestFarm()
	SetupTeamPongmeiSinChestFarm()

	SwitchMode($ID_NORMAL_MODE)
	$pongmei_sin_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerPongmeiSinChestFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
		LoadSkillTemplate($PONGMEI_SIN_CHESTRUNNER_SKILLBAR)
		RandomSleep(250)
	Else
		Warn('Should run this farm as assassin')
	EndIf
EndFunc


Func SetupTeamPongmeiSinChestFarm()
	Info('Setting up fixed support team for Sin chest run')
	SupportTeamKickAllHeroesByIDSweep()
	LeaveParty()
	AddHero($PONGMEI_SIN_ID_KAHMU)
	AddHero($PONGMEI_SIN_ID_MELONNI)
	AddHero($PONGMEI_SIN_ID_MOX)
	AddHero($PONGMEI_SIN_ID_TAHLKORA)
	AddHero($PONGMEI_SIN_ID_MORGAHN)
	AddHero($PONGMEI_SIN_ID_MOW)
	AddHero($PONGMEI_SIN_ID_OLIAS)
	RandomSleep(500)
	Local $requiredHeroes[] = [$PONGMEI_SIN_ID_KAHMU, $PONGMEI_SIN_ID_MELONNI, $PONGMEI_SIN_ID_MOX, $PONGMEI_SIN_ID_TAHLKORA, $PONGMEI_SIN_ID_MORGAHN, $PONGMEI_SIN_ID_MOW, $PONGMEI_SIN_ID_OLIAS]
	If Not SupportTeamHasExactHeroes($requiredHeroes, 8) Then
		Warn('Party not set up correctly. Team size different than 8')
		$pongmei_sin_support_enabled = False
		Return $FAIL
	EndIf

	$pongmei_sin_kahmu_index = SupportTeamResolveHeroIndex($PONGMEI_SIN_ID_KAHMU, $PONGMEI_SIN_HERO_KAHMU_INDEX)
	$pongmei_sin_melonni_index = SupportTeamResolveHeroIndex($PONGMEI_SIN_ID_MELONNI, $PONGMEI_SIN_HERO_MELONNI_INDEX)
	$pongmei_sin_mox_index = SupportTeamResolveHeroIndex($PONGMEI_SIN_ID_MOX, $PONGMEI_SIN_HERO_MOX_INDEX)
	$pongmei_sin_tahlkora_index = SupportTeamResolveHeroIndex($PONGMEI_SIN_ID_TAHLKORA, $PONGMEI_SIN_HERO_TAHLKORA_INDEX)
	$pongmei_sin_morgahn_index = SupportTeamResolveHeroIndex($PONGMEI_SIN_ID_MORGAHN, $PONGMEI_SIN_HERO_MORGAHN_INDEX)
	$pongmei_sin_mow_index = SupportTeamResolveHeroIndex($PONGMEI_SIN_ID_MOW, $PONGMEI_SIN_HERO_MOW_INDEX)
	$pongmei_sin_olias_index = SupportTeamResolveHeroIndex($PONGMEI_SIN_ID_OLIAS, $PONGMEI_SIN_HERO_OLIAS_INDEX)

	LoadSkillTemplate($PONGMEI_SIN_KAHMU_TEMPLATE, $pongmei_sin_kahmu_index)
	RandomSleep(150)
	LoadSkillTemplate($PONGMEI_SIN_MELONNI_TEMPLATE, $pongmei_sin_melonni_index)
	RandomSleep(150)
	LoadSkillTemplate($PONGMEI_SIN_MOX_TEMPLATE, $pongmei_sin_mox_index)
	RandomSleep(150)
	LoadSkillTemplate($PONGMEI_SIN_TAHLKORA_TEMPLATE, $pongmei_sin_tahlkora_index)
	RandomSleep(150)
	LoadSkillTemplate($PONGMEI_SIN_MORGAHN_TEMPLATE, $pongmei_sin_morgahn_index)
	RandomSleep(150)
	LoadSkillTemplate($PONGMEI_SIN_MOW_TEMPLATE, $pongmei_sin_mow_index)
	RandomSleep(150)
	LoadSkillTemplate($PONGMEI_SIN_OLIAS_TEMPLATE, $pongmei_sin_olias_index)
	RandomSleep(250)

	DisableAllHeroSkills($pongmei_sin_kahmu_index)
	DisableAllHeroSkills($pongmei_sin_melonni_index)
	DisableAllHeroSkills($pongmei_sin_mox_index)
	DisableAllHeroSkills($pongmei_sin_tahlkora_index)
	DisableAllHeroSkills($pongmei_sin_morgahn_index)
	DisableAllHeroSkills($pongmei_sin_mow_index)
	DisableAllHeroSkills($pongmei_sin_olias_index)
	EnableHeroSkillSlot($pongmei_sin_kahmu_index, $PONGMEI_SIN_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($pongmei_sin_melonni_index, $PONGMEI_SIN_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($pongmei_sin_mox_index, $PONGMEI_SIN_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($pongmei_sin_tahlkora_index, $PONGMEI_SIN_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($pongmei_sin_morgahn_index, $PONGMEI_SIN_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($pongmei_sin_mow_index, $PONGMEI_SIN_HERO_SUPPORT_SKILL)
	EnableHeroSkillSlot($pongmei_sin_olias_index, $PONGMEI_SIN_HERO_SUPPORT_SKILL)

	ResetPongmeiSinHeroSupportScheduler()
	$pongmei_sin_support_enabled = True
	Return $SUCCESS
EndFunc


Func GoToPongmeiValleySin()
	TravelToOutpost($ID_BOREAS_SEABED, $district_name)
	While GetMapID() <> $ID_PONGMEI_VALLEY
		Info('Moving to Pongmei Valley')
		MoveTo(-25366, 1524)
		MoveTo(-26000, 2400)
		Move(-26200, 2800)
		RandomSleep(1000)
		WaitMapLoading($ID_PONGMEI_VALLEY, 10000, 2000)
	WEnd
	CapturePongmeiSinPortalAnchor()
	FlagPongmeiSinSupportHeroesAtPortal()
EndFunc


Func ResetPongmeiSinHeroSupportScheduler()
	$pongmei_sin_next_mh_tick = 0
	$pongmei_sin_next_cautery_tick = 0
	$pongmei_sin_mh_rotation_index = 0
	$pongmei_sin_cautery_rotation_index = 0
EndFunc


Func FlagPongmeiSinSupportHeroesAtPortal()
	If Not $pongmei_sin_support_enabled Then Return
	If GetMapID() <> $ID_PONGMEI_VALLEY Then Return

	Local $flagX = $pongmei_sin_portal_anchor_x
	Local $flagY = $pongmei_sin_portal_anchor_y
	If $flagX == 0 And $flagY == 0 Then
		CapturePongmeiSinPortalAnchor()
		$flagX = $pongmei_sin_portal_anchor_x
		$flagY = $pongmei_sin_portal_anchor_y
	EndIf

	SupportTeamDebug($PONGMEI_SIN_SUPPORT_DEBUG_VERBOSE, 'Pongmei support: flag heroes at portal X=' & $flagX & ' Y=' & $flagY)
	For $i = 1 To $PONGMEI_SIN_PORTAL_FLAG_MAX_RETRIES
		PongmeiSinCommandAllSupportHeroesTo($flagX, $flagY)
		RandomSleep(140)
		If PongmeiSinAreAllSupportHeroesAt($flagX, $flagY, $PONGMEI_SIN_PORTAL_FLAG_VERIFY_RANGE) Then Return
	Next
	Warn('Pongmei support: not all heroes reached portal flag before run start')
EndFunc


Func CapturePongmeiSinPortalAnchor()
	If GetMapID() <> $ID_PONGMEI_VALLEY Then Return
	Local $me = GetMyAgent()
	If $me == Null Then Return
	$pongmei_sin_portal_anchor_x = Int(DllStructGetData($me, 'X'))
	$pongmei_sin_portal_anchor_y = Int(DllStructGetData($me, 'Y'))
	SupportTeamDebug($PONGMEI_SIN_SUPPORT_DEBUG_VERBOSE, 'Pongmei support: captured portal anchor X=' & $pongmei_sin_portal_anchor_x & ' Y=' & $pongmei_sin_portal_anchor_y)
EndFunc


Func PongmeiSinCommandAllSupportHeroesTo($x, $y)
	CommandHero($pongmei_sin_kahmu_index, $x, $y)
	CommandHero($pongmei_sin_melonni_index, $x, $y)
	CommandHero($pongmei_sin_mox_index, $x, $y)
	CommandHero($pongmei_sin_tahlkora_index, $x, $y)
	CommandHero($pongmei_sin_morgahn_index, $x, $y)
	CommandHero($pongmei_sin_mow_index, $x, $y)
	CommandHero($pongmei_sin_olias_index, $x, $y)
EndFunc


Func PongmeiSinAreAllSupportHeroesAt($x, $y, $maxDist)
	If Not PongmeiSinIsHeroAtFlag($pongmei_sin_kahmu_index, $x, $y, $maxDist) Then Return False
	If Not PongmeiSinIsHeroAtFlag($pongmei_sin_melonni_index, $x, $y, $maxDist) Then Return False
	If Not PongmeiSinIsHeroAtFlag($pongmei_sin_mox_index, $x, $y, $maxDist) Then Return False
	If Not PongmeiSinIsHeroAtFlag($pongmei_sin_tahlkora_index, $x, $y, $maxDist) Then Return False
	If Not PongmeiSinIsHeroAtFlag($pongmei_sin_morgahn_index, $x, $y, $maxDist) Then Return False
	If Not PongmeiSinIsHeroAtFlag($pongmei_sin_mow_index, $x, $y, $maxDist) Then Return False
	If Not PongmeiSinIsHeroAtFlag($pongmei_sin_olias_index, $x, $y, $maxDist) Then Return False
	Return True
EndFunc


Func PongmeiSinIsHeroAtFlag($heroIndex, $x, $y, $maxDist)
	If $heroIndex <= 0 Then Return False
	Local $heroAgent = GetAgentByID(GetHeroID($heroIndex))
	If $heroAgent == Null Then Return False
	Return GetDistanceToPoint($heroAgent, $x, $y) <= $maxDist
EndFunc


Func TickPongmeiSinHeroSupportCasts()
	If Not $pongmei_sin_support_enabled Then Return
	If GetMapID() <> $ID_PONGMEI_VALLEY Then Return
	Local $mhOrder[] = [$pongmei_sin_melonni_index, $pongmei_sin_kahmu_index, $pongmei_sin_mox_index, $pongmei_sin_tahlkora_index]
	Local $cauteryOrder[] = [$pongmei_sin_morgahn_index, $pongmei_sin_mow_index, $pongmei_sin_olias_index]

	If $pongmei_sin_next_mh_tick == 0 Or TimerDiff($pongmei_sin_next_mh_tick) >= $PONGMEI_SIN_MH_CAST_INTERVAL_MS Then
		Local $mhCount = UBound($mhOrder)
		For $i = 0 To $mhCount - 1
			Local $mhPos = Mod($pongmei_sin_mh_rotation_index + $i, $mhCount)
			Local $mhHero = $mhOrder[$mhPos]
			If IsRecharged($PONGMEI_SIN_HERO_SUPPORT_SKILL, $mhHero) Then
				SupportTeamDebug($PONGMEI_SIN_SUPPORT_DEBUG_VERBOSE, 'Pongmei support: MH cast hero index=' & $mhHero)
				UseHeroSkill($mhHero, $PONGMEI_SIN_HERO_SUPPORT_SKILL)
				$pongmei_sin_mh_rotation_index = Mod($mhPos + 1, $mhCount)
				$pongmei_sin_next_mh_tick = TimerInit()
				ExitLoop
			EndIf
		Next
	EndIf

	If $pongmei_sin_next_cautery_tick == 0 Or TimerDiff($pongmei_sin_next_cautery_tick) >= $PONGMEI_SIN_CAUTERY_CAST_INTERVAL_MS Then
		Local $cauteryCount = UBound($cauteryOrder)
		For $i = 0 To $cauteryCount - 1
			Local $cauteryPos = Mod($pongmei_sin_cautery_rotation_index + $i, $cauteryCount)
			Local $cauteryHero = $cauteryOrder[$cauteryPos]
			If IsRecharged($PONGMEI_SIN_HERO_SUPPORT_SKILL, $cauteryHero) Then
				SupportTeamDebug($PONGMEI_SIN_SUPPORT_DEBUG_VERBOSE, 'Pongmei support: Cautery cast hero index=' & $cauteryHero)
				UseHeroSkill($cauteryHero, $PONGMEI_SIN_HERO_SUPPORT_SKILL)
				$pongmei_sin_cautery_rotation_index = Mod($cauteryPos + 1, $cauteryCount)
				$pongmei_sin_next_cautery_tick = TimerInit()
				ExitLoop
			EndIf
		Next
	EndIf
EndFunc


Func PongmeiSinChestFarmLoop()
	If FindInInventory($ID_LOCKPICK)[0] == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf

	If GetMapID() <> $ID_PONGMEI_VALLEY Then Return $FAIL
	Info('Starting chest farm run')
	FlagPongmeiSinSupportHeroesAtPortal()
	ResetPongmeiSinHeroSupportScheduler()

	Local $openedChests = 0

	Info('Running to Spot #1/13')
	AssassinRunPongmei(22399, 1144)
	AssassinRunPongmei(20126, 1983)
	AssassinRunPongmei(17760, 266)
	AssassinRunPongmei(15405, -2025)
	AssassinRunPongmei(13314, -1374)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChestsPongmeiSin) ? 1 : 0
	Info('Running to Spot #2/13')
	AssassinRunPongmei(12947, 2289)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChestsPongmeiSin) ? 1 : 0
	Info('Running to Spot #3/13')
	AssassinRunPongmei(11499, 4242)
	AssassinRunPongmei(11839, 5966)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChestsPongmeiSin) ? 1 : 0
	Info('Running to Spot #4/13')
	AssassinRunPongmei(11703, 8854)
	AssassinRunPongmei(8529, 10036)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChestsPongmeiSin) ? 1 : 0
	Info('Running to Spot #5/13')
	AssassinRunPongmei(5485, 11048)
	AssassinRunPongmei(1597, 7802)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChestsPongmeiSin) ? 1 : 0
	Info('Running to Spot #6/13')
	AssassinRunPongmei(0, 5850)
	AssassinRunPongmei(-2223, 5916)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChestsPongmeiSin) ? 1 : 0
	Info('Running to Spot #7/13')
	AssassinRunPongmei(-7113, 4543)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChestsPongmeiSin) ? 1 : 0
	Info('Running to Spot #8/13')
	AssassinRunPongmei(-9318, 1204)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChestsPongmeiSin) ? 1 : 0
	Info('Running to Spot #9/13')
	AssassinRunPongmei(-12821, 2172)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChestsPongmeiSin) ? 1 : 0
	Info('Running to Spot #10/13')
	AssassinRunPongmei(-16938, 5153)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChestsPongmeiSin) ? 1 : 0
	Info('Running to Spot #11/13')
	AssassinRunPongmei(-17706, -1383)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChestsPongmeiSin) ? 1 : 0
	Info('Running to Spot #12/13')
	AssassinRunPongmei(-16347, -5139)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChestsPongmeiSin) ? 1 : 0
	Info('Running to Spot #13/13')
	AssassinRunPongmei(-13876, -5626)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChestsPongmeiSin) ? 1 : 0
	Info('Opened ' & $openedChests & ' chests.')
	Return $openedChests > 0 And IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func AssassinRunPongmei($x, $y)
	Move($x, $y)
	Local $blockedCounter = 0
	Local $me = GetMyAgent()
	Local $energy
	Local Static $lastDashUse = 0
	Local Static $lastDarkEscapeUse = 0

	While GetDistanceToPoint($me, $x, $y) > 100 And $blockedCounter < 15
		TickPongmeiSinHeroSupportCasts()
		If GetEnergy() >= 5 And IsRecharged($PONGMEI_SIN_I_AM_UNSTOPPABLE) And GetEffect($ID_CRIPPLED) <> Null Then UseSkillEx($PONGMEI_SIN_I_AM_UNSTOPPABLE)

		If GetEnergy() >= 5 And IsRecharged($PONGMEI_SIN_DEATHS_CHARGE) Then
			Local $target = GetTargetForDeathsChargePongmeiSin($x, $y, 700)
			If $target <> Null Then UseSkillEx($PONGMEI_SIN_DEATHS_CHARGE, $target)
		EndIf

		If GetEnergy() >= 20 And IsRecharged($PONGMEI_SIN_SHADOWFORM) And AreFoesInFrontPongmeiSin($x, $y) Then
			If IsRecharged($PONGMEI_SIN_I_AM_UNSTOPPABLE) Then UseSkillEx($PONGMEI_SIN_I_AM_UNSTOPPABLE)
			UseSkillEx($PONGMEI_SIN_DEADLY_PARADOX)
			RandomSleep(50)
			UseSkillEx($PONGMEI_SIN_SHADOWFORM)
		EndIf

		; Speed pattern for Sin:
		; 1) Dash
		; 2) ~3s later Dark Escape (when ready)
		; 3) ~16s later Dash (when ready)
		If GetEnergy() >= 5 Then
			If IsRecharged($PONGMEI_SIN_DARK_ESCAPE) And $lastDashUse <> 0 And TimerDiff($lastDashUse) >= 3000 Then
				UseSkillEx($PONGMEI_SIN_DWARVEN_STABILITY)
				RandomSleep(30)
				UseSkillEx($PONGMEI_SIN_DARK_ESCAPE)
				$lastDarkEscapeUse = TimerInit()
			ElseIf IsRecharged($PONGMEI_SIN_DASH) And ($lastDarkEscapeUse == 0 Or TimerDiff($lastDarkEscapeUse) >= 16000) Then
				UseSkillEx($PONGMEI_SIN_DWARVEN_STABILITY)
				RandomSleep(30)
				UseSkillEx($PONGMEI_SIN_DASH)
				$lastDashUse = TimerInit()
			EndIf
		EndIf

		$energy = GetEnergy()

		$me = GetMyAgent()
		If Not IsPlayerMoving() Then
			$blockedCounter += 1
			Move($x, $y)
		EndIf

		If ($blockedCounter > 5 Or GetHealth() < 100) And $energy >= 5 And IsRecharged($PONGMEI_SIN_HEART_OF_SHADOW) Then
			If $blockedCounter > 5 Then $blockedCounter = 0
			Local $npc = GetNPCInTheBackPongmeiSin($x, $y)
			If $npc == Null Then $npc = $me
			UseSkillEx($PONGMEI_SIN_HEART_OF_SHADOW, $npc)
		EndIf

		RandomSleep(250)
		$me = GetMyAgent()
		If IsPlayerDead() Then Return $FAIL
	WEnd
	$me = GetMyAgent()
	If GetDistanceToPoint($me, $x, $y) > 100 Then Return $FAIL
	Return $SUCCESS
EndFunc


Func AreFoesInFrontPongmeiSin($x, $y)
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST + 350)
	If Not IsArray($foes) Or UBound($foes) <= 0 Then Return False
	For $foe In $foes
		If (GetDistanceToPoint($me, $x, $y) - GetDistanceToPoint($foe, $x, $y)) > 0 Then Return True
	Next
	Return False
EndFunc


Func GetNPCInTheBackPongmeiSin($x, $y)
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $npcs = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST)
	If Not IsArray($npcs) Or UBound($npcs) <= 0 Then Return Null
	Local $bestNpc = Null
	Local $minDot = 1

	Local $moveX = $x - $myX
	Local $moveY = $y - $myY
	Local $myMovementVector = Sqrt($moveX ^ 2 + $moveY ^ 2)
	If $myMovementVector = 0 Then Return Null
	$moveX /= $myMovementVector
	$moveY /= $myMovementVector

	For $npc In $npcs
		Local $npcMoveX = DllStructGetData($npc, 'X') - $myX
		Local $npcMoveY = DllStructGetData($npc, 'Y') - $myY
		Local $npcMovementVector = Sqrt($npcMoveX ^ 2 + $npcMoveY ^ 2)
		If $npcMovementVector = 0 Then ContinueLoop
		$npcMoveX /= $npcMovementVector
		$npcMoveY /= $npcMovementVector

		Local $dot = $npcMoveX * $moveX + $npcMoveY * $moveY
		If $dot < $minDot Then
			$minDot = $dot
			$bestNpc = $npc
		EndIf
	Next
	Return $bestNpc
EndFunc


Func GetTargetForDeathsChargePongmeiSin($x, $y, $distance = 700)
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST)
	If Not IsArray($foes) Or UBound($foes) <= 0 Then Return Null
	For $foe In $foes
		If (GetDistanceToPoint($me, $x, $y) - GetDistanceToPoint($foe, $x, $y)) > $distance Then Return $foe
	Next
	Return Null
EndFunc


Func DefendWhileOpeningChestsPongmeiSin()
	TickPongmeiSinHeroSupportCasts()
	Local $nearestFoe = GetNearestEnemyToAgent(GetMyAgent())

	If GetEnergy() >= 5 And IsRecharged($PONGMEI_SIN_I_AM_UNSTOPPABLE) And GetDistance(GetMyAgent(), $nearestFoe) < $RANGE_AREA Then UseSkillEx($PONGMEI_SIN_I_AM_UNSTOPPABLE)
	If GetEnergy() >= 20 And IsRecharged($PONGMEI_SIN_SHADOWFORM) And GetDistance(GetMyAgent(), $nearestFoe) < ($RANGE_SPELLCAST + 200) Then
		UseSkillEx($PONGMEI_SIN_DEADLY_PARADOX)
		RandomSleep(20)
		UseSkillEx($PONGMEI_SIN_SHADOWFORM)
	EndIf
EndFunc
