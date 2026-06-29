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

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $BUY_ALL_DURATION = 20 * 60 * 1000
Global Const $BUY_ALL_GOLD_WITHDRAW = 60000
Global Const $BUY_ALL_BATCH_SIZE = 10
Global Const $BUY_ALL_BATCHES = 100


;~ Main method: buy 1000 iron, 1000 bones, 1000 dust and stash them
Func BuyAllFarm()
	Info('Buy All starting')
	TravelToOutpost($ID_EYE_OF_THE_NORTH, $district_name)
	RandomSleep(500)

	Info('Withdrawing ' & $BUY_ALL_GOLD_WITHDRAW & ' gold from Xunlai Storage')
	WithdrawGold($BUY_ALL_GOLD_WITHDRAW)
	RandomSleep(300)

	Info('Moving to Crafting Material Trader')
	UseCitySpeedBoost()
	Local $npcCoords = NPCCoordinatesInTown($ID_EYE_OF_THE_NORTH, 'Basic material trader')
	MoveTo($npcCoords[0], $npcCoords[1])
	Local $trader = GetNearestNPCToCoords($npcCoords[0], $npcCoords[1])
	GoToNPC($trader)
	RandomSleep(500)

	; --- Iron ---
	Info('Buying ' & ($BUY_ALL_BATCH_SIZE * $BUY_ALL_BATCHES) & ' iron ingots')
	For $i = 1 To $BUY_ALL_BATCHES
		TraderRequest($ID_IRON_INGOT)
		RandomSleep(200)
		Local $price = GetTraderCostValue()
		If $price <= 0 Then
			Warn('Could not get trader price for iron ingot on batch ' & $i)
			Return $FAIL
		EndIf
		TraderBuy()
		If Mod($i, 10) == 0 Then Info('Bought ' & ($i * $BUY_ALL_BATCH_SIZE) & ' iron ingots so far')
		RandomSleep(200)
	Next

	; --- Bones ---
	Info('Buying ' & ($BUY_ALL_BATCH_SIZE * $BUY_ALL_BATCHES) & ' bones')
	For $i = 1 To $BUY_ALL_BATCHES
		TraderRequest($ID_BONE)
		RandomSleep(200)
		Local $price = GetTraderCostValue()
		If $price <= 0 Then
			Warn('Could not get trader price for bones on batch ' & $i)
			Return $FAIL
		EndIf
		TraderBuy()
		If Mod($i, 10) == 0 Then Info('Bought ' & ($i * $BUY_ALL_BATCH_SIZE) & ' bones so far')
		RandomSleep(200)
	Next

	; --- Dust ---
	Info('Buying ' & ($BUY_ALL_BATCH_SIZE * $BUY_ALL_BATCHES) & ' glittering dust')
	For $i = 1 To $BUY_ALL_BATCHES
		TraderRequest($ID_PILE_OF_GLITTERING_DUST)
		RandomSleep(200)
		Local $price = GetTraderCostValue()
		If $price <= 0 Then
			Warn('Could not get trader price for glittering dust on batch ' & $i)
			Return $FAIL
		EndIf
		TraderBuy()
		If Mod($i, 10) == 0 Then Info('Bought ' & ($i * $BUY_ALL_BATCH_SIZE) & ' glittering dust so far')
		RandomSleep(200)
	Next

	Info('All materials purchased. Depositing gold and stashing materials.')
	DepositGold()
	RandomSleep(300)

	Info('Stashing iron, bones, and dust in Xunlai Storage')
	StoreItemsInXunlaiStorage(BuyAllShouldStore)

	Info('Buy All complete. Iron, bones, and dust in storage.')
	Return $PAUSE
EndFunc


Func BuyAllShouldStore($item)
	Local $modelId = DllStructGetData($item, 'ModelID')
	Return $modelId == $ID_IRON_INGOT Or $modelId == $ID_BONE Or $modelId == $ID_PILE_OF_GLITTERING_DUST
EndFunc
