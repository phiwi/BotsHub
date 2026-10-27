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

Global $shared_loot_keep_farmed_greens = False


Func SharedLootShouldKeepItem($item)
	Local $itemID = DllStructGetData($item, 'ModelID')

	If IsTome($itemID) Then Return $itemID == $ID_DERVISH_ELITETOME
	If Not IsWeapon($item) Then Return False

	Local $itemType = DllStructGetData($item, 'type')
	Local $req = GetItemReq($item)

	If $MAP_ULTRA_RARE_WEAPONS[$itemID] <> Null Then Return True

	If $itemID == $ID_GLACIAL_BLADE Or $itemID == $ID_GLACIAL_BLADES Then Return True

	If $itemID >= $ID_BONE_DRAGON_STAFF_DOMINATION And $itemID <= $ID_BONE_DRAGON_STAFF_CHANNELING Then Return True

	;~ Green uniques are junk except on the farms that exist to farm them
	If GetRarity($item) == $RARITY_GREEN Then Return $shared_loot_keep_farmed_greens

	If $itemType == $ID_TYPE_SHIELD And $req == 8 And GetShieldArmor($item) == 16 Then Return True

	If ($itemID == $ID_DARKWING_DEFENDER Or $itemID == $ID_DARKWING_DEFENDER_TACTICS) And $req == 9 And GetRarity($item) == $RARITY_GOLD Then Return True

	If $itemType == $ID_TYPE_SHIELD And SharedLootIsKeepableOsShield($item) Then Return True

	If SharedLootIsRareShieldSkin($itemID) And IsInscribable($item) Then Return True

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

	If $itemType == $ID_TYPE_OFFHAND And $req == 8 And GetFocusEnergy($item) == 12 Then Return True
	If $itemType == $ID_TYPE_SWORD And $req == 8 And IsMaxStatsForReq($item) Then Return True

	If ($itemType == $ID_TYPE_WAND Or $itemType == $ID_TYPE_OFFHAND) And Not IsInscribable($item) Then
		If SharedLootHasInherentChance($modStruct, $STRUCT_INHERENT_HCT_IDENTIFIER) And SharedLootHasInherentChance($modStruct, $STRUCT_INHERENT_HSR_IDENTIFIER) Then Return True
	EndIf

	If $itemType == $ID_TYPE_STAFF And $req == 9 Then
		If SharedLootHasInherentHCTOrHSR($modStruct) Or StringInStr($modStruct, $STRUCT_MOD_HSR_20) Then Return True
	EndIf

	If $req == 9 Then
		Switch $itemType
			Case $ID_TYPE_AXE, $ID_TYPE_SWORD, $ID_TYPE_HAMMER, $ID_TYPE_BOW
				If SharedLootHasInherentMod($modStruct, $STRUCT_INHERENT_VAMPIRIC_STRENGTH) Then Return True
				If SharedLootHasInherentMod($modStruct, $STRUCT_INHERENT_ZEALOUS_STRENGTH) Then Return True
		EndSwitch
	EndIf

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


;~ Old school shields are only worth keeping as gold q8/q9 with two valuable mods
Func SharedLootIsKeepableOsShield($item)
	If IsInscribable($item) Then Return False
	If GetRarity($item) <> $RARITY_GOLD Then Return False
	Local $req = GetItemReq($item)
	If $req <> 8 And $req <> 9 Then Return False
	Return HasPerfectMods($item)
EndFunc


