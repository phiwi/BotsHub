#CS ===========================================================================
; Author: GitHub Copilot
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
#include '../utilities/SupportTeam.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $OUTCAST_RHEAS_CRATER_SKILLBAR = 'OwJSg5PTTQ/a6M0k3lIQ4O8I'
Global Const $OUTCAST_RHEAS_CRATER_INFORMATIONS = 'Assassin chest run in Rhea''s Crater with death-skip opener.' & @CRLF _
	& 'Flow:' & @CRLF _
	& '- Seafarers Rest -> Rhea''s Crater' & @CRLF _
	& '- Flag heroes at zone spawn, die in first pack to respawn at shrine' & @CRLF _
	& '- Check right branch chest first' & @CRLF _
	& '- If no right chest, go back to shrine and run left branch' & @CRLF _
	& '- Open up to 2 chests and resign'
Global Const $OUTCAST_RHEAS_CRATER_FARM_DURATION = 2 * 60 * 1000

Global Const $OUTCAST_RHEAS_RIGHT_BRANCH_MAX_CHESTS = 1
Global Const $OUTCAST_RHEAS_LEFT_BRANCH_MAX_CHESTS = 1

Global Const $OUTCAST_RHEAS_HERO_OGDEN_TEMPLATE = 'Owkj4wQopO+sqPetLS9dJ7YfMA'
Global Const $OUTCAST_RHEAS_HERO_TAHLKORA_TEMPLATE = 'Owkj4oQopO+sqPe9iQ9dJ74aMA'
Global Const $OUTCAST_RHEAS_HERO_MORGAHN_TEMPLATE = 'OQijEqmMKODbe8OmEbi7x3YWMA'
Global Const $OUTCAST_RHEAS_HERO_ZHED_TEMPLATE = 'OgBCkMzTqYHy06znCVBsAZA'
Global Const $OUTCAST_RHEAS_HERO_VEKK_TEMPLATE = 'OgNCw8zTtgWsS0i1Do2dtuB'
Global Const $OUTCAST_RHEAS_HERO_XANDRA_TEMPLATE = 'OACiAyk8gNtePuwJ00ZOPLYA'
Global Const $OUTCAST_RHEAS_HERO_DUNKORO_TEMPLATE = 'OwAT02HCXyLaj4upe4ua6DC0oBA'

Global Const $OUTCAST_RHEAS_ZONE_OUT_X = -11213
Global Const $OUTCAST_RHEAS_ZONE_OUT_Y = -18352
Global Const $OUTCAST_RHEAS_ENTRY_FLAG_X = -10680
Global Const $OUTCAST_RHEAS_ENTRY_FLAG_Y = -18420
Global Const $OUTCAST_RHEAS_DEATHSPOT_X = -7957
Global Const $OUTCAST_RHEAS_DEATHSPOT_Y = -19461
Global Const $OUTCAST_RHEAS_SHRINE_X = 24
Global Const $OUTCAST_RHEAS_SHRINE_Y = 3673

Global $outcast_rheas_crater_farm_setup = False
Global $outcast_rheas_slot_dash = 1
Global $outcast_rheas_slot_natural_stride = 2
Global $outcast_rheas_slot_shadow_form = 3
Global $outcast_rheas_slot_i_am_unstoppable = 4
Global $outcast_rheas_slot_dwarven_stability = 5
Global $outcast_rheas_slot_heart_of_shadow = 6
Global $outcast_rheas_slot_deaths_charge = 7
Global $outcast_rheas_slot_deadly_paradox = 8

Global $outcast_rheas_hero_ogden_index = 1
Global $outcast_rheas_hero_tahlkora_index = 2
Global $outcast_rheas_hero_morgahn_index = 3
Global $outcast_rheas_hero_zhed_index = 4
Global $outcast_rheas_hero_vekk_index = 5
Global $outcast_rheas_hero_xandra_index = 6
Global $outcast_rheas_hero_dunkoro_index = 7
Global $outcast_rheas_last_chest_x = 0
Global $outcast_rheas_last_chest_y = 0


Func OutcastRheasCraterChestFarm()
	If Not $outcast_rheas_crater_farm_setup Then
		If SetupOutcastRheasCraterFarm() == $FAIL Then
			Warn('Outcast Rhea''s Crater setup failed, attempting one full re-setup before pause')
			$outcast_rheas_crater_farm_setup = False
			RandomSleep(450)
			If SetupOutcastRheasCraterFarm() == $FAIL Then Return $PAUSE
		EndIf
	EndIf

	If FindInInventory($ID_LOCKPICK)[0] == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf

	If OutcastRheasTravelToCrater() == $FAIL Then Return $FAIL
	If OutcastRheasDeathSkipToShrine() == $FAIL Then Return $FAIL
	OutcastRheasLogVisibleChestsFromShrine()

	Local $openedChests = OutcastRheasRunRightThenLeft()
	If $openedChests < 0 Then Return $FAIL
	Info('Opened ' & $openedChests & ' chest(s).')
	ResignAndReturnToOutpost($ID_SEAFARERS_REST)
	Return $SUCCESS
EndFunc


