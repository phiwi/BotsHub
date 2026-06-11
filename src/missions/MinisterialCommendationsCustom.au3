#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'
#include '../utilities/SupportTeam.au3'
#include <File.au3>

Opt('MustDeclareVars', True)

Global Const $A_COMMENDATIONS_CUSTOM_FARMER_SKILLBAR = 'OwFTQ5q+R6qgnovYHMAwlhSMXEA'
Global Const $COMMENDATIONS_CUSTOM_FARM_INFORMATIONS = 'Custom variant:' & @CRLF _
    & '- expects an Assassin player build' & @CRLF _
    & '- same player flow as original Ministerial run' & @CRLF _
    & '- no hero role validation and no hero skill micromanagement'
Global Const $COMMENDATIONS_CUSTOM_FARM_DURATION = (3 * 60 + 20) * 1000
Global Const $COMMENDATIONS_CUSTOM_MIKU_AGENT_ID = 58

Global Const $COMMENDATIONS_CUSTOM_SKILL_FOR_GREAT_JUSTICE = 1
Global Const $COMMENDATIONS_CUSTOM_SKILL_TO_THE_LIMIT = 2
Global Const $COMMENDATIONS_CUSTOM_SKILL_HUNDRED_BLADES = 3
Global Const $COMMENDATIONS_CUSTOM_SKILL_WHIRLWIND_ATTACK = 4
Global Const $COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET = 5
Global Const $COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE = 6
Global Const $COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED = 7
Global Const $COMMENDATIONS_CUSTOM_SKILL_EBON_BATTLE_STANDARD_OF_HONOR = 8
Global Const $COMMENDATIONS_CUSTOM_MAX_SPIKE_WAIT_MS = 22000
Global Const $COMMENDATIONS_CUSTOM_FAST_RESET_ENABLED = True
Global Const $COMMENDATIONS_CUSTOM_FAST_RESIGN_SLEEP_MS = 1400
Global Const $COMMENDATIONS_CUSTOM_FAST_AFTER_RETURN_SLEEP_MS = 1200
Global Const $COMMENDATIONS_CUSTOM_FAST_WAIT_MAP_MS = 7000
Global Const $COMMENDATIONS_CUSTOM_FAST_WAIT_POLL_MS = 400
Global Const $COMMENDATIONS_CUSTOM_XANDRA_HERO_SLOT = 7
Global Const $COMMENDATIONS_CUSTOM_XANDRA_SOUL_TWISTING = 1
Global Const $COMMENDATIONS_CUSTOM_XANDRA_SHELTER = 2
Global Const $COMMENDATIONS_CUSTOM_XANDRA_UNION = 3
Global Const $COMMENDATIONS_CUSTOM_XANDRA_DISPLACEMENT = 4
Global Const $COMMENDATIONS_CUSTOM_XANDRA_ARMOR_OF_UNFEELING = 5
Global Const $COMMENDATIONS_CUSTOM_ZHED_WARD_AGAINST_MELEE = 7

Global Const $COMMENDATIONS_CUSTOM_HERO_NORGU_TEMPLATE = 'OQREAsIjU8MV5aI/dwPgnWFQDA'
Global Const $COMMENDATIONS_CUSTOM_HERO_RAZAH_TEMPLATE = 'OQREAsIjU8MV5aI/ewPgnWFQDA'
Global Const $COMMENDATIONS_CUSTOM_HERO_GWEN_TEMPLATE = 'OQhjAwBc4QkA5ZIg3ATAcQFVXMA'
Global Const $COMMENDATIONS_CUSTOM_HERO_ZHED_TEMPLATE = 'OgBCkMnTqYHy06znCVBsAZA'
; Global Const $COMMENDATIONS_CUSTOM_HERO_VEKK_TEMPLATE = 'OgNCw8zTtgWsS0i1Do2dtuB'
Global Const $COMMENDATIONS_CUSTOM_HERO_OGDEN_TEMPLATE = 'Owkj4wQopO+sqPetLS9dJ7YfMA'
Global Const $COMMENDATIONS_CUSTOM_HERO_LIVIA_TEMPLATE = 'OAhjQoGYIP3hhWVVaO5EeDzxJA'
Global Const $COMMENDATIONS_CUSTOM_HERO_XANDRA_TEMPLATE = 'OACiAyk8gNtePuwJ00ZOPLYA'

Global Const $COMMENDATIONS_CUSTOM_HERO_NORGU_SLOT = 1
Global Const $COMMENDATIONS_CUSTOM_HERO_RAZAH_SLOT = 2
Global Const $COMMENDATIONS_CUSTOM_HERO_GWEN_SLOT = 3
Global Const $COMMENDATIONS_CUSTOM_HERO_ZHED_SLOT = 4
; Global Const $COMMENDATIONS_CUSTOM_HERO_VEKK_SLOT = 5
Global Const $COMMENDATIONS_CUSTOM_HERO_OGDEN_SLOT = 5
Global Const $COMMENDATIONS_CUSTOM_HERO_LIVIA_SLOT = 6
Global Const $COMMENDATIONS_CUSTOM_HERO_XANDRA_SLOT = 7

