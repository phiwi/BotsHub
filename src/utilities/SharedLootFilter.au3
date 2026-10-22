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

	If $itemID == $ID_OMINOUS_AEGIS_TACTICS Or $itemID == $ID_OMINOUS_AEGIS_STRENGTH Or $itemID == $ID_OMINOUS_AEGIS_LEADERSHIP Then Return True

	If $itemID == $ID_JAPAN_1ST_ANNIVERSARY_SHIELD_STRENGTH Or $itemID == $ID_JAPAN_1ST_ANNIVERSARY_SHIELD_TACTICS Or $itemID == $ID_JAPAN_1ST_ANNIVERSARY_SHIELD_LEADERSHIP Then Return True

	If $itemID == $ID_BLADED_SHIELD Or $itemID == $ID_BLADED_SHIELD_2 Then Return True

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

	If $itemType == $ID_TYPE_STAFF And $req == 9 And SharedLootHasInherentHCTOrHSR($modStruct) Then Return True

	; Dual vamp: both inherent +15% damage mods (health regen -1 and energy regen -1)
	If StringInStr($modStruct, $STRUCT_INHERENT_VAMPIRIC_STRENGTH) And StringInStr($modStruct, $STRUCT_INHERENT_ZEALOUS_STRENGTH) Then
		Switch $itemType
			Case $ID_TYPE_AXE, $ID_TYPE_SWORD, $ID_TYPE_HAMMER, $ID_TYPE_BOW
				Return True
		EndSwitch
	EndIf

	If StringInStr($modStruct, $STRUCT_MOD_OF_THE_NECROMANCER) Then
		Switch $itemType
			Case $ID_TYPE_WAND, $ID_TYPE_STAFF, $ID_TYPE_SCYTHE, $ID_TYPE_SPEAR
				Return True
		EndSwitch
	EndIf

	If $itemType == $ID_TYPE_OFFHAND And StringInStr($modStruct, $STRUCT_MOD_OF_APTITUDE) Then Return True

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


Func SharedLootHasInherentHCTOrHSR($modStruct)
	Local $inherentStructs = [ _
		$STRUCT_INHERENT_FIRE_MAGIC_HCT, _
		$STRUCT_INHERENT_FIRE_MAGIC_HSR, _
		$STRUCT_INHERENT_WATER_MAGIC_HCT, _
		$STRUCT_INHERENT_WATER_MAGIC_HSR, _
		$STRUCT_INHERENT_AIR_MAGIC_HCT, _
		$STRUCT_INHERENT_AIR_MAGIC_HSR, _
		$STRUCT_INHERENT_EARTH_MAGIC_HCT, _
		$STRUCT_INHERENT_EARTH_MAGIC_HSR, _
		$STRUCT_INHERENT_ENERGY_STORAGE_HCT, _
		$STRUCT_INHERENT_ENERGY_STORAGE_HSR, _
		$STRUCT_INHERENT_SMITING_PRAYERS_HCT, _
		$STRUCT_INHERENT_SMITING_PRAYERS_HSR, _
		$STRUCT_INHERENT_DIVINE_FAVOR_HCT, _
		$STRUCT_INHERENT_DIVINE_FAVOR_HSR, _
		$STRUCT_INHERENT_HEALING_PRAYERS_HCT, _
		$STRUCT_INHERENT_HEALING_PRAYERS_HSR, _
		$STRUCT_INHERENT_PROTECTION_PRAYERS_HCT, _
		$STRUCT_INHERENT_PROTECTION_PRAYERS_HSR, _
		$STRUCT_INHERENT_CHANNELING_MAGIC_HCT, _
		$STRUCT_INHERENT_CHANNELING_MAGIC_HSR, _
		$STRUCT_INHERENT_RESTORATION_MAGIC_HCT, _
		$STRUCT_INHERENT_RESTORATION_MAGIC_HSR, _
		$STRUCT_INHERENT_COMMUNING_HCT, _
		$STRUCT_INHERENT_COMMUNING_HSR, _
		$STRUCT_INHERENT_SPAWNING_POWER_HCT, _
		$STRUCT_INHERENT_SPAWNING_POWER_HSR, _
		$STRUCT_INHERENT_ILLUSION_MAGIC_HCT, _
		$STRUCT_INHERENT_ILLUSION_MAGIC_HSR, _
		$STRUCT_INHERENT_DOMINATION_MAGIC_HCT, _
		$STRUCT_INHERENT_DOMINATION_MAGIC_HSR, _
		$STRUCT_INHERENT_INSPIRATION_MAGIC_HCT, _
		$STRUCT_INHERENT_INSPIRATION_MAGIC_HSR, _
		$STRUCT_INHERENT_DEATH_MAGIC_HCT, _
		$STRUCT_INHERENT_DEATH_MAGIC_HSR, _
		$STRUCT_INHERENT_BLOOD_MAGIC_HCT, _
		$STRUCT_INHERENT_BLOOD_MAGIC_HSR, _
		$STRUCT_INHERENT_SOUL_REAPING_HCT, _
		$STRUCT_INHERENT_SOUL_REAPING_HSR, _
		$STRUCT_INHERENT_CURSES_HCT, _
		$STRUCT_INHERENT_CURSES_HSR _
	]
	For $struct In $inherentStructs
		If StringInStr($modStruct, $struct) > 0 Then Return True
	Next
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


Func SharedLootIdentifyAndSellLoot($tradeTown = $trade_town)
	Info('Inventory full - identifying and selling loot')
	TravelToOutpost($tradeTown, $district_name)
	SharedLootIdentifyAll()
	SellItemsToMerchant(SharedLootShouldSellItem)
EndFunc
