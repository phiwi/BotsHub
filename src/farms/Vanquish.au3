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
; Edit these to target a different map.
Global Const $VANQ_OUTPOST_ID      = $ID_JOKANUR_DIGGINGS
Global Const $VANQ_EXPLORABLE_ID   = $ID_ZEHLON_REACH
; Intermediate waypoint past the narrow section before the portal
Global Const $VANQ_WAYPOINT_X      = 3560
Global Const $VANQ_WAYPOINT_Y      = 3150
; Walk-in portal position (slightly past the trigger zone)
Global Const $VANQ_PORTAL_X        = 4559
Global Const $VANQ_PORTAL_Y        = 4510

Global Const $VANQ_FARM_INFORMATIONS = 'Generic Vanquish Bot.' & @CRLF _
	& 'Explores any explorable area using enemy-homing + visited-cell grid.' & @CRLF _
	& 'Kills enemies, opens chests, recovers when stuck.' & @CRLF _
	& 'Set VANQ_OUTPOST_ID / VANQ_EXPLORABLE_ID / VANQ_PORTAL_X/Y for your map.'

; ==== Tuning constants ====
Global Const $VANQ_COMBAT_RANGE    = 1350        ; aggro range passed to MoveAggroAndKillInRange
Global Const $VANQ_CELL_SIZE       = 700         ; visited-cell grid resolution (GW units)
Global Const $VANQ_EXPLORE_STEP    = 1100        ; distance of exploration candidate points
Global Const $VANQ_CANDIDATES      = 16          ; number of angular candidates per explore step
Global Const $VANQ_RANDOM_PCT      = 30          ; % chance to pick a random unvisited cell instead of best-scored
Global Const $VANQ_STUCK_MS        = 2800        ; ms without meaningful movement → kick
Global Const $VANQ_STUCK_MIN_DIST  = 40          ; min displacement (units) to not be considered stuck
Global Const $VANQ_NO_FOE_MS       = 7000        ; ms with no enemy in compass → switch to explore
Global Const $VANQ_NO_CONTACT_MS   = 3 * 60 * 1000  ; ms without any enemy contact → early resign
Global Const $VANQ_RUN_TIMEOUT_MS  = 25 * 60 * 1000  ; hard run time-out (25 min)
Global Const $VANQ_MAX_CELLS       = 2000        ; max tracked visited cells before compact

; ==== Player and Hero builds ====
Global Const $VANQ_PLAYER_SKILLBAR = 'OgESY5LTTN8G4Giej18gcG0G'
Global Const $VANQ_PLAYER_WEAPON_SET = 2
Global Const $VANQ_GWEN_SKILLBAR = 'OQhkAoC8AGKzJAna6me5gMQP4iB'
Global Const $VANQ_NORGU_SKILLBAR = 'OQhkAoB6AGK0LACYeGJARQGAH0FD'
Global Const $VANQ_ZHED_SKILLBAR = 'OgNDwbrvO0iaBJRLWPWJQNMC'

; ==== State ====
Global $vanq_setup_done   = False
Global $vanq_run_number   = 0
Global $vanq_cell_cx[$VANQ_MAX_CELLS]
Global $vanq_cell_cy[$VANQ_MAX_CELLS]
Global $vanq_cell_n       = 0
Global $vanq_last_x       = 0
Global $vanq_last_y       = 0
Global $vanq_stuck_timer    = 0
Global $vanq_foe_timer      = 0
Global $vanq_contact_timer  = 0


; ===========================================================================
; Entry point
; ===========================================================================
Func VanquishFarm()
	If Not $vanq_setup_done And SetupVanquishFarm() == $FAIL Then Return $PAUSE

	If VanquishEnterExplorable() == $FAIL Then Return $FAIL

	$vanq_run_number += 1
	VanquishResetRunState()

	VanquishRunLoop()

	ResignAndReturnToOutpost($VANQ_OUTPOST_ID)
	Return $SUCCESS
