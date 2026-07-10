#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Contributor: Gahais
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
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'
#include '../utilities/SupportTeam.au3'
#include '../utilities/OmniFarmer.au3'
#include 'Pongmei.au3'

; Possible improvements :


; ==== Constants ====
Global Const $TASCA_DERVISH_CHESTRUNNER_SKILLBAR = 'OgejwyezHT8I6MHQ3l0kNQ4OIQ'
Global Const $TASCA_ASSASSIN_CHESTRUNNER_SKILLBAR = 'OwBj4xf84Q8I6MHQ3l0kNQ4OIQ'
Global Const $TASCA_MESMER_CHESTRUNNER_SKILLBAR = 'OQdTAmP7ZiHRn5A6ukmsBC3BBC'
Global Const $TASCA_ELEMENTALIST_CHESTRUNNER_SKILLBAR = 'OgdTw4P7HiHRn5A6ukmsBC3BBC'
Global Const $TASCA_MONK_CHESTRUNNER_SKILLBAR = 'OwcTAnP7ZiHRn5A6ukmsBC3BBC'
Global Const $TASCA_NECROMANCER_CHESTRUNNER_SKILLBAR = 'OAdT8Z/YYiHRn5A6ukmsBC3BBC'
Global Const $TASCA_RITUALIST_CHESTRUNNER_SKILLBAR = 'OAej8xeM5Q8I6MHQ3l0kNQ4OIQ'

Global Const $TASCA_CHESTRUN_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 16 in Mysticism if playing Dervish' & @CRLF _
	& '- 3 in Deadly Arts' & @CRLF _
	& '- A staff +20e and +20% enchantment duration' & @CRLF _
	& '- caster weapons on all heroes' & @CRLF _
	& '- Windwalker insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
; Average duration ~ 3m
Global Const $TASCA_FARM_DURATION = (3 * 60) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($TASCA_DWARVEN_STABILITY) is better than UseSkillEx(1))
Global Const $TASCA_DEADLY_PARADOX		= 1
Global Const $TASCA_SHADOWFORM			= 2
Global Const $TASCA_SHROUD_OF_DISTRESS	= 3
Global Const $TASCA_DWARVEN_STABILITY	= 4
Global Const $TASCA_I_AM_UNSTOPPABLE	= 5
Global Const $TASCA_DARK_ESCAPE			= 6
Global Const $TASCA_DEATHS_CHARGE		= 7
Global Const $TASCA_HEART_OF_SHADOW		= 8

Global Const $TASCA_CHEST_RANGE = 1.5 * $RANGE_SPELLCAST

Global Const $TASCA_HERO_KAHMU_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $TASCA_HERO_MELONNI_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $TASCA_HERO_MOX_TEMPLATE = 'OgChoyz9FAAAAAAAAAAAAA'
Global Const $TASCA_HERO_TAHLKORA_TEMPLATE = 'Owohoyz9FAAAAAAAAAAAAA'
Global Const $TASCA_HERO_MORGAHN_TEMPLATE = 'OQijEqmMKO0YAAAAAAAAAAAAAA'
Global Const $TASCA_HERO_MOW_TEMPLATE = 'OAlkUwG4RZmDNGAAAAAAAAAAAAA'
Global Const $TASCA_HERO_OLIAS_TEMPLATE = 'OAlkUwG4RZmDNGAAAAAAAAAAAAA'

Global Const $TASCA_HERO_KAHMU_INDEX = 1
Global Const $TASCA_HERO_MELONNI_INDEX = 2
Global Const $TASCA_HERO_MOX_INDEX = 3
Global Const $TASCA_HERO_TAHLKORA_INDEX = 4
Global Const $TASCA_HERO_MORGAHN_INDEX = 5
Global Const $TASCA_HERO_MOW_INDEX = 6
Global Const $TASCA_HERO_OLIAS_INDEX = 7
Global Const $TASCA_HERO_SUPPORT_SKILL_SLOT = 1
Global Const $TASCA_HERO_MH_CAST_INTERVAL_MS = 1000
Global Const $TASCA_HERO_CAUTERY_CAST_INTERVAL_MS = 5000
Global Const $TASCA_SUPPORT_DEBUG_VERBOSE = False

