#CS ===========================================================================
; Authors: DeeperBlue, unknown
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
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID_Quests.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'


; ==== Constants ====
Global Const $D_COF_SKILLBAR = 'OgCjkqqLrSihdftXYijhOXhX0kA'
Global Const $COF_SIN_PLAYER_SKILLBAR = 'Owpk8xjYaqWEPiOzB0YozV3XNImI'
Global Const $COF_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- +1+3 Wind Prayers Rune' &@CRLF _
	& '- +1 Mystisicm Rune' & @CRLF _
	& '- +1 Scythe Mastery Runed' & @CRLF _
	& '- +50 HP Rune' & @CRLF _
	& '- +2 Energy Rune' & @CRLF _
	& '- Windwalker or blessed insignias'& @CRLF _
	& '- Zealous Scythe of Enchanting (20% longer enchantments duration) with a random inscription' & @CRLF _
	& '- This bot enters the Quest Temple of the Damned, but bot does not finish it' & @CRLF _
	& '- This bot farms Golden Rin Relics and Diessa Chalices and bones in the Cathedral of Flames' & @CRLF _
	& '- If you do not have I Am Unstoppable skill then it is no problem, bot will still work, but the fail rate will increase slightly' & @CRLF _
	& 'This farm bot is based on below article:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:D/any_General_Vow_of_Silence_Farmer' & @CRLF
Global Const $COF_FARM_DURATION = 5 * 60 * 1000
Global Const $COF_SIN_FARM_INFORMATIONS = 'CoF Assassin — perma Shadow Form + Critical Agility (IAS).' & @CRLF _
	& '- Zealous Scythe of Enchanting (20% longer enchantments duration)' & @CRLF _
	& '- +1+3 Shadow Arts Rune' & @CRLF _
	& '- +1 Deadly Arts Rune' & @CRLF _
	& '- +1 Scythe Mastery Rune' & @CRLF _
	& '- +50 HP Rune, +2 Energy Rune' & @CRLF _
	& '- Windwalker or blessed insignias' & @CRLF _
	& 'This farm bot is based on below articles:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:D/any_General_Vow_of_Silence_Farmer' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:A/any_Perma_Shadow_Form'


; === Dialogs ===
Global Const $QUEST_INIT_DIALOG = 0x832103
Global Const $QUEST_ACCEPT_DIALOG = 0x832101
Global Const $ENTER_INIT_DIALOG = 0x832105
Global Const $ENTER_ACCEPT_DIALOG = 0x88

Global Const $MODELID_MURAKAI_SERVANT	= 7069
Global Const $MODELID_CRYPT_GHOUL		= 7075
Global Const $MODELID_CRYPT_SLASHER		= 7077
Global Const $MODELID_CRYPT_WRAITH		= 7079
Global Const $MODELID_CRYPT_BANSHEE		= 7081
Global Const $MODELID_SHOCK_PHANTOM		= 7083
Global Const $MODELID_ASH_PHANTOM		= 7085