Func SetupOutcastRheasCraterFarm()
	Info('Setting up Outcast Rhea''s Crater chest run')
	If OutcastRheasEnsureAtSeafarersRest('setup') == $FAIL Then
		Warn('Outcast Rhea''s Crater setup failed: could not reach Seafarers Rest')
		Return $FAIL
	EndIf

	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_ASSASSIN Then
		Warn('Outcast Rhea''s Crater should run as Assassin primary')
		Return $FAIL
	EndIf

	LoadSkillTemplate($OUTCAST_RHEAS_CRATER_SKILLBAR)
	RandomSleep(250)
	If OutcastRheasResolveSkillSlots() == $FAIL Then
		Warn('Outcast Rhea''s Crater setup failed: required skill slots not found on current bar')
		Return $FAIL
	EndIf
	OutcastRheasEnsureWeaponSet3()

	If OutcastRheasSetupSinTeamFromFroggy() == $FAIL Then
		Warn('Could not apply Outcast Rhea''s Crater fixed Sin team setup')
		Return $FAIL
	EndIf

	SwitchToHardModeIfEnabled()
	$outcast_rheas_crater_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func OutcastRheasEnsureWeaponSet3()
	ChangeWeaponSet(3)
	RandomSleep(100)
EndFunc


Func OutcastRheasTravelToCrater()
	If OutcastRheasEnsureAtSeafarersRest('travel') == $FAIL Then Return $FAIL
	While GetMapID() <> $ID_RHEAS_CRATER
		Info('Moving to Rhea''s Crater')
		MoveTo(-11433, -20959)
		MoveTo(-11324, -19153)
		MoveTo($OUTCAST_RHEAS_ZONE_OUT_X, $OUTCAST_RHEAS_ZONE_OUT_Y)
		Move($OUTCAST_RHEAS_ZONE_OUT_X + 80, $OUTCAST_RHEAS_ZONE_OUT_Y + 120)
		RandomSleep(1200)
		WaitMapLoading($ID_RHEAS_CRATER, 10000, 2000)
	WEnd
	OutcastRheasFlagHeroesAtEntry()
	Return $SUCCESS
EndFunc


Func OutcastRheasEnsureAtSeafarersRest($stageLabel)
	Local $attempt
	For $attempt = 1 To 4
		If GetMapID() == $ID_SEAFARERS_REST Then
			If SupportTeamStabilizeAfterTravel($ID_SEAFARERS_REST, 3000, 200) Then Return $SUCCESS
		EndIf

		Info('Outcast Rhea''s Crater ' & $stageLabel & ': ensuring Seafarers Rest (attempt ' & $attempt & '/4)')
		TravelToOutpost($ID_SEAFARERS_REST, $district_name)

		If SupportTeamStabilizeAfterTravel($ID_SEAFARERS_REST, 9000, 250) Then Return $SUCCESS
		If WaitMapLoading($ID_SEAFARERS_REST, 5000, 250) Then Return $SUCCESS

		Warn('Outcast Rhea''s Crater ' & $stageLabel & ': Seafarers Rest attempt ' & $attempt & ' failed (map=' & GetMapID() & ')')
		RandomSleep(500)
	Next

	Warn('Outcast Rhea''s Crater ' & $stageLabel & ': could not reach/stabilize Seafarers Rest')
	Return $FAIL
EndFunc


Func OutcastRheasDeathSkipToShrine()
	Info('Flagging heroes at entry and forcing death skip')
	OutcastRheasFlagHeroesAtEntry()

	If OutcastRheasMoveToDeathspotDashOnly($OUTCAST_RHEAS_DEATHSPOT_X, $OUTCAST_RHEAS_DEATHSPOT_Y) == $FAIL Then Return $FAIL

	Local $deathWait = TimerInit()
	While IsPlayerAlive() And TimerDiff($deathWait) < 30000
		RandomSleep(200)
	WEnd
	If IsPlayerAlive() Then
		Warn('Death skip failed: player did not die at entry pack')
		Return $FAIL
	EndIf

	Local $rezWait = TimerInit()
	While Not IsPlayerAlive() And TimerDiff($rezWait) < 40000
		RandomSleep(300)
	WEnd
	If Not IsPlayerAlive() Then
		Warn('Death skip failed: no resurrection detected')
		Return $FAIL
	EndIf

	Info('Respawn detected, unflagging heroes for natural behavior')
	ClearPartyCommands()
	CancelAllHeroes()

	If GetDistanceToPoint(GetMyAgent(), $OUTCAST_RHEAS_SHRINE_X, $OUTCAST_RHEAS_SHRINE_Y) > 1800 Then
		MoveTo($OUTCAST_RHEAS_SHRINE_X, $OUTCAST_RHEAS_SHRINE_Y)
	EndIf

	Return $SUCCESS
EndFunc


Func OutcastRheasMoveToDeathspotDashOnly($x, $y)
	OutcastRheasEnsureWeaponSet3()
	Move($x, $y)
	Local $blockedCounter = 0
	Local $moveTimer = TimerInit()
	Local $me = GetMyAgent()

	While IsPlayerAlive() And GetDistanceToPoint($me, $x, $y) > 120 And $blockedCounter < 20 And TimerDiff($moveTimer) < 30000
		OutcastRheasEnsureWeaponSet3()
		; First death-skip leg: sprint only with skill 1, no SF/DP or defensive upkeep.
		If IsRecharged($outcast_rheas_slot_dash) And GetEnergy() >= 5 Then UseSkillEx($outcast_rheas_slot_dash)

		$me = GetMyAgent()
		If Not IsPlayerMoving() Then
			$blockedCounter += 1
			Move($x, $y)
		EndIf

		RandomSleep(180)
		$me = GetMyAgent()
	WEnd

	If Not IsPlayerAlive() Then Return $SUCCESS
	If GetDistanceToPoint(GetMyAgent(), $x, $y) > 250 Then
		Info('Deathskip: did not fully reach deathspot yet, continuing death wait in current aggro state')
	EndIf
	Return $SUCCESS
