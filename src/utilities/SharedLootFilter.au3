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
Global $shared_loot_gold_value_alert = ''
Global Const $shared_loot_keeper_armor_structs[] = [ _
	$STRUCT_ALL_RUNES_SUPERIOR_VIGOR, _
	$STRUCT_ALL_RUNES_MAJOR_VIGOR, _
	$STRUCT_MESMER_INSIGNIAS_PRODIGYS, _
	$STRUCT_RITUALIST_INSIGNIAS_SHAMANS _
]


Func SharedLootShouldKeepItem($item)
	If Not SharedLootIsKeeper($item) Then Return False
	SharedLootFlagGoldValueKeeper($item)
	Return True
EndFunc


;~ Kept items whose merchant value is a multiple of 100 are collector material (x00 GV)
Func SharedLootFlagGoldValueKeeper($item)
	Local $value = DllStructGetData($item, 'Value')
	If $value < 100 Or Mod($value, 100) <> 0 Then Return
	Local $typeName = $WEAPON_NAMES_FROM_TYPES[DllStructGetData($item, 'Type')]
	If $typeName == Null Then $typeName = 'Item'
	$shared_loot_gold_value_alert = $value & ' GV keeper: ' & $typeName & ' q' & GetItemReq($item) & ' (model ' & DllStructGetData($item, 'ModelID') & ')'
	Info($shared_loot_gold_value_alert)
EndFunc


Func SharedLootIsKeeper($item)
	Local $itemID = DllStructGetData($item, 'ModelID')

	If IsTome($itemID) Then Return $itemID == $ID_DERVISH_ELITETOME
	If IsArmorSalvageItem($item) Then Return SharedLootIsKeepableArmor($item)
	If Not IsWeapon($item) Then Return False

	Local $itemType = DllStructGetData($item, 'type')
	Local $req = GetItemReq($item)

	;~ Suntouched staffs sit in the rare weapon list but drop far too often to be worth a stash slot
	If $itemID >= $ID_SUNTOUCHED_STAFF_INSPIRATION And $itemID <= $ID_SUNTOUCHED_STAFF_SPAWNING_POWER Then Return False

	If $MAP_ULTRA_RARE_WEAPONS[$itemID] <> Null Then Return True

	If $itemID == $ID_GLACIAL_BLADE Or $itemID == $ID_GLACIAL_BLADES Then Return True

	If $itemID >= $ID_BONE_DRAGON_STAFF_DOMINATION And $itemID <= $ID_BONE_DRAGON_STAFF_CHANNELING Then Return True

	;~ Green uniques are junk except on the farms that exist to farm them
	If GetRarity($item) == $RARITY_GREEN Then Return $shared_loot_keep_farmed_greens

	If ($itemID == $ID_DARKWING_DEFENDER Or $itemID == $ID_DARKWING_DEFENDER_TACTICS) And $req == 9 And GetRarity($item) == $RARITY_GOLD Then Return True

	If $itemID == $ID_SUNSPEAR Then Return True

	If $itemType == $ID_TYPE_SHIELD And SharedLootIsKeepableOsShield($item) Then Return True

	If ($itemID == $ID_IRIDESCENT_AEGIS Or $itemID == $ID_IRIDESCENT_AEGIS_COMMAND) And ($req == 8 Or $req == 9) And HasPerfectMods($item) Then Return True

	If SharedLootIsRareShieldSkin($itemID) And IsInscribable($item) Then Return True

	If $req == 9 Then
		Switch $itemID
			Case $ID_HOGS_GLUTTONY_TACTICS, $ID_HOGS_GLUTTONY_STRENGTH, $ID_HOGS_GLUTTONY_LEADERSHIP, _
				$ID_SPIDERS_GLUTTONY_TACTICS, $ID_SPIDERS_GLUTTONY_STRENGTH, $ID_SPIDERS_GLUTTONY_LEADERSHIP, _
				$ID_BRONZE_GUARDIAN_TACTICS, $ID_BRONZE_GUARDIAN_STRENGTH, $ID_BRONZE_GUARDIAN_LEADERSHIP, _
				$ID_BLACK_HAWKS_LUST, $ID_SCORPIONS_LUST, $ID_SCORPION_BOW, $ID_ITHAS_BOW, $ID_DARKSTEEL_LONGBOW, _
				$ID_PEACOCKS_WRATH_DOMINATION_MAGIC, $ID_QUICKSILVER_DOMINATION_MAGIC
				Return HasPerfectMods($item)
		EndSwitch
		If $itemID >= $ID_HOURGLASS_STAFF_DOMINATION_MAGIC And $itemID <= $ID_HOURGLASS_STAFF_CHANNELING Then Return True
	EndIf

	Local $modStruct = GetModStruct($item)
	If Not $modStruct Then Return False

	;~ These two shield mods are kept unconditionally, whatever the rest of the shield looks like
	If $itemType == $ID_TYPE_SHIELD Then
		If SharedLootHasInscription($modStruct, $STRUCT_INSCRIPTION_SHELTERED_BY_FAITH) Then Return True
		If StringInStr($modStruct, $STRUCT_MOD_OF_DEVOTION) Then Return True
	EndIf

	;~ A wand or focus above q9 stays junk however many mods it carries
	If ($itemType == $ID_TYPE_WAND Or $itemType == $ID_TYPE_OFFHAND) And $req > 9 Then Return False

	;~ A gold q8 piece with max stats is worth a stash slot whatever its mods
	If $req == 8 And GetRarity($item) == $RARITY_GOLD Then
		Switch $itemType
			Case $ID_TYPE_OFFHAND
				If GetFocusEnergy($item) == 12 Then Return True
			Case $ID_TYPE_SHIELD
				If GetShieldArmor($item) == 16 Then Return True
			Case $ID_TYPE_SWORD
				If IsMaxStatsForReq($item) Then Return True
		EndSwitch
	EndIf

	If ($itemType == $ID_TYPE_WAND Or $itemType == $ID_TYPE_OFFHAND) And ($req == 8 Or $req == 9) And Not IsInscribable($item) Then
		If SharedLootHasInherentChance($modStruct, $STRUCT_INHERENT_HCT_IDENTIFIER) And SharedLootHasInherentChance($modStruct, $STRUCT_INHERENT_HSR_IDENTIFIER) Then Return True
		If SharedLootHasInherentMod($modStruct, $STRUCT_5_ENERGY) And (SharedLootHasInherentChance($modStruct, $STRUCT_INHERENT_HCT_IDENTIFIER, 20) Or SharedLootHasInherentChance($modStruct, $STRUCT_INHERENT_HSR_IDENTIFIER, 20)) Then Return True
	EndIf

	If $itemType == $ID_TYPE_STAFF And $req == 9 Then
		If SharedLootHasInherentHCTOrHSR($modStruct) Or StringInStr($modStruct, $STRUCT_MOD_HSR_20) Then Return True
	EndIf

	If $req == 9 Then
		Switch $itemType
			Case $ID_TYPE_AXE, $ID_TYPE_SWORD, $ID_TYPE_HAMMER, $ID_TYPE_BOW
				If StringInStr($modStruct, $STRUCT_15_DAMAGE) Then
					If SharedLootHasInherentMod($modStruct, $STRUCT_INHERENT_VAMPIRIC_STRENGTH) Then Return True
					If SharedLootHasInherentMod($modStruct, $STRUCT_INHERENT_ZEALOUS_STRENGTH) Then Return True
				EndIf
		EndSwitch
	EndIf

	If $itemType == $ID_TYPE_SWORD And $req == 9 And Not IsInscribable($item) And GetRarity($item) == $RARITY_GOLD Then
		If SharedLootHasInherentMod($modStruct, $STRUCT_5_ENERGY) Then Return True
	EndIf

	If ($itemID == $ID_SHINOBI_BLADE Or $itemID == $ID_KATANA Or $itemID == $ID_DADAO_SWORD) And $req == 9 And GetRarity($item) == $RARITY_GOLD Then
		If SharedLootHasInscription($modStruct, $STRUCT_INSCRIPTION_STRENGTH_AND_HONOR) Then Return True
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


