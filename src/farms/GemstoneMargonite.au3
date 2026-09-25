#CS ===========================================================================
=====================================
|	Margonite Gemstones Farm bot	|
|			TonReuf					|
=====================================
;
; Run this farm bot as Assassin or Mesmer or Ranger or Elementalist
;
; Rewritten for BotsHub: Gahais
; Margonite gemstone farms in City of Torc'qua based on below articles:
https://gwpvx.fandom.com/wiki/Build:Team_-_1_Hero_Margonite_Gemstone_Farm
https://gwpvx.fandom.com/wiki/Build:Team_-_1_Hero_Whirling_Defense_City_Farmer
;
#CE ===========================================================================

#include-once
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID_Quests.au3'
#include '../../lib/GWA2_ID_Skills.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'
#include '../utilities/SupportTeam.au3'


#Region Configuration
; === Build ===
;Global Const $AME_MARGONITE_SKILLBAR = 'OwVT4nPHYiHRn5AiVE3hm0DSEAA'
Global Const $AME_MARGONITE_SKILLBAR = 'OwVTEY/8ZiHRn5AiVkm0DSEA3B'
;Global Const $MEA_MARGONITE_SKILLBAR = 'OQdTA0A+ZiHRn5AiAC3hm0DSEA'
Global Const $MEA_MARGONITE_SKILLBAR = 'OQdTAmA/ZiHRn5AiAC3hm0DyiD'
Global Const $EME_MARGONITE_SKILLBAR = 'OgVUEQkkYmSSfaDfVug0C0keQiAA'
Global Const $RA_MARGONITE_SKILLBAR = 'OgcTcZ/8ZiHRn5AKCC3hm8uU4A'
Global Const $MARGONITE_MONK_HERO_SKILLBAR = 'OwITAnHb5Qe/zhxLkpE6+G'
;Global Const $MARGONITE_MONK_HERO_SKILLBAR = 'OwITAnHb5Qe/zhx7jpE6+G'

; You can select which monk hero to use in the farm here, among 3 heroes available. Uncomment below line for hero to use
; party hero ID that is used to add hero to the party team
;Global Const $MARGONITE_HERO_PARTY_ID = $ID_DUNKORO
Global Const $MARGONITE_HERO_PARTY_ID = $ID_TAHLKORA
;Global Const $MARGONITE_HERO_PARTY_ID = $ID_OGDEN

Global Const $MARGONITE_DEADLY_PARADOX		= 1
Global Const $MARGONITE_SHADOWFORM			= 2
Global Const $MARGONITE_SHROUD_OF_DISTRESS	= 3
Global Const $MARGONITE_DEATHS_CHARGE		= 5
Global Const $MARGONITE_I_AM_UNSTOPPABLE	= 6
Global Const $MARGONITE_ANCESTORS_VISAGE	= 7
Global Const $MARGONITE_MESMER_LIGHTBRINGERS_GAZE	= 8
; Assassin double-visage build reshuffles the shared (Mesmer) slots: IAU 6->5,
; Ancestor's Visage 7->6, Sympathetic Visage added at 7, Death's Charge 5->8.
Global Const $MARGONITE_ASSASSIN_I_AM_UNSTOPPABLE	= 5
Global Const $MARGONITE_ASSASSIN_ANCESTORS_VISAGE	= 6
Global Const $MARGONITE_ASSASSIN_SYMPATHETIC_VISAGE	= 7
Global Const $MARGONITE_ASSASSIN_DEATHS_CHARGE		= 8
; Margonites always create Quickening Zephyr spirit which halves recharge time of spells
; Therefore Ancestors visage recharges after 10 seconds which is basically equal to 9-10 seconds duration with illusion magic attribute equal to 12-14
; The Assassin double-visage build drops the Lightbringer Signet energy battery for a second
; Visage (Sympathetic Visage): 6 energy drained per melee hit instead of 3, so each Margonite
; hits 0 energy (and dies to its own Famine spirit) twice as fast. Shadow Form caps the Sin's
; own damage at 21/hit, so a direct damage skill (Lightbringer's Gaze) is a poor fit; the
; energy-drain speed is what drives the kill.
; Deadly Paradox skill could also be potentially removed because of Quickening Zephyr spirit

Global Const $MARGONITE_ASSASSIN_GREAT_DWARF_ARMOR			= 4

Global Const $MARGONITE_MESMER_WAY_OF_PERFECTION			= 4

Global Const $MARGONITE_ELEMENTALIST_GLYPH_OF_SWIFTNESS		= 1
Global Const $MARGONITE_ELEMENTALIST_OBSIDIAN_FLESH			= 2
Global Const $MARGONITE_ELEMENTALIST_STONEFLESH_AURA		= 3
Global Const $MARGONITE_ELEMENTALIST_ELEMENTAL_LORD			= 4
Global Const $MARGONITE_ELEMENTALIST_AURA_OF_RESTORATION	= 5
Global Const $MARGONITE_ELEMENTALIST_SYMPATHETICVISAGE		= 8

Global Const $MARGONITE_RANGER_UNSEEN_FURY			= 4
Global Const $MARGONITE_RANGER_DWARVEN_STABILITY	= 7
Global Const $MARGONITE_RANGER_WHIRLING_DEFENSE		= 8

; Monk protector hero
Global Const $MARGONITE_HERO_BALTHAZAR_SPIRIT	= 1
Global Const $MARGONITE_HERO_WATCHFUL_SPIRIT	= 2
Global Const $MARGONITE_HERO_LIFE_BARRIER		= 3
Global Const $MARGONITE_HERO_LIFE_BOND			= 4
Global Const $MARGONITE_HERO_VITAL_BLESSING		= 5
Global Const $MARGONITE_HERO_BLESSED_SIGNET		= 6
Global Const $MARGONITE_HERO_EDGE_OF_EXTINCTION	= 7
Global Const $MARGONITE_HERO_TROLL_UNGUENT		= 8
#EndRegion Configuration

; ==== Constants ====
Global Const $GEMSTONE_MARGONITE_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- Armor with HP runes and 5 blessed insignias (+50 armor when enchanted)' & @CRLF _
	& '- Spear/Sword/Axe +5 energy of Enchanting (20% longer enchantments duration)' & @CRLF _
	& '- Shield of Fortitude (+30 HP) with +10 vs Demons (like Stygian Aegis)' & @CRLF _
	& '- Monk hero with +4 Protection prayers (+3+1 headgear)' & @CRLF _
	& '- Monk hero armor and weapons with bonus to energy and HP' & @CRLF _
	& ' ' & @CRLF _
	& 'You can run this farm as Assassin or Mesmer or Ranger or Elementalist. Bot will set up build automatically for these professions' & @CRLF _
	& 'This bot farms margonite gemstones (1 of 4 types) in City of Torcqua location' & @CRLF _
	& 'Player needs to have access to Gate of Anguish outpost which has exit to City of Torcqua location' & @CRLF _
	& 'This farm reduces energy of margonites to 0 with ancestors visage skill which deals damage to margonites because margonites create Famine spirit' & @CRLF _
	& 'Recommended to have maxed out Lightbringer title. If not maxed out then this farm is good for raising lightbringer rank' & @CRLF _
	& 'Can switch to normal mode in case of low success rate but hard mode has better loots' & @CRLF _
	& 'Gemstones can be exchanged into armbrace of truth (15 of each type) or coffer of whisper (1 of each type)' & @CRLF _
	& 'This farm bot is based on below articles:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Team_-_1_Hero_Margonite_Gemstone_Farm' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Team_-_1_Hero_Whirling_Defense_City_Farmer' & @CRLF _
	& 'For Assassin and Mesmer and Elementalist this bot works by casting Visage skills that reduce energy of Margonites to 0 which deals damage to them because they create Famine spirit' & @CRLF
; Average duration ~ 5 minutes
Global Const $GEMSTONE_MARGONITE_FARM_DURATION = 5 * 60 * 1000
Global Const $MAX_GEMSTONE_MARGONITE_FARM_DURATION = 10 * 60 * 1000
Global Const $MARGONITES_RANGE = 800

Global $margonite_move_options									= CloneMap($default_move_options)
$margonite_move_options['movementRoutine']						= MargoniteSurvive
$margonite_move_options['moveTimeout']							= 100 * 1000
$margonite_move_options['moveVariance']							= 25
; Body-block escape: Death's Charge forward into a foe when genuinely stuck (>10
; blocked ticks). Slot is set per-profession in SetupPlayerMargoniteFarm.

