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
Global Const $MD_PLAYER_SKILLBAR = 'OgVUMEkkYGT5irl4gqC+QENuCRAA'
Global Const $MD_PLAYER_WEAPON_SET = 1
Global Const $MD_PYRE_SKILLBAR = 'OgATY57gZxsD+Zn76OoDAAAA'
Global Const $MD_XANDRA_SKILLBAR = 'OACiAyk8EMJnzTAAAAAAAAAA'
Global Const $MD_MORGAHN_SKILLBAR = 'OQChYyDPeHDAAAAAAAAAAA'
Global Const $MISSING_DAUGHTER_FARM_INFORMATIONS = 'Custom Elementalist version:' & @CRLF _
	& '- Uses 3 heroes: Pyre, Xandra, General Morgahn' & @CRLF _
	& '- Pulls Missing Daughter mobs into a stable ball' & @CRLF _
	& '- Executes queued Ele spike sequence on the blob'

Global Const $MISSING_DAUGHTER_FARM_DURATION = (3 * 60 + 20) * 1000

Global Const $MD_PYRE_ID = $ID_PYRE_FIERCESHOT
Global Const $MD_XANDRA_ID = $ID_XANDRA
Global Const $MD_MORGAHN_ID = $ID_GENERAL_MORGAHN

; Player skill slots (Elementalist template)
Global Const $MD_EBON_BATTLE_STANDARD_OF_HONOR = 1
Global Const $MD_MINDBENDER = 2
Global Const $MD_INTENSITY = 3
Global Const $MD_EARTHQUAKE = 4
Global Const $MD_DRAGONS_STOMP = 5
Global Const $MD_RIDE_LIGHTNING = 6
Global Const $MD_SHOCKWAVE = 7
Global Const $MD_MANTRA_RESOLVE = 8

; Hero skill slots used in this script
Global Const $MD_PYRE_FIRST_SPIRIT_SLOT = 1
Global Const $MD_PYRE_LAST_SPIRIT_SLOT = 6
Global Const $MD_XANDRA_RITUAL_LORD = 1
Global Const $MD_XANDRA_EARTHBIND = 2
Global Const $MD_XANDRA_VITAL_WEAPON = 3
Global Const $MD_MORGAHN_INCOMING = 1
Global Const $MD_MORGAHN_FALL_BACK = 2

Global Const $MD_TIMEOUT = 130000
; Strict mode guidance:
; - False (recommended): tolerant live farming with fallback behavior.
; - True: strict deterministic debugging, fail fast on uncertain chain states.
Global Const $MD_STRICT_MODE = False
Global Const $MD_BALL_CENTER_X = -13262
Global Const $MD_BALL_CENTER_Y = -5486
Global Const $MD_BALL_CHECK_RADIUS = 500
Global Const $MD_BALL_STABILITY_RADIUS = 100
Global Const $MD_BALL_STABILITY_REQUIRED = 3
Global Const $MD_BALL_CHECK_INTERVAL_MS = 1400
Global Const $MD_BALL_SOFT_TIMEOUT_MS = 30000
Global Const $MD_BALL_HARD_TIMEOUT_MS = 45000

Global Const $MD_HERO_SAFE_X = -11471
Global Const $MD_HERO_SAFE_Y = -6140
Global Const $MD_HERO_APPROACH_X = -12670
Global Const $MD_HERO_APPROACH_Y = -5580
Global Const $MD_XANDRA_HALF_X = -12071
Global Const $MD_XANDRA_HALF_Y = -5860
Global Const $MD_HERO_FAR_X = -8447
Global Const $MD_HERO_FAR_Y = -10099

Global Const $MD_POST_AIKO_RETURN_SLEEP_MS = 1200
Global Const $MD_PYRE_CAST_SLEEP_MS = 4000
Global Const $MD_XANDRA_CAST_SLEEP_MS = 900
Global Const $MD_SPIKE_PREP_WAIT_MS = 7000
Global Const $MD_HERO_CAST_START_WAIT_MS = 1800
Global Const $MD_HERO_CAST_FINISH_WAIT_MS = 5500

Global $missing_daughter_farm_setup = False
Global $missing_daughter_rezone_done = False
Global $md_deadlock_timer
Global $md_pyre_slot = 1
Global $md_xandra_slot = 2
Global $md_morgahn_slot = 3
Global $missing_daughter_log_handle = -1
Global $missing_daughter_log_file = ''
Global $missing_daughter_log_run_number = 0
Global $missing_daughter_log_timer


;~ Main method for Missing Daughter ele run
Func MissingDaughterFarm()
	If Not $missing_daughter_farm_setup And SetupMissingDaughterFarm() == $FAIL Then Return $PAUSE
	$missing_daughter_log_run_number += 1
	MDFightLogInit()
	MDFightLogWrite('run_start', 'setup=' & $missing_daughter_farm_setup)

	Local $result = MissingDaughterFarmLoop()
	MDFightLogWrite('run_end', 'result=' & $result)
	MDFightLogClose()
	ResignAndReturnToOutpost($ID_THE_MARKETPLACE)
	Return $result