EndFunc


Func SetupVanquishFarm()
	Info('Vanquish: setting up')
	If TravelToOutpost($VANQ_OUTPOST_ID, $district_name) == $FAIL Then Return $FAIL
	If SetupVanquishPlayer() == $FAIL Then Return $FAIL
	If SetupVanquishTeam() == $FAIL Then Return $FAIL
	$vanq_setup_done = True
	Info('Vanquish: setup complete')
	Return $SUCCESS
EndFunc


Func SetupVanquishPlayer()
	Info('Vanquish: loading player build')
	LoadSkillTemplate($VANQ_PLAYER_SKILLBAR)
	RandomSleep(250)
	ChangeWeaponSet($VANQ_PLAYER_WEAPON_SET)
	RandomSleep(150)
	Return $SUCCESS
EndFunc


Func SetupVanquishTeam()
	Info('Vanquish: setting up team with Gwen, Norgu, Zhed')
	If VanquishEnsureSoloParty() == $FAIL Then Return $FAIL

	If VanquishTryAddHero($ID_GWEN, 'Gwen', 1) == $FAIL _
		Or VanquishTryAddHero($ID_NORGU, 'Norgu', 2) == $FAIL _
		Or VanquishTryAddHero($ID_ZHED_SHADOWHOOF, 'Zhed', 3) == $FAIL Then
		Warn('Vanquish: could not assemble team')
		Return $FAIL
	EndIf

	If GetHeroNumberByHeroID($ID_GWEN) <> 1 Then Return $FAIL
	If GetHeroNumberByHeroID($ID_NORGU) <> 2 Then Return $FAIL
	If GetHeroNumberByHeroID($ID_ZHED_SHADOWHOOF) <> 3 Then Return $FAIL

	LoadSkillTemplate($VANQ_GWEN_SKILLBAR, 1)
	RandomSleep(150)
	LoadSkillTemplate($VANQ_NORGU_SKILLBAR, 2)
	RandomSleep(150)
	LoadSkillTemplate($VANQ_ZHED_SKILLBAR, 3)
	RandomSleep(150)

	Return $SUCCESS
EndFunc


Func VanquishEnsureSoloParty($maxWaitMs = 9000)
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
	Warn('Vanquish: party reset timeout. Party=' & GetPartySize() & ', heroes=' & GetHeroCount())
	Return $FAIL
EndFunc


Func VanquishTryAddHero($heroID, $heroName, $heroSlot, $maxWaitMs = 5000)
	Local $timer = TimerInit()
	Local $expectedSize = $heroSlot + 1

	While TimerDiff($timer) < $maxWaitMs
		If AddHeroByProfession($heroID) == $SUCCESS Then
			If GetPartySize() >= $expectedSize Then Return $SUCCESS
		EndIf
		RandomSleep(250)
	WEnd

	Warn('Vanquish: could not add hero ' & $heroName & ' (party=' & GetPartySize() & ')')
	Return $FAIL
EndFunc


Func VanquishEnterExplorable()
	If TravelToOutpost($VANQ_OUTPOST_ID, $district_name) == $FAIL Then Return $FAIL
	While GetMapID() <> $VANQ_EXPLORABLE_ID
		Info('Vanquish: entering explorable')
		MoveTo($VANQ_WAYPOINT_X, $VANQ_WAYPOINT_Y)
		MoveTo($VANQ_PORTAL_X, $VANQ_PORTAL_Y)
		RandomSleep(1500)
		If WaitMapLoading($VANQ_EXPLORABLE_ID, 10000, 1500) Then ExitLoop
	WEnd
	Return GetMapID() == $VANQ_EXPLORABLE_ID ? $SUCCESS : $FAIL
EndFunc


