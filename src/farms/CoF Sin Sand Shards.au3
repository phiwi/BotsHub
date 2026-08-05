#CS ===========================================================================
; Authors: DeeperBlue, unknown (Dervish original)
; Contributor: Gahais, GitHub Copilot (Assassin adaptation)
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
; Cathedral of Flames — Assassin variant using Deadly Paradox + Shadow Form
; for permanent spell immunity (replaces Dervish Vow of Silence).
; This "Sand Shards" variant trades Grenth's Aura for Sand Shards (AoE damage).
; Perma maintenance is adapted from FocusHanaku.au3.
#CE ===========================================================================

#include-once
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID_Quests.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'


; ==== Constants ====
Global Const $COFSINSS_PLAYER_SKILLBAR = 'Owpl8xjWaqSrGxjozcANG6cZeVDiJC'
Global Const $COFSINSS_FARM_INFORMATIONS = 'CoF Assassin Sand Shards variant — perma Shadow Form + Critical Agility (IAS) + Sand Shards (AoE).' & @CRLF _
	& '- Zealous Scythe of Enchanting (20% longer enchantments duration)' & @CRLF _
	& '- +1+3 Shadow Arts Rune' & @CRLF _
	& '- +1 Deadly Arts Rune' & @CRLF _
	& '- +1 Scythe Mastery Rune' & @CRLF _
	& '- +50 HP Rune' & @CRLF _
	& '- +2 Energy Rune' & @CRLF _
	& '- Windwalker or blessed insignias' & @CRLF _
	& '- This bot enters the Quest Temple of the Damned, but bot does not finish it' & @CRLF _
	& '- This bot farms Golden Rin Relics and Diessa Chalices and bones in the Cathedral of Flames' & @CRLF _
	& 'This farm bot is based on below articles:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:D/any_General_Vow_of_Silence_Farmer' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:A/any_Perma_Shadow_Form'
Global Const $COFSINSS_FARM_DURATION = 5 * 60 * 1000


; === Dialogs (same as Dervish CoF) ===
Global Const $COFSINSS_QUEST_INIT_DIALOG = 0x832103
Global Const $COFSINSS_QUEST_ACCEPT_DIALOG = 0x832101
Global Const $COFSINSS_ENTER_INIT_DIALOG = 0x832105
Global Const $COFSINSS_ENTER_ACCEPT_DIALOG = 0x88

Global Const $COFSINSS_MODELID_MURAKAI_SERVANT	= 7069
Global Const $COFSINSS_MODELID_CRYPT_GHOUL		= 7075
Global Const $COFSINSS_MODELID_CRYPT_SLASHER	= 7077
Global Const $COFSINSS_MODELID_CRYPT_WRAITH		= 7079
Global Const $COFSINSS_MODELID_CRYPT_BANSHEE	= 7081
Global Const $COFSINSS_MODELID_SHOCK_PHANTOM	= 7083
Global Const $COFSINSS_MODELID_ASH_PHANTOM		= 7085

; Skill slots (template Owpl8xjWaqSrGxjozcANG6cZeVDiJC — Sand Shards at slot 6)
Global Const $COFSINSS_DEADLY_PARADOX			= 1
Global Const $COFSINSS_SHADOW_FORM				= 2
Global Const $COFSINSS_SHROUD_OF_DISTRESS		= 3
Global Const $COFSINSS_CRIPPLING_VICTORY		= 4
Global Const $COFSINSS_REAP_IMPURITIES			= 5
Global Const $COFSINSS_SAND_SHARDS				= 6
Global Const $COFSINSS_CRITICAL_AGILITY			= 7
Global Const $COFSINSS_SIGNET_OF_MYSTIC_SPEED	= 8

; Perma SF+DP timing (same rhythm as FocusHanaku)
Global Const $COFSINSS_SF_DP_MIN_ENERGY = 20
Global Const $COFSINSS_DP_AFTER_SF_DELAY_MS = 500
Global Const $COFSINSS_SF_QUEUE_RETRY_MS = 1500 ; Guard against Adlib re-cast during DP delay
Global Const $COFSINSS_COMBAT_TIMEOUT_MS = 10 * 60 * 1000 ; Abort combat after 10 min
Global Const $COFSINSS_SAND_SHARDS_MIN_ENERGY = 20

Global $cofsinss_farm_setup = False
Global $cofsinss_log_handle = -1
Global $cofsinss_log_timer = 0
Global $cofsinss_log_run = 0