Global $ministerial_commendations_custom_farm_setup = False
Global $logging_file_commendations_custom

Global Const $COMMENDATIONS_CUSTOM_DEBUG_SKIP_SETUP_TRAVEL_TO_KAINENG = False
Global Const $COMMENDATIONS_CUSTOM_DEBUG_SKIP_PLAYER_BUILD_SETUP = False


Func ResolveCommendationsCustomDistrict($district)
    Switch $district
        Case 'Random', 'Random EU', 'Random US', 'Random Asia', 'America', 'China', 'English', 'French', 'German', 'International', 'Italian', 'Japan', 'Korea', 'Polish', 'Russian', 'Spanish'
            Return $district
    EndSwitch

    Warn('Unsupported district ' & $district & ' for MinisterialCommendationsCustom. Falling back to Random EU')
    Return 'Random EU'
EndFunc


Func IsCommendationsCustomKainengStartMap()
    Local $mapId = GetMapID()
    Return ($mapId == $ID_Kaineng_Center _
        Or $mapId == $ID_KAINENG_CENTER_DEFAULT _
        Or $mapId == $ID_KAINENG_CENTER_CANTHAN_NEW_YEAR)
EndFunc


Func MinisterialCommendationsCustomFarm()
    If Not $ministerial_commendations_custom_farm_setup Then SetupMinisterialCommendationsCustomFarm()

    Local $result = MinisterialCommendationsCustomFarmLoop()
    If GetMapType() <> $ID_OUTPOST Then
        Info('Reset reason (custom): result=' & $result & ', mapType=' & GetMapType() & ', mapId=' & GetMapID())
        Info('Resetting custom run state: resign and return to Kaineng outpost')
        If ReturnToKainengAfterCustomRun() == $FAIL Then
            Warn('Could not return to Kaineng after custom run reset')
        EndIf
    Else
        Info('No reset needed (custom): already in outpost (result=' & $result & ')')
    EndIf
    Return $result
EndFunc


Func ReturnToKainengAfterCustomRun()
    If Not $COMMENDATIONS_CUSTOM_FAST_RESET_ENABLED Then
        Return ResignAndReturnToOutpost($ID_Kaineng_Center, True)
    EndIf

    Info('Custom Ministerial: fast outpost reset path')
    Resign()
    Sleep($COMMENDATIONS_CUSTOM_FAST_RESIGN_SLEEP_MS)
    ReturnToOutpost()
    Sleep($COMMENDATIONS_CUSTOM_FAST_AFTER_RETURN_SLEEP_MS)
    WaitMapLoading($ID_Kaineng_Center, $COMMENDATIONS_CUSTOM_FAST_WAIT_MAP_MS, $COMMENDATIONS_CUSTOM_FAST_WAIT_POLL_MS)
    If GetMapID() == $ID_Kaineng_Center Then Return $SUCCESS

    Warn('Custom Ministerial: fast reset fallback to standard outpost return')
    Return ResignAndReturnToOutpost($ID_Kaineng_Center, True)
EndFunc


Func SetupMinisterialCommendationsCustomFarm()
    Info('Setting up MinisterialCommendationsCustom farm')
    If Not $COMMENDATIONS_CUSTOM_DEBUG_SKIP_SETUP_TRAVEL_TO_KAINENG Then
        If Not IsCommendationsCustomKainengStartMap() Then
            If TravelToOutpost($ID_Kaineng_Center, ResolveCommendationsCustomDistrict($district_name)) == $FAIL Then Return $FAIL
        EndIf
    Else
        Info('Debug: skip initial travel to Kaineng in custom setup')
    EndIf

    SetupPlayerMinisterialCommendationsCustomFarm()
    SetupTeamMinisterialCommendationsCustomFarm()

    SwitchMode($ID_HARD_MODE)
    $ministerial_commendations_custom_farm_setup = True
    Info('Custom Ministerial preparations complete')
    Return $SUCCESS
EndFunc


Func SetupPlayerMinisterialCommendationsCustomFarm()
    If IsTeamAutoSetup() Then Return $SUCCESS
    If $COMMENDATIONS_CUSTOM_DEBUG_SKIP_PLAYER_BUILD_SETUP Then
        Info('Debug: skip player build auto-load (custom)')
        Return $SUCCESS
    EndIf

    If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
        Info('Custom Ministerial expects assassin. Loading recommended assassin build automatically')
        LoadSkillTemplate($A_COMMENDATIONS_CUSTOM_FARMER_SKILLBAR)
        RandomSleep(250)
    Else
        Warn('Custom Ministerial was designed for assassin. Continuing with current player build')
    EndIf

    Return $SUCCESS
EndFunc