; ===========================================================================
; Main run loop
; ===========================================================================
Func VanquishRunLoop()
	Local $run_timer = TimerInit()
	Local $me, $foe_x, $foe_y

	$vanq_foe_timer     = TimerInit()
	$vanq_stuck_timer   = TimerInit()
	$vanq_contact_timer = TimerInit()

	While TimerDiff($run_timer) < $VANQ_RUN_TIMEOUT_MS
		VanquishMarkCurrentCell()
		VanquishCheckUnstuck()

		$me = GetMyAgent()
		Local $foe = GetNearestEnemyToAgent($me)

		If $foe <> Null Then
			$vanq_foe_timer     = TimerInit()
			$vanq_contact_timer = TimerInit()
			$foe_x = DllStructGetData($foe, 'X')
			$foe_y = DllStructGetData($foe, 'Y')
			MoveAggroAndKillInRange($foe_x, $foe_y, 'vanquish kill', $VANQ_COMBAT_RANGE)
			PickUpItems()
			FindAndOpenChests()
		Else
			; Early exit: no enemies and all nearby candidates already visited
			If Not VanquishHasUnvisitedCandidates() Then
				Info('Vanquish: no enemies and area fully explored - resigning early')
				Return
			EndIf

			; Early exit: no enemy contact for too long
			If TimerDiff($vanq_contact_timer) >= $VANQ_NO_CONTACT_MS Then
				Info('Vanquish: no enemy contact for ' & Round($VANQ_NO_CONTACT_MS / 60000) & ' min - resigning early')
				Return
			EndIf

			If TimerDiff($vanq_foe_timer) >= $VANQ_NO_FOE_MS Then
				VanquishExploreStep()
				$vanq_foe_timer = TimerInit()
			Else
				RandomSleep(200)
			EndIf
		EndIf
	WEnd
EndFunc


; ===========================================================================
; Exploration: scored candidate selection with per-run angle rotation
; ===========================================================================
Func VanquishExploreStep()
	Local $me = GetMyAgent()
	Local $px = DllStructGetData($me, 'X')
	Local $py = DllStructGetData($me, 'Y')

	; Rotate base angle each run so different areas are explored across runs
	Local $base_deg = Mod($vanq_run_number * 23, 360)

	Local $best_score = -1
	Local $best_x = $px, $best_y = $py

	; Collect all unvisited candidates for optional random pick
	Local $unvisited_x[$VANQ_CANDIDATES]
	Local $unvisited_y[$VANQ_CANDIDATES]
	Local $unvisited_n = 0

	For $i = 0 To $VANQ_CANDIDATES - 1
		Local $deg = $base_deg + ($i * 360.0 / $VANQ_CANDIDATES)
		Local $rad = $deg * 3.14159265 / 180.0
		Local $cx = $px + $VANQ_EXPLORE_STEP * Cos($rad)
		Local $cy = $py + $VANQ_EXPLORE_STEP * Sin($rad)

		Local $gcx = Int(Floor($cx / $VANQ_CELL_SIZE))
		Local $gcy = Int(Floor($cy / $VANQ_CELL_SIZE))
		Local $visited = VanquishIsCellVisited($gcx, $gcy)

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
	If $unvisited_n > 0 And Random(0, 99, 1) < $VANQ_RANDOM_PCT Then
		Local $pick = Random(0, $unvisited_n - 1, 1)
		$best_x = $unvisited_x[$pick]
		$best_y = $unvisited_y[$pick]
	EndIf

	Info('Vanquish: exploring to (' & Round($best_x) & ',' & Round($best_y) & ')')
	Move($best_x, $best_y)
	RandomSleep(400)
EndFunc


