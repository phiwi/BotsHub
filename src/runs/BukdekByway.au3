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
#include '../../lib/GWA2_ID_Items.au3'
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID_Skills.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'
#include '../utilities/SupportTeam.au3'


; ==== Constants ====
; Assassin chest-runner build (same as PongmeiSin): Shadow Form stealth + Dash.
Global Const $BUKDEK_CHESTRUNNER_SKILLBAR = 'OwVkMYe7HPG0d5EUDEuDCENJPiOD'
Global Const $BUKDEK_FARM_INFORMATIONS = 'Bukdek Byway Plagueborn chest run.' & @CRLF _
	& '- Start in Kaineng Center, exit to Bukdek Byway' & @CRLF _
	& '- Re-zone trick (Kaineng -> Bukdek -> Kaineng -> Bukdek) so the chest spawns at its fixed spot' & @CRLF _
	& '- Run to the single chest, cast Shadow Form (8) + I am Unstoppable (6), open, loot, resign' & @CRLF _
	& '- Heroes (same as Varajar Berserkers) provide speed and tanking'
; Average duration ~ 1m15s
Global Const $BUKDEK_FARM_DURATION = (2 * 60) * 1000
Global Const $BUKDEK_CHEST_RUN_TIMEOUT_MS = 3 * 60 * 1000

; Player skill slots: Shadow Form + I am Unstoppable for the chest, Heart of Shadow only to escape body-blocks.
Global Const $BUKDEK_HEART_OF_SHADOW = 5
Global Const $BUKDEK_I_AM_UNSTOPPABLE = 6
Global Const $BUKDEK_SHADOW_FORM = 8

; Map / chest
Global Const $BUKDEK_CHEST_X = 3908
Global Const $BUKDEK_CHEST_Y = 14348
; Point on the route just before the chest where Shadow Form + I am Unstoppable are cast.
Global Const $BUKDEK_PRECAST_X = 3749
Global Const $BUKDEK_PRECAST_Y = 15481
; Cast Shadow Form + I am Unstoppable this far before the precast point (~3-4s at IMS speed).
Global Const $BUKDEK_PRECAST_RANGE = 1400

; Bukdek Byway exit portal (from Kaineng Center). Reached from two different
; Kaineng spawns, so we just walk to this single point and let the portal trigger.
Global Const $BUKDEK_EXIT_X = 3150
Global Const $BUKDEK_EXIT_Y = -4840
; Kaineng Center exit back from Bukdek Byway (north of the Bukdek spawn).
Global Const $BUKDEK_KAINENG_EXIT_X = -6595
Global Const $BUKDEK_KAINENG_EXIT_Y = 20254

; Heroes (same composition as Varajar Berserkers: Margrid + Morgahn + 5 meat shields)
Global Const $BUKDEK_HERO_MARGRID = $ID_MARGRID_THE_SLY
Global Const $BUKDEK_HERO_MORGAHN = $ID_GENERAL_MORGAHN
Global Const $BUKDEK_HERO_KOSS = $ID_KOSS
Global Const $BUKDEK_HERO_MOX = $ID_MOX
Global Const $BUKDEK_HERO_MELONNI = $ID_MELONNI
Global Const $BUKDEK_HERO_KAHMU = $ID_KAHMU
Global Const $BUKDEK_HERO_JORA = $ID_JORA

Global Const $BUKDEK_MARGRID_TEMPLATE = 'OgkjYxYjJPQHe8O+5AAAAAAAAA'
Global Const $BUKDEK_MORGAHN_TEMPLATE = 'OQijEamLKPm4bMLuCzj3xDbAAA'
Global Const $BUKDEK_KOSS_TEMPLATE = 'OQkiUxm8wj3xAAAAAAAAAAAA'
Global Const $BUKDEK_MOX_TEMPLATE = 'OgmiYynywjBAAAAAAAAAAAAA'
Global Const $BUKDEK_JORA_TEMPLATE = 'OQkiUxm8wj3xAAAAAAAAAAAA'

Global $bukdek_farm_setup = False


;~ Main method to farm the Bukdek Byway Plagueborn chest
Func BukdekBywayFarm()
	If Not $bukdek_farm_setup And SetupBukdekBywayFarm() == $FAIL Then Return $PAUSE
	Local $result = BukdekBywayFarmLoop()
	ResignAndReturnToOutpost($ID_KAINENG_CENTER)
	Return $result
EndFunc


