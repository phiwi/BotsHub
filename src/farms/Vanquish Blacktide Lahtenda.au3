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
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'
#include '../../lib/Utils-Agents.au3'
#include '../utilities/SupportTeam.au3'

Opt('MustDeclareVars', True)

; ==== Configuration ====
Global Const $VANQBT_OUTPOST_ID    = $ID_BLACKTIDE_DEN
Global Const $VANQBT_EXPLORABLE_ID = $ID_LAHTEDA_BOG
; Walk-in portal position (based on recording)
Global Const $VANQBT_PORTAL_X      = 346
Global Const $VANQBT_PORTAL_Y      = -4521

Global Const $VANQBT_FARM_INFORMATIONS = 'Vanquish: Blacktide Den → Lahtenda Bog' & @CRLF _
	& 'Explores using enemy-homing + visited-cell grid.' & @CRLF _
	& 'Kills enemies, opens chests, recovers when stuck.'

; ==== Tuning constants ====
Global Const $VANQBT_COMBAT_RANGE    = 1350        ; aggro range passed to MoveAggroAndKillInRange
Global Const $VANQBT_CELL_SIZE       = 700         ; visited-cell grid resolution (GW units)
Global Const $VANQBT_EXPLORE_STEP    = 1100        ; distance of exploration candidate points
Global Const $VANQBT_CANDIDATES      = 16          ; number of angular candidates per explore step
Global Const $VANQBT_RANDOM_PCT      = 30          ; % chance to pick a random unvisited cell instead of best-scored
Global Const $VANQBT_STUCK_MS        = 2800        ; ms without meaningful movement → kick
Global Const $VANQBT_STUCK_MIN_DIST  = 40          ; min displacement (units) to not be considered stuck
Global Const $VANQBT_NO_FOE_MS       = 7000        ; ms with no enemy in compass → switch to explore
Global Const $VANQBT_NO_CONTACT_MS   = 3 * 60 * 1000  ; ms without any enemy contact → early resign
Global Const $VANQBT_RUN_TIMEOUT_MS  = 25 * 60 * 1000  ; hard run time-out (25 min)
Global Const $VANQBT_MAX_CELLS       = 2000        ; max tracked visited cells before compact

; ==== Player and Hero builds ====
Global Const $VANQBT_PLAYER_SKILLBAR = 'OgESY5LTTN8G4Giej18gcG0G'
Global Const $VANQBT_PLAYER_WEAPON_SET = 2
;Global Const $VANQBT_GWEN_SKILLBAR = 'OQhkAoC8AGKzJAna6me5gMQP4iB'
;Global Const $VANQBT_NORGU_SKILLBAR = 'OQhkAoB6AGK0LACYeGJARQGAH0FD'
;Global Const $VANQBT_ZHED_SKILLBAR = 'OgNDwbrvO0iaBJRLWPWJQNMC'
Global Const $VANQBT_XANDRA_SKILLBAR = 'OASjUwiJZOyhqg3EjhcdmNzLGA'
Global Const $VANQBT_OLIAS_SKILLBAR = 'OANDUshuSLVoBKgbhVVJgPEuVA'
;Global Const $VANQBT_LIVIA_SKILLBAR = 'OAljUwGpZSUBKgfBVVbh8Y7Y1YA'
;Global Const $VANQBT_DUNKORO_SKILLBAR = 'Owkj4wQopO+sqPe9iQ9dJ74aMA'
;Global Const $VANQBT_OGDEN_SKILLBAR = 'Owkj4wQopO+sqPetLS9dJ7YfMA'

; ==== State ====
Global $vanqbt_setup_done   = False
Global $vanqbt_run_number   = 0
Global $vanqbt_cell_cx[$VANQBT_MAX_CELLS]
Global $vanqbt_cell_cy[$VANQBT_MAX_CELLS]
Global $vanqbt_cell_n       = 0
Global $vanqbt_last_x       = 0
Global $vanqbt_last_y       = 0
Global $vanqbt_stuck_timer    = 0
Global $vanqbt_foe_timer      = 0
Global $vanqbt_contact_timer  = 0


; ===========================================================================
; Entry point
; ===========================================================================
Func VanquishBlackTideLahtendaFarm()
	If Not $vanqbt_setup_done And SetupVanquishBTFarm() == $FAIL Then Return $PAUSE

	If VanquishBTEnterExplorable() == $FAIL Then Return $FAIL

	$vanqbt_run_number += 1
	VanquishBTResetRunState()

	VanquishBTRunLoop()

	ResignAndReturnToOutpost($VANQBT_OUTPOST_ID)
	Return $SUCCESS