;~ Main loop of the Cathedral of Flames farm (Assassin Sand Shards)
Func CoFSinSSFarm()
	$cofsinss_log_run += 1
	CoFSinSSLogInit()
	CoFSinSSLogWrite('run_start')

	If Not $cofsinss_farm_setup And SetupCoFSinSSFarm() == $FAIL Then
		CoFSinSSLogWrite('run_end', 'result=fail;reason=setup')
		CoFSinSSLogClose()
		Return $PAUSE
	EndIf
	Sleep(10000)
	GoToCathedralOfFlamesSinSS()
	Local $result = CoFSinSSFarmLoop()
	CoFSinSSLogWrite('run_end', 'result=' & $result)
	CoFSinSSLogClose()
	ResignAndReturnToOutpost($ID_DOOMLORE_SHRINE)
	Return $result
EndFunc


;~ Farm setup : going to the Doomlore Shrine
Func SetupCoFSinSSFarm()
	Info('Setting up CoF Sin Sand Shards farm')
	If TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerCoFSinSSFarm() == $FAIL Then Return $FAIL
	LeaveParty()
	GoToCathedralOfFlamesSinSS()
	RandomSleep(2500)
	Move(-19300, -8250)
	RandomSleep(2500)
	WaitMapLoading($ID_DOOMLORE_SHRINE, 10000, 2500)
	$cofsinss_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerCoFSinSSFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
		If HeroHasTemplate(0, $COFSINSS_PLAYER_SKILLBAR) Then
			Info('CoF Sin Sand Shards player: template already loaded, skipping')
		Else
			LoadSkillTemplate($COFSINSS_PLAYER_SKILLBAR)
		EndIf
		RandomSleep(250)
	Else
		Warn('Should run this farm as assassin')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Exit outpost to enter Cathedral of Flames mission
Func GoToCathedralOfFlamesSinSS()
	TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name)
	While GetMapID() <> $ID_CATHEDRAL_OF_FLAMES
		Info('Entering Cathedral of Flames')
		Local $gron = GetNearestNPCToCoords(-19166, 17980)
		GoToNPC($gron)
		If IsQuestNotFound($ID_QUEST_TEMPLE_OF_THE_DAMNED) Then
			TakeQuest($gron, $ID_QUEST_TEMPLE_OF_THE_DAMNED, $COFSINSS_QUEST_ACCEPT_DIALOG, $COFSINSS_QUEST_INIT_DIALOG)
			Sleep(1000)
		EndIf
		Dialog($COFSINSS_ENTER_INIT_DIALOG)
		Sleep(1000)
		Dialog($COFSINSS_ENTER_ACCEPT_DIALOG)
		WaitMapLoading($ID_CATHEDRAL_OF_FLAMES)
	WEnd
EndFunc


;~ Farm loop of Cathedral of Flames (Assassin Sand Shards)
Func CoFSinSSFarmLoop()
	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-18250, -8595))
	Sleep(500)
	Dialog(0x84)
	Sleep(500)

	AggroAndPrepareSinSS()
	Info('Farming Cryptos')
	AdlibRegister('MaintainCoFSinSSPermaAdlib', 200)
	CleanCoFSinSSMobs()
	AdlibUnRegister('MaintainCoFSinSSPermaAdlib')
	If IsPlayerDead() Then Return $FAIL

	Info('Picking up loot')
	PickUpItems()
	Return $SUCCESS
EndFunc


Func AggroAndPrepareSinSS()
	MoveTo(-16850, -8930)
	; Open with SF + DP (the core perma chain from Hanaku).
	If IsRecharged($COFSINSS_SHADOW_FORM) Then UseSkill($COFSINSS_SHADOW_FORM)
	RandomSleep($COFSINSS_DP_AFTER_SF_DELAY_MS)
	If IsRecharged($COFSINSS_DEADLY_PARADOX) Then UseSkill($COFSINSS_DEADLY_PARADOX)
	; Shroud of Distress replaces Vow of Piety as the defensive layer.
	If IsRecharged($COFSINSS_SHROUD_OF_DISTRESS) Then UseSkillEx($COFSINSS_SHROUD_OF_DISTRESS)
	RandomSleep(80)
	; Critical Agility for IAS (replaces IAU).
	If IsRecharged($COFSINSS_CRITICAL_AGILITY) Then UseSkillEx($COFSINSS_CRITICAL_AGILITY)
	RandomSleep(80)
	; Signet of Mystic Speed.
	If IsRecharged($COFSINSS_SIGNET_OF_MYSTIC_SPEED) Then UseSkillEx($COFSINSS_SIGNET_OF_MYSTIC_SPEED)
	RandomSleep(80)
	MoveTo(-15220, -8950)
	Sleep(500)
EndFunc


;~ AdlibRegister wrapper: calls perma maintenance with utility casts allowed.
Func MaintainCoFSinSSPermaAdlib()
	MaintainCoFSinSSPerma(True)
EndFunc