Func SetupTeamMinisterialCommendationsCustomFarm()
    Info('Custom Ministerial: setting fixed hero team (slots 2-8)')

    If CommendationsCustomEnsureSoloParty() == $FAIL Then
        Warn('Could not reset party before fixed hero setup')
        Return $FAIL
    EndIf

    If CommendationsCustomTryAddHero($ID_NORGU, 'Norgu', 2) == $FAIL Then Return $FAIL
    If CommendationsCustomTryAddHero($ID_RAZAH, 'Razah', 3) == $FAIL Then Return $FAIL
    If CommendationsCustomTryAddHero($ID_GWEN, 'Gwen', 4) == $FAIL Then Return $FAIL
    If CommendationsCustomTryAddHero($ID_ZHED_SHADOWHOOF, 'Zhed Shadowhoof', 5) == $FAIL Then Return $FAIL
    ; If CommendationsCustomTryAddHero($ID_VEKK, 'Vekk', 6) == $FAIL Then Return $FAIL
    If CommendationsCustomTryAddHero($ID_OGDEN, 'Ogden', 6) == $FAIL Then Return $FAIL
    If CommendationsCustomTryAddHero($ID_LIVIA, 'Livia', 7) == $FAIL Then Return $FAIL
    If CommendationsCustomTryAddHero($ID_XANDRA, 'Xandra', 8) == $FAIL Then Return $FAIL

    If GetPartySize() <> 8 Then
        Warn('Fixed team setup failed. Expected party size 8, got ' & GetPartySize())
        Return $FAIL
    EndIf

    ; Enforce exact party order so Xandra remains in slot 8 (hero slot 7).
    If GetHeroNumberByHeroID($ID_NORGU) <> $COMMENDATIONS_CUSTOM_HERO_NORGU_SLOT Then Return $FAIL
    If GetHeroNumberByHeroID($ID_RAZAH) <> $COMMENDATIONS_CUSTOM_HERO_RAZAH_SLOT Then Return $FAIL
    If GetHeroNumberByHeroID($ID_GWEN) <> $COMMENDATIONS_CUSTOM_HERO_GWEN_SLOT Then Return $FAIL
    If GetHeroNumberByHeroID($ID_ZHED_SHADOWHOOF) <> $COMMENDATIONS_CUSTOM_HERO_ZHED_SLOT Then Return $FAIL
    ; If GetHeroNumberByHeroID($ID_VEKK) <> $COMMENDATIONS_CUSTOM_HERO_VEKK_SLOT Then Return $FAIL
    If GetHeroNumberByHeroID($ID_OGDEN) <> $COMMENDATIONS_CUSTOM_HERO_OGDEN_SLOT Then Return $FAIL
    If GetHeroNumberByHeroID($ID_LIVIA) <> $COMMENDATIONS_CUSTOM_HERO_LIVIA_SLOT Then Return $FAIL
    If GetHeroNumberByHeroID($ID_XANDRA) <> $COMMENDATIONS_CUSTOM_HERO_XANDRA_SLOT Then Return $FAIL

    LoadSkillTemplate($COMMENDATIONS_CUSTOM_HERO_NORGU_TEMPLATE, $COMMENDATIONS_CUSTOM_HERO_NORGU_SLOT)
    RandomSleep(150)
    LoadSkillTemplate($COMMENDATIONS_CUSTOM_HERO_RAZAH_TEMPLATE, $COMMENDATIONS_CUSTOM_HERO_RAZAH_SLOT)
    RandomSleep(150)
    LoadSkillTemplate($COMMENDATIONS_CUSTOM_HERO_GWEN_TEMPLATE, $COMMENDATIONS_CUSTOM_HERO_GWEN_SLOT)
    RandomSleep(150)
    LoadSkillTemplate($COMMENDATIONS_CUSTOM_HERO_ZHED_TEMPLATE, $COMMENDATIONS_CUSTOM_HERO_ZHED_SLOT)
    RandomSleep(150)
    ; LoadSkillTemplate($COMMENDATIONS_CUSTOM_HERO_VEKK_TEMPLATE, $COMMENDATIONS_CUSTOM_HERO_VEKK_SLOT)
    LoadSkillTemplate($COMMENDATIONS_CUSTOM_HERO_OGDEN_TEMPLATE, $COMMENDATIONS_CUSTOM_HERO_OGDEN_SLOT)
    RandomSleep(150)
    LoadSkillTemplate($COMMENDATIONS_CUSTOM_HERO_LIVIA_TEMPLATE, $COMMENDATIONS_CUSTOM_HERO_LIVIA_SLOT)
    RandomSleep(150)
    LoadSkillTemplate($COMMENDATIONS_CUSTOM_HERO_XANDRA_TEMPLATE, $COMMENDATIONS_CUSTOM_HERO_XANDRA_SLOT)
    RandomSleep(250)

    CancelAllHeroes()
    RandomSleep(250)
    SupportTeamOpenHeroPanels('Ministerial Commendations Custom')
    Return $SUCCESS