Global $margonite_move_options_elementalist						= CloneMap($margonite_move_options)
$margonite_move_options_elementalist['skillSlotDeathsCharge']	= 0

Global $margonite_obsidian_flesh_timer		= TimerInit()
Global $margonite_stoneflesh_aura_timer		= TimerInit()
Global $margonite_elemental_lord_timer		= TimerInit()
Global $margonite_aura_of_restoration_timer	= TimerInit()

Global $margonite_player_profession = $ID_MESMER
Global $gemstone_margonite_farm_setup = False

; Set to True to write a CSV debug log (logs/margonite_debug-<char>.csv)
Global Const $MARGONITE_DEBUG_LOG = True

;~ Main loop function for farming margonite gemstones
Func GemstoneMargoniteFarm()
	If Not $gemstone_margonite_farm_setup And SetupGemstoneMargoniteFarm() == $FAIL Then Return $PAUSE

	If GoToCityOfTorcqua() == $FAIL Then Return $FAIL
	Local $result = GemstoneMargoniteFarmLoop()
	If $result == $SUCCESS Then
		Info('Successfully cleared margonite mobs')
		MargoniteCsvLog('farm_success')
	ElseIf $result == $FAIL Then
		If IsPlayerDead() Then Warn('Player died')
		If IsHeroDead(1) Then Warn('monk hero died')
		Info('Could not clear margonite mobs')
		MargoniteCsvLog('farm_death')
	EndIf
	Info('Returning back to the outpost')
	ResignAndReturnToOutpost($ID_GATE_OF_ANGUISH, true)
	Return $result
EndFunc


Func SetupGemstoneMargoniteFarm()
	Info('Setting up farm')
	; 4 DoA farm areas have the same map ID as Gate of Anguish outpost (474)
	If GetMapID() <> $ID_GATE_OF_ANGUISH Then
		If TravelToOutpost($ID_GATE_OF_ANGUISH, $district_name) == $FAIL Then Return $FAIL
	Else
		ResignAndReturnToOutpost($ID_GATE_OF_ANGUISH, true)
	EndIf
	SwitchToHardModeIfEnabled()
	RandomSleep(500)
	SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)
	RandomSleep(500)
	If SetupPlayerMargoniteFarm() == $FAIL Then Return $FAIL
	If SetupTeamMargoniteFarm() == $FAIL Then Return $FAIL
	RandomSleep(500)
	$gemstone_margonite_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerMargoniteFarm()
	Info('Setting up player build skill bar')
	$margonite_player_profession = DllStructGetData(GetMyAgent(), 'Primary')
	Switch $margonite_player_profession
		Case $ID_ASSASSIN
			If HeroHasTemplate(0, $AME_MARGONITE_SKILLBAR) Then
				Info('Margonite Assassin: template already loaded, skipping')
			Else
				LoadSkillTemplate($AME_MARGONITE_SKILLBAR)
			EndIf
		Case $ID_MESMER
			If HeroHasTemplate(0, $MEA_MARGONITE_SKILLBAR) Then
				Info('Margonite Mesmer: template already loaded, skipping')
			Else
				LoadSkillTemplate($MEA_MARGONITE_SKILLBAR)
			EndIf
		Case $ID_ELEMENTALIST
			If HeroHasTemplate(0, $EME_MARGONITE_SKILLBAR) Then
				Info('Margonite Elementalist: template already loaded, skipping')
			Else
				LoadSkillTemplate($EME_MARGONITE_SKILLBAR)
			EndIf
		Case $ID_RANGER
			If HeroHasTemplate(0, $RA_MARGONITE_SKILLBAR) Then
				Info('Margonite Ranger: template already loaded, skipping')
			Else
				LoadSkillTemplate($RA_MARGONITE_SKILLBAR)
			EndIf
		Case Else
			Warn('You need to run this farm bot as Assassin or Mesmer or Elementalist or Ranger')
			Return $FAIL
	EndSwitch
	; Body-block escape via Death's Charge for professions that have it. The Sin gets
	; surrounded by the first caster group while running the south-west leg; DCing
	; forward into a foe (the furthest one in spellcast range) clears the body-block.
	Switch $margonite_player_profession
		Case $ID_ASSASSIN
			$margonite_move_options['skillSlotDeathsCharge'] = $MARGONITE_ASSASSIN_DEATHS_CHARGE
		Case $ID_MESMER
			$margonite_move_options['skillSlotDeathsCharge'] = $MARGONITE_DEATHS_CHARGE
		Case Else
			$margonite_move_options['skillSlotDeathsCharge'] = 0
	EndSwitch
	RandomSleep(250)
	Return $SUCCESS
EndFunc


;~ Reset to a solo party (player only) before adding the monk hero. A plain
;~ LeaveParty() can leave a stray hero behind (e.g. Dunkoro from a previous run),
;~ which makes the party size 3 and trips the "team size 2" check below.
Func MargoniteEnsureSoloParty($maxWaitMs = 8000)
	Local $timer = TimerInit()
	SupportTeamKickAllHeroesByIDSweep()
	KickAllHeroes()
	LeaveParty(False)
	While TimerDiff($timer) < $maxWaitMs
		If GetPartySize() <= 1 And GetHeroCount() <= 0 Then Return $SUCCESS
		SupportTeamKickAllHeroesByIDSweep()
		KickAllHeroes()
		LeaveParty(False)
		RandomSleep(320)
	WEnd
	Warn('Margonite team: party reset timeout. Party=' & GetPartySize() & ', heroes=' & GetHeroCount())
	Return $FAIL