; Skill numbers declared to make the code WAY more readable (UseSkillEx($SKILL_CONVICTION is better than UseSkillEx(1))
Global Const $COF_PIOUS_FURY				= 1
Global Const $COF_GRENTHS_AURA				= 2
Global Const $COF_VOW_OF_SILENCE			= 3
Global Const $COF_SIGNET_OF_MYSTIC_SPEED	= 4
Global Const $COF_CRIPPLING_VICTORY			= 5
Global Const $COF_REAP_IMPURITIES			= 6
Global Const $COF_VOW_OF_PIETY				= 7
Global Const $COF_I_AM_UNSTOPPABLE			= 8

; Assassin skill slots (template Owpk8xjYaqWEPiOzB0YozV3XNImI)
Global Const $COF_SIN_DEADLY_PARADOX			= 1
Global Const $COF_SIN_SHADOW_FORM				= 2
Global Const $COF_SIN_SHROUD_OF_DISTRESS		= 3
Global Const $COF_SIN_CRIPPLING_VICTORY		= 4
Global Const $COF_SIN_REAP_IMPURITIES			= 5
Global Const $COF_SIN_GRENTHS_AURA				= 6
Global Const $COF_SIN_CRITICAL_AGILITY			= 7
Global Const $COF_SIN_SIGNET_OF_MYSTIC_SPEED	= 8

Global Const $COF_SIN_SF_DP_MIN_ENERGY = 20
Global Const $COF_SIN_DP_AFTER_SF_DELAY_MS = 500
Global Const $COF_SIN_SF_QUEUE_RETRY_MS = 1500
Global Const $COF_SIN_COMBAT_TIMEOUT_MS = 10 * 60 * 1000
Global Const $COF_SIN_DEBUG_LOG = False ; Set to True to enable CSV debug logging

Global $cof_farm_setup = False
Global $cof_sin_log_handle = -1
Global $cof_sin_log_timer = 0
Global $cof_sin_log_run = 0
Global $cof_vos_timer = Null

;~ Main loop of the Cathedral of Flames farm
Func CoFFarm()
	If Not $cof_farm_setup And SetupCoFFarm() == $FAIL Then Return $PAUSE
	Sleep(10000)
	GoToCathedralOfFlames()
	Local $result = CoFFarmLoop()
	ResignAndReturnToOutpost($ID_DOOMLORE_SHRINE)
	Return $result
EndFunc


;~ Farm setup : going to the Doomlore Shrine
Func SetupCoFFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerCoFFarm() == $FAIL Then Return $FAIL
	LeaveParty()
	GoToCathedralOfFlames()
	RandomSleep(2500)
	Move(-19300, -8250)
	RandomSleep(2500)
	WaitMapLoading($ID_DOOMLORE_SHRINE, 10000, 2500)
	$cof_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerCoFFarm()
	Info('Setting up player build skill bar')
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		Case $ID_DERVISH
			If HeroHasTemplate(0, $D_COF_SKILLBAR) Then
				Info('CoF Dervish: template already loaded, skipping')
			Else
				LoadSkillTemplate($D_COF_SKILLBAR)
				RandomSleep(250)
			EndIf
		Case $ID_ASSASSIN
			If HeroHasTemplate(0, $COF_SIN_PLAYER_SKILLBAR) Then
				Info('CoF Sin: template already loaded, skipping')
			Else
				LoadSkillTemplate($COF_SIN_PLAYER_SKILLBAR)
				RandomSleep(250)
			EndIf
		Case Else
			Warn('Should run this farm as dervish or assassin')
			Return $FAIL
	EndSwitch
	Return $SUCCESS
EndFunc


;~ Exit outpost to enter Cathedral of Flames mission
Func GoToCathedralOfFlames()
	TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name)
	While GetMapID() <> $ID_CATHEDRAL_OF_FLAMES
		Info('Entering Cathedral of Flames')
		Local $gron = GetNearestNPCToCoords(-19166, 17980)
		GoToNPC($gron)
		If IsQuestNotFound($ID_QUEST_TEMPLE_OF_THE_DAMNED) Then
			TakeQuest($gron, $ID_QUEST_TEMPLE_OF_THE_DAMNED, $QUEST_ACCEPT_DIALOG, $QUEST_INIT_DIALOG)
			Sleep(1000)
		EndIf
		Dialog($ENTER_INIT_DIALOG)
		Sleep(1000)
		Dialog($ENTER_ACCEPT_DIALOG)
		WaitMapLoading($ID_CATHEDRAL_OF_FLAMES)
	WEnd
EndFunc


;~ Farm loop of Cathedral of Flames
Func CoFFarmLoop()
	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-18250, -8595))
	Sleep(500)
	Dialog(0x84)
	Sleep(500)

	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
		Return CoFSinFarmLoop()
	EndIf

	AggroAndPrepare()
	Info('Farming Cryptos')
	CheckVoS()
	CleanCoFMobs()
	If IsPlayerDead() Then Return $FAIL

	Info('Picking up loot')
	PickUpItems()
	Return $SUCCESS
EndFunc


Func AggroAndPrepare()
	MoveTo(-16850, -8930)
	UseSkillEx($COF_VOW_OF_PIETY)
	While IsPlayerAlive() And IsRecharged($COF_GRENTHS_AURA)
		UseSkillEx($COF_GRENTHS_AURA)
		RandomSleep(50)
	WEnd
	UseSkillEx($COF_VOW_OF_SILENCE)
	$cof_vos_timer = TimerInit()
	UseSkillEx($COF_SIGNET_OF_MYSTIC_SPEED)
	MoveTo(-15220, -8950)
	UseSkillEx($COF_I_AM_UNSTOPPABLE)
	Sleep(500)