EndFunc


Func OutcastRheasRunRightThenLeft()
	Local $openedChests = 0
	Local $seenChest = OutcastRheasFindShrineVisibleChest($RANGE_COMPASS)
	Local $hadRightChestVisible = False
	Local $chestX
	Local $chestY

	If $seenChest <> Null Then
		$hadRightChestVisible = True
		$chestX = Int(DllStructGetData($seenChest, 'X'))
		$chestY = Int(DllStructGetData($seenChest, 'Y'))
		Info('Shrine-discovery: chest visible from rez-shrine at x=' & $chestX & ', y=' & $chestY & '. Running to discovered chest first')
		If OutcastRheasMoveWithUpkeep($chestX, $chestY, False) == $FAIL Then Return -1
		If OutcastRheasTryOpenNearbyChest($RANGE_COMPASS, True) Then $openedChests += 1
	Else
		Info('Shrine-discovery: no chest visible from rez-shrine, skipping fixed right route and going left directly')
	EndIf

	If Not IsPlayerAlive() Then Return -1
	If Not $hadRightChestVisible Then
		Info('No right chest case: running left in next-chest mode (no precise left endpoint)')
		$openedChests += OutcastRheasRunLeftBranchForNextChest()
		If Not IsPlayerAlive() Then Return -1
		Return $openedChests
	EndIf

	Info('Right chest handled: going directly to left route (no shrine-side transition maneuvers)')
	$openedChests += OutcastRheasRunLeftBranchFromRightChestForNextChest()
	If Not IsPlayerAlive() Then Return -1

	Return $openedChests
EndFunc


Func OutcastRheasFindShrineVisibleChest($range = $RANGE_COMPASS)
	Local $agents = GetAgentArray($ID_AGENT_TYPE_STATIC)
	If Not IsArray($agents) Then Return Null

	Local $agent
	Local $gadgetID
	Local $chestID
	Local $bestChest = Null
	Local $bestDist = 999999
	Local $distToMe

	For $agent In $agents
		$gadgetID = DllStructGetData($agent, 'GadgetID')
		If $MAP_CHESTS_IDS[$gadgetID] == Null Then ContinueLoop
		If GetDistanceToPoint($agent, $OUTCAST_RHEAS_SHRINE_X, $OUTCAST_RHEAS_SHRINE_Y) > $range Then ContinueLoop

		$chestID = DllStructGetData($agent, 'ID')
		If $chests_map[$chestID] == 2 Then ContinueLoop

		$distToMe = GetDistance(GetMyAgent(), $agent)
		If $distToMe < $bestDist Then
			$bestDist = $distToMe
			$bestChest = $agent
		EndIf
	Next

	Return $bestChest
EndFunc


Func OutcastRheasLogVisibleChestsFromShrine()
	Local $agents = GetAgentArray($ID_AGENT_TYPE_STATIC)
	If Not IsArray($agents) Then
		Warn('Outcast Rhea''s Crater probe: could not read static agents for shrine chest check')
		Return
	EndIf

	Local $me = GetMyAgent()
	Local $shrCountCompass = 0
	Local $shrCountSpirit = 0
	Local $myCountCompass = 0
	Local $details = ''
	Local $detailsShown = 0
	Local $agent
	Local $gadgetID
	Local $chestX
	Local $chestY
	Local $distShr
	Local $distMe

	For $agent In $agents
		$gadgetID = DllStructGetData($agent, 'GadgetID')
		If $MAP_CHESTS_IDS[$gadgetID] == Null Then ContinueLoop

		$chestX = Int(DllStructGetData($agent, 'X'))
		$chestY = Int(DllStructGetData($agent, 'Y'))
		$distShr = GetDistanceToPoint($agent, $OUTCAST_RHEAS_SHRINE_X, $OUTCAST_RHEAS_SHRINE_Y)
		$distMe = GetDistance($me, $agent)

		If $distShr <= $RANGE_COMPASS Then $shrCountCompass += 1
		If $distShr <= $RANGE_SPIRIT Then $shrCountSpirit += 1
		If $distMe <= $RANGE_COMPASS Then $myCountCompass += 1

		If $detailsShown < 4 Then
			$detailsShown += 1
			If $details <> '' Then $details &= ' | '
			$details &= '#' & $detailsShown & ' x=' & $chestX & ' y=' & $chestY & ' dShr=' & Int($distShr) & ' dMe=' & Int($distMe)
		EndIf
	Next

	Info('Outcast Rhea''s Crater probe: visible chests from rez-shrine (compass=' & $shrCountCompass & ', spirit=' & $shrCountSpirit & '), from current spot (compass=' & $myCountCompass & ')')
	If $details == '' Then
		Info('Outcast Rhea''s Crater probe: no chest agents detected in current static-agent snapshot')
	Else
		Info('Outcast Rhea''s Crater probe chest sample: ' & $details)
	EndIf
EndFunc