;~ Maintain permament Shadow Form via Deadly Paradox (adapted from FocusHanaku.au3).
;~ Also refreshes Shroud of Distress, Sand Shards and Critical Agility when needed.
;~ @param $allowUtilityCasts - when True, utility enchants are recast on expiry.
Func MaintainCoFSinSSPerma($allowUtilityCasts = True)
	If IsPlayerDead() Then Return
	Local Static $sfQueueTimer = Null

	Local $sfRechargedNow = IsRecharged($COFSINSS_SHADOW_FORM)
	Local $energyNow = GetEnergy()

	; Cast DP first, wait 0.5s, then cast SF — so SF snapshots DP's 33% faster recharge.
	If $sfRechargedNow And $energyNow >= $COFSINSS_SF_DP_MIN_ENERGY And ($sfQueueTimer == Null Or TimerDiff($sfQueueTimer) > $COFSINSS_SF_QUEUE_RETRY_MS) Then
		If IsRecharged($COFSINSS_DEADLY_PARADOX) Then
			CoFSinSSLogWrite('dp_cast', 'e=' & Int($energyNow))
			UseSkill($COFSINSS_DEADLY_PARADOX)
			$sfQueueTimer = TimerInit()
			Local $sfTimer = TimerInit()
			While IsPlayerAlive() And TimerDiff($sfTimer) < $COFSINSS_DP_AFTER_SF_DELAY_MS
				Sleep(10)
			WEnd
			CoFSinSSLogWrite('sf_cast', 'delta_ms=' & Int(TimerDiff($sfQueueTimer)) & ';e=' & Int(GetEnergy()))
			UseSkill($COFSINSS_SHADOW_FORM)
		Else
			CoFSinSSLogWrite('sf_skip', 'reason=dp_not_ready;e=' & Int($energyNow))
		EndIf
		Return
	EndIf

	; Shroud of Distress — keep it up (replaces Vow of Piety).
	If $allowUtilityCasts And IsRecharged($COFSINSS_SHROUD_OF_DISTRESS) Then
		Local $sodRemaining = GetEffectTimeRemaining($ID_SHROUD_OF_DISTRESS)
		If $sodRemaining <= 2500 Then
			CoFSinSSLogWrite('sod_cast', 'remaining_ms=' & Int($sodRemaining))
			UseSkillEx($COFSINSS_SHROUD_OF_DISTRESS)
		EndIf
	EndIf

	; Critical Agility — IAS enchantment; self-renews on crit, but recast if it falls off.
	If $allowUtilityCasts And IsRecharged($COFSINSS_CRITICAL_AGILITY) And GetEnergy() > 12 Then
		If GetEffectTimeRemaining($ID_CRITICAL_AGILITY) <= 500 Then
			CoFSinSSLogWrite('ca_cast')
			UseSkillEx($COFSINSS_CRITICAL_AGILITY)
		EndIf
	EndIf

	; Sand Shards — AoE damage on scythe hits; cast when recharged and energy allows.
	If $allowUtilityCasts And IsRecharged($COFSINSS_SAND_SHARDS) And GetEnergy() > $COFSINSS_SAND_SHARDS_MIN_ENERGY Then
		CoFSinSSLogWrite('ss_cast', 'e=' & Int(GetEnergy()))
		UseSkillEx($COFSINSS_SAND_SHARDS)
	EndIf
EndFunc


Func CleanCoFSinSSMobs()
	Local $target = GetNearestAgentToAgent(GetMyAgent(), $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsUndeadSinSS)
	Local $clock = False
	Local $logHeartbeat = TimerInit()
	Local $combatTimer = TimerInit()
	While $target <> Null And GetDistance(GetMyAgent(), $target) < $MOB_AGGRO_RANGE And TimerDiff($combatTimer) < $COFSINSS_COMBAT_TIMEOUT_MS
		If TimerDiff($logHeartbeat) > 3000 Then
			Local $sfMs = GetEffectTimeRemaining($ID_SHADOW_FORM)
			Local $dpReady = IsRecharged($COFSINSS_DEADLY_PARADOX)
			Local $sfReady = IsRecharged($COFSINSS_SHADOW_FORM)
			CoFSinSSLogWrite('combat_tick', 'sf_ms=' & Int($sfMs) & ';sf_ready=' & $sfReady & ';dp_ready=' & $dpReady & ';e=' & Int(GetEnergy()) & ';hp=' & StringFormat('%.2f', DllStructGetData(GetMyAgent(), 'HealthPercent')) & ';a4=' & GetSkillbarSkillAdrenaline($COFSINSS_CRIPPLING_VICTORY) & ';a5=' & GetSkillbarSkillAdrenaline($COFSINSS_REAP_IMPURITIES))
			$logHeartbeat = TimerInit()
		EndIf
		; Check perma BEFORE blocking skill casts — SF window is tight (~1.4s)
		MaintainCoFSinSSPerma()
		If Not $clock And GetSkillbarSkillAdrenaline($COFSINSS_CRIPPLING_VICTORY) >= 150 Then
			CoFSinSSLogWrite('cv_cast')
			UseSkillEx($COFSINSS_CRIPPLING_VICTORY, $target)
			$clock = True
		ElseIf $clock And GetSkillbarSkillAdrenaline($COFSINSS_REAP_IMPURITIES) >= 120 Then
			CoFSinSSLogWrite('reap_cast')
			UseSkillEx($COFSINSS_REAP_IMPURITIES, $target)
			$clock = False
		Else
			Attack($target)
			Sleep(200)
		EndIf
		MaintainCoFSinSSPerma()
		Sleep(100)
		If IsPlayerDead() Then Return $FAIL
		$target = GetNearestAgentToAgent(GetMyAgent(), $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsUndeadSinSS)
	WEnd
	If TimerDiff($combatTimer) >= $COFSINSS_COMBAT_TIMEOUT_MS Then
		CoFSinSSLogWrite('combat_timeout', 'elapsed_ms=' & Int(TimerDiff($combatTimer)))
		Warn('CoF Sin Sand Shards: combat timeout after ' & Int(TimerDiff($combatTimer) / 1000) & 's')
	EndIf
	RandomSleep(200)
