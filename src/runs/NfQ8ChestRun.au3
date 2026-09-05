#CS ===========================================================================
; Name     : NF Q8 Chest Run (Barbarous Shore)
; Purpose  : Solo Assassin chest run on Barbarous Shore, collecting Q8-class
;            (req-8, max-damage) loot. Loot filtering is handled by the
;            BotsHub loot configuration (see conf/loot).
;
; This module is a faithful, self-contained re-homing of the older standalone
; "Q8 Mono ROAD NF 44+ C,H" farm. It intentionally does NOT depend on / mirror
; the much larger BarbarousShoreSin hero-support engine. Instead it follows the
; proven, leaner BotsHub solo-run pattern (travel -> move to spots -> open
; chests -> loot via the hub -> resign back to the outpost), on the original
; route coordinates of the former standalone farm.
;
; Author : (adaptation) GitHub Copilot, on behalf of the current maintainer.
;          Original route/logic by Wandalou and Herta (RIP).
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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID_Items.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
; Skill bar that actually belongs to this farm. It comes from the inventory
; (Guild Wars skill bar variable naming used by the original farm) and its
; decoded slots match every farm skill variable (SF/IAU/HOS/DASH/WY/STAB/
; SHROUD/SANCTUARY -> Shadow Form, I Am Unstoppable!, Heart of Shadow, Dash,
; Watch Yourself!, Dwarven Stability, Shroud of Distress, Shadow Sanctuary).
Global Const $NFQ8_CHESTRUNNER_SKILLBAR = 'OwFSUzPT6M0kIQTQcF3lHQrg'

; Skill slot numbers (1..8, in the order shown on the loaded skill bar above).
Global Const $NFQ8_SLOT_SHADOWFORM			= 1
Global Const $NFQ8_SLOT_I_AM_UNSTOPPABLE	= 2
Global Const $NFQ8_SLOT_HEART_OF_SHADOW		= 3
Global Const $NFQ8_SLOT_DASH				= 4
Global Const $NFQ8_SLOT_WATCH_YOURSELF		= 5
Global Const $NFQ8_SLOT_DWARVEN_STABILITY	= 6
Global Const $NFQ8_SLOT_SHROUD_OF_DISTRESS	= 7
Global Const $NFQ8_SLOT_SHADOW_SANCTUARY	= 8

Global Const $NFQ8_CHESTRUN_INFORMATIONS = 'Solo Assassin NF Q8 chest run (Barbarous Shore).' & @CRLF _
	& 'Setup :' & @CRLF _
	& '- Run as an Assassin with the NF Q8 chest run skill bar:' & @CRLF _
	& '  ' & $NFQ8_CHESTRUNNER_SKILLBAR & @CRLF _
	& '- Keep lockpicks in inventory' & @CRLF _
	& '- Runs Normal Mode by default' & @CRLF _
	& 'Loot : kept according to the BotsHub loot configuration (set "Req 8" flags' _ 
	& 'in conf/loot to mirror the original Q8-only keeping behaviour).'

; Rough average duration for an NF Q8 chest run.
Global Const $NFQ8_CHESTRUNNER_FARM_DURATION = (10 * 60) * 1000

; Home outpost and explorable for this farm.
Global Const $NFQ8_OUTPOST_ID	= $ID_CAMP_HOJANU
Global Const $NFQ8_EXPLORE_ID	= $ID_BARBAROUS_SHORE

; Original waypoint route (Barbarous Shore). Each waypoint is a spot where we
; stop and look/open nearby chests before moving on.
Global Const $NFQ8_CHEST_SPOTS[13][2] = [ _
		[-12500, 16927], _
		[-14297,   9845], _
		[-15181,   4585], _
		[-10928,   3532], _
		[-7707,    -788], _
		[-8874,     278], _
		[-13019,   -964], _
		[-13406,  -6590], _
		[-11265,  -7448], _
		[-12159, -11117], _
		[-15328, -15860], _
		[-10044, -14745], _
		[-7752,   -7671]]

; Portals from Camp Hojanu outpost into Barbarous Shore (walk into map).
Global Const $NFQ8_PORTAL_PATH[4][2] = [ _
		[-17236, 17474], _
		[-15948, 18021], _
		[-14576, 18262], _
		[-14012, 18242]]