EndFunc


;~ Add the configured monk hero (Tahlkora by default) with verification. We
;~ deliberately avoid AddHeroByProfession's fallback loop: on high latency its
;~ fixed 500ms sleep is too short to see the hero register, so it keeps sending
;~ AddHero for the other monk heroes too — which ends up adding Tahlkora +
;~ Dunkoro + Ogden all at once and then fails with "Could not add any hero".
Func MargoniteAddMonkHero()
	Local $timer = TimerInit()
	While TimerDiff($timer) < 15000
		If GetHeroNumberByHeroID($MARGONITE_HERO_PARTY_ID) <> Null Then Return $SUCCESS
		AddHero($MARGONITE_HERO_PARTY_ID)
		RandomSleep(750)
	WEnd
	Error('Could not add monk hero ' & $MARGONITE_HERO_PARTY_ID)
	Return $FAIL
EndFunc


Func SetupTeamMargoniteFarm()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up team')
	If MargoniteEnsureSoloParty() == $FAIL Then Return $FAIL
	If MargoniteAddMonkHero() == $FAIL Then Return $FAIL
	If GetPartySize() <> 2 Then
		Warn('Could not add monk hero to team. Team size different than 2')
		Return $FAIL
	EndIf
	RandomSleep(250)
	Info('Setting up hero build skill bar')
	If HeroHasTemplate(1, $MARGONITE_MONK_HERO_SKILLBAR) Then
		Info('Margonite monk hero: template already loaded, skipping')
	Else
		LoadSkillTemplate($MARGONITE_MONK_HERO_SKILLBAR, 1)
	EndIf
	RandomSleep(250)
	SetHeroBehaviour(1, $ID_HERO_AVOIDING)
	RandomSleep(250)
	DisableAllHeroSkills(1)
	RandomSleep(250)
	Return $SUCCESS
EndFunc


Func EnableMargoniteHeroSkills()
	EnableHeroSkillSlot(1, $MARGONITE_HERO_BLESSED_SIGNET)
	PingSleep(50)
	EnableHeroSkillSlot(1, $MARGONITE_HERO_TROLL_UNGUENT)
	PingSleep(50)
EndFunc


;~ Exit gate of Anguish outpost by moving into portal that leads into farming location - City of Torc'qua
Func GoToCityOfTorcqua()
	TravelToOutpost($ID_GATE_OF_ANGUISH, $district_name)
	Info('Moving to City of Torcqua')
	; Unfortunately all 4 gemstone farm explorable locations have the same map ID as Gate of Anguish outpost, so it is harder to tell if player left the outpost
	; Therefore below loop checks if player is in close range of coordinates of that start zone where player initially spawns in City of Torc'qua
	Local Static $startX = -18575
	Local Static $startY = -8833
	Local $timerZoning = TimerInit()
	While Not IsAgentInRange(GetMyAgent(), $startX, $startY, $RANGE_EARSHOT)
		If TimerDiff($timerZoning) > 120000 Then
			Info('Could not zone to City of Torcqua')
			Return $FAIL
		EndIf
		MoveTo(6816, -13634)
		MoveTo(8258, -10419)
		MoveTo(10180, -10714)
		Move(11250, -11350)
		Sleep(8000)
	WEnd
EndFunc


Func CastBondsMargoniteFarm()
	Info('Casting hero monk bonds')
	; Below sequence ensures that player have the effect of 5 monk enchantments from monk hero and also monk hero have 1 enchantment - balthazars spirit
	; Last 2 enchantments are least important so these may deactivate when hero energy drops to 0, which is unlikely
	; Disable blessed signet hero skill so that hero does not mess up below sequence with using that skill in wrong moment
	DisableHeroSkillSlot(1, $MARGONITE_HERO_BLESSED_SIGNET)
	PingSleep(50)

	UseHeroSkillTimed(1, $MARGONITE_HERO_BALTHAZAR_SPIRIT, GetMyAgent())	; costs 10 energy
	Sleep(10000)																			; wait until energy is recovered, should recover 10 energy with 3 energy pips
	UseHeroSkillTimed(1, $MARGONITE_HERO_WATCHFUL_SPIRIT, GetMyAgent())	; costs 15 energy
	UseHeroSkillTimed(1, $MARGONITE_HERO_BLESSED_SIGNET)					; recover 6 hero energy
	Sleep(12000)																			; wait until Blessed signet is recharged, should recover 8 energy with 2 energy pips
	UseHeroSkillTimed(1, $MARGONITE_HERO_LIFE_BARRIER, GetMyAgent())		; costs 15 energy, 1 energy should be recovered during casting, energy should be maxed
	UseHeroSkillTimed(1, $MARGONITE_HERO_BLESSED_SIGNET)					; recover 9 hero energy
	Sleep(15000)																			; wait until Blessed signet is recharged, should recover 5 energy with 1 energy pip
	UseHeroSkillTimed(1, $MARGONITE_HERO_LIFE_BOND, GetMyAgent())			; costs 10 energy
	UseHeroSkillTimed(1, $MARGONITE_HERO_BLESSED_SIGNET)					; recover 11 hero energy, energy should be maxed
	Sleep(10000)																			; wait until Blessed signet is recharged, 0 pips
	UseHeroSkillTimed(1, $MARGONITE_HERO_VITAL_BLESSING, GetMyAgent())		; costs 10 energy
	UseHeroSkillTimed(1, $MARGONITE_HERO_BLESSED_SIGNET)					; recover 11 hero energy
	Sleep(10000)																			; wait until Blessed signet is recharged, around 3 energy lost with -1 pip
	UseHeroSkillTimed(1, $MARGONITE_HERO_BALTHAZAR_SPIRIT)					; costs 10 energy
	UseHeroSkillTimed(1, $MARGONITE_HERO_BLESSED_SIGNET)					; recover 11 hero energy, -2 pips, but energy will be recovered soon with balthazars spirit

	; Enable blessed signet skill so that hero uses it whenever it is recharged
	EnableHeroSkillSlot(1, $MARGONITE_HERO_BLESSED_SIGNET)
	PingSleep(50)

	Return $SUCCESS
EndFunc