EndFunc


Func SetupMissingDaughterFarm()
	Info('Setting up Missing Daughter ele farm')
	If TravelToOutpost($ID_THE_MARKETPLACE, $district_name) == $FAIL Then Return $FAIL
	If Not SupportTeamStabilizeAfterTravel($ID_THE_MARKETPLACE, 10000, 300) Then Return $FAIL
	SwitchMode($ID_HARD_MODE)

	If SetupPlayerMissingDaughterFarm() == $FAIL Then Return $FAIL
	If SetupTeamMissingDaughterFarm() == $FAIL Then Return $FAIL

	$missing_daughter_rezone_done = False
	$missing_daughter_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerMissingDaughterFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ELEMENTALIST Then
		LoadSkillTemplate($MD_PLAYER_SKILLBAR)
		RandomSleep(250)
		ChangeWeaponSet($MD_PLAYER_WEAPON_SET)
		RandomSleep(120)
	Else
		Warn('Should run this farm as elementalist')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func SetupTeamMissingDaughterFarm()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up team with Pyre, Xandra, Morgahn')
	MDLogSupportSetupState('pre_solo_reset')
	If MDEnsureSoloParty() == $FAIL Then
		Warn('Could not reset to solo party before adding Missing Daughter heroes')
		Return $FAIL
	EndIf
	MDLogSupportSetupState('post_solo_reset')

	MDLogSupportSetupState('pre_hero_add_attempt_1')
	If MDAssembleSupportTeam() == $FAIL Then
		Warn('First team assembly attempt failed, retrying after outpost refresh')
		MDLogSupportSetupState('hero_add_attempt_1_failed')
		If TravelToOutpost($ID_THE_MARKETPLACE, $district_name) == $FAIL Then Return $FAIL
		If Not SupportTeamStabilizeAfterTravel($ID_THE_MARKETPLACE, 10000, 300) Then Return $FAIL
		MDLogSupportSetupState('post_refresh_before_retry')
		If MDEnsureSoloParty() == $FAIL Then
			Warn('Could not reset to solo party for retry hero setup')
			Return $FAIL
		EndIf
		MDLogSupportSetupState('post_solo_reset_retry')
		MDLogSupportSetupState('pre_hero_add_attempt_2')
		If MDAssembleSupportTeam() == $FAIL Then
			Warn('Second team assembly attempt failed, performing final outpost refresh retry')
			MDLogSupportSetupState('hero_add_attempt_2_failed')
			If TravelToOutpost($ID_THE_MARKETPLACE, $district_name) == $FAIL Then Return $FAIL
			If Not SupportTeamStabilizeAfterTravel($ID_THE_MARKETPLACE, 12000, 300) Then Return $FAIL
			MDLogSupportSetupState('post_refresh_before_retry_3')
			If MDEnsureSoloParty() == $FAIL Then
				Warn('Could not reset to solo party for final hero setup retry')
				Return $FAIL
			EndIf
			MDLogSupportSetupState('post_solo_reset_retry_3')
			MDLogSupportSetupState('pre_hero_add_attempt_3')
			If MDAssembleSupportTeam() == $FAIL Then
				MDLogSupportSetupState('hero_add_attempt_3_failed')
				Return $FAIL
			EndIf
		EndIf
	EndIf
	MDLogSupportSetupState('hero_add_success')
	If Not MDLoadSupportTemplatesStable() Then Return $FAIL

	DisableAllHeroSkills($md_pyre_slot)
	DisableAllHeroSkills($md_xandra_slot)
	RandomSleep(500)

	If Not MDWaitForExpectedPartyState(4, 3, 4500) Then
		Warn('Could not set up party correctly. Team size different than 4')
		Return $FAIL
	EndIf

	Return $SUCCESS
EndFunc


Func MDEnsureSoloParty($maxWaitMs = 9000)
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

	Warn('Missing Daughter: solo-party reset timeout. Party=' & GetPartySize() & ', heroes=' & GetHeroCount())
	Return $FAIL
EndFunc


Func MDTryAddHero($heroID, $heroName)
	For $i = 1 To 14
		If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
		AddHero($heroID)
		RandomSleep(450 + ($i * 20))
		If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
		If Mod($i, 4) == 0 Then SupportTeamStabilizeAfterTravel($ID_THE_MARKETPLACE, 2000, 200)
	Next
	Warn('Could not add hero ' & $heroName)
	Return $FAIL
EndFunc


