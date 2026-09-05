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
Global Const $VARAJAR_BERSERKERS_SKILLBAR = 'OwFTQ5K/HimUlZULXsvYHkn4ACA'
Global Const $VARAJAR_MARGRID_SKILLBAR = 'OgkjYxXjJPQHe8OGAAAAAAAAAA'
Global Const $VARAJAR_MORGAHN_SKILLBAR = 'OQijEamLKPm4bMAAAwj3xDbAAA'
Global Const $VARAJAR_KOSS_SKILLBAR = 'OQkiUxm8wj3xAAAAAAAAAAAA'
Global Const $VARAJAR_MOX_SKILLBAR = 'OgmiYynywjBAAAAAAAAAAAAA'
Global Const $VARAJAR_JORA_SKILLBAR = 'OQkiUxm8wj3xAAAAAAAAAAAA'

Global Const $VARAJAR_BERSERKERS_FARM_INFORMATIONS = 'A/W Whirlwind Sin farming Norn Berserkers in Varajar Fells for Berserker Horns.' & @CRLF _
	& '- Start in Olafstead, exit toward Varajar Fells' & @CRLF _
	& '- Margrid (EoE, disabled) + Morgahn (Enduring Harmony/Make Haste, disabled) provide speed and damage' & @CRLF _
	& '- 5 extra heroes act as meat shields to survive the run' & @CRLF _
	& '- At the split spot all heroes are flagged far away so they cannot loot' & @CRLF _
	& '- Sin casts I Am Unstoppable, runs an aggro circle, then spikes with Hundred Blades + Whirlwind Attack'
Global Const $VARAJAR_BERSERKERS_FARM_DURATION = 4 * 60 * 1000

; Assassin/Warrior player skill slots
Global Const $VB_I_AM_UNSTOPPABLE = 1
Global Const $VB_PROTECTORS_DEFENSE = 2
Global Const $VB_SOLDIERS_DEFENSE = 3
Global Const $VB_EBON_BATTLE_STANDARD = 4
Global Const $VB_HUNDRED_BLADES = 5
Global Const $VB_WHIRLWIND_ATTACK = 6
Global Const $VB_TO_THE_LIMIT = 7
Global Const $VB_SHROUD_OF_DISTRESS = 8

; Hero party indices (Margrid added first, Morgahn second)
Global Const $VB_MARGRID = 1
Global Const $VB_MORGAHN = 2

; Hero skill slots
Global Const $VB_MARGRID_EOE = 1
Global Const $VB_MORGAHN_VOCAL_WAS_SOGOLON = 7
Global Const $VB_MORGAHN_ENDURING_HARMONY = 1
Global Const $VB_MORGAHN_MAKE_HASTE = 2

; Key coordinates
Global Const $VB_SPLIT_X = -13523
Global Const $VB_SPLIT_Y = -6793
Global Const $VB_FLAG_AWAY_X = -2300
Global Const $VB_FLAG_AWAY_Y = 550
Global Const $VB_KILL_X = -15878
Global Const $VB_KILL_Y = -7138

Global $varajar_berserkers_farm_setup = False
Global $varajar_margrid_dead = False
Global $varajar_morgahn_dead = False
Global $varajar_log_handle = -1
Global $varajar_log_file = ''
Global $varajar_log_run_number = 0
Global $varajar_log_timer


;~ Main method to farm Norn Berserkers
Func VarajarBerserkersFarm()
	If Not $varajar_berserkers_farm_setup And SetupVarajarBerserkersFarm() == $FAIL Then Return $PAUSE
	$varajar_log_run_number += 1
	VarajarLogInit()
	VarajarLogWrite('run_start', 'setup=' & $varajar_berserkers_farm_setup)
	Local $result = VarajarBerserkersFarmLoop()
	VarajarLogWrite('run_end', 'result=' & $result)
	VarajarLogClose()
	Return $result
EndFunc