;~ Bukdek Byway chest farm setup
Func SetupBukdekBywayFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_KAINENG_CENTER, $district_name) == $FAIL Then Return $FAIL
	If SetupPlayerBukdekByway() == $FAIL Then Return $FAIL
	If SetupTeamBukdekByway() == $FAIL Then Return $FAIL

	; One-time re-zone trick: Kaineng -> Bukdek -> Kaineng. Entering and leaving
	; Bukdek Byway once forces the chest to spawn at its fixed spot on later entries.
	If BukdekEnterBukdek() == $FAIL Then Return $FAIL
	MoveTo($BUKDEK_KAINENG_EXIT_X, $BUKDEK_KAINENG_EXIT_Y)
	If Not WaitMapLoading($ID_KAINENG_CENTER, 10000, 2000) Then Return $FAIL

	$bukdek_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerBukdekByway()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_ASSASSIN Then
		Warn('Should run this farm as assassin')
		Return $FAIL
	EndIf
	If HeroHasTemplate(0, $BUKDEK_CHESTRUNNER_SKILLBAR) Then
		Info('Bukdek player: template already loaded, skipping')
	Else
		LoadSkillTemplate($BUKDEK_CHESTRUNNER_SKILLBAR)
		RandomSleep(250)
	EndIf
	Return $SUCCESS
EndFunc


Func SetupTeamBukdekByway()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up team')
	LeaveParty()
	AddHero($BUKDEK_HERO_MARGRID)
	AddHero($BUKDEK_HERO_MORGAHN)
	AddHero($BUKDEK_HERO_KOSS)
	AddHero($BUKDEK_HERO_MOX)
	AddHero($BUKDEK_HERO_MELONNI)
	AddHero($BUKDEK_HERO_KAHMU)
	AddHero($BUKDEK_HERO_JORA)
	RandomSleep(500)

	Local $requiredHeroes[] = [$BUKDEK_HERO_MARGRID, $BUKDEK_HERO_MORGAHN, $BUKDEK_HERO_KOSS, $BUKDEK_HERO_MOX, $BUKDEK_HERO_MELONNI, $BUKDEK_HERO_KAHMU, $BUKDEK_HERO_JORA]
	If Not SupportTeamHasExactHeroes($requiredHeroes, 8) Then
		Warn('Party not set up correctly. Team size different than 8')
		Return $FAIL
	EndIf

	; Load hero builds (skip any that are already loaded). Hero indices match the
	; add order: Margrid=1, Morgahn=2, Koss=3, MOX=4, Melonni=5, Kahmu=6, Jora=7.
	BukdekLoadHeroTemplate(1, $BUKDEK_MARGRID_TEMPLATE, 'Margrid')
	BukdekLoadHeroTemplate(2, $BUKDEK_MORGAHN_TEMPLATE, 'Morgahn')
	BukdekLoadHeroTemplate(3, $BUKDEK_KOSS_TEMPLATE, 'Koss')
	BukdekLoadHeroTemplate(4, $BUKDEK_MOX_TEMPLATE, 'MOX')
	BukdekLoadHeroTemplate(5, $BUKDEK_MOX_TEMPLATE, 'Melonni')
	BukdekLoadHeroTemplate(6, $BUKDEK_MOX_TEMPLATE, 'Kahmu')
	BukdekLoadHeroTemplate(7, $BUKDEK_JORA_TEMPLATE, 'Jora')

	; Margrid + Morgahn (the important casters) avoid combat; the five meat shields
	; guard the player so they tank any aggro instead of dying to it.
	SetHeroBehaviour(1, $ID_HERO_AVOIDING)
	SetHeroBehaviour(2, $ID_HERO_AVOIDING)
	For $i = 3 To 7
		SetHeroBehaviour($i, $ID_HERO_GUARDING)
	Next
	Return $SUCCESS
EndFunc


;~ Load a hero template only if it is not already loaded
Func BukdekLoadHeroTemplate($heroIndex, $templateCode, $heroName)
	If HeroHasTemplate($heroIndex, $templateCode) Then
		Info('Bukdek ' & $heroName & ': template already loaded, skipping')
		Return
	EndIf
	LoadSkillTemplate($templateCode, $heroIndex)
	RandomSleep(150)
EndFunc


