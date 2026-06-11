#CS ===========================================================================
; Author: GitHub Copilot (prototype for BotsHub)
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
#include '../utilities/SupportTeam.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $HANAKU_STABLE_BASELINE = '2026-04-15-chain-stable'

Global Const $HANAKU_PLAYER_SKILLBAR = 'Owpl4Jf8ImmqFxjozcANG6c19h7UDC'
Global Const $HANAKU_HERO_MORGAHN_SKILLBAR = 'OQijEqmMKODbe8OmEbi7x3YWMA'
Global Const $HANAKU_HERO_MOW_SKILLBAR = 'OAlkUwG4RZmUMjC4OWN2uzWYVgdA'
Global Const $HANAKU_HERO_OLIAS_SKILLBAR = 'OAlkUwG4RZmUMjC4OWNWC4WIegdA'
Global Const $HANAKU_HERO_LIVIA_SKILLBAR = 'OAhjQoGYIP3hhWVVaO5EeDzxJA'
Global Const $HANAKU_HERO_NORGU_SKILLBAR = 'OQREAsIjU8MV5aI/dwPgnWFQDA'
Global Const $HANAKU_HERO_RAZAH_SKILLBAR = 'OQREAsIjU8MV5aI/ewPgnWFQDA'
Global Const $HANAKU_HERO_GWEN_SKILLBAR = 'OQhjAwBc4QkA5ZIg3ATAcQFVXMA'
Global Const $HANAKU_FARM_DURATION = 3 * 60 * 1000

Global Const $HANAKU_OUTPOST_ID = $ID_SEAFARERS_REST
Global Const $HANAKU_EXPLO_ID = $ID_RHEAS_CRATER
Global Const $HANAKU_BOSS_MODEL_ID = 4029

Global Const $HANAKU_HERO_INDEX = 1

Global Const $HANAKU_DEADLY_PARADOX = 1
Global Const $HANAKU_SHADOW_FORM = 2
Global Const $HANAKU_SHROUD_OF_DISTRESS = 3
Global Const $HANAKU_CRIPPLING_VICTORY = 4
Global Const $HANAKU_REAP_IMPURITIES = 5
Global Const $HANAKU_GRENTHS_AURA = 6
Global Const $HANAKU_DEATHS_CHARGE = 7
Global Const $HANAKU_CRITICAL_AGILITY = 8

Global Const $HANAKU_WEAPON_STAFF = 3
Global Const $HANAKU_WEAPON_SCYTHE = 4

Global Const $HANAKU_OUTPOST_GATE_X = -11194
Global Const $HANAKU_OUTPOST_GATE_Y = -18352
Global Const $HANAKU_STAGING_X = -9980
Global Const $HANAKU_STAGING_Y = -18074
Global Const $HANAKU_HERO_BAIT_X = -8380
Global Const $HANAKU_HERO_BAIT_Y = -19180
Global Const $HANAKU_HERO_RESET_X = -10320
Global Const $HANAKU_HERO_RESET_Y = -18110
Global Const $HANAKU_HERO_SAFE_POST_DC_X = -5990
Global Const $HANAKU_HERO_SAFE_POST_DC_Y = -15670
Global Const $HANAKU_HERO_SUPPORT_X = -7780
Global Const $HANAKU_HERO_SUPPORT_Y = -19470
Global Const $HANAKU_BOSS_X = -6201
Global Const $HANAKU_BOSS_Y = -21074
Global Const $HANAKU_LOOT_NEARBY_MAX_DIST = 650
Global Const $HANAKU_APPROACH_RIGHT_EARLY_X = -9450
Global Const $HANAKU_APPROACH_RIGHT_EARLY_Y = -18390
Global Const $HANAKU_APPROACH_RETURN_LINE_X = -8750
Global Const $HANAKU_APPROACH_RETURN_LINE_Y = -18920
Global Const $HANAKU_HOLD_X = -7240
Global Const $HANAKU_HOLD_Y = -19860
Global Const $HANAKU_FORWARD_PUSH_X = -6320
Global Const $HANAKU_FORWARD_PUSH_Y = -20010
Global Const $HANAKU_FORWARD_PUSH_WAIT_MS = 4000
Global Const $HANAKU_HOLD_PREP_WAIT_MS = 2000
Global Const $HANAKU_PUSH_START_DELAY_MS = 2000
Global Const $HANAKU_FIGHT_SPOT_X = -6920
Global Const $HANAKU_FIGHT_SPOT_Y = -20683
Global Const $HANAKU_BALL_WAIT_MS = 2000
Global Const $HANAKU_HERO_BAIT_WAIT_FORWARD_MS = 5600
Global Const $HANAKU_HERO_BAIT_WAIT_BACK_MS = 3800
Global Const $HANAKU_HERO_BAIT_WAIT_SETTLE_MS = 2200
Global Const $HANAKU_FIGHT_TIMEOUT_MS = 5 * 60 * 1000
Global Const $HANAKU_SF_CHAIN_START_MS = 13000
Global Const $HANAKU_SF_QUEUE_RETRY_MS = 220
Global Const $HANAKU_DP_AFTER_SF_DELAY_MS = 500
Global Const $HANAKU_SF_DP_MIN_ENERGY = 20
Global Const $HANAKU_SF_REFRESH_CADENCE_MS = 20500
Global Const $HANAKU_PUSH_MIN_SF_MS = 15000
Global Const $HANAKU_CHAIN_MIN_ADREN4 = 6
Global Const $HANAKU_CHAIN_MIN_ADREN5 = 6
Global Const $HANAKU_CHAIN_REAP_WINDOW_MS = 1900
Global Const $HANAKU_CHAIN_REAP_MIN_DELAY_MS = 700
Global Const $HANAKU_CHAIN_RETRY_MS = 220
Global Const $HANAKU_FIGHT_LOG_HEARTBEAT_MS = 500
Global Const $HANAKU_DAMAGE_UNLOCK_TIMEOUT_MS = 3500
Global Const $HANAKU_DP_ATTACK_LOCK_MS = 300

Global $hanaku_perma_chain_count = 0

Global $hanaku_farm_setup = False
Global $hanaku_morgahn_index_cache = 0
Global $hanaku_log_handle = -1
Global $hanaku_log_file = ''
Global $hanaku_log_timer = TimerInit()
Global $hanaku_log_run_number = 0
Global $hanaku_log_heartbeat_timer = TimerInit()
Global $hanaku_last_dp_cast_timer = Null
Global $hanaku_last_sf_request_timer = Null
Global $hanaku_combo_state_dbg = 0
Global $hanaku_chain_cv_ok_count = 0
Global $hanaku_chain_reap_ok_count = 0
Global $hanaku_chain_fail_count = 0


;~ Main method to farm Focus of Hanaku
Func FocusHanakuFarm()
	If Not $hanaku_farm_setup And SetupFocusHanakuFarm() == $FAIL Then Return $PAUSE
	If GoToRheasCrater() == $FAIL Then Return $FAIL
	$hanaku_log_run_number += 1
	HanakuFightLogInit()
	HanakuFightLogWrite('run_start', 'run=' & $hanaku_log_run_number & ';baseline=' & $HANAKU_STABLE_BASELINE)

	Local $result = FocusHanakuFarmLoop()
	HanakuFightLogWrite('run_end', 'result=' & $result)
	HanakuFightLogClose()
	ResignAndReturnToOutpost($HANAKU_OUTPOST_ID)
	Return $result