EndFunc


Func SetupVanquishBTFarm()
	Info('Vanquish Blacktide: setting up')
	If TravelToOutpost($VANQBT_OUTPOST_ID, $district_name) == $FAIL Then Return $FAIL
	If SetupVanquishBTPlayer() == $FAIL Then Return $FAIL
	If SetupVanquishBTTeam() == $FAIL Then Return $FAIL
	$vanqbt_setup_done = True
	Info('Vanquish Blacktide: setup complete')
	Return $SUCCESS
EndFunc


Func SetupVanquishBTPlayer()
	Info('Vanquish Blacktide: loading player build')
	LoadSkillTemplate($VANQBT_PLAYER_SKILLBAR)
	RandomSleep(250)
	ChangeWeaponSet($VANQBT_PLAYER_WEAPON_SET)
	RandomSleep(150)
	Return $SUCCESS
EndFunc


Func SetupVanquishBTTeam()
	Info('Vanquish Blacktide: setting up team with Xandra, Olias')
	If VanquishBTEnsureSoloParty() == $FAIL Then Return $FAIL

	If VanquishBTTryAddHero($ID_XANDRA, 'Xandra', 1) == $FAIL _
		Or VanquishBTTryAddHero($ID_OLIAS, 'Olias', 2) == $FAIL Then
;	If VanquishBTTryAddHero($ID_GWEN, 'Gwen', 1) == $FAIL _
;		Or VanquishBTTryAddHero($ID_NORGU, 'Norgu', 2) == $FAIL _
;		Or VanquishBTTryAddHero($ID_ZHED_SHADOWHOOF, 'Zhed', 3) == $FAIL Then
		Warn('Vanquish Blacktide: could not assemble team')
		Return $FAIL
	EndIf

	If GetHeroNumberByHeroID($ID_XANDRA) <> 1 Then Return $FAIL
	If GetHeroNumberByHeroID($ID_OLIAS) <> 2 Then Return $FAIL
;	If GetHeroNumberByHeroID($ID_GWEN) <> 1 Then Return $FAIL
;	If GetHeroNumberByHeroID($ID_NORGU) <> 2 Then Return $FAIL
;	If GetHeroNumberByHeroID($ID_ZHED_SHADOWHOOF) <> 3 Then Return $FAIL

	LoadSkillTemplate($VANQBT_XANDRA_SKILLBAR, 1)
	RandomSleep(150)
	LoadSkillTemplate($VANQBT_OLIAS_SKILLBAR, 2)
	RandomSleep(150)
;	LoadSkillTemplate($VANQBT_GWEN_SKILLBAR, 1)
;	RandomSleep(150)
;	LoadSkillTemplate($VANQBT_NORGU_SKILLBAR, 2)
;	RandomSleep(150)
;	LoadSkillTemplate($VANQBT_ZHED_SKILLBAR, 3)
;	RandomSleep(150)

	Return $SUCCESS
EndFunc


Func VanquishBTEnsureSoloParty($maxWaitMs = 9000)
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
	Warn('Vanquish Blacktide: party reset timeout. Party=' & GetPartySize() & ', heroes=' & GetHeroCount())
	Return $FAIL
EndFunc


Func VanquishBTTryAddHero($heroID, $heroName, $heroSlot, $maxWaitMs = 5000)
	Local $timer = TimerInit()
	Local $expectedSize = $heroSlot + 1

	For $i = 1 To 6
		If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
		AddHero($heroID)
		RandomSleep(350)
		If GetPartySize() >= $expectedSize Then Return $SUCCESS
	Next

	Warn('Vanquish Blacktide: could not add hero ' & $heroName & ' (party=' & GetPartySize() & ')')
	Return $FAIL
EndFunc


Func VanquishBTEnterExplorable()
	If TravelToOutpost($VANQBT_OUTPOST_ID, $district_name) == $FAIL Then Return $FAIL
	While GetMapID() <> $VANQBT_EXPLORABLE_ID
		Info('Vanquish Blacktide: entering explorable')
		MoveTo($VANQBT_PORTAL_X, $VANQBT_PORTAL_Y)
		RandomSleep(1500)
		If WaitMapLoading($VANQBT_EXPLORABLE_ID, 10000, 1500) Then ExitLoop
	WEnd
	Return GetMapID() == $VANQBT_EXPLORABLE_ID ? $SUCCESS : $FAIL