;~ Farm setup : travel to Olafstead and prepare player + team
Func SetupVarajarBerserkersFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_OLAFSTEAD, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_HARD_MODE)
	If SetupPlayerVarajarBerserkers() == $FAIL Then Return $FAIL
	If SetupTeamVarajarBerserkers() == $FAIL Then Warn('Could not set up full hero team. Continuing with what is available')
	$varajar_berserkers_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerVarajarBerserkers()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_ASSASSIN Then
		Warn('Should run this farm as assassin')
		Return $FAIL
	EndIf
	If HeroHasTemplate(0, $VARAJAR_BERSERKERS_SKILLBAR) Then
		Info('Varajar Berserkers player: template already loaded, skipping')
	Else
		LoadSkillTemplate($VARAJAR_BERSERKERS_SKILLBAR)
		RandomSleep(250)
	EndIf
	Return $SUCCESS
EndFunc


Func SetupTeamVarajarBerserkers()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up team')
	LeaveParty()

	; Margrid and Morgahn are required; the other five are meat shields
	Local $requiredOk = True
	$requiredOk = $requiredOk And (AddRequiredHero($ID_MARGRID_THE_SLY) == $SUCCESS)
	$requiredOk = $requiredOk And (AddRequiredHero($ID_GENERAL_MORGAHN) == $SUCCESS)

	AddRequiredHero($ID_KOSS)
	AddRequiredHero($ID_MOX)
	AddRequiredHero($ID_MELONNI)
	AddRequiredHero($ID_KAHMU)
	AddRequiredHero($ID_JORA)

	; Load hero builds (skip any that are already loaded)
	VarajarLoadHeroTemplate($VB_MARGRID, $VARAJAR_MARGRID_SKILLBAR, 'Margrid')
	VarajarLoadHeroTemplate($VB_MORGAHN, $VARAJAR_MORGAHN_SKILLBAR, 'Morgahn')
	VarajarLoadHeroTemplate(3, $VARAJAR_KOSS_SKILLBAR, 'Koss')
	VarajarLoadHeroTemplate(4, $VARAJAR_MOX_SKILLBAR, 'MOX')
	VarajarLoadHeroTemplate(5, $VARAJAR_MOX_SKILLBAR, 'Melonni')
	VarajarLoadHeroTemplate(6, $VARAJAR_MOX_SKILLBAR, 'Kahmu')
	VarajarLoadHeroTemplate(7, $VARAJAR_JORA_SKILLBAR, 'Jora')

	; Open only Margrid (hero 1) and Morgahn (hero 2) hero panels
	VarajarOpenHeroPanels()

	; Disable skills that the bot commands manually
	DisableHeroSkillSlot($VB_MARGRID, $VB_MARGRID_EOE)
	DisableHeroSkillSlot($VB_MORGAHN, $VB_MORGAHN_ENDURING_HARMONY)
	DisableHeroSkillSlot($VB_MORGAHN, $VB_MORGAHN_MAKE_HASTE)

	Return $requiredOk ? $SUCCESS : $FAIL
EndFunc


;~ Load a hero template only if it is not already loaded
Func VarajarLoadHeroTemplate($heroIndex, $templateCode, $heroName)
	If HeroHasTemplate($heroIndex, $templateCode) Then
		Info('Varajar Berserkers ' & $heroName & ': template already loaded, skipping')
		Return
	EndIf
	LoadSkillTemplate($templateCode, $heroIndex)
	RandomSleep(150)
EndFunc


;~ Open only Margrid (hero 1) and Morgahn (hero 2) hero panels
Func VarajarOpenHeroPanels()
	CloseAllPanels()
	Sleep(150 + GetPing())
	ToggleHeroPanel(1)
	Sleep(130 + GetPing())
	SupportTeamSendPanelKey('9')
	Sleep(130 + GetPing())
EndFunc


;~ Move out of Olafstead into Varajar Fells
Func VarajarBerserkersGoToZone()
	TravelToOutpost($ID_OLAFSTEAD, $district_name)
	While GetMapID() <> $ID_VARAJAR_FELLS
		Info('Moving to Varajar Fells')
		MoveTo(222, 756)
		Move(-1435, 1217)
		RandomSleep(5000)
		WaitMapLoading($ID_VARAJAR_FELLS, 10000, 2000)
	WEnd
EndFunc


;~ Called while moving to flag critical hero deaths (Margrid + Morgahn) so the run can be aborted
Func VarajarCheckCriticalHeroesAlive()
	If IsHeroDead($VB_MARGRID) Then $varajar_margrid_dead = True
	If IsHeroDead($VB_MORGAHN) Then $varajar_morgahn_dead = True
EndFunc