Func OutcastRheasRunRightBranchForChest()
	Local $opened = 0
	Local $rightPath[5][2] = [ _
		[-95, 3470], _
		[-480, 3249], _
		[-934, 3725], _
		[-1228, 4884], _
		[-1459, 5096] _
	]

	For $i = 0 To UBound($rightPath) - 1
		If OutcastRheasMoveWithUpkeep($rightPath[$i][0], $rightPath[$i][1], False) == $FAIL Then Return $opened
		If OutcastRheasTryOpenNearbyChest($RANGE_COMPASS) Then
			$opened += 1
			If $opened >= $OUTCAST_RHEAS_RIGHT_BRANCH_MAX_CHESTS Then ExitLoop
		EndIf
	Next
	Return $opened
EndFunc


Func OutcastRheasRunLeftBranchForChest()
	Local $opened = 0
	Local $leftPath[11][2] = [ _
		[-704, 2890], _
		[-1085, 1581], _
		[-1450, 980], _
		[-1679, 527], _
		[-2173, -377], _
		[-2648, -771], _
		[-3212, -1015], _
		[-3834, -1097], _
		[-4149, -1120], _
		[-4995, -1261], _
		[-5022, -1190] _
	]

	For $i = 0 To UBound($leftPath) - 1
		If OutcastRheasMoveWithUpkeep($leftPath[$i][0], $leftPath[$i][1], True) == $FAIL Then Return $opened
		If OutcastRheasTryOpenNearbyChest($RANGE_COMPASS) Then
			$opened += 1
			If $opened >= $OUTCAST_RHEAS_LEFT_BRANCH_MAX_CHESTS Then ExitLoop
		EndIf
	Next
	Return $opened
EndFunc


Func OutcastRheasRunLeftBranchForNextChest()
	Local $opened = 0
	Local $leftMidPath[3][2] = [ _
		[-704, 2890], _
		[-1085, 1581], _
		[-1450, 980] _
	]
	Local $leftTailPath[6][2] = [ _
		[-2173, -377], _
		[-3212, -1015], _
		[-3834, -1097], _
		[-4149, -1120], _
		[-4995, -1261], _
		[-5022, -1190] _
	]
	Local $midpointResult

	For $i = 0 To UBound($leftMidPath) - 1
		If OutcastRheasMoveWithUpkeep($leftMidPath[$i][0], $leftMidPath[$i][1], True) == $FAIL Then Return $opened
	Next

	$midpointResult = OutcastRheasTryLeftMidpointDecision()
	If $midpointResult > 0 Then Return $opened + $midpointResult

	For $i = 0 To UBound($leftTailPath) - 1
		If OutcastRheasMoveWithUpkeep($leftTailPath[$i][0], $leftTailPath[$i][1], True) == $FAIL Then Return $opened
		If OutcastRheasTryOpenNearbyChest($RANGE_SPIRIT) Then
			$opened += 1
			Return $opened
		EndIf
	Next

	; Safety: one last broad scan before giving up this branch.
	If OutcastRheasTryOpenNearbyChest($RANGE_SPIRIT) Then $opened += 1
	Return $opened
EndFunc


Func OutcastRheasRunLeftBranchFromRightChestForNextChest()
	Local $opened = 0
	Local $leftDirectPath[1][2] = [ _
		[-1450, 980] _
	]
	Local $leftTailPath[6][2] = [ _
		[-2173, -377], _
		[-3212, -1015], _
		[-3834, -1097], _
		[-4149, -1120], _
		[-4995, -1261], _
		[-5022, -1190] _
	]
	Local $midpointResult

	For $i = 0 To UBound($leftDirectPath) - 1
		If OutcastRheasMoveWithUpkeep($leftDirectPath[$i][0], $leftDirectPath[$i][1], True) == $FAIL Then Return $opened
	Next

	$midpointResult = OutcastRheasTryLeftMidpointDecision()
	If $midpointResult > 0 Then Return $opened + $midpointResult

	For $i = 0 To UBound($leftTailPath) - 1
		If OutcastRheasMoveWithUpkeep($leftTailPath[$i][0], $leftTailPath[$i][1], True) == $FAIL Then Return $opened
		If OutcastRheasTryOpenNearbyChest($RANGE_SPIRIT) Then
			$opened += 1
			Return $opened
		EndIf
	Next

	If OutcastRheasTryOpenNearbyChest($RANGE_SPIRIT) Then $opened += 1
	Return $opened
EndFunc


Func OutcastRheasTryLeftMidpointDecision()
	Local $midChest = FindChest($RANGE_SPIRIT)
	If $midChest == Null Then
		Info('Left midpoint probe: no chest detected from halfway point, continuing deeper on left path')
		Return 0
	EndIf

	Local $chestX = Int(DllStructGetData($midChest, 'X'))
	Local $chestY = Int(DllStructGetData($midChest, 'Y'))
	Info('Left midpoint probe: chest detected at x=' & $chestX & ', y=' & $chestY & ', moving directly')

	If OutcastRheasMoveWithUpkeep($chestX, $chestY, True) == $FAIL Then Return 0
	If OutcastRheasTryOpenNearbyChest($RANGE_SPIRIT) Then Return 1
	Return 0
EndFunc


Func OutcastRheasTryOpenNearbyChest($range, $fastRecovery = False)
	Local $chest = FindChest($range)
	If $chest == Null Then Return False
	$outcast_rheas_last_chest_x = Int(DllStructGetData($chest, 'X'))
	$outcast_rheas_last_chest_y = Int(DllStructGetData($chest, 'Y'))
	Info('Chest detected, moving to open')
	Local $opened = FindAndOpenChests($range, OutcastRheasDefendWhileOpeningChest, OutcastRheasRecoverWhileOpeningChest)
	If Not $opened Then Return False
	OutcastRheasPostChestLootRecovery($fastRecovery)
	Return True
