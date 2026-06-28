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
Global Const $IRON_BUYER_DURATION = 10 * 60 * 1000
Global Const $IRON_BUYER_GOLD_WITHDRAW = 20000
Global Const $IRON_BUYER_BATCH_SIZE = 10
Global Const $IRON_BUYER_BATCHES = 100


;~ Main method: buy 1000 iron ingots and stash them
Func IronBuyerFarm()
	Info('Iron Buyer starting')
	TravelToOutpost($ID_EYE_OF_THE_NORTH, $district_name)
	RandomSleep(500)

	Info('Withdrawing ' & $IRON_BUYER_GOLD_WITHDRAW & ' gold from Xunlai Storage')
	WithdrawGold($IRON_BUYER_GOLD_WITHDRAW)
	RandomSleep(300)

	Info('Moving to Crafting Material Trader')
	UseCitySpeedBoost()
	Local $npcCoords = NPCCoordinatesInTown($ID_EYE_OF_THE_NORTH, 'Basic material trader')
	MoveTo($npcCoords[0], $npcCoords[1])
	Local $trader = GetNearestNPCToCoords($npcCoords[0], $npcCoords[1])
	GoToNPC($trader)
	RandomSleep(500)

	Info('Buying ' & ($IRON_BUYER_BATCH_SIZE * $IRON_BUYER_BATCHES) & ' iron ingots (' & $IRON_BUYER_BATCHES & ' batches of ' & $IRON_BUYER_BATCH_SIZE & ')')
	For $i = 1 To $IRON_BUYER_BATCHES
		TraderRequest($ID_IRON_INGOT)
		RandomSleep(200)
		Local $price = GetTraderCostValue()
		If $price <= 0 Then
			Warn('Could not get trader price for iron ingot on batch ' & $i)
			Return $FAIL
		EndIf
		TraderBuy()
		If Mod($i, 10) == 0 Then Info('Bought ' & ($i * $IRON_BUYER_BATCH_SIZE) & ' iron ingots so far')
		RandomSleep(200)
	Next

	Info('All iron ingots purchased. Depositing gold and stashing materials.')
	DepositGold()
	RandomSleep(300)

	Info('Stashing iron ingots in Xunlai Storage')
	StoreItemsInXunlaiStorage(IronBuyerShouldStore)

	Info('Iron Buyer complete. Iron ingots in storage.')
	Return $PAUSE
EndFunc


Func IronBuyerShouldStore($item)
	Return DllStructGetData($item, 'ModelID') == $ID_IRON_INGOT
EndFunc
