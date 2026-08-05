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
; Base variant with IAU for anti-KD.
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


Global Const $COFSIN_PLAYER_SKILLBAR = 'Owpk8xjYaqWEPiOzB0YozV3HNJmI'
Global Const $COFSIN_FARM_INFORMATIONS = 'CoF Assassin base variant — perma Shadow Form + IAU (anti-KD).'
Global Const $COFSIN_FARM_DURATION = 5 * 60 * 1000
Global Const $COFSIN_QUEST_INIT_DIALOG = 0x832103
Global Const $COFSIN_QUEST_ACCEPT_DIALOG = 0x832101
Global Const $COFSIN_ENTER_INIT_DIALOG = 0x832105
Global Const $COFSIN_ENTER_ACCEPT_DIALOG = 0x88
Global Const $COFSIN_MODELID_MURAKAI_SERVANT = 7069
Global Const $COFSIN_MODELID_CRYPT_GHOUL = 7075
Global Const $COFSIN_MODELID_CRYPT_SLASHER = 7077
Global Const $COFSIN_MODELID_CRYPT_WRAITH = 7079
Global Const $COFSIN_MODELID_CRYPT_BANSHEE = 7081
Global Const $COFSIN_MODELID_SHOCK_PHANTOM = 7083
Global Const $COFSIN_MODELID_ASH_PHANTOM = 7085
Global Const $COFSIN_DEADLY_PARADOX = 1
Global Const $COFSIN_SHADOW_FORM = 2
Global Const $COFSIN_SHROUD_OF_DISTRESS = 3
Global Const $COFSIN_CRIPPLING_VICTORY = 4
Global Const $COFSIN_REAP_IMPURITIES = 5
Global Const $COFSIN_GRENTHS_AURA = 6
Global Const $COFSIN_IAU = 7
Global Const $COFSIN_SIGNET_OF_MYSTIC_SPEED = 8
Global Const $COFSIN_SF_DP_MIN_ENERGY = 20
Global Const $COFSIN_DP_AFTER_SF_DELAY_MS = 500
Global Const $COFSIN_SF_QUEUE_RETRY_MS = 1500
Global Const $COFSIN_COMBAT_TIMEOUT_MS = 10 * 60 * 1000
Global $cofsin_farm_setup = False


Func CoFSinFarm()
	If Not $cofsin_farm_setup And SetupCoFSinFarm() == $FAIL Then Return $PAUSE
	Sleep(10000)
	GoToCathedralOfFlamesSin()
	Local $result = CoFSinFarmLoop()
	ResignAndReturnToOutpost($ID_DOOMLORE_SHRINE)
	Return $result
EndFunc


Func SetupCoFSinFarm()
	Info('Setting up CoF Sin farm')
	If TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerCoFSinFarm() == $FAIL Then Return $FAIL
	LeaveParty()
	GoToCathedralOfFlamesSin()
	RandomSleep(2500)
	Move(-19300, -8250)
	RandomSleep(2500)
	WaitMapLoading($ID_DOOMLORE_SHRINE, 10000, 2500)
	$cofsin_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerCoFSinFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
		If HeroHasTemplate(0, $COFSIN_PLAYER_SKILLBAR) Then
			Info('CoF Sin player: template already loaded, skipping')
		Else
			LoadSkillTemplate($COFSIN_PLAYER_SKILLBAR)
		EndIf
		RandomSleep(250)
	Else
		Warn('Should run this farm as assassin')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func GoToCathedralOfFlamesSin()
	TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name)
	While GetMapID() <> $ID_CATHEDRAL_OF_FLAMES
		Info('Entering Cathedral of Flames')
		Local $gron = GetNearestNPCToCoords(-19166, 17980)
		GoToNPC($gron)
		If IsQuestNotFound($ID_QUEST_TEMPLE_OF_THE_DAMNED) Then
			TakeQuest($gron, $ID_QUEST_TEMPLE_OF_THE_DAMNED, $COFSIN_QUEST_ACCEPT_DIALOG, $COFSIN_QUEST_INIT_DIALOG)
			Sleep(1000)
		EndIf
		Dialog($COFSIN_ENTER_INIT_DIALOG)
		Sleep(1000)
		Dialog($COFSIN_ENTER_ACCEPT_DIALOG)
		WaitMapLoading($ID_CATHEDRAL_OF_FLAMES)
	WEnd
EndFunc


Func CoFSinFarmLoop()
	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-18250, -8595))
	Sleep(500)
	Dialog(0x84)
	Sleep(500)
	AggroAndPrepareSin()
	Info('Farming Cryptos')
	AdlibRegister('MaintainCoFSinPermaAdlib', 200)
	CleanCoFSinMobs()
	AdlibUnRegister('MaintainCoFSinPermaAdlib')
	If IsPlayerDead() Then Return $FAIL
	Info('Picking up loot')
	PickUpItems()
	Return $SUCCESS
EndFunc


