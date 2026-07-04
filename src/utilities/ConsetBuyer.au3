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
;
; ===========================================================================
; Conset Buyer — kauft 10 komplette Consets (10 Grails + 10 Essences + 10 Armors)
;
; Benötigte Rohstoffe pro Conset:
;   100 Iron Ingots  → 1.000 für 10
;   100 Dust          → 1.000 für 10
;    50 Feathers      →   500 für 10
;    50 Bones         →   500 für 10
;
; Ablauf:
;   1. Nach Eye of the North reisen
;   2. Vorhandene Mats aus dem Stash holen
;   3. Fehlende Mats beim Material-Händler kaufen
;   4. Gold prüfen (7.500 für 10 Consets), ggf. aus Stash holen
;   5. Nach Embark Beach reisen
;   6. 10x Grail of Might        bei Eyja kaufen
;   7. 10x Essence of Celerity   bei Kwat kaufen
;   8. 10x Armor of Salvation    bei Alcus Nailbiter kaufen
; ===========================================================================
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Configuration ====
Global Const $CONSET_BUY_COUNT = 10
Global Const $CONSET_PRICE_PER = 750           ; 1 Conset = 750g (250g pro Teil)
Global Const $CONSET_TOTAL_GOLD = $CONSET_BUY_COUNT * $CONSET_PRICE_PER
Global Const $CONSET_IRON_TOTAL = $CONSET_BUY_COUNT * 100
Global Const $CONSET_DUST_TOTAL = $CONSET_BUY_COUNT * 100
Global Const $CONSET_FEATHER_TOTAL = $CONSET_BUY_COUNT * 50
Global Const $CONSET_BONE_TOTAL = $CONSET_BUY_COUNT * 50
Global Const $CONSET_BUY_DURATION = 10 * 60 * 1000

; ==== Embark Beach NPC-Koordinaten ====
; Eyja — verkauft Grail of Might
Global Const $EYJA_X = 1200
Global Const $EYJA_Y = -2050
; Kwat — verkauft Essence of Celerity
Global Const $KWAT_X = 1350
Global Const $KWAT_Y = -2150
; Alcus Nailbiter — verkauft Armor of Salvation
Global Const $ALCUS_X = 1500
Global Const $ALCUS_Y = -2250


