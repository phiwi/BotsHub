#CS ===========================================================================
; Copyright 2026 caustic-kronos
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
#include <Array.au3>
#include <Math.au3>
#include 'GWA2.au3'
#include 'GWA2_ID.au3'
#include 'Utils.au3'
#include 'Utils-Console.au3'

Global Const $PARTY_BASE64_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'


;~ Prints the build code of the player and of up to 7 heroes
Func DumpPartyBuilds()
	Local $heroCount = GetHeroCount()
	Info('Party builds (' & $heroCount & ' hero(es))')
	PartyPrintBuildCode(0, 'Player')
	For $heroIndex = 1 To $heroCount
		PartyPrintBuildCode($heroIndex, PartyHeroName(PartyHeroCatalogID($heroIndex)))
	Next
	Return $PAUSE
EndFunc


Func PartyPrintBuildCode($heroIndex, $name)
	Local $code = PartyBuildCode($heroIndex, PartyAttributeTable($heroIndex))
	If HeroHasTemplate($heroIndex, $code) Then
		Out('[' & $heroIndex & '] ' & $name & '  ' & $code, $LVL_NOTICE)
	Else
		Out('[' & $heroIndex & '] ' & $name & '  ' & $code & ' [MISMATCH]', $LVL_WARNING)
	EndIf
EndFunc


;~ Hero catalog id (e.g. $ID_NORGU) of the hero sitting at the given party index
Func PartyHeroCatalogID($heroIndex)
	If $heroIndex <= 0 Then Return Null
	Local $offset[] = [0, 0x18, 0x4C, 0x54, 0x24, 8 + 0x18 * ($heroIndex - 1)]
	Local $heroID = MemoryReadPtr(GetProcessHandle(), $base_address_ptr, $offset)
	Return $heroID[1]
EndFunc


Func PartyHeroName($heroID)
	If $heroID == Null Then Return 'unknown hero'
	Local $index = _ArraySearch($HERO_IDS, $heroID)
	If $index < 0 Then Return 'hero ' & $heroID
	Return $HERO_NAMES[$index]
EndFunc


Func PartyPrimaryAndSecondary($heroIndex)
	Local $professions[2]
	If $heroIndex == 0 Then
		Local $me = GetMyAgent()
		$professions[0] = DllStructGetData($me, 'Primary')
		$professions[1] = DllStructGetData($me, 'Secondary')
	Else
		$professions[0] = GetHeroProfession($heroIndex)
		$professions[1] = GetHeroProfession($heroIndex, True)
	EndIf
	For $i = 0 To 1
		If $professions[$i] == Null Then $professions[$i] = 0
	Next
	Return $professions
EndFunc


;~ [attribute id, points spent] pairs of the given party index; points are the rune-less values a template stores
Func PartyAttributeTable($heroIndex)
	Local $table[UBound($ATTRIBUTES_DOUBLE_ARRAY)][2]
	For $row = 0 To UBound($ATTRIBUTES_DOUBLE_ARRAY) - 1
		Local $attributeID = $ATTRIBUTES_DOUBLE_ARRAY[$row][0]
		Local $level = GetAttributeByID($attributeID, False, $heroIndex)
		If $level == Null Then $level = 0
		$table[$row][0] = $attributeID
		$table[$row][1] = $level
	Next
	Return $table
EndFunc


;~ Encodes the professions, attributes and skillbar of the given party index as a skill template code
Func PartyBuildCode($heroIndex, $attributes)
	Local $professions = PartyPrimaryAndSecondary($heroIndex)

	Local $spentAttributes[UBound($attributes)][2]
	Local $attributeCount = 0
	Local $attributeBits = 4
	For $row = 0 To UBound($attributes) - 1
		If $attributes[$row][1] <= 0 Then ContinueLoop
		$spentAttributes[$attributeCount][0] = $attributes[$row][0]
		$spentAttributes[$attributeCount][1] = $attributes[$row][1]
		$attributeCount += 1
		$attributeBits = _Max($attributeBits, PartyBitLength($attributes[$row][0]))
	Next

	Local $skills[8]
	Local $skillBits = 8
	For $slot = 1 To 8
		Local $skillID = GetSkillbarSkillID($slot, $heroIndex)
		If $skillID == Null Then $skillID = 0
		$skills[$slot - 1] = $skillID
		$skillBits = _Max($skillBits, PartyBitLength($skillID))
	Next

	Local $highestProfession = _Max($professions[0], $professions[1])
	Local $professionCode = 0
	If $highestProfession > 0 Then $professionCode = _Max(0, Ceiling(PartyBitLength($highestProfession) / 2) - 2)
	Local $professionWidth = $professionCode * 2 + 4

	Local $bits = PartyBits(14, 4) & PartyBits(0, 4) & PartyBits($professionCode, 2)
	$bits &= PartyBits($professions[0], $professionWidth) & PartyBits($professions[1], $professionWidth)
	$bits &= PartyBits($attributeCount, 4) & PartyBits($attributeBits - 4, 4)
	For $i = 0 To $attributeCount - 1
		$bits &= PartyBits($spentAttributes[$i][0], $attributeBits) & PartyBits($spentAttributes[$i][1], 4)
	Next
	$bits &= PartyBits($skillBits - 8, 4)
	For $i = 0 To 7
		$bits &= PartyBits($skills[$i], $skillBits)
	Next

	$bits &= '0'
	While Mod(StringLen($bits), 6) <> 0
		$bits &= '0'
	WEnd
	Return PartyBitsToBase64($bits)
EndFunc


;~ Fixed width binary representation of a value, lowest bit first
Func PartyBits($value, $width)
	Local $bits = ''
	For $i = 1 To $width
		$bits &= Mod($value, 2) == 0 ? '0' : '1'
		$value = Floor($value / 2)
	Next
	Return $bits
EndFunc


Func PartyBitLength($value)
	Local $bits = 0
	While $value > 0
		$value = Floor($value / 2)
		$bits += 1
	WEnd
	Return $bits
EndFunc


Func PartyBitsToBase64($bits)
	Local $code = ''
	For $i = 1 To StringLen($bits) Step 6
		Local $chunk = StringMid($bits, $i, 6)
		Local $value = 0
		For $j = 1 To 6
			If StringMid($chunk, $j, 1) == '1' Then $value += 2 ^ ($j - 1)
		Next
		$code &= StringMid($PARTY_BASE64_ALPHABET, $value + 1, 1)
	Next
	Return $code
EndFunc