EndFunc


Func OutcastRheasDefendWhileOpeningChest()
	OutcastRheasUseUpkeep(True, True)
EndFunc


Func OutcastRheasRecoverWhileOpeningChest()
	Local $me = GetMyAgent()
	If $me == Null Then Return
	OutcastRheasTryUnblockMove(Int(DllStructGetData($me, 'X')) + 120, Int(DllStructGetData($me, 'Y')) + 80, True)
EndFunc


Func OutcastRheasPostChestLootRecovery($fastExit = False)
	If $fastExit Then
		Info('Chest opened, fast loot recovery for direct left transition')
	Else
		Info('Chest opened, attempting loot recovery')
	EndIf

	Local $passes = $fastExit ? 3 : 8
	For $i = 1 To $passes
		If Not IsPlayerAlive() Then Return
		OutcastRheasUseUpkeep(True, True)

		If $outcast_rheas_last_chest_x <> 0 Or $outcast_rheas_last_chest_y <> 0 Then
			If Not $fastExit And GetDistanceToPoint(GetMyAgent(), $outcast_rheas_last_chest_x, $outcast_rheas_last_chest_y) > 250 Then
				OutcastRheasTryUnblockMove($outcast_rheas_last_chest_x, $outcast_rheas_last_chest_y, True)
			EndIf
			Move($outcast_rheas_last_chest_x, $outcast_rheas_last_chest_y)
		EndIf

		PickUpItems(OutcastRheasDefendWhileOpeningChest)

		If Not $fastExit And Not IsPlayerMoving() Then
			Local $me = GetMyAgent()
			If $me <> Null Then
				If $outcast_rheas_last_chest_x <> 0 Or $outcast_rheas_last_chest_y <> 0 Then
					OutcastRheasTryUnblockMove($outcast_rheas_last_chest_x, $outcast_rheas_last_chest_y, True)
				Else
					OutcastRheasTryUnblockMove(Int(DllStructGetData($me, 'X')) + 140, Int(DllStructGetData($me, 'Y')) + 100, True)
				EndIf
			EndIf
		EndIf

		RandomSleep($fastExit ? 120 : 180)
	Next
EndFunc


Func OutcastRheasMoveWithUpkeep($x, $y, $forceIau)
	OutcastRheasEnsureWeaponSet3()
	Move($x, $y)
	Local $blockedCounter = 0
	Local $unblockAttempts = 0
	Local $me = GetMyAgent()
	While IsPlayerAlive() And GetDistanceToPoint($me, $x, $y) > 120 And $blockedCounter < 24
		OutcastRheasEnsureWeaponSet3()
		OutcastRheasUseUpkeep($forceIau, True)

		$me = GetMyAgent()
		If Not IsPlayerMoving() Then
			$blockedCounter += 1
			If $blockedCounter >= 6 And Mod($blockedCounter, 3) == 0 And $unblockAttempts < 4 Then
				$unblockAttempts += 1
				Info('Blocked while moving, trying to unblock (attempt ' & $unblockAttempts & ')')
				OutcastRheasTryUnblockMove($x, $y, $forceIau)
			EndIf
			Move($x, $y)
		EndIf

		RandomSleep(220)
		$me = GetMyAgent()
	WEnd
	If Not IsPlayerAlive() Then Return $FAIL

	If GetDistanceToPoint(GetMyAgent(), $x, $y) > 200 Then
		For $i = 1 To 2
			Info('Final unblock retry #' & $i)
			OutcastRheasTryUnblockMove($x, $y, $forceIau)
			If GetDistanceToPoint(GetMyAgent(), $x, $y) <= 200 Then ExitLoop
		Next
	EndIf

	Return GetDistanceToPoint(GetMyAgent(), $x, $y) <= 200 ? $SUCCESS : $FAIL
EndFunc


Func OutcastRheasTryUnblockMove($targetX, $targetY, $forceIau)
	OutcastRheasEnsureWeaponSet3()
	OutcastRheasUseUpkeep($forceIau, True)

	If IsRecharged($outcast_rheas_slot_dash) And GetEnergy() >= 5 Then UseSkillEx($outcast_rheas_slot_dash)

	Local $backNpc = OutcastRheasGetNpcInBack()
	If IsRecharged($outcast_rheas_slot_heart_of_shadow) And GetEnergy() >= 5 Then
		If $backNpc == Null Then
			$backNpc = GetMyAgent()
		EndIf
		UseSkillEx($outcast_rheas_slot_heart_of_shadow, $backNpc)
		RandomSleep(120)
	EndIf

	Local $dcTarget = OutcastRheasGetDistantEnemyForUnblock(450)
	If $dcTarget <> Null And IsRecharged($outcast_rheas_slot_deaths_charge) And GetEnergy() >= 5 Then
		UseSkillEx($outcast_rheas_slot_deaths_charge, $dcTarget)
		RandomSleep(120)
	EndIf

	Local $me = GetMyAgent()
	Local $myX = Int(DllStructGetData($me, 'X'))
	Local $myY = Int(DllStructGetData($me, 'Y'))
	Move($myX + 180, $myY + 120)
	RandomSleep(120)
	Move($myX - 180, $myY - 120)
	RandomSleep(120)
	Move($targetX, $targetY)
EndFunc