Global Const $TASCA_PORTAL_FLAG_FALLBACK_X = -9250
Global Const $TASCA_PORTAL_FLAG_FALLBACK_Y = 19850

Global $tasca_farm_setup = False
Global $tasca_player_profession = $ID_DERVISH
Global $tasca_support_enabled = False
Global $tasca_next_mh_tick = 0
Global $tasca_next_cautery_tick = 0
Global $tasca_mh_rotation_index = 0
Global $tasca_cautery_rotation_index = 0
Global $tasca_kahmu_index = $TASCA_HERO_KAHMU_INDEX
Global $tasca_melonni_index = $TASCA_HERO_MELONNI_INDEX
Global $tasca_mox_index = $TASCA_HERO_MOX_INDEX
Global $tasca_tahlkora_index = $TASCA_HERO_TAHLKORA_INDEX
Global $tasca_morgahn_index = $TASCA_HERO_MORGAHN_INDEX
Global $tasca_mow_index = $TASCA_HERO_MOW_INDEX
Global $tasca_olias_index = $TASCA_HERO_OLIAS_INDEX

;~ Main method to chest farm Tasca
Func TascaChestFarm()
	If Not $tasca_farm_setup And SetupTascaChestFarm() == $FAIL Then Return $PAUSE

	GoToTascasDemise()
	Local $result = TascaChestFarmLoop()
	ResignAndReturnToOutpost($ID_THE_GRANITE_CITADEL)
	Return $result
EndFunc


;~ Tasca chest farm setup
Func SetupTascaChestFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_THE_GRANITE_CITADEL, $district_name) == $FAIL Then Return $FAIL
	UseCitySpeedBoost()
	If SetupPlayerTascaChestFarm() == $FAIL Then Return $FAIL
	If SetupTeamTascaChestFarm() == $FAIL Then Return $FAIL
	SwitchToHardModeIfEnabled()

	GoToTascasDemise()
	MoveTo(-9250, 19850)
	Move(-10000, 18875)
	RandomSleep(1000)
	WaitMapLoading($ID_THE_GRANITE_CITADEL, 10000, 1000)
	$tasca_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerTascaChestFarm()
	Info('Setting up player build skill bar')
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		Case $ID_DERVISH
			$tasca_player_profession = $ID_DERVISH
			LoadSkillTemplate($TASCA_DERVISH_CHESTRUNNER_SKILLBAR)
		Case $ID_ASSASSIN
			$tasca_player_profession = $ID_ASSASSIN
			LoadSkillTemplate($TASCA_ASSASSIN_CHESTRUNNER_SKILLBAR)
		Case $ID_MESMER
			$tasca_player_profession = $ID_MESMER
			LoadSkillTemplate($TASCA_MESMER_CHESTRUNNER_SKILLBAR)
		Case $ID_MONK
			$tasca_player_profession = $ID_MONK
			LoadSkillTemplate($TASCA_MONK_CHESTRUNNER_SKILLBAR)
		Case $ID_ELEMENTALIST
			$tasca_player_profession = $ID_ELEMENTALIST
			LoadSkillTemplate($TASCA_ELEMENTALIST_CHESTRUNNER_SKILLBAR)
		Case $ID_NECROMANCER
			$tasca_player_profession = $ID_NECROMANCER
			LoadSkillTemplate($TASCA_NECROMANCER_CHESTRUNNER_SKILLBAR)
		Case $ID_RITUALIST
			$tasca_player_profession = $ID_RITUALIST
			LoadSkillTemplate($TASCA_RITUALIST_CHESTRUNNER_SKILLBAR)
		Case Else
			; other characters have too few energy
			Warn('Should run this farm as Dervish, Assassin, Mesmer, Monk, Elementalist, Necromancer or Ritualist')
			Return $FAIL
	EndSwitch
	RandomSleep(250)
	Return $SUCCESS
EndFunc