EndFunc


Func SetupFocusHanakuFarm()
	Info('Setting up Focus of Hanaku farm')
	Info('Travelling to Seafarer''s Rest')
	If TravelToOutpost($HANAKU_OUTPOST_ID, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)

	If SetupPlayerFocusHanakuFarm() == $FAIL Then Return $FAIL
	If SetupTeamFocusHanakuFarm() == $FAIL Then Return $FAIL

	$hanaku_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerFocusHanakuFarm()
	Info('Setting up player build and starting weapon set')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
		LoadSkillTemplate($HANAKU_PLAYER_SKILLBAR)
	Else
		Warn('Should run this farm as assassin')
		Return $FAIL
	EndIf
	RandomSleep(250)
	ChangeWeaponSet($HANAKU_WEAPON_STAFF)
	Return $SUCCESS
EndFunc


Func SetupTeamFocusHanakuFarm()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up fixed hero team: Morgahn, Master of Whispers, Olias, Livia, Norgu, Razah, Gwen')
	Info('Hanaku team setup phase 1/3: clearing party and heroes')
	If HanakuEnsureSoloParty() == $FAIL Then
		If HanakuHasExactFixedTeam() Then
			Warn('Hanaku clear timed out, but fixed team is already present; proceeding with build application')
		Else
		Warn('Hanaku team setup failed while clearing current party/heroes')
		Return $FAIL
		EndIf
	EndIf

	Info('Hanaku team setup phase 2/3: adding heroes')

	If HanakuTryAddHero($ID_GENERAL_MORGAHN, 'Morgahn', 2) == $FAIL Then Return $FAIL
	If HanakuTryAddHero($ID_MASTER_OF_WHISPERS, 'Master of Whispers', 3) == $FAIL Then Return $FAIL
	If HanakuTryAddHero($ID_OLIAS, 'Olias', 4) == $FAIL Then Return $FAIL
	If HanakuTryAddHero($ID_LIVIA, 'Livia', 5) == $FAIL Then Return $FAIL
	If HanakuTryAddHero($ID_NORGU, 'Norgu', 6) == $FAIL Then Return $FAIL
	If HanakuTryAddHero($ID_RAZAH, 'Razah', 7) == $FAIL Then Return $FAIL
	If HanakuTryAddHero($ID_GWEN, 'Gwen', 8) == $FAIL Then Return $FAIL

	If Not HanakuHasExactFixedTeam() Then
		Warn('Could not set up Hanaku party correctly. Team composition mismatch (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')
		Return $FAIL
	EndIf

	Info('Hanaku team setup phase 3/3: applying hero builds')
	If HanakuLoadHeroBuildByID($ID_GENERAL_MORGAHN, 'Morgahn', $HANAKU_HERO_MORGAHN_SKILLBAR, 1) == $FAIL Then Return $FAIL
	If HanakuLoadHeroBuildByID($ID_MASTER_OF_WHISPERS, 'Master of Whispers', $HANAKU_HERO_MOW_SKILLBAR, 2) == $FAIL Then Return $FAIL
	If HanakuLoadHeroBuildByID($ID_OLIAS, 'Olias', $HANAKU_HERO_OLIAS_SKILLBAR, 3) == $FAIL Then Return $FAIL
	If HanakuLoadHeroBuildByID($ID_LIVIA, 'Livia', $HANAKU_HERO_LIVIA_SKILLBAR, 4) == $FAIL Then Return $FAIL
	If HanakuLoadHeroBuildByID($ID_NORGU, 'Norgu', $HANAKU_HERO_NORGU_SKILLBAR, 5) == $FAIL Then Return $FAIL
	If HanakuLoadHeroBuildByID($ID_RAZAH, 'Razah', $HANAKU_HERO_RAZAH_SKILLBAR, 6) == $FAIL Then Return $FAIL
	If HanakuLoadHeroBuildByID($ID_GWEN, 'Gwen', $HANAKU_HERO_GWEN_SKILLBAR, 7) == $FAIL Then Return $FAIL
	RandomSleep(200)
	RandomSleep(200)
	SupportTeamOpenHeroPanels('Focus Hanaku')

	Return $SUCCESS
EndFunc


Func HanakuTryAddHero($heroID, $heroName, $expectedSize)
	For $i = 1 To 8
		If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
		AddHero($heroID)
		Local $verifyTimer = TimerInit()
		While TimerDiff($verifyTimer) < 2000
			If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
			RandomSleep(140)
		WEnd

		If GetPartySize() < $expectedSize Then RandomSleep(220)
	Next
	Warn('Could not add hero ' & $heroName & ' (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')
	Return $FAIL
EndFunc


Func HanakuEnsureSoloParty($maxWaitMs = 9000)
	$maxWaitMs = 14000
	Local $timer = TimerInit()
	SupportTeamKickAllHeroesByIDSweep()
	KickAllHeroes()
	LeaveParty(False)
	While TimerDiff($timer) < $maxWaitMs
		If GetPartySize() <= 1 And GetHeroCount() == 0 Then Return $SUCCESS
		SupportTeamKickAllHeroesByIDSweep()
		KickAllHeroes()
		LeaveParty(False)
		RandomSleep(320)
	WEnd
	Warn('Hanaku party reset timeout (party=' & GetPartySize() & ', heroes=' & GetHeroCount() & ')')
	Return $FAIL
EndFunc


Func HanakuHasExactFixedTeam()
	Local $requiredHeroes[7] = [ _
		$ID_GENERAL_MORGAHN, _
		$ID_MASTER_OF_WHISPERS, _
		$ID_OLIAS, _
		$ID_LIVIA, _
		$ID_NORGU, _
		$ID_RAZAH, _
		$ID_GWEN _
	]

	If GetPartySize() <> 8 Then Return False
	For $i = 0 To UBound($requiredHeroes) - 1
		If GetHeroNumberByHeroID($requiredHeroes[$i]) == Null Then Return False
	Next
	Return True
EndFunc


Func HanakuLoadHeroBuildByID($heroID, $heroName, $template, $fallbackIndex)
	Local $heroIndex = GetHeroNumberByHeroID($heroID)
	If $heroIndex == Null Then $heroIndex = $fallbackIndex
	If $heroIndex <= 0 Then
		Warn('Could not resolve hero index for ' & $heroName & ' while loading build')
		Return $FAIL
	EndIf

	LoadSkillTemplate($template, $heroIndex)
	RandomSleep(150)
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Rhea's Crater
Func GoToRheasCrater()
	TravelToOutpost($HANAKU_OUTPOST_ID, $district_name)
	Local $zoneAttempt = 0
	While GetMapID() <> $HANAKU_EXPLO_ID
		$zoneAttempt += 1
		Info('Running through Seafarer''s Rest exit (attempt ' & $zoneAttempt & ')')
		; Two-step approach reduces occasional portal miss/pathing hiccups.
		MoveTo(-11120, -18760)
		MoveTo(-11335, -19078)
		Move($HANAKU_OUTPOST_GATE_X, $HANAKU_OUTPOST_GATE_Y)
		If WaitMapLoading($HANAKU_EXPLO_ID, 15000, 1000) Then ExitLoop

		; Quick reposition and retry when the first portal touch did not zone.
		MoveTo(-11240, -18890)
		MoveTo(-11060, -18680)
		If $zoneAttempt >= 4 Then Return $FAIL
		RandomSleep(450)
	WEnd
	HanakuSetAllHeroesGuard()
	HanakuLockMorgahnSkills()
	ChangeWeaponSet($HANAKU_WEAPON_STAFF)
	RandomSleep(120)
	Info('Rhea''s Crater reached - switched to weapon set 3')
	Return $SUCCESS
