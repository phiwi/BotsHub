#CS ===========================================================================
; Author: TDawg
; Contributor: Gahais
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
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2_Headers.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils.au3'
#include '../utilities/SupportTeam.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $FROGGY_FARM_INFORMATIONS = 'For best results, do not cheap out on heroes' & @CRLF _
	& 'Testing was done with a ROJ monk and an adapted mesmerway (1 E-surge replaced by a ROJ, ineptitude replaced by blinding surge)' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded rooms' & @CRLF _
	& '32mn average in NM' & @CRLF _
	& '41mn average in HM with consets (automatically used if HM is on)'

Global Const $FROGGY_AGGRO_RANGE = $RANGE_SPELLCAST + 100
Global Const $ID_FROGGY_QUEST = $ID_QUEST_GIRIFFS_WAR
;Global Const $ID_FROGGY_QUEST = $ID_QUEST_TEKKS_WAR

Global Const $FROGGY_FARM_DURATION = 40 * 60 * 1000
Global Const $MAX_FROGGY_FARM_DURATION = 60 * 60 * 1000
Global Const $FROGGY_HERO_PANELS_TEST_DURATION = 30 * 1000
Global Const $FROGGY_TEAM_ASSEMBLY_PASSES = 4
Global Const $FROGGY_TEAM_MISSING_FALLBACK_PASSES = 3
Global Const $FROGGY_TEAM_OUTPOST_RETRIES = 4
Global Const $FROGGY_TEMPLATE_LOAD_RETRIES = 5
Global Const $FROGGY_ASSASSIN_SKILLBAR = 'OwhiAyiMVNNAeNd28N5DWOxMBA'
Global Const $FROGGY_ELEMENTALIST_SKILLBAR = 'OgdTgYm6RicYX0m0V8bwNDdYUAA'
Global Const $FROGGY_ASSASSIN_WEAPON_SET = 2
Global Const $FROGGY_ELEMENTALIST_WEAPON_SET = 3
Global Const $FROGGY_ASSASSIN_HERO_GWEN_TEMPLATE = 'OQhjAwBc4QkA5ZIg3ATAcQFVXMA'
;~ Global Const $FROGGY_ASSASSIN_HERO_MOW_TEMPLATE = 'OANDYazPSxVNgeETffEaRJg1NA' ; Healer's Boon
Global Const $FROGGY_ASSASSIN_HERO_MOW_TEMPLATE = 'OAlkUwG4RZmUMjC4OWN2uzWYVgdA' ; Xinrae
Global Const $FROGGY_ASSASSIN_HERO_OLIAS_TEMPLATE = 'OAlkUwG4RZmUMjC4OWNWC4WIegdA'
Global Const $FROGGY_ASSASSIN_HERO_DUNKORO_TEMPLATE = 'OwAT02HCXyLaj4upe4ua6DC0oBA'
Global Const $FROGGY_ASSASSIN_HERO_NORGU_TEMPLATE = 'OQREAsIjU8MV5aI/dwPgnWFQDA'
Global Const $FROGGY_ASSASSIN_HERO_RAZAH_TEMPLATE = 'OQREAsIjU8MV5aI/ewPgnWFQDA' ; ESurge
Global Const $FROGGY_ASSASSIN_HERO_LIVIA_TEMPLATE = 'OABDUslXSLVUB4BWClBbhVVKgA' ; Bone Fiends
;~ Global Const $FROGGY_ELEMENTALIST_HERO_GWEN_TEMPLATE = 'OQhkAsC8gFKzJIHM9MdjQcaG4iB' ; ESurge
;~ Global Const $FROGGY_ELEMENTALIST_HERO_GWEN_TEMPLATE = 'OQhjAwBc4QkA5ZIg3ATAcQFVXMA' ; Fevered + Clumsi
;~ Global Const $FROGGY_ELEMENTALIST_HERO_GWEN_TEMPLATE = 'OQlkAkB8wYm0LACIHUeGJgTQPFRA' ; Inep + Epi + Frust
Global Const $FROGGY_ELEMENTALIST_HERO_GWEN_TEMPLATE = 'OQlkAkB8wYm0LACIHUeGJQPVGwOG' ; Inep + Command

