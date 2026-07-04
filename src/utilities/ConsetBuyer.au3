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
Global Const $EYJA_X = 3339
Global Const $EYJA_Y = 616
; Kwat — verkauft Essence of Celerity
Global Const $KWAT_X = 3625
Global Const $KWAT_Y = 155
; Alcus Nailbiter — verkauft Armor of Salvation
Global Const $ALCUS_X = 3693
Global Const $ALCUS_Y = -57


;~ Hauptfunktion
Func ConsetBuyerFarm()
	Info('Conset Buyer: buying ' & $CONSET_BUY_COUNT & ' consets')

	; ── Schritt 1: Nach Eye of the North ──
	TravelToOutpost($ID_EYE_OF_THE_NORTH, $district_name)
	RandomSleep(500)

	; ── Schritt 2: Mats aus dem Stash holen ──
	Info('Checking inventory and stash for materials')

	; ── Bereits im Inventar vorhandene Mats zählen ──
	Local $invIron    = CountMaterialInInventory($ID_IRON_INGOT)
	Local $invDust    = CountMaterialInInventory($ID_PILE_OF_GLITTERING_DUST)
	Local $invFeather = CountMaterialInInventory($ID_FEATHER)
	Local $invBone    = CountMaterialInInventory($ID_BONE)
	Info('Materials in inventory: Iron=' & $invIron & ' Dust=' & $invDust & ' Feathers=' & $invFeather & ' Bones=' & $invBone)

	; ── Rest aus dem Stash holen ──
	Local $stashIron    = WithdrawMaterialFromStorage($ID_IRON_INGOT,             $CONSET_IRON_TOTAL    - $invIron)
	Local $stashDust    = WithdrawMaterialFromStorage($ID_PILE_OF_GLITTERING_DUST, $CONSET_DUST_TOTAL    - $invDust)
	Local $stashFeather = WithdrawMaterialFromStorage($ID_FEATHER,                 $CONSET_FEATHER_TOTAL - $invFeather)
	Local $stashBone    = WithdrawMaterialFromStorage($ID_BONE,                    $CONSET_BONE_TOTAL    - $invBone)

	Info('Materials from stash: Iron=' & $stashIron & ' Dust=' & $stashDust & ' Feathers=' & $stashFeather & ' Bones=' & $stashBone)

	; ── Schritt 3: Gold für Mats + Consets sicherstellen (VOR dem Händler!) ──
	; Pro 10er-Batch: Iron~180g, Dust~170g, Feathers~350g, Bones~150g → großzügig 100k deckt alles
	Local $goldNeeded = 100000
	If GetGoldCharacter() < 20000 Then
		Info('Need gold for materials and consets. Withdrawing up to ' & $goldNeeded & ' from stash.')
		WithdrawGold($goldNeeded)
		RandomSleep(300)
	EndIf
	Info('Gold: ' & GetGoldCharacter())

	; ── Schritt 4: Fehlende Mats beim Händler kaufen ──
	Local $totalIron    = $invIron    + $stashIron
	Local $totalDust    = $invDust    + $stashDust
	Local $totalFeather = $invFeather + $stashFeather
	Local $totalBone    = $invBone    + $stashBone
	Local $needIron    = _Max(0, $CONSET_IRON_TOTAL    - $totalIron)
	Local $needDust    = _Max(0, $CONSET_DUST_TOTAL    - $totalDust)
	Local $needFeather = _Max(0, $CONSET_FEATHER_TOTAL - $totalFeather)
	Local $needBone    = _Max(0, $CONSET_BONE_TOTAL    - $totalBone)

	If $needIron > 0 Or $needDust > 0 Or $needFeather > 0 Or $needBone > 0 Then
		Info('Buying missing materials from trader: Iron=' & $needIron & ' Dust=' & $needDust & ' Feathers=' & $needFeather & ' Bones=' & $needBone)
		; Nur wenn wir auch wirklich aus dem Stash gezogen haben, könnte der Xunlai-Tresor noch offen sein
		If $stashIron > 0 Or $stashDust > 0 Or $stashFeather > 0 Or $stashBone > 0 Then
			CloseAllPanels()
			RandomSleep(500)
		EndIf
		GoToMaterialTraderEotN()
		RandomSleep(1000)
		If $needIron    > 0 Then BuyMaterialBatch($ID_IRON_INGOT,             $needIron,    'Iron')
		If $needDust    > 0 Then BuyMaterialBatch($ID_PILE_OF_GLITTERING_DUST, $needDust,    'Dust')
		If $needFeather > 0 Then BuyMaterialBatch($ID_FEATHER,                 $needFeather, 'Feathers')
		If $needBone    > 0 Then BuyMaterialBatch($ID_BONE,                    $needBone,    'Bones')
	Else
		Info('All materials already in inventory — skipping trader')
	EndIf

	; ── Schritt 5: Nach Embark Beach (Mats bleiben im Inventar für Conset-Kauf!) ──
	Info('Travelling to Embark Beach')
	TravelToOutpost($ID_EMBARK_BEACH, $district_name)
	RandomSleep(500)
	UseCitySpeedBoost()

	; Fehlende Mats (falls EotN-Trader fehlschlug) in Embark Beach nachkaufen
	Local $currIron    = CountMaterialInInventory($ID_IRON_INGOT)
	Local $currDust    = CountMaterialInInventory($ID_PILE_OF_GLITTERING_DUST)
	Local $currFeather = CountMaterialInInventory($ID_FEATHER)
	Local $currBone    = CountMaterialInInventory($ID_BONE)
	Local $stillNeedIron    = _Max(0, $CONSET_IRON_TOTAL    - $currIron)
	Local $stillNeedDust    = _Max(0, $CONSET_DUST_TOTAL    - $currDust)
	Local $stillNeedFeather = _Max(0, $CONSET_FEATHER_TOTAL - $currFeather)
	Local $stillNeedBone    = _Max(0, $CONSET_BONE_TOTAL    - $currBone)
	If $stillNeedIron > 0 Or $stillNeedDust > 0 Or $stillNeedFeather > 0 Or $stillNeedBone > 0 Then
		Info('Buying remaining materials in Embark Beach: Iron=' & $stillNeedIron & ' Dust=' & $stillNeedDust & ' Feathers=' & $stillNeedFeather & ' Bones=' & $stillNeedBone)
		Local $ebNpcCoords = NPCCoordinatesInTown($ID_EMBARK_BEACH, 'Basic material trader')
		MoveTo($ebNpcCoords[0], $ebNpcCoords[1])
		Local $ebTrader = GetNearestNPCToCoords($ebNpcCoords[0], $ebNpcCoords[1])
		GoToNPC($ebTrader)
		RandomSleep(1000)
		If $stillNeedIron    > 0 Then BuyMaterialBatch($ID_IRON_INGOT,             $stillNeedIron,    'Iron')
		If $stillNeedDust    > 0 Then BuyMaterialBatch($ID_PILE_OF_GLITTERING_DUST, $stillNeedDust,    'Dust')
		If $stillNeedFeather > 0 Then BuyMaterialBatch($ID_FEATHER,                 $stillNeedFeather, 'Feathers')
		If $stillNeedBone    > 0 Then BuyMaterialBatch($ID_BONE,                    $stillNeedBone,    'Bones')
	EndIf

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
	; Erstmal zum NPC laufen und Interact senden
	GoToNPC($trader)
	RandomSleep(750)
	; Sicherstellen dass der Dialog wirklich offen ist: nochmal interact
	Local $me = GetMyAgent()
	If GetDistance($me, $trader) <= 250 Then
		GoNPC($trader)
		RandomSleep(750)
	EndIf