EndFunc


;~ Main run logic in explorable
Func FocusHanakuFarmLoop()
	If GetMapID() <> $HANAKU_EXPLO_ID Then Return $FAIL
	HanakuSetAllHeroesGuard()
	HanakuLockMorgahnSkills()
	ChangeWeaponSet($HANAKU_WEAPON_STAFF)
	RandomSleep(80)
	Info('Moving to staging point')
	If Not MoveToWithRetry($HANAKU_STAGING_X, $HANAKU_STAGING_Y, 4) Then
		Warn('Could not reach staging point after zoning')
		Return $FAIL
	EndIf

	If HeroBaitAndReset() == $FAIL Then Return $FAIL

	Info('Init SF/DP/SoD')
	If CastPermaChain() == $FAIL Then Return $FAIL
	HanakuTriggerMorgahnOnPermaStart()

	Info('Running to Hanaku hold spot')
	If MoveToHanakuHoldSpot() == $FAIL Then Return $FAIL

	Info('Holding position and balling melee for ' & Int($HANAKU_BALL_WAIT_MS / 1000) & ' seconds')
	If WaitAndMaintainPerma($HANAKU_BALL_WAIT_MS, $HANAKU_HOLD_X, $HANAKU_HOLD_Y) == $FAIL Then Return $FAIL
	Info('Waiting 2 seconds before push')
	If WaitAndMaintainPerma($HANAKU_PUSH_START_DELAY_MS, $HANAKU_HOLD_X, $HANAKU_HOLD_Y) == $FAIL Then Return $FAIL

	Info('Switching to zealous scythe, using slot 7 and pushing to Hanaku')
	If PushBallToHanakuFightSpot() == $FAIL Then Return $FAIL

	Info('Killing Hanaku')
	If KillHanaku() == $FAIL Then Return $FAIL

	Info('Picking up loot')
	If LootHanakuFast() == $FAIL Then Return $FAIL
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func CastPermaChain()
	If IsPlayerDead() Then Return $FAIL
	If IsRecharged($HANAKU_SHADOW_FORM) Then UseSkill($HANAKU_SHADOW_FORM)
	RandomSleep($HANAKU_DP_AFTER_SF_DELAY_MS)
	If IsRecharged($HANAKU_DEADLY_PARADOX) Then
		UseSkill($HANAKU_DEADLY_PARADOX)
		HanakuMarkDpCast()
	EndIf
	If IsRecharged($HANAKU_SHROUD_OF_DISTRESS) Then UseSkillEx($HANAKU_SHROUD_OF_DISTRESS)
	RandomSleep(80)
	Return $SUCCESS
EndFunc


Func HeroBaitAndReset()
	If GetPartySize() < 2 Then
		Warn('Party too small for hero bait sequence - skipping bait this run')
		ChangeWeaponSet($HANAKU_WEAPON_STAFF)
		RandomSleep(120)
		Return $SUCCESS
	EndIf
	ChangeWeaponSet($HANAKU_WEAPON_STAFF)
	RandomSleep(80)
	HanakuSetAllHeroesGuard()
	HanakuLockMorgahnSkills()
	Info('Flagging heroes to first mob')
	CommandAll($HANAKU_HERO_BAIT_X, $HANAKU_HERO_BAIT_Y)
	RandomSleep($HANAKU_HERO_BAIT_WAIT_FORWARD_MS)
	ChangeWeaponSet($HANAKU_WEAPON_STAFF)
	Info('Resetting heroes back to start')
	CommandAll($HANAKU_HERO_RESET_X, $HANAKU_HERO_RESET_Y)
	RandomSleep(500)
	CommandAll($HANAKU_HERO_RESET_X, $HANAKU_HERO_RESET_Y)
	RandomSleep($HANAKU_HERO_BAIT_WAIT_BACK_MS)
	ChangeWeaponSet($HANAKU_WEAPON_STAFF)
	Info('Waiting for first mob to commit before pre-cast')
	RandomSleep($HANAKU_HERO_BAIT_WAIT_SETTLE_MS)
	Return $SUCCESS
EndFunc


Func MoveToHanakuHoldSpot()
	Local $path[6][2] = [ _
		[$HANAKU_APPROACH_RIGHT_EARLY_X, $HANAKU_APPROACH_RIGHT_EARLY_Y], _
		[$HANAKU_APPROACH_RETURN_LINE_X, $HANAKU_APPROACH_RETURN_LINE_Y], _
		[-8612, -18781], [-7958, -19276], [-7420, -19584], [$HANAKU_HOLD_X, $HANAKU_HOLD_Y] _
	]
	For $i = 0 To UBound($path) - 1
		If IsPlayerDead() Then Return $FAIL
		If Not MoveToWithRetry($path[$i][0], $path[$i][1], 2) Then Return $FAIL
	Next

	Info('Reached first hold point - waiting 2 seconds')
	If WaitAndMaintainPerma($HANAKU_HOLD_PREP_WAIT_MS, $HANAKU_HOLD_X, $HANAKU_HOLD_Y) == $FAIL Then Return $FAIL

	If Not MoveToWithRetry($HANAKU_FORWARD_PUSH_X, $HANAKU_FORWARD_PUSH_Y, 4) Then
		Warn('Forward push blocked - continuing without deep push this run')
		Return $SUCCESS
	EndIf

	Info('Forward push reached - holding briefly before retreat')
	If WaitAndMaintainPerma($HANAKU_FORWARD_PUSH_WAIT_MS, $HANAKU_FORWARD_PUSH_X, $HANAKU_FORWARD_PUSH_Y) == $FAIL Then Return $FAIL

	Info('Returning to hold spot')
	If Not MoveToWithRetry($HANAKU_HOLD_X, $HANAKU_HOLD_Y, 3) Then Return $FAIL
	Return $SUCCESS
EndFunc


