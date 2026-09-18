#CS ===========================================================================
; Author: Crux
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
#include '../../lib/GWA2_ID_Items.au3'
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'
#include '../utilities/SupportTeam.au3'


; ==== Constants ====
; TODO: rework builds following 26.06.24 nerfs
;Global Const $GEMSTONES_MESMER_SKILLBAR = 'OQBCAswDPVP/DMd5Zu2Nd6B'
Global Const $GEMSTONES_MESMER_SKILLBAR = 'OQBDAcMCT7iTPNB/AmO5ZcNyiA'
Global Const $GEMSTONES_ELEMENTALIST_SKILLBAR = 'OgljgwMopS7ihD0CkD+Y1YfDeDA'
; Fixed 7-hero team. Hero index 1..7 = the AddHero order in SetupTeamGemstonesFarm.
Global Const $GEMSTONES_HERO_OLIAS_ID = $ID_OLIAS
Global Const $GEMSTONES_HERO_OLIAS_TEMPLATE = 'OAhjQoGYIP3hhWVVaO5EeDzxJA'
Global Const $GEMSTONES_HERO_NORGU_ID = $ID_NORGU
Global Const $GEMSTONES_HERO_NORGU_TEMPLATE = 'OQNEAqwD2yQDwpmupXOIDwBQjA'
Global Const $GEMSTONES_HERO_RAZAH_ID = $ID_RAZAH
Global Const $GEMSTONES_HERO_RAZAH_TEMPLATE = 'OQNEAsoD2yECxpmupXOIDoBQjA'
Global Const $GEMSTONES_HERO_GWEN_ID = $ID_GWEN
Global Const $GEMSTONES_HERO_GWEN_TEMPLATE = 'OQBDAawDSvAIgcQ5ZkArATAEBA'
Global Const $GEMSTONES_HERO_XANDRA_ID = $ID_XANDRA
Global Const $GEMSTONES_HERO_XANDRA_TEMPLATE = 'OACiAyk8gNtePuwJ00Ze2QuA'
Global Const $GEMSTONES_HERO_MERCENARY1_ID = $ID_MERCENARY_HERO_1
Global Const $GEMSTONES_HERO_MERCENARY1_TEMPLATE = 'OACjEuiMpNXzqJGrcyMncSzhJA'
Global Const $GEMSTONES_HERO_LIVIA_ID = $ID_LIVIA
Global Const $GEMSTONES_HERO_LIVIA_TEMPLATE = 'OABEQTtGeLB0cUhHUGYJgGsFSFA'
Global Const $GEMSTONES_FARM_INFORMATIONS = 'Requirements:' & @CRLF _
	& '- Access to mallyx (finished all 4 doa parts)' & @CRLF _
	& '- Recommended to have maxed out Lightbringer title' & @CRLF _
	& '- Strong hero build' &@CRLF _
	& '- Hero order: 1. ST Ritu, 2. SoS Ritu, 3. BiP Necro, 4. MM Lich Necro, Rest - Energy Surge mesmers' &@CRLF _
	& ' ' & @CRLF _
	& 'Equipment:' & @CRLF _
	& '- 5x Artificer Rune' & @CRLF _
	& '- 1x Superior Vigor ' & @CRLF _
	& '- 1x Minor Fast Casting + 1x Major Fast Casting' & @CRLF _
	& '- 2x Vitae ' & @CRLF _
	& '- 40/40 DOM Set' & @CRLF _
	& '- Character Stats: 14 Fast Casting, 13 Domination Magic' & @CRLF _
	& ' ' & @CRLF _
	& 'Ebony Citadel of Mallyx location is unlocked after defeating all 4 Lords of Anguish in Mallyx the Unyielding quest.' & @CRLF _
	& 'Caution: do not defeat Mallyx the Unyielding, because this will finish the quest which would require to do 4 DoA parts all over again to get access to Ebony Citadel of Mallyx' & @CRLF _
	& 'This bot does not defeat Mallyx the Unyielding, only attempts to defeat all 19 waves, which does not finish the quest' & @CRLF _
	& 'This farm bot is based on below article:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Team_-_7_Hero_AFK_Gemstone_Farm' & @CRLF
; Average duration ~ 12m30sec
Global Const $GEMSTONES_FARM_DURATION = (12 * 60 + 30) * 1000
Global Const $MAX_GEMSTONES_FARM_DURATION = 18 * 60 * 1000
; Re-summon cadence for the Legionnaire crystal: slightly longer than the 60s
; Summoning Sickness. Summoned allies are not reliably visible in the agent
; array (skill summons like the Ebon Vanguard Assassin live outside it), so we
; re-trigger on a fixed interval instead of detecting the ally's death.
Global Const $GEMSTONES_SUMMON_RESUMMON_MS = 65000