;~ Global Const $FROGGY_ELEMENTALIST_HERO_GWEN_TEMPLATE = 'OQBDAawDSvAIg5ZkATAcQOB9UA' ; Frust/Epi/Frag
;~ Global Const $FROGGY_ELEMENTALIST_HERO_NORGU_TEMPLATE = 'OQhkAsC8gFKzJIHM9MdjQcaG4iB' ; ESurge
;~ Global Const $FROGGY_ELEMENTALIST_HERO_NORGU_TEMPLATE = 'OQhkAsC8gFKTIc6lDupDBTXG4iB' ; Psychic Inst
Global Const $FROGGY_ELEMENTALIST_HERO_NORGU_TEMPLATE = 'OQhkAoC8AGKzJAna6me5gMAR4iB' ; Esurge
;~ Global Const $FROGGY_ELEMENTALIST_HERO_RAZAH_TEMPLATE = 'OQhkAsC8gFKzJIHM9MdjQcaG4iB' ; ESurge
;~ Global Const $FROGGY_ELEMENTALIST_HERO_RAZAH_TEMPLATE = 'OQhkAsC7AGODNIHM9MdjQcaG4iB' ; Panic
Global Const $FROGGY_ELEMENTALIST_HERO_RAZAH_TEMPLATE = 'OQhkAoC8AGKzJAna6me5gMAR4iB' ; Esurge
;~ Global Const $FROGGY_ELEMENTALIST_HERO_MOW_TEMPLATE = 'OANDYbzfRxVNgeETffEaRVV1DA' ; Healer's Boon
Global Const $FROGGY_ELEMENTALIST_HERO_XANDRA_TEMPLATE = 'OACjAyhDJPYTnp17xFOhmWzLG'
;~ Global Const $FROGGY_ELEMENTALIST_HERO_TAHLKORA_TEMPLATE = 'OwUTMwmCZaj4uJC8ioLKDoHghAA'
;~ Global Const $FROGGY_ELEMENTALIST_HERO_DUNKORO_TEMPLATE = 'OwAS4YIPGEqvLx6nPwrVfAC' ; SoJ
Global Const $FROGGY_ELEMENTALIST_HERO_DUNKORO_TEMPLATE = 'Owkj4sQqpO+sqPe9iQ9dJ3jdMA' ; RoJ + Command
Global Const $FROGGY_ELEMENTALIST_HERO_ZHED_TEMPLATE = 'OgBEgkqLzHlysOoOMNAJaM8nBNA' ; Water Magic Burning Variant
;~ Global Const $FROGGY_ELEMENTALIST_HERO_ZHED_TEMPLATE = 'OgljgwMpZSXVfDLg6QKNhD1Y7YA' ; BlindingS
Global Const $FROGGY_ELEMENTALIST_HERO_JIN_TEMPLATE = 'OggkYpXYGKq0qEuxvxnBYI0BqBGD' ; Splinter + Throw Dirt
;~ Global Const $FROGGY_ELEMENTALIST_HERO_JIN_TEMPLATE = 'OggkYpXYGKq0qEuxvxnBYI0hqBGD'
Global Const $FROGGY_ELEMENTALIST_HERO_SOUSUKE_TEMPLATE = 'OgBVgw0pwFy0Rs+nxqqj1RPMHOWB' ; Master of Magic
;~ Global Const $FROGGY_ELEMENTALIST_HERO_SOUSUKE_TEMPLATE = 'OgBEgkqLzHlysOoOMNAJaM8nBNA' ; Water Magic Burning Variant
;~ Global Const $FROGGY_ELEMENTALIST_HERO_OLIAS_TEMPLATE = 'OAhjQkGZIP3hhmwrqKNncDzxJA'
Global Const $FROGGY_ELEMENTALIST_HERO_OLIAS_TEMPLATE = 'OAhkQkG4RFyzdwOI8qqSzJ3wccC' ; BiP Resto + Enfeebling Blood
;~ Global Const $FROGGY_ELEMENTALIST_HERO_LIVIA_TEMPLATE = 'OAljUwGpZSUBKgfBVVbh8Y7Y1YA' ; Bone Fiends
;~ Global Const $FROGGY_ELEMENTALIST_HERO_LIVIA_TEMPLATE = 'OAhjUwGooSyBVBoBKgbheTYM4BA' ; Minion Bomber
Global Const $FROGGY_ELEMENTALIST_HERO_LIVIA_TEMPLATE = 'OABDUslXSLVUBVVWClBbhfBCNA' ; Bone Fiends + Curses
Global Const $FROGGY_ELEMENTALIST_HERO_OGDEN_TEMPLATE = 'Owkj4sQqpO+sqPe9iQ9dJ7YfMA' ; RoJ + Never Surrender
Global Const $FROGGY_ELEMENTALIST_HERO_VEKK_TEMPLATE = 'OgNCw8zTtgksS0i1jbydNgA' ; Ether Renewal Prot (Draw)
;~ SoO-mirrored values assigned to existing template constants below
;~ Global Const $FROGGY_ELEMENTALIST_SLOT1_HERO_ID = $ID_GWEN
;~ Global Const $FROGGY_ELEMENTALIST_SLOT1_HERO_NAME = 'Gwen'
;~ Global Const $FROGGY_ELEMENTALIST_SLOT1_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_GWEN_TEMPLATE
;~ Global Const $FROGGY_ELEMENTALIST_SLOT1_HERO_ID = $ID_ZHED_SHADOWHOOF
;~ Global Const $FROGGY_ELEMENTALIST_SLOT1_HERO_NAME = 'Zhed Shadowhoof'
;~ Global Const $FROGGY_ELEMENTALIST_SLOT1_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_ZHED_TEMPLATE
Global Const $FROGGY_ELEMENTALIST_SLOT1_HERO_ID = $ID_GWEN
Global Const $FROGGY_ELEMENTALIST_SLOT1_HERO_NAME = 'Gwen'
Global Const $FROGGY_ELEMENTALIST_SLOT1_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_GWEN_TEMPLATE

Global Const $FROGGY_ELEMENTALIST_SLOT2_HERO_ID = $ID_NORGU
Global Const $FROGGY_ELEMENTALIST_SLOT2_HERO_NAME = 'Norgu'
;~ Global Const $FROGGY_ELEMENTALIST_SLOT2_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_NORGU_TEMPLATE
Global Const $FROGGY_ELEMENTALIST_SLOT2_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_NORGU_TEMPLATE

Global Const $FROGGY_ELEMENTALIST_SLOT3_HERO_ID = $ID_RAZAH
Global Const $FROGGY_ELEMENTALIST_SLOT3_HERO_NAME = 'Razah'
;~ Global Const $FROGGY_ELEMENTALIST_SLOT3_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_RAZAH_TEMPLATE
Global Const $FROGGY_ELEMENTALIST_SLOT3_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_RAZAH_TEMPLATE

;~ Global Const $FROGGY_ELEMENTALIST_SLOT4_HERO_ID = $ID_MASTER_OF_WHISPERS
;~ Global Const $FROGGY_ELEMENTALIST_SLOT4_HERO_NAME = 'Master of Whispers'
;~ Global Const $FROGGY_ELEMENTALIST_SLOT4_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_MOW_TEMPLATE
Global Const $FROGGY_ELEMENTALIST_SLOT4_HERO_ID = $ID_XANDRA
Global Const $FROGGY_ELEMENTALIST_SLOT4_HERO_NAME = 'Xandra'
Global Const $FROGGY_ELEMENTALIST_SLOT4_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_XANDRA_TEMPLATE
;~ Global Const $FROGGY_ELEMENTALIST_SLOT4_HERO_ID = $ID_TAHLKORA
;~ Global Const $FROGGY_ELEMENTALIST_SLOT4_HERO_NAME = 'Tahlkora'
;~ Global Const $FROGGY_ELEMENTALIST_SLOT4_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_TAHLKORA_TEMPLATE

Global Const $FROGGY_ELEMENTALIST_SLOT5_HERO_ID = $ID_OLIAS
Global Const $FROGGY_ELEMENTALIST_SLOT5_HERO_NAME = 'Olias'
;~ Global Const $FROGGY_ELEMENTALIST_SLOT5_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_OLIAS_TEMPLATE
Global Const $FROGGY_ELEMENTALIST_SLOT5_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_OLIAS_TEMPLATE

;~ Global Const $FROGGY_ELEMENTALIST_SLOT6_HERO_ID = $ID_VEKK
;~ Global Const $FROGGY_ELEMENTALIST_SLOT6_HERO_NAME = 'Vekk'
;~ Global Const $FROGGY_ELEMENTALIST_SLOT6_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_VEKK_TEMPLATE
Global Const $FROGGY_ELEMENTALIST_SLOT6_HERO_ID = $ID_DUNKORO
Global Const $FROGGY_ELEMENTALIST_SLOT6_HERO_NAME = 'Dunkoro'
Global Const $FROGGY_ELEMENTALIST_SLOT6_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_DUNKORO_TEMPLATE