EndFunc


Func CommendationsCustomEnsureSoloParty($maxWaitMs = 8000)
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
    Warn('Custom Ministerial: party reset timeout. Party=' & GetPartySize() & ', heroes=' & GetHeroCount())
    Return $FAIL
EndFunc


Func CommendationsCustomTryAddHero($heroID, $heroName, $expectedSize)
    For $i = 1 To 6
        If GetHeroNumberByHeroID($heroID) <> Null Then Return $SUCCESS
        AddHero($heroID)
        RandomSleep(420)
        If GetPartySize() >= $expectedSize Then Return $SUCCESS
    Next
    Warn('Custom Ministerial: could not add hero ' & $heroName & '. Party size=' & GetPartySize())
    Return $FAIL
EndFunc


Func MinisterialCommendationsCustomFarmLoop()
    ChangeWeaponSet(1)
    RandomSleep(100)

    If Not IsCommendationsCustomKainengStartMap() Then
        If TravelToOutpost($ID_Kaineng_Center, ResolveCommendationsCustomDistrict($district_name)) == $FAIL Then Return $FAIL
    EndIf
    If $log_level == 0 Then $logging_file_commendations_custom = FileOpen(@ScriptDir & '/logs/commendation_custom_farm-' & GetCharacterName() & '.log', $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)

    Info('Entering quest (custom)')
    EnterAChanceEncounterQuestCustom()
    If GetMapID() <> $ID_KAINENG_A_CHANCE_ENCOUNTER Then Return $FAIL

    Info('Preparing to fight (custom)')
    PrepareToFightCustom()

    Info('Fighting first group (custom)')
    If InitialFightCustom() == $FAIL Then Return $FAIL
    If IsCommendationsCustomFail() Then Return $FAIL

    Info('Running to kill spot (custom)')
    If RunToKillSpotCustom() == $FAIL Then Return $FAIL
    If IsCommendationsCustomFail() Then Return $FAIL

    Info('Waiting for spike (custom)')
    If WaitForPurityBallCustom() == $FAIL Then Return $FAIL

    Info('Spiking the farm group (custom)')
    If KillMinistryOfPurityCustom() == $FAIL Then Return $FAIL

    RandomSleep(1000)
    Info('Picking up loot')
    ; Sweep until no GUI-allowed items remain nearby (or timeout), instead of fixed pass count.
    Local $lootDeadlock = TimerInit()
    Local $lootPasses = 0
    Local $stalledPasses = 0
    While IsPlayerAlive() And TimerDiff($lootDeadlock) < 45000
        Local $remainingBefore = CountPickableItemsCustom($RANGE_SPIRIT, DefaultShouldPickItem)
        If $remainingBefore == 0 Then ExitLoop

        PickUpItems(HealWhilePickingItemsCustom, DefaultShouldPickItem, $RANGE_SPIRIT)
        RandomSleep(1000)
        $lootPasses += 1

        Local $remainingAfter = CountPickableItemsCustom($RANGE_SPIRIT, DefaultShouldPickItem)
        If $remainingAfter >= $remainingBefore Then
            $stalledPasses += 1
        Else
            $stalledPasses = 0
        EndIf

        ; Prevent endless loops if ownership/pathing blocks specific drops temporarily.
        If $stalledPasses >= 2 Then ExitLoop
    WEnd
    Info('Loot sweep done: passes=' & $lootPasses & ' remaining=' & CountPickableItemsCustom($RANGE_SPIRIT, DefaultShouldPickItem))

    If $log_level == 0 Then FileClose($logging_file_commendations_custom)
    Return $SUCCESS
EndFunc


Func EnterAChanceEncounterQuestCustom()
    Local $me = GetMyAgent()
    Local $coordsX = DllStructGetData($me, 'X')
    Local $coordsY = DllStructGetData($me, 'Y')

    If -1400 < $coordsX And $coordsX < -550 And - 2000 < $coordsY And $coordsY < -1100 Then
        MoveTo(1474, -1197, 25, 0)
    EndIf

    RandomSleep(1000)
    UseCitySpeedBoost()
    Local $npc = GetNearestNPCToCoords(2240, -1264)
    GoToNPC($npc)
    If GetDistance(GetMyAgent(), $npc) > $RANGE_ADJACENT Then
        MoveTo(1474, -1197, 25, 0)
        GoToNPC($npc)
    EndIf
    RandomSleep(250)
    Dialog(0x84)
    RandomSleep(500)
    WaitMapLoading($ID_KAINENG_A_CHANCE_ENCOUNTER)
EndFunc


Func PrepareToFightCustom()
    StartingPositionsCustom()
    RandomSleep(1500)
    RandomSleep(11000)
    UseConsumable($ID_BIRTHDAY_CUPCAKE)
    ; Original run used a hero shout to make enemies hostile; Xandra responds right after that shout.
    If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_FOR_GREAT_JUSTICE) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_FOR_GREAT_JUSTICE)
    PrecastXandraSpiritsCustom()
    RandomSleep(2500)
    UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_EBON_BATTLE_STANDARD_OF_HONOR)
    RandomSleep(1000)
