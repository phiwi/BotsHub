#CS ===========================================================================
|   Underworld Chamber Traps Farm                                           |
|   Solo Ranger trap farm: kills two Aatxe groups in The Chamber            |
|   with Dust Trap combos amplified by Arcane Echo + Echo                   |
|   Authors: BotsHub                                                         |
===========================================================================
; Copyright 2025 caustic-kronos
;
; Licensed under the Apache License, Version 2.0 (the 'License');
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2_Headers.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils.au3'
#include '../utilities/SupportTeam.au3'

Opt('MustDeclareVars', True)

#Region Configuration
Global Const $UWCT_SKILLBAR         = 'OgUTMmLj5Z4uEUCJHlzyR4E3AA'
Global Const $UWCT_WEAPON_SET       = 4

; Skill slot constants (1-based)
Global Const $UWCT_TRAPPERS_SPEED   = 1
Global Const $UWCT_ARCANE_ECHO      = 2
Global Const $UWCT_ECHO             = 3
Global Const $UWCT_DUST_TRAP        = 4
Global Const $UWCT_BARBED_TRAP      = 5
Global Const $UWCT_FLAME_TRAP       = 6
Global Const $UWCT_WHIRLING_DEFENSE = 7
Global Const $UWCT_ETHER_SIGNET     = 8

Global Const $UWCT_FARM_INFORMATIONS = _
    'Solo Ranger trap farm in the Underworld Chamber.' & @CRLF & _
    'Kills two groups of Aatxe using Dust Trap combos amplified by Arcane Echo + Echo.' & @CRLF & _
    'Build: OgUTMmLj5Z4uEUCJHlzyR4E3AA (Ranger, weapon set 4).' & @CRLF & _
    'No heroes needed. Run in Normal Mode.' & @CRLF & _
    'Bind "Panel: Open Hero Commander 2-7" as noted in the GW Options if hero panels are used elsewhere.' & @CRLF & _
    ' ' & @CRLF & _
    'Skill Points:' & @CRLF & _
    'Rune with +3 Wilderness Survival on Head Piece (results in 16 Wilderness Survival)' & @CRLF & _
    'Rune with +3 Expertise on Leggins (results in 15 Expertise)' & @CRLF & _
    ' ' & @CRLF & _
    'Energy:' & @CRLF & _
    'Full Radiant insignias (5x)' & @CRLF & _
    'One additional Rune of Attunement' & @CRLF & _
    'Staff (of Defense) with +20 Energy' & @CRLF & _
    'such that all of the above results in exactly 55 Energy'

Global Const $UWCT_FARM_DURATION     = 5 * 60 * 1000
Global Const $MAX_UWCT_FARM_DURATION = 10 * 60 * 1000
Global Const $UWCT_MAX_ENERGY        = 55   ; Ranger build max energy — update if gear changes

; Aatxe model IDs visible in The Chamber
Global Const $UWCT_AATXE_MODEL_ID         = 2389
Global Const $UWCT_VENGEFUL_AATXE_MODEL_ID = $ID_VENGEFUL_AATXE

Global $uw_ct_farm_setup = False
#EndRegion Configuration


; ============================================================
; Main entry point
; ============================================================
Func UWChamberTrapsFarm()
    If Not $uw_ct_farm_setup And SetupUWChamberTrapsFarm() == $FAIL Then Return $PAUSE

    If EnterUnderworld() <> $SUCCESS Then
        $uw_ct_farm_setup = False
        Return $FAIL
    EndIf

    Local $result = UWChamberTrapsLoop()
    If $result == $SUCCESS Then
        Info('UW Chamber Traps: run completed successfully')
    Else
        Info('UW Chamber Traps: run failed (player died or timed out)')
        $uw_ct_farm_setup = False
    EndIf

    TravelToUWOutpost($district_name)
    Return $result
EndFunc


