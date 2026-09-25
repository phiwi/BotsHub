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
Global Const $GEMSTONES_MESMER_SKILLBAR = 'OghkkgKKjIyEz0rA0XR0t41U1kPI'
;~ Global Const $GEMSTONES_ELEMENTALIST_SKILLBAR = 'OgBCsMz0uI0w7w6whT6gcZuI' ; Water
;~ Global Const $GEMSTONES_ELEMENTALIST_SKILLBAR = 'OgdUkSFySvSpCMNnC3iwCRfFRLQA' ; Promise Wards 
;~ Global Const $GEMSTONES_ELEMENTALIST_SKILLBAR = 'OgBDgcqMS7ihD0CkDvCwCfDeDA' ; Air + Wards
;~ Global Const $GEMSTONES_ELEMENTALIST_SKILLBAR = 'OgljgwMopS7ihD0CkD+Y1YfDeDA' ; Air + Commmand
Global Const $GEMSTONES_ELEMENTALIST_SKILLBAR = 'OghkkwKBjIyEz0u4rw1U1U5kPYrI' ; Spirits + Wards
;~ Global Const $GEMSTONES_ELEMENTALIST_SKILLBAR = 'OgVDIMusRkD7i3imOCO3U4UTPA' ; Dom

; Fixed 7-hero team. Hero index 1..7 = the AddHero order in SetupTeamGemstonesFarm.
Global Const $GEMSTONES_HERO_OLIAS_ID = $ID_OLIAS
Global Const $GEMSTONES_HERO_OLIAS_TEMPLATE = 'OAhjQoGYIP3hhWVV4JNncDzxJA'
Global Const $GEMSTONES_HERO_NORGU_ID = $ID_NORGU
Global Const $GEMSTONES_HERO_NORGU_TEMPLATE = 'OQNEAqwD2yQDwpmupXOIDQ6QjA'
Global Const $GEMSTONES_HERO_RAZAH_ID = $ID_RAZAH
Global Const $GEMSTONES_HERO_RAZAH_TEMPLATE = 'OQNEAqwD2yQDwpmupXOIDQ6QjA'
Global Const $GEMSTONES_HERO_GWEN_ID = $ID_GWEN
Global Const $GEMSTONES_HERO_GWEN_TEMPLATE = 'OQBDAawDSvAIgcQ5ZkArATAEBA'
;~ Global Const $GEMSTONES_HERO_GWEN_TEMPLATE = 'OQBDAawDSvAIgcQ5ZkArATAEBA'
Global Const $GEMSTONES_HERO_XANDRA_ID = $ID_XANDRA
Global Const $GEMSTONES_HERO_XANDRA_TEMPLATE = 'OACiAyk8gNtePuwJ00Ze2QuA'
Global Const $GEMSTONES_HERO_MERCENARY1_ID = $ID_MERCENARY_HERO_1
Global Const $GEMSTONES_HERO_MERCENARY1_TEMPLATE = 'OACjEuiMpNXzqJGrcyMncSzhJA'
Global Const $GEMSTONES_HERO_MERCENARY2_ID = $ID_MERCENARY_HERO_2
Global Const $GEMSTONES_HERO_MERCENARY2_TEMPLATE = 'OANDYazPSxVNgeErEfEaRVVGNA'
Global Const $GEMSTONES_HERO_LIVIA_ID = $ID_LIVIA
Global Const $GEMSTONES_HERO_LIVIA_TEMPLATE = 'OAhkUoG3xFu0SVVgdAawWolwkzwE'
;~ Global Const $GEMSTONES_HERO_LIVIA_TEMPLATE = 'OABEQTtGeLB0QFAHgHsFqAaJYHA'

;~ Global Const $GEMSTONES_HERO_LIVIA_TEMPLATE = 'OABEQTtGeLB0cURFgHsFWGYJYHA'
Global Const $GEMSTONES_HERO_MOW_ID = $ID_MASTER_OF_WHISPERS
Global Const $GEMSTONES_HERO_MOW_TEMPLATE = 'OAhkUoG3xFuEQDVwnAewWYZg00wE'

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
Global $gemstones_hard_mode = False
; Optional single-consumable override for Hard Mode: '' (all), 'grail', 'armor' or 'essence'.
Global $gemstones_consets_override = ''

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


;~ Main method to farm Gemstones in Hard Mode (overrides the default Normal Mode).
Func GemstonesHardModeFarm()
	Return GemstonesRunHardMode('')
EndFunc