Func SetupTeamTascaChestFarm()
	Info('Setting up fixed support team')
	If TascaEnsureSoloParty() == $FAIL Then
		Warn('Could not reset to solo party before hero setup')
		$tasca_support_enabled = False
		Return $FAIL
	EndIf

	If TascaTryAddSupportHero($ID_KAHMU, 'Kahmu', 2) == $FAIL Then
		$tasca_support_enabled = False
		Return $FAIL
	EndIf
	If TascaTryAddSupportHero($ID_MELONNI, 'Melonni', 3) == $FAIL Then
		$tasca_support_enabled = False
		Return $FAIL
	EndIf
	If TascaTryAddSupportHero($ID_MOX, 'M.O.X.', 4) == $FAIL Then
		$tasca_support_enabled = False
		Return $FAIL
	EndIf
	If TascaTryAddSupportHero($ID_TAHLKORA, 'Tahlkora', 5) == $FAIL Then
		$tasca_support_enabled = False
		Return $FAIL
	EndIf
	If TascaTryAddSupportHero($ID_GENERAL_MORGAHN, 'General Morgahn', 6) == $FAIL Then
		$tasca_support_enabled = False
		Return $FAIL
	EndIf
	If TascaTryAddSupportHero($ID_MASTER_OF_WHISPERS, 'Master of Whispers', 7) == $FAIL Then
		$tasca_support_enabled = False
		Return $FAIL
	EndIf
	If TascaTryAddSupportHero($ID_OLIAS, 'Olias', 8) == $FAIL Then
		$tasca_support_enabled = False
		Return $FAIL
	EndIf

	If Not TascaHasExactSupportTeam() Then
		Warn('Could not set up party correctly. Team composition is invalid. Party=' & GetPartySize())
		$tasca_support_enabled = False
		Return $FAIL
	EndIf

	$tasca_kahmu_index = SupportTeamResolveHeroIndex($ID_KAHMU, $TASCA_HERO_KAHMU_INDEX)
	$tasca_melonni_index = SupportTeamResolveHeroIndex($ID_MELONNI, $TASCA_HERO_MELONNI_INDEX)
	$tasca_mox_index = SupportTeamResolveHeroIndex($ID_MOX, $TASCA_HERO_MOX_INDEX)
	$tasca_tahlkora_index = SupportTeamResolveHeroIndex($ID_TAHLKORA, $TASCA_HERO_TAHLKORA_INDEX)
	$tasca_morgahn_index = SupportTeamResolveHeroIndex($ID_GENERAL_MORGAHN, $TASCA_HERO_MORGAHN_INDEX)
	$tasca_mow_index = SupportTeamResolveHeroIndex($ID_MASTER_OF_WHISPERS, $TASCA_HERO_MOW_INDEX)
	$tasca_olias_index = SupportTeamResolveHeroIndex($ID_OLIAS, $TASCA_HERO_OLIAS_INDEX)

	LoadSkillTemplate($TASCA_HERO_KAHMU_TEMPLATE, $tasca_kahmu_index)
	RandomSleep(150)
	LoadSkillTemplate($TASCA_HERO_MELONNI_TEMPLATE, $tasca_melonni_index)
	RandomSleep(150)
	LoadSkillTemplate($TASCA_HERO_MOX_TEMPLATE, $tasca_mox_index)
	RandomSleep(150)
	LoadSkillTemplate($TASCA_HERO_TAHLKORA_TEMPLATE, $tasca_tahlkora_index)
	RandomSleep(150)
	LoadSkillTemplate($TASCA_HERO_MORGAHN_TEMPLATE, $tasca_morgahn_index)
	RandomSleep(150)
	LoadSkillTemplate($TASCA_HERO_MOW_TEMPLATE, $tasca_mow_index)
	RandomSleep(150)
	LoadSkillTemplate($TASCA_HERO_OLIAS_TEMPLATE, $tasca_olias_index)
	RandomSleep(250)

	DisableAllHeroSkills($tasca_kahmu_index)
	DisableAllHeroSkills($tasca_melonni_index)
	DisableAllHeroSkills($tasca_mox_index)
	DisableAllHeroSkills($tasca_tahlkora_index)
	DisableAllHeroSkills($tasca_morgahn_index)
	DisableAllHeroSkills($tasca_mow_index)
	DisableAllHeroSkills($tasca_olias_index)
	EnableHeroSkillSlot($tasca_kahmu_index, $TASCA_HERO_SUPPORT_SKILL_SLOT)
	EnableHeroSkillSlot($tasca_melonni_index, $TASCA_HERO_SUPPORT_SKILL_SLOT)
	EnableHeroSkillSlot($tasca_mox_index, $TASCA_HERO_SUPPORT_SKILL_SLOT)
	EnableHeroSkillSlot($tasca_tahlkora_index, $TASCA_HERO_SUPPORT_SKILL_SLOT)
	EnableHeroSkillSlot($tasca_morgahn_index, $TASCA_HERO_SUPPORT_SKILL_SLOT)
	EnableHeroSkillSlot($tasca_mow_index, $TASCA_HERO_SUPPORT_SKILL_SLOT)
	EnableHeroSkillSlot($tasca_olias_index, $TASCA_HERO_SUPPORT_SKILL_SLOT)

	ResetTascaSupportScheduler()
	$tasca_support_enabled = True
	Return $SUCCESS