Func OutcastRheasGetDistantEnemyForUnblock($minDistance = 450)
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_COMPASS)
	If Not IsArray($foes) Or UBound($foes) <= 0 Then Return Null

	For $foe In $foes
		If GetDistance($me, $foe) >= $minDistance Then Return $foe
	Next
	Return Null
EndFunc


Func OutcastRheasUseUpkeep($forceIau, $allowEmergency)
	OutcastRheasEnsureWeaponSet3()
	If GetEnergy() >= 20 And IsRecharged($outcast_rheas_slot_shadow_form) Then
		If IsRecharged($outcast_rheas_slot_deadly_paradox) Then
			UseSkillEx($outcast_rheas_slot_deadly_paradox)
			RandomSleep(30)
		EndIf
		UseSkillEx($outcast_rheas_slot_shadow_form)
	EndIf

	If IsRecharged($outcast_rheas_slot_dwarven_stability) And GetEnergy() >= 5 Then UseSkillEx($outcast_rheas_slot_dwarven_stability)

	If IsRecharged($outcast_rheas_slot_dash) And GetEnergy() >= 5 Then UseSkillEx($outcast_rheas_slot_dash)

	If IsRecharged($outcast_rheas_slot_natural_stride) And GetEnergy() >= 5 And GetEffect($ID_CRIPPLED) <> Null Then UseSkillEx($outcast_rheas_slot_natural_stride)

	If (GetEffect($ID_CRIPPLED) <> Null Or $forceIau) And IsRecharged($outcast_rheas_slot_i_am_unstoppable) And GetEnergy() >= 5 Then
		UseSkillEx($outcast_rheas_slot_i_am_unstoppable)
	EndIf

	If Not $allowEmergency Then Return

	If GetHealth() < 0.65 And IsRecharged($outcast_rheas_slot_heart_of_shadow) And GetEnergy() >= 5 Then
		Local $npc = OutcastRheasGetNpcInBack()
		If $npc == Null Then $npc = GetMyAgent()
		UseSkillEx($outcast_rheas_slot_heart_of_shadow, $npc)
	EndIf

	If GetHealth() < 0.60 And IsRecharged($outcast_rheas_slot_deaths_charge) And GetEnergy() >= 5 Then
		Local $target = GetNearestEnemyToAgent(GetMyAgent())
		If $target <> Null Then UseSkillEx($outcast_rheas_slot_deaths_charge, $target)
	EndIf
EndFunc


Func OutcastRheasGetNpcInBack()
	Local $me = GetMyAgent()
	Local $npcs = GetNPCsInRangeOfAgent($me, Null, $RANGE_SPELLCAST)
	If Not IsArray($npcs) Or UBound($npcs) <= 0 Then Return Null
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $nearest = Null
	Local $farthestDist = -1
	For $npc In $npcs
		Local $dist = Sqrt((DllStructGetData($npc, 'X') - $myX) ^ 2 + (DllStructGetData($npc, 'Y') - $myY) ^ 2)
		If $dist > $farthestDist Then
			$farthestDist = $dist
			$nearest = $npc
		EndIf
	Next
	Return $nearest
EndFunc


Func OutcastRheasResolveSkillSlots()
	For $i = 1 To 8
		Switch GetSkillbarSkillID($i)
			Case $ID_DASH
				$outcast_rheas_slot_dash = $i
			Case $ID_NATURAL_STRIDE
				$outcast_rheas_slot_natural_stride = $i
			Case $ID_SHADOW_FORM
				$outcast_rheas_slot_shadow_form = $i
			Case $ID_I_AM_UNSTOPPABLE
				$outcast_rheas_slot_i_am_unstoppable = $i
			Case $ID_DWARVEN_STABILITY
				$outcast_rheas_slot_dwarven_stability = $i
			Case $ID_HEART_OF_SHADOW
				$outcast_rheas_slot_heart_of_shadow = $i
			Case $ID_DEATHS_CHARGE
				$outcast_rheas_slot_deaths_charge = $i
			Case $ID_DEADLY_PARADOX
				$outcast_rheas_slot_deadly_paradox = $i
		EndSwitch
	Next

	If GetSkillbarSkillID($outcast_rheas_slot_shadow_form) <> $ID_SHADOW_FORM Then Return $FAIL
	If GetSkillbarSkillID($outcast_rheas_slot_deadly_paradox) <> $ID_DEADLY_PARADOX Then Return $FAIL
	If GetSkillbarSkillID($outcast_rheas_slot_dash) <> $ID_DASH Then Return $FAIL
	If GetSkillbarSkillID($outcast_rheas_slot_dwarven_stability) <> $ID_DWARVEN_STABILITY Then Return $FAIL
	Return $SUCCESS
EndFunc