Func MDAssembleSupportTeam()
	If MDTryAddHero($MD_PYRE_ID, 'Pyre') == $FAIL Then Return $FAIL
	If MDTryAddHero($MD_XANDRA_ID, 'Xandra') == $FAIL Then Return $FAIL
	If MDTryAddHero($MD_MORGAHN_ID, 'General Morgahn') == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func MDLoadSupportTemplatesStable()
	If Not MDResolveSupportHeroSlotsStable() Then Return False

	If Not MDLoadHeroTemplateStable($MD_PYRE_ID, 'Pyre', $MD_PYRE_SKILLBAR, $ID_RANGER) Then Return False
	RandomSleep(150)
	If Not MDLoadHeroTemplateStable($MD_XANDRA_ID, 'Xandra', $MD_XANDRA_SKILLBAR, $ID_RITUALIST, 10, 1, $ID_RITUAL_LORD, $ID_RITUAL_LORD_PVP) Then Return False
	RandomSleep(150)
	If Not MDLoadHeroTemplateStable($MD_MORGAHN_ID, 'General Morgahn', $MD_MORGAHN_SKILLBAR, $ID_PARAGON, 10, 1, $ID_INCOMING, $ID_INCOMING_PVP) Then Return False
	RandomSleep(250)

	If Not MDResolveSupportHeroSlotsStable() Then Return False
	Return True
EndFunc


Func MDResolveSupportHeroSlotsStable($maxWaitMs = 5000)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs
		$md_pyre_slot = GetHeroNumberByHeroID($MD_PYRE_ID)
		$md_xandra_slot = GetHeroNumberByHeroID($MD_XANDRA_ID)
		$md_morgahn_slot = GetHeroNumberByHeroID($MD_MORGAHN_ID)
		If $md_pyre_slot <> Null And $md_xandra_slot <> Null And $md_morgahn_slot <> Null Then
			If GetHeroProfession($md_pyre_slot) == $ID_RANGER _
				And GetHeroProfession($md_xandra_slot) == $ID_RITUALIST _
				And GetHeroProfession($md_morgahn_slot) == $ID_PARAGON Then
				Return True
			EndIf
		EndIf
		RandomSleep(180)
	WEnd

	Warn('Could not resolve stable hero slots/professions for Missing Daughter support team')
	Return False
EndFunc


Func MDLoadHeroTemplateStable($heroID, $heroName, $template, $expectedProfession, $maxAttempts = 8, $verifySkillSlot = 0, $verifySkillID = 0, $verifySkillIDAlt = 0)
	Local $attempt
	For $attempt = 1 To $maxAttempts
		If Mod($attempt, 3) == 0 Then
			; Party/hero structs may lag in outpost after add/reset cycles.
			SupportTeamStabilizeAfterTravel($ID_THE_MARKETPLACE, 2000, 200)
		EndIf

		Local $slot = GetHeroNumberByHeroID($heroID)
		If $slot == Null Then
			RandomSleep(180)
			ContinueLoop
		EndIf

		If HeroHasTemplate($slot, $template) Then
			Info('MD ' & $heroName & ': template already loaded, skipping')
			Return True
		EndIf

		Local $profession = GetHeroProfession($slot)
		If $profession <> $expectedProfession Then
			RandomSleep(180)
			ContinueLoop
		EndIf

		; LoadSkillTemplate has no reliable success return value in this codebase.
		; Apply template, then validate via optional slot/skill check when provided.
		LoadSkillTemplate($template, $slot)
		RandomSleep(280 + ($attempt * 20))

		If $verifySkillSlot <= 0 Or $verifySkillID <= 0 Then
			Info('Template loaded for ' & $heroName & ' (attempt ' & $attempt & ')')
			Return True
		EndIf

		Local $loadedSkill = GetSkillbarSkillID($verifySkillSlot, $slot)
		If $loadedSkill == $verifySkillID Or ($verifySkillIDAlt > 0 And $loadedSkill == $verifySkillIDAlt) Then
			Info('Template verified for ' & $heroName & ' at slot ' & $verifySkillSlot & ' (attempt ' & $attempt & ')')
			Return True
		EndIf

		Warn('Template verify pending for ' & $heroName & ' at attempt ' & $attempt & ' (slot=' & $slot & ',skill=' & $loadedSkill & ')')
		RandomSleep(220)
	Next

	Warn('Could not load template for ' & $heroName & ' after retries')
	Return False
EndFunc


