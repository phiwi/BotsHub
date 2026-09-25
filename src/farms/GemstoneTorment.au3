#CS ===========================================================================
=========================================
|		Torment Gemstones Farm bot		|
|				TonReuf					|
=========================================
;
; Run this farm bot as Elementalist
;
; Rewritten for BotsHub: Gahais
; Torment gemstone farm in the Ravenheart Gloom based on below article:
https://gwpvx.fandom.com/wiki/Build:E/A_Obsidian_Flesh_Gloom_Farmer
;
#CE ===========================================================================

#include-once
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'


#Region Configuration
; === Build ===
Global Const $EA_TORMENT_SKILLBAR = 'OgdTkSFzSC3xF0YQbAYYYgXoXA'

Global Const $TORMENT_DEATHS_CHARGE				= 1
Global Const $TORMENT_ELEMENTAL_LORD			= 2
Global Const $TORMENT_GLYPH_OF_ELEMENTAL_POWER	= 3
Global Const $TORMENT_OBSIDIAN_FLESH			= 4
Global Const $TORMENT_METEOR_SHOWER				= 5
Global Const $TORMENT_LAVA_FONT					= 6
Global Const $TORMENT_FLAME_BURST				= 7
Global Const $TORMENT_RODGORTS_INVOCATION		= 8
#EndRegion Configuration

; ==== Constants ====
Global Const $GEMSTONE_TORMENT_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- At least 100 energy to be able to cast all the spells' & @CRLF _
	& '- Full Radiant Armor with Attunement Runes to max out energy' & @CRLF _
	& '- Spear/Sword/Axe +5 energy of Enchanting (20% longer enchantments duration)' & @CRLF _
	& '- A focus with a Live for Today inscription (+15 energy, -1 energy degeneration) to max out energy' & @CRLF _
	& ' ' & @CRLF _
	& 'You can run this farm as Elementalist. Bot will set up build automatically' & @CRLF _
	& 'This bot farms torment gemstones (1 of 4 types) in Ravenheart Gloom location' & @CRLF _
	& 'Player needs to have access to Gate of Anguish outpost which has exit to RavenHeart Gloom location' & @CRLF _
	& 'Recommended to have maxed out Lightbringer title. If not maxed out then this farm is good for raising lightbringer rank' & @CRLF _
	& 'It is recommended to run this farm in normal mode' & @CRLF _
	& 'Gemstones can be exchanged into armbrace of truth (15 of each type) or coffer of whisper (1 of each type)' & @CRLF _
	& 'This farm bot is based on below article:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:E/A_Obsidian_Flesh_Gloom_Farmer' & @CRLF
; Average duration ~ 10 minutes
Global Const $GEMSTONE_TORMENT_FARM_DURATION = 10 * 60 * 1000
Global Const $MAX_GEMSTONE_TORMENT_FARM_DURATION = 20 * 60 * 1000

; Staff of enchanting 20% for the run and faster energy regeneration
Global Const $TORMENT_WEAPON_SLOT_STAFF = 2
; Weapon set used for the fire spike
Global Const $TORMENT_WEAPON_SLOT_FOCUS = 1
; Curse of Darkness (Shadow Army necromancer) — the second group in Ravenheart Gloom.
Global Const $TORMENT_MODELID_CURSE_OF_DARKNESS = 5244

; Set to True to write a CSV debug log (logs/torment_debug-<char>.csv)
Global Const $TORMENT_DEBUG_LOG = True

Global $torment_run_options						= CloneMap($default_move_options)
$torment_run_options['movementRoutine']			= SurviveTormentFarm
$torment_run_options['moveTimeout']				= 3 * 60 * 1000
$torment_run_options['moveVariance']			= 200
$torment_run_options['skillSlotDeathsCharge']	= $TORMENT_DEATHS_CHARGE
; chests in Ravenheart Gloom should have good loot
$torment_run_options['openChests']				= True

Global $gemstone_torment_farm_setup = False