Func AggroAndPrepareSin()
	MoveTo(-16850, -8930)
	If IsRecharged($COFSIN_DEADLY_PARADOX) Then UseSkill($COFSIN_DEADLY_PARADOX)
	RandomSleep($COFSIN_DP_AFTER_SF_DELAY_MS)
	If IsRecharged($COFSIN_SHADOW_FORM) Then UseSkill($COFSIN_SHADOW_FORM)
	If IsRecharged($COFSIN_SHROUD_OF_DISTRESS) Then UseSkillEx($COFSIN_SHROUD_OF_DISTRESS)
	RandomSleep(80)
	If IsRecharged($COFSIN_IAU) Then UseSkillEx($COFSIN_IAU)
	RandomSleep(80)
	If IsRecharged($COFSIN_SIGNET_OF_MYSTIC_SPEED) Then UseSkillEx($COFSIN_SIGNET_OF_MYSTIC_SPEED)
	RandomSleep(80)
	MoveTo(-15220, -8950)
	Sleep(500)
EndFunc


Func MaintainCoFSinPermaAdlib()
	MaintainCoFSinPerma(True)
EndFunc


Func MaintainCoFSinPerma($allowUtilityCasts = True)
	If IsPlayerDead() Then Return
	Local Static $sfQueueTimer = Null
	Local $sfRechargedNow = IsRecharged($COFSIN_SHADOW_FORM)
	Local $energyNow = GetEnergy()
	If $sfRechargedNow And $energyNow >= $COFSIN_SF_DP_MIN_ENERGY And ($sfQueueTimer == Null Or TimerDiff($sfQueueTimer) > $COFSIN_SF_QUEUE_RETRY_MS) Then
		If IsRecharged($COFSIN_DEADLY_PARADOX) Then
			UseSkill($COFSIN_DEADLY_PARADOX)
			$sfQueueTimer = TimerInit()
			Local $sfTimer = TimerInit()
			While IsPlayerAlive() And TimerDiff($sfTimer) < $COFSIN_DP_AFTER_SF_DELAY_MS
				Sleep(10)
			WEnd
			UseSkill($COFSIN_SHADOW_FORM)
		EndIf
		Return
	EndIf
	If $allowUtilityCasts And IsRecharged($COFSIN_SHROUD_OF_DISTRESS) Then
		If GetEffectTimeRemaining($ID_SHROUD_OF_DISTRESS) <= 2500 Then
			UseSkillEx($COFSIN_SHROUD_OF_DISTRESS)
		EndIf
	EndIf
	If $allowUtilityCasts And IsRecharged($COFSIN_GRENTHS_AURA) And GetEnergy() > 24 Then
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.90 Then
			UseSkillEx($COFSIN_GRENTHS_AURA)
		EndIf
	EndIf
EndFunc


Func CleanCoFSinMobs()
	Local $target = GetNearestAgentToAgent(GetMyAgent(), $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsUndeadSin)
	Local $clock = False
	Local $combatTimer = TimerInit()
	While $target <> Null And GetDistance(GetMyAgent(), $target) < $MOB_AGGRO_RANGE And TimerDiff($combatTimer) < $COFSIN_COMBAT_TIMEOUT_MS
		MaintainCoFSinPerma()
		If Not $clock And GetSkillbarSkillAdrenaline($COFSIN_CRIPPLING_VICTORY) >= 150 Then
			UseSkillEx($COFSIN_CRIPPLING_VICTORY, $target)
			$clock = True
		ElseIf $clock And GetSkillbarSkillAdrenaline($COFSIN_REAP_IMPURITIES) >= 120 Then
			UseSkillEx($COFSIN_REAP_IMPURITIES, $target)
			$clock = False
		Else
			Attack($target)
			Sleep(200)
		EndIf
		MaintainCoFSinPerma()
		Sleep(100)
		If IsPlayerDead() Then Return $FAIL
		$target = GetNearestAgentToAgent(GetMyAgent(), $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsUndeadSin)
	WEnd
	If TimerDiff($combatTimer) >= $COFSIN_COMBAT_TIMEOUT_MS Then
		Warn('CoF Sin: combat timeout after ' & Int(TimerDiff($combatTimer) / 1000) & 's')
	EndIf
	RandomSleep(200)
EndFunc


Func IsUndeadSin($agent)
	Local $modelID = DllStructGetData($agent, 'ModelID')
	Return Not GetIsDead($agent) And DllStructGetData($agent, 'HealthPercent') > 0 And _
		($modelID == $COFSIN_MODELID_MURAKAI_SERVANT Or $modelID == $COFSIN_MODELID_CRYPT_GHOUL _
		Or $modelID == $COFSIN_MODELID_CRYPT_SLASHER Or $modelID == $COFSIN_MODELID_CRYPT_WRAITH _
		Or $modelID == $COFSIN_MODELID_CRYPT_BANSHEE Or $modelID == $COFSIN_MODELID_SHOCK_PHANTOM _
		Or $modelID == $COFSIN_MODELID_ASH_PHANTOM)
EndFunc