EndFunc


;~ Ensure that Vow of Silence enchantment is active
Func CheckVoS()
	If $cof_vos_timer == Null Or TimerDiff($cof_vos_timer) >= 10000 Then
		UseSkillEx($COF_PIOUS_FURY)
		While IsPlayerAlive() And IsRecharged($COF_GRENTHS_AURA)
			UseSkillEx($COF_GRENTHS_AURA)
			RandomSleep(50)
		WEnd
		UseSkillEx($COF_VOW_OF_SILENCE)
		$cof_vos_timer = TimerInit()
	EndIf
EndFunc


Func CleanCoFMobs()
	Local $target = GetNearestAgentToAgent(GetMyAgent(), $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsUndead)
	Local $clock = False
	While $target <> Null And GetDistance(GetMyAgent(), $target) < $MOB_AGGRO_RANGE
		If Not $clock And GetSkillbarSkillAdrenaline($COF_CRIPPLING_VICTORY) >= 150 Then
			UseSkillEx($COF_CRIPPLING_VICTORY, $target)
			$clock = True
			;RandomSleep(800)
		ElseIf $clock And GetSkillbarSkillAdrenaline($COF_REAP_IMPURITIES) >= 120 Then
			UseSkillEx($COF_REAP_IMPURITIES, $target)
			$clock = False
			;RandomSleep(800)
		Else
			Attack($target)
			Sleep(200)
		EndIf
		CheckVoS()
		Sleep(100)
		If IsPlayerDead() Then Return $FAIL
		$target = GetNearestAgentToAgent(GetMyAgent(), $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsUndead)
	WEnd
	RandomSleep(200)
EndFunc


Func IsUndead($agent)
	Local $modelID = DllStructGetData($agent, 'ModelID')
	Return Not GetIsDead($agent) And DllStructGetData($agent, 'HealthPercent') > 0 And _
		($modelID == $MODELID_MURAKAI_SERVANT Or $modelID == $MODELID_CRYPT_GHOUL _
		Or $modelID == $MODELID_CRYPT_SLASHER Or $modelID == $MODELID_CRYPT_WRAITH _
		Or $modelID == $MODELID_CRYPT_BANSHEE Or $modelID == $MODELID_SHOCK_PHANTOM _
		Or $modelID == $MODELID_ASH_PHANTOM)


; ============================================================
; Assassin SinCA variant
; ============================================================
Func CoFSinFarmLoop()
	$cof_sin_log_run += 1
	CoFSinLogInit()
	CoFSinLogWrite('run_start')

	AggroAndPrepareSinCA()
	Info('Farming Cryptos')
	CleanCoFSinMobs()
	If IsPlayerDead() Then
		CoFSinLogWrite('run_end', 'result=fail;reason=dead')
		CoFSinLogClose()
		Return $FAIL
	EndIf

	Info('Picking up loot')
	PickUpItems()
	CoFSinLogWrite('run_end', 'result=0')
	CoFSinLogClose()
	Return $SUCCESS
EndFunc


Func AggroAndPrepareSinCA()
	MoveTo(-16850, -8930)
	If IsRecharged($COF_SIN_DEADLY_PARADOX) Then UseSkill($COF_SIN_DEADLY_PARADOX)
	RandomSleep($COF_SIN_DP_AFTER_SF_DELAY_MS)
	If IsRecharged($COF_SIN_SHADOW_FORM) Then UseSkill($COF_SIN_SHADOW_FORM)
	If IsRecharged($COF_SIN_SHROUD_OF_DISTRESS) Then UseSkillEx($COF_SIN_SHROUD_OF_DISTRESS)
	RandomSleep(80)
	If IsRecharged($COF_SIN_CRITICAL_AGILITY) Then UseSkillEx($COF_SIN_CRITICAL_AGILITY)
	RandomSleep(80)
	If IsRecharged($COF_SIN_SIGNET_OF_MYSTIC_SPEED) Then UseSkillEx($COF_SIN_SIGNET_OF_MYSTIC_SPEED)
	RandomSleep(80)
	MoveTo(-15220, -8950)
	Sleep(500)
