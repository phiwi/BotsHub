#CS ===========================================================================
; Author: GitHub Copilot (based on Brightclaw pattern by caustic-kronos)
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
Global Const $WINGSTORM_PLAYER_SKILLBAR = 'OwhiAyiMVNdNVO5D+Nd2ABtCCA'
Global Const $WINGSTORM_RUN_TIMEOUT_MS = 5 * 60 * 1000
Global Const $WINGSTORM_SKIP_PLAYER_BUILD_SETUP_DEBUG = False
Global Const $WINGSTORM_SKIP_TEAM_SETUP_DEBUG = False
Global Const $WINGSTORM_WEAPON_SET_RUNNER = 3

; Hanaku-aligned team templates
Global Const $WINGSTORM_HERO_MORGAHN_SKILLBAR = 'OQijEqmMKODbe8OmEbi7x3YWMA'
Global Const $WINGSTORM_HERO_MOW_SKILLBAR = 'OAlkUwG4RZmUMjC4OWN2uzWYVgdA'
Global Const $WINGSTORM_HERO_OLIAS_SKILLBAR = 'OAlkUwG4RZmUMjC4OWNWC4WIegdA'
Global Const $WINGSTORM_HERO_DUNKORO_SKILLBAR = 'OwhiAyiMVNdNVO5D+Nd2ABtCCA'
Global Const $WINGSTORM_HERO_NORGU_SKILLBAR = 'OQREAsIjU8MV5aI/dwPgnWFQDA'
Global Const $WINGSTORM_HERO_RAZAH_SKILLBAR = 'OQREAsIjU8MV5aI/ewPgnWFQDA'
Global Const $WINGSTORM_HERO_GWEN_SKILLBAR = 'OQhjAwBc4QkA5ZIg3ATAcQFVXMA'

; Recorder map IDs: outpost=222, explo=195
Global Const $WINGSTORM_OUTPOST_ID = $ID_THE_ETERNAL_GROVE ; 222
Global Const $WINGSTORM_EXPLO_ID = $ID_DRAZACH_THICKET ; 195
Global Const $WINGSTORM_BOSS_MODEL_ID = 3714

Global Const $WINGSTORM_HERO_PARTY_ID = $ID_GENERAL_MORGAHN
Global Const $WINGSTORM_HERO_INDEX = 1

; Hero skills on WINGSTORM_HERO_SKILLBAR
Global Const $WINGSTORM_HERO_SPEED_1 = 1
Global Const $WINGSTORM_HERO_SPEED_2 = 2

; Player skill slots (Sin spirit build)
Global Const $WING_PAINFUL_BOND = 1
Global Const $WING_SOS = 2
Global Const $WING_BLOODSONG = 3
Global Const $WING_VAMPIRISM = 4
Global Const $WING_PAIN = 5
Global Const $WING_SHADOWSONG = 6
Global Const $WING_SPIRIT_WALK = 7
Global Const $WING_SHADOW_SANCTUARY = 8

Global Const $WING_PAINFUL_BOND_MIN_ENERGY = 15

; Recorded routing points
Global Const $WING_OUTPOST_PORTAL_X = -6250
Global Const $WING_OUTPOST_PORTAL_Y = 14370
; From 2026-04-16 22:37 recording with HERO_POS telemetry:
; heroes engage around ~(-53xx, -105xx), while Sin waits around ~(-7200, -12464)
Global Const $WING_GROUP_HERO_POST_X = -5330
Global Const $WING_GROUP_HERO_POST_Y = -10520
Global Const $WING_GROUP_WAIT_X = -7350
Global Const $WING_GROUP_WAIT_Y = -12600
; Keep heroes fully out of leash by posting them back near the explorable start area.
Global Const $WING_HERO_SAFE_X = -3904
Global Const $WING_HERO_SAFE_Y = -16110
Global Const $WING_SPIRIT_SETUP_X = -5634
Global Const $WING_SPIRIT_SETUP_Y = -9844
; Slightly right-shifted pull line to reduce accidental aggro when Bezzr patrols closer.
Global Const $WING_PULL_CAST_X = -5815
Global Const $WING_PULL_CAST_Y = -9590
Global Const $WING_BEHIND_SPIRITS_X = -5560
Global Const $WING_BEHIND_SPIRITS_Y = -9960
Global Const $WING_RETREAT_BEHIND_SPIRITS_DISTANCE = 650

Global Const $WING_GROUP_CLEAR_TIMEOUT_MS = 95000
Global Const $WING_BOSS_FIGHT_TIMEOUT_MS = 90000

Global $wingstorm_farm_setup = False
Global $wingstorm_last_boss_death_x = 0
Global $wingstorm_last_boss_death_y = 0