; ============================================================
; Setup
; ============================================================
Func SetupUWChamberTrapsFarm()
    Info('UW Chamber Traps: setting up')
    If TravelToUWOutpost($district_name) == $FAIL Then Return $FAIL
    SwitchMode($ID_NORMAL_MODE)
    If UWCTEnsureSoloParty() == $FAIL Then Return $FAIL
    If SetupUWCTPlayer() == $FAIL Then Return $FAIL
    $uw_ct_farm_setup = True
    Info('UW Chamber Traps: setup complete')
    Return $SUCCESS
EndFunc


Func UWCTEnsureSoloParty($maxWaitMs = 9000)
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
    Warn('UW Chamber Traps: could not get solo party (size=' & GetPartySize() & ')')
    Return $FAIL
EndFunc


Func SetupUWCTPlayer()
    If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_RANGER Then
        Warn('UW Chamber Traps requires Ranger primary profession')
        Return $FAIL
    EndIf
    If HeroHasTemplate(0, $UWCT_SKILLBAR) Then
        Info('UW Chamber Traps: build already loaded, skipping')
    Else
        LoadSkillTemplate($UWCT_SKILLBAR)
        RandomSleep(250)
    EndIf
    ChangeWeaponSet($UWCT_WEAPON_SET)
    RandomSleep(150)
    Return $SUCCESS
EndFunc


; ============================================================
; Farm loop (one UW run)
; ============================================================
Func UWChamberTrapsLoop()
    ChangeWeaponSet($UWCT_WEAPON_SET)
    RandomSleep(120)

    Local $runTimer = TimerInit()

    ; --- Phase 1: right Aatxe group ---
    Info('UW CT: Phase 1 - moving to Spot 1A')
    MoveTo(1363, 7411)
    If Not IsPlayerAlive() Then Return $FAIL
    If CheckStuck('UW CT', $MAX_UWCT_FARM_DURATION) == $FAIL Then Return $FAIL

    Info('UW CT: casting initial trap combo at Spot 1A')
    UWCTCastInitialCombo()
    If Not IsPlayerAlive() Then Return $FAIL

    Info('UW CT: moving into Spot 1B niche for more traps')
    MoveTo(1397, 7512)
    UWCTCastSpot1BTraps()
    If Not IsPlayerAlive() Then Return $FAIL

    Info('UW CT: aggro run - walking into Aatxe aggro range')
    MoveTo(951, 7859)
    If Not IsPlayerAlive() Then Return $FAIL
    UWCTStepIntoAggroRange()
    If Not IsPlayerAlive() Then Return $FAIL
    Info('UW CT: running back to trap area with Aatxe following')
    MoveTo(1383, 7585)
    If Not IsPlayerAlive() Then Return $FAIL

    UseSkillEx($UWCT_WHIRLING_DEFENSE)
    UWCTCastExtraTraps()

    Info('UW CT: waiting for right Aatxe group to die')
    If UWCTKillLoop($runTimer) == $FAIL Then Return $FAIL

    Sleep(500 + GetPing())
    PickUpItems()
    If Not IsPlayerAlive() Then Return $FAIL

    ; --- Phase 2: second Aatxe group (same choreography as Phase 1) ---
    Info('UW CT: Phase 2 - moving to Spot 2')
    MoveTo(700, 7000)
    MoveTo(200, 6550)
    MoveTo(142, 6191)
    If Not IsPlayerAlive() Then Return $FAIL
    If CheckStuck('UW CT', $MAX_UWCT_FARM_DURATION) == $FAIL Then Return $FAIL

    If UWCTWaitForEnergySpot2(142, 6191) == $FAIL Then Return $FAIL

    Info('UW CT: casting initial trap combo at Spot 2')
    UWCTCastInitialCombo()
    If Not IsPlayerAlive() Then Return $FAIL

    Info('UW CT: Spot 2 - additional trap sequence')
    UWCTCastSpot1BTraps()
    If Not IsPlayerAlive() Then Return $FAIL

    Info('UW CT: aggro run - walking into Aatxe aggro range')
    UWCTLogPosition('spot2_pre_aggro')
    MoveTo(-260, 6380)
    If Not IsPlayerAlive() Then Return $FAIL
    UWCTLogPosition('spot2_stairs')
    UWCTStepIntoAggroRange()
    If Not IsPlayerAlive() Then Return $FAIL
    UWCTLogPosition('spot2_aggro_done')
    ; Whirling Defense before the run back: the Aatxe swarm her at the stairs choke
    ; point and would kill her mid-return without the block stance.
    UseSkillEx($UWCT_WHIRLING_DEFENSE)
    Info('UW CT: running back with second Aatxe group following')
    MoveAvoidingBodyBlock(-432, 6536)
    MoveTo(-258, 6556)
    MoveTo(-28, 6547)
    MoveTo(190, 6476)
    MoveTo(278, 6329)
    MoveTo(400, 6150)
    If Not IsPlayerAlive() Then Return $FAIL
    UWCTLogPosition('spot2_return')

    UWCTCastExtraTraps()

    Info('UW CT: waiting for second Aatxe group to die')
    If UWCTKillLoop($runTimer) == $FAIL Then Return $FAIL

    Sleep(500 + GetPing())
    PickUpItems()

    Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