Func WaitAndMaintainPerma($waitMs, $anchorX = Null, $anchorY = Null)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $waitMs And IsPlayerAlive()
		MaintainHanakuPermaTick()
		If $anchorX <> Null And $anchorY <> Null Then
			If Not IsPlayerMoving() And GetDistanceToPoint(GetMyAgent(), $anchorX, $anchorY) > 180 Then Move($anchorX, $anchorY, 0)
		EndIf
		Sleep(90)
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func PushBallToHanakuFightSpot()
	If IsPlayerDead() Then Return $FAIL
	Info('Waiting up to 3 seconds for SF window before teleport push')
	If HanakuWaitForPushSFWindow(3000) == $FAIL Then Return $FAIL
	HanakuForceScytheSet()
	Local $dcUsed = HanakuTryDeathsChargeToHanaku(2200)

	Local $path[4][2] = [ _
		[-7123, -19855], [-6683, -20000], [-6920, -20683], [$HANAKU_FIGHT_SPOT_X, $HANAKU_FIGHT_SPOT_Y] _
	]
	For $i = 0 To UBound($path) - 1
		If IsPlayerDead() Then Return $FAIL
		; If DC already landed us on/near Hanaku, do not walk old waypoints backwards.
		If HanakuCanEngageHanaku(1450) Then ExitLoop
		$dcUsed = HanakuTryDeathsChargeToHanaku(900) Or $dcUsed
		If HanakuCanEngageHanaku(1450) Then ExitLoop
		If Not MoveToWithRetry($path[$i][0], $path[$i][1], 3) Then
			; Last push segment can be body-blocked by melee; continue if Hanaku is already engageable.
			If $i >= 2 And HanakuCanEngageHanaku(2500) Then
				Warn('Final push waypoint blocked, but Hanaku is in engage range - continuing')
				ExitLoop
			EndIf
			If $i >= 2 And MoveToWithRetry($HANAKU_BOSS_X, $HANAKU_BOSS_Y, 2) And HanakuCanEngageHanaku(2500) Then
				Warn('Recovered push via direct boss approach')
				ExitLoop
			EndIf
			Return $FAIL
		EndIf
		$dcUsed = HanakuTryDeathsChargeToHanaku(700) Or $dcUsed
	Next

	HanakuRetargetForPush()
	If $dcUsed Then HanakuSendHeroesSafeAfterDC()
	Return $SUCCESS
EndFunc


Func HanakuTryDeathsChargeToHanaku($windowMs = 1000)
	If IsPlayerDead() Then Return False
	Local $timer = TimerInit()
	While TimerDiff($timer) < $windowMs And IsPlayerAlive()
		If Not IsRecharged($HANAKU_DEATHS_CHARGE) Then Return True
		Local $hanaku = GetHanakuTarget()
		If $hanaku <> Null Then
			ChangeTarget($hanaku)
			UseSkillEx($HANAKU_DEATHS_CHARGE, $hanaku)
		EndIf
		RandomSleep(130)
	WEnd
	Return Not IsRecharged($HANAKU_DEATHS_CHARGE)
EndFunc


Func HanakuSendHeroesSafeAfterDC()
	If GetPartySize() < 2 Then Return
	Info('Sending heroes to post-DC safe point')
	HanakuSetAllHeroesGuard()
	HanakuLockMorgahnSkills()
	CommandHero(1, $HANAKU_HERO_SAFE_POST_DC_X, $HANAKU_HERO_SAFE_POST_DC_Y)
	CommandAll($HANAKU_HERO_SAFE_POST_DC_X, $HANAKU_HERO_SAFE_POST_DC_Y)
	RandomSleep(250)
	CommandHero(1, $HANAKU_HERO_SAFE_POST_DC_X, $HANAKU_HERO_SAFE_POST_DC_Y)
	CommandAll($HANAKU_HERO_SAFE_POST_DC_X, $HANAKU_HERO_SAFE_POST_DC_Y)
EndFunc


Func MoveToWithRetry($x, $y, $attempts = 3)
	For $a = 1 To $attempts
		If IsPlayerDead() Then Return False
		If MoveTo($x, $y, 25, 0, MaintainHanakuPermaTick) Then Return True

		; Deterministic anti-block nudges avoid random backward hops.
		Local $nudgeX = $x
		Local $nudgeY = $y
		Switch Mod($a, 4)
			Case 1
				$nudgeX = $x + 180
			Case 2
				$nudgeX = $x - 180
			Case 3
				$nudgeY = $y + 180
			Case 0
				$nudgeY = $y - 180
		EndSwitch
		MoveTo($nudgeX, $nudgeY, 25, 0, MaintainHanakuPermaTick)
		RandomSleep(140)
	Next

	If HanakuTryBodyblockRescue($x, $y) Then Return True
	Warn('Waypoint blocked: (' & $x & ',' & $y & ')')
	Return False
EndFunc


Func HanakuTryBodyblockRescue($targetX, $targetY)
	Local $me = GetMyAgent()
	Local $mx = DllStructGetData($me, 'X')
	Local $my = DllStructGetData($me, 'Y')
	Local $dx = $targetX - $mx
	Local $dy = $targetY - $my
	Local $len = Sqrt(($dx * $dx) + ($dy * $dy))
	If $len < 1 Then Return False

	; Perpendicular unit vector for right/left escape moves.
	Local $rx = $dy / $len
	Local $ry = -$dx / $len

	Info('Bodyblock rescue: trying right side-steps')
	If HanakuTryRescueSide($targetX, $targetY, $rx, $ry) Then Return True
	Info('Bodyblock rescue: trying right forward arc')
	If HanakuTryRescueArc($targetX, $targetY, $rx, $ry) Then Return True

	Info('Bodyblock rescue: trying left side-steps')
	If HanakuTryRescueSide($targetX, $targetY, -$rx, -$ry) Then Return True
	Info('Bodyblock rescue: trying left forward arc')
	If HanakuTryRescueArc($targetX, $targetY, -$rx, -$ry) Then Return True

	Return False
EndFunc


Func HanakuTryRescueSide($targetX, $targetY, $vx, $vy)
	Local $me = GetMyAgent()
	Local $mx = DllStructGetData($me, 'X')
	Local $my = DllStructGetData($me, 'Y')
	Local $step1x = Int($mx + (220 * $vx))
	Local $step1y = Int($my + (220 * $vy))
	Local $step2x = Int($mx + (420 * $vx))
	Local $step2y = Int($my + (420 * $vy))

	If IsPlayerDead() Then Return False
	MoveTo($step1x, $step1y, 25, 0, MaintainHanakuPermaTick)
	RandomSleep(120)
	If MoveTo($targetX, $targetY, 25, 0, MaintainHanakuPermaTick) Then Return True

	If IsPlayerDead() Then Return False
	MoveTo($step2x, $step2y, 25, 0, MaintainHanakuPermaTick)
	RandomSleep(120)
	If MoveTo($targetX, $targetY, 25, 0, MaintainHanakuPermaTick) Then Return True

	Return False
EndFunc


Func HanakuTryRescueArc($targetX, $targetY, $sideX, $sideY)
	Local $me = GetMyAgent()
	Local $mx = DllStructGetData($me, 'X')
	Local $my = DllStructGetData($me, 'Y')
	Local $dx = $targetX - $mx
	Local $dy = $targetY - $my
	Local $len = Sqrt(($dx * $dx) + ($dy * $dy))
	If $len < 1 Then Return False

	Local $fx = $dx / $len
	Local $fy = $dy / $len

	Local $arc1x = Int($mx + (170 * $sideX) + (230 * $fx))
	Local $arc1y = Int($my + (170 * $sideY) + (230 * $fy))
	Local $arc2x = Int($mx + (260 * $sideX) + (430 * $fx))
	Local $arc2y = Int($my + (260 * $sideY) + (430 * $fy))

	If IsPlayerDead() Then Return False
	MoveTo($arc1x, $arc1y, 25, 0, MaintainHanakuPermaTick)
	RandomSleep(120)
	HanakuRetargetForPush()
	If MoveTo($targetX, $targetY, 25, 0, MaintainHanakuPermaTick) Then Return True

	If IsPlayerDead() Then Return False
	MoveTo($arc2x, $arc2y, 25, 0, MaintainHanakuPermaTick)
	RandomSleep(120)
	HanakuRetargetForPush()
	If MoveTo($targetX, $targetY, 25, 0, MaintainHanakuPermaTick) Then Return True

	Return False