;=== Configuration / Globals ===
Global Const $GEMSTONES_DEFEND_POSITION_X = -3432
Global Const $GEMSTONES_DEFEND_POSITION_Y = -5564

; Skill numbers declared to make the code WAY more readable (UseSkill($SKILL_CONVICTION) is better than UseSkill(1))
Global Const $GEM_SYMBOLIC_CELERITY		= 1
Global Const $GEM_SYMBOLIC_POSTURE		= 2
Global Const $GEM_KEYSTONE_SIGNET		= 3
Global Const $GEM_UNNATURAL_SIGNET		= 4
Global Const $GEM_SIGNET_OF_CLUMSINESS	= 5
Global Const $GEM_SIGNET_OF_DISRUPTION	= 6
Global Const $GEM_WASTRELS_DEMISE		= 7
Global Const $GEM_MISTRUST				= 8

Global Const $GEM_SKILLS_ARRAY			= [$GEM_SYMBOLIC_CELERITY,	$GEM_SYMBOLIC_POSTURE,	$GEM_KEYSTONE_SIGNET,	$GEM_UNNATURAL_SIGNET,	$GEM_SIGNET_OF_CLUMSINESS,	$GEM_SIGNET_OF_DISRUPTION,	$GEM_WASTRELS_DEMISE,	$GEM_MISTRUST]
Global Const $GEM_SKILLS_COSTS_ARRAY	= [15,						10,						0,						0,						0,							0,							5,						10]
Global Const $GEM_SKILLS_COSTS_MAP		= MapFromArrays($GEM_SKILLS_ARRAY, $GEM_SKILLS_COSTS_ARRAY)

Global $gemstones_fight_options

; in ebony citadel of Mallyx location, the agent ID of Zhellix is always assigned to 15, when party has 8 members (can be accessed in GWToolbox)
Global Const $AGENTID_ZHELLIX = 15
Global Const $MODELID_ZHELLIX = 5272

Global $gemstones_farm_setup = False
Global $gemstones_no_builds_mode = False

;~ Main Gemstones farm entry function
Func GemstonesFarm()
	If Not $gemstones_farm_setup Then SetupGemstonesFarm()

	Local $result = GemstonesFarmLoop()
	If $result == $SUCCESS Then Info('Successfully cleared all 19 waves')
	If $result == $FAIL Then Info('Could not clear all 19 waves')
	TravelToOutpost($ID_GATE_OF_ANGUISH, $district_name)
	Return $result
EndFunc


;~ Main method to farm Gemstones (no builds variant — preserves custom party and skill bars)
Func GemstonesNoBuildsFarm()
	$gemstones_no_builds_mode = True
	Local $result = GemstonesFarm()
	$gemstones_no_builds_mode = False
	Return $result
EndFunc


;~ Gemstones farm setup
Func SetupGemstonesFarm()
	Info('Setting up farm')
	; the 4 DoA farm areas have the same map ID as Gate of Anguish outpost (474)
	If GetMapID() <> $ID_GATE_OF_ANGUISH Then
		TravelToOutpost($ID_GATE_OF_ANGUISH, $district_name)
	Else
		ResignAndReturnToOutpost($ID_GATE_OF_ANGUISH, true)
	EndIf
	SwitchMode($ID_NORMAL_MODE)
	SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)
	If Not $gemstones_no_builds_mode Then
		SetupPlayerGemstonesFarm()
		SetupTeamGemstonesFarm()
	Else
		Info('Gemstones no-builds: skipping player and hero template loading')
		Info('Gemstones no-builds: preserving custom party (' & GetPartySize() & ' members, ' & GetHeroCount() & ' heroes)')
	EndIf
	; Zhellix agent ID will be lower if team size is lower than 8, therefore checking for fail
	If GetPartySize() <> $ID_TEAM_SIZE_LARGE Then
		Error('Party not set up correctly. Team size different than ' & $ID_TEAM_SIZE_LARGE)
		Return $FAIL
	EndIf
	SupportTeamOpenHeroPanels('Gemstones')
	SetupGemstonesFightOptions()
	$gemstones_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


