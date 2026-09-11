#include-once

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

Global Const $AMFAH600_SB_SKILLBAR = 'Owgk4gPKkEyU9gWkroFzuI+g+g8A'
Global Const $AMFAH600_SB_FARM_INFORMATIONS = 'Mo/Rt Spirit Bond Am Fah q8 from Nahpui Quarter to Wajjun Bazaar'
Global Const $AMFAH600_SB_FARM_DURATION = 6 * 60 * 1000

Global Const $AMFAH600_PROTECTIVE_SPIRIT = 1
Global Const $AMFAH600_SPIRIT_BOND = 2
; Slot 3 = Snow Storm (Deldrimor, 10e): cold damage over 5 s on a Necro. Our
; direct-damage tool so Necros (which out-live the SB/VWK reflect and stack
; life degeneration) die much faster. The old Ebon Battle Standard of Wisdom
; (recharge banner) is gone entirely.
Global Const $AMFAH600_SNOW_STORM = 3
Global Const $AMFAH600_VWK = 4
Global Const $AMFAH600_EVAS = 5
Global Const $AMFAH600_RETRIBUTION = 6
Global Const $AMFAH600_ESSENCE_BOND = 7
Global Const $AMFAH600_BALTHAZARS_SPIRIT = 8

Global Const $AMFAH600_SKILLS_ARRAY = [$AMFAH600_PROTECTIVE_SPIRIT, $AMFAH600_SPIRIT_BOND, $AMFAH600_SNOW_STORM, $AMFAH600_VWK, $AMFAH600_EVAS, $AMFAH600_RETRIBUTION, $AMFAH600_ESSENCE_BOND, $AMFAH600_BALTHAZARS_SPIRIT]
Global Const $AMFAH600_SKILLS_COSTS_ARRAY = [10, 10, 10, 5, 15, 1, 1, 1]
Global Const $AMFAH600_SKILL_COSTS_MAP = MapFromArrays($AMFAH600_SKILLS_ARRAY, $AMFAH600_SKILLS_COSTS_ARRAY)

Global Const $AMFAH600_MORGAHN_TEMPLATE = 'OQijEamM6Om4bMAAAwj3xDbAAA'
Global Const $AMFAH600_MORGAHN_FLAG_X = 13879
Global Const $AMFAH600_MORGAHN_FLAG_Y = -6658
Global Const $AMFAH600_SPOT2_X = 14337
Global Const $AMFAH600_SPOT2_Y = -7157
; Rez shrine near Spot 2 (recorded 2026-09-03 23:49): after a trap death once
; Spot 1's foes are dead, the monk respawns here and walks DIRECTLY to the
; Spot 2 Marksman anchor — NOT back to Tosai. She only enters the Marksman
; aggro once the 3 maintained enchants (6/7/8) are up and energy has refilled.
Global Const $AMFAH600_SHRINE_X = 15479
Global Const $AMFAH600_SHRINE_Y = -8865
; Undercity portal (Wajjun Bazaar -> The Undercity), recorded 2026-09-09 19:17.
; The zoning trigger sits right at this coordinate — the old code stopped ~270
; units short of it and never fired.
Global Const $AMFAH600_UNDERCITY_PORTAL_X = 17133
Global Const $AMFAH600_UNDERCITY_PORTAL_Y = -9929
; Spot 3: the final Am Fah cluster, past Spot 2's 3 Marksmen. We are greeted by
; 3 more Marksmen just outside the greeting point — pre-cast PS/SB/VWK there,
; then walk PAST them (under fire, recasting SB) to the kill anchor where the
; whole group is balled and reflect-killed. No Necromancers at this spot — lots
; of Assassins keep energy high, so EVAS + Snow Storm go on the Healers instead.
Global Const $AMFAH600_SPOT3_GREETING_X = 11194
Global Const $AMFAH600_SPOT3_GREETING_Y = -11881
Global Const $AMFAH600_SPOT3_X = 9967
Global Const $AMFAH600_SPOT3_Y = -14183
; Spot 3 has far more Am Fah than Spot 2 (many Assassins), so the reflect kill
; takes noticeably longer — give it a much longer fight window.
Global Const $AMFAH600_SPOT3_FIGHT_TIMEOUT_MS = 180000
; The opening volley at Spot 3 is brutal — suppress EVAS/Snow Storm for the
; first ~10s at the kill spot so every cast goes to the survival core (1/2/4).
Global Const $AMFAH600_SPOT3_OPENING_SUPPRESS_MS = 10000
Global Const $AMFAH600_PRECAST_RECAST_EARLY_MS = 1000
; Am Fah Assassin spike traps expire ~90s after the Assassins that laid them die.
; We wait out this window before every loot sweep so the field is clear when we
; step onto it (method 2: "wait 90s until loot").
Global Const $AMFAH600_TRAP_EXPIRE_MS = 90000

Global Const $AMFAH600_TOSAI_X = 15790
Global Const $AMFAH600_TOSAI_Y = -14951
; Second-group pull target (from 2026-08-18 17:37 recording): after activating
; Refuse to Drink at Tosai, walk TOWARD this point to lure the second Am Fah
; group. In that recording group 2 sat at the same spot as group 1, but it is
; not always the case — this point still triggers it ~95% of the time.
; We do NOT walk all the way in: the Marksmen there knock the 600hp monk down
; and interrupt casts (the last run died at dist=276 to a healer). We stop as
; soon as group 2 is at aggro range, and never closer than the stop radius.
Global Const $AMFAH600_SECOND_GROUP_PULL_X = 15410
Global Const $AMFAH600_SECOND_GROUP_PULL_Y = -13349
; Never walk closer than this to the recorded group-2 spot (~aggro range, so
; the group chases us instead of us standing in the middle of it). Reduced from
; 1000 to 700: group 2 often spawns further north than the recorded spot, so the
; old 1000-unit ring fired before the "foe ahead" stop and left most of group 2
; outside the aggro bubble (the 15:48 run pulled only 1 foe).
Global Const $AMFAH600_PULL_STOP_RADIUS = 700
; Stop the pull walk as soon as a group-2 foe ahead of us is within this range.
; Tightened to 850 so the monk walks a few more steps and the WHOLE cluster
; (spread ~300 units) falls inside the ~1185 aggro bubble.
Global Const $AMFAH600_PULL_AGGRO_STOP_DIST = 850
; Ignore chasing group-1 members closer than this (they trail right behind us).
Global Const $AMFAH600_PULL_MIN_CANDIDATE_DIST = 500
; The monk must walk at least this far toward the pull spot before the
; "foe ahead" stop is trusted. Group 1 (hostile since the quest trigger) chases
; from Tosai and surrounds us at pull start — a single group-1 Necromancer can
; sit "ahead" and false-trigger the stop, leaving group 2 unpulled so the fight
; starts under-aggro and kills the monk.
Global Const $AMFAH600_PULL_MIN_PROGRESS_DIST = 500
; EVAS (Ebon Vanguard Assassin) is the only targeted cast during the fight.
; GW's client auto-approaches toward an out-of-range target, so we only target
; Necromancers inside EVAS' real cast range (~1200). This lets the monk hit the
; Necros that hover just outside the aggro bubble (~1000-1200) and still keep
; her standing at the anchor — she never chases far ones across the compass.
Global Const $AMFAH600_EVAS_CAST_RANGE = 1200
; EVAS costs 15 energy and has a ~2s cast. Only summon when the survival core
; (PS + SB) is actually up. Energy floor is aligned with Snow Storm (20) so
; EVAS is always attempted first — it kills faster than Snow Storm.
Global Const $AMFAH600_EVAS_MIN_ENERGY = 20
; In the energy-collapsed state (few-foe / healer linchpin) drop the energy
; buffer: EVAS (15e cost) and Snow Storm (10e cost) may fire at their raw cost
; so the Healer-kill is not starved while income collapses.
Global Const $AMFAH600_EVAS_MIN_ENERGY_COLLAPSED = 15
Global Const $AMFAH600_SNOW_STORM_MIN_ENERGY = 20
Global Const $AMFAH600_SNOW_STORM_MIN_ENERGY_COLLAPSED = 10
Global Const $AMFAH600_HEALER_MODEL_ID = 4258
Global Const $AMFAH600_NECROMANCER_MODEL_ID = 4257
; Marksmen (bow, knockdown) — in the endgame they are the ones that stay alive
; near the spike-traps and force the monk to walk into the trap field to finish
; them (which kills her). We recognise them by model ID so EVAS assassins can be
; sent onto them to trigger the traps from a safe distance instead.
Global Const $AMFAH600_MARKSMAN_MODEL_ID = 4256

Global Const $AMFAH600_TOSAI_APPROACH_TIMEOUT_MS = 90000
Global Const $AMFAH600_FIRST_PULL_TIMEOUT_MS = 120000
; When only Necromancers remain in the first fight, keep fighting up to this
; long so EVAS assassins can finish them — otherwise a surviving Necro hexes
; the monk to death on the trek to Spot 2.
Global Const $AMFAH600_NECRO_CLEANUP_TIMEOUT_MS = 45000
; Endgame stall guard: if after the ball breaks only a couple of killable foes
; (Marksmen/Healers) remain but none are in earshot (nothing attacks us, so
; SB/VWK reflect cannot finish them), wait this long for them to re-engage and
; then move on to Spot 2 instead of idling the whole phase into a run-fail.
Global Const $AMFAH600_STRAY_MAX_FOES = 3
; Few-foe threshold: at or below this many living compass foes, the fight has
; collapsed into the energy-saving mode (drop PS, prioritize VWK/EVAS/Snow Storm).
Global Const $AMFAH600_FEW_FOES_MAX = 4
Global Const $AMFAH600_STRAY_CLEANUP_TIMEOUT_MS = 25000
Global Const $AMFAH600_RAMP_PULL_TIMEOUT_MS = 150000
Global Const $AMFAH600_ENERGY_WAIT_TIMEOUT_MS = 90000
Global Const $AMFAH600_MORGAHN_SEND_VERIFY_MS = 9000
Global Const $AMFAH600_MORGAHN_SPEED_INTERVAL_MS = 10000
Global Const $AMFAH600_DIALOG_ACCEPT_REFUSE_TO_DRINK = 0x814F01
Global Const $AMFAH600_DIALOG_PROGRESS_REFUSE_TO_DRINK = 0x814F05

Global $amfah600_sb_setup_done = False
Global $amfah600_sb_maintained_precast_done = False
Global $amfah600_sb_precast4_done = False
Global $amfah600_sb_precast7_done = False
Global $amfah600_sb_precast8_done = False
Global $amfah600_sb_morgahn_flagged_this_cycle = False
Global $amfah600_sb_morgahn_last_speed_timer = 0
Global $amfah600_sb_morgahn_last_speed_skill = 0 ; 0=none, 1=Incoming, 2=Fall Back
; Necro the most recent EVAS assassin was sent to (shared, so Snow Storm can
; hit the OTHER Necro and both are worn down in parallel).
Global $amfah600_sb_last_evas_target_id = 0

; Death counter. The FIRST death of a run is tolerated (single -15% malus):
; a trap death (after Spot 1 cleared) recovers shrine -> Spot 2, a combat death
; (foes in earshot) re-zones via the Undercity tunnels and restarts the farm.
; The SECOND death is not recoverable (past -15%) - the run pauses at the rez
; shrine. Reset per fresh external farm start (monk alive at the outpost).
Global $amfah600_sb_deaths_this_run = 0
; Bounded tunnel-resets for a Spot-1 fight that times out while alive (poisoned
; instance: quest active / foes hostile / stuck stragglers). Avoids endless loops.
Global $amfah600_sb_fight_retries = 0


Func AmFah600SpiritBondRun()
	; A fresh external farm start begins a new attempt from the outpost, so the
	; death counter and tunnel-reset counter reset here (before the internal loop
	; may recover one death / reset one poisoned fight).
	If IsPlayerAlive() Then
		$amfah600_sb_deaths_this_run = 0
		$amfah600_sb_fight_retries = 0
	EndIf
	If Not $amfah600_sb_setup_done And SetupAmFah600SpiritBondRun() == $FAIL Then Return $PAUSE
	If GetMapID() <> $ID_WAJJUN_BAZAAR Then
		Switch GetMapID()
			Case $ID_NAHPUI_QUARTER
				If GoToWajjunBazarFromNahpuiQuarter() == $FAIL Then Return $FAIL
			Case $ID_THE_UNDERCITY
				If GoToWajjunBazarFromUndercity() == $FAIL Then Return $FAIL
			Case Else
				; Unknown start map for this run: reset to canonical outpost route.
				If TravelToOutpost($ID_NAHPUI_QUARTER, $district_name) == $FAIL Then Return $FAIL
				If GoToWajjunBazarFromNahpuiQuarter() == $FAIL Then Return $FAIL
		EndSwitch
	EndIf

	Local $result = AmFah600SpiritBondRunLoop()
	If IsPlayerDead() And $amfah600_sb_deaths_this_run >= 2 Then
		Warn('Am Fah 600 SB debug mode: died ' & $amfah600_sb_deaths_this_run & ' times, pausing at rez shrine for recording')
		Return $PAUSE
	EndIf
	Return $result