EndFunc


Func HanakuRetargetForPush()
	Local $hanaku = GetHanakuTarget()
	If $hanaku == Null Then $hanaku = GetCurrentTarget()
	If $hanaku == Null Then Return
	ChangeTarget($hanaku)
	Attack($hanaku)
EndFunc


Func LootHanakuFast()
	If IsPlayerDead() Then Return $FAIL

	; Minimalist post-kill loot: no extra movement, just pick nearby drops at current position.
	Local $nearestLoot = GetNearestItemToAgent(GetMyAgent())
	Local $nearestLootDist = -1
	If $nearestLoot <> Null Then $nearestLootDist = Int(GetDistance(GetMyAgent(), $nearestLoot))
	If $nearestLoot == Null Then
		Info('No nearby loot detected after Hanaku kill - skipping loot loop')
		Return $SUCCESS
	EndIf
	If $nearestLootDist > $HANAKU_LOOT_NEARBY_MAX_DIST Then
		Info('No nearby loot detected after Hanaku kill - skipping loot loop (nearest=' & $nearestLootDist & ')')
		Return $SUCCESS
	EndIf

	Info('Picking up loot')
	For $j = 1 To 4
		PickUpItems(Null, DefaultShouldPickItem, $RANGE_SPIRIT)
		RandomSleep(150)
	Next
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_SPIRIT)
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func HanakuTryLootUnstuck()
	If IsPlayerDead() Then Return
	Local $foe = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_EARSHOT)
	If $foe <> Null And IsRecharged($HANAKU_DEATHS_CHARGE) Then
		Info('Loot unstuck: using Death''s Charge on nearby foe')
		UseSkillEx($HANAKU_DEATHS_CHARGE, $foe)
		RandomSleep(220)
	Else
		MoveRandom($HANAKU_BOSS_X, $HANAKU_BOSS_Y, 160)
		RandomSleep(180)
	EndIf
EndFunc


Func HanakuWaitForPlayerNearPoint($x, $y, $range, $timeout)
	Local $timer = TimerInit()
	While GetDistanceToPoint(GetMyAgent(), $x, $y) > $range
		If IsPlayerDead() Then Return $FAIL
		If TimerDiff($timer) > $timeout Then Return $FAIL
		Sleep(200)
	WEnd
	Return $SUCCESS
EndFunc


Func HanakuLockMorgahnSkills()
	If GetPartySize() < 2 Then Return
	HanakuDisableIncomingHeroesSkills()
EndFunc


Func HanakuTriggerMorgahnOnPermaStart()
	If GetPartySize() < 2 Then
		Warn('Morgahn trigger skipped: hero 1 is not available')
		Return
	EndIf

	; Requested debug behavior: force hero 1 (Morgahn) to cast slot 2 right after opener.
	Local $me = GetMyAgent()
	CommandHero(1, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'))
	SetHeroBehaviour(1, $ID_HERO_FIGHTING)
	For $i = 1 To 4
		UseHeroSkill(1, 2, $me)
		RandomSleep(120)
		If HanakuGetBestEffectTimeRemaining($ID_INCOMING, $ID_INCOMING_PVP) > 0 Then ExitLoop
	Next

	Local $incomingOnMe = HanakuGetBestEffectTimeRemaining($ID_INCOMING, $ID_INCOMING_PVP)
	If $incomingOnMe > 0 Then
		Info('Morgahn (hero 1) cast slot 2 on Sin')
	Else
		Warn('Morgahn (hero 1) slot 2 did not land on Sin (range/timing)')
	EndIf
EndFunc


Func HanakuWaitForPushSFWindow($maxWaitMs = 12000)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs And IsPlayerAlive()
		MaintainHanakuPermaTick()
		Local $sfRemaining = HanakuGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP)
		If $sfRemaining >= $HANAKU_PUSH_MIN_SF_MS Then Return $SUCCESS
		Sleep(90)
	WEnd
	; Do not hard-fail push if SF window did not open in time.
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func HanakuDisableIncomingHeroesSkills()
	Local $heroCount = GetHeroCount()
	If $heroCount <= 0 Then Return
	For $i = 1 To $heroCount
		Local $slot2 = GetSkillbarSkillID(2, $i)
		If $slot2 == $ID_INCOMING Or $slot2 == $ID_INCOMING_PVP Then DisableAllHeroSkills($i)
	Next
EndFunc


Func HanakuTriggerIncomingAcrossHeroes()
	Local $heroCount = GetHeroCount()
	If $heroCount <= 0 Then Return 0

	Local $triggered = 0
	; Pass 1: prefer paragon heroes with Incoming on slot 2.
	For $i = 1 To $heroCount
		If GetHeroProfession($i) <> $ID_PARAGON Then ContinueLoop
		Local $slot2p = GetSkillbarSkillID(2, $i)
		If $slot2p <> $ID_INCOMING And $slot2p <> $ID_INCOMING_PVP Then ContinueLoop
		For $k = 1 To 4
			UseHeroSkill($i, 2)
			RandomSleep(180)
		Next
		DisableAllHeroSkills($i)
		$triggered += 1
	Next
	If $triggered > 0 Then Return $triggered

	; Pass 2 fallback: any hero with Incoming on slot 2.
	For $i = 1 To $heroCount
		Local $slot2 = GetSkillbarSkillID(2, $i)
		If $slot2 <> $ID_INCOMING And $slot2 <> $ID_INCOMING_PVP Then ContinueLoop
		For $k = 1 To 4
			UseHeroSkill($i, 2)
			RandomSleep(180)
		Next
		DisableAllHeroSkills($i)
		$triggered += 1
	Next
	Return $triggered
EndFunc


Func HanakuTriggerFallbackAcrossHeroes()
	Local $heroCount = GetHeroCount()
	If $heroCount <= 0 Then Return 0

	Local $triggered = 0
	For $i = 1 To $heroCount
		Local $slot3 = GetSkillbarSkillID(3, $i)
		If $slot3 <> $ID_FALL_BACK And $slot3 <> $ID_FALL_BACK_PVP Then ContinueLoop
		For $k = 1 To 3
			UseHeroSkill($i, 3, GetMyAgent())
			RandomSleep(180)
		Next
		DisableAllHeroSkills($i)
		$triggered += 1
	Next
	Return $triggered
EndFunc


Func HanakuCanEngageHanaku($maxDistance = 2500)
	Local $hanaku = GetHanakuTarget()
	If $hanaku == Null Then Return False
	Return GetDistance(GetMyAgent(), $hanaku) <= $maxDistance
EndFunc