;~ Hauptfunktion
Func ConsetBuyerFarm()
	Info('Conset Buyer: buying ' & $CONSET_BUY_COUNT & ' consets')

	; ── Schritt 1: Nach Eye of the North ──
	TravelToOutpost($ID_EYE_OF_THE_NORTH, $district_name)
	RandomSleep(500)

	; ── Schritt 2: Mats aus dem Stash holen ──
	Info('Checking stash for materials')
	Local $stashIron    = WithdrawMaterialFromStorage($ID_IRON_INGOT,             $CONSET_IRON_TOTAL)
	Local $stashDust    = WithdrawMaterialFromStorage($ID_PILE_OF_GLITTERING_DUST, $CONSET_DUST_TOTAL)
	Local $stashFeather = WithdrawMaterialFromStorage($ID_FEATHER,                 $CONSET_FEATHER_TOTAL)
	Local $stashBone    = WithdrawMaterialFromStorage($ID_BONE,                    $CONSET_BONE_TOTAL)

	Info('Materials from stash: Iron=' & $stashIron & ' Dust=' & $stashDust & ' Feathers=' & $stashFeather & ' Bones=' & $stashBone)

	; ── Schritt 3: Fehlende Mats beim Händler kaufen ──
	Local $needIron    = _Max(0, $CONSET_IRON_TOTAL    - $stashIron)
	Local $needDust    = _Max(0, $CONSET_DUST_TOTAL    - $stashDust)
	Local $needFeather = _Max(0, $CONSET_FEATHER_TOTAL - $stashFeather)
	Local $needBone    = _Max(0, $CONSET_BONE_TOTAL    - $stashBone)

	If $needIron > 0 Or $needDust > 0 Or $needFeather > 0 Or $needBone > 0 Then
		Info('Buying missing materials from trader: Iron=' & $needIron & ' Dust=' & $needDust & ' Feathers=' & $needFeather & ' Bones=' & $needBone)
		GoToMaterialTraderEotN()
		If $needIron    > 0 Then BuyMaterialBatch($ID_IRON_INGOT,             $needIron)
		If $needDust    > 0 Then BuyMaterialBatch($ID_PILE_OF_GLITTERING_DUST, $needDust)
		If $needFeather > 0 Then BuyMaterialBatch($ID_FEATHER,                 $needFeather)
		If $needBone    > 0 Then BuyMaterialBatch($ID_BONE,                    $needBone)
	Else
		Info('All materials already in inventory — skipping trader')
	EndIf

	; ── Schritt 4: Gold sicherstellen ──
	Local $goldNeeded = $CONSET_TOTAL_GOLD
	If GetGoldCharacter() < $goldNeeded Then
		Info('Need ' & $goldNeeded & ' gold, only have ' & GetGoldCharacter() & '. Withdrawing from stash.')
		WithdrawGold($goldNeeded)
		RandomSleep(300)
		If GetGoldCharacter() < $goldNeeded Then
			Warn('Not enough gold (' & GetGoldCharacter() & ') to buy ' & $CONSET_BUY_COUNT & ' consets')
			Return $FAIL
		EndIf
	EndIf
	Info('Gold OK: ' & GetGoldCharacter())

	; Material-Reste zurück in den Stash legen (damit Inventar nicht überläuft)
	StoreItemsInXunlaiStorage(ConsetBuyerShouldStoreMat)

	; ── Schritt 5: Nach Embark Beach ──
	Info('Travelling to Embark Beach')
	TravelToOutpost($ID_EMBARK_BEACH, $district_name)
	RandomSleep(500)
	UseCitySpeedBoost()

	; ── Schritt 6: 10x Grail of Might bei Eyja ──
	Info('Buying ' & $CONSET_BUY_COUNT & 'x Grail of Might from Eyja')
	GoToNPCByCoords($EYJA_X, $EYJA_Y)
	BuyConsetItem($ID_GRAIL_OF_MIGHT, $CONSET_BUY_COUNT)

	; ── Schritt 7: 10x Essence of Celerity bei Kwat ──
	Info('Buying ' & $CONSET_BUY_COUNT & 'x Essence of Celerity from Kwat')
	GoToNPCByCoords($KWAT_X, $KWAT_Y)
	BuyConsetItem($ID_ESSENCE_OF_CELERITY, $CONSET_BUY_COUNT)

	; ── Schritt 8: 10x Armor of Salvation bei Alcus Nailbiter ──
	Info('Buying ' & $CONSET_BUY_COUNT & 'x Armor of Salvation from Alcus Nailbiter')
	GoToNPCByCoords($ALCUS_X, $ALCUS_Y)
	BuyConsetItem($ID_ARMOR_OF_SALVATION, $CONSET_BUY_COUNT)

	Info('Conset Buyer: done. Bought ' & $CONSET_BUY_COUNT & ' consets.')
	Return $PAUSE
EndFunc


;~ Zum Material-Händler in Eye of the North gehen
Func GoToMaterialTraderEotN()
	UseCitySpeedBoost()
	Local $npcCoords = NPCCoordinatesInTown($ID_EYE_OF_THE_NORTH, 'Basic material trader')
	MoveTo($npcCoords[0], $npcCoords[1])
	Local $trader = GetNearestNPCToCoords($npcCoords[0], $npcCoords[1])
	GoToNPC($trader)
	RandomSleep(500)
EndFunc