EndFunc


Func TascaEnsureSoloParty($maxWaitMs = 8000)
	Local $timer = TimerInit()
	Local $attempt = 0
	SupportTeamKickAllHeroesByIDSweep()
	KickAllHeroes()
	LeaveParty(False)
	While TimerDiff($timer) < $maxWaitMs
		$attempt += 1
		If GetPartySize() <= 1 Then Return $SUCCESS
		SupportTeamDebug($TASCA_SUPPORT_DEBUG_VERBOSE, 'Tasca reset attempt #' & $attempt & ' party=' & GetPartySize() & ' heroes=' & GetHeroCount())
		SupportTeamKickAllHeroesByIDSweep()
		KickAllHeroes()
		LeaveParty(False)
		RandomSleep(320)
	WEnd
	Warn('Solo-party reset timeout. Party=' & GetPartySize() & ', heroes=' & GetHeroCount())
	Return $FAIL
EndFunc


Func TascaTryAddSupportHero($heroID, $heroName, $expectedSize)
	For $i = 1 To 6
		If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
		AddHero($heroID)
		RandomSleep(420)
		If GetPartySize() >= $expectedSize Then Return $SUCCESS
	Next
	Warn('Could not add support hero ' & $heroName & '. Party size=' & GetPartySize())
	Return $FAIL
EndFunc


Func TascaHasExactSupportTeam()
	Local $requiredHeroes[] = [$ID_KAHMU, $ID_MELONNI, $ID_MOX, $ID_TAHLKORA, $ID_GENERAL_MORGAHN, $ID_MASTER_OF_WHISPERS, $ID_OLIAS]
	Return SupportTeamHasExactHeroes($requiredHeroes, 8)
EndFunc


Func ResetTascaSupportScheduler()
	$tasca_next_mh_tick = 0
	$tasca_next_cautery_tick = 0
	$tasca_mh_rotation_index = 0
	$tasca_cautery_rotation_index = 0
EndFunc


Func FlagTascaSupportHeroesAtPortal()
	If Not $tasca_support_enabled Then Return
	If GetMapID() <> $ID_TASCAS_DEMISE Then Return

	Local $flagX = $TASCA_PORTAL_FLAG_FALLBACK_X
	Local $flagY = $TASCA_PORTAL_FLAG_FALLBACK_Y
	Local $me = GetMyAgent()
	If $me <> Null Then
		$flagX = Int(DllStructGetData($me, 'X'))
		$flagY = Int(DllStructGetData($me, 'Y'))
	EndIf

	CommandHero($tasca_kahmu_index, $flagX, $flagY)
	CommandHero($tasca_melonni_index, $flagX, $flagY)
	CommandHero($tasca_mox_index, $flagX, $flagY)
	CommandHero($tasca_tahlkora_index, $flagX, $flagY)
	CommandHero($tasca_morgahn_index, $flagX, $flagY)
	CommandHero($tasca_mow_index, $flagX, $flagY)
	CommandHero($tasca_olias_index, $flagX, $flagY)