;~ Main loop function for farming torment gemstones
Func GemstoneTormentFarm()
	If Not $gemstone_torment_farm_setup And SetupGemstoneTormentFarm() == $FAIL Then Return $PAUSE

	If GoToRavenHeartGloom() == $FAIL Then Return $FAIL
	Local $result = GemstoneTormentFarmLoop()
	If $result == $SUCCESS Then
		Info('Successfully cleared torment mobs')
		TormentCsvLog('farm_success')
	EndIf
	If $result == $FAIL Then
		Info('Player died. Could not clear torment mobs')
		TormentCsvLog('farm_death')
	EndIf
	Info('Returning back to the outpost')
	ResignAndReturnToOutpost($ID_GATE_OF_ANGUISH, true)
	Return $result
EndFunc


Func SetupGemstoneTormentFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_GATE_OF_ANGUISH Then
		If TravelToOutpost($ID_GATE_OF_ANGUISH, $district_name) == $FAIL Then Return $FAIL
	Else
		ResignAndReturnToOutpost($ID_GATE_OF_ANGUISH, true)
	EndIf
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerTormentFarm() == $FAIL Then Return $FAIL
	LeaveParty()
	SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)
	RandomSleep(500)
	$gemstone_torment_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerTormentFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ELEMENTALIST Then
		If HeroHasTemplate(0, $EA_TORMENT_SKILLBAR) Then
			Info('Torment player: template already loaded, skipping')
		Else
			LoadSkillTemplate($EA_TORMENT_SKILLBAR)
			RandomSleep(250)
		EndIf
	Else
		Warn('You need to run this farm bot as Elementalist')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ exit gate of Anguish outpost by moving into portal that leads into farming location - RavenHeart Gloom
Func GoToRavenHeartGloom()
	TravelToOutpost($ID_GATE_OF_ANGUISH, $district_name)
	Info('Moving to RavenHeart Gloom')
	; Unfortunately all 4 gemstone farm explorable locations have the same map ID as Gate of Anguish outpost, so it is harder to tell if player left the outpost
	; Therefore below loop checks if player is in close range of coordinates of that start zone where player initially spawns in RavenHeart Gloom
	Local Static $startX = 16034
	Local Static $startY = 1244
	Local $timerZoning = TimerInit()
	While Not IsAgentInRange(GetMyAgent(), $startX, $startY, $RANGE_EARSHOT)
		If TimerDiff($timerZoning) > 120000 Then
			Info('Could not zone to RavenHeart Gloom')
			Return $FAIL
		EndIf
		MoveTo(6798, -15867)
		MoveTo(5487, -17983)
		MoveTo(6489, -20099)
		Move(6700, -21250)
		Sleep(8000)
	WEnd
EndFunc