;~ Done here to pick latest version of $default_move_aggro_kill_options
Func SetupGemstonesFightOptions()
	; heroes will be flagged before fight to defend the start location
	$gemstones_fight_options						= CloneMap($default_move_aggro_kill_options)
	$gemstones_fight_options['fightTimeout']		= $GEMSTONES_FARM_DURATION
	$gemstones_fight_options['priorityTargeting']	= True
	$gemstones_fight_options['skillsCostMap']		= $GEM_SKILLS_COSTS_MAP
	; there are no chests in Ebony Citadel of Mallyx location
	$gemstones_fight_options['openChests']			= False
EndFunc


Func SetupPlayerGemstonesFarm()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Local $primary = DllStructGetData(GetMyAgent(), 'Primary')
	If $primary == $ID_ELEMENTALIST Then
		If HeroHasTemplate(0, $GEMSTONES_ELEMENTALIST_SKILLBAR) Then
			Info('Gemstones player: elementalist template already loaded, skipping')
		Else
			Info('Players profession is elementalist. Loading recommended elementalist build automatically')
			LoadSkillTemplate($GEMSTONES_ELEMENTALIST_SKILLBAR)
			RandomSleep(250)
		EndIf
	ElseIf $primary == $ID_MESMER Then
		If HeroHasTemplate(0, $GEMSTONES_MESMER_SKILLBAR) Then
			Info('Gemstones player: mesmer template already loaded, skipping')
		Else
			Info('Players profession is mesmer. Loading up recommended mesmer build automatically')
			LoadSkillTemplate($GEMSTONES_MESMER_SKILLBAR)
			RandomSleep(250)
		EndIf
	Else
		Info('Automatic player build setup is disabled. Assuming that player build is set up manually')
	EndIf
EndFunc


;~ Set up the fixed 7-hero team (order matters: hero index 1..7 = add order).
Func SetupTeamGemstonesFarm()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up team: Olias, Norgu, Razah, Gwen, Xandra, A R U Atmosphere, Livia')
	LeaveParty()
	AddHero($GEMSTONES_HERO_OLIAS_ID)
	AddHero($GEMSTONES_HERO_NORGU_ID)
	AddHero($GEMSTONES_HERO_RAZAH_ID)
	AddHero($GEMSTONES_HERO_GWEN_ID)
	AddHero($GEMSTONES_HERO_XANDRA_ID)
	AddHero($GEMSTONES_HERO_MERCENARY1_ID)
	AddHero($GEMSTONES_HERO_LIVIA_ID)
	RandomSleep(500)
	If GetPartySize() <> $ID_TEAM_SIZE_LARGE Then
		Warn('Party not set up correctly. Team size different than ' & $ID_TEAM_SIZE_LARGE)
		Return $FAIL
	EndIf
	If GemstonesLoadHeroTemplate($GEMSTONES_HERO_OLIAS_ID, 'Olias', $GEMSTONES_HERO_OLIAS_TEMPLATE) == $FAIL Then Return $FAIL
	If GemstonesLoadHeroTemplate($GEMSTONES_HERO_NORGU_ID, 'Norgu', $GEMSTONES_HERO_NORGU_TEMPLATE) == $FAIL Then Return $FAIL
	If GemstonesLoadHeroTemplate($GEMSTONES_HERO_RAZAH_ID, 'Razah', $GEMSTONES_HERO_RAZAH_TEMPLATE) == $FAIL Then Return $FAIL
	If GemstonesLoadHeroTemplate($GEMSTONES_HERO_GWEN_ID, 'Gwen', $GEMSTONES_HERO_GWEN_TEMPLATE) == $FAIL Then Return $FAIL
	If GemstonesLoadHeroTemplate($GEMSTONES_HERO_XANDRA_ID, 'Xandra', $GEMSTONES_HERO_XANDRA_TEMPLATE) == $FAIL Then Return $FAIL
	If GemstonesLoadHeroTemplate($GEMSTONES_HERO_MERCENARY1_ID, 'A R U Atmosphere', $GEMSTONES_HERO_MERCENARY1_TEMPLATE) == $FAIL Then Return $FAIL
	If GemstonesLoadHeroTemplate($GEMSTONES_HERO_LIVIA_ID, 'Livia', $GEMSTONES_HERO_LIVIA_TEMPLATE) == $FAIL Then Return $FAIL
	RandomSleep(250)
	Return $SUCCESS
EndFunc