Func WingstormFarm()
	If Not $wingstorm_farm_setup And SetupWingstormFarm() == $FAIL Then Return $PAUSE
	If GoToWingstormMap() == $FAIL Then Return $FAIL

	Local $result = WingstormFarmLoop()
	If $result == $PAUSE Then Return $PAUSE
	ResignAndReturnToOutpost($WINGSTORM_OUTPOST_ID)
	Return $result
EndFunc


Func SetupWingstormFarm()
	Info('Setting up Wingstorm farm')
	If TravelToOutpost($WINGSTORM_OUTPOST_ID, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)

	If SetupPlayerWingstormFarm() == $FAIL Then Return $FAIL
	If SetupTeamWingstormFarm() == $FAIL Then Return $FAIL
	ChangeWeaponSet($WINGSTORM_WEAPON_SET_RUNNER)
	RandomSleep(200)

	$wingstorm_farm_setup = True
	Info('Wingstorm preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerWingstormFarm()
	If $WINGSTORM_SKIP_PLAYER_BUILD_SETUP_DEBUG Then
		Info('Debug mode: skipping player build setup (template load)')
		Return $SUCCESS
	EndIf

	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
		If HeroHasTemplate(0, $WINGSTORM_PLAYER_SKILLBAR) Then
			Info('Wingstorm player: template already loaded, skipping')
		Else
			LoadSkillTemplate($WINGSTORM_PLAYER_SKILLBAR)
		EndIf
	Else
		Warn('Should run this farm as assassin')
		Return $FAIL
	EndIf
	RandomSleep(250)
	Return $SUCCESS
EndFunc


Func SetupTeamWingstormFarm()
	If $WINGSTORM_SKIP_TEAM_SETUP_DEBUG Then
		If GetPartySize() < 8 Then
			Warn('Wingstorm debug expects full party (you + 7 heroes). Current size: ' & GetPartySize())
			Return $FAIL
		EndIf
		; Ensure no stale hero flags from previous runs interfere with current post commands.
		ClearPartyCommands()
		CancelAllHeroes()
		Info('Debug mode: skipping team setup and using existing 7-hero party')
		Return $SUCCESS
	EndIf

	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up fixed hero team (Hanaku variant): Morgahn, Master of Whispers, Olias, Dunkoro, Norgu, Razah, Gwen')
	If WingstormEnsureSoloParty() == $FAIL Then
		Warn('Could not reset to solo party before Wingstorm hero setup')
		Return $FAIL
	EndIf

	If WingstormTryAddHero($ID_GENERAL_MORGAHN, 'Morgahn', 2) == $FAIL _
		Or WingstormTryAddHero($ID_MASTER_OF_WHISPERS, 'Master of Whispers', 3) == $FAIL _
		Or WingstormTryAddHero($ID_OLIAS, 'Olias', 4) == $FAIL _
		Or WingstormTryAddHero($ID_DUNKORO, 'Dunkoro', 5) == $FAIL _
		Or WingstormTryAddHero($ID_NORGU, 'Norgu', 6) == $FAIL _
		Or WingstormTryAddHero($ID_RAZAH, 'Razah', 7) == $FAIL _
		Or WingstormTryAddHero($ID_GWEN, 'Gwen', 8) == $FAIL Then
		Warn('First Wingstorm hero assembly attempt failed; retrying after solo reset')
		If WingstormEnsureSoloParty() == $FAIL Then
			Warn('Could not reset to solo party for Wingstorm retry')
			Return $FAIL
		EndIf

		If WingstormTryAddHero($ID_GENERAL_MORGAHN, 'Morgahn', 2) == $FAIL _
			Or WingstormTryAddHero($ID_MASTER_OF_WHISPERS, 'Master of Whispers', 3) == $FAIL _
			Or WingstormTryAddHero($ID_OLIAS, 'Olias', 4) == $FAIL _
			Or WingstormTryAddHero($ID_DUNKORO, 'Dunkoro', 5) == $FAIL _
			Or WingstormTryAddHero($ID_NORGU, 'Norgu', 6) == $FAIL _
			Or WingstormTryAddHero($ID_RAZAH, 'Razah', 7) == $FAIL _
			Or WingstormTryAddHero($ID_GWEN, 'Gwen', 8) == $FAIL Then
			Warn('Second Wingstorm hero assembly attempt failed')
			Return $FAIL
		EndIf
	EndIf

	If GetPartySize() <> 8 Then
		Warn('Could not set up Wingstorm party correctly. Team size different than 8')
		Return $FAIL
	EndIf

	If GetHeroNumberByHeroID($ID_GENERAL_MORGAHN) <> 1 Then
		Warn('Wingstorm party order mismatch: Morgahn expected slot 1, got ' & GetHeroNumberByHeroID($ID_GENERAL_MORGAHN))
		Return $FAIL
	EndIf
	If GetHeroNumberByHeroID($ID_MASTER_OF_WHISPERS) <> 2 Then
		Warn('Wingstorm party order mismatch: Master of Whispers expected slot 2, got ' & GetHeroNumberByHeroID($ID_MASTER_OF_WHISPERS))
		Return $FAIL
	EndIf
	If GetHeroNumberByHeroID($ID_OLIAS) <> 3 Then
		Warn('Wingstorm party order mismatch: Olias expected slot 3, got ' & GetHeroNumberByHeroID($ID_OLIAS))
		Return $FAIL
	EndIf
	If GetHeroNumberByHeroID($ID_DUNKORO) <> 4 Then
		Warn('Wingstorm party order mismatch: Dunkoro expected slot 4, got ' & GetHeroNumberByHeroID($ID_DUNKORO))
		Return $FAIL
	EndIf
	If GetHeroNumberByHeroID($ID_NORGU) <> 5 Then
		Warn('Wingstorm party order mismatch: Norgu expected slot 5, got ' & GetHeroNumberByHeroID($ID_NORGU))
		Return $FAIL
	EndIf
	If GetHeroNumberByHeroID($ID_RAZAH) <> 6 Then
		Warn('Wingstorm party order mismatch: Razah expected slot 6, got ' & GetHeroNumberByHeroID($ID_RAZAH))
		Return $FAIL
	EndIf
	If GetHeroNumberByHeroID($ID_GWEN) <> 7 Then
		Warn('Wingstorm party order mismatch: Gwen expected slot 7, got ' & GetHeroNumberByHeroID($ID_GWEN))
		Return $FAIL
	EndIf

	If HeroHasTemplate(1, $WINGSTORM_HERO_MORGAHN_SKILLBAR) Then
		Info('Wingstorm Morgahn: template already loaded, skipping')
	Else
		LoadSkillTemplate($WINGSTORM_HERO_MORGAHN_SKILLBAR, 1)
	EndIf
	RandomSleep(150)
	If HeroHasTemplate(2, $WINGSTORM_HERO_MOW_SKILLBAR) Then
		Info('Wingstorm MoW: template already loaded, skipping')
	Else
		LoadSkillTemplate($WINGSTORM_HERO_MOW_SKILLBAR, 2)
	EndIf
	RandomSleep(150)
	If HeroHasTemplate(3, $WINGSTORM_HERO_OLIAS_SKILLBAR) Then
		Info('Wingstorm Olias: template already loaded, skipping')
	Else
		LoadSkillTemplate($WINGSTORM_HERO_OLIAS_SKILLBAR, 3)
	EndIf
	RandomSleep(150)
	If HeroHasTemplate(4, $WINGSTORM_HERO_DUNKORO_SKILLBAR) Then
		Info('Wingstorm Dunkoro: template already loaded, skipping')
	Else
		LoadSkillTemplate($WINGSTORM_HERO_DUNKORO_SKILLBAR, 4)
	EndIf
	RandomSleep(150)
	If HeroHasTemplate(5, $WINGSTORM_HERO_NORGU_SKILLBAR) Then
		Info('Wingstorm Norgu: template already loaded, skipping')
	Else
		LoadSkillTemplate($WINGSTORM_HERO_NORGU_SKILLBAR, 5)
	EndIf
	RandomSleep(150)
	If HeroHasTemplate(6, $WINGSTORM_HERO_RAZAH_SKILLBAR) Then
		Info('Wingstorm Razah: template already loaded, skipping')
	Else
		LoadSkillTemplate($WINGSTORM_HERO_RAZAH_SKILLBAR, 6)
	EndIf
	RandomSleep(150)
	If HeroHasTemplate(7, $WINGSTORM_HERO_GWEN_SKILLBAR) Then
		Info('Wingstorm Gwen: template already loaded, skipping')
	Else
		LoadSkillTemplate($WINGSTORM_HERO_GWEN_SKILLBAR, 7)
	EndIf
	RandomSleep(250)

	ClearPartyCommands()
	CancelAllHeroes()
	Return $SUCCESS
EndFunc


Func WingstormEnsureSoloParty($maxWaitMs = 9000)
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
	Warn('Wingstorm: party reset timeout. Party=' & GetPartySize() & ', heroes=' & GetHeroCount())
	Return $FAIL
EndFunc


Func WingstormTryAddHero($heroID, $heroName, $expectedSize)
	For $i = 1 To 6
		If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
		AddHero($heroID)
		RandomSleep(350)
		If GetPartySize() >= $expectedSize Then Return $SUCCESS
	Next
	Warn('Could not add hero ' & $heroName & ' (party=' & GetPartySize() & ')')
	Return $FAIL
EndFunc


Func GoToWingstormMap()
	TravelToOutpost($WINGSTORM_OUTPOST_ID, $district_name)
	While GetMapID() <> $WINGSTORM_EXPLO_ID
		Info('Moving to Drazach Thicket')
		If WingstormMoveToPointRobust(-4045, 13404, 260, 12000, 'to first outpost waypoint') == $FAIL Then Return $FAIL

		If WingstormMoveToPointRobust(-5113, 13949, 260, 12000, 'to second outpost waypoint') == $FAIL Then Return $FAIL

		If WingstormMoveToPointRobust($WING_OUTPOST_PORTAL_X, $WING_OUTPOST_PORTAL_Y, 260, 12000, 'to Drazach portal') == $FAIL Then Return $FAIL

		Move(-6400, 14500)
		If Not WaitMapLoading($WINGSTORM_EXPLO_ID, 15000, 1000) Then
			Warn('Failed zoning into Drazach Thicket (map load timeout)')
			Return $FAIL
		EndIf
	WEnd
	Return $SUCCESS
EndFunc


Func WingstormMoveToPointRobust($x, $y, $range, $timeout, $stepLabel = '')
	Local $timer = TimerInit()
	Local $reissueTimer = TimerInit()
	MoveTo($x, $y, 25, 0)

	While GetDistanceToPoint(GetMyAgent(), $x, $y) > $range
		If IsPlayerDead() Then Return $FAIL
		If TimerDiff($timer) > $timeout Then
			Warn('Move timeout ' & $stepLabel & ' at (' & $x & ', ' & $y & ')')
			Return $FAIL
		EndIf

		If TimerDiff($reissueTimer) > 3500 Then
			MoveTo($x, $y, 25, 0)
			$reissueTimer = TimerInit()
		EndIf

		Sleep(200)
	WEnd

	Return $SUCCESS
EndFunc


Func WingstormFarmLoop()
	If GetMapID() <> $WINGSTORM_EXPLO_ID Then Return $FAIL
	ChangeWeaponSet($WINGSTORM_WEAPON_SET_RUNNER)

	Local $runTimer = TimerInit()
	If FollowPathToGroupHold() == $FAIL Then Return $FAIL
	If ClearGroupsThenParkHeroes() == $FAIL Then Return $FAIL
	If SetupAndKillWingstorm() == $FAIL Then Return $FAIL
	If LootWingstormFast() == $FAIL Then Return $FAIL
	If TimerDiff($runTimer) > $WINGSTORM_RUN_TIMEOUT_MS Then
		Warn('Wingstorm run timed out')
		Return $FAIL
	EndIf

	Return $SUCCESS
EndFunc


Func FollowPathToGroupHold()
	Local $path[10][2] = [ _
		[-3904, -16110], [-5009, -15721], [-6248, -15549], [-7478, -15357], _
		[-8317, -15082], [-8598, -14207], [-8429, -13705], [-7939, -13213], _
		[-7538, -12820], [$WING_GROUP_WAIT_X, $WING_GROUP_WAIT_Y] _
	]

	Local $heroRetreated = False
	Local $midPointIndex = 6

	WingstormInitializeHeroSpeedSupport()

	For $i = 0 To UBound($path) - 1
		If IsPlayerDead() Then Return $FAIL
		MoveTo($path[$i][0], $path[$i][1], 25, 0)

		Local $waypointTimer = TimerInit()
		While GetDistanceToPoint(GetMyAgent(), $path[$i][0], $path[$i][1]) > 360
			If IsPlayerDead() Then Return $FAIL

			If TimerDiff($waypointTimer) > 10000 Then
				MoveTo($path[$i][0], $path[$i][1], 25, 0)
				$waypointTimer = TimerInit()
			EndIf

			Sleep(250)
		WEnd

		If Not $heroRetreated And $i >= $midPointIndex Then
			Info('Path midpoint reached. Morgahn casts speed')
			UseHeroSkill($WINGSTORM_HERO_INDEX, $WINGSTORM_HERO_SPEED_2, GetMyAgent())
			RandomSleep(200)
			$heroRetreated = True
		EndIf
	Next

	If WingstormWaitForPlayerNearPoint($WING_GROUP_WAIT_X, $WING_GROUP_WAIT_Y, 180, 9000) == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func WingstormInitializeHeroSpeedSupport()
	CancelHero($WINGSTORM_HERO_INDEX)
	RandomSleep(250)
	UseHeroSkill($WINGSTORM_HERO_INDEX, $WINGSTORM_HERO_SPEED_1, GetMyAgent())
	RandomSleep(250)
	UseHeroSkill($WINGSTORM_HERO_INDEX, $WINGSTORM_HERO_SPEED_2, GetMyAgent())
EndFunc


Func ClearGroupsThenParkHeroes()
	Info('Posting heroes between both groups at (' & $WING_GROUP_HERO_POST_X & ', ' & $WING_GROUP_HERO_POST_Y & ')')
	WingstormSetAllHeroesFlag($WING_GROUP_HERO_POST_X, $WING_GROUP_HERO_POST_Y)
	RandomSleep(300)

	; Keep Sin on dedicated wait spot while heroes clear both groups.
	If WingstormWaitForPlayerNearPoint($WING_GROUP_WAIT_X, $WING_GROUP_WAIT_Y, 180, 4000) == $FAIL Then
		MoveTo($WING_GROUP_WAIT_X, $WING_GROUP_WAIT_Y, 20, 0)
		If WingstormWaitForPlayerNearPoint($WING_GROUP_WAIT_X, $WING_GROUP_WAIT_Y, 180, 9000) == $FAIL Then Return $FAIL
	EndIf

	If WaitForGroupClearOrWingstormNearest($WING_GROUP_CLEAR_TIMEOUT_MS) == $FAIL Then
		Warn('Group clear failed or timed out')
		Return $FAIL
	EndIf

	Info('Groups done. Parking hero out of leash range')
	WingstormSetAllHeroesFlag($WING_HERO_SAFE_X, $WING_HERO_SAFE_Y)
	RandomSleep(300)
	Return $SUCCESS
EndFunc


Func WaitForGroupClearOrWingstormNearest($timeoutMs)
	Local $timer = TimerInit()
	Local $wingstormSeenCount = 0
	Local $clearStableCount = 0
	Local $combatSeen = False
	Local $minWaitMs = 12000
	Local $lastProgressLog = TimerInit()

	While TimerDiff($timer) < $timeoutMs And IsPlayerAlive()
		Local $heroesInCombat = WingstormAnyHeroNearEnemy(1400)
		If $heroesInCombat Then
			$combatSeen = True
			$clearStableCount = 0
		Else
			$clearStableCount += 1
		EndIf

		Local $nearest = GetNearestEnemyToAgent(GetMyAgent(), 2200)
		If $nearest <> Null Then
			Local $modelID = DllStructGetData($nearest, 'ModelID')
			If $modelID == $WINGSTORM_BOSS_MODEL_ID Then
				$wingstormSeenCount += 1
			Else
				$wingstormSeenCount = 0
			EndIf
		Else
			$wingstormSeenCount = 0
		EndIf

		If TimerDiff($timer) >= $minWaitMs Then
			If $wingstormSeenCount >= 4 Then
				Info('Nearest enemy is Wingstorm. Group clear phase complete')
				Return $SUCCESS
			EndIf
			If $clearStableCount >= 8 Then
				Info('Hero-side combat quiet for stable window. Group clear phase complete')
				Return $SUCCESS
			EndIf
		EndIf

		If TimerDiff($lastProgressLog) > 5000 Then
			Info('Waiting group clear: heroCombat=' & $heroesInCombat & ', calmTicks=' & $clearStableCount & ', wingstormTicks=' & $wingstormSeenCount & ', combatSeen=' & $combatSeen)
			$lastProgressLog = TimerInit()
		EndIf

		Sleep(500)
	WEnd

	Return $FAIL
EndFunc


Func WingstormSetAllHeroesFlag($x, $y)
	ClearPartyCommands()
	CancelAllHeroes()
	RandomSleep(100)
	CommandAll($x, $y)
EndFunc


Func WingstormAnyHeroNearEnemy($range)
	Local $heroCount = GetHeroCount()
	For $heroIndex = 1 To $heroCount
		Local $heroID = GetHeroID($heroIndex)
		If $heroID == 0 Then ContinueLoop

		Local $hero = GetAgentByID($heroID)
		If $hero == Null Then ContinueLoop
		If GetIsDead($hero) Or DllStructGetData($hero, 'HealthPercent') <= 0 Then ContinueLoop

		Local $nearEnemy = GetNearestEnemyToAgent($hero, $range)
		If $nearEnemy <> Null Then Return True
	Next
	Return False
EndFunc


Func SetupAndKillWingstorm()
	Info('Running to spirit setup point')
	MoveTo($WING_SPIRIT_SETUP_X, $WING_SPIRIT_SETUP_Y, 20, 0)
	If WingstormWaitForPlayerNearPoint($WING_SPIRIT_SETUP_X, $WING_SPIRIT_SETUP_Y, 260, 12000) == $FAIL Then Return $FAIL

	Info('Setting up spirits and Shadowsong')
	UseSkillEx($WING_BLOODSONG)
	UseSkillEx($WING_VAMPIRISM)
	UseSkillEx($WING_PAIN)
	UseSkillEx($WING_SOS)
	UseSkillEx($WING_SHADOWSONG)

	Info('Moving to pull/cast point')
	MoveTo($WING_PULL_CAST_X, $WING_PULL_CAST_Y, 20, 0)
	If WingstormWaitForPlayerNearPoint($WING_PULL_CAST_X, $WING_PULL_CAST_Y, 260, 6000) == $FAIL Then Return $FAIL

	Local $boss = WingstormWaitForBossInRange($RANGE_SPELLCAST + 120, 15000)
	If $boss == Null Then
		Warn('Wingstorm not in range for Painful Bond opener')
		Return $FAIL
	EndIf

	$boss = WingstormOpenWithPainfulBond(12000)
	If $boss == Null Then
		Warn('Could not land Painful Bond opener on Wingstorm')
		Return $FAIL
	EndIf
	Info('Painful Bond opener confirmed on Wingstorm')

	WingstormExecutePostPBDefense($boss)

	Local $fightTimer = TimerInit()
	Local $lastBondTry = TimerInit()
	While IsPlayerAlive() And TimerDiff($fightTimer) < $WING_BOSS_FIGHT_TIMEOUT_MS
		$boss = WingstormGetBossByModelID($WINGSTORM_BOSS_MODEL_ID)
		If $boss == Null Then
			If WingstormIsBossConfirmedDead(2500) Then Return $SUCCESS
			Sleep(200)
			ContinueLoop
		EndIf

		If GetIsDead($boss) Or DllStructGetData($boss, 'HealthPercent') <= 0 Then
			$wingstorm_last_boss_death_x = DllStructGetData($boss, 'X')
			$wingstorm_last_boss_death_y = DllStructGetData($boss, 'Y')
			Return $SUCCESS
		EndIf

		If TimerDiff($lastBondTry) > 1800 Then
			Local $distance = GetDistance(GetMyAgent(), $boss)
			; Do not step out from spirit wall: only recast from current safe range.
			If $distance <= ($RANGE_SPELLCAST + 60) Then
				WingstormTryManualLikeSkillCastStrict($WING_PAINFUL_BOND, $boss, 1)
			EndIf
			$lastBondTry = TimerInit()
		EndIf
		Sleep(300)
	WEnd

	Warn('Wingstorm fight timed out')
	Return $FAIL
EndFunc


Func WingstormExecutePostPBDefense($boss)
	Local $returnTarget = WingstormGetBestReturnSpirit($boss)
	If $returnTarget <> Null Then
		Local $rID = DllStructGetData($returnTarget, 'ID')
		Local $rModel = DllStructGetData($returnTarget, 'ModelID')
		Local $rAlleg = DllStructGetData($returnTarget, 'Allegiance')
		Local $rOwner = DllStructGetData($returnTarget, 'Owner')
		Local $myID = DllStructGetData(GetMyAgent(), 'ID')
		Local $slot7SkillID = GetSkillbarSkillID($WING_SPIRIT_WALK)
		Info('Spirit Walk target selected: id=' & $rID & ', model=' & $rModel & ', alleg=' & $rAlleg & ', owner=' & $rOwner & ', myID=' & $myID)
		Info('Slot 7 skill id=' & $slot7SkillID & ' (expected Spirit Walk=' & $ID_SPIRIT_WALK & ')')
		If WingstormTrySpiritWalkShadowStep($returnTarget, 3, 80) Then
			Info('Spirit Walk cast to rear spirit')
		Else
			Info('Spirit Walk shadow-step not confirmed (no movement), continuing with fallback retreat')
		EndIf
	Else
		Info('No suitable rear spirit for Spirit Walk, using direct retreat')
	EndIf

	If IsRecharged($WING_SHADOW_SANCTUARY) Then
		UseSkillEx($WING_SHADOW_SANCTUARY)
		Sleep(250)
	EndIf

	; Requested: retreat farther than before after PB defense sequence.
	WingstormRetreatBehindSpiritsFromBoss($boss, 2.0)
EndFunc


Func WingstormOpenWithPainfulBond($windowMs = 12000)
	Local $timer = TimerInit()
	Local $lastLogTick = TimerInit()
	Local $pbSkillID = GetSkillbarSkillID($WING_PAINFUL_BOND)
	Local $pbEnergyCost = WingstormGetSkillEnergyCost($WING_PAINFUL_BOND)

	While IsPlayerAlive() And TimerDiff($timer) < $windowMs
		Local $boss = WingstormGetBossByModelID($WINGSTORM_BOSS_MODEL_ID)
		If $boss == Null Then
			Sleep(150)
			ContinueLoop
		EndIf

		; Manual-like behavior: keep target locked and press PB; GW handles auto-approach into cast range.
		Attack($boss)
		If IsRecharged($WING_PAINFUL_BOND) And GetEnergy() >= $pbEnergyCost Then
			UseSkill($WING_PAINFUL_BOND, $boss)
		EndIf

		; Confirm success as soon as recharge flips or cast animation starts with PB.
		Local $confirmTimer = TimerInit()
		While TimerDiff($confirmTimer) < 700
			Local $me = GetMyAgent()
			If Not IsRecharged($WING_PAINFUL_BOND) Then Return $boss
			If IsCasting($me) Then
				Local $activeSkill = DllStructGetData($me, 'Skill')
				If $activeSkill == $pbSkillID Or $activeSkill == 0 Then Return $boss
			EndIf
			Sleep(70)
		WEnd

		If TimerDiff($lastLogTick) > 1500 Then
			Info('Trying Painful Bond opener: dist=' & Int(GetDistance(GetMyAgent(), $boss)) & ', recharged=' & IsRecharged($WING_PAINFUL_BOND))
			$lastLogTick = TimerInit()
		EndIf

		Sleep(120)
	WEnd

	Return Null
EndFunc


Func WingstormRetreatBehindSpiritsFromBoss($boss, $distanceMultiplier = 1.0)
	Info('Retreating behind spirits and waiting for kill')
	If $boss <> Null Then
		Local $me = GetMyAgent()
		Local $mx = DllStructGetData($me, 'X')
		Local $my = DllStructGetData($me, 'Y')
		Local $bx = DllStructGetData($boss, 'X')
		Local $by = DllStructGetData($boss, 'Y')

		Local $dx = $mx - $bx
		Local $dy = $my - $by
		Local $length = Sqrt($dx * $dx + $dy * $dy)
		If $length > 0 Then
			Local $distance = $WING_RETREAT_BEHIND_SPIRITS_DISTANCE * $distanceMultiplier
			Local $targetX = $mx + ($dx / $length) * $distance
			Local $targetY = $my + ($dy / $length) * $distance
			MoveTo($targetX, $targetY, 20, 0)
			If WingstormWaitForPlayerNearPoint($targetX, $targetY, 220, 6000) == $SUCCESS Then Return
		EndIf
	EndIf

	; Fallback for edge cases where boss snapshot is missing.
	MoveTo($WING_BEHIND_SPIRITS_X, $WING_BEHIND_SPIRITS_Y, 20, 0)
	WingstormWaitForPlayerNearPoint($WING_BEHIND_SPIRITS_X, $WING_BEHIND_SPIRITS_Y, 260, 6000)
EndFunc


Func WingstormGetBestReturnSpirit($boss)
	Local $me = GetMyAgent()
	If $me == Null Then Return Null

	Local $myID = DllStructGetData($me, 'ID')
	Local $mx = DllStructGetData($me, 'X')
	Local $my = DllStructGetData($me, 'Y')
	Local $dx = 1
	Local $dy = 0

	If $boss <> Null Then
		$dx = $mx - DllStructGetData($boss, 'X')
		$dy = $my - DllStructGetData($boss, 'Y')
	EndIf

	Local $dirLen = Sqrt($dx * $dx + $dy * $dy)
	If $dirLen == 0 Then Return Null

	Local $bestSpirit = Null
	Local $bestScore = -1000000

	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_SPIRIT Then ContinueLoop
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop

		Local $sx = DllStructGetData($agent, 'X')
		Local $sy = DllStructGetData($agent, 'Y')
		Local $dist = GetDistanceToPoint($me, $sx, $sy)
		; Spirit Walk should happen immediately after PB; skip far spirits that are likely invalid here.
		If $dist > ($RANGE_SPELLCAST + 220) Then ContinueLoop

		Local $vx = $sx - $mx
		Local $vy = $sy - $my
		; Score by projection in retreat direction: higher means "more behind us" relative to boss.
		Local $score = ($vx * $dx + $vy * $dy) / $dirLen

		; Strongly prefer own spirits for Spirit Walk validity.
		If DllStructGetData($agent, 'Owner') == $myID Then $score += 10000

		If $score > $bestScore Then
			$bestScore = $score
			$bestSpirit = $agent
		EndIf
	Next

	Return $bestSpirit
EndFunc


Func WingstormTryCastByRechargeTransition($skillSlot, $target, $attempts = 3)
	If $target == Null Then Return False
	Local $requiredEnergy = WingstormGetSkillEnergyCost($skillSlot)

	For $i = 1 To $attempts
		If IsPlayerDead() Then Return False
		If Not IsRecharged($skillSlot) Then
			Sleep(120)
			ContinueLoop
		EndIf
		If GetEnergy() < $requiredEnergy Then
			Sleep(120)
			ContinueLoop
		EndIf

		UseSkill($skillSlot, $target)
		Sleep(150)
		If Not IsRecharged($skillSlot) Then Return True
		If IsCasting(GetMyAgent()) Then Return True
	Next

	Return False
EndFunc


Func WingstormTrySpiritWalkShadowStep($target, $attempts = 3, $minMoveDist = 80)
	If $target == Null Then Return False
	Local $requiredEnergy = WingstormGetSkillEnergyCost($WING_SPIRIT_WALK)
	Local $targetID = DllStructGetData($target, 'ID')

	For $i = 1 To $attempts
		If IsPlayerDead() Then Return False
		If Not IsRecharged($WING_SPIRIT_WALK) Then
			Sleep(120)
			ContinueLoop
		EndIf
		If GetEnergy() < $requiredEnergy Then
			Sleep(120)
			ContinueLoop
		EndIf

		Local $meBefore = GetMyAgent()
		Local $beforeX = Int(DllStructGetData($meBefore, 'X'))
		Local $beforeY = Int(DllStructGetData($meBefore, 'Y'))

		ChangeTarget($target)
		Sleep(90)
		Local $currentTarget = GetCurrentTarget()
		Local $currentTargetID = 0
		If $currentTarget <> Null Then $currentTargetID = DllStructGetData($currentTarget, 'ID')
		Info('Spirit Walk cast attempt ' & $i & ': targetID=' & $targetID & ', currentTargetID=' & $currentTargetID)

		UseSkillEx($WING_SPIRIT_WALK, $target)
		Sleep(260)

		Local $meAfter = GetMyAgent()
		Local $afterX = Int(DllStructGetData($meAfter, 'X'))
		Local $afterY = Int(DllStructGetData($meAfter, 'Y'))
		Local $dx = $afterX - $beforeX
		Local $dy = $afterY - $beforeY
		Local $moveDist = Int(Sqrt($dx * $dx + $dy * $dy))
		Info('Spirit Walk move delta: from=(' & $beforeX & ', ' & $beforeY & ') to=(' & $afterX & ', ' & $afterY & ') dist=' & $moveDist)

		If $moveDist >= $minMoveDist Then Return True

		Sleep(120)
	Next

	Return False
EndFunc


Func LootWingstormFast()
	If IsPlayerDead() Then Return $FAIL

	Info('Wingstorm dead. Looting')
	RandomSleep(50)

	If $wingstorm_last_boss_death_x <> 0 And $wingstorm_last_boss_death_y <> 0 Then
		MoveTo($wingstorm_last_boss_death_x, $wingstorm_last_boss_death_y, 20, 0)
		WingstormWaitForPlayerNearPoint($wingstorm_last_boss_death_x, $wingstorm_last_boss_death_y, 240, 5000)
	EndIf

	PickUpItems()
	RandomSleep(350)
	PickUpItems()
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func WingstormWaitForBossInRange($range, $timeoutMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $timeoutMs And IsPlayerAlive()
		Local $boss = WingstormGetBossByModelID($WINGSTORM_BOSS_MODEL_ID)
		If $boss <> Null And GetDistance(GetMyAgent(), $boss) <= $range Then Return $boss
		Sleep(150)
	WEnd
	Return Null
EndFunc


Func WingstormIsBossConfirmedDead($confirmWindowMs = 2500)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $confirmWindowMs
		Local $boss = WingstormGetBossByModelID($WINGSTORM_BOSS_MODEL_ID)
		If $boss <> Null And Not GetIsDead($boss) And DllStructGetData($boss, 'HealthPercent') > 0 Then Return False
		Sleep(150)
	WEnd
	Return True
EndFunc


Func WingstormTryManualLikeSkillCastStrict($skillSlot, $target, $attempts = 3)
	If $target == Null Then Return False
	Local $requiredEnergy = WingstormGetSkillEnergyCost($skillSlot)

	For $i = 1 To $attempts
		If IsPlayerDead() Then Return False
		If GetEnergy() < $requiredEnergy Then
			Sleep(120)
			ContinueLoop
		EndIf

		Local $wasRecharged = IsRecharged($skillSlot)
		If Not $wasRecharged Then Return True

		UseSkill($skillSlot, $target)
		Sleep(140)
		If $wasRecharged And Not IsRecharged($skillSlot) Then Return True
		If IsCasting(GetMyAgent()) Then Return True
	Next
	Return False
EndFunc


Func WingstormGetSkillEnergyCost($skillSlot)
	Local $skillID = GetSkillbarSkillID($skillSlot)
	If $skillID == 0 Then Return 999
	Local $skill = GetSkillByID($skillID)
	Return Number(StringReplace(StringReplace(StringReplace(StringMid(DllStructGetData($skill, 'Unknown4'), 6, 1), 'C', '25'), 'B', '15'), 'A', '10'))
EndFunc


; Return nearest alive foe that matches modelID
Func WingstormGetBossByModelID($modelID)
	Local $me = GetMyAgent()
	Local $nearestBoss = Null
	Local $nearestDistance = 100000000

	For $agent In GetAgentArray($ID_AGENT_TYPE_NPC)
		If DllStructGetData($agent, 'ModelID') <> $modelID Then ContinueLoop
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then ContinueLoop
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop

		Local $distance = GetDistance($me, $agent)
		If $distance < $nearestDistance Then
			$nearestDistance = $distance
			$nearestBoss = $agent
		EndIf
	Next

	Return $nearestBoss
EndFunc


Func WingstormWaitForPlayerNearPoint($x, $y, $range, $timeout)
	Local $timer = TimerInit()
	While GetDistanceToPoint(GetMyAgent(), $x, $y) > $range
		If IsPlayerDead() Then Return $FAIL
		If TimerDiff($timer) > $timeout Then Return $FAIL
		Sleep(250)
	WEnd
	Return $SUCCESS
EndFunc