Global Const $FROGGY_ELEMENTALIST_SLOT7_HERO_ID = $ID_LIVIA
Global Const $FROGGY_ELEMENTALIST_SLOT7_HERO_NAME = 'Livia'
Global Const $FROGGY_ELEMENTALIST_SLOT7_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_LIVIA_TEMPLATE
;~ Global Const $FROGGY_ELEMENTALIST_SLOT7_HERO_ID = $ID_ACOLYTE_SOUSUKE
;~ Global Const $FROGGY_ELEMENTALIST_SLOT7_HERO_NAME = 'Acolyte Sousuke'
;~ Global Const $FROGGY_ELEMENTALIST_SLOT7_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_SOUSUKE_TEMPLATE
;~ Global Const $FROGGY_ELEMENTALIST_SLOT7_HERO_ID = $ID_OGDEN
;~ Global Const $FROGGY_ELEMENTALIST_SLOT7_HERO_NAME = 'Ogden Stonehealer'
;~ Global Const $FROGGY_ELEMENTALIST_SLOT7_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_OGDEN_TEMPLATE
;~ Global Const $FROGGY_ELEMENTALIST_SLOT7_HERO_ID = $ID_XANDRA
;~ Global Const $FROGGY_ELEMENTALIST_SLOT7_HERO_NAME = 'Xandra'
;~ Global Const $FROGGY_ELEMENTALIST_SLOT7_HERO_TEMPLATE = $FROGGY_ELEMENTALIST_HERO_XANDRA_TEMPLATE

Global $froggy_farm_setup = False

;~ Main method to farm Froggy
Func FroggyFarm()
	If Not $froggy_farm_setup And SetupFroggyFarm() == $FAIL Then Return $FAIL
	Return FroggyFarmLoop()
EndFunc


Func FroggyHeroPanelsPseudoFarm()
	Info('Froggy hero-panel pseudo farm: setup team and expand all hero skill panels')
	If TravelToOutpost($ID_GADDS_ENCAMPMENT, $district_name) == $FAIL Then Return $PAUSE
	If SetupFroggyElementalistTeam(True) == $FAIL Then Return $PAUSE
	ForceFroggyElementalistWeaponSet()
	FroggyTryOpenHeroPanelsForMonitoring()
	Info('Froggy hero-panel pseudo farm done')
	Return $PAUSE
EndFunc


;~ Wait for party to be alive, and if a wipe happened, clear all hero flags so they follow from shrine.
Func FroggyWaitUntilPartyAlive()
	Local $wasWiped = IsPlayerAndPartyWiped()
	WaitUntilPartyAlive()
	If $wasWiped Then CancelAllHeroes()
EndFunc


;~ Froggy farm setup
Func SetupFroggyFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_GADDS_ENCAMPMENT, $district_name) == $FAIL Then Return $FAIL
	If Not SupportTeamStabilizeAfterTravel($ID_GADDS_ENCAMPMENT, 10000, 250) Then
		Warn('Froggy setup: outpost stabilization timed out before team setup')
	EndIf
	;~ If SetupFroggyAssassinOverrides() == $FAIL Then Return $FAIL
	If SetupFroggyElementalistOverrides() == $FAIL Then Return $FAIL
	ForceFroggyElementalistWeaponSet()
	SetDisplayedTitle($ID_ASURA_TITLE)
	SwitchToHardModeIfEnabled()
	While Not $froggy_farm_setup
		If RunToBogroot() == $FAIL Then ContinueLoop
		$froggy_farm_setup = True
	WEnd
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupFroggyAssassinOverrides()
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_ASSASSIN Then Return $SUCCESS

	Info('Froggy Assassin mode: loading Sin build, weapon set 2, and fixed support team')
	If HeroHasTemplate(0, $FROGGY_ASSASSIN_SKILLBAR) Then
		Info('Froggy player: template already loaded, skipping')
	Else
		LoadSkillTemplate($FROGGY_ASSASSIN_SKILLBAR)
		RandomSleep(250)
	EndIf
	ChangeWeaponSet($FROGGY_ASSASSIN_WEAPON_SET)
	RandomSleep(150)

	If SetupFroggySinTeamFromWingstorm() == $FAIL Then
		Warn('Could not apply Froggy Assassin fixed team setup')
		Return $FAIL
	EndIf

	Return $SUCCESS
EndFunc


Func SetupFroggyElementalistOverrides()
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_ELEMENTALIST Then Return $SUCCESS

	Info('Froggy Elementalist mode: loading Ele build, weapon set 3 and fixed Elementalist team')
	If HeroHasTemplate(0, $FROGGY_ELEMENTALIST_SKILLBAR) Then
		Info('Froggy player: template already loaded, skipping')
	Else
		LoadSkillTemplate($FROGGY_ELEMENTALIST_SKILLBAR)
		RandomSleep(250)
	EndIf
	ChangeWeaponSet($FROGGY_ELEMENTALIST_WEAPON_SET)
	RandomSleep(150)

	If SetupFroggyElementalistTeam() == $FAIL Then
		Warn('Could not apply Froggy Elementalist fixed team setup')
		Return $FAIL
	EndIf

	FroggyTryOpenHeroPanelsForMonitoring()

	Return $SUCCESS
EndFunc