; ============================================================
; Trap choreography
; ============================================================

; Full Arcane Echo + Echo combo: places up to 3 Dust Traps + Barbed + Flame.
; Sequence (slot numbers):
;   1. Trapper's Speed  (if recharged)
;   2. Arcane Echo      (slot 2 → becomes Echo copy for 20 s)
;   3. Echo             (slot 3 activates; slot 2 is now Echo copy)
;   4. Dust Trap        (slot 3 becomes Dust Trap copy)
;   2. Echo copy        (slot 2 fires Echo again)
;   3. Dust Trap copy   (slot 2, now acting as Echo, becomes Dust Trap copy)
;   2. 3rd Dust Trap    (slot 2's Dust Trap copy fires)
;   5. Barbed Trap
;   6. Flame Trap
Func UWCTCastInitialCombo()
    If IsRecharged($UWCT_TRAPPERS_SPEED) Then
        UseSkillEx($UWCT_TRAPPERS_SPEED)
        RandomSleep(250)
    EndIf

    UWCTEtherSignetCheck()

    UseSkillEx($UWCT_ARCANE_ECHO)
    RandomSleep(250)

    UseSkillEx($UWCT_ECHO)
    RandomSleep(250)

    UseSkillEx($UWCT_DUST_TRAP)
    RandomSleep(250)

    ; Slot 2 now holds Echo copy (0 cooldown) — fires Echo again
    UseSkillEx($UWCT_ARCANE_ECHO)
    RandomSleep(250)

    ; Slot 3 now holds Dust Trap copy (0 cooldown) — slot 2's Echo becomes Dust Trap
    UseSkillEx($UWCT_ECHO)
    RandomSleep(250)

    UWCTEtherSignetCheck()

    ; Slot 2 now holds Dust Trap copy (0 cooldown) — 3rd Dust Trap!
    UseSkillEx($UWCT_ARCANE_ECHO)
    RandomSleep(250)

    UseSkillEx($UWCT_BARBED_TRAP)
    RandomSleep(250)

    UseSkillEx($UWCT_FLAME_TRAP)
    RandomSleep(250)

    ; One final Dust Trap cast if slot 2's copy is still within its 20-second window
    If IsRecharged($UWCT_ARCANE_ECHO) Then
        UseSkillEx($UWCT_ARCANE_ECHO)
        RandomSleep(250)
    EndIf
EndFunc


; Spot 1B sequence:
;   1) Wait for slot 4 → cast (1 if ready), 4, 3
;   2) Wait for slot 3 DT copy (~5 s) → cast 3 directly, then 8, then 2
;   3) Wait for slot 4 → cast 3, 4, 3
Func UWCTCastSpot1BTraps()
    ; Wait for Dust Trap (slot 4) after the initial combo
    Info('UW CT: Spot 1B - waiting for Dust Trap to recharge')
    Local $t = TimerInit()
    While Not IsRecharged($UWCT_DUST_TRAP) And TimerDiff($t) < 35000
        UWCTEtherSignetCheck()
        Sleep(200)
    WEnd

    ; First burst: (1 if ready) → 4 → 3
    If IsRecharged($UWCT_TRAPPERS_SPEED) Then
        UseSkillEx($UWCT_TRAPPERS_SPEED)
        RandomSleep(250)
    EndIf
    UseSkillEx($UWCT_DUST_TRAP)   ; DT #1
    RandomSleep(250)
    UseSkillEx($UWCT_ECHO)        ; Echo activates; slot 3 = DT copy after next spell
    RandomSleep(250)

    ; Slot 3 (DT copy) recharges quickly (~5 s) — wait and cast immediately
    Local $t3 = TimerInit()
    While Not IsRecharged($UWCT_ECHO) And TimerDiff($t3) < 10000
        Sleep(200)
    WEnd
    UseSkillEx($UWCT_ECHO)        ; DT #2 (copy fires)
    RandomSleep(250)

    ; Directly after: 8 (Ether Signet) then 2 (AE / DT copy)
    If IsRecharged($UWCT_ETHER_SIGNET) Then
        UseSkillEx($UWCT_ETHER_SIGNET)
        RandomSleep(250)
    EndIf
    If IsRecharged($UWCT_ARCANE_ECHO) Then
        UseSkillEx($UWCT_ARCANE_ECHO)
        RandomSleep(250)
    EndIf

    ; Wait for slot 4 (DT) for second burst
    Info('UW CT: Spot 1B - waiting for second DT burst')
    Local $t2 = TimerInit()
    While Not IsRecharged($UWCT_DUST_TRAP) And TimerDiff($t2) < 35000
        UWCTEtherSignetCheck()
        Sleep(200)
    WEnd

    ; Second burst: 3 → 4 → 3
    UseSkillEx($UWCT_ECHO)        ; Echo activates
    RandomSleep(250)
    UseSkillEx($UWCT_DUST_TRAP)   ; DT #3; slot 3 = DT copy
    RandomSleep(250)
    UseSkillEx($UWCT_ECHO)        ; DT #4 (copy)
    RandomSleep(250)
    UWCTEtherSignetCheck()
