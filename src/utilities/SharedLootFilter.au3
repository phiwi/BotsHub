#CS ===========================================================================
; Author: caustic-kronos
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
#include '../../lib/Utils.au3'


Func SharedLootShouldKeepItem($item)
	Local $itemID = DllStructGetData($item, 'ModelID')

	If IsTome($itemID) Then Return $itemID == $ID_DERVISH_ELITETOME
	If Not IsWeapon($item) Then Return False

	Local $itemType = DllStructGetData($item, 'type')
	Local $req = GetItemReq($item)

	If $itemType == $ID_TYPE_SHIELD And $req == 8 Then Return True

	If $itemID == $ID_GLACIAL_BLADE Or $itemID == $ID_GLACIAL_BLADES Then Return True

	If $itemID >= $ID_BONE_DRAGON_STAFF_DOMINATION And $itemID <= $ID_BONE_DRAGON_STAFF_CHANNELING Then Return True

	If $itemID == $ID_FROGGY_DOMINATION Or ($itemID >= $ID_FROGGY_FAST_CASTING And $itemID <= $ID_FROGGY_CHANNELING) Then Return True

	If $req == 9 Then
		Switch $itemID
			Case $ID_HOGS_GLUTTONY_TACTICS, $ID_HOGS_GLUTTONY_STRENGTH, $ID_HOGS_GLUTTONY_LEADERSHIP, _
				$ID_SPIDERS_GLUTTONY_TACTICS, $ID_SPIDERS_GLUTTONY_STRENGTH, $ID_SPIDERS_GLUTTONY_LEADERSHIP, _
				$ID_BRONZE_GUARDIAN_TACTICS, $ID_BRONZE_GUARDIAN_STRENGTH, $ID_BRONZE_GUARDIAN_LEADERSHIP, _
				$ID_BLACK_HAWKS_LUST, $ID_SCORPIONS_LUST, $ID_SCORPION_BOW, $ID_ITHAS_BOW, $ID_DARKSTEEL_LONGBOW, _
				$ID_PEACOCKS_WRATH_DOMINATION_MAGIC, $ID_QUICKSILVER_DOMINATION_MAGIC
				Return True
		EndSwitch
		If $itemID >= $ID_HOURGLASS_STAFF_DOMINATION_MAGIC And $itemID <= $ID_HOURGLASS_STAFF_CHANNELING Then Return True
	EndIf

	Local $modStruct = GetModStruct($item)
	If Not $modStruct Then Return False

	If StringInStr($modStruct, $STRUCT_MOD_OF_THE_NECROMANCER) Then
		Switch $itemType
			Case $ID_TYPE_WAND, $ID_TYPE_STAFF, $ID_TYPE_SCYTHE, $ID_TYPE_SPEAR
				Return True
		EndSwitch
	EndIf

	If SharedLootHasInscription($modStruct, $STRUCT_INSCRIPTION_APTITUDE_NOT_ATTITUDE) Then Return True
	If SharedLootHasInscription($modStruct, $STRUCT_INSCRIPTION_FORGET_ME_NOT) Then Return True

	Return False
EndFunc


Func SharedLootHasInscription($modStruct, $struct)
	Local $pos = StringInStr($modStruct, $struct)
	While $pos > 0
		If IsInscriptionStruct($modStruct, $pos) Then Return True
		$pos = StringInStr($modStruct, $struct, 0, 1, $pos + 1)
	WEnd
	Return False
EndFunc


Func SharedLootShouldSellItem($item)
	If DllStructGetData($item, 'Equipped') > 0 Then Return False
	If DllStructGetData($item, 'Customized') <> 0 Then Return False

	Local $rarity = GetRarity($item)
	Local $itemID = DllStructGetData($item, 'ModelID')
	If ($rarity == $RARITY_PURPLE Or $rarity == $RARITY_GOLD) And (IsWeapon($item) Or IsTome($itemID)) Then
		Return Not SharedLootShouldKeepItem($item)
	EndIf
	If IsWeapon($item) And $rarity == $RARITY_GREEN Then Return True
	Return DefaultShouldSellItem($item)
EndFunc


Func SharedLootIdentifyAll()
	For $bagIndex = 1 To $bags_count
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			Local $item = GetItemBySlot($bagIndex, $i)
			If DllStructGetData($item, 'ID') == 0 Then ContinueLoop
			If IsIdentified($item) Then ContinueLoop
			Local $rarity = GetRarity($item)
			If $rarity <> $RARITY_PURPLE And $rarity <> $RARITY_GOLD Then ContinueLoop
			If FindIdentificationKit() == Null Then BuySuperiorIdentificationKitInTown()
			IdentifyItem($item)
			RandomSleep(100)
		Next
	Next
EndFunc


Func SharedLootIdentifyAndSellLoot()
	Info('Inventory full - identifying and selling loot')
	TravelToOutpost($trade_town, $district_name)
	SharedLootIdentifyAll()
	SellItemsToMerchant(SharedLootShouldSellItem)
EndFunc