Func MDWaitForExpectedPartyState($expectedPartySize, $expectedHeroCount, $maxWaitMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs
		If GetPartySize() == $expectedPartySize And GetHeroCount() == $expectedHeroCount Then Return True
		RandomSleep(150)
	WEnd
	Return False
EndFunc


Func MDLogSupportSetupState($phase)
	Info('Missing Daughter support state [' & $phase & '] map=' & GetMapID() & ', party=' & GetPartySize() & ', heroes=' & GetHeroCount())
EndFunc


Func MissingDaughterFarmLoop()
	MDFixPlayerWeaponSet()
	MDAssureHeroPanelsVisible()

	MDFightLogWrite('stage', 'GoToBukdekBywayMissingDaughter')
	GoToBukdekBywayMissingDaughter()
	If Not $missing_daughter_rezone_done Then
		MDFightLogWrite('stage', 'RezoneBukdekBywayMissingDaughter')
		If RezoneBukdekBywayMissingDaughter() == $FAIL Then Return $FAIL
		$missing_daughter_rezone_done = True
	EndIf
	MDFightLogWrite('stage', 'FlagHeroesSafeBeforeAiko')
	FlagHeroesSafeBeforeAiko()

	$md_deadlock_timer = TimerInit()
	MDFightLogWrite('stage', 'PullAikoAndReturnToHeroes')
	If PullAikoAndReturnToHeroes() == $FAIL Then Return $FAIL
	MDFightLogWrite('stage', 'CastPyreSpiritChain')
	If CastPyreSpiritChain() == $FAIL Then Return $FAIL
	$md_deadlock_timer = TimerInit()
	MDFightLogWrite('stage', 'WaitForStableJadeBall')
	If WaitForStableJadeBall() == $FAIL Then Return $FAIL
	MDFightLogWrite('stage', 'PrepareXandraSupport')
	If PrepareXandraSupport() == $FAIL Then Return $FAIL
	; Hard safety: ensure all heroes are flagged back before spike.
	CommandAll($MD_HERO_FAR_X, $MD_HERO_FAR_Y)
	RandomSleep(300)
	MDFightLogWrite('stage', 'ExecuteEleSpikeSequence')
	If ExecuteEleSpikeSequence() == $FAIL Then Return $FAIL

	RandomSleep(1000)
	If IsPlayerDead() Then Return $FAIL
	Info('Looting')
	MDFightLogWrite('stage', 'Looting')
	PickUpItems()
	Return $SUCCESS
EndFunc


Func MDFixPlayerWeaponSet()
	ChangeWeaponSet($MD_PLAYER_WEAPON_SET)
	RandomSleep(120)
EndFunc


Func MDAssureHeroPanelsVisible()
	SupportTeamOpenHeroPanels('Missing Daughter')
EndFunc


Func RezoneBukdekBywayMissingDaughter()
	Info('Applying re-zone trick (walk back through portal, then re-enter)')
	; Use the proven Bukdek -> Marketplace portal path used by JadeBrotherhood setup.
	MoveTo(-14000, -11000)
	Move(-14000, -11700)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_THE_MARKETPLACE) Then
		MDFightLogWrite('rezone_fail', 'could_not_zone_to_marketplace')
		Return $FAIL
	EndIf

	; Re-enter Bukdek immediately.
	GoToBukdekBywayMissingDaughter()
	If GetMapID() <> $ID_BUKDEK_BYWAY Then
		MDFightLogWrite('rezone_fail', 'could_not_reenter_bukdek')
		Return $FAIL
	EndIf

	MDFightLogWrite('rezone_ok', 'out_in_completed')
	Return $SUCCESS
EndFunc


Func GoToBukdekBywayMissingDaughter()
	TravelToOutpost($ID_THE_MARKETPLACE, $district_name)
	If GetQuestByID($ID_QUEST_MISSING_DAUGHTER) <> Null Then
		Info('Abandoning quest')
		AbandonQuest($ID_QUEST_MISSING_DAUGHTER)
	EndIf

	While GetMapID() <> $ID_BUKDEK_BYWAY
		Info('Moving to Bukdek Byway')
		MoveTo(16106, 18497)
		MoveTo(16500, 19400)
		Move(16551, 19860)
		RandomSleep(1000)
		WaitMapLoading($ID_BUKDEK_BYWAY)
	WEnd
EndFunc


Func FlagHeroesSafeBeforeAiko()
	Info('Flagging heroes to safe position before Aiko')
	MoveTo(-10475, -9685)
	MoveTo($MD_HERO_SAFE_X, $MD_HERO_SAFE_Y)
	CommandAll($MD_HERO_SAFE_X, $MD_HERO_SAFE_Y)
	MoveTo(-11983, -6261)
EndFunc


Func PullAikoAndReturnToHeroes()
	Info('Cast Mindbender and talk to Aiko')
	If IsRecharged($MD_MANTRA_RESOLVE) Then UseSkillEx($MD_MANTRA_RESOLVE)
	RandomSleep(100)
	UseSkillEx($MD_MINDBENDER)
	UseHeroSkill($md_morgahn_slot, $MD_MORGAHN_INCOMING)
	RandomSleep(50)
	GoNearestNPCToCoords(-13923, -5098)
	RandomSleep(300)
	; Keep the same interaction style as other custom pull scripts.
	Dialog(0x84)
	RandomSleep(250)
	AcceptQuest($ID_QUEST_MISSING_DAUGHTER)

	UseHeroSkill($md_morgahn_slot, $MD_MORGAHN_FALL_BACK)
	If IsRecharged($MD_MANTRA_RESOLVE) Then UseSkillEx($MD_MANTRA_RESOLVE)
	; Retreat must complete before Pyre starts, otherwise we can die at pull spot.
	MDMovePlayerNearPoint(-12850, -5900, 450, 3000, 'aiko_retreat_mid')
	MDMovePlayerNearPoint($MD_HERO_SAFE_X, $MD_HERO_SAFE_Y, 500, 5200, 'aiko_retreat_safe')
	MoveTo($MD_HERO_SAFE_X, $MD_HERO_SAFE_Y)
	CommandAll($MD_HERO_SAFE_X, $MD_HERO_SAFE_Y)
	RandomSleep($MD_POST_AIKO_RETURN_SLEEP_MS + 600)
	Return IsPlayerDead() ? $FAIL : $SUCCESS
EndFunc