Func OutcastRheasFlagHeroesAtEntry()
	If GetHeroCount() < 7 Then
		Warn('Deathskip flagging: expected 7 heroes, got ' & GetHeroCount())
	EndIf

	; Re-issue party commands first to ensure old commands are cleared before entry flag.
	ClearPartyCommands()
	CancelAllHeroes()

	For $i = 1 To 3
		CommandAll($OUTCAST_RHEAS_ENTRY_FLAG_X, $OUTCAST_RHEAS_ENTRY_FLAG_Y)
		CommandHero($outcast_rheas_hero_ogden_index, $OUTCAST_RHEAS_ENTRY_FLAG_X, $OUTCAST_RHEAS_ENTRY_FLAG_Y)
		CommandHero($outcast_rheas_hero_tahlkora_index, $OUTCAST_RHEAS_ENTRY_FLAG_X, $OUTCAST_RHEAS_ENTRY_FLAG_Y)
		CommandHero($outcast_rheas_hero_morgahn_index, $OUTCAST_RHEAS_ENTRY_FLAG_X, $OUTCAST_RHEAS_ENTRY_FLAG_Y)
		CommandHero($outcast_rheas_hero_zhed_index, $OUTCAST_RHEAS_ENTRY_FLAG_X, $OUTCAST_RHEAS_ENTRY_FLAG_Y)
		CommandHero($outcast_rheas_hero_vekk_index, $OUTCAST_RHEAS_ENTRY_FLAG_X, $OUTCAST_RHEAS_ENTRY_FLAG_Y)
		CommandHero($outcast_rheas_hero_xandra_index, $OUTCAST_RHEAS_ENTRY_FLAG_X, $OUTCAST_RHEAS_ENTRY_FLAG_Y)
		CommandHero($outcast_rheas_hero_dunkoro_index, $OUTCAST_RHEAS_ENTRY_FLAG_X, $OUTCAST_RHEAS_ENTRY_FLAG_Y)
		RandomSleep(180)
	Next
EndFunc


Func OutcastRheasSetupSinTeamFromFroggy()
	Info('Outcast Rhea''s Crater team: Ogden, Tahlkora, General Morgahn, Zhed, Vekk, Xandra, Dunkoro')
	If Not SupportTeamStabilizeAfterTravel($ID_SEAFARERS_REST, 9000, 250) Then
		Warn('Outcast Rhea''s Crater team: initial outpost stabilization timed out')
	EndIf

	If OutcastRheasEnsureSoloParty() == $FAIL Then Return $FAIL
	If OutcastRheasAssembleSinTeamPass('Outcast Rhea''s Crater') == $FAIL Then
		Warn('Outcast Rhea''s Crater team assembly pass 1 failed, refreshing outpost for pass 2')
		If TravelToOutpost($ID_SEAFARERS_REST, $district_name) == $FAIL Then Return $FAIL
		If Not SupportTeamStabilizeAfterTravel($ID_SEAFARERS_REST, 10000, 250) Then
			Warn('Outcast Rhea''s Crater team: outpost stabilization timed out before pass 2')
		EndIf
		If OutcastRheasEnsureSoloParty() == $FAIL Then Return $FAIL
		If OutcastRheasAssembleSinTeamPass('Outcast Rhea''s Crater') == $FAIL Then
			Warn('Outcast Rhea''s Crater team assembly pass 2 failed, trying targeted missing-hero fallback')
			If OutcastRheasRetryMissingSinHeroes('Outcast Rhea''s Crater') == $FAIL Then
				Warn('Outcast Rhea''s Crater team assembly failed')
				Return $FAIL
			EndIf
		EndIf
	EndIf

	$outcast_rheas_hero_ogden_index = SupportTeamResolveHeroIndex($ID_OGDEN, 1)
	$outcast_rheas_hero_tahlkora_index = SupportTeamResolveHeroIndex($ID_TAHLKORA, 2)
	$outcast_rheas_hero_morgahn_index = SupportTeamResolveHeroIndex($ID_GENERAL_MORGAHN, 3)
	$outcast_rheas_hero_zhed_index = SupportTeamResolveHeroIndex($ID_ZHED_SHADOWHOOF, 4)
	$outcast_rheas_hero_vekk_index = SupportTeamResolveHeroIndex($ID_VEKK, 5)
	$outcast_rheas_hero_xandra_index = SupportTeamResolveHeroIndex($ID_XANDRA, 6)
	$outcast_rheas_hero_dunkoro_index = SupportTeamResolveHeroIndex($ID_DUNKORO, 7)

	LoadSkillTemplate($OUTCAST_RHEAS_HERO_OGDEN_TEMPLATE, $outcast_rheas_hero_ogden_index)
	RandomSleep(150)
	LoadSkillTemplate($OUTCAST_RHEAS_HERO_TAHLKORA_TEMPLATE, $outcast_rheas_hero_tahlkora_index)
	RandomSleep(150)
	LoadSkillTemplate($OUTCAST_RHEAS_HERO_MORGAHN_TEMPLATE, $outcast_rheas_hero_morgahn_index)
	RandomSleep(150)
	LoadSkillTemplate($OUTCAST_RHEAS_HERO_ZHED_TEMPLATE, $outcast_rheas_hero_zhed_index)
	RandomSleep(150)
	LoadSkillTemplate($OUTCAST_RHEAS_HERO_VEKK_TEMPLATE, $outcast_rheas_hero_vekk_index)
	RandomSleep(150)
	LoadSkillTemplate($OUTCAST_RHEAS_HERO_XANDRA_TEMPLATE, $outcast_rheas_hero_xandra_index)
	RandomSleep(150)
	LoadSkillTemplate($OUTCAST_RHEAS_HERO_DUNKORO_TEMPLATE, $outcast_rheas_hero_dunkoro_index)
	RandomSleep(250)

	ClearPartyCommands()
	CancelAllHeroes()
	Return $SUCCESS
EndFunc