EndFunc


Func SetupAmFah600SpiritBondRun()
	Info('Setting up Am Fah 600 Spirit Bond run')
	Local $mapID = GetMapID()
	If $mapID <> $ID_NAHPUI_QUARTER And $mapID <> $ID_WAJJUN_BAZAAR And $mapID <> $ID_THE_UNDERCITY Then
		If TravelToOutpost($ID_NAHPUI_QUARTER, $district_name) == $FAIL Then Return $FAIL
	ElseIf $mapID == $ID_THE_UNDERCITY Then
		Info('Am Fah setup: starting from Undercity, keeping current location')
	EndIf
	SwitchMode($ID_HARD_MODE)

	If SetupPlayerAmFah600SpiritBondRun() == $FAIL Then Return $FAIL
	If GetMapType() == $ID_OUTPOST Then
		If SetupTeamAmFah600SpiritBondRun() == $FAIL Then Return $FAIL
	Else
		Info('Am Fah setup: skipping team setup outside outpost (using current party state)')
	EndIf

	If GetMapID() <> $ID_WAJJUN_BAZAAR Then
		Switch GetMapID()
			Case $ID_NAHPUI_QUARTER
				If GoToWajjunBazarFromNahpuiQuarter() == $FAIL Then Return $FAIL
			Case $ID_THE_UNDERCITY
				If GoToWajjunBazarFromUndercity() == $FAIL Then Return $FAIL
			Case Else
				If GoToWajjunBazarFromNahpuiQuarter() == $FAIL Then Return $FAIL
		EndSwitch
	EndIf

	$amfah600_sb_setup_done = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerAmFah600SpiritBondRun()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_MONK Then
		Warn('Should run this farm as monk primary')
		Return $FAIL
	EndIf

	If HeroHasTemplate(0, $AMFAH600_SB_SKILLBAR) Then
		Info('Am Fah 600 player: template already loaded, skipping')
	Else
		LoadSkillTemplate($AMFAH600_SB_SKILLBAR)
		RandomSleep(250)
	EndIf
	ChangeWeaponSet(1)
	RandomSleep(120)
	$amfah600_sb_maintained_precast_done = False
	$amfah600_sb_precast4_done = False
	$amfah600_sb_precast7_done = False
	$amfah600_sb_precast8_done = False
	Return $SUCCESS
EndFunc


Func SetupTeamAmFah600SpiritBondRun()
	If IsTeamAutoSetup() Then Return $SUCCESS

	If AmFah600SpiritBondEnsureSoloParty() == $FAIL Then Return $FAIL
	If AddRequiredHero($ID_GENERAL_MORGAHN) == $FAIL Then
		Warn('Could not add General Morgahn for approach speed support')
		Return $FAIL
	EndIf
	If HeroHasTemplate(1, $AMFAH600_MORGAHN_TEMPLATE) Then
		Info('Am Fah 600 Morgahn: template already loaded, skipping')
	Else
		LoadSkillTemplate($AMFAH600_MORGAHN_TEMPLATE, 1)
		RandomSleep(150)
	EndIf
	DisableHeroSkillSlot(1, 4) ; Disable Make Haste — only Incoming (1) + Fall Back (2) for speed
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondEnsureSoloParty($maxWaitMs = 9000)
	Local $timer = TimerInit()
	KickAllHeroes()
	LeaveParty(False)
	While TimerDiff($timer) < $maxWaitMs
		If GetPartySize() <= 1 And GetHeroCount() == 0 Then Return $SUCCESS
		KickAllHeroes()
		LeaveParty(False)
		RandomSleep(320)
	WEnd
	Warn('Am Fah 600 SB: party reset timeout. Party=' & GetPartySize() & ', heroes=' & GetHeroCount())
	Return $FAIL
EndFunc


Func GoToWajjunBazarFromNahpuiQuarter()
	TravelToOutpost($ID_NAHPUI_QUARTER, $district_name)
	While GetMapID() <> $ID_WAJJUN_BAZAAR
		Info('Moving to Wajjun Bazaar from Nahpui Quarter')
		MoveTo(-22000, 12500)
		Move(-21750, 14500)
		RandomSleep(1000)
		If WaitMapLoading($ID_WAJJUN_BAZAAR, 10000, 2000) Then ExitLoop
		TravelToOutpost($ID_NAHPUI_QUARTER, $district_name)
	WEnd
	Return GetMapID() == $ID_WAJJUN_BAZAAR ? $SUCCESS : $FAIL
EndFunc


Func GoToWajjunBazarFromUndercity()
	Info('Moving to Wajjun Bazaar from The Undercity')
	Local $mapLoaded = False
	For $i = 1 To 4
		MoveTo(-16309, -6894)
		Move(-16580, -6900)
		RandomSleep(1000)
		$mapLoaded = WaitMapLoading($ID_WAJJUN_BAZAAR, 8000, 1500)
		If $mapLoaded Then ExitLoop
	Next
	Return GetMapID() == $ID_WAJJUN_BAZAAR ? $SUCCESS : $FAIL
EndFunc


Func AmFah600SpiritBondRunLoop()
	If GetMapID() <> $ID_WAJJUN_BAZAAR Then Return $FAIL
	While IsPlayerAlive() And $amfah600_sb_deaths_this_run < 2
		If GetMapID() <> $ID_WAJJUN_BAZAAR Then Return $FAIL
		$amfah600_sb_morgahn_flagged_this_cycle = False
		$amfah600_sb_morgahn_last_speed_timer = 0
		$amfah600_sb_morgahn_last_speed_skill = 0
		If AmFah600SpiritBondCastMaintainedPrebuffs() == $FAIL Then Return $FAIL
		If AmFah600SpiritBondGoToBrotherTosai() == $FAIL Then Return $FAIL
		AmFah600SpiritBondSendMorgahnToDesert()
		If AmFah600SpiritBondPrepareBeforeQuestTrigger() == $FAIL Then Return $FAIL
		If AmFah600SpiritBondActivateQuest() == $FAIL Then Return $FAIL
		; Walk from Tosai to the recorded pull point to lure the second group
		; into aggro range (maintenance keeps the 600hp build alive on the way).
		If AmFah600SpiritBondPullSecondGroup() == $FAIL Then
			; Died during the pull = combat death (foes hostile). Reset via the
			; tunnels and restart the farm cycle (recover the first death instead
			; of returning $FAIL, which made the outer loop spam "Starting run N"
			; with 0s failures while the monk was still dead at the shrine).
			If IsPlayerDead() Then
				If AmFah600SpiritBondRecoverFromCombatDeath() == $SUCCESS Then ContinueLoop
			EndIf
			Return $FAIL
		EndIf

		; Spot 1: Brother Tosai — fight first two groups. FightWindow already
		; returns only when all foes are dead or only Necromancers remain, so
		; there is nothing left to re-engage here (ContinueLoop would re-approach
		; Tosai and kill us).
		If AmFah600SpiritBondFightFirstTwoGroups() == $FAIL Then
			; Combat death (foes still in earshot) -> tunnels re-zone + restart.
			If IsPlayerDead() Then
				If AmFah600SpiritBondRecoverFromCombatDeath() == $SUCCESS Then ContinueLoop
				Return $FAIL
			EndIf
			; Timed out while alive: the Tosai instance is unclean (quest active /
			; foes hostile / stuck stragglers). Reset via the tunnels and retry.
			If AmFah600SpiritBondResetAfterFailedFight() == $SUCCESS Then ContinueLoop
			Return $FAIL
		EndIf
		$amfah600_sb_fight_retries = 0

		; Spot 2 leg: loot Spot 1, walk to Spot 2 (3 Marksmen), fight and loot.
		; A spike-trap death after Spot 1's foes are dead (still healthy at
		; -15%) is recovered from the shrine DIRECTLY into the Spot 2 fight (see
		; RecoverForSpot2), with 6/7/8 + full energy first.
		If AmFah600SpiritBondDoSpot2Leg() == $FAIL Then
			; A failure here is a combat death in the Spot-2 fight (or an
			; unrecoverable 2nd death). First-death combat -> tunnels + restart.
			If IsPlayerDead() Then
				If AmFah600SpiritBondRecoverFromCombatDeath() == $SUCCESS Then ContinueLoop
			EndIf
			Return $FAIL
		EndIf

		; Spot 3 leg: the final Am Fah cluster (many Assassins + Healers, no
		; Necromancers). Walk past the 3-Marksman greeting (pre-cast PS/SB/VWK,
		; then cross under fire with SB maintenance), fight and loot. A death
		; here is a combat death (foes hostile once the Marksmen aggro).
		If AmFah600SpiritBondDoSpot3Leg() == $FAIL Then
			If IsPlayerDead() Then
				If AmFah600SpiritBondRecoverFromCombatDeath() == $SUCCESS Then ContinueLoop
			EndIf
			Return $FAIL
		EndIf
		If AmFah600SpiritBondRezoneViaUndercity() == $FAIL Then Return $FAIL
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func AmFah600SpiritBondCastMaintainedPrebuffs()
	If IsPlayerDead() Then Return $FAIL
	AmFah600SpiritBondSyncPrebuffState()
	If $amfah600_sb_maintained_precast_done Then Return $SUCCESS

	If GetEffectTimeRemaining(GetEffect($ID_RETRIBUTION)) == 0 Then
		If AmFah600SpiritBondCastSkillChecked($AMFAH600_RETRIBUTION) == $FAIL Then Return $FAIL
	EndIf

	AmFah600SpiritBondSyncPrebuffState()
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondGoToBrotherTosai()
	Local $waypointsNahpui[][2] = [[9032, -19395], [7606, -18046], [5777, -17714], [4299, -17071], [2942, -16271], [2673, -15746], [2818, -14502], [4041, -14150], [6489, -14511], [8938, -14764], [10087, -12923], [11230, -12575], [12378, -11805], [14019, -11786], [14966, -12071], [15388, -13325], [15790, -14951]]
	; Direct wall-avoiding route from Undercity-side Wajjun spawn to Tosai
	; (recorded 2026-09-09 18:20): northeast, straight north, then east into Tosai.
	Local $waypointsUndercity[][2] = [ _
		[16510, -9978], _ ; Undercity-side spawn
		[16045, -10158], _ ; recording start
		[15955, -10434], _
		[15862, -10711], _
		[15774, -10987], _
		[15693, -11267], _
		[15612, -11547], _
		[15532, -11827], _
		[15461, -12169], _
		[15446, -12402], _ ; straight north leg
		[15449, -12634], _
		[15455, -12868], _
		[15463, -13101], _
		[15473, -13334], _
		[15484, -13563], _
		[15497, -13799], _
		[15500, -13856], _ ; turn east
		[15552, -14022], _
		[15607, -14188], _
		[15662, -14354], _
		[15716, -14518], _
		[15771, -14686], _
		[15825, -14851], _
		[15790, -14951] _ ; Tosai
	]

	Local $me = GetMyAgent()
	Local $fromUndercitySide = GetDistanceToPoint($me, 16510, -9978) < 2200
	Local $waypoints = $fromUndercitySide ? $waypointsUndercity : $waypointsNahpui
	Info('Approach Tosai from ' & ($fromUndercitySide ? 'Undercity-side spawn' : 'Nahpui-side spawn'))
	If $fromUndercitySide Then
		AmFah600SpiritBondFlagMorgahnAtRecordedSpotVerified('spawn-pass', 5000)
	ElseIf GetDistanceToPoint($me, $AMFAH600_MORGAHN_FLAG_X, $AMFAH600_MORGAHN_FLAG_Y) < 1600 Then
		AmFah600SpiritBondTryFlagMorgahnAtRecordedSpot('spawn-pass')
	EndIf

	Local $timer = TimerInit()
	For $i = 0 To UBound($waypoints) - 1
		If TimerDiff($timer) > $AMFAH600_TOSAI_APPROACH_TIMEOUT_MS Then Return $FAIL
		If IsPlayerDead() Then Return $FAIL
		AmFah600SpiritBondTryMorgahnSpeedBoost()
		; Flag Morgahn to his desert off-spot ~5 waypoints before arrival so he
		; is well clear of the aggro zone by the time we trigger the quest.
		If $i == UBound($waypoints) - 5 Then AmFah600SpiritBondTryFlagMorgahnAtRecordedSpot('pre-arrival')
		AmFah600SpiritBondTryMovementPrebuffCast()
		MoveTo($waypoints[$i][0], $waypoints[$i][1])
		AmFah600SpiritBondTryMovementPrebuffCast()
		RandomSleep(120)
	Next

	Local $precastTimer = TimerInit()
	While IsPlayerAlive() And TimerDiff($precastTimer) < $AMFAH600_ENERGY_WAIT_TIMEOUT_MS
		If AmFah600SpiritBondAllPrebuffsActive() Then ExitLoop
		AmFah600SpiritBondTryMovementPrebuffCast()
		RandomSleep(120)
	WEnd
	If Not AmFah600SpiritBondAllPrebuffsActive() Then
		Warn('Could not finish movement prebuffs (6/7/8) before Tosai')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondTryMovementPrebuffCast()
	Local $me = GetMyAgent()
	Local $maxEnergy = DllStructGetData($me, 'MaxEnergy')
	If GetEnergy($me) < ($maxEnergy - 0.2) Then Return

	AmFah600SpiritBondSyncPrebuffState()

	If GetEffectTimeRemaining(GetEffect($ID_RETRIBUTION)) == 0 Then
		If IsRecharged($AMFAH600_RETRIBUTION) And GetEnergy() >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_RETRIBUTION] Then
			Info('Movement prebuff: cast 6 (Retribution)')
			UseSkillEx($AMFAH600_RETRIBUTION)
			RandomSleep(90)
			AmFah600SpiritBondSyncPrebuffState()
			Return
		EndIf
	EndIf

	If Not $amfah600_sb_precast7_done Then
		If IsRecharged($AMFAH600_ESSENCE_BOND) And GetEnergy() >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_ESSENCE_BOND] Then
			Info('Movement prebuff: cast 7 (Essence Bond)')
			UseSkillEx($AMFAH600_ESSENCE_BOND)
			$amfah600_sb_precast7_done = True
			RandomSleep(90)
			AmFah600SpiritBondSyncPrebuffState()
		EndIf
		Return
	EndIf

	If Not $amfah600_sb_precast8_done Then
		If IsRecharged($AMFAH600_BALTHAZARS_SPIRIT) And GetEnergy() >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_BALTHAZARS_SPIRIT] Then
			Info('Movement prebuff: cast 8 (Balthazar''s Spirit)')
			UseSkillEx($AMFAH600_BALTHAZARS_SPIRIT)
			$amfah600_sb_precast8_done = True
			RandomSleep(90)
			AmFah600SpiritBondSyncPrebuffState()
		EndIf
		Return
	EndIf

	; Snow Storm (3) and VWK (4) are intentionally NOT pre-cast on the way to
	; Tosai — they are combat-only. Snow Storm is a targeted Necro nuke and VWK
	; is the reflect engine; pre-casting them mid-route wastes the energy the
	; monk needs to keep PS/SB tight at the quest trigger. AllPrebuffsActive
	; only requires 6/7/8, so nothing else depends on them being up early.