Func CastPyreSpiritChain()
	Info('Pyre casts all 6 spirits')
	If IsPlayerDead() Then
		MDFightLogWrite('pyre_abort', 'player_dead_before_chain')
		Return $FAIL
	EndIf
	For $slot = $MD_PYRE_FIRST_SPIRIT_SLOT To $MD_PYRE_LAST_SPIRIT_SLOT
		If IsPlayerDead() Then
			MDFightLogWrite('pyre_abort', 'player_dead_during_chain_slot=' & $slot)
			Return $FAIL
		EndIf
		If TimerDiff($md_deadlock_timer) > $MD_TIMEOUT Then
			MDFightLogWrite('pyre_abort', 'timeout_slot=' & $slot)
			Return $FAIL
		EndIf
		UseHeroSkill($md_pyre_slot, $slot)
		MDFightLogWrite('pyre_cast_cmd', 'slot=' & $slot, GetAgentByID(GetHeroID($md_pyre_slot)), $slot)
		; Deterministic spacing: one spirit command every 4s.
		RandomSleep($MD_PYRE_CAST_SLEEP_MS)
	Next
	Return $SUCCESS
EndFunc


Func WaitForStableJadeBall()
	Info('Waiting for ball')
	RandomSleep(4500)
	Local $ballTimer = TimerInit()
	Local $foesBalled = 0
	Local $peasantsAlive = 100
	Local $countsDidNotChange = 0
	Local $prevFoesBalled = 0
	Local $prevPeasantsAlive = 100

	While ($foesBalled <> 8 Or $peasantsAlive > 1)
		If IsPlayerDead() Or TimerDiff($md_deadlock_timer) > $MD_TIMEOUT Then Return $FAIL
		Debug('Foes balled : ' & $foesBalled)
		Debug('Peasants alive : ' & $peasantsAlive)
		RandomSleep(4500)
		$prevFoesBalled = $foesBalled
		$prevPeasantsAlive = $peasantsAlive
		$foesBalled = CountFoesInRangeOfCoords($MD_BALL_CENTER_X, $MD_BALL_CENTER_Y, $MD_BALL_CHECK_RADIUS)
		$peasantsAlive = CountAlliesInRangeOfCoords($MD_BALL_CENTER_X, $MD_BALL_CENTER_Y, 1200)
		If Not $MD_STRICT_MODE And TimerDiff($ballTimer) > $MD_BALL_SOFT_TIMEOUT_MS And $foesBalled >= 7 Then
			MDFightLogWrite('ball_soft_timeout_continue', 'foes=' & $foesBalled & ',peasants=' & $peasantsAlive)
			Return $SUCCESS
		EndIf
		If Not $MD_STRICT_MODE And TimerDiff($ballTimer) > $MD_BALL_HARD_TIMEOUT_MS Then
			MDFightLogWrite('ball_hard_timeout_continue', 'foes=' & $foesBalled & ',peasants=' & $peasantsAlive)
			Return $SUCCESS
		EndIf
		If ($foesBalled = $prevFoesBalled And $peasantsAlive = $prevPeasantsAlive) Then
			$countsDidNotChange += 1
			If $countsDidNotChange > 2 Then Return $SUCCESS
		Else
			$countsDidNotChange = 0
		EndIf
	WEnd

	Return $SUCCESS
EndFunc


Func PrepareXandraSupport()
	Info('Move Xandra halfway in, cast 1->2 and 1->3 safely, then regroup all at portal')
	CommandHero($md_xandra_slot, $MD_XANDRA_HALF_X, $MD_XANDRA_HALF_Y)
	RandomSleep(1700)
	Local $xandraAgent = GetAgentByID(GetHeroID($md_xandra_slot))

	MDUseHeroSkillCastSafe($md_xandra_slot, $MD_XANDRA_RITUAL_LORD)
	RandomSleep(220)
	If Not MDUseHeroSkillCastSafe($md_xandra_slot, $MD_XANDRA_EARTHBIND, Null, True, 'xandra_earthbind') Then
		Warn('Xandra Earthbind did not complete safely')
		MDFightLogWrite('xandra_support_fail', 'earthbind_not_completed', $xandraAgent, $MD_XANDRA_EARTHBIND)
		If $MD_STRICT_MODE Then Return $FAIL
		MDFightLogWrite('xandra_support_warn', 'earthbind_continue_non_strict', $xandraAgent, $MD_XANDRA_EARTHBIND)
	EndIf

	MDUseHeroSkillCastSafe($md_xandra_slot, $MD_XANDRA_RITUAL_LORD)
	RandomSleep(220)
	MDUseHeroSkillCastSafe($md_xandra_slot, $MD_XANDRA_VITAL_WEAPON, GetMyAgent(), True, 'xandra_vital_weapon')
	RandomSleep(300)
	MDFightLogWrite('xandra_support_done', 'halfway_cast_complete', $xandraAgent, $MD_XANDRA_VITAL_WEAPON)

	; Group retreat: speed boost first, then explicitly flag all 3 heroes together.
	UseHeroSkill($md_morgahn_slot, $MD_MORGAHN_INCOMING)
	RandomSleep(200)
	CommandHero($md_pyre_slot, $MD_HERO_FAR_X, $MD_HERO_FAR_Y)
	CommandHero($md_xandra_slot, $MD_HERO_FAR_X, $MD_HERO_FAR_Y)
	CommandHero($md_morgahn_slot, $MD_HERO_FAR_X, $MD_HERO_FAR_Y)
	RandomSleep(250)
	CommandAll($MD_HERO_FAR_X, $MD_HERO_FAR_Y)
	RandomSleep(900)
	CommandAll($MD_HERO_FAR_X, $MD_HERO_FAR_Y)
	RandomSleep(700)

	Return IsPlayerDead() ? $FAIL : $SUCCESS