EndFunc


Func StartingPositionsCustom()
    Local $availableHeroes = GetPartySize() - 1

    ; Reuse original opening spread to prevent hero clumping at pull start.
    CommandHeroIfPresentCustom(1, -6524, -5178, $availableHeroes)
    CommandHeroIfPresentCustom(2, -6165, -5585, $availableHeroes)
    CommandHeroIfPresentCustom(3, -6224, -5075, $availableHeroes)
    CommandHeroIfPresentCustom(4, -6033, -5271, $availableHeroes)
    CommandHeroIfPresentCustom(5, -6524, -5178, $availableHeroes)
    CommandHeroIfPresentCustom(6, -5766, -5226, $availableHeroes)
    CommandHeroIfPresentCustom(7, -6170, -4792, $availableHeroes)

    MoveTo(-6285, -5343)
    RandomSleep(1000)

    CommandHeroIfPresentCustom(5, -6515, -5510, $availableHeroes)
EndFunc


Func CommandHeroIfPresentCustom($heroSlot, $x, $y, $availableHeroes)
    If $heroSlot <= $availableHeroes Then CommandHero($heroSlot, $x, $y)
EndFunc


Func PrecastXandraSpiritsCustom()
    Local $availableHeroes = GetPartySize() - 1
    If $COMMENDATIONS_CUSTOM_XANDRA_HERO_SLOT > $availableHeroes Then
        Info('Custom Ministerial: skipping Xandra spirit pre-cast (hero slot missing)')
        LogIntoFileCustom('Xandra pre-cast skipped: hero slot missing')
        Return
    EndIf

    ; Hero 7 (party slot 8): Soul Twisting -> Shelter -> Union -> Displacement, then AoU.
    Info('Custom Ministerial: Xandra pre-cast start (1->2->3->4->5)')
    LogIntoFileCustom('Xandra pre-cast start')

    Info('Custom Ministerial: Xandra cast #1 Soul Twisting')
    LogIntoFileCustom('Xandra cast #1 Soul Twisting')
    UseHeroSkill($COMMENDATIONS_CUSTOM_XANDRA_HERO_SLOT, $COMMENDATIONS_CUSTOM_XANDRA_SOUL_TWISTING)
    RandomSleep(2000)

    Info('Custom Ministerial: Xandra cast #2 Shelter')
    LogIntoFileCustom('Xandra cast #2 Shelter')
    UseHeroSkill($COMMENDATIONS_CUSTOM_XANDRA_HERO_SLOT, $COMMENDATIONS_CUSTOM_XANDRA_SHELTER)
    RandomSleep(2000)

    Info('Custom Ministerial: Xandra cast #3 Union')
    LogIntoFileCustom('Xandra cast #3 Union')
    UseHeroSkill($COMMENDATIONS_CUSTOM_XANDRA_HERO_SLOT, $COMMENDATIONS_CUSTOM_XANDRA_UNION)
    RandomSleep(2000)

    Info('Custom Ministerial: Xandra cast #4 Displacement')
    LogIntoFileCustom('Xandra cast #4 Displacement')
    UseHeroSkill($COMMENDATIONS_CUSTOM_XANDRA_HERO_SLOT, $COMMENDATIONS_CUSTOM_XANDRA_DISPLACEMENT)

    Info('Custom Ministerial: Xandra waiting 10s before cast #5 Armor of Unfeeling')
    LogIntoFileCustom('Xandra wait 10s before cast #5 Armor of Unfeeling')
    RandomSleep(10000)

    Info('Custom Ministerial: Xandra cast #5 Armor of Unfeeling')
    LogIntoFileCustom('Xandra cast #5 Armor of Unfeeling')
    UseHeroSkill($COMMENDATIONS_CUSTOM_XANDRA_HERO_SLOT, $COMMENDATIONS_CUSTOM_XANDRA_ARMOR_OF_UNFEELING)
    RandomSleep(2000)

    Info('Custom Ministerial: Zhed cast #7 Ward Against Melee')
    LogIntoFileCustom('Zhed cast #7 Ward Against Melee')
    UseHeroSkill($COMMENDATIONS_CUSTOM_HERO_ZHED_SLOT, $COMMENDATIONS_CUSTOM_ZHED_WARD_AGAINST_MELEE)
    RandomSleep(2000)

    Info('Custom Ministerial: Xandra pre-cast done')
    LogIntoFileCustom('Xandra pre-cast done')
EndFunc


Func GetMikuAgentOrMineCustom()
    If GetAgentExists($COMMENDATIONS_CUSTOM_MIKU_AGENT_ID) Then Return GetAgentByID($COMMENDATIONS_CUSTOM_MIKU_AGENT_ID)
    Return GetMyAgent()
EndFunc