Func GemstoneMargoniteFarmLoop()
	Local $me = Null, $target = Null
	Info('Starting Farm')
	MargoniteCsvLog('farm_start')

	CommandAll(-18571, -9328)
	RandomSleep(2000)
	CastBondsMargoniteFarm()
	EnableMargoniteHeroSkills()
	MargoniteCsvLog('bonds_done')
	If GetLightbringerTitle() < 50000 Then
		Info('Taking Blessing')
		GoNearestNPCToCoords(-17623, -9670)
		RandomSleep(1000)
		Dialog(0x85)
		RandomSleep(500)
	EndIf

	Local $questNPC = GetNearestNPCToCoords(-17710, -8811)
	If TakeQuest($questNPC, $ID_QUEST_THE_CITY_OF_TORC_QA, 0x82EF01) == $FAIL Then Return $FAIL

	Info('Moving to spot and aggroing margonites')
	MoveTo(-17541, -9431)

	; === East leg: run east pulling the front Margonite groups ===
	; The melees stay glued to us while the casters ball up behind (to the west).
	; The occasional stop to (re)cast buffs (MargoniteSurvive) also lets the mobs
	; catch up so they don't lose aggro.
	If MargoniteMoveLeg('east_1', -13935, -9850) == $FAIL Then Return $FAIL
	CommandAll(-16878, -9571)
	If MargoniteMoveLeg('east_2', -14321, -11803) == $FAIL Then Return $FAIL
	If MargoniteMoveLeg('east_3', -12115, -11057) == $FAIL Then Return $FAIL
	CommandAll(-14879, -11729)
	If MargoniteWait('Mobs nach east_3', 7000) == $FAIL Then Return $FAIL
	; Furthest east spot: pull the front mobs but stay close enough that the rear
	; mobs don't peel off and kill the monk hero.
	If MargoniteMoveLeg('east_far', -10277, -10778) == $FAIL Then Return $FAIL
	CommandAll(-12861, -12620)
	; Wait (~50s) for the far margonite group to come into range.
	If MargoniteWait('ferne Gruppe am East Spot', 50000) == $FAIL Then Return $FAIL

	; === South-west leg: run back south-west along the ledge (Vorsprung) ===
	; Hugging the wall in a curve makes GW mobs follow better, so the melees and
	; the new caster group get dragged onto the old caster ball (all casters stack).
	If MargoniteMoveLeg('sw_1', -12065, -10905) == $FAIL Then Return $FAIL
	If MargoniteWait('kurz sw_1', 5000) == $FAIL Then Return $FAIL
	If MargoniteMoveLeg('sw_2', -12246, -10149) == $FAIL Then Return $FAIL
	If MargoniteWait('kurz sw_2', 7000) == $FAIL Then Return $FAIL
	If MargoniteMoveLeg('sw_3', -12303, -10349) == $FAIL Then Return $FAIL
	If MargoniteMoveLeg('sw_4', -11410, -11359) == $FAIL Then Return $FAIL
	If MargoniteWait('kurz sw_4', 3000) == $FAIL Then Return $FAIL
	If MargoniteMoveLeg('sw_5', -11484, -11034) == $FAIL Then Return $FAIL
	If IsPlayerDead() Or IsHeroDead(1) Then Return $FAIL

	; if margonites group is somehow not in the spot then try to get closer to them
	; getting closer to nearest Anur Dabi or Kaya or Ki or Su, not nearest Vu, Ruk, Tuk
	$me = GetMyAgent()
	; Death's Charge into the CENTER of the caster ball, not onto a single caster at
	; its edge. Targeting one nearest caster (Anur Dabi/Kaya/Ki/Su) puts the Sin at the
	; rim of the ball, then the follow-up MoveTo chases that one caster while the rest of
	; the ball de-aggros and walks home — the kill phase then starts with only a few
	; melees around and "Killed 0 margonites". Averaging the caster positions lands the
	; Sin in the middle so the melees follow into the Famine kill zone.
	Local $margoniteCaster = GetNearestAgentToAgent($me, $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsAnurDabiOrKayaOrKiOrSu)
	Local $margoniteCasterCenter[] = [0, 0]
	If $margoniteCaster == Null Then
		; No caster in range — the Sin may already be balled (walked in during the SW
		; leg). Fall back to the nearest enemy and skip the centroid Death's Charge.
		MargoniteCsvLog('step', 'dc_fallback_no_caster')
		Info('Margonite: kein Caster gefunden - DC auf naechsten Gegner')
		$target = GetNearestEnemyToAgent($me)
	Else
		$margoniteCasterCenter = MargoniteCasterCentroid($margoniteCaster)
		$target = GetNearestEnemyToCoords($margoniteCasterCenter[0], $margoniteCasterCenter[1])
		Info('Margonite: Hinein-DC in den Caster mob')
		MargoniteCsvLog('step', 'dc_into_casters')
	EndIf
	If $target == Null Then
		MargoniteCsvLog('step', 'dc_aborted_no_target')
		Info('Margonite: kein Ziel gefunden - Abbruch')
		Return $FAIL
	EndIf
	; Diagnostic: log player / caster-seed / centroid / target coordinates so we can
	; see where the Death's Charge is actually pointing and why it might land wrong.
	Local $margoniteCasterStr = 'none'
	If $margoniteCaster <> Null Then
		$margoniteCasterStr = Round(DllStructGetData($margoniteCaster, 'X')) & '/' & Round(DllStructGetData($margoniteCaster, 'Y'))
	EndIf
	MargoniteCsvLog('dc_target', 'player=' & Round(DllStructGetData($me, 'X')) & '/' & Round(DllStructGetData($me, 'Y')) & _
		' caster=' & $margoniteCasterStr & _
		' centroid=' & Round($margoniteCasterCenter[0]) & '/' & Round($margoniteCasterCenter[1]) & _
		' target=' & Round(DllStructGetData($target, 'X')) & '/' & Round(DllStructGetData($target, 'Y')))
	Info('Margonite DC target: player=' & Round(DllStructGetData($me, 'X')) & ',' & Round(DllStructGetData($me, 'Y')) & _
		' caster=' & $margoniteCasterStr & _
		' centroid=' & Round($margoniteCasterCenter[0]) & ',' & Round($margoniteCasterCenter[1]) & _
		' target=' & Round(DllStructGetData($target, 'X')) & ',' & Round(DllStructGetData($target, 'Y')))
	; Ensure a healthy energy buffer BEFORE teleporting into the caster ball. The
	; Visages that kill the margonites are gated on >20 energy, and Anur Ki/Su
	; (Energy Surge mesmers) drain energy once we are in their range. Entering the
	; ball low on energy means the Visages never cast, nothing dies, and the Sin is
	; drained to death (seen as "Killed 0 margonites" + sudden death). Wait up to
	; ~15s for energy to recover to ~75% before the Death's Charge.
	Local $margoniteMaxEnergy = DllStructGetData(GetMyAgent(), 'MaxEnergy')
	Local $margoniteEnergyGoal = Int($margoniteMaxEnergy * 0.75)
	Local $margoniteEnergyTimer = TimerInit()
	While GetEnergy() < $margoniteEnergyGoal And TimerDiff($margoniteEnergyTimer) < 15000 And IsPlayerAlive()
		MargoniteSurvive()
		RandomSleep(250)
	WEnd
	If IsPlayerDead() Then Return $FAIL
	If $margonite_player_profession <> $ID_ELEMENTALIST Then
		If IsRecharged(MargoniteDeathChargeSlot()) Then
			Local $dcOk = UseSkillEx(MargoniteDeathChargeSlot(), $target)
			MargoniteCsvLog('step', 'dc_cast ok=' & $dcOk)
			Info('Margonite: Death Charge cast, ok=' & $dcOk)
			RandomSleep(50)
		Else
			MargoniteCsvLog('step', 'dc_skipped_not_recharged')
			Info('Margonite: Death Charge NICHT gecastet (nicht bereit)')
		EndIf
	EndIf
	; Keep Shadow Form (and the other buffs) up while closing the final distance into the
	; ball. This MoveTo used to run WITHOUT a survival routine, so SF could expire during
	; it and the Sin would be hexed and killed before the kill phase even started.
	MoveTo(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'), 100, MargoniteSurvive)

	If KillMargonites() == $FAIL Then Return $FAIL
	RandomSleep(1000)
	Info('Picking up loot')
	PickUpItems(MargoniteCheckBuffs)
	Return $SUCCESS
EndFunc


Func IsAnurDabiOrKayaOrKiOrSu($agent)
	; Use the canonical Margonite caster Model IDs from GWA2_ID.au3 (5217-5220).
	; The old hardcoded values (5166-5169) were wrong and matched nothing, so
	; GetNearestAgentToAgent always returned Null ("kein Caster gefunden").
	Return EnemyAgentFilter($agent) And _
		(DllStructGetData($agent, 'ModelID') == $ID_MARGONITE_ANUR_KAYA Or _
		DllStructGetData($agent, 'ModelID') == $ID_MARGONITE_ANUR_DABI Or _
		DllStructGetData($agent, 'ModelID') == $ID_MARGONITE_ANUR_SU Or _
		DllStructGetData($agent, 'ModelID') == $ID_MARGONITE_ANUR_KI)
EndFunc


;~ Compute the centroid of all Margonite casters (Anur Dabi/Kaya/Ki/Su) around the
;~ given seed caster. The generic FindMiddleOfFoes seeds from the nearest enemy of ANY
;~ type (GetNearestEnemyToCoords), which can land on a melee — then no caster is found
;~ within range, it warns "No foes to find middle of" and returns [0,0], sending the
;~ Sin to a nonsense spot. Seed from the caster directly and average all casters in
;~ earshot range instead.
Func MargoniteCasterCentroid($seedCaster)
	Local $position[] = [0, 0]
	Local $sumX = 0, $sumY = 0, $count = 0
	Local $casters = GetFoesInRangeOfAgent($seedCaster, $RANGE_EARSHOT, IsAnurDabiOrKayaOrKiOrSu)
	For $caster In $casters
		$sumX += DllStructGetData($caster, 'X')
		$sumY += DllStructGetData($caster, 'Y')
		$count += 1
	Next
	If $count == 0 Then
		$position[0] = DllStructGetData($seedCaster, 'X')
		$position[1] = DllStructGetData($seedCaster, 'Y')
		Return $position
	EndIf
	$position[0] = $sumX / $count
	$position[1] = $sumY / $count
	Return $position
EndFunc


Func WaitAggroMargonites($timeToWait)
	Local $timerAggro = TimerInit()
	While TimerDiff($timerAggro) < $timeToWait
		If IsPlayerDead() Or CheckStuck('Waiting for margonites aggro', $MAX_GEMSTONE_MARGONITE_FARM_DURATION) == $FAIL Then Return $FAIL
		MargoniteSurvive()
		RandomSleep(50)
	WEnd
	Return $SUCCESS
EndFunc


Func MargoniteMoveAndSurvive($destinationX, $destinationY)
	Local $result = Null
	Switch $margonite_player_profession
		Case $ID_ASSASSIN, $ID_MESMER, $ID_RANGER
			$result = MoveAvoidingBodyBlock($destinationX, $destinationY, $margonite_move_options)
		Case $ID_ELEMENTALIST
			$result = MoveAvoidingBodyBlock($destinationX, $destinationY, $margonite_move_options_elementalist)
	EndSwitch
	Return $result
	;~ ==== Disabled: fight-where-stuck fallback (re-enable if bodyblock kills runs) ====
	;~ If $result == $SUCCESS Then Return $SUCCESS
	;~ ; If no success when moving, either we died (the end) or we were bodyblocked
	;~ If IsPlayerDead() Then Return $FAIL
	;~ ; When playing as Elementalist or other professions that do not have deaths charge or heart of shadow skills, then fight Margonites wherever player got surrounded and stuck
	;~ If KillMargonites() == $FAIL Then Return $FAIL
	;~ RandomSleep(1000)
	;~ If IsPlayerDead() Then Return $FAIL
	;~ Info('Picking up loot')
	;~ PickUpItems(MargoniteCheckBuffs)
	;~ Return $SUCCESS
EndFunc


;~ Log a planned move leg, execute it, then log whether the Sin reached the spot.
Func MargoniteMoveLeg($label, $destinationX, $destinationY)
	Info('Margonite plan: ' & $label & ' -> (' & $destinationX & ', ' & $destinationY & ')')
	MargoniteCsvLog('plan', $label & ' target=' & $destinationX & '/' & $destinationY)
	Local $result = MargoniteMoveAndSurvive($destinationX, $destinationY)
	If $result == $SUCCESS Then
		Info('Margonite erreicht: ' & $label)
		MargoniteCsvLog('reached', $label)
	Else
		Info('Margonite FEHLER: ' & $label & ' nicht erreicht')
		MargoniteCsvLog('move_failed', $label)
	EndIf
	Return $result
EndFunc


;~ Log what the Sin is waiting for, then wait for margonite aggro.
Func MargoniteWait($label, $timeToWait)
	Info('Margonite warte: ' & $label & ' (' & $timeToWait & 'ms)')
	MargoniteCsvLog('wait', $label)
	Return WaitAggroMargonites($timeToWait)
EndFunc


Func MargoniteSurvive()
	Local Static $surviveLogTimer = TimerInit()
	MargoniteCheckBuffs()
	MargoniteMonkHeroHeal()
	If TimerDiff($surviveLogTimer) > 5000 Then
		MargoniteCsvLog('survive_state')
		$surviveLogTimer = TimerInit()
	EndIf
EndFunc


Func MargoniteMonkHeroHeal()
	Local $monkHero = GetAgentByID(GetHeroID(1))
	If $monkHero == Null Then Return
	If IsRecharged($MARGONITE_HERO_TROLL_UNGUENT, 1) And GetEnergy($monkHero) > 10 And _
		Not IsNearlyEqual(DllStructGetData($monkHero, 'HealthPercent'), 1) And GetEffect($ID_TROLL_UNGUENT, 1) == Null Then
		UseHeroSkill(1, $MARGONITE_HERO_TROLL_UNGUENT)
	EndIf
	; A peeled margonite can walk over and kill the monk hero (a protector with only
	; Troll Unguent for self-heal). The old hp<0.6 + foe<500 gate let a foe close to
	; ~100u and kill her in ~2s before she could move. Flag her toward the Sin EARLY —
	; as soon as a foe is approaching (~1200u) or she is taking damage — so she starts
	; escaping while the foe is still far away, and the mob re-aggros the Shadow-Formed
	; player instead of finishing the hero.
	Local $heroFoe = GetNearestEnemyToAgent($monkHero)
	If $heroFoe <> Null Then
		Local $heroFoeDist = GetDistance($monkHero, $heroFoe)
		If $heroFoeDist < 1200 Or DllStructGetData($monkHero, 'HealthPercent') < 0.85 Then
			Local $me = GetMyAgent()
			CommandHero(1, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'))
			MargoniteCsvLog('hero_escape', 'hp=' & Round(DllStructGetData($monkHero, 'HealthPercent') * 100, 1) & ' dist=' & Round($heroFoeDist))
		EndIf
	EndIf
EndFunc


Func MargoniteCheckBuffs()
	Local $me = Null, $target = Null
	If IsPlayerDead() Then Return $FAIL

	; Margonites cast quickening zephyr spirit which halves skill recharge time but increases skill energy cost by 30% and
	; famine spirit which deals damage when energy is 0, therefore Shadow Form and buffs skills usage is adjusted accordingly below
	If $margonite_player_profession <> $ID_ELEMENTALIST Then
		If IsRecharged($MARGONITE_SHADOWFORM) Then
			; Always cast Deadly Paradox before Shadow Form so SF's recharge is halved (15s < 19-21s
			; duration) independent of Quickening Zephyr. Relying on QZ alone caused SF to drop when the
			; Margonites die mid-kill (their QZ spirit disappears): SF recharge jumps 15s -> 30s > duration,
			; leaving a ~10s gap where the Sin can be hexed and killed.
			; Deadly Paradox (~19.5e under QZ) + Shadow Form (~13e under QZ) need ~33e together.
			; The margonite mesmers (Anur Ki/Su) drain energy hard during the pull — if energy is
			; short when SF comes up for refresh, DP+SF can't both fire, SF lapses and the Sin
			; dies (seen during the east_far wait). Wait up to ~4s for enough energy first.
			Local $sfEnergyTimer = TimerInit()
			While IsPlayerAlive() And GetEnergy() < 33 And TimerDiff($sfEnergyTimer) < 4000
				RandomSleep(200)
			WEnd
			If IsPlayerDead() Then Return $FAIL
			UseSkillEx($MARGONITE_DEADLY_PARADOX)
			; SF costs ~13 energy under QZ (UseSkillEx only checks the base cost), so a momentary
			; energy shortfall can make the cast silently fail and leave the Sin un-shadowed. Retry
			; on cast failure (UseSkillEx returns False) a few times so one miss can't end the run.
			; NOTE: do not gate on GetEffectTimeRemaining() == 0 — a just-expired (stale) SF effect
			; reports a clamped 1ms, not 0, which would wrongly skip the recast and leave the Sin
			; running into the ball unprotected.
			Local $sfRetries = 0
			While IsPlayerAlive() And $sfRetries < 4
				If UseSkillEx($MARGONITE_SHADOWFORM) Then ExitLoop
				$sfRetries += 1
				RandomSleep(200)
			WEnd
		EndIf
		If IsRecharged($MARGONITE_SHROUD_OF_DISTRESS) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEnergy() > 14 Then UseSkillEx($MARGONITE_SHROUD_OF_DISTRESS)
	EndIf

	Switch $margonite_player_profession
		Case $ID_ASSASSIN
			If IsRecharged($MARGONITE_ASSASSIN_GREAT_DWARF_ARMOR) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEnergy() > 8 And GetEffect($ID_GREAT_DWARF_ARMOR) == Null Then UseSkillEx($MARGONITE_ASSASSIN_GREAT_DWARF_ARMOR)
		Case $ID_MESMER
			If IsRecharged($MARGONITE_MESMER_WAY_OF_PERFECTION) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEnergy() > 8 And GetEffect($ID_WAY_OF_PERFECTION) == Null Then UseSkillEx($MARGONITE_MESMER_WAY_OF_PERFECTION)
		Case $ID_ELEMENTALIST
			MargoniteCheckBuffsElementalist()
		Case $ID_RANGER
			; Keep Whirling Defense up while aggroing so Paragons don't build adrenaline (guide).
			If IsRecharged($MARGONITE_RANGER_WHIRLING_DEFENSE) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEnergy() > 8 Then UseSkillEx($MARGONITE_RANGER_WHIRLING_DEFENSE)
			If IsRecharged($MARGONITE_RANGER_DWARVEN_STABILITY) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEnergy() > 8 Then UseSkillEx($MARGONITE_RANGER_DWARVEN_STABILITY)
			If IsRecharged($MARGONITE_RANGER_UNSEEN_FURY) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEffect($ID_WHIRLING_DEFENSE) == Null Then UseSkillEx($MARGONITE_RANGER_UNSEEN_FURY)
	EndSwitch

	If IsRecharged(MargoniteIAUSlot()) And GetEnergy() > 8 Then UseSkillEx(MargoniteIAUSlot())
	;~ Disabled: emergency Death's Charge on low health. It targeted the NEAREST
	;~ enemy, which during the south-west leg is a caster in the ball — so the Sin
	;~ shadow-stepped INTO the ball mid-pull and died. The kill-phase DC is done
	;~ explicitly AFTER the pull, so this survival DC is redundant and harmful.
	;~ If $margonite_player_profession <> $ID_ELEMENTALIST Then
	;~ 	$me = GetMyAgent()
	;~ 	$target = GetNearestEnemyToAgent($me)
	;~ 	If IsRecharged(MargoniteDeathChargeSlot()) And Not IsRecharged($MARGONITE_SHADOWFORM) And _
	;~ 			GetDistance($me, $target) < $MARGONITES_RANGE And DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.3 Then
	;~ 		UseSkillEx(MargoniteDeathChargeSlot(), $target)
	;~ 		PingSleep(50)
	;~ 	EndIf
	;~ EndIf
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func MargoniteCheckBuffsElementalist()
	If TimerDiff($margonite_elemental_lord_timer) > 50000 And GetEnergy() > 8 Then
		UseSkillEx($MARGONITE_ELEMENTALIST_ELEMENTAL_LORD)
		$margonite_elemental_lord_timer = TimerInit()
	EndIf
	If TimerDiff($margonite_aura_of_restoration_timer) > 50000 And GetEnergy() > 8 Then
		UseSkillEx($MARGONITE_ELEMENTALIST_AURA_OF_RESTORATION)
		$margonite_aura_of_restoration_timer = TimerInit()
	EndIf
	If IsRecharged($MARGONITE_ELEMENTALIST_OBSIDIAN_FLESH) And TimerDiff($margonite_obsidian_flesh_timer) > 14000 Then
		While GetEnergy() < 8 And IsPlayerAlive()
			Sleep(100)
		WEnd
		UseSkillEx($MARGONITE_ELEMENTALIST_GLYPH_OF_SWIFTNESS)
		While GetEnergy() < 32 And IsPlayerAlive()
			Sleep(100)
		WEnd
		Local $ofOk = UseSkillEx($MARGONITE_ELEMENTALIST_OBSIDIAN_FLESH)
		MargoniteCsvLog('of_cast', 'ok=' & $ofOk)
		$margonite_obsidian_flesh_timer = TimerInit()
	EndIf
	If IsRecharged($MARGONITE_ELEMENTALIST_STONEFLESH_AURA) And TimerDiff($margonite_stoneflesh_aura_timer) > 10000 And Not IsRecharged($MARGONITE_ELEMENTALIST_OBSIDIAN_FLESH) Then
		While GetEnergy() < 12 And IsPlayerAlive()
			Sleep(100)
		WEnd
		UseSkillEx($MARGONITE_ELEMENTALIST_STONEFLESH_AURA)
		$margonite_stoneflesh_aura_timer = TimerInit()
	EndIf
EndFunc


;~ Resolve the Death's Charge slot for the current profession. The Assassin
;~ double-visage build moves it from slot 5 to 8.
Func MargoniteDeathChargeSlot()
	Return ($margonite_player_profession == $ID_ASSASSIN) ? $MARGONITE_ASSASSIN_DEATHS_CHARGE : $MARGONITE_DEATHS_CHARGE
EndFunc


;~ Resolve the "I Am Unstoppable!" slot for the current profession. The Assassin
;~ double-visage build moves it from slot 6 to 5.
Func MargoniteIAUSlot()
	Return ($margonite_player_profession == $ID_ASSASSIN) ? $MARGONITE_ASSASSIN_I_AM_UNSTOPPABLE : $MARGONITE_I_AM_UNSTOPPABLE
EndFunc


;~ Resolve the Ancestor's Visage slot for the current profession. The Assassin
;~ double-visage build moves it from slot 7 to 6.
Func MargoniteAncestorsVisageSlot()
	Return ($margonite_player_profession == $ID_ASSASSIN) ? $MARGONITE_ASSASSIN_ANCESTORS_VISAGE : $MARGONITE_ANCESTORS_VISAGE
EndFunc


Func KillMargonites()
	Info('Fighting margonites')
	; Count foes in the kill ball before the fight so we can report how many were killed (Berserker-style).
	Local $foesBefore = CountFoesInRangeOfAgent(GetMyAgent(), $MARGONITES_RANGE)
	UseHeroSkill(1, $MARGONITE_HERO_EDGE_OF_EXTINCTION)
	; The monk hero stays at her last CommandAll spot (~2200u from the ball). Both
	; bond range and loot range are compass range (5000u), so moving her out of loot
	; range would also drop the bonds — they're the same limit. Leave her put.
	Switch $margonite_player_profession
		Case $ID_ASSASSIN, $ID_MESMER, $ID_ELEMENTALIST
			KillMargonitesUsingVisageSkills()
		Case $ID_RANGER
			KillMargonitesUsingWhirlingDefense()
	EndSwitch
	; Count survivors after the kill and report the kill count (clamped at 0 so a
	; late straggler can never make the count negative).
	Local $foesAfter = CountFoesInRangeOfAgent(GetMyAgent(), $MARGONITES_RANGE)
	Local $foesKilled = $foesBefore - $foesAfter
	If $foesKilled < 0 Then $foesKilled = 0
	MargoniteCsvLog('kill_count', 'killed=' & $foesKilled & ';before=' & $foesBefore & ';after=' & $foesAfter)
	Info('Killed ' & $foesKilled & ' margonites')
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func KillMargonitesUsingVisageSkills()
	If IsPlayerDead() Then Return $FAIL
	MargoniteCsvLog('kill_start')
	Local $timerKill = TimerInit()
	Local $logTimer = TimerInit()
	Local $adjacentTimer = TimerInit()
	Local Static $maxFightTime = 100000

	While CountFoesInRangeOfAgent(GetMyAgent(), $MARGONITES_RANGE) > 0 And TimerDiff($timerKill) < $maxFightTime And Not IsHeroDead(1)
		RandomSleep(100)
		MargoniteSurvive()
		If TimerDiff($logTimer) > 5000 Then
			MargoniteCsvLog('fight_state')
			$logTimer = TimerInit()
		EndIf

		; Early abort: Ancestor's/Sympathetic Visage only drain ADJACENT (156u) foes.
		; If nothing is adjacent for 10s, the survivors have de-aggroed / drifted out of
		; drain range and will never die — the loop would otherwise just stall against
		; the 100s cap. Resign instead of wasting ~90s.
		If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_ADJACENT) > 0 Then
			$adjacentTimer = TimerInit()
		ElseIf TimerDiff($adjacentTimer) > 10000 Then
			MargoniteCsvLog('kill_abort_no_adjacent')
			Info('Margonite: keine Gegner mehr in Adjacent-Range (10s) - Kill-Loop beendet')
			Return $FAIL
		EndIf

		; A Margonite knockdown can make the 2s Visage cast fail to even start
		; (UseSkillEx returns False when the cast never begins -> 'visage_av ok=False').
		; IAU prevents knockdown, so keep it up right before the Visages so they land.
		If IsRecharged(MargoniteIAUSlot()) And GetEnergy() > 8 Then
			UseSkillEx(MargoniteIAUSlot())
		EndIf

		; Ancestor's Visage drains enemy energy to 0 so the Famine spirit kills them.
		; QZ raises its energy cost by +30% (~20), so require > 20 energy and don't
		; gate on the tank skill recharge (that alignment never matched, see issue #235).
		; Each Visage is gated only on its OWN effect so AV + SV stack for 6 e/hit.
		If IsRecharged(MargoniteAncestorsVisageSlot()) And GetEffect($ID_ANCESTORS_VISAGE) == Null And GetEnergy() > 20 Then
			Local $avOk = UseSkillEx(MargoniteAncestorsVisageSlot())
			MargoniteCsvLog('visage_av', 'ok=' & $avOk)
		EndIf

		Switch $margonite_player_profession
			Case $ID_ELEMENTALIST
				If IsRecharged($MARGONITE_ELEMENTALIST_SYMPATHETICVISAGE) And GetEffect($ID_SYMPATHETIC_VISAGE) == Null And GetEnergy() > 20 Then
					Local $svOk = UseSkillEx($MARGONITE_ELEMENTALIST_SYMPATHETICVISAGE)
					MargoniteCsvLog('visage_sv', 'ok=' & $svOk)
				EndIf
			Case $ID_ASSASSIN
				; Sympathetic Visage (slot 7) stacks with Ancestor's Visage for 6 e/hit, halving
				; the time for each Margonite to hit 0 energy and die to its own Famine spirit.
				If IsRecharged($MARGONITE_ASSASSIN_SYMPATHETIC_VISAGE) And GetEffect($ID_SYMPATHETIC_VISAGE) == Null And GetEnergy() > 20 Then
					Local $svOk = UseSkillEx($MARGONITE_ASSASSIN_SYMPATHETIC_VISAGE)
					MargoniteCsvLog('visage_sv', 'ok=' & $svOk)
				EndIf
			Case $ID_MESMER
				; Mesmer build keeps Lightbringer's Gaze in slot 8 (direct holy damage, capped at
				; 21/hit under Shadow Form). Cast when energy runs low as a filler/interrupt.
				If IsRecharged($MARGONITE_MESMER_LIGHTBRINGERS_GAZE) And GetEnergy() < 20 Then
					UseSkillEx($MARGONITE_MESMER_LIGHTBRINGERS_GAZE)
					RandomSleep(100)
				EndIf
		EndSwitch
		If IsPlayerDead() Then Return $FAIL
	WEnd
	MargoniteCsvLog('kill_end')
	Return $SUCCESS