Global $nfq8_farm_setup = False

;~ Main entry point called by the BotsHub farm loop (single run per call).
Func NfQ8ChestFarm()
	If Not $nfq8_farm_setup Then SetupNfQ8ChestFarm()

	GoToBarbarousShoreNfQ8()
	Local $result = NfQ8ChestFarmLoop()
	; The original farm used a death/resign trick at the end of each run.
	ResignAndReturnToOutpost($NFQ8_OUTPOST_ID)
	Return $result
EndFunc


;~ One-time setup: travel home, prepare the player build, then go to Normal Mode.
Func SetupNfQ8ChestFarm()
	Info('Setting up NF Q8 chest run farm')
	TravelToOutpost($NFQ8_OUTPOST_ID, $district_name)

	SetupPlayerNfQ8ChestFarm()

	; The original farm force-switched to Normal Mode. Respect the central
	; hard-mode option so users may opt-in to hard mode, but default to NM.
	SwitchToHardModeIfEnabled()

	$nfq8_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerNfQ8ChestFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
		; Persistent bar snapshot - load once per map entry (Setup is called once,
		; guarded by $nfq8_farm_setup). Already-active skills are simply reloaded,
		; which is idempotent and matches how most BotsHub solo runs operate.
		LoadSkillTemplate($NFQ8_CHESTRUNNER_SKILLBAR)
		RandomSleep(250)
	Else
		Warn('Should run this farm as an assassin on the Q8 chest run skill bar')
	EndIf
EndFunc


;~ Walk from the Camp Hojanu outpost into Barbarous Shore and clear chest state
;~ (a fresh explorable instance means fresh chests).
Func GoToBarbarousShoreNfQ8()
	TravelToOutpost($NFQ8_OUTPOST_ID, $district_name)
	While GetMapID() <> $NFQ8_EXPLORE_ID
		Info('Moving to Barbarous Shore')
		For $i = 0 To UBound($NFQ8_PORTAL_PATH) - 1
			MoveTo($NFQ8_PORTAL_PATH[$i][0], $NFQ8_PORTAL_PATH[$i][1])
		Next
		RandomSleep(1000)
		WaitMapLoading($NFQ8_EXPLORE_ID, 10000, 2000)
	WEnd
	ClearChestsMap()
EndFunc


;~ Run the route: reach each chest spot, then open nearby chests. Loot is picked
;~ up by BotsHub (FindAndOpenChests -> PickUpItems) honoring the loot config.
Func NfQ8ChestFarmLoop()
	If FindInInventory($ID_LOCKPICK)[0] == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf

	If GetMapID() <> $NFQ8_EXPLORE_ID Then Return $FAIL
	Info('Starting NF Q8 chest run')

	Local $openedChests = 0
	Local $total = UBound($NFQ8_CHEST_SPOTS)

	For $i = 0 To $total - 1
		If IsPlayerDead() Then
			; The original run tolerated death (it resigns back to the outpost) but
			; we should not keep going while dead - give up this run.
			Return $openedChests > 0 ? $SUCCESS : $FAIL
		EndIf

		Info('Running to chest spot #' & ($i + 1) & '/' & $total)
		NfQ8RunToSpot($NFQ8_CHEST_SPOTS[$i][0], $NFQ8_CHEST_SPOTS[$i][1])

		; Open whatever chests are around this spot. Loot is collected by BotsHub
		; according to the loot configuration.
		Local $opened = FindAndOpenChests($RANGE_SPELLCAST, SurvivorNfQ8)
		If $opened Then $openedChests += 1
	Next

	Info('Opened ' & $openedChests & ' chests.')
	Return ($openedChests > 0 And IsPlayerAlive()) ? $SUCCESS : $FAIL
EndFunc