;~ Run from the Varajar Fells entry to the split spot
Func VarajarBerserkersRunToSplit()
	$varajar_margrid_dead = False
	$varajar_morgahn_dead = False
	Local $route[24][2] = [ _
		[-2252, 831], _
		[-2601, 229], _
		[-3084, -562], _
		[-3322, -1614], _
		[-3326, -2811], _
		[-3319, -2891], _
		[-3051, -2990], _
		[-2639, -3432], _
		[-2944, -3730], _
		[-3426, -3959], _
		[-4042, -4263], _
		[-4519, -4456], _
		[-5132, -4606], _
		[-5747, -4695], _
		[-6612, -3787], _
		[-7405, -2837], _
		[-8057, -3210], _
		[-8816, -3563], _
		[-9678, -4330], _
		[-10497, -4915], _
		[-11374, -5480], _
		[-12226, -6153], _
		[-13098, -6654], _
		[-13523, -6793] _
	]

	For $i = 0 To UBound($route) - 1
		If $varajar_margrid_dead Or $varajar_morgahn_dead Then Return False
		MoveTo($route[$i][0], $route[$i][1], 100, VarajarCheckCriticalHeroesAlive)
		If IsPlayerDead() Then Return False
	Next
	Return True
EndFunc


;~ Split spot choreography : wait, EoE, Enduring Harmony + Make Haste, flag heroes away
Func VarajarBerserkersSplit()
	; Wait for all heroes to catch up
	RandomSleep(3000)

	; Player casts Shroud of Distress (safety) while Margrid plants Edge of Extinction
	UseHeroSkill($VB_MARGRID, $VB_MARGRID_EOE)
	UseSkillEx($VB_SHROUD_OF_DISTRESS)
	RandomSleep(500)

	; Morgahn casts Vocal Was Sogolon, then Enduring Harmony, then Make Haste on the player.
	; Enduring Harmony MUST land before Make Haste (MH gets +50% duration from EH). Use UseHeroSkillEx
	; (waits for the cast to actually start recharging) so the order is deterministic instead of racy.
	UseHeroSkillEx($VB_MORGAHN, $VB_MORGAHN_VOCAL_WAS_SOGOLON)
	PingSleep(200)
	UseHeroSkillEx($VB_MORGAHN, $VB_MORGAHN_ENDURING_HARMONY, GetMyAgent())
	RandomSleep(2000)
	UseHeroSkillEx($VB_MORGAHN, $VB_MORGAHN_MAKE_HASTE, GetMyAgent())
	RandomSleep(500)

	; Flag all heroes far away (back toward the run start) so they cannot loot
	CommandAll($VB_FLAG_AWAY_X, $VB_FLAG_AWAY_Y)
	RandomSleep(500)
EndFunc