EndFunc


Func MaintainCoFSinPerma($allowUtilityCasts = True)
	If IsPlayerDead() Then Return
	Local Static $sfQueueTimer = Null
	Local $sfRechargedNow = IsRecharged($COF_SIN_SHADOW_FORM)
	Local $energyNow = GetEnergy()

	If $sfRechargedNow And $energyNow >= $COF_SIN_SF_DP_MIN_ENERGY And ($sfQueueTimer == Null Or TimerDiff($sfQueueTimer) > $COF_SIN_SF_QUEUE_RETRY_MS) Then
		If IsRecharged($COF_SIN_DEADLY_PARADOX) Then
			CoFSinLogWrite('dp_cast', 'e=' & Int($energyNow))
			UseSkill($COF_SIN_DEADLY_PARADOX)
			$sfQueueTimer = TimerInit()
			Local $sfTimer = TimerInit()
			While IsPlayerAlive() And TimerDiff($sfTimer) < $COF_SIN_DP_AFTER_SF_DELAY_MS
				Sleep(10)
			WEnd
			CoFSinLogWrite('sf_cast', 'delta_ms=' & Int(TimerDiff($sfQueueTimer)) & ';e=' & Int(GetEnergy()))
			UseSkill($COF_SIN_SHADOW_FORM)
		Else
			CoFSinLogWrite('sf_skip', 'reason=dp_not_ready;e=' & Int($energyNow))
		EndIf
		Return
	EndIf

	If $allowUtilityCasts And IsRecharged($COF_SIN_SHROUD_OF_DISTRESS) Then
		Local $sodRemaining = GetEffectTimeRemaining($ID_SHROUD_OF_DISTRESS)
		If $sodRemaining <= 2500 Then
			CoFSinLogWrite('sod_cast', 'remaining_ms=' & Int($sodRemaining))
			UseSkillEx($COF_SIN_SHROUD_OF_DISTRESS)
		EndIf
	EndIf

	If $allowUtilityCasts And IsRecharged($COF_SIN_CRITICAL_AGILITY) And GetEnergy() > 12 Then
		If GetEffectTimeRemaining($ID_CRITICAL_AGILITY) <= 500 Then
			CoFSinLogWrite('ca_cast')
			UseSkillEx($COF_SIN_CRITICAL_AGILITY)
		EndIf
	EndIf

	If $allowUtilityCasts And IsRecharged($COF_SIN_GRENTHS_AURA) And GetEnergy() > 24 Then
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.90 Then
			CoFSinLogWrite('ga_cast', 'hp=' & StringFormat('%.2f', DllStructGetData(GetMyAgent(), 'HealthPercent')))
			UseSkillEx($COF_SIN_GRENTHS_AURA)
		EndIf
	EndIf
EndFunc