EndFunc


Func KillMargonitesUsingWhirlingDefense()
	If IsPlayerDead() Then Return $FAIL
	MargoniteCsvLog('kill_start')
	Local $timerKill = TimerInit()
	Local $logTimer = TimerInit()
	Local Static $maxFightTime = 100000

	While CountFoesInRangeOfAgent(GetMyAgent(), $MARGONITES_RANGE) > 0 And TimerDiff($timerKill) < $maxFightTime And Not IsHeroDead(1)
		RandomSleep(100)
		MargoniteSurvive()
		If TimerDiff($logTimer) > 5000 Then
			MargoniteCsvLog('fight_state')
			$logTimer = TimerInit()
		EndIf

		If IsRecharged($MARGONITE_RANGER_DWARVEN_STABILITY) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEnergy() > 8 Then
			UseSkillEx($MARGONITE_RANGER_DWARVEN_STABILITY)
			RandomSleep(100)
		EndIf
		If IsRecharged($MARGONITE_RANGER_WHIRLING_DEFENSE) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEnergy() > 8 Then
			UseSkillEx($MARGONITE_RANGER_WHIRLING_DEFENSE)
			RandomSleep(100)
		EndIf
		If IsPlayerDead() Then Return $FAIL
	WEnd
	MargoniteCsvLog('kill_end')
	Return $SUCCESS