Func InitialFightCustom()
    LogIntoFileCustom('New custom run started')
    RandomSleep(1000)
    Local $deadlock = TimerInit()
    Local $foesInRange = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS)

    While $foesInRange == 0 And TimerDiff($deadlock) < 10000
        RandomSleep(1000)
        $foesInRange = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS)
        If IsCommendationsCustomFail() Then Return $FAIL
    WEnd

    If $foesInRange == 0 Then
        Info('No initial aggro detected, forcing a short pull')
        If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.85 Then
            If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE)
            If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.75 And IsRecharged($COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET)
            RandomSleep(300)
        EndIf
        If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED)
        MoveTo(-6150, -5150)
        RandomSleep(500)
        MoveTo(-6285, -5343)
        RandomSleep(500)

        Local $pullTimer = TimerInit()
        While $foesInRange == 0 And TimerDiff($pullTimer) < 7000
            If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_FOR_GREAT_JUSTICE) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_FOR_GREAT_JUSTICE)
            RandomSleep(750)
            $foesInRange = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS)
            If IsCommendationsCustomFail() Then Return $FAIL
        WEnd

        If $foesInRange == 0 Then
            Info('Timed out waiting for initial aggro')
            Return $FAIL
        EndIf
    EndIf

    While $foesInRange > 1 And TimerDiff($deadlock) < 80000
        Local $me = GetMyAgent()
        Local $meHp = DllStructGetData($me, 'HealthPercent')
        Local $miku = GetMikuAgentOrMineCustom()
        Local $mikuHp = DllStructGetData($miku, 'HealthPercent')

        ; Survival first: keep player and Miku stable, then pressure.
        If $mikuHp < 0.60 Or $meHp < 0.45 Then
            If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE)
            If DllStructGetData($me, 'HealthPercent') < 0.70 And IsRecharged($COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET)
            RandomSleep(350)
        EndIf

        If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_FOR_GREAT_JUSTICE) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_FOR_GREAT_JUSTICE)
        If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_HUNDRED_BLADES) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_HUNDRED_BLADES)
        If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_TO_THE_LIMIT) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_TO_THE_LIMIT)
        AttackOrUseSkill(1300, $COMMENDATIONS_CUSTOM_SKILL_FOR_GREAT_JUSTICE, $COMMENDATIONS_CUSTOM_SKILL_HUNDRED_BLADES)

        ; Allow player deaths here so heroes can resurrect.
        If IsPlayerDead() Then
            RandomSleep(500)
            ContinueLoop
        EndIf

        $foesInRange = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS)
    WEnd
    If TimerDiff($deadlock) > 80000 Then Info('Timed out waiting for most mobs to be dead')

    PickUpItems(Null, PickOnlyImportantItem)

    CancelAllHeroes()
    Local $mikuPressure = CountFoesInRangeOfAgent($COMMENDATIONS_CUSTOM_MIKU_AGENT_ID, $RANGE_SPELLCAST)
    Local $stabilizeTimer = TimerInit()
    While $mikuPressure > 2 And TimerDiff($stabilizeTimer) < 9000 And Not IsCommendationsCustomFail()
        If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.85 Then
            If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE)
            If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.70 And IsRecharged($COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET)
        EndIf
        AttackOrUseSkill(1200, $COMMENDATIONS_CUSTOM_SKILL_FOR_GREAT_JUSTICE, $COMMENDATIONS_CUSTOM_SKILL_HUNDRED_BLADES)
        RandomSleep(250)
        $mikuPressure = CountFoesInRangeOfAgent($COMMENDATIONS_CUSTOM_MIKU_AGENT_ID, $RANGE_SPELLCAST)
    WEnd

    CommandAll(-6699, -5645)

    If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED)
    Move(-4693, -3137)

    $deadlock = TimerInit()
    While (CountFoesInRangeOfAgent($COMMENDATIONS_CUSTOM_MIKU_AGENT_ID, $RANGE_SPELLCAST) > 0 And TimerDiff($deadlock) < 45000 And Not IsCommendationsCustomFail())
        Move(-4693, -3137)
        RandomSleep(750)
    WEnd
    RandomSleep(500)
    If TimerDiff($deadlock) > 45000 Then Info('Timed out waiting for all mobs to be dead')

    CommandAll(-7075, -5685)

    RandomSleep(250)
    Return $SUCCESS
EndFunc


Func RunToKillSpotCustom()
    If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED)
    MoveTo(-4199, -1475)
    If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED)
    MoveTo(-4709, -609)
    If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED)
    MoveTo(-3116, 650)
    If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED)
    MoveTo(-2518, 631)
    If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED)
    MoveTo(-2096, -1067)
    If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED)
    MoveTo(-815, -1898)
    If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED)
    MoveTo(-690, -3769)
    If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED) Then UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SOLDIERS_SPEED)
    MoveTo(-850, -3961, 0, 0)
    RandomSleep(500)
    Return $SUCCESS
EndFunc