EndFunc


;~ Eine bestimmte Menge eines Materials in 10er-Batches kaufen
Func BuyMaterialBatch($modelID, $amount, $name = '')
	If $name == '' Then $name = $modelID
	Local $batches = Ceiling($amount / 10)
	Info('Buying ' & $amount & ' ' & $name & ' (' & $batches & ' batches of 10)')
	For $i = 1 To $batches
		Local $requestOK = TraderRequest($modelID)
		; Falls TraderRequest fehlschlägt, kurz warten und retry
		If Not $requestOK Then
			Warn('Retrying trader request for ' & $name & ' on batch ' & $i)
			RandomSleep(1500)
			$requestOK = TraderRequest($modelID)
		EndIf
		If Not $requestOK Then
			Warn('Could not request ' & $name & ' from trader on batch ' & $i)
			Return $FAIL
		EndIf
		RandomSleep(250)
		Local $price = GetTraderCostValue()
		If $price <= 0 Then
			Warn('Could not get trader price for ' & $name & ' on batch ' & $i)
			Return $FAIL
		EndIf
		TraderBuy()
		RandomSleep(200)
	Next
	Return $SUCCESS
EndFunc


;~ Materialien aus dem Stash holen (Material-Storage + regulärer Stash), bis zu $maxAmount
;~ Movet mehrfach, da pro Move nur 250 Einheiten (1 Stack) ins Inventar passen.
Func WithdrawMaterialFromStorage($modelID, $maxAmount)
	Local $totalWithdrawn = 0

	While $totalWithdrawn < $maxAmount
		Local $foundBag = 0, $foundSlot = 0, $available = 0

		; 1) Material-Storage (Bag 6) prüfen
		Local $materialSlot = $MAP_MATERIAL_LOCATION[$modelID]
		If $materialSlot <> Null Then
			Local $matItem = GetItemBySlot(6, $materialSlot)
			If DllStructGetData($matItem, 'ModelID') == $modelID Then
				$available = DllStructGetData($matItem, 'Equipped') * 256 + DllStructGetData($matItem, 'Quantity')
				If $available > 0 Then
					$foundBag = 6
					$foundSlot = $materialSlot
				EndIf
			EndIf
		EndIf

		; 2) Regulärer Stash (Bags 8-21) als Fallback
		If $foundBag == 0 Then
			Local $found = FindInXunlaiStorage($modelID)
			If $found[0] == 0 Then ExitLoop
			$foundBag = $found[0]
			$foundSlot = $found[1]
			$available = DllStructGetData(GetItemBySlot($foundBag, $foundSlot), 'Quantity')
		EndIf

		If $available <= 0 Then ExitLoop

		Local $emptySlot = FindInventoryEmptySlot()
		If $emptySlot[0] == 0 Then
			Warn('No inventory space to withdraw more ' & $modelID)
			ExitLoop
		EndIf

		Local $item = GetItemBySlot($foundBag, $foundSlot)
		MoveItem($item, $emptySlot[0], $emptySlot[1])
		RandomSleep(300)

		; Eine Bewegung holt max. 250 (1 Stack). Prüfen, was tatsächlich angekommen ist.
		Local $movedItem = GetItemBySlot($emptySlot[0], $emptySlot[1])
		Local $movedQty = DllStructGetData($movedItem, 'Quantity')
		$totalWithdrawn += $movedQty
	WEnd

	Return $totalWithdrawn
