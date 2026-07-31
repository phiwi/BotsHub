#CS ===========================================================================
; Author: GitHub Copilot (Tunnels Forsaken Custom prototype)
; Based on: TunnelsOfTheForsaken.au3
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

#include '../../lib/GWA2_Headers.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils.au3'
#include '../utilities/SupportTeam.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $TUNNELS_FORSAKEN_CUSTOM_INFORMATIONS = 'Custom Tunnels Forsaken farm for Monk with 3 heroes.' & @CRLF _
	& 'Master of Whispers, Gwen, Xandra.'
Global Const $TUNNELS_FORSAKEN_CUSTOM_DURATION = 40 * 60 * 1000
Global Const $MAX_TUNNELS_FORSAKEN_CUSTOM_DURATION = 60 * 60 * 1000

;~ Global Const $TFC_PLAYER_SKILLBAR = 'OwcT4Y44ZaX0mcB6ewV0NTiBnAA'
;~ Global Const $TFC_PLAYER_SKILLBAR = 'OwcT8Wo6VaXcBKmMgAkRR8N7iAA'
Global Const $TFC_PLAYER_SKILLBAR = 'OwgiAyiMVNNAeNd24DWOBNxMBA'
Global Const $TFC_HERO_ZHED_TEMPLATE = 'OgljgwMpZS0ChDXVfDeD6QLgIDA' ; BSurge

Global Const $TFC_HERO_OGDEN_TEMPLATE = 'OwUUMO3+OoO+sMw94igXdJ1j7KA' 
Global Const $TFC_HERO_GWEN_TEMPLATE = 'OQhkAoC8AGKjbTDwBMd40MwIMHA'
Global Const $TFC_HERO_XANDRA_TEMPLATE = 'OAOjAyhDJPYTnp17xFOhmtkLGA'
Global Const $TFC_HERO_ALTHEA_TEMPLATE = 'OQhkAoB8AGK0LACYeGJAHUGARwFD'
Global Const $TFC_HERO_VEKK_TEMPLATE = 'OgNDwbrvO0iaBJRLWPWJQNPC'
Global Const $TFC_HERO_OLIAS_TEMPLATE = 'OAhkQkG5xEyzdo6VVveTOp5wM5C'
Global Const $TFC_HERO_DUNKORO_TEMPLATE = 'OwAT44HC1xnhXvI3juoLpeoFBA'
Global Const $TFC_HERO_LIVIA_TEMPLATE = 'OANDUspPSyBUBHVKg4BLCaRrEA'
Global Const $TFC_HERO_MOW_TEMPLATE = 'OANDUspPSyBUBHVKgbhLCaR1DA'

Global $tunnels_forsaken_custom_setup = False

Global Const $TFC_HERO2_KEY = "9"
Global Const $TFC_HERO_PANEL_KEYS = "5|6|7|8"

;~ Main method to farm TunnelsOfTheForsaken Custom
Func TunnelsOfTheForsakenCustomFarm()
	If Not $tunnels_forsaken_custom_setup And SetupTunnelsForsakenCustom() == $FAIL Then Return $FAIL

	If RunToTunnelsCustom() == $FAIL Then Return $FAIL
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = TunnelsForsakenCustomFarmLoop()
	AdlibUnregister('TrackPartyStatus')
	TravelToOutpost($ID_PIKEN_SQUARE, $district_name)
	Return $result
EndFunc


Func TunnelsForsakenCustomOpenHeroPanels()
	SupportTeamOpenHeroPanels('Tunnels Custom', $TFC_HERO2_KEY, $TFC_HERO_PANEL_KEYS)
EndFunc


;~ Tunnels Forsaken Custom setup
Func SetupTunnelsForsakenCustom()
	Info('Setting up Tunnels Forsaken Custom farm')
	TravelToOutpost($ID_PIKEN_SQUARE, $district_name)
	SwitchToHardModeIfEnabled()
	AbandonQuest($ID_QUEST_THE_DREAMER_AND_THE_ZEALOT)

	Info('Setting up player Monk build')
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_MONK Then
		Warn('Should run this farm as monk')
		Return $FAIL
	EndIf
	If Not HeroHasTemplate(0, $TFC_PLAYER_SKILLBAR) Then
		LoadSkillTemplate($TFC_PLAYER_SKILLBAR)
		RandomSleep(250)
	EndIf

	If SetupTunnelsForsakenCustomTeam() == $FAIL Then Return $FAIL
	TunnelsForsakenCustomOpenHeroPanels()

	Info('Preparations complete')
	$tunnels_forsaken_custom_setup = True
	Return $SUCCESS
EndFunc