Func HanakuGetMorgahnIndex()
	Local $heroCount = GetHeroCount()
	If $heroCount <= 0 Then Return 0

	; Reuse cache when still valid.
	If $hanaku_morgahn_index_cache >= 1 And $hanaku_morgahn_index_cache <= $heroCount Then
		Local $cachedSlot2 = GetSkillbarSkillID(2, $hanaku_morgahn_index_cache)
		If $cachedSlot2 == $ID_INCOMING Or $cachedSlot2 == $ID_INCOMING_PVP Then Return $hanaku_morgahn_index_cache
	EndIf

	For $i = 1 To $heroCount
		Local $slot2 = GetSkillbarSkillID(2, $i)
		If $slot2 == $ID_INCOMING Or $slot2 == $ID_INCOMING_PVP Then
			$hanaku_morgahn_index_cache = $i
			Return $i
		EndIf
	Next

	; Fallback to configured index if incoming cannot be identified.
	If $HANAKU_HERO_INDEX >= 1 And $HANAKU_HERO_INDEX <= $heroCount Then
		$hanaku_morgahn_index_cache = $HANAKU_HERO_INDEX
		Return $HANAKU_HERO_INDEX
	EndIf

	Return 0
EndFunc


Func HanakuSetAllHeroesGuard()
	Local $heroCount = GetHeroCount()
	If $heroCount <= 0 Then Return
	For $i = 1 To $heroCount
		SetHeroBehaviour($i, 1)
	Next
EndFunc


Func KillHanaku()
	If IsPlayerDead() Then Return $FAIL
	HanakuFightLogWrite('kill_start')
	$hanaku_combo_state_dbg = 0
	$hanaku_chain_cv_ok_count = 0
	$hanaku_chain_reap_ok_count = 0
	$hanaku_chain_fail_count = 0
	HanakuForceScytheSet()

	If IsRecharged($HANAKU_GRENTHS_AURA) Then UseSkillEx($HANAKU_GRENTHS_AURA)
	RandomSleep(80)
	If IsRecharged($HANAKU_CRITICAL_AGILITY) Then UseSkillEx($HANAKU_CRITICAL_AGILITY)
	RandomSleep(80)
	HanakuForceScytheSet(False)

	; After teleport: only 6 and 8, then wait for one real SF->DP refresh cycle.
	Local $permaChainAtFightStart = $hanaku_perma_chain_count
	Local $damageChoreoUnlocked = False
	Local $damageUnlockTimer = TimerInit()

	Local $lastCripplingAttempt = TimerInit()
	Local $lastReapAttempt = TimerInit()
	Local $comboState = 0 ; 0 = wait/use 4, 1 = wait/use 5
	Local $nextReapEarliestMs = 0
	Local $nextReapDeadlineMs = 0
	Local $lastWeaponRefresh = TimerInit()
	Local $lastAdrenalineDiagnostic = TimerInit()
	Local $lastAdrenalineWarn = TimerInit()
	Local $lastCAMaintenanceCheck = TimerInit()

	Local $fightTimer = TimerInit()
	While IsPlayerAlive() And TimerDiff($fightTimer) < $HANAKU_FIGHT_TIMEOUT_MS
		If Not HanakuIsBossAlive() Then Return $SUCCESS
		Local $hanaku = GetHanakuTarget()
		If $hanaku == Null Then
			$hanaku = GetCurrentTarget()
			If $hanaku == Null Then
				If Not HanakuIsBossAlive() Then Return $SUCCESS
				If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) == 0 Then Return $SUCCESS
				Sleep(150)
				ContinueLoop
			EndIf
		EndIf
		If GetIsDead($hanaku) Or DllStructGetData($hanaku, 'HealthPercent') <= 0 Then Return $SUCCESS

		ChangeTarget($hanaku)
		If TimerDiff($lastWeaponRefresh) > 650 Then
			HanakuForceScytheSet(False)
			$lastWeaponRefresh = TimerInit()
		EndIf

		; Keep auto-attack active for adrenaline and critical-strike energy returns.
		Attack($hanaku)
		Local $dpAttackLockActive = HanakuIsDpAttackLockActive()
		If TimerDiff($lastAdrenalineDiagnostic) > 4000 Then
			Local $adren4 = GetSkillbarSkillAdrenaline($HANAKU_CRIPPLING_VICTORY)
			Local $adren5 = GetSkillbarSkillAdrenaline($HANAKU_REAP_IMPURITIES)
			If $adren4 < 2 Then
				If TimerDiff($lastAdrenalineWarn) > 8000 Then
					Warn('Low adrenaline detected while attacking. Re-forcing weapon set 4')
					$lastAdrenalineWarn = TimerInit()
				EndIf
				HanakuForceScytheSet(False)
			EndIf
			If $adren4 < 2 And $adren5 < 2 Then Attack($hanaku)
			HanakuFightLogWrite('adrenaline_diag', 'a4=' & $adren4 & ';a5=' & $adren5 & ';state=' & $comboState & ';dp_lock=' & $dpAttackLockActive)
			$lastAdrenalineDiagnostic = TimerInit()
		EndIf
		$hanaku_combo_state_dbg = $comboState

		HanakuFightLogHeartbeat('fight_loop', 'state=' & $comboState)
		; Keep SF/DP alive in all states; suppress utility casts while waiting for 5.
		MaintainHanakuPermaTick($comboState == 0)
		Local $reserveForSF = HanakuShouldReserveEnergyForSF()
		If Not $damageChoreoUnlocked Then
			If $hanaku_perma_chain_count > $permaChainAtFightStart Or TimerDiff($damageUnlockTimer) >= $HANAKU_DAMAGE_UNLOCK_TIMEOUT_MS Then
				$damageChoreoUnlocked = True
				HanakuFightLogWrite('damage_unlock', 'perma=' & $hanaku_perma_chain_count & ';fallback=' & (TimerDiff($damageUnlockTimer) >= $HANAKU_DAMAGE_UNLOCK_TIMEOUT_MS))
			Else
				Sleep(90)
				ContinueLoop
			EndIf
		EndIf
		If $comboState == 0 And $reserveForSF Then
			; Stop all non-critical casts shortly before SF refresh to avoid animation lock.
			HanakuFightLogHeartbeat('reserve_sf')
			Sleep(90)
			ContinueLoop
		EndIf

		If $comboState == 0 And $dpAttackLockActive Then
			HanakuFightLogHeartbeat('dp_attack_lock')
			Sleep(90)
			ContinueLoop
		EndIf

		; Maintenance spells are allowed to interrupt chain only when actually needed.
		If $comboState == 0 And IsRecharged($HANAKU_SHROUD_OF_DISTRESS) And HanakuGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP) <= 2500 Then
			UseSkillEx($HANAKU_SHROUD_OF_DISTRESS)
			HanakuFightLogWrite('sod_recast')
			Sleep(80)
			ContinueLoop
		EndIf

		Local $adren4Now = GetSkillbarSkillAdrenaline($HANAKU_CRIPPLING_VICTORY)
		Local $adren5Now = GetSkillbarSkillAdrenaline($HANAKU_REAP_IMPURITIES)

		; Strict adrenaline-driven 4 -> 5 sequence.
		If $comboState == 0 Then
			If TimerDiff($lastCripplingAttempt) > $HANAKU_CHAIN_RETRY_MS And $adren4Now >= $HANAKU_CHAIN_MIN_ADREN4 Then
				Local $cvAccepted = HanakuTryUseAdrenalineSkill($HANAKU_CRIPPLING_VICTORY, $hanaku)
				If Not $cvAccepted Then
					; One controlled retry reduces false cv_fail without allowing 5-alone paths.
					Sleep(70)
					If GetSkillbarSkillAdrenaline($HANAKU_CRIPPLING_VICTORY) >= $HANAKU_CHAIN_MIN_ADREN4 Then
						$cvAccepted = HanakuTryUseAdrenalineSkill($HANAKU_CRIPPLING_VICTORY, $hanaku)
						If $cvAccepted Then HanakuFightLogWrite('chain_cv_retry_ok', 'a4=' & $adren4Now & ';a5=' & $adren5Now)
					EndIf
				EndIf

				If $cvAccepted Then
					$hanaku_chain_cv_ok_count += 1
					$nextReapEarliestMs = TimerDiff($fightTimer) + $HANAKU_CHAIN_REAP_MIN_DELAY_MS
					$nextReapDeadlineMs = TimerDiff($fightTimer) + $HANAKU_CHAIN_REAP_WINDOW_MS
					$comboState = 1
					$hanaku_combo_state_dbg = $comboState
					HanakuFightLogWrite('chain_cv_ok', 'a4=' & $adren4Now & ';a5=' & $adren5Now)
				Else
					$hanaku_chain_fail_count += 1
					HanakuFightLogWrite('chain_cv_fail', 'a4=' & $adren4Now & ';a5=' & $adren5Now)
				EndIf
				$lastCripplingAttempt = TimerInit()
			EndIf
		Else
			Local $fightElapsedMs = TimerDiff($fightTimer)
			If $fightElapsedMs > $nextReapDeadlineMs Then
				$hanaku_chain_fail_count += 1
				HanakuFightLogWrite('chain_reap_timeout', 'a4=' & $adren4Now & ';a5=' & $adren5Now)
				$comboState = 0
				$hanaku_combo_state_dbg = $comboState
			ElseIf $fightElapsedMs < $nextReapEarliestMs Then
				; Respect 4 animation/server lock before attempting 5.
				HanakuFightLogHeartbeat('chain_wait_reap')
			ElseIf TimerDiff($lastReapAttempt) > $HANAKU_CHAIN_RETRY_MS And $adren5Now >= $HANAKU_CHAIN_MIN_ADREN5 Then
				If HanakuTryUseAdrenalineSkill($HANAKU_REAP_IMPURITIES, $hanaku) Then
					HanakuFightLogWrite('chain_reap_ok', 'a4=' & $adren4Now & ';a5=' & $adren5Now)
					$hanaku_chain_reap_ok_count += 1
					$comboState = 0
					$hanaku_combo_state_dbg = $comboState
				Else
					$hanaku_chain_fail_count += 1
					HanakuFightLogWrite('chain_reap_fail', 'a4=' & $adren4Now & ';a5=' & $adren5Now)
				EndIf
				$lastReapAttempt = TimerInit()
			EndIf
		EndIf

		If $comboState == 0 And IsRecharged($HANAKU_GRENTHS_AURA) And GetEnergy() > 24 And DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.97 Then
			UseSkillEx($HANAKU_GRENTHS_AURA)
			HanakuFightLogWrite('grenths_cast', 'hp=' & DllStructGetData(GetMyAgent(), 'HealthPercent'))
			Sleep(80)
			ContinueLoop
		EndIf

		If $comboState == 0 And TimerDiff($lastCAMaintenanceCheck) > 3500 Then
			If GetEffectTimeRemaining($ID_CRITICAL_AGILITY) <= 500 And IsRecharged($HANAKU_CRITICAL_AGILITY) And GetEnergy() > 22 Then
				UseSkillEx($HANAKU_CRITICAL_AGILITY)
				HanakuForceScytheSet(False)
			EndIf
			$lastCAMaintenanceCheck = TimerInit()
		EndIf

		Sleep(90)
	WEnd
	If IsPlayerAlive() Then Warn('Fight timeout reached (5 minutes) - aborting run and resigning')
	HanakuFightLogWrite('kill_timeout')
	Return $FAIL