Func SetupFroggyElementalistTeam($skipBuildLoad = False)
	Info('Froggy Elementalist team: ' & $FROGGY_ELEMENTALIST_SLOT1_HERO_NAME & ', ' & $FROGGY_ELEMENTALIST_SLOT2_HERO_NAME & ', ' & $FROGGY_ELEMENTALIST_SLOT3_HERO_NAME & ', ' & $FROGGY_ELEMENTALIST_SLOT4_HERO_NAME & ', ' & $FROGGY_ELEMENTALIST_SLOT5_HERO_NAME & ', ' & $FROGGY_ELEMENTALIST_SLOT6_HERO_NAME & ', ' & $FROGGY_ELEMENTALIST_SLOT7_HERO_NAME)
	Local $heroIDs[7] = [ _
		$FROGGY_ELEMENTALIST_SLOT1_HERO_ID, _
		$FROGGY_ELEMENTALIST_SLOT2_HERO_ID, _
		$FROGGY_ELEMENTALIST_SLOT3_HERO_ID, _
		$FROGGY_ELEMENTALIST_SLOT4_HERO_ID, _
		$FROGGY_ELEMENTALIST_SLOT5_HERO_ID, _
		$FROGGY_ELEMENTALIST_SLOT6_HERO_ID, _
		$FROGGY_ELEMENTALIST_SLOT7_HERO_ID _
	]
	Local $heroNames[7] = [ _
		$FROGGY_ELEMENTALIST_SLOT1_HERO_NAME, _
		$FROGGY_ELEMENTALIST_SLOT2_HERO_NAME, _
		$FROGGY_ELEMENTALIST_SLOT3_HERO_NAME, _
		$FROGGY_ELEMENTALIST_SLOT4_HERO_NAME, _
		$FROGGY_ELEMENTALIST_SLOT5_HERO_NAME, _
		$FROGGY_ELEMENTALIST_SLOT6_HERO_NAME, _
		$FROGGY_ELEMENTALIST_SLOT7_HERO_NAME _
	]
	Local $heroTemplates[7] = [ _
		$FROGGY_ELEMENTALIST_SLOT1_HERO_TEMPLATE, _
		$FROGGY_ELEMENTALIST_SLOT2_HERO_TEMPLATE, _
		$FROGGY_ELEMENTALIST_SLOT3_HERO_TEMPLATE, _
		$FROGGY_ELEMENTALIST_SLOT4_HERO_TEMPLATE, _
		$FROGGY_ELEMENTALIST_SLOT5_HERO_TEMPLATE, _
		$FROGGY_ELEMENTALIST_SLOT6_HERO_TEMPLATE, _
		$FROGGY_ELEMENTALIST_SLOT7_HERO_TEMPLATE _
	]

	If FroggyAssembleFixedTeamWithRecovery($heroIDs, $heroNames, 'Froggy Elementalist') == $FAIL Then Return $FAIL
	If Not SupportTeamHasExactHeroes($heroIDs, 8) Or GetHeroCount() < 7 Then
		Warn('Froggy Elementalist setup aborted: incomplete hero team before template load (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')
		FroggyWarnMissingHeroes($heroIDs, $heroNames, 'Froggy Elementalist')
		Return $FAIL
	EndIf
	If FroggyVerifyTeamState($heroIDs, $heroNames, $heroTemplates, 'Froggy Elementalist') == $FAIL Then Return $FAIL

	If Not $skipBuildLoad Then
		If FroggyLoadHeroTemplateByID($FROGGY_ELEMENTALIST_SLOT1_HERO_ID, $FROGGY_ELEMENTALIST_SLOT1_HERO_NAME, $FROGGY_ELEMENTALIST_SLOT1_HERO_TEMPLATE) == $FAIL Then Return $FAIL
		If FroggyLoadHeroTemplateByID($FROGGY_ELEMENTALIST_SLOT2_HERO_ID, $FROGGY_ELEMENTALIST_SLOT2_HERO_NAME, $FROGGY_ELEMENTALIST_SLOT2_HERO_TEMPLATE) == $FAIL Then Return $FAIL
		If FroggyLoadHeroTemplateByID($FROGGY_ELEMENTALIST_SLOT3_HERO_ID, $FROGGY_ELEMENTALIST_SLOT3_HERO_NAME, $FROGGY_ELEMENTALIST_SLOT3_HERO_TEMPLATE) == $FAIL Then Return $FAIL
		If FroggyLoadHeroTemplateByID($FROGGY_ELEMENTALIST_SLOT4_HERO_ID, $FROGGY_ELEMENTALIST_SLOT4_HERO_NAME, $FROGGY_ELEMENTALIST_SLOT4_HERO_TEMPLATE) == $FAIL Then Return $FAIL
		If FroggyLoadHeroTemplateByID($FROGGY_ELEMENTALIST_SLOT5_HERO_ID, $FROGGY_ELEMENTALIST_SLOT5_HERO_NAME, $FROGGY_ELEMENTALIST_SLOT5_HERO_TEMPLATE) == $FAIL Then Return $FAIL
		If FroggyLoadHeroTemplateByID($FROGGY_ELEMENTALIST_SLOT6_HERO_ID, $FROGGY_ELEMENTALIST_SLOT6_HERO_NAME, $FROGGY_ELEMENTALIST_SLOT6_HERO_TEMPLATE) == $FAIL Then Return $FAIL
		If FroggyLoadHeroTemplateByID($FROGGY_ELEMENTALIST_SLOT7_HERO_ID, $FROGGY_ELEMENTALIST_SLOT7_HERO_NAME, $FROGGY_ELEMENTALIST_SLOT7_HERO_TEMPLATE) == $FAIL Then Return $FAIL
		RandomSleep(250)
	EndIf

	ClearPartyCommands()
	CancelAllHeroes()
	Return $SUCCESS
EndFunc


Func SetupFroggySinTeamFromWingstorm()
	Info('Froggy Assassin team: Gwen, Norgu, Razah, Master of Whispers, Olias, Livia, Dunkoro')
	Local $heroIDs[7] = [ _
		$ID_GWEN, _
		$ID_NORGU, _
		$ID_RAZAH, _
		$ID_MASTER_OF_WHISPERS, _
		$ID_OLIAS, _
		$ID_LIVIA, _
		$ID_DUNKORO _
	]
	Local $heroNames[7] = [ _
		'Gwen', _
		'Norgu', _
		'Razah', _
		'Master of Whispers', _
		'Olias', _
		'Livia', _
		'Dunkoro' _
	]
	Local $heroTemplates[7] = [ _
		$FROGGY_ASSASSIN_HERO_GWEN_TEMPLATE, _
		$FROGGY_ASSASSIN_HERO_NORGU_TEMPLATE, _
		$FROGGY_ASSASSIN_HERO_RAZAH_TEMPLATE, _
		$FROGGY_ASSASSIN_HERO_MOW_TEMPLATE, _
		$FROGGY_ASSASSIN_HERO_OLIAS_TEMPLATE, _
		$FROGGY_ASSASSIN_HERO_LIVIA_TEMPLATE, _
		$FROGGY_ASSASSIN_HERO_DUNKORO_TEMPLATE _
	]

	If FroggyAssembleFixedTeamWithRecovery($heroIDs, $heroNames, 'Froggy Assassin') == $FAIL Then Return $FAIL
	If Not SupportTeamHasExactHeroes($heroIDs, 8) Or GetHeroCount() < 7 Then
		Warn('Froggy Assassin setup aborted: incomplete hero team before template load (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')
		FroggyWarnMissingHeroes($heroIDs, $heroNames, 'Froggy Assassin')
		Return $FAIL
	EndIf
	If FroggyVerifyTeamState($heroIDs, $heroNames, $heroTemplates, 'Froggy Assassin') == $FAIL Then Return $FAIL

	If FroggyLoadHeroTemplateByID($ID_GWEN, 'Gwen', $FROGGY_ASSASSIN_HERO_GWEN_TEMPLATE) == $FAIL Then Return $FAIL
	If FroggyLoadHeroTemplateByID($ID_NORGU, 'Norgu', $FROGGY_ASSASSIN_HERO_NORGU_TEMPLATE) == $FAIL Then Return $FAIL
	If FroggyLoadHeroTemplateByID($ID_RAZAH, 'Razah', $FROGGY_ASSASSIN_HERO_RAZAH_TEMPLATE) == $FAIL Then Return $FAIL
	If FroggyLoadHeroTemplateByID($ID_MASTER_OF_WHISPERS, 'Master of Whispers', $FROGGY_ASSASSIN_HERO_MOW_TEMPLATE) == $FAIL Then Return $FAIL
	If FroggyLoadHeroTemplateByID($ID_OLIAS, 'Olias', $FROGGY_ASSASSIN_HERO_OLIAS_TEMPLATE) == $FAIL Then Return $FAIL
	If FroggyLoadHeroTemplateByID($ID_LIVIA, 'Livia', $FROGGY_ASSASSIN_HERO_LIVIA_TEMPLATE) == $FAIL Then Return $FAIL
	If FroggyLoadHeroTemplateByID($ID_DUNKORO, 'Dunkoro', $FROGGY_ASSASSIN_HERO_DUNKORO_TEMPLATE) == $FAIL Then Return $FAIL
	RandomSleep(250)

	ClearPartyCommands()
	CancelAllHeroes()
	Return $SUCCESS