;~ Hard Mode using only Grail of Might (when the "consets" checkbox is enabled).
Func GemstonesHardModeGrailFarm()
	Return GemstonesRunHardMode('grail')
EndFunc


;~ Hard Mode using only Armor of Salvation (when the "consets" checkbox is enabled).
Func GemstonesHardModeArmorFarm()
	Return GemstonesRunHardMode('armor')
EndFunc


;~ Hard Mode using only Essence of Celerity (when the "consets" checkbox is enabled).
Func GemstonesHardModeEssenceFarm()
	Return GemstonesRunHardMode('essence')
EndFunc


;~ Hard Mode using only Grail of Might, no builds (preserves custom party/bars).
Func GemstonesHardModeGrailNoBuildsFarm()
	Return GemstonesRunHardMode('grail', True)
EndFunc


;~ Hard Mode using only Armor of Salvation, no builds (preserves custom party/bars).
Func GemstonesHardModeArmorNoBuildsFarm()
	Return GemstonesRunHardMode('armor', True)
EndFunc


;~ Hard Mode using only Essence of Celerity, no builds (preserves custom party/bars).
Func GemstonesHardModeEssenceNoBuildsFarm()
	Return GemstonesRunHardMode('essence', True)
EndFunc


;~ Shared Hard Mode runner: sets the mode, (optional) single-consumable override
;~ and (optional) no-builds flag, runs the farm, then restores defaults for the
;~ next run.
Func GemstonesRunHardMode($consetsOverride, $noBuilds = False)
	$gemstones_hard_mode = True
	$gemstones_consets_override = $consetsOverride
	$gemstones_no_builds_mode = $noBuilds
	Local $result = GemstonesFarm()
	$gemstones_hard_mode = False
	$gemstones_consets_override = ''
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
	If Not SupportTeamStabilizeAfterTravel($ID_GATE_OF_ANGUISH, 10000, 250) Then
		Warn('Gemstones setup: outpost stabilization timed out before team setup')
	EndIf
	If $gemstones_hard_mode Then
		SwitchMode($ID_HARD_MODE)
	Else
		SwitchMode($ID_NORMAL_MODE)
	EndIf
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
	; 2000u (statt default 1500u) damit Fernkämpfer wie der Tortureweb Dryder
	; auch auf Distanz erkannt, priorisiert und angegriffen werden.
	$gemstones_fight_options['fightRange']			= 2000
	$gemstones_fight_options['fightTimeout']		= $GEMSTONES_FARM_DURATION
	$gemstones_fight_options['priorityTargeting']	= True
	; Sehr grosse Prioritaets-Reichweite: die Tortureweb Dryder ist ein Fernkaempfer,
	; der weit weg bleibt/kitet (teils >5000u). Nur so wird sie zuverlaessig gefunden
	; und der Bot faellt nicht auf den Dream Rider zurueck.
	$gemstones_fight_options['priorityRange']		= 20000
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
	AddHero($GEMSTONES_HERO_MOW_ID)
	;~ AddHero($GEMSTONES_HERO_MERCENARY2_ID)
	;~ AddHero($GEMSTONES_HERO_MERCENARY1_ID)
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
	If GemstonesLoadHeroTemplate($GEMSTONES_HERO_MOW_ID, 'MoW', $GEMSTONES_HERO_MOW_TEMPLATE) == $FAIL Then Return $FAIL
	;~ If GemstonesLoadHeroTemplate($GEMSTONES_HERO_MERCENARY1_ID, 'A R U Atmosphere', $GEMSTONES_HERO_MERCENARY1_TEMPLATE) == $FAIL Then Return $FAIL
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
	; Arrange heroes in a tight ring around the player (Ele in the center) so the
	; player's Wards cover everyone. Radius keeps the 25%-tighter spacing (250 * 0.75 = 188).
	GemstonesArrangeHeroesAroundPlayer(188)
EndFunc