Func WaitForPurityBallCustom()
    Local $deadlock = TimerInit()
    Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)

    While IsPlayerAlive() And $foesCount == 0 And TimerDiff($deadlock) < 55000
        RandomSleep(1000)
        $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
    WEnd

    LogIntoFileCustom('Ball wait start foes=' & $foesCount & ' wwAdr=' & GetSkillbarSkillAdrenaline($COMMENDATIONS_CUSTOM_SKILL_WHIRLWIND_ATTACK))

    Local $ping = GetPing()
    Local $spikeWaitTimer = TimerInit()
    While IsPlayerAlive() And TimerDiff($deadlock) < 75000 And (Not IsFurthestMobInBallCustom() Or GetSkillbarSkillAdrenaline($COMMENDATIONS_CUSTOM_SKILL_WHIRLWIND_ATTACK) < 130)
        If TimerDiff($spikeWaitTimer) >= $COMMENDATIONS_CUSTOM_MAX_SPIKE_WAIT_MS Then
            LogIntoFileCustom('Ball wait forced engage at ' & Round(TimerDiff($spikeWaitTimer) / 1000) & 's (foes=' & $foesCount & ', wwAdr=' & GetSkillbarSkillAdrenaline($COMMENDATIONS_CUSTOM_SKILL_WHIRLWIND_ATTACK) & ')')
            ExitLoop
        EndIf

        If ($foesCount > 3 And IsRecharged($COMMENDATIONS_CUSTOM_SKILL_TO_THE_LIMIT) And GetSkillbarSkillAdrenaline($COMMENDATIONS_CUSTOM_SKILL_WHIRLWIND_ATTACK) < 130) Then
            UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_TO_THE_LIMIT)
            RandomSleep(50)
        EndIf

        Local $meHp = DllStructGetData(GetMyAgent(), 'HealthPercent')
        If $meHp < 0.90 Then
            ; Prioritize Shadow Refuge whenever healing is needed at hold spot.
            While IsPlayerAlive() And IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE)
                UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE)
                RandomSleep(50)
            WEnd

            $meHp = DllStructGetData(GetMyAgent(), 'HealthPercent')
            If $meHp < 0.82 And IsRecharged($COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET) Then
                UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET)
                Sleep(100 + $ping)
            EndIf
        EndIf

        $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
        RandomSleep(250)
    WEnd

    LogIntoFileCustom('Ball wait end t=' & Round(TimerDiff($deadlock) / 1000) & 's foes=' & $foesCount & ' furthestInBall=' & IsFurthestMobInBallCustom() & ' wwAdr=' & GetSkillbarSkillAdrenaline($COMMENDATIONS_CUSTOM_SKILL_WHIRLWIND_ATTACK))
    If IsPlayerDead() Then
        Warn('Player died at hold spot during wait.')
        LogIntoFileCustom('Player died at hold spot during wait.')
        Return $FAIL
    EndIf
    If TimerDiff($deadlock) > 75000 Then Info('Timed out waiting for mobs to ball')
    Return $SUCCESS
EndFunc


Func IsFurthestMobInBallCustom()
    Local $furthestEnemy = GetNearestEnemyToCoords(1817, -798)
    Return GetDistance($furthestEnemy, GetMyAgent()) <= $RANGE_NEARBY
EndFunc