Func SharedLootIsRareShieldSkin($itemID)
	Switch $itemID
		Case $ID_OMINOUS_AEGIS_TACTICS, $ID_OMINOUS_AEGIS_STRENGTH, $ID_OMINOUS_AEGIS_LEADERSHIP, _
			$ID_JAPAN_1ST_ANNIVERSARY_SHIELD_STRENGTH, $ID_JAPAN_1ST_ANNIVERSARY_SHIELD_TACTICS, $ID_JAPAN_1ST_ANNIVERSARY_SHIELD_LEADERSHIP, _
			$ID_BLADED_SHIELD, $ID_BLADED_SHIELD_2, $ID_DRAGON_FANGS, $ID_OUTCAST_SHIELD, $ID_OUTCAST_SHIELD_2, _
			$ID_CELESTIAL_SHIELD, $ID_CELESTIAL_SHIELD_2, $ID_ECHOVALD_SHIELD_STRENGTH, $ID_ECHOVALD_SHIELD_TACTICS, _
			$ID_DIAMOND_AEGIS, $ID_DIAMOND_AEGIS_2, $ID_DIAMOND_AEGIS_3, $ID_ORNATE_SHIELD, _
			$ID_PLAGUEBORN_SHIELD_STRENGTH, $ID_PLAGUEBORN_SHIELD_TACTICS, $ID_GOTHIC_DEFENDER, $ID_GOTHIC_DEFENDER_2
			Return True
	EndSwitch
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


Func SharedLootHasInherentMod($modStruct, $struct)
	Local $pos = StringInStr($modStruct, $struct)
	While $pos > 0
		If Not IsWeaponUpgradeStruct($modStruct, $pos) And Not IsInscriptionStruct($modStruct, $pos) Then Return True
		$pos = StringInStr($modStruct, $struct, 0, 1, $pos + 1)
	WEnd
	Return False
EndFunc


;~ Half skill recharge and half casting time mods roll 19-20% when tied to one attribute, 9-10% when tied to all spells
Func SharedLootHasInherentChance($modStruct, $identifier)
	Local $mods = StringTrimLeft($modStruct, 2)
	For $i = 0 To StringLen($mods) / 8 - 1
		If StringMid($mods, 8 * $i + 5, 4) <> $identifier Then ContinueLoop
		If Int('0x' & StringMid($mods, 8 * $i + 3, 2)) >= 19 Then Return True
	Next
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

	Local $itemID = DllStructGetData($item, 'ModelID')
	If IsKey($itemID) And $itemID <> $ID_ZAISHEN_KEY Then Return DllStructGetData($item, 'Value') > 0
	Switch $itemID
		Case $ID_UNDEAD_BONE, $ID_KRAIT_SKIN, $ID_SENTIENT_VINE, $ID_SKELK_FANG, $ID_SKELK_CLAW, _
			$ID_SAURIAN_BONE, $ID_BEETLE_EGG, $ID_AMPHIBIAN_TONGUE, $ID_BERSERKER_HORN, $ID_DRAGON_ROOT, _
			$ID_INCUBUS_WING
			Return DllStructGetData($item, 'Value') > 0
	EndSwitch
	If IsBlueScroll($itemID) Then Return DllStructGetData($item, 'Value') > 0
	If IsGoldScroll($itemID) Then Return $itemID <> $ID_UW_SCROLL And DllStructGetData($item, 'Value') > 0
	If IsWeapon($item) Or IsTome($itemID) Then Return Not SharedLootShouldKeepItem($item)
	Return DefaultShouldSellItem($item)
EndFunc


;~ Green items stay lootable on the farms that exist to farm them
Func SharedLootShouldPickItem($item)
	If $shared_loot_keep_farmed_greens And GetRarity($item) == $RARITY_GREEN Then Return True
	Return DefaultShouldPickItem($item)
EndFunc


Func SharedLootShouldStoreItem($item)
	If DllStructGetData($item, 'Equipped') > 0 Then Return False
	If DllStructGetData($item, 'Customized') <> 0 Then Return False
	If SharedLootShouldKeepItem($item) Then Return True
	If IsWeapon($item) Then Return False
	Return DefaultShouldStoreItem($item)
EndFunc


Func SharedLootIdentifyAndSellLoot()
	Info('Inventory full - identifying and selling loot')
	TravelToOutpost($trade_town, $district_name)
	IdentifyAllLootItems()
	SellItemsToMerchant(SharedLootShouldSellItem)
	StoreItemsInXunlaiStorage(SharedLootShouldStoreItem)
EndFunc


Func SharedLootForceInventoryClear()
	Return InventoryManagementBeforeRun(SharedLootShouldSellItem, SharedLootShouldStoreItem, True)
EndFunc