EndFunc


Func FroggyEnsureSoloParty($maxWaitMs = 9000)
	Local $timer = TimerInit()
	SupportTeamKickAllHeroesByIDSweep()
	KickAllHeroes()
	LeaveParty(False)
	While TimerDiff($timer) < $maxWaitMs
		If GetPartySize() <= 1 Then Return $SUCCESS
		SupportTeamKickAllHeroesByIDSweep()
		KickAllHeroes()
		LeaveParty(False)
		RandomSleep(320)
	WEnd
	Warn('Froggy team: party reset timeout. Party=' & GetPartySize() & ', heroes=' & GetHeroCount())
	Return $FAIL
EndFunc


Func FroggyVerifyTeamState(ByRef $heroIDs, ByRef $heroNames, ByRef $heroTemplates, $teamLabel)
	Local $issues = 0
	Info($teamLabel & ' verify: begin (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')

	For $i = 0 To UBound($heroIDs) - 1
		Local $heroID = $heroIDs[$i]
		Local $heroName = $heroNames[$i]
		Local $heroIndex = GetHeroNumberByHeroID($heroID)
		Local $expectedProfession = FroggyGetTemplatePrimaryProfession($heroTemplates[$i])
		Local $actualProfession = -1
		If $heroIndex <> Null Then $actualProfession = GetHeroProfession($heroIndex)

		If $heroIndex == Null Then
			$issues += 1
			Info($teamLabel & ' verify: ' & $heroName & ' id=' & $heroID & ' slot=missing actualProf=na expectedProf=' & $expectedProfession)
		Else
			If $expectedProfession > 0 And $actualProfession <> $expectedProfession Then $issues += 1
			Info($teamLabel & ' verify: ' & $heroName & ' id=' & $heroID & ' slot=' & $heroIndex & ' actualProf=' & $actualProfession & ' expectedProf=' & $expectedProfession)
		EndIf
	Next

	If $issues > 0 Then
		Warn($teamLabel & ' verify failed: issues=' & $issues & ' (aborting setup)')
		Return $FAIL
	EndIf

	Info($teamLabel & ' verify: ok')
	Return $SUCCESS
EndFunc


Func FroggyLoadHeroTemplateByID($heroID, $heroName, $templateCode)
	Local $templatePrimaryProfession = FroggyGetTemplatePrimaryProfession($templateCode)

	For $attempt = 1 To $FROGGY_TEMPLATE_LOAD_RETRIES
		Local $heroIndex = GetHeroNumberByHeroID($heroID)
		If $heroIndex == Null Then
			Warn('Froggy team setup: hero index not found for ' & $heroName & ' on template attempt ' & $attempt & '/' & $FROGGY_TEMPLATE_LOAD_RETRIES)
			SupportTeamStabilizeAfterTravel($ID_GADDS_ENCAMPMENT, 1200, 120)
			ContinueLoop
		EndIf

		If HeroHasTemplate($heroIndex, $templateCode) Then
			Info('Froggy ' & $heroName & ': template already loaded, skipping')
			Return $SUCCESS
		EndIf

		Local $heroPrimaryProfession = GetHeroProfession($heroIndex)
		If $templatePrimaryProfession > 0 And $templatePrimaryProfession <> $heroPrimaryProfession Then
			Warn('Froggy template mismatch before load: hero=' & $heroName & ' (heroID=' & $heroID & ', heroIndex=' & $heroIndex & ', heroProf=' & $heroPrimaryProfession & ', templateProf=' & $templatePrimaryProfession & ')')
			SupportTeamStabilizeAfterTravel($ID_GADDS_ENCAMPMENT, 1200, 120)
			ContinueLoop
		EndIf

		LoadSkillTemplate($templateCode, $heroIndex)
		RandomSleep(220)
		Return $SUCCESS
	Next

	Warn('Froggy team setup aborted: could not apply template for ' & $heroName & ' after retries')
	Return $FAIL
EndFunc


Func FroggyGetTemplatePrimaryProfession($templateCode)
	If $templateCode == '' Then Return -1

	Local $bin64 = ''
	Local $i
	For $i = 1 To StringLen($templateCode)
		$bin64 &= Base64ToBin64(StringMid($templateCode, $i, 1))
	Next

	If StringLen($bin64) < 10 Then Return -1

	Local $templateType = Bin64ToDec(StringLeft($bin64, 4))
	If $templateType <> 14 Then Return -1

	$bin64 = StringTrimLeft($bin64, 8)
	Local $professionBits = Bin64ToDec(StringLeft($bin64, 2)) * 2 + 4
	$bin64 = StringTrimLeft($bin64, 2)
	If StringLen($bin64) < $professionBits Then Return -1

	Return Bin64ToDec(StringLeft($bin64, $professionBits))
EndFunc