Func KillMinistryOfPurityCustom()
    Local $deadlock
    Local $foesCount

    If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.90 Then
        While IsPlayerAlive() And IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE)
            UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE)
            RandomSleep(50)
        WEnd

        If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.65 And IsRecharged($COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET) Then
            UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET)
            RandomSleep(50)
        EndIf
    EndIf

    If IsPlayerDead() Then
        Warn('Player died at hold spot during spike.')
        LogIntoFileCustom('Player died at hold spot during spike.')
        Return $FAIL
    EndIf

    ; Give the ball two more seconds to tighten before starting the spike sequence.
    RandomSleep(2000)

    UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_EBON_BATTLE_STANDARD_OF_HONOR)
    RandomSleep(50)

    If IsPlayerDead() Then
        Warn('Player died at hold spot during spike.')
        LogIntoFileCustom('Player died at hold spot during spike.')
        Return $FAIL
    EndIf
    UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_HUNDRED_BLADES)
    RandomSleep(50)

    If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_FOR_GREAT_JUSTICE) Then
        While IsRecharged($COMMENDATIONS_CUSTOM_SKILL_FOR_GREAT_JUSTICE)
            UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_FOR_GREAT_JUSTICE)
            RandomSleep(50)
            If IsPlayerDead() Then
                Warn('Player died at hold spot during spike.')
                LogIntoFileCustom('Player died at hold spot during spike.')
                Return $FAIL
            EndIf
        WEnd
    EndIf

    Local $initialFoeCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
    Local $initialAdrenaline = GetSkillbarSkillAdrenaline($COMMENDATIONS_CUSTOM_SKILL_WHIRLWIND_ATTACK)
    Local $adrenaline = $initialAdrenaline
    While IsRecharged($COMMENDATIONS_CUSTOM_SKILL_WHIRLWIND_ATTACK) And $adrenaline >= $initialAdrenaline
        If IsPlayerDead() Then
            Warn('Player died at hold spot during spike.')
            LogIntoFileCustom('Player died at hold spot during spike.')
            Return $FAIL
        EndIf
        RandomSleep(200)

        $adrenaline = GetSkillbarSkillAdrenaline($COMMENDATIONS_CUSTOM_SKILL_WHIRLWIND_ATTACK)
        If (IsRecharged($COMMENDATIONS_CUSTOM_SKILL_TO_THE_LIMIT) And $adrenaline < 130) Then
            UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_TO_THE_LIMIT)
            RandomSleep(50)
        EndIf

        UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_WHIRLWIND_ATTACK, GetNearestEnemyToAgent(GetMyAgent()))
        RandomSleep(50)
    WEnd

    CancelAction()
    RandomSleep(250)
    CancelAction()

    $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)

    $deadlock = TimerInit()
    ; If some foes are still alive, we have 10s to finish them else we just pick up and leave.
    While $foesCount > 0 And TimerDiff($deadlock) < 10000
        If IsPlayerDead() Then
            Warn('Player died at hold spot during spike.')
            LogIntoFileCustom('Player died at hold spot during spike.')
            Return $FAIL
        EndIf

        If (IsRecharged($COMMENDATIONS_CUSTOM_SKILL_TO_THE_LIMIT) And GetSkillbarSkillAdrenaline($COMMENDATIONS_CUSTOM_SKILL_WHIRLWIND_ATTACK) < 130) Then
            UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_TO_THE_LIMIT)
            RandomSleep(50)
        EndIf

        Local $meHp = DllStructGetData(GetMyAgent(), 'HealthPercent')
        If $meHp < 0.90 Then
            While IsPlayerAlive() And IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE)
                UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE)
                RandomSleep(50)
            WEnd

            $meHp = DllStructGetData(GetMyAgent(), 'HealthPercent')
            If $meHp < 0.60 And IsRecharged($COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET) Then
                UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET)
                RandomSleep(1000)
            EndIf
        ElseIf GetSkillbarSkillAdrenaline($COMMENDATIONS_CUSTOM_SKILL_WHIRLWIND_ATTACK) == 130 Then
            While IsRecharged($COMMENDATIONS_CUSTOM_SKILL_WHIRLWIND_ATTACK) And TimerDiff($deadlock) < 10000
                If IsPlayerDead() Then
                    Warn('Player died at hold spot during spike.')
                    LogIntoFileCustom('Player died at hold spot during spike.')
                    Return $FAIL
                EndIf
                UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_WHIRLWIND_ATTACK, GetNearestEnemyToAgent(GetMyAgent()))
                RandomSleep(250)
            WEnd
        Else
            AttackOrUseSkill(1300, $COMMENDATIONS_CUSTOM_SKILL_FOR_GREAT_JUSTICE)
        EndIf

        $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
    WEnd
    CancelAction()

    If TimerDiff($deadlock) > 10000 Then Info('Left ' & $foesCount & ' mobs alive out of ' & $initialFoeCount & ' foes')
    LogIntoFileCustom('Mobs killed - ' & ($initialFoeCount - $foesCount))
    LogIntoFileCustom('Mobs left alive - ' & $foesCount)

    Sleep(250)
    Return $SUCCESS
EndFunc


Func HealWhilePickingItemsCustom()
    If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.90 Then
        If IsRecharged($COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE) Then
            UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_SHADOW_REFUGE)
            RandomSleep(50)
        EndIf
        If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.80 And IsRecharged($COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET) Then
            UseSkillEx($COMMENDATIONS_CUSTOM_SKILL_HEALING_SIGNET)
            Sleep(20 + GetPing())
        EndIf
    EndIf
EndFunc


Func CountPickableItemsCustom($range = $RANGE_SPIRIT, $shouldPickItem = DefaultShouldPickItem)
    Local $count = 0
    Local $agents = GetAgentArray($ID_AGENT_TYPE_ITEM)
    Local $me = GetMyAgent()
    Local $item

    For $agent In $agents
        If Not GetCanPickUp($agent) Then ContinueLoop
        If GetDistance($me, $agent) > $range Then ContinueLoop

        $item = GetItemByAgentID(DllStructGetData($agent, 'ID'))
        If $shouldPickItem($item) Then $count += 1
    Next

    Return $count
EndFunc


Func IsCommendationsCustomFail()
    If IsPlayerDead() Then
        Warn('Player died.')
        LogIntoFileCustom('Player died.')
        Return True
    EndIf
    Return False
EndFunc


Func LogIntoFileCustom($string)
    If $log_level == 0 Then _FileWriteLog($logging_file_commendations_custom, $string)
EndFunc
