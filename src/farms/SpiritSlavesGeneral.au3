#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
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
;
; General-purpose run to the Spirit Slaves farming spot in Shattered Ravines.
; Works with ANY character profession — no build is loaded.
; The bot navigates from Bone Palace through Joko's Domain to the safe spot
; at (-7900, -10550) in Shattered Ravines, then pauses so you can take over.
#CE ===========================================================================

#include-once
#include '../../lib/GWA2_ID_Items.au3'
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID_Skills.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'


; ==== Constants ====
Global Const $SPIRIT_SLAVES_GENERAL_FARM_INFORMATIONS = 'Runs any character from Bone Palace to the Spirit Slaves spot in Shattered Ravines.' & @CRLF _
	& '- No build is loaded — works with any profession' & @CRLF _
	& '- Switches to Hard Mode and sets Lightbringer title' & @CRLF _
	& '- Pauses at (-7900, -10550) in Shattered Ravines for manual farming'
Global Const $SPIRIT_SLAVES_GENERAL_FARM_DURATION = 10 * 60 * 1000

Global $spirit_slaves_general_farm_setup = False


;~ Main entry point: run to the Spirit Slaves spot, then pause.
Func SpiritSlavesGeneralFarm()
	If Not $spirit_slaves_general_farm_setup Then
		If SetupSpiritSlavesGeneralFarm() == $FAIL Then Return $PAUSE
	EndIf

	If GetMapID() == $ID_THE_SHATTERED_RAVINES Then
		Info('Already in Shattered Ravines — moving to safe spot')
		MoveTo(-7900, -10550)
		Info('Spirit Slaves General: arrived at farm spot. Bot paused — take over manually.')
		Return $PAUSE
	EndIf

	If RunToShatteredRavinesGeneral() == $FAIL Then
		Warn('Spirit Slaves General: run to Shattered Ravines failed')
		Return $FAIL
	EndIf

	Info('Spirit Slaves General: arrived at farm spot. Bot paused — take over manually.')
	Return $PAUSE
EndFunc


;~ Setup: travel to Bone Palace, set HM + Lightbringer title, no build load.
Func SetupSpiritSlavesGeneralFarm()
	Info('Setting up Spirit Slaves General run')
	If TravelToOutpost($ID_BONE_PALACE, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_HARD_MODE)
	SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)
	LeaveParty()
	$spirit_slaves_general_farm_setup = True
	Info('Preparations complete — ready to run to Shattered Ravines')
	Return $SUCCESS
EndFunc


;~ Path: Bone Palace → Joko's Domain → Shattered Ravines → safe spot.
;~ Skill usage is skipped when the character doesn't have the expected skills.
Func RunToShatteredRavinesGeneral()
	TravelToOutpost($ID_BONE_PALACE, $district_name)

	; ----- Bone Palace → Joko's Domain -----
	Info('Exiting Bone Palace to Jokos Domain')
	MoveTo(-14500, 6000)
	Move(-14800, 3400)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_JOKOS_DOMAIN) Then Return $FAIL

	RandomSleep(500)
	; Mindbender (slot 8) — skip silently if not on this character's bar.
	If IsRecharged(8) Then UseSkillEx(8)
	MoveTo(-12650, 2600)
	MoveTo(-10950, 4250)

	; ----- Wurm spoor -----
	Info('Taking wurm')
	ChangeTarget(GetNearestSignpostToCoords(-10950, 4250))
	RandomSleep(500)
	TargetNearestItem()
	ActionInteract()
	RandomSleep(1500)
	; Wurm skill 5 (jump / dash) — always available once inside the wurm.
	If IsRecharged(5) Then UseSkillEx(5)
	MoveTo(-8255, 5320)

	; ----- Joko's Domain crossing (enemies possible) -----
	Local $me = GetMyAgent()
	If CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 0 And IsRecharged(5) Then UseSkillEx(5)
	MoveTo(-8600, 10600)
	$me = GetMyAgent()
	If CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 0 And IsRecharged(5) Then UseSkillEx(5)
	MoveTo(-8250, 12800)
	Move(-3850, 19200)
	$me = GetMyAgent()
	While IsPlayerMoving()
		If CountFoesInRangeOfAgent($me, $RANGE_NEARBY) > 0 And IsRecharged(5) Then UseSkillEx(5)
		RandomSleep(500)
		$me = GetMyAgent()
		If IsPlayerDead() Then Return $FAIL
	WEnd
	MoveTo(-4500, 19700)
	RandomSleep(3000)
	MoveTo(-4500, 19700)
	If IsPlayerDead() Then Return $FAIL

	; ----- Entering The Shattered Ravines -----
	Info('Entering The Shattered Ravines — careful')
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_THE_SHATTERED_RAVINES, 10000, 2000) Then Return $FAIL

	; ----- Hurry to safe spot -----
	MoveTo(-9700, -10750)
	If IsRecharged(8) Then UseSkillEx(8)
	MoveTo(-7900, -10550)
	Return $SUCCESS
EndFunc