Func FroggyTryAddHero($heroID, $heroName, $expectedSize, $teamLabel = 'Froggy team')
	For $i = 1 To 7
		If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
		AddHero($heroID)
		Local $verifyTimer = TimerInit()
		While TimerDiff($verifyTimer) < 2200
			If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
			RandomSleep(120)
		WEnd

		If Mod($i, 2) == 0 Then
			SupportTeamStabilizeAfterTravel($ID_GADDS_ENCAMPMENT, 1800, 150)
		EndIf
	Next
	Warn('Could not add ' & $teamLabel & ' hero ' & $heroName & ' after retries (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')
	Return $FAIL
EndFunc


Func FroggyAssembleFixedTeamWithRecovery(ByRef $heroIDs, ByRef $heroNames, $teamLabel)
	Local $attempt
	For $attempt = 1 To $FROGGY_TEAM_OUTPOST_RETRIES
		If $attempt > 1 Then
			Warn($teamLabel & ' team assembly pass ' & $attempt & ' after outpost refresh')
			If TravelToOutpost($ID_GADDS_ENCAMPMENT, $district_name) == $FAIL Then Return $FAIL
			If Not SupportTeamStabilizeAfterTravel($ID_GADDS_ENCAMPMENT, 10000, 250) Then
				Warn($teamLabel & ' team: outpost stabilization timed out before pass ' & $attempt)
			EndIf
		EndIf

		If FroggyEnsureSoloParty() == $FAIL Then Return $FAIL
		If FroggyAssembleTeamPass($heroIDs, $heroNames, $teamLabel) == $SUCCESS Then Return $SUCCESS
		Warn($teamLabel & ' team assembly pass ' & $attempt & ' failed, trying targeted missing-hero fallback')
		If FroggyRetryMissingHeroes($heroIDs, $heroNames, $teamLabel) == $SUCCESS Then Return $SUCCESS
	Next

	Warn($teamLabel & ' team assembly failed after all recovery passes')
	FroggyWarnMissingHeroes($heroIDs, $heroNames, $teamLabel)
	Return $FAIL
EndFunc


Func FroggyAssembleTeamPass(ByRef $heroIDs, ByRef $heroNames, $teamLabel)
	Local $round
	Local $i
	For $round = 1 To $FROGGY_TEAM_ASSEMBLY_PASSES
		For $i = 0 To UBound($heroIDs) - 1
			If GetHeroNumberByHeroID($heroIDs[$i]) == Null Then
				FroggyTryAddHero($heroIDs[$i], $heroNames[$i], 0, $teamLabel)
			EndIf
		Next

		If SupportTeamHasExactHeroes($heroIDs, 8) Then Return $SUCCESS
		Warn($teamLabel & ' team fill round ' & $round & ' incomplete (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')
		SupportTeamStabilizeAfterTravel($ID_GADDS_ENCAMPMENT, 2200, 150)
	Next

	FroggyWarnMissingHeroes($heroIDs, $heroNames, $teamLabel)
	Return $FAIL
EndFunc


Func FroggyRetryMissingHeroes(ByRef $heroIDs, ByRef $heroNames, $teamLabel)
	Local $round
	Local $i
	For $round = 1 To $FROGGY_TEAM_MISSING_FALLBACK_PASSES
		Local $attemptedAny = False
		For $i = 0 To UBound($heroIDs) - 1
			If GetHeroNumberByHeroID($heroIDs[$i]) == Null Then
				$attemptedAny = True
				Info($teamLabel & ' targeted fallback round ' & $round & ': retrying missing hero ' & $heroNames[$i])
				FroggyTryAddHero($heroIDs[$i], $heroNames[$i], 0, $teamLabel)
			EndIf
		Next

		If SupportTeamHasExactHeroes($heroIDs, 8) Then
			Info($teamLabel & ' targeted missing-hero fallback succeeded on round ' & $round)
			Return $SUCCESS
		EndIf

		If Not $attemptedAny Then ExitLoop
		SupportTeamStabilizeAfterTravel($ID_GADDS_ENCAMPMENT, 2200, 150)
	Next

	FroggyWarnMissingHeroes($heroIDs, $heroNames, $teamLabel)
	Return $FAIL
EndFunc


Func FroggyWarnMissingHeroes(ByRef $heroIDs, ByRef $heroNames, $teamLabel)
	Local $missing = ''
	Local $i
	For $i = 0 To UBound($heroIDs) - 1
		If GetHeroNumberByHeroID($heroIDs[$i]) == Null Then
			If $missing <> '' Then $missing &= ', '
			$missing &= $heroNames[$i]
		EndIf
	Next
	If $missing == '' Then $missing = 'none'
	Warn($teamLabel & ' missing heroes after pass: ' & $missing & ' (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')
EndFunc