EndFunc


; ===========================================================================
; Main run loop
; ===========================================================================
Func VanquishBTRunLoop()
	Local $run_timer = TimerInit()
	Local $me, $foe_x, $foe_y

	$vanqbt_foe_timer     = TimerInit()
	$vanqbt_stuck_timer   = TimerInit()
	$vanqbt_contact_timer = TimerInit()

	While TimerDiff($run_timer) < $VANQBT_RUN_TIMEOUT_MS
		VanquishBTMarkCurrentCell()
		VanquishBTCheckUnstuck()

		$me = GetMyAgent()
		Local $foe = GetNearestEnemyToAgent($me)

		If $foe <> Null Then
			$vanqbt_foe_timer     = TimerInit()
			$vanqbt_contact_timer = TimerInit()
			$foe_x = DllStructGetData($foe, 'X')
			$foe_y = DllStructGetData($foe, 'Y')
			MoveAggroAndKillInRange($foe_x, $foe_y, 'vanquish kill', $VANQBT_COMBAT_RANGE)
			PickUpItems()
			FindAndOpenChests()
		Else
			; Early exit: no enemies and all nearby candidates already visited
			If Not VanquishBTHasUnvisitedCandidates() Then
				Info('Vanquish Blacktide: no enemies and area fully explored - resigning early')
				Return
			EndIf

			; Early exit: no enemy contact for too long
			If TimerDiff($vanqbt_contact_timer) >= $VANQBT_NO_CONTACT_MS Then
				Info('Vanquish Blacktide: no enemy contact for ' & Round($VANQBT_NO_CONTACT_MS / 60000) & ' min - resigning early')
				Return
			EndIf

			If TimerDiff($vanqbt_foe_timer) >= $VANQBT_NO_FOE_MS Then
				VanquishBTExploreStep()
				$vanqbt_foe_timer = TimerInit()
			Else
				RandomSleep(200)
			EndIf
		EndIf
	WEnd
EndFunc


; ===========================================================================
; Exploration: scored candidate selection with per-run angle rotation
; ===========================================================================
Func VanquishBTExploreStep()
	Local $me = GetMyAgent()
	Local $px = DllStructGetData($me, 'X')
	Local $py = DllStructGetData($me, 'Y')

	; Rotate base angle each run so different areas are explored across runs
	Local $base_deg = Mod($vanqbt_run_number * 23, 360)

	Local $best_score = -1
	Local $best_x = $px, $best_y = $py

	; Collect all unvisited candidates for optional random pick
	Local $unvisited_x[$VANQBT_CANDIDATES]
	Local $unvisited_y[$VANQBT_CANDIDATES]
	Local $unvisited_n = 0

	For $i = 0 To $VANQBT_CANDIDATES - 1
		Local $deg = $base_deg + ($i * 360.0 / $VANQBT_CANDIDATES)
		Local $rad = $deg * 3.14159265 / 180.0
		Local $cx = $px + $VANQBT_EXPLORE_STEP * Cos($rad)
		Local $cy = $py + $VANQBT_EXPLORE_STEP * Sin($rad)

		Local $gcx = Int(Floor($cx / $VANQBT_CELL_SIZE))
		Local $gcy = Int(Floor($cy / $VANQBT_CELL_SIZE))
		Local $visited = VanquishBTIsCellVisited($gcx, $gcy)

		Local $score = ($visited ? 0.0 : 1.0) + Random(0, 0.4)

		If Not $visited Then
			$unvisited_x[$unvisited_n] = $cx
			$unvisited_y[$unvisited_n] = $cy
			$unvisited_n += 1
		EndIf

		If $score > $best_score Then
			$best_score = $score
			$best_x = $cx
			$best_y = $cy
		EndIf
	Next

	; 30% chance: pick a random unvisited candidate instead of best-scored
	If $unvisited_n > 0 And Random(0, 99, 1) < $VANQBT_RANDOM_PCT Then
		Local $pick = Random(0, $unvisited_n - 1, 1)
		$best_x = $unvisited_x[$pick]
		$best_y = $unvisited_y[$pick]
	EndIf

	Info('Vanquish Blacktide: exploring to (' & Round($best_x) & ',' & Round($best_y) & ')')
	Move($best_x, $best_y)
	RandomSleep(400)
EndFunc