;~ Move to a spot while keeping the original NF Q8 assassin's speed/defence
;~ rotation active (faithful port of the old farm's "_Run" behaviour, using the
;~ decoded build slot numbers). Returns $SUCCESS when the destination is reached
;~ (or we are close enough) while alive, $FAIL if the player died along the way.
Func NfQ8RunToSpot($x, $y, $precision = 100, $maxBlocked = 20)
	If IsPlayerDead() Then Return $FAIL

	Local $me = GetMyAgent()
	Local $destX = $x
	Local $destY = $y
	Move($destX, $destY)
	Local $blocked = 0
	Local $energy

	While IsPlayerAlive()
		$me = GetMyAgent()
		If GetDistanceToPoint($me, $x, $y) <= $precision Then ExitLoop
		$energy = GetEnergy()

		; --- movement speed rotation (mirrors old farm, build-A slots) ---
		; Start Dwarven Stability (slot 6) so our Dash stance lasts longer, then
		; Dash, then use the movement/shout upkeep as in the original.
		If $energy >= 5 And NfQ8OffEffect($NFQ8_SLOT_DWARVEN_STABILITY) And IsRecharged($NFQ8_SLOT_DWARVEN_STABILITY) Then
			UseSkillEx($NFQ8_SLOT_DWARVEN_STABILITY)
		EndIf
		If $energy >= 8 And IsRecharged($NFQ8_SLOT_DASH) Then
			UseSkillEx($NFQ8_SLOT_DASH)
		EndIf
		If $energy >= 11 And NfQ8OffEffect($NFQ8_SLOT_DASH) And IsRecharged($NFQ8_SLOT_SHADOW_SANCTUARY) Then
			UseSkillEx($NFQ8_SLOT_SHADOW_SANCTUARY)
		EndIf
		If $energy >= 15 And NfQ8OffEffect($NFQ8_SLOT_SHADOW_SANCTUARY) And NfQ8OffEffect($NFQ8_SLOT_DASH) And IsRecharged($NFQ8_SLOT_WATCH_YOURSELF) Then
			UseSkillEx($NFQ8_SLOT_WATCH_YOURSELF)
		EndIf

		; --- crippling / knock counter ---
		If GetEffect($ID_CRIPPLED) <> Null And IsRecharged($NFQ8_SLOT_I_AM_UNSTOPPABLE) Then
			UseSkillEx($NFQ8_SLOT_I_AM_UNSTOPPABLE)
		EndIf
		If GetIsKnocked($me) And IsRecharged($NFQ8_SLOT_I_AM_UNSTOPPABLE) And GetEnergy() >= 5 Then
			UseSkillEx($NFQ8_SLOT_I_AM_UNSTOPPABLE)
		EndIf

		; --- low HP / defence (mirrors old farm, build-A slots) ---
		; Note: original farm compared HP as a 0..1 fraction; BotsHub's GetHealth()
		; returns absolute HP, so we compare through NfQ8HealthFraction().
		If NfQ8HealthFraction() < 0.9 And GetEnergy() >= 10 And NfQ8OffEffect($NFQ8_SLOT_SHROUD_OF_DISTRESS) And IsRecharged($NFQ8_SLOT_SHROUD_OF_DISTRESS) Then
			If GetEffect($ID_DAZED) <> Null Then
				Local $nearestFoe = GetNearestEnemyToAgent($me)
				If $nearestFoe <> Null And GetDistance($me, $nearestFoe) >= 1300 Then UseSkillEx($NFQ8_SLOT_SHROUD_OF_DISTRESS)
			Else
				UseSkillEx($NFQ8_SLOT_SHROUD_OF_DISTRESS)
			EndIf
		EndIf
		If NfQ8HealthFraction() < 0.7 And GetEnergy() >= 5 And IsRecharged($NFQ8_SLOT_SHADOWFORM) Then
			Local $nearestFoe = GetNearestEnemyToAgent($me)
			If $nearestFoe <> Null And GetDistance($me, $nearestFoe) <= 1400 And GetEffect($ID_DAZED) == Null Then
				UseSkillEx($NFQ8_SLOT_SHADOWFORM)
			EndIf
		EndIf
		If NfQ8HealthFraction() < 0.5 And GetEnergy() >= 5 Then
			; Emergency: Shadow Sanctuary (regen + armor) first, else Heart of Shadow.
			If IsRecharged($NFQ8_SLOT_SHADOW_SANCTUARY) Then
				UseSkillEx($NFQ8_SLOT_SHADOW_SANCTUARY)
			ElseIf IsRecharged($NFQ8_SLOT_HEART_OF_SHADOW) Then
				UseSkillEx($NFQ8_SLOT_HEART_OF_SHADOW)
			EndIf
		EndIf

		; --- movement ---
		$me = GetMyAgent()
		If Not IsPlayerMoving() Then
			$blocked += 1
			Move($destX, $destY)
		EndIf
		If $blocked > 10 And IsRecharged($NFQ8_SLOT_HEART_OF_SHADOW) Then
			$blocked = 0
			Local $npc = GetNPCBehindNfQ8($destX, $destY)
			If $npc == Null Then $npc = $me
			UseSkillEx($NFQ8_SLOT_HEART_OF_SHADOW, $npc)
		EndIf

		PingSleep(120)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Defence callback invoked by BotsHub while walking to / opening chests. Keeps