EndFunc


Func HanakuForceScytheSet($withWarmup = True)
	If $withWarmup Then
		Info('Ensuring weapon set 4 (zealous scythe)')
		For $i = 1 To 3
			ChangeWeaponSet($HANAKU_WEAPON_SCYTHE)
			RandomSleep(60)
		Next
	Else
		ChangeWeaponSet($HANAKU_WEAPON_SCYTHE)
	EndIf
EndFunc


Func MaintainHanakuPermaTick($allowUtilityCasts = True)
	If IsPlayerDead() Then Return
	Local Static $sfQueueTimer = Null

	Local $sfRemaining = HanakuGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP)
	Local $sodRemaining = HanakuGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)
	Local $sfRechargedNow = IsRecharged($HANAKU_SHADOW_FORM)
	Local $energyNow = GetEnergy()

	; Single deterministic rhythm: whenever SF is ready, cast SF, wait 0.5s, then cast DP.
	; DP is never cast from any other timing anchor inside perma maintenance.
	If $sfRechargedNow And $energyNow >= $HANAKU_SF_DP_MIN_ENERGY And ($sfQueueTimer == Null Or TimerDiff($sfQueueTimer) > $HANAKU_SF_QUEUE_RETRY_MS) Then
		UseSkill($HANAKU_SHADOW_FORM)
		$sfQueueTimer = TimerInit()
		$hanaku_last_sf_request_timer = TimerInit()
		HanakuFightLogWrite('sf_request')
		Local $dpTimer = TimerInit()
		While IsPlayerAlive() And TimerDiff($dpTimer) < $HANAKU_DP_AFTER_SF_DELAY_MS
			Sleep(10)
		WEnd
		; Hard timing rule: attempt DP exactly after the fixed SF delay.
		If IsRecharged($HANAKU_DEADLY_PARADOX) Then
			UseSkill($HANAKU_DEADLY_PARADOX)
			HanakuMarkDpCast()
			Local $deltaMs = ($hanaku_last_sf_request_timer == Null) ? -1 : Int(TimerDiff($hanaku_last_sf_request_timer))
			HanakuFightLogWrite('dp_cast', 'delta_from_sf_ms=' & $deltaMs)
			$hanaku_perma_chain_count += 1
		Else
			HanakuFightLogWrite('dp_skip', 'reason=dp_not_ready;e=' & GetEnergy())
		EndIf
		Return
	EndIf

	If $sfRechargedNow And $energyNow < $HANAKU_SF_DP_MIN_ENERGY Then HanakuFightLogHeartbeat('sf_low_energy', 'e=' & $energyNow)

	If $sfRemaining > ($HANAKU_SF_CHAIN_START_MS + 2500) Then
		$sfQueueTimer = Null
	EndIf

	If $allowUtilityCasts And $sodRemaining <= 2500 And IsRecharged($HANAKU_SHROUD_OF_DISTRESS) Then UseSkillEx($HANAKU_SHROUD_OF_DISTRESS)

	If $allowUtilityCasts And Not HanakuShouldReserveEnergyForSF() And DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.90 And IsRecharged($HANAKU_GRENTHS_AURA) And GetEnergy() > 24 Then UseSkillEx($HANAKU_GRENTHS_AURA)
EndFunc


Func GetHanakuTarget()
	Local $me = GetMyAgent()
	Local $nearest = Null
	Local $nearestDistance = 100000000

	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		If DllStructGetData($agent, 'ModelID') <> $HANAKU_BOSS_MODEL_ID Then ContinueLoop
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop

		Local $distance = GetDistance($me, $agent)
		If $distance < $nearestDistance Then
			$nearestDistance = $distance
			$nearest = $agent
		EndIf
	Next
	Return $nearest