Func GemstoneTormentFarmLoop()
	Info('Starting Farm')
	TormentCsvLog('farm_start')
	Local $timerWait
	Local $maxEnergy = DllStructGetData(GetMyAgent(), 'MaxEnergy')

	Info('Changing Weapons: Slot ' & $TORMENT_WEAPON_SLOT_STAFF & ' - Staff')
	ChangeWeaponSet($TORMENT_WEAPON_SLOT_STAFF)
	RandomSleep(250)
	TormentCsvLog('weapon_staff')
	If GetLightbringerTitle() < 50000 Then
		Info('Taking Blessing')
		GoNearestNPCToCoords(16457, 1801)
		Sleep(1000)
		Dialog(0x85)
		Sleep(500)
	EndIf

	If RunTormentFarm(15125, 2794) == $FAIL Then Return $FAIL
	If RunTormentFarm(15561, 5241) == $FAIL Then Return $FAIL
	$timerWait = TimerInit()
	While TimerDiff($timerWait) < 5000 And IsPlayerAlive()
		RandomSleep(100)
	WEnd
	$timerWait = TimerInit()
	TormentCsvLog('initial_of_before')
	Local $initialOfOk = UseSkillTimed($TORMENT_OBSIDIAN_FLESH)
	TormentCsvLog('initial_of_after', 'ok=' & $initialOfOk)
	While TimerDiff($timerWait) < 2000 And IsPlayerAlive()
		RandomSleep(100)
	WEnd

	If RunTormentFarm(12304, 9022) == $FAIL Then Return $FAIL
	If RunTormentFarm(11444, 9370) == $FAIL Then Return $FAIL
	If RunTormentFarm(10828, 10583) == $FAIL Then Return $FAIL
	$timerWait = TimerInit()
	While IsPlayerAlive() And (TimerDiff($timerWait) < 15000 Or Not IsRecharged($TORMENT_OBSIDIAN_FLESH) Or GetEnergy() < ($maxEnergy - 0.5))
		RandomSleep(100)
	WEnd
	Info('First group')
	TormentCsvLog('first_group')
	CastBuffsTormentFarm()
	If RunTormentFarm(10779, 9898) == $FAIL Then Return $FAIL
	;If RunTormentFarm(11125, 9198) == $FAIL Then Return $FAIL
	Info('Changing Weapons: Slot ' & $TORMENT_WEAPON_SLOT_FOCUS & ' - Focus')
	ChangeWeaponSet($TORMENT_WEAPON_SLOT_FOCUS)
	RandomSleep(500)
	TormentCsvLog('weapon_focus')
	If KillTormentMobs() == $FAIL Then Return $FAIL
	Info('Picking up loot')
	PickUpItems()

	Info('Changing Weapons: Slot ' & $TORMENT_WEAPON_SLOT_STAFF & ' - Staff')
	ChangeWeaponSet($TORMENT_WEAPON_SLOT_STAFF)
	RandomSleep(250)
	; Route around the Tormentor "pillar of eyes" group toward the second group
	; (six Curse of Darkness, model 5244). Path recorded manually 2026-09-21.
	If RunTormentFarm(11035, 11944) == $FAIL Then Return $FAIL
	If RunTormentFarm(11170, 14185) == $FAIL Then Return $FAIL
	If RunTormentFarm(11335, 14928) == $FAIL Then Return $FAIL
	If RunTormentFarm(11735, 15908) == $FAIL Then Return $FAIL
	If RunTormentFarm(12170, 17079) == $FAIL Then Return $FAIL
	If RunTormentFarm(13566, 16981) == $FAIL Then Return $FAIL
	If RunTormentFarm(14938, 17129) == $FAIL Then Return $FAIL
	; Staging spot — hold here (safely outside the group's aggro) while energy recovers.
	If RunTormentFarm(15248, 16661) == $FAIL Then Return $FAIL
	TormentLogNearbyFoes('second_group_at_staging')
	$timerWait = TimerInit()
	Local $waitLogTimer = TimerInit()
	While IsPlayerAlive() And (TimerDiff($timerWait) < 42000 Or Not IsRecharged($TORMENT_ELEMENTAL_LORD) Or _
			Not IsRecharged($TORMENT_OBSIDIAN_FLESH) Or Not IsRecharged($TORMENT_METEOR_SHOWER) Or GetEnergy() < ($maxEnergy - 0.5))
		SurviveTormentFarm()
		If TimerDiff($waitLogTimer) > 5000 Then
			TormentCsvLog('wait_tick')
			$waitLogTimer = TimerInit()
		EndIf
		RandomSleep(100)
	WEnd
	Info('Second group')
	TormentCsvLog('second_group')
	CastBuffsTormentFarm()
	RandomSleep(250)
	TormentLogNearbyFoes('second_group_before_approach')
	; Move into Death's Charge range of the Curse of Darkness ball.
	If RunTormentFarm(15613, 16283) == $FAIL Then Return $FAIL
	Info('Changing Weapons: Slot ' & $TORMENT_WEAPON_SLOT_FOCUS & ' - Focus')
	ChangeWeaponSet($TORMENT_WEAPON_SLOT_FOCUS)
	RandomSleep(500)
	TormentCsvLog('weapon_focus')
	If KillTormentMobs($TORMENT_MODELID_CURSE_OF_DARKNESS) == $FAIL Then Return $FAIL

	Info('Picking up loot')
	PickUpItems()
	Return $SUCCESS
EndFunc


Func RunTormentFarm($destinationX, $destinationY)
	Return MoveAvoidingBodyBlock($destinationX, $destinationY, $torment_run_options)
EndFunc


Func CastBuffsTormentFarm()
	If IsPlayerDead() Then Return $FAIL
	RandomSleep(150)
	TormentCsvLog('buffs_before')
	Local $elOk = UseSkillTimed($TORMENT_ELEMENTAL_LORD)
	TormentCsvLog('buffs_el', 'ok=' & $elOk)
	Local $glyphOk = UseSkillTimed($TORMENT_GLYPH_OF_ELEMENTAL_POWER)
	TormentCsvLog('buffs_glyph', 'ok=' & $glyphOk)
	Local $ofOk = UseSkillTimed($TORMENT_OBSIDIAN_FLESH)
	TormentCsvLog('buffs_of', 'ok=' & $ofOk)
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func SurviveTormentFarm()
	Local $me = GetMyAgent(), $target = Null

	If (DllStructGetData($me, 'HealthPercent') < 0.3 Or _
			(DllStructGetData($me, 'HealthPercent') < 0.4 And GetHasCondition($me))) And _
			CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST) > 0 And _
			IsRecharged($TORMENT_DEATHS_CHARGE) And GetEnergy() > 5 Then
		$target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_SPELLCAST)
		UseSkillTimed($TORMENT_DEATHS_CHARGE, $target)
	EndIf