EndFunc


;~ Write a CSV debug row (AmFah600-style) to debug the Margonite farm.
;~ Set $MARGONITE_DEBUG_LOG to True to enable. Output: logs/margonite_debug-<char>.csv
Func MargoniteCsvLog($event, $detail = '')
	If Not $MARGONITE_DEBUG_LOG Then Return
	Local Static $csvHandle = Null
	If $csvHandle == Null Then
		Local $csvPath = @ScriptDir & '/logs/margonite_debug-' & GetCharacterName() & '.csv'
		$csvHandle = FileOpen($csvPath, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
		If $csvHandle == -1 Then Return ; silently skip if file can't be opened
		Info('Margonite CSV: ' & $csvPath)
		FileWriteLine($csvHandle, 'timestamp,elapsed_ms,event,detail,profession,energy,max_energy,hp%,player_x,player_y,moving,hero_hp%,hero_x,hero_y,hero_foe_dist,hero_foe_x,hero_foe_y,sf_ms,of_ms,sa_ms,av_ms,sv_ms,wd_ms,foes_earshot')
	EndIf

	Local $alive = IsPlayerAlive()
	Local $elapsed = TimerDiff($run_timer)
	Local $prof = '?'
	Switch $margonite_player_profession
		Case $ID_ASSASSIN
			$prof = 'A'
		Case $ID_MESMER
			$prof = 'Me'
		Case $ID_ELEMENTALIST
			$prof = 'E'
		Case $ID_RANGER
			$prof = 'R'
	EndSwitch

	Local $energy = 0, $maxEnergy = 0, $hp = 0, $playerX = 0, $playerY = 0, $moving = 0, $sfMs = 0, $ofMs = 0, $saMs = 0, $avMs = 0, $svMs = 0, $wdMs = 0, $foes = 0
	If $alive Then
		$energy = Round(GetEnergy())
		$maxEnergy = DllStructGetData(GetMyAgent(), 'MaxEnergy')
		$hp = Round(DllStructGetData(GetMyAgent(), 'HealthPercent') * 100, 1)
		$playerX = Round(DllStructGetData(GetMyAgent(), 'X'))
		$playerY = Round(DllStructGetData(GetMyAgent(), 'Y'))
		$moving = IsPlayerMoving() ? 1 : 0
		$sfMs = Round(GetEffectTimeRemaining($ID_SHADOW_FORM))
		$ofMs = Round(GetEffectTimeRemaining($ID_OBSIDIAN_FLESH))
		$saMs = Round(GetEffectTimeRemaining($ID_STONEFLESH_AURA))
		$avMs = Round(GetEffectTimeRemaining($ID_ANCESTORS_VISAGE))
		$svMs = Round(GetEffectTimeRemaining($ID_SYMPATHETIC_VISAGE))
		$wdMs = Round(GetEffectTimeRemaining($ID_WHIRLING_DEFENSE))
		$foes = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
	EndIf

	Local $heroHp = 0
	Local $heroX = 0, $heroY = 0, $heroFoeDist = 0, $heroFoeX = 0, $heroFoeY = 0
	Local $hero = GetAgentByID(GetHeroID(1))
	If $hero <> Null Then
		$heroHp = Round(DllStructGetData($hero, 'HealthPercent') * 100, 1)
		$heroX = Round(DllStructGetData($hero, 'X'))
		$heroY = Round(DllStructGetData($hero, 'Y'))
		Local $heroFoe = GetNearestEnemyToAgent($hero)
		If $heroFoe <> Null Then
			$heroFoeDist = Round(GetDistance($hero, $heroFoe))
			$heroFoeX = Round(DllStructGetData($heroFoe, 'X'))
			$heroFoeY = Round(DllStructGetData($heroFoe, 'Y'))
		EndIf
	EndIf

	Local $detailSafe = StringReplace($detail, ',', ' ')
	Local $ts = @YEAR & '-' & @MON & '-' & @MDAY & ' ' & @HOUR & ':' & @MIN & ':' & @SEC
	FileWriteLine($csvHandle, $ts & ',' & Round($elapsed, 0) & ',' & $event & ',' & $detailSafe & ',' & $prof & ',' & $energy & ',' & $maxEnergy & ',' & $hp & ',' & $playerX & ',' & $playerY & ',' & $moving & ',' & $heroHp & ',' & $heroX & ',' & $heroY & ',' & $heroFoeDist & ',' & $heroFoeX & ',' & $heroFoeY & ',' & $sfMs & ',' & $ofMs & ',' & $saMs & ',' & $avMs & ',' & $svMs & ',' & $wdMs & ',' & $foes)
EndFunc