Func CleanCoFSinMobs()
	Local $target = GetNearestAgentToAgent(GetMyAgent(), $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsUndead)
	Local $clock = False
	Local $logHeartbeat = TimerInit()
	Local $combatTimer = TimerInit()
	While $target <> Null And GetDistance(GetMyAgent(), $target) < $MOB_AGGRO_RANGE And TimerDiff($combatTimer) < $COF_SIN_COMBAT_TIMEOUT_MS
		If TimerDiff($logHeartbeat) > 3000 Then
			Local $sfMs = GetEffectTimeRemaining($ID_SHADOW_FORM)
			Local $dpReady = IsRecharged($COF_SIN_DEADLY_PARADOX)
			Local $sfReady = IsRecharged($COF_SIN_SHADOW_FORM)
			CoFSinLogWrite('combat_tick', 'sf_ms=' & Int($sfMs) & ';sf_ready=' & $sfReady & ';dp_ready=' & $dpReady & ';e=' & Int(GetEnergy()) & ';hp=' & StringFormat('%.2f', DllStructGetData(GetMyAgent(), 'HealthPercent')) & ';a4=' & GetSkillbarSkillAdrenaline($COF_SIN_CRIPPLING_VICTORY) & ';a5=' & GetSkillbarSkillAdrenaline($COF_SIN_REAP_IMPURITIES))
			$logHeartbeat = TimerInit()
		EndIf
		MaintainCoFSinPerma()
		If Not $clock And GetSkillbarSkillAdrenaline($COF_SIN_CRIPPLING_VICTORY) >= 150 Then
			CoFSinLogWrite('cv_cast')
			UseSkillEx($COF_SIN_CRIPPLING_VICTORY, $target)
			$clock = True
		ElseIf $clock And GetSkillbarSkillAdrenaline($COF_SIN_REAP_IMPURITIES) >= 120 Then
			CoFSinLogWrite('reap_cast')
			UseSkillEx($COF_SIN_REAP_IMPURITIES, $target)
			$clock = False
		Else
			Attack($target)
			Sleep(200)
		EndIf
		MaintainCoFSinPerma()
		Sleep(100)
		If IsPlayerDead() Then Return $FAIL
		$target = GetNearestAgentToAgent(GetMyAgent(), $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsUndead)
	WEnd
	If TimerDiff($combatTimer) >= $COF_SIN_COMBAT_TIMEOUT_MS Then
		CoFSinLogWrite('combat_timeout', 'elapsed_ms=' & Int(TimerDiff($combatTimer)))
		Warn('CoF Sin: combat timeout after ' & Int(TimerDiff($combatTimer) / 1000) & 's')
	EndIf
	RandomSleep(200)
EndFunc


; ------------------------------------------------------------
; Debug CSV logging
; ------------------------------------------------------------
Func CoFSinLogInit()
	If Not $COF_SIN_DEBUG_LOG Then Return
	Local $timestamp = @YEAR & @MON & @MDAY & '_' & @HOUR & @MIN & @SEC
	Local $path = @ScriptDir & '/logs/cofsin_debug-' & GetCharacterName() & '-run' & $cof_sin_log_run & '-' & $timestamp & '.csv'
	$cof_sin_log_handle = FileOpen($path, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	$cof_sin_log_timer = TimerInit()
	If $cof_sin_log_handle == -1 Then Return
	Info('CoF Sin CSV: ' & $path)
	FileWriteLine($cof_sin_log_handle, 'time_ms;run;event;energy;hp;sf_ms;sod_ms;ca_ms;sf_ready;dp_ready;sod_ready;a4;a5;note')
EndFunc

Func CoFSinLogClose()
	If $cof_sin_log_handle == -1 Then Return
	FileClose($cof_sin_log_handle)
	$cof_sin_log_handle = -1
EndFunc

Func CoFSinLogWrite($eventName, $note = '')
	If $cof_sin_log_handle == -1 Then Return
	Local $timeMs = Int(TimerDiff($cof_sin_log_timer))
	Local $me = GetMyAgent()
	Local $energy = GetEnergy()
	Local $hp = DllStructGetData($me, 'HealthPercent')
	Local $sfMs = GetEffectTimeRemaining($ID_SHADOW_FORM)
	Local $sodMs = GetEffectTimeRemaining($ID_SHROUD_OF_DISTRESS)
	Local $caMs = GetEffectTimeRemaining($ID_CRITICAL_AGILITY)
	Local $sfReady = IsRecharged($COF_SIN_SHADOW_FORM)
	Local $dpReady = IsRecharged($COF_SIN_DEADLY_PARADOX)
	Local $sodReady = IsRecharged($COF_SIN_SHROUD_OF_DISTRESS)
	Local $a4 = GetSkillbarSkillAdrenaline($COF_SIN_CRIPPLING_VICTORY)
	Local $a5 = GetSkillbarSkillAdrenaline($COF_SIN_REAP_IMPURITIES)
	Local $safeNote = StringReplace($note, ';', ',')
	FileWriteLine($cof_sin_log_handle, $timeMs & ';' & $cof_sin_log_run & ';' & $eventName & ';' & $energy & ';' & $hp & ';' & $sfMs & ';' & $sodMs & ';' & $caMs & ';' & $sfReady & ';' & $dpReady & ';' & $sodReady & ';' & $a4 & ';' & $a5 & ';' & $safeNote)
EndFunc
; ------------------------------------------------------------
; ============================================================