Func SetupTunnelsForsakenCustomTeam()
	Info('Tunnels Forsaken Custom team: Master of Whispers, Gwen, Xandra')
	LeaveParty()
	RandomSleep(200)

	;~ Local $heroIDs[3] = [$ID_MASTER_OF_WHISPERS, $ID_GWEN, $ID_XANDRA]
	;~ Local $heroNames[3] = ['Master of Whispers', 'Gwen', 'Xandra']
	;~ Local $heroTemplates[3] = [$TFC_HERO_MOW_TEMPLATE, $TFC_HERO_GWEN_TEMPLATE, $TFC_HERO_XANDRA_TEMPLATE]
	;~ Local $heroIDs[3] = [$ID_GWEN, $ID_MASTER_OF_WHISPERS, $ID_XANDRA]
	;~ Local $heroIDs[3] = [$ID_GWEN, $ID_GHOST_OF_ALTHEA, $ID_VEKK]
	;~ Local $heroNames[3] = ['Gwen', 'Althea', 'Vekk']
	;~ Local $heroIDs[3] = [$ID_DUNKORO, $ID_OGDEN, $ID_OLIAS]
	;~ Local $heroNames[3] = ['Dunkoro', 'Ogden', 'Olias']
	;~ Local $heroTemplates[3] = [$TFC_HERO_MOW_TEMPLATE, $TFC_HERO_LIVIA_TEMPLATE, $TFC_HERO_OLIAS_TEMPLATE]
	Local $heroIDs[3] = [$ID_DUNKORO, $ID_GWEN, $ID_OLIAS]
	Local $heroNames[3] = ['Dunkoro', 'Gwen', 'Olias']
	Local $heroTemplates[3] = [$TFC_HERO_MOW_TEMPLATE, $TFC_HERO_GWEN_TEMPLATE, $TFC_HERO_OLIAS_TEMPLATE]

	For $i = 0 To 2
		For $attempt = 1 To 5
			If GetHeroNumberByHeroID($heroIDs[$i]) <> Null Then ExitLoop
			AddHero($heroIDs[$i])
			Local $verifyTimer = TimerInit()
			While TimerDiff($verifyTimer) < 2200
				If GetHeroNumberByHeroID($heroIDs[$i]) <> Null Then ExitLoop 2
				RandomSleep(120)
			WEnd
		Next
		If GetHeroNumberByHeroID($heroIDs[$i]) == Null Then
			Warn('Could not add hero ' & $heroNames[$i])
			Return $FAIL
		EndIf
	Next

	If GetPartySize() <> 4 Then
		Warn('Tunnels Forsaken Custom team setup failed: party=' & GetPartySize())
		Return $FAIL
	EndIf

	For $i = 0 To 2
		Local $heroIndex = GetHeroNumberByHeroID($heroIDs[$i])
		If $heroIndex == Null Then
			Warn('Could not find ' & $heroNames[$i] & ' in party')
			Return $FAIL
		EndIf
		If HeroHasTemplate($heroIndex, $heroTemplates[$i]) Then
			Info('TFC ' & $heroNames[$i] & ': template already loaded, skipping')
		Else
			LoadSkillTemplate($heroTemplates[$i], $heroIndex)
			RandomSleep(220)
		EndIf
	Next

	ClearPartyCommands()
	CancelAllHeroes()
	Return $SUCCESS
EndFunc