Func OutcastRheasAssembleSinTeamPass($teamLabel)
	Local $heroIDs[7] = [ _
		$ID_OGDEN, _
		$ID_TAHLKORA, _
		$ID_GENERAL_MORGAHN, _
		$ID_ZHED_SHADOWHOOF, _
		$ID_VEKK, _
		$ID_XANDRA, _
		$ID_DUNKORO _
	]
	Local $heroNames[7] = [ _
		'Ogden', _
		'Tahlkora', _
		'General Morgahn', _
		'Zhed', _
		'Vekk', _
		'Xandra', _
		'Dunkoro' _
	]
	Local $round
	Local $i

	For $round = 1 To 4
		For $i = 0 To UBound($heroIDs) - 1
			If GetHeroNumberByHeroID($heroIDs[$i]) == Null Then
				OutcastRheasTryAddHero($heroIDs[$i], $heroNames[$i], 0, $teamLabel)
			EndIf
		Next

		If OutcastRheasHasExactSinTeam() Then Return $SUCCESS

		Warn($teamLabel & ' team fill round ' & $round & ' incomplete (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')
		SupportTeamStabilizeAfterTravel($ID_SEAFARERS_REST, 2200, 150)
	Next

	OutcastRheasWarnMissingSinHeroes($teamLabel)
	Return $FAIL
EndFunc


Func OutcastRheasHasExactSinTeam()
	Local $requiredHeroIDs[7] = [ _
		$ID_OGDEN, _
		$ID_TAHLKORA, _
		$ID_GENERAL_MORGAHN, _
		$ID_ZHED_SHADOWHOOF, _
		$ID_VEKK, _
		$ID_XANDRA, _
		$ID_DUNKORO _
	]
	Return SupportTeamHasExactHeroes($requiredHeroIDs, 8)
EndFunc


Func OutcastRheasWarnMissingSinHeroes($teamLabel)
	Local $heroIDs[7] = [ _
		$ID_OGDEN, _
		$ID_TAHLKORA, _
		$ID_GENERAL_MORGAHN, _
		$ID_ZHED_SHADOWHOOF, _
		$ID_VEKK, _
		$ID_XANDRA, _
		$ID_DUNKORO _
	]
	Local $heroNames[7] = [ _
		'Ogden', _
		'Tahlkora', _
		'General Morgahn', _
		'Zhed', _
		'Vekk', _
		'Xandra', _
		'Dunkoro' _
	]
	Local $missing = ''
	Local $i
	For $i = 0 To UBound($heroIDs) - 1
		If GetHeroNumberByHeroID($heroIDs[$i]) == Null Then
			If $missing <> '' Then $missing &= ', '
			$missing &= $heroNames[$i]
		EndIf
	Next
	If $missing == '' Then $missing = 'none'
	Warn($teamLabel & ' missing heroes after pass: ' & $missing & ' (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')
EndFunc


Func OutcastRheasRetryMissingSinHeroes($teamLabel)
	Local $heroIDs[7] = [ _
		$ID_OGDEN, _
		$ID_TAHLKORA, _
		$ID_GENERAL_MORGAHN, _
		$ID_ZHED_SHADOWHOOF, _
		$ID_VEKK, _
		$ID_XANDRA, _
		$ID_DUNKORO _
	]
	Local $heroNames[7] = [ _
		'Ogden', _
		'Tahlkora', _
		'General Morgahn', _
		'Zhed', _
		'Vekk', _
		'Xandra', _
		'Dunkoro' _
	]
	Local $round
	Local $i
	For $round = 1 To 3
		Local $attemptedAny = False
		For $i = 0 To UBound($heroIDs) - 1
			If GetHeroNumberByHeroID($heroIDs[$i]) == Null Then
				$attemptedAny = True
				Info($teamLabel & ' targeted fallback round ' & $round & ': retrying missing hero ' & $heroNames[$i])
				OutcastRheasTryAddHero($heroIDs[$i], $heroNames[$i], 0, $teamLabel)
			EndIf
		Next

		If OutcastRheasHasExactSinTeam() Then
			Info($teamLabel & ' targeted missing-hero fallback succeeded on round ' & $round)
			Return $SUCCESS
		EndIf

		If Not $attemptedAny Then ExitLoop
		SupportTeamStabilizeAfterTravel($ID_SEAFARERS_REST, 2200, 150)
	Next

	OutcastRheasWarnMissingSinHeroes($teamLabel)
	Return $FAIL
EndFunc


Func OutcastRheasEnsureSoloParty($maxWaitMs = 9000)
	Local $timer = TimerInit()
	SupportTeamKickAllHeroesByIDSweep()
	KickAllHeroes()
	LeaveParty(False)
	While TimerDiff($timer) < $maxWaitMs
		If GetPartySize() <= 1 Then Return $SUCCESS
		SupportTeamKickAllHeroesByIDSweep()
		KickAllHeroes()
		LeaveParty(False)
		RandomSleep(320)
	WEnd
	Warn('Outcast Rhea''s Crater team: party reset timeout. Party=' & GetPartySize() & ', heroes=' & GetHeroCount())
	Return $FAIL
EndFunc


Func OutcastRheasTryAddHero($heroID, $heroName, $expectedSize, $teamLabel)
	Local $i
	For $i = 1 To 7
		If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
		AddHero($heroID)
		Local $verifyTimer = TimerInit()
		While TimerDiff($verifyTimer) < 2500
			If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
			RandomSleep(120)
		WEnd

		If Mod($i, 2) == 0 Then
			SupportTeamStabilizeAfterTravel($ID_SEAFARERS_REST, 1500, 150)
		EndIf
	Next
	Warn('Could not add ' & $teamLabel & ' hero ' & $heroName & ' after retries (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')
	Return $FAIL
EndFunc