EndFunc


;~ Zählt, wie viele Einheiten eines Materials bereits im Inventar (Bags 1-5) liegen
Func CountMaterialInInventory($modelID)
	Local $total = 0
	For $bagIndex = 1 To $bags_count
		Local $bag = GetBag($bagIndex)
		For $slot = 1 To DllStructGetData($bag, 'Slots')
			Local $item = GetItemBySlot($bagIndex, $slot)
			If DllStructGetData($item, 'ModelID') == $modelID Then
				$total += DllStructGetData($item, 'Quantity')
			EndIf
		Next
	Next
	Return $total
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
	RandomSleep(750)
	; Sicherstellen dass der Dialog wirklich offen ist: nochmal interact
	Local $me = GetMyAgent()
	If GetDistance($me, $npc) <= 250 Then
		GoNPC($npc)
		RandomSleep(750)
	EndIf
EndFunc


;~ Ein Conset-Item (Grail/Essence/Armor) in angegebener Menge beim aktuellen NPC kaufen
Func BuyConsetItem($modelID, $amount)
	For $i = 1 To $amount
		Local $requestOK = TraderRequest($modelID)
		If Not $requestOK Then
			Warn('Retrying conset request for ' & $modelID & ' (item ' & $i & ')')
			RandomSleep(1500)
			$requestOK = TraderRequest($modelID)
		EndIf
		If Not $requestOK Then
			Warn('Could not request ' & $modelID & ' from trader (item ' & $i & ')')
			Return $FAIL
		EndIf
		RandomSleep(250)
		TraderBuy()
		RandomSleep(250)
	Next
	Return $SUCCESS
EndFunc