Func RunToBogroot()
	TravelToOutpost($ID_GADDS_ENCAMPMENT, $district_name)
	ResetFailuresCounter()
	Info('Making way to portal')
	MoveTo(-10018, -21892)
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(-9550, -20400)
		Move(-9451, -19766)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_SPARKFLY_SWAMP)
	WEnd
	Info('Making way to Bogroot')
	AdlibRegister('TrackPartyStatus', 10000)
	Local $bogrootPathPasses = 0
	While Not IsAgentInRange(GetMyAgent(), 4671, 7094, 1250)
		If IsPlayerDead() Then
			RandomSleep(1500)
			ContinueLoop
		EndIf

		If IsRunFailed() Then
			Warn('Froggy setup: party wipe detected on way to Bogroot beacon 1, recovering and retrying path')
			ResetFailuresCounter()
			RandomSleep(1500)
			ContinueLoop
		EndIf

		$bogrootPathPasses += 1
		MoveAggroAndKillInRange(-4559, -14406, 'I majored in pain, with a minor in suffering', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-5204, -9831, 'Youre dumb! Youll die, and youll leave a dumb corpse!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-928, -8699, 'I am fire! I am war! What are you?', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(4200, -4897, 'Praise Joko!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(4671, 7094, 'I can outrun a centaur', $FROGGY_AGGRO_RANGE)

		If Not IsAgentInRange(GetMyAgent(), 4671, 7094, 1250) And $bogrootPathPasses >= 5 Then
			Warn('Froggy setup: no progress while moving to Bogroot beacon 1, re-approaching portal and retrying')
			MoveTo(-9550, -20400)
			Move(-9451, -19766)
			RandomSleep(1200)
			$bogrootPathPasses = 0
		EndIf
	WEnd

	While Not IsAgentInRange(GetMyAgent(), 12280, 22585, 1250)
		If IsPlayerDead() Then
			RandomSleep(1500)
			ContinueLoop
		EndIf

		If IsRunFailed() Then
			Warn('Froggy setup: party wipe detected on way to Bogroot beacon 2, recovering and retrying path')
			ResetFailuresCounter()
			RandomSleep(1500)
			ContinueLoop
		EndIf
		MoveAggroAndKillInRange(11025, 11710, 'Wow. Thats quality armor.', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(14624, 19314, 'By Ogdens Hammer, what savings!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(14650, 19417, 'More violets I say. Less violence', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(12280, 22585, 'Guild wars 2 is actually great, you know?', $FROGGY_AGGRO_RANGE)
	WEnd
	AdlibUnRegister('TrackPartyStatus')
	Return IsRunFailed() ? $FAIL : $SUCCESS
EndFunc


;~ Farm loop
Func FroggyFarmLoop()
	ForceFroggyElementalistWeaponSet()
	ResetFailuresCounter()
	AdlibRegister('TrackPartyStatus', 10000)
	GetRewardRefreshAndTakeFroggyQuest()
	; Failure return delayed after adlib function deregistered
	If (ClearFroggyFloor1() == $FAIL Or ClearFroggyFloor2() == $FAIL) Then $froggy_farm_setup = False
	AdlibUnRegister('TrackPartyStatus')
	If Not $froggy_farm_setup Then Return $FAIL

	Info('Waiting for timer end')
	Sleep(190000)
	While Not WaitMapLoading($ID_SPARKFLY_SWAMP)
		Sleep(500)
	WEnd
	Info('Finished Run')
	Return $SUCCESS
EndFunc


Func ForceFroggyElementalistWeaponSet()
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_ELEMENTALIST Then Return
	ChangeWeaponSet($FROGGY_ELEMENTALIST_WEAPON_SET)
	RandomSleep(120)
EndFunc


; GW1 keybinds for hero panels that have no working PerformAction code.
; Bind in GW1 Options > Controls > "Panel: Open Hero Commander N":
;   Hero 2 -> 9
;   Hero 4 -> 5,  Hero 5 -> 6,  Hero 6 -> 7,  Hero 7 -> 8
; Heroes 1 and 3 work via PerformAction and need no keybind.
Global Const $FROGGY_HERO2_KEY = "9"
Global Const $FROGGY_HERO_PANEL_KEYS = "5|6|7|8"

Func FroggyTryOpenHeroPanelsForMonitoring()
	SupportTeamOpenHeroPanels('Froggy mode', $FROGGY_HERO2_KEY, $FROGGY_HERO_PANEL_KEYS)
EndFunc


;~ Take quest rewards, refresh quest by entering dungeon and exiting it, then take quest again and reenter dungeon
;~ This is Giriff's War version. To use Tekk's war quest instead, replace:
;~ GoToNPC(GetNearestNPCToCoords(12308, 22836)) -> GoToNPC(GetNearestNPCToCoords(12500, 22648))
;~ Dialog(0x832207) -> Dialog(0x833907)
;~ Dialog(0x832201) -> Dialog(0x833901)
;~ Dialog(0x832205) -> Dialog(0x833905)
Func GetRewardRefreshAndTakeFroggyQuest()
	MoveTo(12061, 22485)
	Local $questNPC = GetNearestNPCToCoords(12308, 22836)
	TakeQuestReward($questNPC, $ID_FROGGY_QUEST, 0x832207)

	Info('Get in dungeon to reset quest')
	MoveTo(12228, 22677)
	MoveTo(12470, 25036)
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(12968, 26219)
		Move(13097, 26393)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_BOGROOT_GROWTHS_LVL_1)
	WEnd

	Info('Get out of dungeon to reset quest')
	$mapLoaded = False
	While Not $mapLoaded
		MoveTo(14876, 632)
		Move(14700, 450)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_SPARKFLY_SWAMP)
	WEnd

	MoveTo(12061, 22485)
	; after rezoning quest npc agent could have changed so getting quest npc again
	$questNPC = GetNearestNPCToCoords(12308, 22836)
	TakeQuest($questNPC, $ID_FROGGY_QUEST, 0x832201)
	; This is not taking the quest, this is validating the first step of it
	Info('Talk to Tekk/Giriff if already had quest')
	For $i = 1 To 2
		GoToNPC($questNPC)
		PingSleep(1000)
		Dialog(0x832205)
		PingSleep(1000)
	Next

	Info('Get back in')
	MoveTo(12228, 22677)
	MoveTo(12470, 25036)
	$mapLoaded = False
	While Not $mapLoaded
		MoveTo(12968, 26219)
		Move(13097, 26393)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_BOGROOT_GROWTHS_LVL_1)
	WEnd
EndFunc