;~ Load a hero template, skipping if the hero already has it (saves setup time).
Func GemstonesLoadHeroTemplate($heroID, $heroName, $templateCode)
	Local $heroIndex = GetHeroNumberByHeroID($heroID)
	If $heroIndex == Null Then
		Warn('Gemstones team: hero index not found for ' & $heroName)
		Return $FAIL
	EndIf
	If HeroHasTemplate($heroIndex, $templateCode) Then
		Info('Gemstones ' & $heroName & ': template already loaded, skipping')
		Return $SUCCESS
	EndIf
	LoadSkillTemplate($templateCode, $heroIndex)
	RandomSleep(220)
	Return $SUCCESS
EndFunc


;~ Gemstones farm loop
Func GemstonesFarmLoop()
	If TalkToZhellix() == $FAIL Then Return $FAIL
	WalkToSpotGemstonesFarm()
	; Spawn the Legionnaire ally before the waves start (gated by the
	; "Use Legionnaire summon" GUI option inside UseSummoningStone).
	UseSummoningStone()
	Sleep(2000)
	If GemstonesDefendPosition() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Talking to Zhellix
Func TalkToZhellix()
	If GetMapID() <> $ID_GATE_OF_ANGUISH Then Return $FAIL
	Local $zhellix = GetNearestNpcToCoords(6081, -13314)
	ChangeTarget($zhellix)
	GoToNPC($zhellix)
	Dialog(0x84)
	WaitMapLoading($ID_THE_EBONY_CITADEL_OF_MALLYX)
	Return GetMapID() == $ID_THE_EBONY_CITADEL_OF_MALLYX? $SUCCESS : $FAIL
EndFunc


;~ Getting into positions
Func WalkToSpotGemstonesFarm()
	Info('Moving to defend position')
	; go close to Zhellix to let him start erforming the ritual, Null for no interaction
	GoToAgent(GetAgentByID($AGENTID_ZHELLIX), Null)
	MoveTo($GEMSTONES_DEFEND_POSITION_X, $GEMSTONES_DEFEND_POSITION_Y)
	FanFlagHeroes()
EndFunc


;~ Defending function
Func GemstonesDefendPosition()
	Info('Defending...')

	While IsZhellixPerformingRitual()
		If CheckStuck('Gemstones fight', $MAX_GEMSTONES_FARM_DURATION) == $FAIL Then Return $FAIL
		If IsDoARunFailed() Then Return $FAIL
		GemstonesMaintainSummon()
		Sleep(1000)
		KillFoesInArea($gemstones_fight_options)
		If IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $RANGE_SPIRIT)
		MoveTo($GEMSTONES_DEFEND_POSITION_X, $GEMSTONES_DEFEND_POSITION_Y)
	WEnd
	; if ritual completed then successful run
	Return IsDoARunFailed()? $FAIL : $SUCCESS
EndFunc


;~ Keep the Legionnaire alive across all 19 waves. Summoned allies are not
;~ reliably visible in the agent array (skill summons like the Ebon Vanguard
;~ Assassin live outside it), so instead of detecting the ally's death we
;~ re-trigger the crystal on a fixed interval once Summoning Sickness (60s) has
;~ expired. For an infinite summon this is a harmless no-op while the ally is
;~ still alive, and brings it straight back once it has died.
Func GemstonesMaintainSummon()
	Local Static $lastSummon = 0
	If GetEffectTimeRemaining(GetEffect($ID_SUMMONING_SICKNESS)) > 0 Then Return
	If $lastSummon <> 0 And TimerDiff($lastSummon) < $GEMSTONES_SUMMON_RESUMMON_MS Then Return
	If UseSummoningStone() Then $lastSummon = TimerInit()
EndFunc


;~ Check if run failed
Func IsDoARunFailed()
	Local $zhellix = GetAgentByID($AGENTID_ZHELLIX)
	If GetIsDead($zhellix) Then Warn('Zhellix dead')
	If IsPlayerDead() Then Warn('Player dead')
	Return GetIsDead($zhellix) Or Not HasRezMemberAlive()
EndFunc


;~ While Zhellix stays within entrance of citadel area and performs opening ritual then farm run is still on
Func IsZhellixPerformingRitual()
	If IsDoARunFailed() Then Return False

	Local $me = GetMyAgent()
	Local $zhellix = GetAgentByID($AGENTID_ZHELLIX)
	Local $foesCount = CountFoesInRangeOfAgent($me, $gemstones_fight_options['fightRange'])
	; After all waves are finished, Zhellix leaves entrance of citadel area where player is, which makes below check False
	Return (Not GetIsDead($zhellix) And GetDistance($me, $zhellix) < 1500) Or $foesCount > 0
EndFunc