;~ Eine bestimmte Menge eines Materials in 10er-Batches kaufen
Func BuyMaterialBatch($modelID, $amount)
	Local $batches = Ceiling($amount / 10)
	Info('Buying ' & $amount & 'x ' & $modelID & ' (' & $batches & ' batches of 10)')
	For $i = 1 To $batches
		TraderRequest($modelID)
		RandomSleep(200)
		Local $price = GetTraderCostValue()
		If $price <= 0 Then
			Warn('Could not get trader price for modelID ' & $modelID & ' on batch ' & $i)
			Return $FAIL
		EndIf
		TraderBuy()
		RandomSleep(200)
	Next
	Return $SUCCESS
EndFunc


;~ Materialien aus dem Stash holen, bis zu $maxAmount
Func WithdrawMaterialFromStorage($modelID, $maxAmount)
	Local $found = FindInXunlaiStorage($modelID)
	If $found[0] == 0 Then Return 0

	Local $item = GetItemBySlot($found[0], $found[1])
	Local $qty = DllStructGetData($item, 'Quantity')
	Local $take = _Min($maxAmount, $qty)

	; Wenn der Stack grösser als benötigt, nur Teilmenge via Split nehmen
	; Wenn der ganze Stack passt, einfach moven
	If $take >= $qty Then
		; Ganzen Stack in Inventar verschieben
		Local $emptySlot = FindInventoryEmptySlot()
		If $emptySlot[0] == 0 Then
			Warn('No inventory space to withdraw ' & $modelID)
			Return 0
		EndIf
		MoveItem($item, $emptySlot[0], $emptySlot[1])
		RandomSleep(300)
		Return $qty
	Else
		; Stack splitten ist komplex — fürs Erste: ganzen Stack nehmen
		; und Rest später zurücklegen (wird in StoreItemsInXunlaiStorage erledigt)
		Local $emptySlot = FindInventoryEmptySlot()
		If $emptySlot[0] == 0 Then
			Warn('No inventory space to withdraw ' & $modelID)
			Return 0
		EndIf
		MoveItem($item, $emptySlot[0], $emptySlot[1])
		RandomSleep(300)
		Return $qty
	EndIf
EndFunc


;~ Leeren Inventar-Slot finden
Func FindInventoryEmptySlot()
	For $bagIndex = 1 To $bags_count
		Local $bag = GetBag($bagIndex)
		For $slot = 1 To DllStructGetData($bag, 'Slots')
			Local $item = GetItemBySlot($bagIndex, $slot)
			If DllStructGetData($item, 'ModelID') == 0 Then
				Local $result[] = [$bagIndex, $slot]
				Return $result
			EndIf
		Next
	Next
	Local $empty[] = [0, 0]
	Return $empty
EndFunc


;~ Filter für StoreItemsInXunlaiStorage: nur die 4 Rohstoffe
Func ConsetBuyerShouldStoreMat($item)
	Local $modelId = DllStructGetData($item, 'ModelID')
	Return $modelId == $ID_IRON_INGOT _
		Or $modelId == $ID_PILE_OF_GLITTERING_DUST _
		Or $modelId == $ID_FEATHER _
		Or $modelId == $ID_BONE
EndFunc


;~ Zum nächsten NPC bei den angegebenen Koordinaten laufen
Func GoToNPCByCoords($x, $y)
	MoveTo($x, $y)
	Local $npc = GetNearestNPCToCoords($x, $y)
	GoToNPC($npc)
	RandomSleep(500)
EndFunc


;~ Ein Conset-Item (Grail/Essence/Armor) in angegebener Menge beim aktuellen NPC kaufen
Func BuyConsetItem($modelID, $amount)
	For $i = 1 To $amount
		If Not TraderRequest($modelID) Then
			Warn('Could not request ' & $modelID & ' from trader (item ' & $i & ')')
			Return $FAIL
		EndIf
		RandomSleep(250)
		TraderBuy()
		RandomSleep(250)
	Next
	Return $SUCCESS
EndFunc