Func RunToTunnelsCustom()
	TravelToOutpost($ID_PIKEN_SQUARE, $district_name)
	AbandonQuest($ID_QUEST_THE_DREAMER_AND_THE_ZEALOT)
	Info('Making way to portal')
	MoveTo(21030, 9015)
	MoveTo(20255, 8712)
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(20248, 7855)
		Move(20180, 7500)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_THE_BREACH)
	WEnd
	Info('Making way to entrance')
	AdlibRegister('TrackPartyStatus', 10000)
	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 18000, -1700, $RANGE_AREA)
		WaitUntilPartyAlive()
		UseSummoningStone()
		MoveAggroAndKillInRange(21250, 3550, '1', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(18850, -900, '2', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(19200, -4200, '3', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(18000, -1700, '4', $PLAYER_AGGRO_RANGE)
	WEnd
	AdlibUnRegister('TrackPartyStatus')

	$mapLoaded = False
	Info('Going through door')
	While Not $mapLoaded
		MoveTo(17900, -1600)
		Move(17600, -1300)
		Sleep(3000)
		$mapLoaded = WaitMapLoading($ID_TUNNELS_OF_THE_FORSAKEN_LVL_1)
	WEnd
	Return IsRunFailed() ? $FAIL : $SUCCESS
EndFunc


;~ Farm loop
Func TunnelsForsakenCustomFarmLoop()
	ResetFailuresCounter()
	AdlibRegister('TrackPartyStatus', 10000)
	If (ClearTunnelsForsakenCustomFloor1() == $FAIL Or ClearTunnelsForsakenCustomFloor2() == $FAIL Or ClearTunnelsForsakenCustomFloor3() == $FAIL) Then $tunnels_forsaken_custom_setup = False
	AdlibUnRegister('TrackPartyStatus')
	If Not $tunnels_forsaken_custom_setup Then Return $FAIL

	Info('Finished Run')
	Return $SUCCESS
EndFunc


;~ Clear TunnelsOfTheForsaken floor 1
Func ClearTunnelsForsakenCustomFloor1()
	Info('------------------------------------')
	Info('First floor')
	If IsHardmodeEnabled() Then UseConset()

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -8684, 4580, $RANGE_AREA)
		WaitUntilPartyAlive()
		If CheckStuck('TunnelsForsakenCustom Floor 1', $MAX_TUNNELS_FORSAKEN_CUSTOM_DURATION) == $FAIL Then Return $FAIL
		UseMoraleConsumableIfNeeded()
		UseSummoningStone()
		If IsHardmodeEnabled() Then UseConset()
		MoveTo(-15247, -5785)
		MoveAggroAndKillInRange(-13102, -6841, '2', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-11660, -7585, '3', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-7836, -9115, '4', $PLAYER_AGGRO_RANGE)

		Local $questNPC = GetNearestNPCToCoords(-7400, -9462)
		TakeQuest($questNPC, $ID_QUEST_THE_DREAMER_AND_THE_ZEALOT, 0x85B501)

		MoveAggroAndKillInRange(-9672, -3286, '5', $PLAYER_AGGRO_RANGE)
		TFCPickUpElementalKeystone()
		MoveAggroAndKillInRange(-11186, -1788, '6', $PLAYER_AGGRO_RANGE)
		TFCPickUpElementalKeystone()
		MoveAggroAndKillInRange(-10727, -304, '7', $PLAYER_AGGRO_RANGE)
		TFCPickUpElementalKeystone()
		MoveAggroAndKillInRange(-8618, 3132, '8', $PLAYER_AGGRO_RANGE)
		TFCPickUpElementalKeystone()
		MoveAggroAndKillInRange(-8684, 4580, '8', $PLAYER_AGGRO_RANGE)
	WEnd
	If IsRunFailed() Then Return $FAIL

	Info('Going through portal')
	Local $mapLoaded = False
	While Not $mapLoaded
		If CheckStuck('TunnelsForsakenCustom Floor 1 - Portal', $MAX_TUNNELS_FORSAKEN_CUSTOM_DURATION) == $FAIL Then Return $FAIL
		MoveTo(-8684, 4580)
		Move(-8687, 4700)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_TUNNELS_OF_THE_FORSAKEN_LVL_2)
	WEnd
	Return $SUCCESS
EndFunc


;~ Clear TunnelsOfTheForsaken floor 2
Func ClearTunnelsForsakenCustomFloor2()
	Info('------------------------------------')
	Info('Second floor')
	If IsHardmodeEnabled() Then UseConset()

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -16748, 5350, $RANGE_LONGBOW)
		If CheckStuck('TunnelsForsakenCustom Floor 2', $MAX_TUNNELS_FORSAKEN_CUSTOM_DURATION) == $FAIL Then Return $FAIL
		WaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		UseSummoningStone()
		If IsHardmodeEnabled() Then UseConset()
		MoveAggroAndKillInRange(-2196, 12191, '1', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(1228, 16292, '2', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-764, 17454, '3', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-643, 20296, '4', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-2584, 21152, '5', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-3558, 21554, '6', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-3788, 21873, '7', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-6974, 20808, '8', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-9017, 21345, '9', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10769, 20331, '10', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-12465, 20092, '11', $RANGE_NEARBY)
		MoveAggroAndKillInRange(-14464, 19742, '12', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16238, 17982, '13', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16724, 15846, '14', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-13865, 17135, '15', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-12848, 18506, '16', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10956, 19044, '17', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-7875, 18959, '18', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-6272, 17188, '19', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-5910, 14892, '20', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-7177, 13320, '21', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10482, 14259, '22', $PLAYER_AGGRO_RANGE)
		RandomSleep(5000)
		MoveAggroAndKillInRange(-10816, 15686, '23', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-12402, 15310, '24', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-14553, 12670, '25', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16047, 10162, '26', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16759, 7708, '27', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16748, 5350, '28', $PLAYER_AGGRO_RANGE)
	WEnd
	If IsRunFailed() Then Return $FAIL

	Info('Going through portal')
	Local $mapLoaded = False
	While Not $mapLoaded
		If CheckStuck('TunnelsForsakenCustom Floor 2 - Portal', $MAX_TUNNELS_FORSAKEN_CUSTOM_DURATION) == $FAIL Then Return $FAIL
		MoveTo(-16780, 4324)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_TUNNELS_OF_THE_FORSAKEN_LVL_3)
	WEnd
	Return $SUCCESS