EndFunc


Func IsUndeadSinSS($agent)
	Local $modelID = DllStructGetData($agent, 'ModelID')
	Return Not GetIsDead($agent) And DllStructGetData($agent, 'HealthPercent') > 0 And _
		($modelID == $COFSINSS_MODELID_MURAKAI_SERVANT Or $modelID == $COFSINSS_MODELID_CRYPT_GHOUL _
		Or $modelID == $COFSINSS_MODELID_CRYPT_SLASHER Or $modelID == $COFSINSS_MODELID_CRYPT_WRAITH _
		Or $modelID == $COFSINSS_MODELID_CRYPT_BANSHEE Or $modelID == $COFSINSS_MODELID_SHOCK_PHANTOM _
		Or $modelID == $COFSINSS_MODELID_ASH_PHANTOM)
EndFunc


#Region Debug CSV logging
Func CoFSinSSLogInit()
	Local $timestamp = @YEAR & @MON & @MDAY & '_' & @HOUR & @MIN & @SEC
	Local $path = @ScriptDir & '/logs/cofsinss_debug-' & GetCharacterName() & '-run' & $cofsinss_log_run & '-' & $timestamp & '.csv'
	$cofsinss_log_handle = FileOpen($path, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	$cofsinss_log_timer = TimerInit()
	If $cofsinss_log_handle == -1 Then Return
	Info('CoF Sin Sand Shards CSV: ' & $path)
	FileWriteLine($cofsinss_log_handle, 'time_ms;run;event;energy;hp;sf_ms;sod_ms;ca_ms;sf_ready;dp_ready;sod_ready;a4;a5;note')
EndFunc

Func CoFSinSSLogClose()
	If $cofsinss_log_handle == -1 Then Return
	FileClose($cofsinss_log_handle)
	$cofsinss_log_handle = -1
EndFunc

Func CoFSinSSLogWrite($eventName, $note = '')
	If $cofsinss_log_handle == -1 Then Return
	Local $timeMs = Int(TimerDiff($cofsinss_log_timer))
	Local $me = GetMyAgent()
	Local $energy = GetEnergy()
	Local $hp = DllStructGetData($me, 'HealthPercent')
	Local $sfMs = GetEffectTimeRemaining($ID_SHADOW_FORM)
	Local $sodMs = GetEffectTimeRemaining($ID_SHROUD_OF_DISTRESS)
	Local $caMs = GetEffectTimeRemaining($ID_CRITICAL_AGILITY)
	Local $sfReady = IsRecharged($COFSINSS_SHADOW_FORM)
	Local $dpReady = IsRecharged($COFSINSS_DEADLY_PARADOX)
	Local $sodReady = IsRecharged($COFSINSS_SHROUD_OF_DISTRESS)
	Local $a4 = GetSkillbarSkillAdrenaline($COFSINSS_CRIPPLING_VICTORY)
	Local $a5 = GetSkillbarSkillAdrenaline($COFSINSS_REAP_IMPURITIES)
	Local $safeNote = StringReplace($note, ';', ',')
	FileWriteLine($cofsinss_log_handle, $timeMs & ';' & $cofsinss_log_run & ';' & $eventName & ';' & $energy & ';' & $hp & ';' & $sfMs & ';' & $sodMs & ';' & $caMs & ';' & $sfReady & ';' & $dpReady & ';' & $sodReady & ';' & $a4 & ';' & $a5 & ';' & $safeNote)
EndFunc
#EndRegion Debug CSV logging