EndFunc


Func AmFah600SpiritBondAllPrebuffsActive()
	Return GetEffectTimeRemaining(GetEffect($ID_RETRIBUTION)) > 0 _
		And GetEffectTimeRemaining(GetEffect($ID_ESSENCE_BOND)) > 0 _
		And GetEffectTimeRemaining(GetEffect($ID_BALTHAZARS_SPIRIT)) > 0
EndFunc


Func AmFah600SpiritBondSyncPrebuffState()
	$amfah600_sb_precast4_done = GetEffectTimeRemaining(GetEffect($ID_VENGEFUL_WAS_KHANHEI)) > 0
	$amfah600_sb_precast7_done = GetEffectTimeRemaining(GetEffect($ID_ESSENCE_BOND)) > 0
	$amfah600_sb_precast8_done = GetEffectTimeRemaining(GetEffect($ID_BALTHAZARS_SPIRIT)) > 0
	$amfah600_sb_maintained_precast_done = AmFah600SpiritBondAllPrebuffsActive()
EndFunc


Func AmFah600SpiritBondPrepareBeforeQuestTrigger()
	If AmFah600SpiritBondCastSkillChecked($AMFAH600_PROTECTIVE_SPIRIT) == $FAIL Then Return $FAIL
	AmFah600SpiritBondCsvLog('PrepareBeforeQuest', 'ps=' & (GetEffect($ID_PROTECTIVE_SPIRIT) <> Null ? 'ok' : 'fail'))
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondActivateQuest()
	Info('Starting Refuse to Drink at Brother Tosai')
	If IsQuestActive($ID_QUEST_REFUSE_TO_DRINK) Then
		Info('Refuse to Drink already active')
		Return $SUCCESS
	EndIf

	; Abandon any stale quest state from previous failed attempts.
	; Partial activation (Dialog+AcceptQuest may make enemies hostile without
	; the quest registering as 'active') poisons the next run — the approach
	; waypoints don't maintain PS/SB and the player dies during movement.
	If Not IsQuestNotFound($ID_QUEST_REFUSE_TO_DRINK) Then
		Warn('Refuse to Drink quest in non-active state — abandoning to reset')
		AbandonQuest($ID_QUEST_REFUSE_TO_DRINK)
		PingSleep(500)
	EndIf

	; Cast fresh defensive enchants NOW — don't rely on PrepareBeforeQuestTrigger's
	; casts which may have expired during the approach to Tosai.
	AmFah600SpiritBondMaintainCoreUpkeep()

	; Only PS (1) needs to be up before the first dialog. SB (2), Snow Storm (3)
	; and VWK (4) are all cast on-combat — the Am Fah aggro with a delay, so SB
	; is cast "in time" (after they turn hostile), not pre-cast. This keeps
	; energy full for the fight start and drops the redundant double SB cast.
	Local $prebuffTimer = TimerInit()
	While IsPlayerAlive() And TimerDiff($prebuffTimer) < 5000
		If GetEffect($ID_PROTECTIVE_SPIRIT) <> Null Then ExitLoop
		AmFah600SpiritBondMaintainCoreUpkeep()
		RandomSleep(80)
	WEnd
	If IsPlayerDead() Then
		AmFah600SpiritBondCsvLog('ActivateQuest', 'dead_during_prebuff')
		Return $FAIL
	EndIf

	Local $timerQuest = TimerInit()
	Local $attempt = 0
	While Not IsQuestActive($ID_QUEST_REFUSE_TO_DRINK)
		If IsPlayerDead() Then
			AmFah600SpiritBondCsvLog('ActivateQuest', 'dead_in_loop')
			Return $FAIL
		EndIf
		If TimerDiff($timerQuest) > 30000 Then
			Warn('Could not activate Refuse to Drink quest after 30s')
			AmFah600SpiritBondCsvLog('ActivateQuest', 'timeout_30s')
			; Abandon to reset enemies that may have become hostile via partial
			; activation — otherwise the next run dies during approach.
			If Not IsQuestNotFound($ID_QUEST_REFUSE_TO_DRINK) Then
				AbandonQuest($ID_QUEST_REFUSE_TO_DRINK)
			EndIf
			Return $FAIL
		EndIf
		$attempt += 1
		AmFah600SpiritBondCsvLog('ActivateQuest_attempt', $attempt)

		; Refresh NPC reference each iteration — GW may recycle agent IDs.
		Local $tosai = GetNearestNPCToCoords($AMFAH600_TOSAI_X, $AMFAH600_TOSAI_Y)
		GoToNPC($tosai)
		PingSleep(500)
		; ⚠️ If the quest became active during the approach (e.g. from a
		; previous attempt that partially succeeded), stop talking to Tosai
		; immediately — re-entering dialogs will delay SB maintenance.
		If IsQuestActive($ID_QUEST_REFUSE_TO_DRINK) Then ExitLoop
		Dialog(0x84)
		PingSleep(500)
		Dialog($AMFAH600_DIALOG_ACCEPT_REFUSE_TO_DRINK)
		PingSleep(250)

		; AcceptQuest turns both Ambush groups HOSTILE immediately. EVAS and Snow
		; Storm are both allowed right away — they self-limit via their energy /
		; core-uptime checks so they can never starve a PS/SB refresh.
		; MUST refresh PS+SB+4 NOW — the 1.75 s of dialogs above may have let
		; enchantments tick dangerously low.  Do multiple passes so that if PS
		; is cast first, SB is caught on the next pass.
		AcceptQuest($ID_QUEST_REFUSE_TO_DRINK)
		For $postAccept = 1 To 10
			AmFah600SpiritBondMaintainCoreUpkeep()
			RandomSleep(25)
		Next
		AmFah600SpiritBondCsvLog('ActivateQuest_post_accept', 'hp=' & Round(DllStructGetData(GetMyAgent(), 'HealthPercent') * 100) & '% sb=' & (GetEffect($ID_SPIRIT_BOND) <> Null ? 'on' : 'off') & ' ps=' & (GetEffect($ID_PROTECTIVE_SPIRIT) <> Null ? 'on' : 'off'))

		PingSleep(500)
		Dialog($AMFAH600_DIALOG_PROGRESS_REFUSE_TO_DRINK)
		PingSleep(250)

		; The progress dialog turns the Am Fah hostile. Maintain PS/SB while
		; giving them a short window to appear, then break out once any foe is
		; in earshot - the quest may not report 'active' even though it has
		; effectively started. This avoids re-running dialogs under fire.
		Local $foeWaitTimer = TimerInit()
		While IsPlayerAlive() And TimerDiff($foeWaitTimer) < 2500
			AmFah600SpiritBondMaintainCoreUpkeep()
			If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) > 0 Then ExitLoop
			RandomSleep(50)
		WEnd

		If IsQuestActive($ID_QUEST_REFUSE_TO_DRINK) Or CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) > 0 Then ExitLoop
	WEnd

	Info('Refuse to Drink is active - entering high-pressure guard')
	; Survival first: the next ~8s are the deadliest of the run. Both Ambush
	; groups are hostile; keep 1/2/4 tight here and ALWAYS cast EVAS / Snow Storm
	; on a reachable Necro — they engage the second group's vanguard and drag its
	; healers into range.
	Local $timerGuard = TimerInit()
	Local $guardLoops = 0
	While IsPlayerAlive() And TimerDiff($timerGuard) < 3000
		AmFah600SpiritBondMaintainCoreUpkeep()
		AmFah600SpiritBondTryCastEvasOnNecromancer()
		AmFah600SpiritBondTryCastSnowStormOnNecromancer()
		RandomSleep(50)
		$guardLoops += 1
	WEnd
	AmFah600SpiritBondCsvLog('ActivateQuest_guard', 'loops=' & $guardLoops & ' alive=' & IsPlayerAlive())
	If IsPlayerDead() Then Return $FAIL
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondPullSecondGroup()
	Info('Pulling second Am Fah group (stop at aggro range, never into the group)')
	; The quest already made both ambush groups hostile. Walk from Tosai toward
	; the second group, but STOP at aggro range — never walk into the middle of
	; it, because its Marksmen knock the 600hp monk down and interrupt casts
	; (that killed the last run at dist=276 to a healer). Group 1 chases behind
	; us; group 2 sits ahead in the pull direction, so we stop as soon as a foe
	; ahead is within aggro range and never past the stop radius.
	Local $timer = TimerInit()
	Local $blockedCount = 0
	Local $startDistToSpot = GetDistanceToPoint(GetMyAgent(), $AMFAH600_SECOND_GROUP_PULL_X, $AMFAH600_SECOND_GROUP_PULL_Y)
	; 1 Hz CSV heartbeat through the pull so an SB/PS lapse during the walk is
	; fully visible (columns ps_ms/sb_ms/energy/foes_earshot already snapshot
	; the moment). The death in the 19:57 run happened mid-pull with no CSV rows
	; between the guard and PullSecondGroup_stop — that gap is now closed.
	Local $pullLogTimer = TimerInit()
	While IsPlayerAlive() And TimerDiff($timer) < 60000
		AmFah600SpiritBondPullTick()
		Local $me = GetMyAgent()
		If TimerDiff($pullLogTimer) > 1000 Then
			$pullLogTimer = TimerInit()
			AmFah600SpiritBondCsvLog('PullTick', 'sb_rech=' & (IsRecharged($AMFAH600_SPIRIT_BOND) ? 1 : 0) & ' ps_rech=' & (IsRecharged($AMFAH600_PROTECTIVE_SPIRIT) ? 1 : 0) & ' evas_rech=' & (IsRecharged($AMFAH600_EVAS) ? 1 : 0))
		EndIf
		If AmFah600SpiritBondPullShouldStop($me, $startDistToSpot) Then ExitLoop
		Move($AMFAH600_SECOND_GROUP_PULL_X, $AMFAH600_SECOND_GROUP_PULL_Y)
		RandomSleep(100)
		; Body-blocked by the chasing first group — nudge around like MoveTo does.
		If Not IsPlayerMoving() Then
			$blockedCount += 1
			If $blockedCount > 3 Then
				MoveRadial($AMFAH600_SECOND_GROUP_PULL_X, $AMFAH600_SECOND_GROUP_PULL_Y, $RANGE_AREA * 1.5)
				Sleep(1000)
			EndIf
		EndIf
	WEnd
	If IsPlayerDead() Then Return $FAIL

	AmFah600SpiritBondMaintainCoreUpkeep()
	Local $me = GetMyAgent()
	AmFah600SpiritBondCsvLog('PullSecondGroup_stop', 'distToSpot=' & Round(GetDistanceToPoint($me, $AMFAH600_SECOND_GROUP_PULL_X, $AMFAH600_SECOND_GROUP_PULL_Y)) & ' x=' & Round(DllStructGetData($me, 'X')) & ' y=' & Round(DllStructGetData($me, 'Y')))
	Local $healer = AmFah600SpiritBondGetNearestHealerInRange($RANGE_COMPASS)
	If $healer <> Null Then
		Info('Second group pulled: healer model=' & DllStructGetData($healer, 'ModelID') & ', dist=' & Round(GetDistance($me, $healer)))
		ChangeTarget($healer)
	Else
		Info('No Am Fah Healer in compass yet; holding at stop point for aggro')
	EndIf
	Return $SUCCESS
