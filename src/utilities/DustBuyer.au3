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
Global Const $DUST_BUYER_DURATION = 10 * 60 * 1000
Global Const $DUST_BUYER_GOLD_WITHDRAW = 20000
Global Const $DUST_BUYER_BATCH_SIZE = 10
Global Const $DUST_BUYER_BATCHES = 100


;~ Main method: buy 1000 glittering dust and stash them
Func DustBuyerFarm()
	Info('Glittering Dust Buyer starting')
	TravelToOutpost($ID_EYE_OF_THE_NORTH, $district_name)
	RandomSleep(500)

	Info('Withdrawing ' & $DUST_BUYER_GOLD_WITHDRAW & ' gold from Xunlai Storage')
	WithdrawGold($DUST_BUYER_GOLD_WITHDRAW)
	RandomSleep(300)

	Info('Moving to Crafting Material Trader')
	UseCitySpeedBoost()
	Local $npcCoords = NPCCoordinatesInTown($ID_EYE_OF_THE_NORTH, 'Basic material trader')
	MoveTo($npcCoords[0], $npcCoords[1])
	Local $trader = GetNearestNPCToCoords($npcCoords[0], $npcCoords[1])
	GoToNPC($trader)
	RandomSleep(500)

	Info('Buying ' & ($DUST_BUYER_BATCH_SIZE * $DUST_BUYER_BATCHES) & ' glittering dust (' & $DUST_BUYER_BATCHES & ' batches of ' & $DUST_BUYER_BATCH_SIZE & ')')
	For $i = 1 To $DUST_BUYER_BATCHES
		TraderRequest($ID_PILE_OF_GLITTERING_DUST)
		RandomSleep(200)
		Local $price = GetTraderCostValue()
		If $price <= 0 Then
			Warn('Could not get trader price for glittering dust on batch ' & $i)
			Return $FAIL
		EndIf
		TraderBuy()
		If Mod($i, 10) == 0 Then Info('Bought ' & ($i * $DUST_BUYER_BATCH_SIZE) & ' glittering dust so far')
		RandomSleep(200)
	Next

	Info('All glittering dust purchased. Depositing gold and stashing materials.')
	DepositGold()
	RandomSleep(300)

	Info('Stashing glittering dust in Xunlai Storage')
	StoreItemsInXunlaiStorage(DustBuyerShouldStore)

	Info('Glittering Dust Buyer complete. Dust in storage.')
	Return $PAUSE
EndFunc


Func DustBuyerShouldStore($item)
	Return DllStructGetData($item, 'ModelID') == $ID_PILE_OF_GLITTERING_DUST
EndFunc