; Returns True if at least one of the VANQ_CANDIDATES angular positions around the player is unvisited
Func VanquishHasUnvisitedCandidates()
	Local $me = GetMyAgent()
	Local $px = DllStructGetData($me, 'X')
	Local $py = DllStructGetData($me, 'Y')
	Local $base_deg = Mod($vanq_run_number * 23, 360)

	For $i = 0 To $VANQ_CANDIDATES - 1
		Local $deg = $base_deg + ($i * 360.0 / $VANQ_CANDIDATES)
		Local $rad = $deg * 3.14159265 / 180.0
		Local $gcx = Int(Floor(($px + $VANQ_EXPLORE_STEP * Cos($rad)) / $VANQ_CELL_SIZE))
		Local $gcy = Int(Floor(($py + $VANQ_EXPLORE_STEP * Sin($rad)) / $VANQ_CELL_SIZE))
		If Not VanquishIsCellVisited($gcx, $gcy) Then Return True
	Next
	Return False
EndFunc


; ===========================================================================
; Visited-cell tracking
; ===========================================================================
Func VanquishMarkCurrentCell()
	Local $me = GetMyAgent()
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')
	Local $gcx = Int(Floor($x / $VANQ_CELL_SIZE))
	Local $gcy = Int(Floor($y / $VANQ_CELL_SIZE))

	If VanquishIsCellVisited($gcx, $gcy) Then Return

	If $vanq_cell_n >= $VANQ_MAX_CELLS Then
		; Drop oldest half to make room
		Local $keep = Int($VANQ_MAX_CELLS / 2)
		Local $offset = $VANQ_MAX_CELLS - $keep
		For $i = 0 To $keep - 1
			$vanq_cell_cx[$i] = $vanq_cell_cx[$i + $offset]
			$vanq_cell_cy[$i] = $vanq_cell_cy[$i + $offset]
		Next
		$vanq_cell_n = $keep
	EndIf

	$vanq_cell_cx[$vanq_cell_n] = $gcx
	$vanq_cell_cy[$vanq_cell_n] = $gcy
	$vanq_cell_n += 1
EndFunc


Func VanquishIsCellVisited($gcx, $gcy)
	For $i = 0 To $vanq_cell_n - 1
		If $vanq_cell_cx[$i] == $gcx And $vanq_cell_cy[$i] == $gcy Then Return True
	Next
	Return False
EndFunc


; ===========================================================================
; Stuck detection and recovery
; ===========================================================================
Func VanquishCheckUnstuck()
	Local $me = GetMyAgent()
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')

	Local $dx = $x - $vanq_last_x
	Local $dy = $y - $vanq_last_y
	Local $dist = Sqrt($dx * $dx + $dy * $dy)

	If $dist >= $VANQ_STUCK_MIN_DIST Then
		$vanq_last_x = $x
		$vanq_last_y = $y
		$vanq_stuck_timer = TimerInit()
		Return
	EndIf

	If TimerDiff($vanq_stuck_timer) < $VANQ_STUCK_MS Then Return

	; Kick in a random direction
	Info('Vanquish: stuck, applying random kick')
	Local $angle = Random(0, 359, 1) * 3.14159265 / 180.0
	Local $kick = $VANQ_EXPLORE_STEP * 0.8
	Move($x + $kick * Cos($angle), $y + $kick * Sin($angle))
	RandomSleep(600)
	Move($x + $kick * Cos($angle + 1.2), $y + $kick * Sin($angle + 1.2))
	RandomSleep(400)
	Move($x + $kick * Cos($angle - 1.2), $y + $kick * Sin($angle - 1.2))
	RandomSleep(300)

	$vanq_last_x = DllStructGetData(GetMyAgent(), 'X')
	$vanq_last_y = DllStructGetData(GetMyAgent(), 'Y')
	$vanq_stuck_timer = TimerInit()
EndFunc


; ===========================================================================
; Per-run state reset (cell grid persists across runs intentionally)
; ===========================================================================
Func VanquishResetRunState()
	Local $me = GetMyAgent()
	$vanq_last_x = DllStructGetData($me, 'X')
	$vanq_last_y = DllStructGetData($me, 'Y')
	$vanq_stuck_timer   = TimerInit()
	$vanq_foe_timer     = TimerInit()
	$vanq_contact_timer = TimerInit()
EndFunc