EndFunc


;~ Returns True when the pull walk should stop. Primary: a group-2 foe ahead of
;~ us is already within aggro range, so it chases us instead of us walking into
;~ its knockdown range. Fallback: never get closer than the stop radius to the
;~ recorded group-2 spot (~aggro range, half the recorded Tosai→group distance).
Func AmFah600SpiritBondPullShouldStop($me, $startDistToSpot = 0)
	If $me == Null Then Return True
	Local $mx = DllStructGetData($me, 'X')
	Local $my = DllStructGetData($me, 'Y')

	; Fallback cap: stay at aggro range of the recorded group-2 spot.
	Local $distToSpot = GetDistanceToPoint($me, $AMFAH600_SECOND_GROUP_PULL_X, $AMFAH600_SECOND_GROUP_PULL_Y)
	If $distToSpot <= $AMFAH600_PULL_STOP_RADIUS Then
		Info('Pull stop: reached ring around recorded spot (dist=' & Round($distToSpot) & ')')
		Return True
	EndIf

	; Do not trust the "foe ahead" signal until we have actually walked toward
	; the spot. Group 1 chases from behind and surrounds us at pull start, so a
	; group-1 Necromancer can false-trigger the stop before we reach group 2.
	If ($startDistToSpot - $distToSpot) < $AMFAH600_PULL_MIN_PROGRESS_DIST Then Return False

	; Direction toward the recorded group-2 spot.
	Local $dirX = $AMFAH600_SECOND_GROUP_PULL_X - $mx
	Local $dirY = $AMFAH600_SECOND_GROUP_PULL_Y - $my
	Local $dirLen = Sqrt($dirX * $dirX + $dirY * $dirY)
	If $dirLen < 1 Then Return True

	; A foe ahead of us at aggro range = group 2 pulling (group 1 trails behind).
	Local $foes = GetFoesInRangeOfAgent($me, $AMFAH600_PULL_AGGRO_STOP_DIST + 300)
	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If GetIsDead($foe) Then ContinueLoop
		Local $fx = DllStructGetData($foe, 'X') - $mx
		Local $fy = DllStructGetData($foe, 'Y') - $my
		Local $dist = Sqrt($fx * $fx + $fy * $fy)
		If $dist < $AMFAH600_PULL_MIN_CANDIDATE_DIST Then ContinueLoop
		Local $dot = ($fx * $dirX + $fy * $dirY) / ($dirLen * $dist)
		If $dot < 0.5 Then ContinueLoop
		If $dist <= $AMFAH600_PULL_AGGRO_STOP_DIST Then
			Info('Pull stop: group 2 at aggro range (model=' & DllStructGetData($foe, 'ModelID') & ', dist=' & Round($dist) & ')')
			Return True
		EndIf
	Next
	Return False
EndFunc


;~ Tick used during the second-group pull: keeps the 600hp build alive (PS/SB)
;~ while the monk walks from Tosai to the pull point. Deliberately does NOT cast
;~ EVAS/Snow Storm here — their 2s + 1s casts stall the northward walk AND block
;~ the SB recast while the monk is between the two groups (the 15:48 run died
;~ exactly this way: SB lapsed mid-pull and HP bled from 89% to 38% before the
;~ fight even began). The Necromancers are pressured later, during the fight.
Func AmFah600SpiritBondPullTick()
	AmFah600SpiritBondMaintainCoreUpkeep()
EndFunc


Func AmFah600SpiritBondFightFirstTwoGroups()
	Info('Fighting first two Am Fah groups')
	Return AmFah600SpiritBondFightWindow('First two groups', $AMFAH600_FIRST_PULL_TIMEOUT_MS)
EndFunc


Func AmFah600SpiritBondFightRampThreeGroups()
	Info('Fighting ramp-side three groups')
	Return AmFah600SpiritBondFightWindow('Ramp three groups', $AMFAH600_RAMP_PULL_TIMEOUT_MS)
EndFunc


Func AmFah600SpiritBondFightWindow($label, $timeoutMs)
	Local $timer = TimerInit()
	Local $me = GetMyAgent()
	Local $anchorX = DllStructGetData($me, 'X')
	Local $anchorY = DllStructGetData($me, 'Y')
	Move($anchorX, $anchorY)
	AmFah600SpiritBondCsvLog('FightWindow_start', $label & ' x=' & Round($anchorX) & ' y=' & Round($anchorY))
	While IsPlayerAlive() And TimerDiff($timer) < $timeoutMs
		; Keep 1/2/4 as tight as possible first — PS/SB/VWK are the survival
		; core and must never be delayed by an EVAS summon. Maintenance runs
		; before EVAS in the same pass, so EVAS only fires when the core is
		; already healthy — no extra gating needed.
		AmFah600SpiritBondMaintainCoreUpkeep()

		; Cast EVAS after the core is safe — hit a Necro with an assassin. On
		; recharge it picks up the next Necro.
		If AmFah600SpiritBondTryCastEvasOnNecromancer() Then
			; EVAS cast is done — cancel any client auto-approach toward the
			; Necro and return the monk to the anchor (never drift toward Spot 2).
			Move($anchorX, $anchorY)
			RandomSleep(60)
			ContinueLoop
		EndIf

		; Snow Storm (3) — direct cold damage on a Necro while EVAS handles the
		; other, so the Necros that out-live the reflect die much faster.
		If AmFah600SpiritBondTryCastSnowStormOnNecromancer() Then
			Move($anchorX, $anchorY)
			RandomSleep(60)
			ContinueLoop
		EndIf

		$me = GetMyAgent()

		; Only end the fight once EVERY foe in compass is dead. We never walk to
		; Spot 2 early — either we kill everything or we die here.
		If TimerDiff($timer) > 8000 And AmFah600SpiritBondShouldEndFirstFight() Then
			Info('All foes dead - moving on to Spot 2')
			AmFah600SpiritBondCsvLog('FightWindow_cleared', $label & ' x=' & Round(DllStructGetData($me, 'X')) & ' y=' & Round(DllStructGetData($me, 'Y')))
			Return $SUCCESS
		EndIf

		AmFah600SpiritBondHoldPosition($anchorX, $anchorY)

		; Only target foes that can actually be reflect-killed (in earshot).
		; Never select a distant straggler — picking one can make the client
		; auto-chase it toward the wall instead of holding the reflect spot.
		Local $target = AmFah600SpiritBondGetNearestHealerInRange($RANGE_EARSHOT)
		If $target == Null Then $target = AmFah600SpiritBondGetNearestNecromancerInRange($RANGE_EARSHOT)
		If $target == Null Then $target = GetNearestEnemyToAgent($me, $RANGE_EARSHOT)
		If $target <> Null Then ChangeTarget($target)

		RandomSleep(25)
	WEnd

	; The loop ends on timeout OR when the monk died mid-fight. Distinguish the
	; two in the log/CSV — a 'timeout' while dead was very confusing to read and
	; the caller routes a combat death to a tunnel re-zone + restart.
	If IsPlayerDead() Then
		Warn('Am Fah 600 SB combat death in phase: ' & $label)
		AmFah600SpiritBondCsvLog('FightWindow_death', $label & ' x=' & Round(DllStructGetData($me, 'X')) & ' y=' & Round(DllStructGetData($me, 'Y')))
	Else
		Warn('Am Fah 600 SB timeout in phase: ' & $label)
		AmFah600SpiritBondCsvLog('FightWindow_timeout', $label & ' x=' & Round(DllStructGetData($me, 'X')) & ' y=' & Round(DllStructGetData($me, 'Y')))
	EndIf
	Return $FAIL
EndFunc


Func AmFah600SpiritBondShouldEndFirstFight()
	; Return True only when EVERY foe in compass is dead. The fight must never
	; end early — either we kill everything or we die; there is no escape.
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS)
	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If GetIsDead($foe) Then ContinueLoop
		; Any living foe (Necromancer, Marksman, Healer, Assassin) keeps us fighting.
		Return False
	Next
	Return True
EndFunc


;~ Number of alive non-Necromancer foes in compass (Marksmen/Healers/Assassins
;~ are killable by SB/VWK reflect; Necromancers are excluded here because they
;~ are finished separately by EVAS assassins via their own cleanup window).
Func AmFah600SpiritBondCountKillableFoes()
	Local $count = 0
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS)
	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If GetIsDead($foe) Then ContinueLoop
		If AmFah600SpiritBondIsNecromancerAgent($foe) Then ContinueLoop
		$count += 1
	Next
	Return $count
EndFunc


Func AmFah600SpiritBondMaintainCoreUpkeep()
	If IsPlayerDead() Then Return
	Local $energy = GetEnergy()
	Local $me = GetMyAgent()
	; Cast Snow Storm/VWK and pre-emptive PS/SB only once the Am Fah are hostile -
	; before that, only keep 1/2 alive so energy stays full for the fight.
	Local $foeCount = CountFoesInRangeOfAgent($me, $RANGE_EARSHOT)
	Local $inCombat = $foeCount > 0
	; Few-foe tail: once only a handful of foes remain ANYWHERE relevant
	; (compass-wide — e.g. the last 2 Marksmen that hover just at/past earshot),
	; Essence-Bond energy income collapses. Drop PS entirely and switch to the
	; energy-saving SB (2) + VWK (4) mode — the saved energy must go to EVAS on
	; those last stragglers (assassins trigger the spike-traps), NOT into a
	; wasted PS refresh. Keyed on the COMPASS living-foe count (not earshot) so
	; a lone Marksman at ~1000-1200 still counts as 'few' — otherwise full mode
	; keeps recasting PS while 2 Marksmen are left. Also triggers on the
	; "healer linchpin" (a Healer + only ranged Marksmen left) — see
	; AmFah600SpiritBondIsEnergyCollapsed. 0 foes keeps full mode so PS/SB
	; never lapse while moving/pulling.
	Local $fewFoes = AmFah600SpiritBondIsEnergyCollapsed()

	; Read both remaining times first to avoid one blocking the other.
	Local $psRemaining = GetEffectTimeRemaining(GetEffect($ID_PROTECTIVE_SPIRIT))
	Local $sbRemaining = GetEffectTimeRemaining(GetEffect($ID_SPIRIT_BOND))

	; ---------------- Energy-saving mode: few foes / healer linchpin ----------------
	If $fewFoes Then
		; SB (the heal engine) always has top priority with scarce energy.
		If $sbRemaining == 0 And IsRecharged($AMFAH600_SPIRIT_BOND) And $energy >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_SPIRIT_BOND] Then
			UseSkillEx($AMFAH600_SPIRIT_BOND)
			RandomSleep(25)
			Return
		EndIf
		; VWK (the reflect kill engine) next — cheap and ends the fight. NOT gated
		; on $inCombat: the few remaining foes (bow Marksmen) hover just outside
		; earshot but still shoot us, so VWK reflect is exactly what kills them.
		If GetEffectTimeRemaining(GetEffect($ID_VENGEFUL_WAS_KHANHEI)) == 0 _
			And IsRecharged($AMFAH600_VWK) _
			And $energy >= 12 Then
			UseSkillEx($AMFAH600_VWK)
			RandomSleep(25)
			Return
		EndIf
		; With a healthy energy buffer (>25), PS is safe to maintain even in the
		; few-foe tail — it prevents a stray spike from one-shotting the monk.
		; Otherwise (scarce energy) keep the old energy-saving mode: SB + VWK
		; alone, no PS. Skip the pre-emptive SB recast — it starves the energy
		; that VWK / Snow Storm need.
		If $psRemaining == 0 And IsRecharged($AMFAH600_PROTECTIVE_SPIRIT) And $energy > 25 Then
			UseSkillEx($AMFAH600_PROTECTIVE_SPIRIT)
			RandomSleep(25)
		EndIf
		Return
	EndIf

	; ---------------- Full mode: many foes, energy income is high ----------------
	Local $castAnything = False

	; Priority #1: Protective Spirit COMPLETELY expired — cast immediately or die.
	If $psRemaining == 0 And IsRecharged($AMFAH600_PROTECTIVE_SPIRIT) And $energy >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_PROTECTIVE_SPIRIT] Then
		UseSkillEx($AMFAH600_PROTECTIVE_SPIRIT)
		$castAnything = True
		$energy -= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_PROTECTIVE_SPIRIT]
		RandomSleep(25)
	EndIf

	; Priority #2: Spirit Bond COMPLETELY expired — cast immediately, this is the
	; active healing engine; without it the 600hp char has zero sustain.
	; ALSO cast if PS was just cast above (both were critical).
	; Gate on $inCombat: SB is only ever cast once the Am Fah are HOSTILE. They
	; aggro with a delay at Tosai, so pre-casting SB before the dialog wastes it
	; and forces a redundant second cast right after — SB must land "in time".
	If $inCombat And $sbRemaining == 0 And IsRecharged($AMFAH600_SPIRIT_BOND) And $energy >= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_SPIRIT_BOND] Then
		UseSkillEx($AMFAH600_SPIRIT_BOND)
		$energy -= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_SPIRIT_BOND]
		; High-pressure rule: VWK is only ever cast DIRECTLY after SB, so its cast
		; time never delays a needed SB recast (SB was just re-applied).
		AmFah600SpiritBondChainVwkAfterSb($energy)
		$castAnything = True
		RandomSleep(25)
	EndIf

	If $castAnything Then Return

	; Priority #3: Pre-emptive Spirit Bond recast. SB has ~4s recharge and ~8s
	; duration, so recasting whenever recharged (energy permitting) keeps the
	; healing engine running without expiry gaps. Reserve 3 energy.
	If $inCombat And $sbRemaining > 0 And IsRecharged($AMFAH600_SPIRIT_BOND) And $energy >= ($AMFAH600_SKILL_COSTS_MAP[$AMFAH600_SPIRIT_BOND] + 3) Then
		UseSkillEx($AMFAH600_SPIRIT_BOND)
		$energy -= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_SPIRIT_BOND]
		; Same high-pressure rule: chain VWK right after the SB refresh.
		AmFah600SpiritBondChainVwkAfterSb($energy)
		$castAnything = True
		RandomSleep(25)
	EndIf

	If $castAnything Then Return