EndFunc


;~ Clear TunnelsOfTheForsaken floor 3
Func ClearTunnelsForsakenCustomFloor3()
	Info('------------------------------------')
	Info('Third floor')
	If IsHardmodeEnabled() Then UseConset()

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -10264, -4463, $RANGE_LONGBOW)
		If CheckStuck('TunnelsForsakenCustom Floor 3 - First loop', $MAX_TUNNELS_FORSAKEN_CUSTOM_DURATION) == $FAIL Then Return $FAIL
		WaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		UseSummoningStone()
		If IsHardmodeEnabled() Then UseConset()
		MoveAggroAndKillInRange(-11162, 3309, '1', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10127, 2505, '2', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-17353, -952, '3', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16397, -3496, '4', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-15176, -3768, '5', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-13875, -4543, '6', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-14111, -6232, '7', $PLAYER_AGGRO_RANGE)
		Sleep(2000)
		MoveAggroAndKillInRange(-13875, -4543, '8', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-12599, -5454, '9', $PLAYER_AGGRO_RANGE)
		Sleep(4000)
		PickUpItems()
		MoveAggroAndKillInRange(-10724, -3552, '10', $PLAYER_AGGRO_RANGE)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -15949, -8561, $RANGE_LONGBOW)
		If CheckStuck('TunnelsForsakenCustom Floor 3 - Second loop', $MAX_TUNNELS_FORSAKEN_CUSTOM_DURATION) == $FAIL Then Return $FAIL
		WaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		UseSummoningStone()
		If IsHardmodeEnabled() Then UseConset()
		MoveAggroAndKillInRange(-9820, -2108, '11', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-8166, 1081, '12', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-5090, -78, '13', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-6212, -2777, '14', $PLAYER_AGGRO_RANGE)
		Info('Open dungeon door')
		ClearTarget()

		For $i = 1 To 2
			RandomSleep(500)
			MoveTo(-6442, -4281)
			TargetNearestItem()
			Sleep(1500)
			ActionInteract()
			RandomSleep(500)
			ActionInteract()
		Next
		MoveAggroAndKillInRange(-7771, -6279, '15', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-11025, -7480, '16', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-12939, -8238, '17', $PLAYER_AGGRO_RANGE)
		RandomSleep(2000)
		MoveAggroAndKillInRange(-13836, -8918, '18', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16021, -8601, '19', $PLAYER_AGGRO_RANGE)
		RandomSleep(2000)
	WEnd
	If IsRunFailed() Then Return $FAIL

	Local $questrewardNPC = GetNearestNPCToCoords(-16098, -8626)
	TakeQuestReward($questrewardNPC, $ID_QUEST_THE_DREAMER_AND_THE_ZEALOT, 0x85B507)

	MoveTo(-15776, -8484)
	MoveTo(-16066, -8370)
	For $i = 1 To 2
		Info('Opening chest')
		TargetNearestItem()
		ActionInteract()
		RandomSleep(2500)
		PickUpItems()
	Next
	Return $SUCCESS
EndFunc


;~ Pick up the Elemental Keystone
Func TFCPickUpElementalKeystone()
	Local $agents = GetAgentArray($ID_AGENT_TYPE_ITEM)
	For $agent In $agents
		Local $agentID = DllStructGetData($agent, 'ID')
		Local $item = GetItemByAgentID($agentID)
		If (DllStructGetData($item, 'ModelID') == $ID_TUNNELS_ELEMENTAL_KEYSTONE) Then
			Info('Elemental Keystone: (' & Round(DllStructGetData($agent, 'X')) & ', ' & Round(DllStructGetData($agent, 'Y')) & ')')
			For $attempt = 0 To 4
				PickUpItem($item)
				Local $waitCycles = 0
				While $waitCycles < 10
					RandomSleep(1000)
					$waitCycles += 1
					If Not IsPlayerOrPartyAlive() Then Return False
					If Not GetAgentExists($agentID) Then Return True
				WEnd
				Error('Could not get Elemental Keystone at (' & DllStructGetData($agent, 'X') & ', ' & DllStructGetData($agent, 'Y') & ')')
			Next
			Return False
		EndIf
	Next
	Return False
EndFunc