EndFunc


;~ Walk toward a destination but stop as soon as a foe is within its aggro bubble
;~ (plus a small safety margin). This keeps the Ele from pulling a group before her
;~ Obsidian Flesh buff is up — the second group's old DPS spot sat inside aggro range.
Func TormentMoveToAggroEdge($destinationX, $destinationY, $safetyDistance = 150)
	Local $stopDistance = $MOB_AGGRO_RANGE + $safetyDistance
	Local $me = GetMyAgent()
	Local $foe = GetNearestEnemyToAgent($me)
	While IsPlayerAlive() And GetDistanceToPoint($me, $destinationX, $destinationY) > $RANGE_NEARBY
		SurviveTormentFarm()
		$me = GetMyAgent()
		$foe = GetNearestEnemyToAgent($me)
		If $foe <> Null And GetDistance($me, $foe) < $stopDistance Then
			CancelAction()
			Return $SUCCESS
		EndIf
		Move($destinationX, $destinationY)
		RandomSleep(200)
		$me = GetMyAgent()
	WEnd
	; The in-flight Move is still active here — cancel it so she actually HOLDS at the
	; aggro edge instead of walking the rest of the way into the group / a straggler.
	CancelAction()
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Log the ModelIDs of all foes in earshot so we can identify which enemy group is
;~ actually being targeted (Tormentors vs. Shadow Army "Curse of Darkness").
Func TormentLogNearbyFoes($label)
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
	Local $ids = ''
	For $foe In $foes
		$ids &= DllStructGetData($foe, 'ModelID') & ';'
	Next
	Info('Torment [' & $label & '] player=' & Round(DllStructGetData(GetMyAgent(), 'X')) & '/' & Round(DllStructGetData(GetMyAgent(), 'Y')) & ' foes=' & $ids)
EndFunc


;~ Get nearest foe matching a specific ModelID (e.g. Curse of Darkness) within range.
Func GetNearestFoeByModelID($modelID, $range = $RANGE_COMPASS)
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $range)
	Local $nearest = Null
	Local $bestDist = 99999
	Local $me = GetMyAgent()
	For $foe In $foes
		If DllStructGetData($foe, 'ModelID') == $modelID Then
			Local $d = GetDistance($me, $foe)
			If $d < $bestDist Then
				$bestDist = $d
				$nearest = $foe
			EndIf
		EndIf
	Next
	Return $nearest