EndFunc


;~ Cast Vengeful Was Khanhei (4) IMMEDIATELY after a Spirit Bond cast (full-mode
;~ high-pressure rule). VWK's ~1s cast must never sit between the SB lapse and
;~ its recast — instead we only summon it while SB was just applied (full ~8s
;~ window), so SB can be recast straight after on the next pass. This keeps the
;~ reflect engine up without ever starving the heal engine.
Func AmFah600SpiritBondChainVwkAfterSb(ByRef $energy)
	If GetEffectTimeRemaining(GetEffect($ID_VENGEFUL_WAS_KHANHEI)) > 0 Then Return
	If Not IsRecharged($AMFAH600_VWK) Then Return
	If $energy < 12 Then Return
	UseSkillEx($AMFAH600_VWK)
	$energy -= $AMFAH600_SKILL_COSTS_MAP[$AMFAH600_VWK]
	RandomSleep(25)
EndFunc


Func AmFah600SpiritBondTryCastEvasOnNecromancer()
	If Not IsRecharged($AMFAH600_EVAS) Then Return False
	Local $collapsed = AmFah600SpiritBondIsEnergyCollapsed()
	; EVAS must fire on a reachable Necromancer from the very start — the
	; summoned assassins are the only way to kill Necros and they pull the
	; second group's healers into range. BUT the summon must never starve the
	; heal engine: it costs 15 and its ~2s cast can outlive the current SB/PS
	; tick. So only summon while the survival core is up and energy matches
	; Snow Storm's floor (20). PS is required ONLY while many foes are beating
	; on us — in the few-foe tail (<= 3 compass-living foes) the upkeep DROPS PS
	; to save energy for EVAS, and the assassin is exactly what finishes the
	; last Necro, so a missing PS must NOT block the summon there.
	If Not $collapsed And GetEffect($ID_PROTECTIVE_SPIRIT) == Null Then Return False
	If GetEffect($ID_SPIRIT_BOND) == Null Then Return False
	If GetEnergy() < ($collapsed ? $AMFAH600_EVAS_MIN_ENERGY_COLLAPSED : $AMFAH600_EVAS_MIN_ENERGY) Then Return False
	; Don't summon during an HP emergency while many foes are beating on us —
	; EVAS has a cast time. With only a few foes left (e.g. the last Necro) the
	; 2s cast is safe even at low HP, and that is exactly when the assassin is
	; needed to finish them off.
	If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.5 And _
		CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) > 3 Then Return False

	; Choose the EVAS target. Maintain always runs before this on the same
	; pass, so a summon only happens while the survival core is healthy.
	;   1) A reachable Necromancer is always highest priority (the only way to
	;      kill Necros — they out-heal SB/VWK reflect). Prefer the Necro the
	;      previous assassin is NOT already on, so assassins spread.
	;   2) Once the Necros are dead, fall back to a Healer (they out-heal the
	;      reflect too) and then to a Marksman in the endgame tail.
	; Only ever target foes inside EVAS' real cast range (~1200): targeting a
	; far one makes the GW client auto-approach (walk toward it, into walls).
	Local $target = AmFah600SpiritBondGetNearestNecromancerInRange($AMFAH600_EVAS_CAST_RANGE, $amfah600_sb_last_evas_target_id)
	If $target == Null Then $target = AmFah600SpiritBondGetNearestNecromancerInRange($AMFAH600_EVAS_CAST_RANGE, 0)
	If $target == Null Then $target = AmFah600SpiritBondGetNearestHealerInRange($AMFAH600_EVAS_CAST_RANGE)
	If $target == Null Then
		Local $livingCompass = AmFah600SpiritBondCountLivingFoes($RANGE_COMPASS)
		If $livingCompass > 0 And $livingCompass <= $AMFAH600_STRAY_MAX_FOES Then
			$target = AmFah600SpiritBondGetNearestMarksmanInRange($AMFAH600_EVAS_CAST_RANGE)
		EndIf
	EndIf
	If $target == Null Then Return False

	$amfah600_sb_last_evas_target_id = DllStructGetData($target, 'ID')
	Local $targetName = AmFah600SpiritBondIsMarksmanAgent($target) ? 'marksman' : (AmFah600SpiritBondIsHealerAgent($target) ? 'healer' : 'necromancer')
	Info('Am Fah 600: casting EVAS on ' & $targetName & ' (dist=' & Round(GetDistance(GetMyAgent(), $target)) & ', id=' & $amfah600_sb_last_evas_target_id & ')')
	UseSkillEx($AMFAH600_EVAS, $target)
	Return True
EndFunc


;~ Slot 3 = Snow Storm (Deldrimor cold AoE over 5 s). EVAS assassins alone are
;~ too slow to kill a Necro that keeps out-living the reflect and stacks life
;~ degeneration on us, so we add direct damage on top. Cast it on a DIFFERENT
;~ Necro than the one the current EVAS assassin is on (see
;~ $amfah600_sb_last_evas_target_id) — both Necros are then worn down in
;~ parallel. Same safety rules as EVAS: never while the survival core is down,
;~ never without an energy buffer (10 for Snow Storm + 10 for an immediate SB).
Func AmFah600SpiritBondTryCastSnowStormOnNecromancer()
	If Not IsRecharged($AMFAH600_SNOW_STORM) Then Return False
	Local $collapsed = AmFah600SpiritBondIsEnergyCollapsed()
	; Same as EVAS: PS is required only while many foes beat on us — in the
	; few-foe tail PS is dropped to fund the kill spells, so it must not block
	; the nuke on the last Necro.
	If Not $collapsed And GetEffect($ID_PROTECTIVE_SPIRIT) == Null Then Return False
	If GetEffect($ID_SPIRIT_BOND) == Null Then Return False
	If GetEnergy() < ($collapsed ? $AMFAH600_SNOW_STORM_MIN_ENERGY_COLLAPSED : $AMFAH600_SNOW_STORM_MIN_ENERGY) Then Return False
	; Don't nuke during an HP emergency while many foes are beating on us.
	If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.5 And _
		CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) > 3 Then Return False
	; Prefer the Necro the EVAS assassin is NOT on, so kills run in parallel;
	; once the Necros are dead, fall back to a Healer.
	Local $necro = AmFah600SpiritBondGetNearestNecromancerInRange($AMFAH600_EVAS_CAST_RANGE, $amfah600_sb_last_evas_target_id)
	If $necro == Null Then $necro = AmFah600SpiritBondGetNearestNecromancerInRange($AMFAH600_EVAS_CAST_RANGE, 0)
	If $necro == Null Then $necro = AmFah600SpiritBondGetNearestHealerInRange($AMFAH600_EVAS_CAST_RANGE)
	If $necro == Null Then Return False
	Info('Am Fah 600: casting Snow Storm on ' & (AmFah600SpiritBondIsHealerAgent($necro) ? 'healer' : 'necromancer') & ' (dist=' & Round(GetDistance(GetMyAgent(), $necro)) & ', id=' & DllStructGetData($necro, 'ID') & ')')
	UseSkillEx($AMFAH600_SNOW_STORM, $necro)
	Return True
EndFunc


Func AmFah600SpiritBondHoldPosition($anchorX, $anchorY, $maxDrift = 140)
	Local $me = GetMyAgent()
	If GetDistanceToPoint($me, $anchorX, $anchorY) <= $maxDrift Then Return
	Move($anchorX, $anchorY)
	RandomSleep(30)
EndFunc


Func AmFah600SpiritBondSendMorgahnToDesert()
	If $amfah600_sb_morgahn_flagged_this_cycle Then
		Info('Morgahn already flagged at recorded spot during approach')
		Return
	EndIf
	If Not AmFah600SpiritBondFlagMorgahnAtRecordedSpotVerified('pre-tosai', $AMFAH600_MORGAHN_SEND_VERIFY_MS) Then _
		Warn('Morgahn flag not verified in time; continuing anyway')
EndFunc


Func AmFah600SpiritBondTryFlagMorgahnAtRecordedSpot($reason = 'approach')
	Local $slot = GetHeroNumberByHeroID($ID_GENERAL_MORGAHN)
	If $slot == Null Then Return

	Info('Flagging Morgahn at recorded spot (' & $reason & '): x=' & $AMFAH600_MORGAHN_FLAG_X & ', y=' & $AMFAH600_MORGAHN_FLAG_Y)
	CommandHero($slot, $AMFAH600_MORGAHN_FLAG_X, $AMFAH600_MORGAHN_FLAG_Y)
	RandomSleep(120)

	Local $heroAgent = GetAgentByID(GetHeroID($slot))
	If $heroAgent == Null Then Return
	Local $dist = GetDistanceToPoint($heroAgent, $AMFAH600_MORGAHN_FLAG_X, $AMFAH600_MORGAHN_FLAG_Y)
	If $dist < 320 Then
		$amfah600_sb_morgahn_flagged_this_cycle = True
		Info('Morgahn flag quick-verified at recorded spot: dist=' & Round($dist))
	EndIf
EndFunc


Func AmFah600SpiritBondFlagMorgahnAtRecordedSpotVerified($reason = 'approach', $maxWaitMs = 4500)
	Local $slot = GetHeroNumberByHeroID($ID_GENERAL_MORGAHN)
	If $slot == Null Then
		Warn('Morgahn flag skipped: General Morgahn not present')
		Return False
	EndIf

	Info('Flagging Morgahn at recorded spot (' & $reason & '): x=' & $AMFAH600_MORGAHN_FLAG_X & ', y=' & $AMFAH600_MORGAHN_FLAG_Y)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $maxWaitMs
		CommandHero($slot, $AMFAH600_MORGAHN_FLAG_X, $AMFAH600_MORGAHN_FLAG_Y)
		RandomSleep(220)

		Local $heroAgent = GetAgentByID(GetHeroID($slot))
		If $heroAgent == Null Then ContinueLoop
		Local $dist = GetDistanceToPoint($heroAgent, $AMFAH600_MORGAHN_FLAG_X, $AMFAH600_MORGAHN_FLAG_Y)
		If $dist < 260 Then
			$amfah600_sb_morgahn_flagged_this_cycle = True
			Info('Morgahn flag verified at recorded point: x=' & Round(DllStructGetData($heroAgent, 'X')) & ', y=' & Round(DllStructGetData($heroAgent, 'Y')))
			Return True
		EndIf
	WEnd

	Warn('Morgahn flag verify timeout (' & $reason & ')')
	Return False
EndFunc


Func AmFah600SpiritBondCastSkillAndWaitFullEnergy($skillSlot, $label)
	If AmFah600SpiritBondCastSkillChecked($skillSlot) == $FAIL Then
		Warn('Could not cast skill for ' & $label)
		Return $FAIL
	EndIf
	If AmFah600SpiritBondWaitForFullEnergy($label) == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondCastSkillChecked($skillSlot)
	Local $timer = TimerInit()
	While IsPlayerAlive() And TimerDiff($timer) < $AMFAH600_ENERGY_WAIT_TIMEOUT_MS
		If IsRecharged($skillSlot) And GetEnergy() >= $AMFAH600_SKILL_COSTS_MAP[$skillSlot] Then
			UseSkillEx($skillSlot)
			RandomSleep(90)
			Return $SUCCESS
		EndIf
		RandomSleep(80)
	WEnd
	Return $FAIL
EndFunc


Func AmFah600SpiritBondWaitForFullEnergy($label)
	Local $timer = TimerInit()
	While IsPlayerAlive() And TimerDiff($timer) < $AMFAH600_ENERGY_WAIT_TIMEOUT_MS
		Local $me = GetMyAgent()
		Local $maxEnergy = DllStructGetData($me, 'MaxEnergy')
		If GetEnergy($me) >= ($maxEnergy - 0.2) Then Return $SUCCESS
		RandomSleep(120)
	WEnd
	Warn('Energy did not refill to full in time: ' & $label)
	Return $FAIL