;~ One full run: enter Bukdek, walk to the chest, cast, open, loot.
Func BukdekBywayFarmLoop()
	If FindInInventory($ID_LOCKPICK)[0] == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf

	Info('Starting chest farm run')

	; Enter Bukdek Byway (the one-time re-zone in setup already fixed the chest spawn).
	If BukdekEnterBukdek() == $FAIL Then Return $FAIL

	; Run to the chest area (defensive skills keep the assassin alive).
	If BukdekRunToChest() == $FAIL Then Return $FAIL

	; The chest spawns within aggro range of the recorded spot, not exactly on it.
	; FindAndOpenChests scans the whole compass range and walks straight to it.
	Local $openedChest = FindAndOpenChests($RANGE_COMPASS, BukdekDefendWhileOpening, BukdekUnblock)
	Info('Opened ' & ($openedChest ? 1 : 0) & ' chest.')
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Walk directly to the Bukdek Byway exit portal. After resign/travel the player
;~ spawns close to the portal, so a straight-line walk to the last waypoint is enough.
Func BukdekEnterBukdek()
	Info('Moving to Bukdek Byway exit')
	MoveTo($BUKDEK_EXIT_X, $BUKDEK_EXIT_Y)
	If Not WaitMapLoading($ID_BUKDEK_BYWAY, 10000, 2000) Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Walk from the Bukdek Byway spawn to the chest area. Heroes provide the speed boost.
Func BukdekRunToChest()
	Info('Running to the Plagueborn chest')
	Local $waypoints[][2] = [ _
		[-6737, 19698], _
		[-6606, 19255], _
		[-6475, 18824], _
		[-5997, 18216], _
		[-5364, 17548], _
		[-4921, 17119], _
		[-4436, 16733], _
		[-3891, 16443], _
		[-3586, 16391], _
		[-2976, 16489], _
		[-2054, 16606], _
		[-1513, 16636], _
		[-900, 16661], _
		[-284, 16699], _
		[169, 16781], _
		[933, 16927], _
		[1546, 17019], _
		[2167, 17086], _
		[2628, 17066], _
		[3083, 16945], _
		[3340, 16600], _
		[3517, 16238], _
		[3698, 15645], _
		[$BUKDEK_PRECAST_X, $BUKDEK_PRECAST_Y] _
	]
	Local $runTimer = TimerInit()
	Local $precastDone = False
	For $i = 0 To UBound($waypoints) - 1
		If TimerDiff($runTimer) > $BUKDEK_CHEST_RUN_TIMEOUT_MS Then Return $FAIL
		If IsPlayerDead() Then Return $FAIL
		MoveTo($waypoints[$i][0], $waypoints[$i][1])
		RandomSleep(100)
		; Cast Shadow Form (8) + I am Unstoppable (6) ~3-4s before reaching the chest.
		If Not $precastDone And GetDistanceToPoint(GetMyAgent(), $BUKDEK_PRECAST_X, $BUKDEK_PRECAST_Y) <= $BUKDEK_PRECAST_RANGE Then
			BukdekCastDefensiveSkills()
			$precastDone = True
		EndIf
	Next
	Return $SUCCESS
EndFunc


;~ Cast Shadow Form (8) and I am Unstoppable (6) before opening.
Func BukdekCastDefensiveSkills()
	If IsRecharged($BUKDEK_SHADOW_FORM) Then UseSkillEx($BUKDEK_SHADOW_FORM)
	If IsRecharged($BUKDEK_I_AM_UNSTOPPABLE) Then UseSkillEx($BUKDEK_I_AM_UNSTOPPABLE)
	RandomSleep(200)
EndFunc


;~ Survival callback used while FindAndOpenChests walks to and opens the chest:
;~ re-cast I am Unstoppable and Shadow Form when foes are close.
Func BukdekDefendWhileOpening()
	Local $nearestFoe = GetNearestEnemyToAgent(GetMyAgent())

	If GetEnergy() >= 5 And IsRecharged($BUKDEK_I_AM_UNSTOPPABLE) And GetDistance(GetMyAgent(), $nearestFoe) < $RANGE_AREA Then UseSkillEx($BUKDEK_I_AM_UNSTOPPABLE)
	If GetEnergy() >= 10 And IsRecharged($BUKDEK_SHADOW_FORM) And GetDistance(GetMyAgent(), $nearestFoe) < ($RANGE_SPELLCAST + 200) Then UseSkillEx($BUKDEK_SHADOW_FORM)
EndFunc


;~ Blocked callback used while FindAndOpenChests walks to the chest: if body-blocked
;~ by Plagueborn, Heart of Shadow (5) shadow steps to a nearby foe (or self, which
;~ teleports in a random direction) to break free.
Func BukdekUnblock()
	If IsRecharged($BUKDEK_HEART_OF_SHADOW) Then
		Local $target = GetNearestEnemyToAgent(GetMyAgent())
		If $target == Null Then $target = GetMyAgent()
		UseSkillEx($BUKDEK_HEART_OF_SHADOW, $target)
	EndIf
EndFunc