EndFunc


; Cast any recharged traps to maximise trap density at the current position.
; Also attempts an Echo-based Dust Trap combo if both Echo and Dust Trap are ready.
Func UWCTCastExtraTraps()
    UWCTEtherSignetCheck()

    ; Try full Echo + Dust Trap sub-combo for extra Dust Traps
    If IsRecharged($UWCT_ARCANE_ECHO) And IsRecharged($UWCT_ECHO) And IsRecharged($UWCT_DUST_TRAP) Then
        UseSkillEx($UWCT_ARCANE_ECHO)
        RandomSleep(250)
        UseSkillEx($UWCT_ECHO)
        RandomSleep(250)
        UseSkillEx($UWCT_DUST_TRAP)
        RandomSleep(250)
        UseSkillEx($UWCT_ARCANE_ECHO)
        RandomSleep(250)
        UseSkillEx($UWCT_ECHO)
        RandomSleep(250)
        UseSkillEx($UWCT_ARCANE_ECHO)
        RandomSleep(250)
    ElseIf IsRecharged($UWCT_ECHO) And IsRecharged($UWCT_DUST_TRAP) Then
        UseSkillEx($UWCT_ECHO)
        RandomSleep(250)
        UseSkillEx($UWCT_DUST_TRAP)
        RandomSleep(250)
        UseSkillEx($UWCT_ECHO)
        RandomSleep(250)
    ElseIf IsRecharged($UWCT_DUST_TRAP) Then
        UseSkillEx($UWCT_DUST_TRAP)
        RandomSleep(250)
    EndIf

    UWCTEtherSignetCheck()

    If IsRecharged($UWCT_BARBED_TRAP) Then
        UseSkillEx($UWCT_BARBED_TRAP)
        RandomSleep(250)
    EndIf

    If IsRecharged($UWCT_FLAME_TRAP) Then
        UseSkillEx($UWCT_FLAME_TRAP)
        RandomSleep(250)
    EndIf

    UWCTEtherSignetCheck()