EndFunc


Func AmFah600SpiritBondGetNearestHealerInRange($range)
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $range)
	Local $nearest = Null
	Local $nearestDist = 100000000
	Local $healerCount = 0
	Static $noneLogTimer = 0
	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If Not AmFah600SpiritBondIsHealerAgent($foe) Then ContinueLoop
		$healerCount += 1
		Local $dist = GetDistance($me, $foe)
		If $dist < $nearestDist Then
			$nearestDist = $dist
			$nearest = $foe
		EndIf
	Next
	If $healerCount == 0 Then
		If $noneLogTimer == 0 Or TimerDiff($noneLogTimer) > 3000 Then
			Info('Am Fah 600: no healer in range=' & $range & ' (foes=' & UBound($foes) & ')')
			$noneLogTimer = TimerInit()
		EndIf
	Else
		$noneLogTimer = 0
		Static $lastHealerHp = -1
		Static $lastHealerDist = 0
		Static $lastHealerLogTime = 0
		Local $curHp = Round(DllStructGetData($nearest, 'HealthPercent') * 100)
		Local $hpChanged = Abs($curHp - $lastHealerHp) >= 15
		Local $distChanged = Abs($nearestDist - $lastHealerDist) >= 200
		If $hpChanged Or $distChanged Or TimerDiff($lastHealerLogTime) > 3000 Then
			Info('Am Fah 600: healer — found=' & $healerCount & ', dist=' & Round($nearestDist) & ', hp=' & $curHp & '%')
			$lastHealerHp = $curHp
			$lastHealerDist = $nearestDist
			$lastHealerLogTime = TimerInit()
		EndIf
	EndIf
	Return $nearest
EndFunc


Func AmFah600SpiritBondTryMorgahnSpeedBoost()
	Local $slot = GetHeroNumberByHeroID($ID_GENERAL_MORGAHN)
	If $slot == Null Then Return
	If $amfah600_sb_morgahn_last_speed_timer <> 0 And TimerDiff($amfah600_sb_morgahn_last_speed_timer) < $AMFAH600_MORGAHN_SPEED_INTERVAL_MS Then Return

	; Strict alternation: 1 → 10s → 2 → 10s → 1 → ...
	; Both skills have 10s duration / 20s cooldown, giving permanent speed.
	If $amfah600_sb_morgahn_last_speed_skill <> 1 Then
		If IsRecharged(1, $slot) Then
			Info('Am Fah 600: Morgahn using Incoming (1)')
			UseHeroSkill($slot, 1)
			$amfah600_sb_morgahn_last_speed_skill = 1
			$amfah600_sb_morgahn_last_speed_timer = TimerInit()
		EndIf
	Else
		If IsRecharged(2, $slot) Then
			Info('Am Fah 600: Morgahn using Fall Back (2)')
			UseHeroSkill($slot, 2)
			$amfah600_sb_morgahn_last_speed_skill = 2
			$amfah600_sb_morgahn_last_speed_timer = TimerInit()
		EndIf
	EndIf
EndFunc


Func AmFah600SpiritBondIsHealerAgent($agent)
	If $agent == Null Then Return False
	Return DllStructGetData($agent, 'ModelID') == $AMFAH600_HEALER_MODEL_ID
EndFunc


Func AmFah600SpiritBondIsNecromancerAgent($agent)
	If $agent == Null Then Return False
	Return DllStructGetData($agent, 'ModelID') == $AMFAH600_NECROMANCER_MODEL_ID
EndFunc


Func AmFah600SpiritBondIsMarksmanAgent($agent)
	If $agent == Null Then Return False
	Return DllStructGetData($agent, 'ModelID') == $AMFAH600_MARKSMAN_MODEL_ID
EndFunc


;~ Count of ALIVE foes within range (GetFoesInRangeOfAgent may include corpses,
;~ so we filter GetIsDead — mirrors ShouldEndFirstFight's counting). Used to
;~ decide the "few-foe tail" where PS is dropped and energy goes to EVAS.
Func AmFah600SpiritBondCountLivingFoes($range = $RANGE_COMPASS)
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $range)
	Local $count = 0
	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If GetIsDead($foe) Then ContinueLoop
		$count += 1
	Next
	Return $count
EndFunc


;~ True when the fight has collapsed into a low-energy state where the PS upkeep
;~ must be dropped and energy redirected to the kill spells (VWK reflect,
;~ EVAS/Snow Storm on a Necro/Healer). Two triggers:
;~   1) few living foes remain anywhere relevant (<= $AMFAH600_FEW_FOES_MAX), or
;~   2) the "healer linchpin": a living Healer is NEARBY (earshot) and every
;~      other nearby living foe is a ranged Marksman. The Healer out-heals the
;~      reflect and the ranged Marksmen don't reliably hit the monk, so
;~      Essence-Bond income collapses and the reflect can never finish them —
;~      we must drop PS and kill the Healer directly with EVAS/Snow Storm.
;~      Scoped to EARSHOT (not compass) so a retreated Necro/Assassin that is
;~      still alive but far away does NOT keep us stuck in full mode.
Func AmFah600SpiritBondIsEnergyCollapsed()
	Local $compassLiving = AmFah600SpiritBondCountLivingFoes($RANGE_COMPASS)

	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
	Local $earshotLiving = 0
	Local $hasHealer = False
	Local $onlyHealerAndMarksmen = True
	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If GetIsDead($foe) Then ContinueLoop
		$earshotLiving += 1
		Local $modelID = DllStructGetData($foe, 'ModelID')
		If $modelID == $AMFAH600_HEALER_MODEL_ID Then
			$hasHealer = True
		ElseIf $modelID <> $AMFAH600_MARKSMAN_MODEL_ID Then
			; A living Necromancer or Assassin is still nearby.
			$onlyHealerAndMarksmen = False
		EndIf
	Next

	; Determine the collapse reason and log transitions (edge-triggered) so a
	; run log shows which trigger fired: 'few' (<= few-foe max) or
	; 'healer_linchpin' (Healer + only ranged Marksmen). 'none' = full mode.
	Local Static $lastCollapse = ''
	Local $reason = ''
	If $compassLiving > 0 And $compassLiving <= $AMFAH600_FEW_FOES_MAX Then
		$reason = 'few'
	ElseIf $hasHealer And $onlyHealerAndMarksmen Then
		$reason = 'healer_linchpin'
	EndIf

	If $reason <> $lastCollapse Then
		AmFah600SpiritBondCsvLog('EnergyCollapse', 'reason=' & ($reason == '' ? 'none' : $reason) & ' compass=' & $compassLiving & ' earshot=' & $earshotLiving)
		$lastCollapse = $reason
	EndIf

	Return $reason <> ''
EndFunc


Func AmFah600SpiritBondGetNearestMarksmanInRange($range, $excludeId = 0)
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $range)
	Local $nearest = Null
	Local $nearestDist = 100000000
	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If GetIsDead($foe) Then ContinueLoop
		If Not AmFah600SpiritBondIsMarksmanAgent($foe) Then ContinueLoop
		If $excludeId <> 0 And DllStructGetData($foe, 'ID') == $excludeId Then ContinueLoop
		Local $dist = GetDistance($me, $foe)
		If $dist < $nearestDist Then
			$nearestDist = $dist
			$nearest = $foe
		EndIf
	Next
	Return $nearest
EndFunc


Func AmFah600SpiritBondCountLivingHealers()
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
	Local $count = 0
	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If GetIsDead($foe) Then ContinueLoop
		If AmFah600SpiritBondIsHealerAgent($foe) Then $count += 1
	Next
	Return $count
EndFunc


Func AmFah600SpiritBondGetNearestNecromancerInRange($range, $excludeId = 0)
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $range)
	Local $nearest = Null
	Local $nearestDist = 100000000
	For $foe In $foes
		If $foe == Null Then ContinueLoop
		If GetIsDead($foe) Then ContinueLoop
		If Not AmFah600SpiritBondIsNecromancerAgent($foe) Then ContinueLoop
		; Skip the Necro the last EVAS assassin is already on, so we spread
		; assassins across multiple Necros instead of stacking on the nearest.
		If $excludeId <> 0 And DllStructGetData($foe, 'ID') == $excludeId Then ContinueLoop
		Local $dist = GetDistance($me, $foe)
		If $dist < $nearestDist Then
			$nearestDist = $dist
			$nearest = $foe
		EndIf
	Next
	Return $nearest
EndFunc


Func AmFah600SpiritBondRezoneViaUndercity()
	Info('Rezoning loop: Tosai -> Undercity -> Wajjun Bazaar')

	; Reverse of recorded Wajjun -> Tosai segment to return to portal side.
	Local $toPortal[][2] = [[15732, -14770], [15645, -14477], [15485, -13729], [15213, -12930], [14983, -12371], [14765, -11976], [14468, -11228], [14639, -10557], [15016, -9361], [15556, -9894], [16147, -9862], [16510, -9978]]
	For $i = 0 To UBound($toPortal) - 1
		If IsPlayerDead() Then
			; Hostile stragglers left over from a poisoned fight can kill the
			; monk mid-walk. Fall through to the combat-death recovery (rez at
			; the shrine right by the portal, then travel through) so the
			; rezone still completes instead of silently failing the run.
			Return AmFah600SpiritBondRecoverFromCombatDeath()
		EndIf
		MoveTo($toPortal[$i][0], $toPortal[$i][1])
		RandomSleep(100)
	Next

	Return AmFah600SpiritBondTravelThroughUndercity()
EndFunc


;~ Travel through The Undercity portal and straight back into Wajjun Bazaar — a
;~ fresh spawn that clears quest/aggro state. The monk must already be near the
;~ portal (this is the shared tail of every tunnel re-zone).
Func AmFah600SpiritBondTravelThroughUndercity()
	Local $mapLoaded = False
	For $i = 1 To 4
		MoveTo(16510, -9978)
		Move(16720, -10010)
		; The zoning trigger sits right at the portal coordinate (recorded
		; 2026-09-09 19:17) — walk to it and keep nudging so it reliably fires.
		Local $walkTimer = TimerInit()
		While TimerDiff($walkTimer) < 8000
			Move($AMFAH600_UNDERCITY_PORTAL_X, $AMFAH600_UNDERCITY_PORTAL_Y)
			RandomSleep(200)
		WEnd
		$mapLoaded = WaitMapLoading($ID_THE_UNDERCITY, 8000, 1500)
		If $mapLoaded Then ExitLoop
	Next
	If Not $mapLoaded Then
		Warn('Could not enter The Undercity portal')
		Return $FAIL
	EndIf

	$mapLoaded = False
	For $i = 1 To 4
		MoveTo(-16309, -6894)
		Move(-16580, -6900)
		RandomSleep(1000)
		$mapLoaded = WaitMapLoading($ID_WAJJUN_BAZAAR, 8000, 1500)
		If $mapLoaded Then ExitLoop
	Next
	If Not $mapLoaded Then
		Warn('Could not return to Wajjun Bazaar')
		Return $FAIL
	EndIf

	$amfah600_sb_maintained_precast_done = False
	$amfah600_sb_precast4_done = False
	$amfah600_sb_precast7_done = False
	$amfah600_sb_precast8_done = False
	Return $SUCCESS
EndFunc


;~ Record a death for the run. Returns True when this is the first (recoverable)
;~ death (still within a single -15% malus); False on the second death, which
;~ means the run must stop (resign/restart from the outpost).
Func AmFah600SpiritBondRecordDeath($context)
	$amfah600_sb_deaths_this_run += 1
	AmFah600SpiritBondCsvLog('Death_' & $context, 'death=' & $amfah600_sb_deaths_this_run & ' morale=' & Round(GetMorale()))
	Return $amfah600_sb_deaths_this_run <= 1
EndFunc


;~ Walk from the rez shrine to the Undercity portal using the wall-avoiding
;~ route recorded 2026-09-09 19:17 — descend from the shrine to the east-west
;~ road (y~-10000), then head straight east to the portal. The old code did a
;~ direct MoveTo to the portal, which body-blocked on walls and never fired.
Func AmFah600SpiritBondWalkShrineToPortal()
	Info('Am Fah 600: walking from rez shrine to Undercity portal')
	Local $waypoints[][2] = [ _
		[15644, -9505], _   ; rez shrine (recording start)
		[15546, -9810], _   ; descend to the east-west road
		[15598, -9976], _   ; onto the road
		[15685, -10010], _  ; turn east
		[15975, -9989], _
		[16267, -9972], _
		[16500, -9958], _
		[16730, -9945], _
		[16906, -9935], _
		[$AMFAH600_UNDERCITY_PORTAL_X, $AMFAH600_UNDERCITY_PORTAL_Y] _
	]
	For $i = 0 To UBound($waypoints) - 1
		If IsPlayerDead() Then Return $FAIL
		MoveTo($waypoints[$i][0], $waypoints[$i][1])
		RandomSleep(120)
	Next
	Return $SUCCESS
EndFunc