EndFunc


Func TickTascaSupportCasts()
	If Not $tasca_support_enabled Then Return
	If GetMapID() <> $ID_TASCAS_DEMISE Then Return
	Local $mhOrder[] = [$tasca_melonni_index, $tasca_kahmu_index, $tasca_mox_index, $tasca_tahlkora_index]
	Local $cauteryOrder[] = [$tasca_morgahn_index, $tasca_mow_index, $tasca_olias_index]

	If $tasca_next_mh_tick == 0 Or TimerDiff($tasca_next_mh_tick) >= $TASCA_HERO_MH_CAST_INTERVAL_MS Then
		Local $mhCount = UBound($mhOrder)
		For $i = 0 To $mhCount - 1
			Local $mhPos = Mod($tasca_mh_rotation_index + $i, $mhCount)
			Local $mhHero = $mhOrder[$mhPos]
			If IsRecharged($TASCA_HERO_SUPPORT_SKILL_SLOT, $mhHero) Then
				UseHeroSkill($mhHero, $TASCA_HERO_SUPPORT_SKILL_SLOT)
				$tasca_mh_rotation_index = Mod($mhPos + 1, $mhCount)
				$tasca_next_mh_tick = TimerInit()
				ExitLoop
			EndIf
		Next
	EndIf

	If $tasca_next_cautery_tick == 0 Or TimerDiff($tasca_next_cautery_tick) >= $TASCA_HERO_CAUTERY_CAST_INTERVAL_MS Then
		Local $cauteryCount = UBound($cauteryOrder)
		For $i = 0 To $cauteryCount - 1
			Local $cauteryPos = Mod($tasca_cautery_rotation_index + $i, $cauteryCount)
			Local $cauteryHero = $cauteryOrder[$cauteryPos]
			If IsRecharged($TASCA_HERO_SUPPORT_SKILL_SLOT, $cauteryHero) Then
				UseHeroSkill($cauteryHero, $TASCA_HERO_SUPPORT_SKILL_SLOT)
				$tasca_cautery_rotation_index = Mod($cauteryPos + 1, $cauteryCount)
				$tasca_next_cautery_tick = TimerInit()
				ExitLoop
			EndIf
		Next
	EndIf
EndFunc


;~ Move out of outpost into Tasca's Demise
Func GoToTascasDemise()
	TravelToOutpost($ID_THE_GRANITE_CITADEL, $district_name)
	While GetMapID() <> $ID_TASCAS_DEMISE
		Info('Moving to Tascas Demise')
		MoveTo(-10000, 18875)
		Move(-9250, 19850)
		RandomSleep(1000)
		WaitMapLoading($ID_TASCAS_DEMISE, 10000, 2000)
	WEnd
	FlagTascaSupportHeroesAtPortal()
EndFunc