;~ the assassin's defensive state topped up (Shadow Form etc.) so it can survive
;~ standing still to open a chest, mirroring the original farm.
Func SurvivorNfQ8()
	If IsPlayerDead() Then Return

	; Cast Shadow Form proactively when we still have energy and are threatened or
	; while standing still opening a chest.
	Local $me = GetMyAgent()
	Local $nearestFoe = GetNearestEnemyToAgent($me)
	Local $energy = GetEnergy()

	If $energy >= 5 And IsRecharged($NFQ8_SLOT_I_AM_UNSTOPPABLE) And ($nearestFoe <> Null And GetDistance($me, $nearestFoe) < $RANGE_AREA) Then
		UseSkillEx($NFQ8_SLOT_I_AM_UNSTOPPABLE)
	EndIf
	If $energy >= 20 And IsRecharged($NFQ8_SLOT_SHADOWFORM) And ($nearestFoe <> Null And GetDistance($me, $nearestFoe) < ($RANGE_SPELLCAST + 400)) Then
		UseSkillEx($NFQ8_SLOT_SHADOWFORM)
	EndIf

	RandomSleep(120)
EndFunc


;~ ---- Local helpers (faithful adaptation of the old farm's helpers) ----

;~ Current player health as a 0..1 fraction (mirrors the original farm, which
;~ compared the struct's HP fraction). BotsHub's GetHealth() returns absolute HP.
Func NfQ8HealthFraction()
	Local $me = GetMyAgent()
	Local $maxHealth = DllStructGetData($me, 'MaxHealth')
	If $maxHealth <= 0 Then Return 0
	Return GetHealth() / $maxHealth
EndFunc


;~ True when the current effect originating from the skill in the given slot is
;~ NOT active (i.e. we are free to recast it). Mirrors old "OffEffect(x)".
Func NfQ8OffEffect($slot)
	Local $skillID = GetSkillbarSkillID($slot)
	If $skillID == 0 Then Return True
	Local $effect = GetEffect($skillID)
	If $effect == Null Then Return True
	Return False
EndFunc


;~ Find an NPC (foe or party ally) roughly behind the movement direction (dot
;~ product based) to use Heart of Shadow / movement tools on - simplified form of
;~ the original helper. Returns Null when nobody suitable is in range.
Func GetNPCBehindNfQ8($targetX, $targetY)
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $npcs = GetNPCsInRangeOfAgent($me, Null, $RANGE_SPELLCAST)
	Local $bestNpc = Null
	Local $minDot = 1

	Local $moveX = $targetX - $myX
	Local $moveY = $targetY - $myY
	Local $len = Sqrt($moveX ^ 2 + $moveY ^ 2)
	If $len = 0 Then Return Null
	$moveX /= $len
	$moveY /= $len

	If IsArray($npcs) Then
		For $npc In $npcs
			Local $dx = DllStructGetData($npc, 'X') - $myX
			Local $dy = DllStructGetData($npc, 'Y') - $myY
			Local $nLen = Sqrt($dx ^ 2 + $dy ^ 2)
			If $nLen = 0 Then ContinueLoop
			$dx /= $nLen
			$dy /= $nLen
			Local $dot = $dx * $moveX + $dy * $moveY
			If $dot < $minDot Then
				$minDot = $dot
				$bestNpc = $npc
			EndIf
		Next
	EndIf
	Return $bestNpc
EndFunc