EndFunc


Func MDMovePlayerNearPoint($x, $y, $radius = 450, $maxWaitMs = 4500, $label = '')
	Local $timer = TimerInit()
	MoveTo($x, $y)
	While TimerDiff($timer) < $maxWaitMs
		If IsPlayerDead() Then Return False
		Local $me = GetMyAgent()
		If $me <> Null Then
			If GetDistanceToPoint($me, $x, $y) <= $radius Then Return True
		EndIf
		If Not IsPlayerMoving() Then Move($x, $y)
		RandomSleep(120)
	WEnd
	MDFightLogWrite('move_timeout', 'label=' & $label & ',x=' & $x & ',y=' & $y)
	Return False
EndFunc


Func MDUseHeroSkillCastSafe($heroSlot, $skillSlot, $target = Null, $waitForFinish = False, $castLabel = '')
	Local $heroAgent = GetAgentByID(GetHeroID($heroSlot))
	If $heroAgent == Null Then Return False

	If $target == Null Then
		UseHeroSkill($heroSlot, $skillSlot)
	Else
		UseHeroSkill($heroSlot, $skillSlot, $target)
	EndIf

	Local $started = MDWaitForHeroSkillStart($heroSlot, $skillSlot, $MD_HERO_CAST_START_WAIT_MS)
	If Not $started Then
		If $castLabel <> '' Then MDFightLogWrite('hero_cast_start_fail', 'label=' & $castLabel, $heroAgent, $skillSlot)
		Return False
	EndIf

	If Not $waitForFinish Then Return True

	If Not MDWaitForHeroCastFinish($heroSlot, $MD_HERO_CAST_FINISH_WAIT_MS) Then
		If $castLabel <> '' Then MDFightLogWrite('hero_cast_finish_fail', 'label=' & $castLabel, $heroAgent, $skillSlot)
		Return False
	EndIf

	Return True
EndFunc