;~ Aggro the berserkers, wait for the ball, then spike
Func VarajarBerserkersAggroAndSpike()
	; I Am Unstoppable to avoid knockdown/cripple while aggroing
	UseSkillEx($VB_I_AM_UNSTOPPABLE)
	RandomSleep(100)

	; Run the full aggro path from the split spot to gather all berserkers
	; Densified from path_action_20260904_232725.csv to keep the circle round (no right angles -> avoid Bull's Strike knockdown)
	Local $aggroPath[113][2] = [ _
		[-13523, -6793], _
		[-13628, -6754], _
		[-13947, -6531], _
		[-14298, -6220], _
		[-14662, -5710], _
		[-14975, -4996], _
		[-15209, -4910], _
		[-15263, -4856], _
		[-15322, -4804], _
		[-15358, -4740], _
		[-15378, -4664], _
		[-15423, -4604], _
		[-15479, -4548], _
		[-15533, -4497], _
		[-15594, -4451], _
		[-15667, -4415], _
		[-15739, -4383], _
		[-15812, -4368], _
		[-15887, -4360], _
		[-15969, -4351], _
		[-16043, -4343], _
		[-16121, -4337], _
		[-16200, -4334], _
		[-16276, -4331], _
		[-16358, -4329], _
		[-16434, -4326], _
		[-16509, -4323], _
		[-16587, -4321], _
		[-16666, -4318], _
		[-16743, -4315], _
		[-16822, -4313], _
		[-16894, -4318], _
		[-16963, -4356], _
		[-17006, -4417], _
		[-17046, -4483], _
		[-17085, -4548], _
		[-17127, -4619], _
		[-17166, -4684], _
		[-17204, -4751], _
		[-17240, -4821], _
		[-17272, -4889], _
		[-17304, -4960], _
		[-17338, -5034], _
		[-17369, -5104], _
		[-17374, -5181], _
		[-17397, -5251], _
		[-17429, -5329], _
		[-17458, -5398], _
		[-17496, -5470], _
		[-17538, -5536], _
		[-17583, -5598], _
		[-17632, -5658], _
		[-17683, -5716], _
		[-17736, -5774], _
		[-17789, -5829], _
		[-17842, -5881], _
		[-17902, -5936], _
		[-17971, -5968], _
		[-18029, -6014], _
		[-18087, -6066], _
		[-18146, -6117], _
		[-18203, -6172], _
		[-18251, -6234], _
		[-18286, -6303], _
		[-18308, -6378], _
		[-18295, -6456], _
		[-18251, -6521], _
		[-18194, -6580], _
		[-18134, -6627], _
		[-18072, -6672], _
		[-18008, -6718], _
		[-17942, -6761], _
		[-17877, -6801], _
		[-17808, -6837], _
		[-17735, -6866], _
		[-17665, -6890], _
		[-17589, -6892], _
		[-17513, -6882], _
		[-17438, -6887], _
		[-17361, -6900], _
		[-17288, -6929], _
		[-17219, -6962], _
		[-17150, -7002], _
		[-17096, -7053], _
		[-17088, -7133], _
		[-17094, -7210], _
		[-17099, -7289], _
		[-17095, -7366], _
		[-17067, -7435], _
		[-17037, -7508], _
		[-17005, -7580], _
		[-16973, -7650], _
		[-16939, -7721], _
		[-16899, -7781], _
		[-16856, -7816], _
		[-16801, -7838], _
		[-16741, -7841], _
		[-16713, -7792], _
		[-16689, -7741], _
		[-16654, -7691], _
		[-16620, -7646], _
		[-16583, -7600], _
		[-16550, -7552], _
		[-16519, -7505], _
		[-16480, -7458], _
		[-16438, -7418], _
		[-16392, -7383], _
		[-16341, -7353], _
		[-16291, -7325], _
		[-16040, -7227], _
		[-15941, -7162], _
		[-15841, -7101], _
		[-15878, -7138] _
	]

	; Run the aggro path - all but the final kill-spot waypoint
	For $i = 0 To UBound($aggroPath) - 2
		MoveTo($aggroPath[$i][0], $aggroPath[$i][1])
		If IsPlayerDead() Then Return False
	Next

	; Final approach to the kill spot
	MoveTo($aggroPath[UBound($aggroPath) - 1][0], $aggroPath[UBound($aggroPath) - 1][1])
	If IsPlayerDead() Then Return False
	VarajarLogWrite('spike_stop')

	; Standing still now. Spike order: Protector's Defense (2) -> To The Limit! (7, instant shout for adrenaline)
	; -> Soldier's Defense (3) -> Ebon Battle Standard (4) -> Hundred Blades (5) -> Whirlwind (6)
	UseSkillEx($VB_PROTECTORS_DEFENSE)
	VarajarLogWrite('cast_2', '', $VB_PROTECTORS_DEFENSE)
	UseSkillEx($VB_TO_THE_LIMIT)
	VarajarLogWrite('cast_7', '', $VB_TO_THE_LIMIT)
	UseSkillEx($VB_SOLDIERS_DEFENSE)
	VarajarLogWrite('cast_3', '', $VB_SOLDIERS_DEFENSE)
	UseSkillEx($VB_EBON_BATTLE_STANDARD)
	VarajarLogWrite('cast_4', '', $VB_EBON_BATTLE_STANDARD)
	; Give the ball an extra moment to tighten before the Hundred Blades spike
	RandomSleep(1500)
	UseSkillEx($VB_HUNDRED_BLADES)
	VarajarLogWrite('cast_5', '', $VB_HUNDRED_BLADES)

	; Auto-attack to top up adrenaline for Whirlwind Attack (6), then fire it
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	If $target <> Null Then
		ChangeTarget($target)
		Local $wwTimer = TimerInit()
		While IsPlayerAlive() And GetSkillbarSkillAdrenaline($VB_WHIRLWIND_ATTACK) < 130 And TimerDiff($wwTimer) < 8000
			Attack($target)
			VarajarLogWrite('pre6_spam', 'adrenaline=' & GetSkillbarSkillAdrenaline($VB_WHIRLWIND_ATTACK))
			RandomSleep(150)
		WEnd
		If IsPlayerAlive() And GetSkillbarSkillAdrenaline($VB_WHIRLWIND_ATTACK) >= 130 Then
			UseSkillEx($VB_WHIRLWIND_ATTACK, $target)
			VarajarLogWrite('cast_6', 'adrenaline=' & GetSkillbarSkillAdrenaline($VB_WHIRLWIND_ATTACK))
		Else
			VarajarLogWrite('cast_6_fail', 'adrenaline=' & GetSkillbarSkillAdrenaline($VB_WHIRLWIND_ATTACK))
		EndIf
	EndIf

	; Loot immediately after the spike - do not wait for stragglers, they can kill us
	PickUpItems()

	Return True
EndFunc


;~ Farm loop : one full run
Func VarajarBerserkersFarmLoop()
	VarajarBerserkersGoToZone()
	If GetMapID() <> $ID_VARAJAR_FELLS Then Return $FAIL

	If Not VarajarBerserkersRunToSplit() Then
		If $varajar_margrid_dead Then Info('Margrid died during the run - resigning and restarting')
		If $varajar_morgahn_dead Then Info('Morgahn died during the run - resigning and restarting')
		ResignAndReturnToOutpost($ID_OLAFSTEAD)
		Return $FAIL
	EndIf
	VarajarBerserkersSplit()
	If Not VarajarBerserkersAggroAndSpike() Then Return $FAIL

	Info('Picking up loot')
	RandomSleep(1000)
	PickUpItems()

	ResignAndReturnToOutpost($ID_OLAFSTEAD)
	Return $SUCCESS
EndFunc


;~ CSV debug logging (MissingDaughter style) so spike timing and skill-5 delays
;~ are visible per run. Columns include the Whirlwind Attack (6) adrenaline so
;~ we can see exactly when it is ready to fire.
Func VarajarLogInit()
	Local $timestamp = @YEAR & @MON & @MDAY & '_' & @HOUR & @MIN & @SEC
	$varajar_log_file = @ScriptDir & '/logs/varajar_berserkers_debug-' & GetCharacterName() & '-run' & $varajar_log_run_number & '-' & $timestamp & '.csv'
	$varajar_log_handle = FileOpen($varajar_log_file, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	$varajar_log_timer = TimerInit()
	Info('Varajar Berserkers CSV: ' & $varajar_log_file)
	If $varajar_log_handle == -1 Then Return
	FileWriteLine($varajar_log_handle, 'time_ms;run;event;energy;hp;map_id;x;y;skill;skill_ready;casting;adrenaline6;note')
EndFunc


Func VarajarLogClose()
	If $varajar_log_handle == -1 Then Return
	FileClose($varajar_log_handle)
	$varajar_log_handle = -1
EndFunc


Func VarajarLogWrite($eventName, $note = '', $skillSlot = -1)
	If $varajar_log_handle == -1 Then Return
	Local $timeMs = Int(TimerDiff($varajar_log_timer))
	Local $me = GetMyAgent()
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')
	Local $energy = Round(GetEnergy(), 1)
	Local $hp = Round(DllStructGetData($me, 'HealthPercent'), 3)
	Local $mapID = GetMapID()
	Local $skillReady = -1
	If $skillSlot > 0 Then $skillReady = IsRecharged($skillSlot) ? 1 : 0
	Local $adrenaline6 = GetSkillbarSkillAdrenaline($VB_WHIRLWIND_ATTACK)
	Local $safeNote = StringReplace(StringReplace($note, ';', ','), @CRLF, ' ')
	FileWriteLine($varajar_log_handle, $timeMs & ';' & $varajar_log_run_number & ';' & $eventName & ';' & $energy & ';' & $hp & ';' & $mapID & ';' & $x & ';' & $y & ';' & $skillSlot & ';' & $skillReady & ';' & (IsCasting($me) ? 1 : 0) & ';' & $adrenaline6 & ';' & $safeNote)
EndFunc