EndFunc


Func KillTormentMobs($modelID = Null)
	If IsPlayerDead() Then Return $FAIL
	TormentCsvLog('kill_start')
	TormentLogNearbyFoes('kill_start')
	Local $target = Null

	; Death's Charge first, onto the centroid enemy in the middle of the ball.
	Local $nearest = GetNearestEnemyToAgent(GetMyAgent())
	If $modelID <> Null Then
		Local $preferred = GetNearestFoeByModelID($modelID)
		If $preferred <> Null Then $nearest = $preferred
	EndIf
	Local $center = FindMiddleOfFoes(DllStructGetData($nearest, 'X'), DllStructGetData($nearest, 'Y'), $RANGE_SPELLCAST)
	$target = GetNearestEnemyToCoords($center[0], $center[1])
	ChangeTarget($target)
	UseSkillTimed($TORMENT_DEATHS_CHARGE, $target)
	; Then Meteor Shower, Lava Font, Flame Burst and Rodgort's Invocation (5-6-7-8).
	$target = GetNearestEnemyToAgent(GetMyAgent())
	UseSkillTimed($TORMENT_METEOR_SHOWER, $target)
	UseSkillTimed($TORMENT_LAVA_FONT)
	UseSkillTimed($TORMENT_FLAME_BURST)
	UseSkillTimed($TORMENT_RODGORTS_INVOCATION, $target)
	; waiting for mobs to be cleaned by meteor shower
	RandomSleep(1500)

	TormentCsvLog('kill_end')
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Write a CSV debug row (AmFah600-style) to help debug why Obsidian Flesh is not cast.
;~ Set $TORMENT_DEBUG_LOG to True to enable. Output: logs/torment_debug-<char>.csv
Func TormentCsvLog($event, $detail = '')
	If Not $TORMENT_DEBUG_LOG Then Return
	Local Static $csvHandle = Null
	If $csvHandle == Null Then
		Local $csvPath = @ScriptDir & '/logs/torment_debug-' & GetCharacterName() & '.csv'
		$csvHandle = FileOpen($csvPath, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
		If $csvHandle == -1 Then Return ; silently skip if file can't be opened
		Info('Torment CSV: ' & $csvPath)
		FileWriteLine($csvHandle, 'timestamp,elapsed_ms,event,detail,energy,max_energy,hp%,of_ms,of_ready,el_ms,foes_earshot')
	EndIf

	Local $alive = IsPlayerAlive()
	Local $elapsed = TimerDiff($run_timer)
	Local $energy = 0, $maxEnergy = 0, $hp = 0, $ofMs = 0, $ofReady = 0, $elMs = 0, $foes = 0
	If $alive Then
		$energy = Round(GetEnergy())
		$maxEnergy = DllStructGetData(GetMyAgent(), 'MaxEnergy')
		$hp = Round(DllStructGetData(GetMyAgent(), 'HealthPercent') * 100, 1)
		$ofMs = Round(GetEffectTimeRemaining($ID_OBSIDIAN_FLESH))
		$ofReady = IsRecharged($TORMENT_OBSIDIAN_FLESH) ? 1 : 0
		$elMs = Round(GetEffectTimeRemaining($ID_ELEMENTAL_LORD_LUXON))
		If $elMs == 0 Then $elMs = Round(GetEffectTimeRemaining($ID_ELEMENTAL_LORD_KURZICK))
		$foes = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
	EndIf

	Local $detailSafe = StringReplace($detail, ',', ' ')
	Local $ts = @YEAR & '-' & @MON & '-' & @MDAY & ' ' & @HOUR & ':' & @MIN & ':' & @SEC
	FileWriteLine($csvHandle, $ts & ',' & Round($elapsed, 0) & ',' & $event & ',' & $detailSafe & ',' & $energy & ',' & $maxEnergy & ',' & $hp & ',' & $ofMs & ',' & $ofReady & ',' & $elMs & ',' & $foes)
EndFunc