;~ After a combat death the monk respawns at the shrine close to the portal.
;~ Walk to the portal, then travel through The Undercity and back into Wajjun
;~ Bazaar — a fresh spawn clears the hostile quest/aggro state.
Func AmFah600SpiritBondRezoneAfterCombatDeath()
	Info('Am Fah 600: rezoning via Undercity tunnels to restart the farm')
	If AmFah600SpiritBondWalkShrineToPortal() == $FAIL Then Return $FAIL
	Return AmFah600SpiritBondTravelThroughUndercity()
EndFunc


;~ Death happened while fighting (foes were still in earshot / the quest is
;~ active). Wait for the shrine resurrection, then re-zone through the Undercity
;~ tunnels to clear the hostile state and restart the farm cycle from a fresh
;~ Wajjun spawn. Only allowed for the first death of the run.
Func AmFah600SpiritBondRecoverFromCombatDeath()
	If Not AmFah600SpiritBondRecordDeath('combat') Then
		Warn('Am Fah 600: second death in this run - pausing at rez shrine (resign/restart needed)')
		Return $FAIL
	EndIf
	Info('Am Fah 600: combat death - waiting to resurrect, then rezoning via tunnels')
	Local $rezTimer = TimerInit()
	While IsPlayerDead() And TimerDiff($rezTimer) < 60000
		RandomSleep(1000)
	WEnd
	If IsPlayerDead() Then
		Warn('Am Fah 600: did not resurrect in time')
		Return $FAIL
	EndIf
	If AmFah600SpiritBondRezoneAfterCombatDeath() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ The Spot-1 fight ended without the monk dying (timeout / poisoned instance:
;~ quest active, foes hostile or stuck stragglers). Reset via the Undercity
;~ tunnels for a fresh instance, bounded so a persistently-unwinnable fight does
;~ not loop forever.
Func AmFah600SpiritBondResetAfterFailedFight()
	$amfah600_sb_fight_retries += 1
	AmFah600SpiritBondCsvLog('FightReset', 'retry=' & $amfah600_sb_fight_retries)
	If $amfah600_sb_fight_retries > 3 Then
		Warn('Am Fah 600: Spot 1 fight failed repeatedly - aborting run')
		; Leave the map clean anyway so the outer restart does not begin inside a
		; poisoned instance (quest active / foes hostile).
		AmFah600SpiritBondRezoneViaUndercity()
		Return $FAIL
	EndIf
	Info('Am Fah 600: Spot 1 fight unclean - rezoning via tunnels to retry (' & $amfah600_sb_fight_retries & '/3)')
	Return AmFah600SpiritBondRezoneViaUndercity()
EndFunc


;~ Walk from Tosai (start of the Spot-2 leg in the normal flow) to Spot 2's
;~ Marksman group anchor. Run without casting — energy must be saved for the
;~ fight at Spot 2.
Func AmFah600SpiritBondGoToSpot2()
	Info('Moving to Spot 2 (Marksman group)')
	; Wall-avoiding route recorded 2026-09-09 18:05 — heads north from Tosai,
	; then a straight north leg, then curves east into Spot 2. The old route cut
	; corners and got the monk body-blocked on walls. Do NOT cast anything during
	; the trek — energy must be saved for the fight at Spot 2.
	Local $waypoints[][2] = [ _
		[15356, -13349], _   ; just north of Tosai (recording start)
		[15254, -12895], _
		[15140, -12565], _
		[15030, -12293], _
		[14941, -12080], _
		[14849, -11864], _
		[14763, -11650], _
		[14681, -11431], _
		[14611, -11212], _
		[14590, -10979], _   ; straight north leg begins
		[14575, -10398], _
		[14557, -10051], _
		[14540, -9818],  _
		[14518, -9587],  _
		[14496, -9358],  _
		[14469, -9068],  _
		[14441, -8777],  _
		[14415, -8488],  _   ; east curve begins
		[14400, -8373],  _
		[14383, -8257],  _
		[14377, -8086],  _
		[14393, -7975],  _
		[14374, -7858],  _
		[14369, -7828],  _   ; recording end
		[$AMFAH600_SPOT2_X, $AMFAH600_SPOT2_Y] _  ; Spot 2
	]
	For $i = 0 To UBound($waypoints) - 1
		If IsPlayerDead() Then Return $FAIL
		MoveTo($waypoints[$i][0], $waypoints[$i][1])
		RandomSleep(120)
	Next
	Return $SUCCESS
EndFunc


;~ Walk / approach from the rez shrine (15479,-8865) DIRECTLY to the Spot 2
;~ anchor (14337,-7157). The shrine sits only a short hop from the 3-Marksman
;~ group, so a direct MoveTo is enough — we do NOT go back toward Tosai (that
;~ route crosses the spike-trap field that killed the monk). True safety comes
;~ from the caller ensuring 6/7/8 + full energy BEFORE calling this: the monk
;~ must never enter the Marksman aggro without her maintained enchants.
Func AmFah600SpiritBondGoFromShrineToSpot2()
	Info('Am Fah 600: walking from rez shrine to Spot 2 Marksman anchor')
	If IsPlayerDead() Then Return $FAIL
	MoveTo($AMFAH600_SPOT2_X, $AMFAH600_SPOT2_Y)
	Return IsPlayerDead() ? $FAIL : $SUCCESS
EndFunc


;~ Guarantee all 3 maintained enchants (6 Retribution, 7 Essence Bond,
;~ 8 Balthazar's Spirit) are active AND energy is near full before the monk
;~ steps into Spot 2's Marksman aggro. Runs while standing safe at the shrine.
Func AmFah600SpiritBondEnsurePrebuffsBeforeSpot2()
	Local $timer = TimerInit()
	While IsPlayerAlive() And TimerDiff($timer) < $AMFAH600_ENERGY_WAIT_TIMEOUT_MS
		If AmFah600SpiritBondAllPrebuffsActive() Then
			Local $me = GetMyAgent()
			Local $maxEnergy = DllStructGetData($me, 'MaxEnergy')
			; Enough energy to cast SB/VWK once in combat AND afford EVAS headroom.
			If GetEnergy($me) >= ($maxEnergy - 0.2) Then Return $SUCCESS
		EndIf
		AmFah600SpiritBondTryMovementPrebuffCast()
		RandomSleep(150)
	WEnd
	If Not AmFah600SpiritBondAllPrebuffsActive() Then
		Warn('Could not ensure prebuffs 6/7/8 before Spot 2')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Wait for Morgahn to be alive again (he respawns at the shrine too), then send
;~ him back to his death/flag spot so he stays clear of the Spot 2 fight.
Func AmFah600SpiritBondReflagMorgahnForSpot2()
	Local $slot = GetHeroNumberByHeroID($ID_GENERAL_MORGAHN)
	If $slot == Null Then
		Warn('Morgahn not present - skipping re-flag for Spot 2')
		Return
	EndIf
	Local $t = TimerInit()
	While TimerDiff($t) < 30000
		Local $heroAgent = GetAgentByID(GetHeroID($slot))
		If $heroAgent <> Null And Not GetIsDead($heroAgent) Then ExitLoop
		RandomSleep(1000)
	WEnd
	Info('Morgahn alive again - flagging him to his death spot for Spot 2')
	AmFah600SpiritBondFlagMorgahnAtRecordedSpotVerified('recover-spot2')
EndFunc


;~ Recover after ONE trap death once Spot 1's foes are all dead (while looting or
;~ walking toward Spot 2). The run is still healthy at a single -15% death, so
;~ the monk respawns at the shrine, re-buffs 6/7/8, refills energy, re-flags
;~ Morgahn, then walks DIRECTLY into the Spot 2 Marksman fight. A second death
;~ (past -15%) is not recoverable within a Spot-2 leg — the caller returns $FAIL
;~ so the outer debug-pause (>= 2 deaths) applies.
Func AmFah600SpiritBondRecoverForSpot2()
	Info('Am Fah 600: trap death after Spot 1 - recovering at shrine to continue to Spot 2')
	If Not AmFah600SpiritBondRecordDeath('trap') Then
		Warn('Am Fah 600: second death in this run - pausing at rez shrine (resign/restart needed)')
		Return $FAIL
	EndIf
	AmFah600SpiritBondCsvLog('Recover_spot2_start', 'death=' & $amfah600_sb_deaths_this_run & ' morale=' & Round(GetMorale()))

	; Wait to be resurrected at the shrine.
	Local $rezTimer = TimerInit()
	While IsPlayerDead() And TimerDiff($rezTimer) < 60000
		RandomSleep(1000)
	WEnd
	If IsPlayerDead() Then
		Warn('Am Fah 600: did not resurrect in time - aborting run')
		AmFah600SpiritBondCsvLog('Recover_spot2_abort', 'death=' & $amfah600_sb_deaths_this_run)
		Return $FAIL
	EndIf
	AmFah600SpiritBondCsvLog('Recover_spot2_alive', 'death=' & $amfah600_sb_deaths_this_run & ' morale=' & Round(GetMorale()))

	; Fresh per-segment bookkeeping after the shrine respawn.
	$amfah600_sb_morgahn_flagged_this_cycle = False
	$amfah600_sb_morgahn_last_speed_timer = 0
	$amfah600_sb_morgahn_last_speed_skill = 0
	$amfah600_sb_maintained_precast_done = False
	$amfah600_sb_precast4_done = False
	$amfah600_sb_precast7_done = False
	$amfah600_sb_precast8_done = False

	; Morgahn also died - wait until he is alive, then send him to his death spot.
	AmFah600SpiritBondReflagMorgahnForSpot2()

	; Stand safe at the shrine, cast 6/7/8 and wait for full energy BEFORE ever
	; stepping toward the 3-Marksman aggro.
	If AmFah600SpiritBondEnsurePrebuffsBeforeSpot2() == $FAIL Then Return $FAIL
	If AmFah600SpiritBondGoFromShrineToSpot2() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Loot after the Am Fah spike traps have expired (method 2: "wait 90s"). The
;~ traps expire ~90s after the Assassins that laid them die, so we wait out that
;~ window and then sweep the field once. All foes are already dead (the fight
;~ only ends when the compass is clear) and the monk is stationary, so nothing
;~ attacks us during the wait — PS/SB/VWK upkeep is NOT needed (in particular
;~ PS must not be maintained; it would only waste energy). The 90s wait also
;~ lets any hero/EVAS drop ownership expire, so a single pass catches
;~ everything without stepping onto a live trap.
Func AmFah600SpiritBondWaitForTrapsAndLoot()
	Info('Am Fah 600: waiting 90s for spike traps to expire before looting')
	Local $waitTimer = TimerInit()
	While IsPlayerAlive() And TimerDiff($waitTimer) < $AMFAH600_TRAP_EXPIRE_MS
		RandomSleep(250)
	WEnd
	PickUpItems()
EndFunc


;~ The Spot 2 leg: wait for Spot 1's spike traps to expire, then loot, walk from
;~ Tosai to Spot 2, fight the 3 Marksmen, loot. If the monk dies once *after*
;~ Spot 1's foes are all dead (a trap on the crossing), we recover from the
;~ shrine DIRECTLY into the Spot 2 fight (still healthy at -15%).
Func AmFah600SpiritBondDoSpot2Leg()
	; Wait for Spot 1's spike traps to expire, then loot, then head to Spot 2.
	AmFah600SpiritBondWaitForTrapsAndLoot()
	If IsPlayerDead() Then
		If AmFah600SpiritBondRecoverForSpot2() == $FAIL Then Return $FAIL
		; Recovered + walked into Spot 2 - fight it.
		If AmFah600SpiritBondFightSpot2() == $FAIL Then Return $FAIL
		AmFah600SpiritBondWaitForTrapsAndLoot()
		Return $SUCCESS
	EndIf

	; Normal path: walk from Tosai to Spot 2.
	If AmFah600SpiritBondGoToSpot2() == $FAIL Then
		; GoToSpot2 only fails on death (a spike trap on the crossing). Recover
		; from the shrine into Spot 2 — this is a trap death, NOT a combat death,
		; so we must not re-zone via the Undercity tunnels.
		If AmFah600SpiritBondRecoverForSpot2() == $FAIL Then Return $FAIL
		If AmFah600SpiritBondFightSpot2() == $FAIL Then Return $FAIL
		AmFah600SpiritBondWaitForTrapsAndLoot()
		Return $SUCCESS
	EndIf

	If AmFah600SpiritBondFightSpot2() == $FAIL Then Return $FAIL
	AmFah600SpiritBondWaitForTrapsAndLoot()
	Return $SUCCESS
EndFunc


;~ The 3 Marksmen normally aggro right at Spot 2's anchor, but occasionally they
;~ spawn further north. If no foe is in aggro range after arriving at Spot 2,
;~ walk north along the search path (recorded 2026-09-09 23:50) until a foe is
;~ in range or the path is exhausted.
Func AmFah600SpiritBondEnsureMarksmanAggro()
	If IsPlayerDead() Then Return $FAIL
	If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) > 0 Then Return $SUCCESS

	Info('Am Fah 600: no Marksmen aggro at Spot 2 - searching deeper spawn')
	Local $search[][2] = [ _
		[14328, -6947], _
		[14246, -6871], _
		[14166, -6790], _
		[14096, -6696], _
		[14017, -6613], _
		[13948, -6519], _
		[13880, -6424], _
		[13812, -6331], _
		[13738, -6230] _
	]
	For $i = 0 To UBound($search) - 1
		If IsPlayerDead() Then Return $FAIL
		AmFah600SpiritBondMaintainCoreUpkeep()
		MoveTo($search[$i][0], $search[$i][1])
		AmFah600SpiritBondMaintainCoreUpkeep()
		If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) > 0 Then Return $SUCCESS
		RandomSleep(120)
	Next
	Return $SUCCESS