Func MDWaitForHeroSkillStart($heroSlot, $skillSlot, $maxWaitMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs
		Local $heroAgent = GetAgentByID(GetHeroID($heroSlot))
		If $heroAgent <> Null And IsCasting($heroAgent) Then Return True
		If Not IsRecharged($skillSlot, $heroSlot) Then Return True
		RandomSleep(35)
	WEnd
	Return False
EndFunc


Func MDWaitForHeroCastFinish($heroSlot, $maxWaitMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs
		Local $heroAgent = GetAgentByID(GetHeroID($heroSlot))
		If $heroAgent == Null Then Return False
		If Not IsCasting($heroAgent) Then Return True
		RandomSleep(35)
	WEnd
	Return False
EndFunc


Func ExecuteEleSpikeSequence()
	Local $target = GetNearestEnemyToCoords($MD_BALL_CENTER_X, $MD_BALL_CENTER_Y)
	If $target == Null Then
		Warn('No target found near ball center')
		MDFightLogWrite('spike_fail', 'no_target_ball_center')
		Return $FAIL
	EndIf

	Local $center = FindMiddleOfFoes(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'), 2 * $RANGE_EARSHOT)
	If IsArray($center) Then
		$target = GetNearestEnemyToCoords($center[0], $center[1])
	EndIf
	If $target == Null Then
		MDFightLogWrite('spike_fail', 'no_target_after_centering')
		Return $FAIL
	EndIf

	Info('Moving max close and executing queued spike sequence')
	; Re-enforce approach so choreography does not start in place.
	ChangeTarget($target)
	GetAlmostInRangeOfAgent($target)
	RandomSleep(220)
	ChangeTarget($target)
	GetAlmostInRangeOfAgent($target)
	RandomSleep(220)
	MDFightLogWrite('spike_pre_move_complete', '', $target)
	Local $me = GetMyAgent()
	CancelAction()

	; Choreo summary (deterministic):
	; 8 -> 1 -> 2 -> 3 -> 4 -> queue 5 during 4 -> queue 6 during 5 -> 7(self) finisher.
	UseSkillEx($MD_MANTRA_RESOLVE)
	UseSkillEx($MD_EBON_BATTLE_STANDARD_OF_HONOR)
	RandomSleep(1000)
	UseSkillEx($MD_MINDBENDER)
	RandomSleep(1000)
	UseSkillEx($MD_INTENSITY)
	RandomSleep(6000)
	$target = GetNearestEnemyToAgent(GetMyAgent())
	If $target == Null Then Return $FAIL
	ChangeTarget($target)
	$me = GetMyAgent()
	MDLogSpikeSkillState('pre_s4', $MD_EARTHQUAKE, $target)
	MDPressSkill($MD_EARTHQUAKE, $target)

	; Hard requirement: queue 5 while 4 is still casting so 5 is blinking/queued.
	RandomSleep(80)
	MDLogSpikeSkillState('pre_s5_queue', $MD_DRAGONS_STOMP, $target)
	MDPressSkill($MD_DRAGONS_STOMP, $target)

	; Wait for 4 cast (~3s), then 1s into 5 press 3 (instant, no interruption).
	RandomSleep(3100)
	RandomSleep(1000)
	MDLogSpikeSkillState('pre_s3_during_s5', $MD_INTENSITY, $target)
	MDPressSkill($MD_INTENSITY)
	RandomSleep(60)

	; While 5 is still casting (3s total), queue 6 behind it.
	$target = GetNearestEnemyToAgent(GetMyAgent())
	If $target == Null Then $target = GetNearestEnemyToCoords($MD_BALL_CENTER_X, $MD_BALL_CENTER_Y)
	If $target == Null Then $target = GetNearestEnemyToAgent(GetMyAgent())
	If $target == Null Then
		MDFightLogWrite('spike_fail', 'no_target_before_s6')
		Return $FAIL
	EndIf
	ChangeTarget($target)
	$me = GetMyAgent()
	Local $xBefore6 = DllStructGetData($me, 'X')
	Local $yBefore6 = DllStructGetData($me, 'Y')
	MDLogSpikeSkillState('pre_s6_queue', $MD_RIDE_LIGHTNING, $target)
	MDPressSkill($MD_RIDE_LIGHTNING, $target)
	RandomSleep(90)
	MDLogSpikeSkillState('pre_s6_queue_retry', $MD_RIDE_LIGHTNING, $target)
	MDPressSkill($MD_RIDE_LIGHTNING, $target)

	; Hard gate: do not press 7 until 6 has actually started (recharge consumed).
	Local $s6Started = MDWaitForSkillStart($MD_RIDE_LIGHTNING, 2800)
	MDFightLogWrite('spike_s6_started', 'value=' & ($s6Started ? 1 : 0), $target, $MD_RIDE_LIGHTNING)
	If Not $s6Started Then
		If $MD_STRICT_MODE Then
			Warn('Strict mode: 6 did not start in time, aborting chain')
			MDFightLogWrite('spike_fail', 'strict_no_s6_start', $target, $MD_RIDE_LIGHTNING)
			Return $FAIL
		Else
			; Detector can be false-negative on this skill; do not skip 7 entirely in tolerant mode.
			Warn('6 start not confirmed in time, using fallback delay then casting 7')
			MDFightLogWrite('spike_s7_fallback_after_s6_uncertain', '', $target, $MD_SHOCKWAVE)
			RandomSleep(420)
		EndIf
	EndIf

	RandomSleep(180)
	$me = GetMyAgent()
	Local $xAfter6 = DllStructGetData($me, 'X')
	Local $yAfter6 = DllStructGetData($me, 'Y')
	Local $delta6 = Sqrt((($xAfter6 - $xBefore6) * ($xAfter6 - $xBefore6)) + (($yAfter6 - $yBefore6) * ($yAfter6 - $yBefore6)))
	Info('MD-SPIKE post_s6 pos_delta=' & Int($delta6) & ' cast=' & (IsCasting($me) ? 1 : 0) & ' energy=' & Round(GetEnergy(), 1))
	MDFightLogWrite('spike_post_s6', 'pos_delta=' & Int($delta6) & ',cast=' & (IsCasting($me) ? 1 : 0) & ',energy=' & Round(GetEnergy(), 1), $target, $MD_RIDE_LIGHTNING)
	$me = GetMyAgent()
	ChangeTarget($me)
	MDLogSpikeSkillState('pre_s7_self', $MD_SHOCKWAVE, $me)
	Local $s7Started = MDPressSkillWithStartConfirm($MD_SHOCKWAVE, Null, 700, 3, 120)
	MDFightLogWrite('spike_s7_started', 'value=' & ($s7Started ? 1 : 0), $me, $MD_SHOCKWAVE)
	If Not $s7Started Then
		Warn('7 did not confirm start, forcing final retry')
		RandomSleep(220)
		MDPressSkill($MD_SHOCKWAVE)
	EndIf
	RandomSleep(1000)

	Local $cleanupTimer = TimerInit()
	While CountFoesInRangeOfAgent(GetMyAgent(), 1250) > 0 And TimerDiff($cleanupTimer) < 8000
		If IsPlayerDead() Then Return $FAIL
		$target = GetNearestEnemyToAgent(GetMyAgent())
		If $target == Null Then ExitLoop
		ChangeTarget($target)
		CancelAction()
		RandomSleep(250)
	WEnd

	Return IsPlayerDead() ? $FAIL : $SUCCESS
EndFunc


Func MDWaitForSkillStart($skillSlot, $maxWaitMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs
		; Skill start is confirmed when recharge is consumed.
		If Not IsRecharged($skillSlot) Then Return True
		RandomSleep(40)
	WEnd
	Return False
EndFunc


Func MDPressSkill($skillSlot, $target = Null)
	If IsPlayerDead() Then Return False
	If $target == Null Then
		UseSkill($skillSlot)
	Else
		UseSkill($skillSlot, $target)
	EndIf
	Return True
EndFunc


Func MDPressSkillWithStartConfirm($skillSlot, $target = Null, $confirmMs = 700, $maxAttempts = 2, $retrySleepMs = 120)
	Local $skillID = GetSkillbarSkillID($skillSlot)
	Local $attempt
	For $attempt = 1 To $maxAttempts
		If IsPlayerDead() Then Return False
		MDPressSkill($skillSlot, $target)
		Local $timer = TimerInit()
		While TimerDiff($timer) < $confirmMs
			If IsPlayerDead() Then Return False
			If Not IsRecharged($skillSlot) Then Return True
			Local $me = GetMyAgent()
			If IsCasting($me) Then
				If $skillID == 0 Or DllStructGetData($me, 'Skill') == $skillID Then Return True
			EndIf
			RandomSleep(35)
		WEnd
		RandomSleep($retrySleepMs)
	Next
	Return False
EndFunc


Func MDLogSpikeSkillState($phase, $skillSlot, $target = Null)
	Local $me = GetMyAgent()
	Local $targetId = -1
	Local $targetDist = -1
	Local $targetHp = -1
	Local $targetDead = -1

	If $target <> Null Then
		$targetId = DllStructGetData($target, 'ID')
		$targetDist = Int(GetDistance($me, $target))
		$targetHp = Round(DllStructGetData($target, 'HP'), 3)
		$targetDead = GetIsDead($target) ? 1 : 0
	EndIf

	Info('MD-SPIKE ' & $phase & ' s=' & $skillSlot _
		& ' ready=' & (IsRecharged($skillSlot) ? 1 : 0) _
		& ' cast=' & (IsCasting($me) ? 1 : 0) _
		& ' energy=' & Round(GetEnergy(), 1) _
		& ' tid=' & $targetId _
		& ' dist=' & $targetDist _
		& ' thp=' & $targetHp _
		& ' tdead=' & $targetDead)
	MDFightLogWrite('spike_' & $phase, 'tdead=' & $targetDead & ',ready=' & (IsRecharged($skillSlot) ? 1 : 0) & ',cast=' & (IsCasting($me) ? 1 : 0), $target, $skillSlot)
EndFunc


Func MDFightLogInit()
	Local $timestamp = @YEAR & @MON & @MDAY & '_' & @HOUR & @MIN & @SEC
	$missing_daughter_log_file = @ScriptDir & '/logs/missing_daughter_debug-' & GetCharacterName() & '-run' & $missing_daughter_log_run_number & '-' & $timestamp & '.csv'
	$missing_daughter_log_handle = FileOpen($missing_daughter_log_file, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	$missing_daughter_log_timer = TimerInit()
	Info('Missing Daughter CSV: ' & $missing_daughter_log_file)
	If $missing_daughter_log_handle == -1 Then Return
	FileWriteLine($missing_daughter_log_handle, 'time_ms;run;event;energy;hp;map_id;x;y;target_id;target_hp;target_dist;skill;skill_ready;casting;note')
EndFunc


Func MDFightLogClose()
	If $missing_daughter_log_handle == -1 Then Return
	FileClose($missing_daughter_log_handle)
	$missing_daughter_log_handle = -1
EndFunc


Func MDFightLogWrite($eventName, $note = '', $target = Null, $skillSlot = -1)
	If $missing_daughter_log_handle == -1 Then Return
	Local $timeMs = Int(TimerDiff($missing_daughter_log_timer))
	Local $me = GetMyAgent()
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')
	Local $energy = Round(GetEnergy(), 1)
	Local $hp = Round(DllStructGetData($me, 'HealthPercent'), 3)
	Local $mapID = GetMapID()
	Local $targetID = -1
	Local $targetHp = -1
	Local $targetDist = -1
	Local $skillReady = -1
	If $skillSlot > 0 Then $skillReady = IsRecharged($skillSlot) ? 1 : 0

	If $target <> Null Then
		$targetID = DllStructGetData($target, 'ID')
		$targetHp = Round(DllStructGetData($target, 'HealthPercent'), 3)
		$targetDist = Int(GetDistance($me, $target))
	EndIf

	Local $safeNote = StringReplace(StringReplace($note, ';', ','), @CRLF, ' ')
	FileWriteLine($missing_daughter_log_handle, $timeMs & ';' & $missing_daughter_log_run_number & ';' & $eventName & ';' & $energy & ';' & $hp & ';' & $mapID & ';' & $x & ';' & $y & ';' & $targetID & ';' & $targetHp & ';' & $targetDist & ';' & $skillSlot & ';' & $skillReady & ';' & (IsCasting($me) ? 1 : 0) & ';' & $safeNote)
EndFunc