;~ Place the 7 heroes in a ring around the player (Elementalist in the center) so the
;~ player's Wards benefit every hero. The ring is oriented with one hero facing the
;~ nearest foe (incoming waves). $range is the ring radius (188 = 25% tighter than the
;~ default fan spacing of 250).
Func GemstonesArrangeHeroesAroundPlayer($range = 188)
	Local $heroCount = GetHeroCount()
	If $heroCount < 1 Then Return
	Local $me = GetMyAgent()
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')

	; Forward direction: toward the nearest foe, else the player's facing.
	Local $fx = DllStructGetData($me, 'RotationCos')
	Local $fy = DllStructGetData($me, 'RotationSin')
	Local $foe = GetNearestEnemyToAgent($me)
	If $foe <> Null Then
		Local $dx = DllStructGetData($foe, 'X') - $x
		Local $dy = DllStructGetData($foe, 'Y') - $y
		Local $len = Sqrt($dx * $dx + $dy * $dy)
		If $len > 0 Then
			$fx = $dx / $len
			$fy = $dy / $len
		EndIf
	EndIf
	; Right direction (perpendicular to forward, matches FanFlagHeroes convention).
	Local $rx = $fy
	Local $ry = -$fx

	Local $angleStep = (2 * 3.14159265358979) / $heroCount
	For $i = 1 To $heroCount
		Local $a = ($i - 1) * $angleStep
		Local $cosA = Cos($a)
		Local $sinA = Sin($a)
		CommandHero($i, $x + ($fx * $cosA + $rx * $sinA) * $range, $y + ($fy * $cosA + $ry * $sinA) * $range)
	Next
EndFunc


;~ Defending function
Func GemstonesDefendPosition()
	Info('Defending...')
	; The 19 waves are not defined in code — they are handled implicitly by
	; IsZhellixPerformingRitual(). Track a heuristic wave number for logging.
	; Detection counts foes around the FIXED defend point (not the player, who
	; moves while looting/chasing) so the signal is stable. Because ranged
	; stragglers (Tortureweb Dryders etc.) often linger, a wave is only
	; considered "over" once foes drop to a straggler-only count (<= 2) and
	; stay there for a few seconds; a new wave starts when foes rise back above
	; that threshold.
	Local $waveNumber = 0
	Local $waveActive = False
	Local $lullSince = 0

	While IsZhellixPerformingRitual()
		If CheckStuck('Gemstones fight', $MAX_GEMSTONES_FARM_DURATION) == $FAIL Then Return $FAIL
		If IsDoARunFailed() Then Return $FAIL
		; Hard Mode: maintain consets throughout the waves (gated by the GUI
		; "use consets" checkbox). If a single-consumable override is set,
		; only that consumable is used.
		If $gemstones_hard_mode Then GemstonesMaintainConsets()
		GemstonesMaintainSummon()
		Sleep(1000)

		Local $foesNow = CountFoesInRangeOfCoords($GEMSTONES_DEFEND_POSITION_X, $GEMSTONES_DEFEND_POSITION_Y, $gemstones_fight_options['fightRange'])
		If $foesNow >= 3 And Not $waveActive Then
			$waveNumber += 1
			Info('Wave ' & $waveNumber & '/19 started (' & $foesNow & ' foes in range)')
			$waveActive = True
			$lullSince = 0
		ElseIf $foesNow <= 2 Then
			; Only stragglers left. Require a sustained lull so a brief dip
			; while a wave is still dying doesn't miscount as the wave ending.
			If $lullSince == 0 Then $lullSince = TimerInit()
			If $waveActive And TimerDiff($lullSince) >= 6000 Then
				Info('Wave ' & $waveNumber & ' cleared (' & $foesNow & ' stragglers left)')
				$waveActive = False
			EndIf
		Else
			$lullSince = 0
		EndIf

		KillFoesInArea($gemstones_fight_options)
		If IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $RANGE_SPIRIT)
		MoveTo($GEMSTONES_DEFEND_POSITION_X, $GEMSTONES_DEFEND_POSITION_Y)
	WEnd
	Info('Defend loop ended after wave ' & $waveNumber & '.')
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


;~ Maintain consets during Hard Mode. When $gemstones_consets_override is set to
;~ 'grail', 'armor' or 'essence', only that single consumable is used (still
;~ gated by the GUI "use consets" checkbox). Otherwise all three are used.
Func GemstonesMaintainConsets()
	If Not $run_options_cache['run.use_consets'] Then Return
	Switch $gemstones_consets_override
		Case 'grail'
			If GetEffectTimeRemaining(GetEffect($ID_GRAIL_OF_MIGHT_EFFECT)) <= 0 Then UseConsumable($ID_GRAIL_OF_MIGHT, True)
		Case 'armor'
			If GetEffectTimeRemaining(GetEffect($ID_ARMOR_OF_SALVATION_EFFECT)) <= 0 Then UseConsumable($ID_ARMOR_OF_SALVATION, True)
		Case 'essence'
			If GetEffectTimeRemaining(GetEffect($ID_ESSENCE_OF_CELERITY_EFFECT)) <= 0 Then UseConsumable($ID_ESSENCE_OF_CELERITY, True)
		Case Else
			UseConset()
	EndSwitch
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