;~ Tasca Chest farm loop
Func TascaChestFarmLoop()
	If FindInInventory($ID_LOCKPICK)[0] == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf

	If GetMapID() <> $ID_TASCAS_DEMISE Then Return $FAIL

	Info('Starting chest run')
	UseConsumable($ID_BIRTHDAY_CUPCAKE, True)
	FlagTascaSupportHeroesAtPortal()
	ResetTascaSupportScheduler()
	TickTascaSupportCasts()
	TascaDefendFunction(0, 0)	; Calling it here to already use shroud of distress and dwarven stability and have enough mana later on
	CommandAll(-11300, 21389)
	TascaSurviveFunction(0, 0)
	Move(-4000, 19000)
	Sleep(10000)

	Local $openedChests = 0
	;ToggleMapping(2)
	TascaChestRun(-2000, 17500)
	TascaChestRun(1000, 16500)
	Info('#1/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(3000, 15000)
	TascaChestRun(5900, 14500)
	Local $annoyingChest = ScanForChests(2000, True, 5500, 18000)
	Notice('Bonus chest ? ' & ($annoyingChest <> Null))
	TascaChestRun(6750, 14500)
	Info('#2/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(8000, 15000)
	TascaChestRun(9500, 16000)
	TascaChestRun(10500, 18000)
	Info('#3/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(11500, 19500)
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(12500, 21000)
	; Very far chests here, spirit range is needed
	Info('#4/13')
	$openedChests += FindAndOpenChests($RANGE_SPIRIT, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(13000, 23500)
	Info('#5/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(12000, 25000)
	Info('#6/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(11500, 26000)
	Info('#7/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(9750, 26750)
	Info('#8/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(7750, 26125)
	Info('#9/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(6500, 27500)
	Info('#10/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(5000, 28000)
	; Chest can be all the way north of the map - need extreme range here
	$openedChests += FindAndOpenChests($RANGE_SPIRIT + 500, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(4000, 27000)
	; Chest can be all the way west of the map - need extreme range here
	Info('#11/13')
	$openedChests += FindAndOpenChests($RANGE_SPIRIT + 500, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(4000, 26000)
	$openedChests += FindAndOpenChests($RANGE_SPIRIT, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(5000, 25000)
	TascaChestRun(6000, 22000)
	Info('#12/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(4500, 21500)
	If ($annoyingChest == Null) Then $annoyingChest = ScanForChests(2000, True, 5500, 18000)
	Notice('Bonus chest ? ' & ($annoyingChest <> Null))
	TascaChestRun(3000, 21500)
	Info('#13/13')
	$openedChests += FindAndOpenChests($RANGE_SPIRIT, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0

	If ($annoyingChest <> Null) Then
		TascaChestRun(6000, 21500)
		TascaChestRun(7000, 20500)
		Info('#Bonus chest')
		$annoyingChest = ScanForChests(2000, True, 5500, 18000)
		Local $target = GetTargetToEscapeWithDeathsCharge(DllStructGetData($annoyingChest, 'X'), DllStructGetData($annoyingChest, 'Y'))
		If $target <> Null Then UseSkillEx($TASCA_DEATHS_CHARGE, $target)
		$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaSurviveFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
		RandomSleep(1000)
	EndIf

	;ToggleMapping()
	Info('Opened ' & $openedChests & ' chests.')
	Return ($openedChests > 0) Or IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Main function for chest run
Func TascaChestRun($X, $Y)
	If IsPlayerDead() Then Return $FAIL

	Move($X, $Y)
	Local $blockedCounter = 0
	Local $me = GetMyAgent()
	Local $energy
	While GetDistanceToPoint($me, $X, $Y) > 150 And $blockedCounter < 20
		TickTascaSupportCasts()
		If Not IsPlayerMoving() Then
			$blockedCounter += 1
			Move($X, $Y)
		EndIf

		TascaSurviveFunction($X, $Y)
		; Energy usage becomes too heavy if we start using Death's Charge as a speedup
		;If GetEnergy() >= 5 And IsRecharged($TASCA_DEATHS_CHARGE) Then
		;	Local $target = GetTargetForDeathsCharge($X, $Y, 700)
		;	If $target <> Null Then UseSkillEx($TASCA_DEATHS_CHARGE, $target)
		;EndIf

		; We only start unblocking after 10 times 250 ms which is 2.5 s -> that's because knockdown lasts 2s
		If $blockedCounter > 10 And GetEnergy() >= 10 Then
			Local $target = GetTargetToEscapeWithDeathsCharge($X, $Y)
			If $target <> Null And IsRecharged($TASCA_DEATHS_CHARGE) Then
				UseSkillEx($TASCA_DEATHS_CHARGE, $target)
				$blockedCounter = 0
			ElseIf IsRecharged($TASCA_HEART_OF_SHADOW) Then
				Local $npc = GetNPCInTheBack($X, $Y)
				If $npc == Null Then $npc = $me
				UseSkillEx($TASCA_HEART_OF_SHADOW, $npc)
				$blockedCounter = 0
			EndIf
		EndIf

		RandomSleep(250)
		$me = GetMyAgent()
		If IsPlayerDead() Then Return $FAIL
	WEnd
	Return $SUCCESS
EndFunc


;~ Get a foe close enough to use Death's Charge on and as close as possible to coordinates
Func GetTargetToEscapeWithDeathsCharge($X, $Y)
	Local $targetDistance = 999999
	Local $target = Null
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
	If Not IsArray($foes) Or UBound($foes) <= 0 Then Return Null
	For $foe In $foes
		Local $distance = GetDistanceToPoint($foe, $X, $Y)
		If $distance < $targetDistance Then
			$target = $foe
			$targetDistance = $distance
		EndIf
	Next
	Return $target
EndFunc


;~ Function to unblocked when opening chests
Func UnblockWhenOpeningChests()
	If IsRecharged($TASCA_HEART_OF_SHADOW) Then
		Local $target = GetNearestEnemyToAgent(GetMyAgent())
		If $target == Null Then $target = GetMyAgent()
		UseSkillEx($TASCA_HEART_OF_SHADOW, $target)
	ElseIf IsRecharged($TASCA_DEATHS_CHARGE) Then
		Local $target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, Null, Null, $RANGE_SPELLCAST)
		If $target <> Null Then UseSkillEx($TASCA_DEATHS_CHARGE, $target)
	EndIf
EndFunc


;~ Wrapper for TascaSurviveFunction to be used in FindAndOpenChests
Func TascaSurviveFunctionForChests()
	Return TascaSurviveFunction(0, 0)
EndFunc


;~ Use defensive skills while opening chests
Func TascaDefendFunction($X, $Y)
	TickTascaSupportCasts()Func TascaSurviveFunction($X, $Y)
	; Using timers here reduce DllCalls and make bot more reactive
	Local Static $timer_ShroudOfDistress = Null
	Local Static $timer_Shadowform = Null
	Local Static $timer_DwarvenStability = Null

	Local $me = GetMyAgent()
	Local $target = GetNearestEnemyToAgent($me)
	If ($timer_Shadowform == Null Or TimerDiff($timer_Shadowform) > 19500) Then
		Local $enemiesAreNear = GetDistance($me, $target) < $RANGE_SPELLCAST
		If $enemiesAreNear Or ($X <> 0 And AreFoesInFront($X, $Y)) Then
			If $enemiesAreNear And IsRecharged($TASCA_I_AM_UNSTOPPABLE) Then UseSkillEx($TASCA_I_AM_UNSTOPPABLE)
			While IsPlayerAlive() And GetEnergy() < 20 And $enemiesAreNear
				Sleep(250)
				$target = GetNearestEnemyToAgent($me)
				$enemiesAreNear = GetDistance($me, $target) < $RANGE_SPELLCAST
			WEnd
			AdlibRegister('UseDeadlyParadox', 750)
			While IsPlayerAlive() And IsRecharged($TASCA_SHADOWFORM)
				UseSkillEx($TASCA_SHADOWFORM, $me)
				PingSleep(50)
			WEnd
			$timer_Shadowform = TimerInit()
			PingSleep(50)
			If ($timer_DwarvenStability == Null Or TimerDiff($timer_DwarvenStability) > 34000) And GetEnergy() >= 5 Then
				UseSkillEx($TASCA_DWARVEN_STABILITY)
				$timer_DwarvenStability = TimerInit()
				PingSleep(50)
			EndIf
			If (GetEnergy() >= 5) Then UseSkillEx($TASCA_DARK_ESCAPE)
		EndIf
	EndIf
	If ($timer_ShroudOfDistress == Null Or TimerDiff($timer_ShroudOfDistress) > 62000) And GetEnergy() >= 10 Then
		If (GetEnergy() >= 10) Then
			UseSkillEx($TASCA_SHROUD_OF_DISTRESS)
			$timer_ShroudOfDistress = TimerInit()
		EndIf
	EndIf
EndFunc


;~ Use Whirling Defense skill
Func UseDeadlyParadox()
	While IsPlayerAlive() And IsRecharged($TASCA_DEADLY_PARADOX)
		UseSkillEx($TASCA_DEADLY_PARADOX)
		Sleep(50)
	WEnd
	AdlibUnRegister('UseDeadlyParadox')
EndFunc