EndFunc


Func HanakuIsBossAlive()
	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		If DllStructGetData($agent, 'ModelID') <> $HANAKU_BOSS_MODEL_ID Then ContinueLoop
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		Return True
	Next
	Return False
EndFunc


Func HanakuGetBestEffectTimeRemaining($skillID1, $skillID2 = 0)
	Local $v1 = GetEffectTimeRemaining($skillID1)
	If $skillID2 == 0 Then Return $v1
	Local $v2 = GetEffectTimeRemaining($skillID2)
	Return $v2 > $v1 ? $v2 : $v1
EndFunc


Func HanakuShouldReserveEnergyForSF()
	; Reserve only when SF is ready AND immediately castable.
	; If SF is ready but energy is below budget, never stall the chain loop.
	Return IsRecharged($HANAKU_SHADOW_FORM) And GetEnergy() >= $HANAKU_SF_DP_MIN_ENERGY
EndFunc


Func HanakuTryUseAdrenalineSkill($skillSlot, $target)
	Local $beforeAdren = GetSkillbarSkillAdrenaline($skillSlot)
	Local $beforeReady = IsRecharged($skillSlot)
	Local $skillID = GetSkillbarSkillID($skillSlot)
	UseSkill($skillSlot, $target)
	; Strict confirmation: only accept if this exact slot changed state.
	; This prevents false positives from unrelated casts (SF/DP/SoD/GA/CA).
	Local $timer = TimerInit()
	Local $confirmTimeoutMs = 950
	If $skillSlot == $HANAKU_CRIPPLING_VICTORY Or $skillSlot == $HANAKU_REAP_IMPURITIES Then $confirmTimeoutMs = 1100
	Local $minAdren = $beforeAdren
	While TimerDiff($timer) < $confirmTimeoutMs
		Local $afterAdren = GetSkillbarSkillAdrenaline($skillSlot)
		If $afterAdren < $minAdren Then $minAdren = $afterAdren
		If $minAdren < $beforeAdren Then Return True
		If $beforeReady And Not IsRecharged($skillSlot) Then Return True
		If $skillID <> 0 And DllStructGetData(GetMyAgent(), 'Skill') == $skillID Then Return True
		Sleep(15)
	WEnd
	Return False
EndFunc


Func HanakuMarkDpCast()
	$hanaku_last_dp_cast_timer = TimerInit()
EndFunc


Func HanakuIsDpAttackLockActive()
	If $hanaku_last_dp_cast_timer == Null Then Return False
	Return TimerDiff($hanaku_last_dp_cast_timer) < $HANAKU_DP_ATTACK_LOCK_MS
EndFunc


Func HanakuFightLogInit()
	Local $timestamp = @YEAR & @MON & @MDAY & '_' & @HOUR & @MIN & @SEC
	$hanaku_log_file = @ScriptDir & '/logs/hanaku_fight_debug-' & GetCharacterName() & '-run' & $hanaku_log_run_number & '-' & $timestamp & '.csv'
	$hanaku_log_handle = FileOpen($hanaku_log_file, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	$hanaku_log_timer = TimerInit()
	$hanaku_log_heartbeat_timer = TimerInit()
	Info('Hanaku CSV: ' & $hanaku_log_file)
	If $hanaku_log_handle == -1 Then Return
	FileWriteLine($hanaku_log_handle, 'time_ms;run;event;energy;hp;map_id;sf_ms;sod_ms;a4;a5;sf_ready;dp_ready;sod_ready;ga_ready;ca_ready;sf_req_ms;dp_lock_ms;combo_state;cv_ok;reap_ok;chain_fail;target_hp;target_dist;x;y;note')
EndFunc


Func HanakuFightLogClose()
	If $hanaku_log_handle == -1 Then Return
	FileClose($hanaku_log_handle)
	$hanaku_log_handle = -1
EndFunc


Func HanakuFightLogHeartbeat($eventName, $note = '')
	If TimerDiff($hanaku_log_heartbeat_timer) < $HANAKU_FIGHT_LOG_HEARTBEAT_MS Then Return
	HanakuFightLogWrite($eventName, $note)
	$hanaku_log_heartbeat_timer = TimerInit()
EndFunc


Func HanakuFightLogWrite($eventName, $note = '')
	If $hanaku_log_handle == -1 Then Return
	Local $timeMs = Int(TimerDiff($hanaku_log_timer))
	Local $me = GetMyAgent()
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')
	Local $energy = GetEnergy()
	Local $hp = DllStructGetData($me, 'HealthPercent')
	Local $mapID = GetMapID()
	Local $sfRemaining = HanakuGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP)
	Local $sodRemaining = HanakuGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)
	Local $a4 = GetSkillbarSkillAdrenaline($HANAKU_CRIPPLING_VICTORY)
	Local $a5 = GetSkillbarSkillAdrenaline($HANAKU_REAP_IMPURITIES)
	Local $sfReady = IsRecharged($HANAKU_SHADOW_FORM)
	Local $dpReady = IsRecharged($HANAKU_DEADLY_PARADOX)
	Local $sodReady = IsRecharged($HANAKU_SHROUD_OF_DISTRESS)
	Local $gaReady = IsRecharged($HANAKU_GRENTHS_AURA)
	Local $caReady = IsRecharged($HANAKU_CRITICAL_AGILITY)
	Local $sfReqMs = -1
	If $hanaku_last_sf_request_timer <> Null Then $sfReqMs = Int(TimerDiff($hanaku_last_sf_request_timer))
	Local $dpLockMs = -1
	If $hanaku_last_dp_cast_timer <> Null Then $dpLockMs = Int(TimerDiff($hanaku_last_dp_cast_timer))

	Local $target = GetHanakuTarget()
	If $target == Null Then $target = GetCurrentTarget()
	Local $targetHp = -1
	Local $targetDist = -1
	If $target <> Null Then
		$targetHp = DllStructGetData($target, 'HealthPercent')
		$targetDist = Int(GetDistance($me, $target))
	EndIf

	Local $safeNote = StringReplace($note, ';', ',')
	FileWriteLine($hanaku_log_handle, $timeMs & ';' & $hanaku_log_run_number & ';' & $eventName & ';' & $energy & ';' & $hp & ';' & $mapID & ';' & $sfRemaining & ';' & $sodRemaining & ';' & $a4 & ';' & $a5 & ';' & $sfReady & ';' & $dpReady & ';' & $sodReady & ';' & $gaReady & ';' & $caReady & ';' & $sfReqMs & ';' & $dpLockMs & ';' & $hanaku_combo_state_dbg & ';' & $hanaku_chain_cv_ok_count & ';' & $hanaku_chain_reap_ok_count & ';' & $hanaku_chain_fail_count & ';' & $targetHp & ';' & $targetDist & ';' & $x & ';' & $y & ';' & $safeNote)
EndFunc


Func EnsureHanakuHeroPresent()
	If GetHeroID($HANAKU_HERO_INDEX) <> 0 Then Return $SUCCESS
	Warn('Hero slot 1 missing, re-adding Morgahn for this run')
	AddHero($ID_GENERAL_MORGAHN)
	RandomSleep(350)
	Return GetHeroID($HANAKU_HERO_INDEX) == 0 ? $FAIL : $SUCCESS
EndFunc