EndFunc


; Use Ether Signet when energy is below 5 (safely within the skill's <6 threshold).
Func UWCTEtherSignetCheck()
    If GetEnergy() < 5 And IsRecharged($UWCT_ETHER_SIGNET) Then
        UseSkillEx($UWCT_ETHER_SIGNET)
        RandomSleep(500)
    EndIf
EndFunc


; Wait until energy is at or above $minEnergy, up to 15 seconds.
Func UWCTWaitForEnergy($minEnergy, $maxWaitMs = 15000)
    Local $t = TimerInit()
    While GetEnergy() < $minEnergy And TimerDiff($t) < $maxWaitMs
        Sleep(500)
    WEnd
EndFunc


; Like UWCTWaitForEnergy but watches for Nightmare attacks (Spot 2).
; If health drops during the wait, auto-attack the nearest enemy 4× then return to spot.
Func UWCTWaitForEnergySpot2($spotX, $spotY)
    Info('UW CT: waiting for full energy at Spot 2')
    While GetEnergy() < $UWCT_MAX_ENERGY
        Local $hpBefore = GetHealth()
        Sleep(300)
        If Not IsPlayerAlive() Then Return $FAIL
        If GetHealth() < $hpBefore - 10 Then
            Info('UW CT: Nightmare detected - attacking')
            Local $nightmare = GetNearestEnemyToAgent(GetMyAgent())
            If DllStructGetData($nightmare, 'ID') <> 0 Then
                Attack($nightmare)
                Sleep(1800)
                Attack($nightmare)
                Sleep(1800)
                Attack($nightmare)
                Sleep(1800)
                Attack($nightmare)
                Sleep(1800)
            EndIf
            If Not IsPlayerAlive() Then Return $FAIL
            MoveTo($spotX, $spotY)
        EndIf
        UWCTEtherSignetCheck()
    WEnd
    Return $SUCCESS
EndFunc


Func UWCTStepIntoAggroRange()
    Local $me = GetMyAgent()
    Local $foe = GetNearestEnemyToAgent($me)
    If DllStructGetData($foe, 'ID') = 0 Then
        Warn('UW CT: no enemy found to step into aggro range')
        Return
    EndIf

    Local $myX = DllStructGetData($me, 'X')
    Local $myY = DllStructGetData($me, 'Y')
    Local $dx = DllStructGetData($foe, 'X') - $myX
    Local $dy = DllStructGetData($foe, 'Y') - $myY
    Local $dist = Sqrt($dx * $dx + $dy * $dy)
    If $dist < 1 Then Return
    Local $destX = $myX + ($dx / $dist) * ($dist + 1500)
    Local $destY = $myY + ($dy / $dist) * ($dist + 1500)

    Local $t = TimerInit()
    While CountFoesInRangeOfAgent(GetMyAgent(), $MOB_AGGRO_RANGE) == 0 And TimerDiff($t) < 12000
        If Not IsPlayerAlive() Then Return
        Move($destX, $destY)
        RandomSleep(200)
    WEnd
    CancelAction()
EndFunc


; Log the player's current position, used to see where the Ranger gets stuck during
; the aggro run (e.g. against the stairs at Spot 2).
Func UWCTLogPosition($label)
    Local $me = GetMyAgent()
    Info('UW CT [' & $label & '] pos=' & Round(DllStructGetData($me, 'X')) & '/' & Round(DllStructGetData($me, 'Y')))
EndFunc


; ============================================================
; Kill loop
; ============================================================

; Wait for all enemies in earshot to die, with a 30-second hard timeout.
Func UWCTKillLoop($runTimer)
    Local $killTimer = TimerInit()
    Local $foeCount = 999
    While $foeCount > 0
        Sleep(1000)
        If Not IsPlayerAlive() Then Return $FAIL
        If TimerDiff($runTimer) > $MAX_UWCT_FARM_DURATION Then Return $FAIL
        If TimerDiff($killTimer) > 30000 Then ExitLoop
        $foeCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
    WEnd
    Return $SUCCESS
EndFunc