; Returns True if at least one of the VANQBT_CANDIDATES angular positions around the player is unvisited
Func VanquishBTHasUnvisitedCandidates()
	Local $me = GetMyAgent()
	Local $px = DllStructGetData($me, 'X')
	Local $py = DllStructGetData($me, 'Y')
	Local $base_deg = Mod($vanqbt_run_number * 23, 360)

	For $i = 0 To $VANQBT_CANDIDATES - 1
		Local $deg = $base_deg + ($i * 360.0 / $VANQBT_CANDIDATES)
		Local $rad = $deg * 3.14159265 / 180.0
		Local $gcx = Int(Floor(($px + $VANQBT_EXPLORE_STEP * Cos($rad)) / $VANQBT_CELL_SIZE))
		Local $gcy = Int(Floor(($py + $VANQBT_EXPLORE_STEP * Sin($rad)) / $VANQBT_CELL_SIZE))
		If Not VanquishBTIsCellVisited($gcx, $gcy) Then Return True
	Next
	Return False
EndFunc


; ===========================================================================
; Visited-cell tracking
; ===========================================================================
Func VanquishBTMarkCurrentCell()
	Local $me = GetMyAgent()
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')
	Local $gcx = Int(Floor($x / $VANQBT_CELL_SIZE))
	Local $gcy = Int(Floor($y / $VANQBT_CELL_SIZE))

	If VanquishBTIsCellVisited($gcx, $gcy) Then Return

	If $vanqbt_cell_n >= $VANQBT_MAX_CELLS Then
		; Drop oldest half to make room
		Local $keep = Int($VANQBT_MAX_CELLS / 2)
		Local $offset = $VANQBT_MAX_CELLS - $keep
		For $i = 0 To $keep - 1
			$vanqbt_cell_cx[$i] = $vanqbt_cell_cx[$i + $offset]
			$vanqbt_cell_cy[$i] = $vanqbt_cell_cy[$i + $offset]
		Next
		$vanqbt_cell_n = $keep
	EndIf

	$vanqbt_cell_cx[$vanqbt_cell_n] = $gcx
	$vanqbt_cell_cy[$vanqbt_cell_n] = $gcy
	$vanqbt_cell_n += 1
EndFunc


Func VanquishBTIsCellVisited($gcx, $gcy)
	For $i = 0 To $vanqbt_cell_n - 1
		If $vanqbt_cell_cx[$i] == $gcx And $vanqbt_cell_cy[$i] == $gcy Then Return True
	Next
	Return False
EndFunc


; ===========================================================================
; Stuck detection and recovery
; ===========================================================================
Func VanquishBTCheckUnstuck()
	Local $me = GetMyAgent()
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')

	Local $dx = $x - $vanqbt_last_x
	Local $dy = $y - $vanqbt_last_y
	Local $dist = Sqrt($dx * $dx + $dy * $dy)

	If $dist >= $VANQBT_STUCK_MIN_DIST Then
		$vanqbt_last_x = $x
		$vanqbt_last_y = $y
		$vanqbt_stuck_timer = TimerInit()
		Return
	EndIf

	If TimerDiff($vanqbt_stuck_timer) < $VANQBT_STUCK_MS Then Return

	; Kick in a random direction
	Info('Vanquish Blacktide: stuck, applying random kick')
	Local $angle = Random(0, 359, 1) * 3.14159265 / 180.0
	Local $kick = $VANQBT_EXPLORE_STEP * 0.8
	Move($x + $kick * Cos($angle), $y + $kick * Sin($angle))
	RandomSleep(600)
	Move($x + $kick * Cos($angle + 1.2), $y + $kick * Sin($angle + 1.2))
	RandomSleep(400)
	Move($x + $kick * Cos($angle - 1.2), $y + $kick * Sin($angle - 1.2))
	RandomSleep(300)

	$vanqbt_last_x = DllStructGetData(GetMyAgent(), 'X')
	$vanqbt_last_y = DllStructGetData(GetMyAgent(), 'Y')
	$vanqbt_stuck_timer = TimerInit()
EndFunc


; ===========================================================================
; Per-run state reset (cell grid persists across runs intentionally)
; ===========================================================================
Func VanquishBTResetRunState()
	Local $me = GetMyAgent()
	$vanqbt_last_x = DllStructGetData($me, 'X')
	$vanqbt_last_y = DllStructGetData($me, 'Y')
	$vanqbt_stuck_timer   = TimerInit()
	$vanqbt_foe_timer     = TimerInit()
	$vanqbt_contact_timer = TimerInit()
EndFunc