EndFunc


Func AmFah600SpiritBondFightSpot2()
	Info('Fighting Spot 2 (Marksman group remnants)')
	; The 3 Marksmen can spawn further north than the anchor — search for their
	; aggro before anchoring the fight.
	If AmFah600SpiritBondEnsureMarksmanAggro() == $FAIL Then Return $FAIL
	Local $timer = TimerInit()
	Local $me = GetMyAgent()
	Local $anchorX = DllStructGetData($me, 'X')
	Local $anchorY = DllStructGetData($me, 'Y')
	Move($anchorX, $anchorY)
	Local $foesCleared = False
	While IsPlayerAlive() And TimerDiff($timer) < 90000
		; Core upkeep first — Maintain runs before EVAS on the same pass and only
		; spends on a summon when PS+SB are up and energy headroom allows it, so
		; EVAS never pre-empts a needed PS/SB/VWK cast.
		AmFah600SpiritBondMaintainCoreUpkeep()

		; Cast EVAS after the core is safe while energy is high.
		If AmFah600SpiritBondTryCastEvasOnNecromancer() Then
			; EVAS cast is done — cancel any client auto-approach toward the
			; Necro and return the monk to the anchor.
			Move($anchorX, $anchorY)
			RandomSleep(60)
			ContinueLoop
		EndIf

		; Snow Storm (3) — cold damage on a Necro while the assassin works the
		; other one; both are worn down in parallel.
		If AmFah600SpiritBondTryCastSnowStormOnNecromancer() Then
			Move($anchorX, $anchorY)
			RandomSleep(60)
			ContinueLoop
		EndIf

		$me = GetMyAgent()

		; End only when EVERY foe in compass is dead. The 3 Marksmen stay at bow
		; range (just outside earshot) and shoot the monk — an earshot-clear
		; check bails to Spot 3 while they are still alive. EVAS assassins chase
		; and kill them from the anchor.
		If TimerDiff($timer) > 8000 And AmFah600SpiritBondShouldEndFirstFight() Then
			$foesCleared = True
			ExitLoop
		EndIf

		; Hold position loosely — Spot 2 is smaller, less need for strict anchoring.
		If GetDistanceToPoint($me, $anchorX, $anchorY) > 250 Then
			Move($anchorX, $anchorY)
			RandomSleep(30)
		EndIf

		; Target: healer > necromancer > nearest enemy.
		Local $target = AmFah600SpiritBondGetNearestHealerInRange($RANGE_COMPASS)
		If $target == Null Then $target = AmFah600SpiritBondGetNearestNecromancerInRange($RANGE_COMPASS)
		If $target == Null Then $target = GetNearestEnemyToAgent($me, $RANGE_EARSHOT)
		If $target <> Null Then ChangeTarget($target)

		RandomSleep(25)
	WEnd

	Return $foesCleared ? $SUCCESS : $FAIL
EndFunc


;~ The Spot 3 leg: walk to the final Am Fah cluster (pre-casting PS/SB/VWK at
;~ the 3-Marksman greeting, then crossing under fire with SB maintenance),
;~ fight the many-Assassin/Healer ball, then wait for the traps to expire and
;~ loot. A death here is a combat death (foes hostile once the Marksmen aggro) —
;~ the caller routes it to a tunnel re-zone + restart.
Func AmFah600SpiritBondDoSpot3Leg()
	Info('Am Fah 600: Spot 3 leg - final Am Fah cluster')
	If AmFah600SpiritBondGoToSpot3() == $FAIL Then Return $FAIL
	If AmFah600SpiritBondFightSpot3() == $FAIL Then Return $FAIL
	AmFah600SpiritBondWaitForTrapsAndLoot()
	Return $SUCCESS
EndFunc


;~ Walk to a point while keeping the survival core (PS/SB/VWK) alive. Unlike
;~ MoveTo (blocking), this ticks MaintainCoreUpkeep every ~100 ms so SB is
;~ recast the instant it lapses while the monk is under fire.
Func AmFah600SpiritBondMoveMaintaining($x, $y, $arriveRadius = 220, $timeoutMs = 25000)
	Local $timer = TimerInit()
	While IsPlayerAlive() And TimerDiff($timer) < $timeoutMs
		AmFah600SpiritBondMaintainCoreUpkeep()
		Local $me = GetMyAgent()
		If GetDistanceToPoint($me, $x, $y) < $arriveRadius Then Return $SUCCESS
		Move($x, $y)
		RandomSleep(100)
	WEnd
	Return IsPlayerDead() ? $FAIL : $SUCCESS
EndFunc


;~ Pre-cast the survival/reflect core (PS/SB/VWK) just OUTSIDE the 3-Marksman
;~ greeting aggro at Spot 3. Mirrors the Spot 1/2 pre-aggro order: PS and SB
;~ first (survival), then VWK (the reflect engine) so the first Marksman volley
;~ is already reflected.
Func AmFah600SpiritBondPrecastForSpot3()
	Info('Am Fah 600: pre-casting PS/SB/VWK before the Spot 3 greeting')
	If AmFah600SpiritBondCastSkillChecked($AMFAH600_PROTECTIVE_SPIRIT) == $FAIL Then Return $FAIL
	If AmFah600SpiritBondCastSkillChecked($AMFAH600_SPIRIT_BOND) == $FAIL Then Return $FAIL
	If AmFah600SpiritBondCastSkillChecked($AMFAH600_VWK) == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Walk from Spot 2 to Spot 3 (the final Am Fah cluster). Phase 1 runs quiet to
;~ the greeting point (energy saved for the pre-cast). Phase 2 pre-casts
;~ PS/SB/VWK just outside the 3-Marksman aggro. Phase 3 crosses PAST the
;~ Marksmen to the kill anchor while maintaining SB/PS under fire (they aggro
;~ the moment we step past the greeting, so SB must be recast on the move).
Func AmFah600SpiritBondGoToSpot3()
	Info('Am Fah 600: walking from Spot 2 to Spot 3 (final Am Fah cluster)')
	; Wall-avoiding route recorded 2026-09-09 18:46 — north from Spot 2, curve
	; west then south, then east into the greeting point.
	Local $toGreeting[][2] = [ _
		[14368, -7122], _  ; just outside Spot 2 (recording start)
		[14469, -8312], _
		[14465, -9187], _
		[14476, -9653], _
		[14501, -10320], _
		[14447, -10779], _
		[14328, -11047], _
		[14239, -11198], _
		[14052, -11490], _
		[13978, -11580], _
		[13794, -11718], _
		[13449, -11753], _
		[13098, -11767], _
		[12633, -11793], _
		[12166, -11817], _
		[11701, -11844], _
		[11236, -11878], _
		[$AMFAH600_SPOT3_GREETING_X, $AMFAH600_SPOT3_GREETING_Y] _
	]
	For $i = 0 To UBound($toGreeting) - 1
		If IsPlayerDead() Then Return $FAIL
		MoveTo($toGreeting[$i][0], $toGreeting[$i][1])
		RandomSleep(120)
	Next

	; Pre-cast the survival/reflect core BEFORE the 3 Marksmen aggro.
	If AmFah600SpiritBondPrecastForSpot3() == $FAIL Then Return $FAIL

	; Cross past the Marksmen to the kill anchor, maintaining SB/PS under fire.
	Local $toAnchor[][2] = [ _
		[10940, -11899], _  ; VWK cast point in the recording
		[10872, -11902], _
		[10640, -11918], _
		[10455, -12040], _
		[10345, -12177], _
		[10188, -12340], _
		[10067, -12531], _
		[9979, -12650], _
		[9982, -12933], _
		[$AMFAH600_SPOT3_X, $AMFAH600_SPOT3_Y] _
	]
	For $i = 0 To UBound($toAnchor) - 1
		If IsPlayerDead() Then Return $FAIL
		If AmFah600SpiritBondMoveMaintaining($toAnchor[$i][0], $toAnchor[$i][1]) == $FAIL Then Return $FAIL
	Next
	AmFah600SpiritBondCsvLog('Spot3_arrived', 'x=' & Round(DllStructGetData(GetMyAgent(), 'X')) & ' y=' & Round(DllStructGetData(GetMyAgent(), 'Y')))
	Return IsPlayerDead() ? $FAIL : $SUCCESS
EndFunc


Func AmFah600SpiritBondFightSpot3()
	Info('Fighting Spot 3 (final Am Fah cluster)')
	Local $timer = TimerInit()
	Local $me = GetMyAgent()
	Local $anchorX = DllStructGetData($me, 'X')
	Local $anchorY = DllStructGetData($me, 'Y')
	Move($anchorX, $anchorY)
	Local $foesCleared = False
	While IsPlayerAlive() And TimerDiff($timer) < $AMFAH600_SPOT3_FIGHT_TIMEOUT_MS
		; Core upkeep first (PS/SB/VWK), then EVAS + Snow Storm on the Healers.
		; There are no Necromancers at Spot 3, so the EVAS/Snow Storm fallback
		; naturally puts both on the Healers — and the many Assassins keep the
		; energy high enough to sustain that on every pass.
		AmFah600SpiritBondMaintainCoreUpkeep()

		; The opening volley at Spot 3 is brutal — suppress EVAS/Snow Storm for
		; the first ~10s at the kill spot so every cast goes to 1/2/4 (PS/SB/VWK).
		If TimerDiff($timer) > $AMFAH600_SPOT3_OPENING_SUPPRESS_MS Then
			If AmFah600SpiritBondTryCastEvasOnNecromancer() Then
				Move($anchorX, $anchorY)
				RandomSleep(60)
				ContinueLoop
			EndIf

			If AmFah600SpiritBondTryCastSnowStormOnNecromancer() Then
				Move($anchorX, $anchorY)
				RandomSleep(60)
				ContinueLoop
			EndIf
		EndIf

		$me = GetMyAgent()

		; End only when EVERY foe in compass is dead (same reason as Spot 2:
		; bow-range Marksmen / stragglers stay just outside earshot and must not
		; be left behind).
		If TimerDiff($timer) > 8000 And AmFah600SpiritBondShouldEndFirstFight() Then
			$foesCleared = True
			ExitLoop
		EndIf

		If GetDistanceToPoint($me, $anchorX, $anchorY) > 250 Then
			Move($anchorX, $anchorY)
			RandomSleep(30)
		EndIf

		; Target: healer > nearest enemy (no Necromancers here).
		Local $target = AmFah600SpiritBondGetNearestHealerInRange($RANGE_COMPASS)
		If $target == Null Then $target = GetNearestEnemyToAgent($me, $RANGE_EARSHOT)
		If $target <> Null Then ChangeTarget($target)

		RandomSleep(25)
	WEnd

	Return $foesCleared ? $SUCCESS : $FAIL
EndFunc


Func AmFah600SpiritBondCsvLog($event, $detail = '')
	Local Static $csvHandle = Null
	If $csvHandle == Null Then
		Local $csvPath = @ScriptDir & '/logs/amfah600_sb_debug-' & GetCharacterName() & '.csv'
		$csvHandle = FileOpen($csvPath, $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
		If $csvHandle == -1 Then Return ; silently skip if file can't be opened
		FileWriteLine($csvHandle, 'timestamp,elapsed_ms,event,detail,map_id,player_hp%,quest_active,foes_earshot,ps_ms,sb_ms,energy')
	EndIf
	Local $elapsed = TimerDiff($run_timer)
	Local $hp = IsPlayerAlive() ? Round(DllStructGetData(GetMyAgent(), 'HealthPercent') * 100, 1) : 0
	Local $quest = IsQuestActive($ID_QUEST_REFUSE_TO_DRINK) ? 1 : 0
	Local $foes = IsPlayerAlive() ? CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) : 0
	Local $psMs = IsPlayerAlive() ? Round(GetEffectTimeRemaining(GetEffect($ID_PROTECTIVE_SPIRIT))) : 0
	Local $sbMs = IsPlayerAlive() ? Round(GetEffectTimeRemaining(GetEffect($ID_SPIRIT_BOND))) : 0
	Local $energy = IsPlayerAlive() ? Round(GetEnergy()) : 0
	Local $ts = @YEAR & '-' & @MON & '-' & @MDAY & ' ' & @HOUR & ':' & @MIN & ':' & @SEC
	FileWriteLine($csvHandle, $ts & ',' & Round($elapsed, 0) & ',' & $event & ',' & $detail & ',' & GetMapID() & ',' & $hp & ',' & $quest & ',' & $foes & ',' & $psMs & ',' & $sbMs & ',' & $energy)
EndFunc