;~ Armor carries its rune into the stash, so these five upgrades make a piece worth keeping
Func SharedLootIsKeepableArmor($item)
	If GetRarity($item) <> $RARITY_GOLD Then Return False
	If Not IsIdentified($item) Then Return False
	Local $modStruct = GetModStruct($item)
	For $struct In $shared_loot_keeper_armor_structs
		If StringInStr($modStruct, $struct) Then Return True
	Next
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
Func SharedLootHasInherentChance($modStruct, $identifier, $minimumChance = 19)
	Local $mods = StringTrimLeft($modStruct, 2)
	For $i = 0 To StringLen($mods) / 8 - 1
		If StringMid($mods, 8 * $i + 5, 4) <> $identifier Then ContinueLoop
		If Int('0x' & StringMid($mods, 8 * $i + 3, 2)) >= $minimumChance Then Return True
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
			$ID_INCUBUS_WING, $ID_FUNGAL_ROOT, $ID_CHROMATIC_SCALE, $ID_SPIRITWOOD_PLANK, $ID_PLANT_FIBER, _
			$ID_SKREE_WING, $ID_BOLT_OF_CLOTH, $ID_JADE_BRACELET, $ID_BOLT_OF_SILK, $ID_PLAGUE_IDOL, _
			$ID_BONE, $ID_KOURNAN_PENDANT, $ID_STOLEN_GOODS, $ID_SILVER_BULLION_COIN, $ID_DEMONIC_REMAINS, _
			$ID_TANNED_HIDE_SQUARE
			Return DllStructGetData($item, 'Value') > 0
	EndSwitch
	If IsBlueScroll($itemID) Then Return DllStructGetData($item, 'Value') > 0
	If IsGoldScroll($itemID) Then Return $itemID <> $ID_UW_SCROLL And DllStructGetData($item, 'Value') > 0
	If IsWeapon($item) Then Return Not SharedLootShouldKeepItem($item)
	If SharedLootShouldKeepItem($item) Then Return False
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
	;~ Anything the filter would sell must not end up in the chest before the next sell
	If SharedLootShouldSellItem($item) Then Return False
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