;~ Clear Froggy floor 1
Func ClearFroggyFloor1()
	Info('------------------------------------')
	Info('First floor')
	If IsHardmodeEnabled() Then UseConset()

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 6078, 4483, 1250)
		If CheckStuck('Froggy Floor 1 - First loop', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		FroggyWaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(17619, 2687, 'Moving near duo', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(18168, 4788, 'Killing one from duo', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(18880, 7749, 'Triggering beacon 1', $FROGGY_AGGRO_RANGE)

		Info('Getting blessing')
		MoveTo(19063, 7875)
		GoToNPC(GetNearestNPCToCoords(19058, 7952))
		RandomSleep(250)
		Dialog(0x84)
		RandomSleep(250)

		MoveAggroAndKillInRange(13080, 7822, 'Moving towards nettles cave', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(9946, 6963, 'Nettles cave', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(6078, 4483, 'Nettles cave exit group', $FROGGY_AGGRO_RANGE)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -1501, -8590, 1250)
		If CheckStuck('Froggy Floor 1 - Second loop', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		FroggyWaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(4960, 1984, 'Triggering beacon 2', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(3567, -278, 'Massive frog cave', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(1763, -607, 'Im getting buried here!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(224, -2238, 'Massive frog cave exit', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-1175, -4994, 'Moving through poison jets', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-115, -8569, 'Ragna-rock n roll!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-1501, -8590, 'Triggering beacon 3', $FROGGY_AGGRO_RANGE)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 7171, -17934, 1250)
		If CheckStuck('Froggy Floor 1 - Third loop', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		FroggyWaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(-115, -8569, 'You played two hours and died like this?!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(1966, -11018, 'Last cave entrance', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(5775, -12761, 'Youre interrupting my calculations', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(6125, -15820, 'Commander, a word...', $FROGGY_AGGRO_RANGE)
		Info('Last cave exit')
		MoveTo(7171, -17934)
	WEnd
	If IsRunFailed() Then Return $FAIL

	Info('Going through portal')
	Local $mapLoaded = False
	While Not $mapLoaded
		If CheckStuck('Froggy Floor 1 - Getting through portal', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		MoveTo(7171, -17934)
		Move(7600, -19100)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_BOGROOT_GROWTHS_LVL_2)
	WEnd
	Return $SUCCESS
EndFunc


;~ Clear Froggy floor 2
Func ClearFroggyFloor2()
	Info('------------------------------------')
	Info('Second floor')
	If IsHardmodeEnabled() Then UseConset()

	While Not IsAgentInRange(GetMyAgent(), -719, 11140, 1250)
		If IsPlayerDead() Then
			RandomSleep(1200)
			ContinueLoop
		EndIf

		If IsRunFailed() Then
			Warn('Froggy Floor 2: wipe detected before incubus exit beacon, recovering and retrying')
			ResetFailuresCounter()
			RandomSleep(1500)
			ContinueLoop
		EndIf

		If CheckStuck('Froggy Floor 2 - First loop', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		FroggyWaitUntilPartyAlive()
		Info('Getting blessing')
		MoveTo(-11072, -5522)
		GoToNPC(GetNearestNPCToCoords(-11055, -5533))
		RandomSleep(250)
		Dialog(0x84)
		RandomSleep(250)

		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(-10931, -4584, 'Moving in cave', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10121, -3175, 'Moving near river ', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-9646, -1005, 'Going through river ', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-8548, 601, 'Moving to incubus cave', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-7217, 3353, 'Incubus cave entrance', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-8229, 5519, 'Wololo', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-9434, 8479, 'Help! The crusaders are attacking our trade routes!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-8182, 10187, 'La Hire wishes to kill something', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-6440, 11526, 'The blood on La Hires sword is almost dry!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-3963, 10050, 'It is a good day for La Hire to die... ', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-1992, 11950, 'Ill be back, Saracen dogs!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-719, 11140, 'Triggering incubus cave exit beacon', $FROGGY_AGGRO_RANGE)
	WEnd

	While Not IsAgentInRange(GetMyAgent(), 8398, 4358, 1250)
		If IsPlayerDead() Then
			RandomSleep(1200)
			ContinueLoop
		EndIf

		If IsRunFailed() Then
			Warn('Froggy Floor 2: wipe detected in beetle section, recovering and retrying')
			ResetFailuresCounter()
			RandomSleep(1500)
			ContinueLoop
		EndIf

		If CheckStuck('Froggy Floor 2 - Second loop', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		FroggyWaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(3130, 12731, 'Beetle zone', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(3535, 13860, 'Aiur will be restored', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(5717, 13357, 'Eternal obedience', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(6945, 9820, 'Beetle zone exit', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(8117, 7465, 'Gokir fight', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(8398, 4358, 'Triggering beacon 2', $FROGGY_AGGRO_RANGE)
	WEnd

	While Not IsAgentInRange(GetMyAgent(), 19597, -11553, 1250)
		If IsPlayerDead() Then
			RandomSleep(1200)
			ContinueLoop
		EndIf

		If IsRunFailed() Then
			Warn('Froggy Floor 2: wipe detected before boss beacon, recovering and retrying')
			ResetFailuresCounter()
			RandomSleep(1500)
			ContinueLoop
		EndIf

		If CheckStuck('Froggy Floor 2 - Third loop', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		FroggyWaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(9829, -1175, 'The Death Fleet descends', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(10932, -5203, 'I hear and obey', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(13305, -6475, 'Target in range.', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(16841, -5619, 'Keyboss', $FROGGY_AGGRO_RANGE)

		RandomSleep(500)
		PickUpItems()

		Info('Open dungeon door')
		ClearTarget()

		; Tripled to secure bot
		For $i = 1 To 3
			MoveTo(17888, -6243)
			RandomSleep(500)
			TargetNearestItem()
			ActionInteract()
			RandomSleep(500)
			TargetNearestItem()
			ActionInteract()
			RandomSleep(500)
		Next

		MoveAggroAndKillInRange(18363, -8696, 'Going to boss area', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(16631, -11655, 'I will do all that must be done', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(19122, -12284, 'Glory to the Firstborn', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(19597, -11553, 'Triggering boss beacon', $FROGGY_AGGRO_RANGE)
	WEnd

	Local $largeFroggyAggroRange = $RANGE_SPELLCAST + 300
	Local $bossAreaPasses = 0
	Local $bossAreaTimer = TimerInit()
	Local $lastBossAreaWipeCount = $party_failures_count
	While Not IsRunFailed() And Not IsQuestReward($ID_FROGGY_QUEST)
		If IsPlayerDead() Then
			CancelAllHeroes()
			RandomSleep(1200)
			ContinueLoop
		EndIf

		If $party_failures_count > $lastBossAreaWipeCount Then
			$lastBossAreaWipeCount = $party_failures_count
			$bossAreaPasses = 0
			Warn('Froggy Floor 2: wipe detected in boss area, extending retry window')
			CancelAllHeroes()
			RandomSleep(1800)
			ContinueLoop
		EndIf

		$bossAreaPasses += 1
		If CheckStuck('Froggy Floor 2 - Fourth loop', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		Info('------------------------------------')
		Info('Boss area')
		FroggyWaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(17494, -14149, 'Our enemies will be undone', $largeFroggyAggroRange)
		MoveAggroAndKillInRange(14641, -15081, 'I live to serve.', $largeFroggyAggroRange)
		MoveAggroAndKillInRange(13934, -17384, 'The mission is in peril!', $largeFroggyAggroRange)
		MoveAggroAndKillInRange(14365, -17681, 'Boss fight', $largeFroggyAggroRange)
		FlagMoveAggroAndKillInRange(15286, -17662, 'All hail! King of the losers!', $largeFroggyAggroRange)
		FlagMoveAggroAndKillInRange(15804, -19107, 'Oh fuck its huge', $largeFroggyAggroRange)
		RandomSleep(250)

		If $bossAreaPasses >= 12 And TimerDiff($bossAreaTimer) > 240000 Then
			Warn('Froggy Floor 2: boss area repeated without quest completion, resetting run')
			Return $FAIL
		EndIf
	WEnd
	If IsRunFailed() Then Return $FAIL

	; Chest
	MoveTo(15910, -19134)
	MoveTo(15329, -18948)
	MoveTo(15086, -19132)
	Info('Opening chest')
	; Doubled to secure the looting
	For $i = 1 To 2
		TargetNearestItem()
		ActionInteract()
		RandomSleep(2500)
		PickUpItems()
		RandomSleep(5000)
	Next
	Return $SUCCESS
EndFunc