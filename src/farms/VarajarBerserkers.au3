#CS ===========================================================================
; Author: GitHub Copilot
; Copyright 2026
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
#include '../../lib/GWA2_ID_Skills.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'


; ==== Constants ====
Global Const $VARAJAR_BERSERKERS_SKILLBAR = 'OwFTQ56+NimUlZULXsvYHMC6ACA'
Global Const $VARAJAR_MARGRID_SKILLBAR = 'OgkjYxYjJPQHe8O+5AAAAAAAAA'
Global Const $VARAJAR_MORGAHN_SKILLBAR = 'OQijEamLKPm4bMLGAwj3xDbAAA'
Global Const $VARAJAR_KOSS_SKILLBAR = 'OQkiUxm8wj3xAAAAAAAAAAAA'
Global Const $VARAJAR_MOX_SKILLBAR = 'OgmiYynywjBAAAAAAAAAAAAA'
Global Const $VARAJAR_JORA_SKILLBAR = 'OQkiUxm8wj3xAAAAAAAAAAAA'

Global Const $VARAJAR_BERSERKERS_FARM_INFORMATIONS = 'A/W Whirlwind Sin farming Norn Berserkers in Varajar Fells for Berserker Horns.' & @CRLF _
	& '- Start in Olafstead, exit toward Varajar Fells' & @CRLF _
	& '- Margrid (EoE + Winnowing, disabled) + Morgahn (Enduring Harmony/Make Haste/Bladeturn Refrain/Incoming, disabled) provide speed and damage' & @CRLF _
	& '- 5 extra heroes act as meat shields to survive the run' & @CRLF _
	& '- Midway, meat shields 4-7 are flagged onto the dangerous troop; Margrid/Morgahn/Koss are flagged away at the split spot' & @CRLF _
	& '- Sin casts I Am Unstoppable, runs an aggro circle, then spikes with Hundred Blades + Whirlwind Attack'
Global Const $VARAJAR_BERSERKERS_FARM_DURATION = 4 * 60 * 1000

; Assassin/Warrior player skill slots
Global Const $VB_I_AM_UNSTOPPABLE = 1
Global Const $VB_PROTECTORS_DEFENSE = 2
Global Const $VB_SOLDIERS_DEFENSE = 3
Global Const $VB_EBON_BATTLE_STANDARD = 4
Global Const $VB_HUNDRED_BLADES = 5
Global Const $VB_WHIRLWIND_ATTACK = 6
Global Const $VB_UNSEEN_FURY = 7
Global Const $VB_SHROUD_OF_DISTRESS = 8

; Hero party indices (Margrid added first, Morgahn second)
Global Const $VB_MARGRID = 1
Global Const $VB_MORGAHN = 2

; Hero skill slots
Global Const $VB_MARGRID_EOE = 1
Global Const $VB_MARGRID_WINNOWING = 4
Global Const $VB_MORGAHN_VOCAL_WAS_SOGOLON = 7
Global Const $VB_MORGAHN_ENDURING_HARMONY = 1
Global Const $VB_MORGAHN_MAKE_HASTE = 2
Global Const $VB_MORGAHN_BLADETURN_REFRAIN = 3
Global Const $VB_MORGAHN_INCOMING = 5

; Key coordinates
Global Const $VB_SPLIT_X = -13000
Global Const $VB_SPLIT_Y = -6620
Global Const $VB_FLAG_AWAY_X = -2300
Global Const $VB_FLAG_AWAY_Y = 550
Global Const $VB_KILL_X = -15653
Global Const $VB_KILL_Y = -7067

; Meat shields (4-7) are flagged onto this dangerous troop midway through the approach so
; they tank it instead of it killing Margrid (1) / Morgahn (2).
; Destination = the Sin's final position in the flag recording (the heroes were body-blocked
; on the way and never reached it, so their stop position was NOT the real flag spot).
Global Const $VB_MEATSHIELD_FLAG_X = -6998
Global Const $VB_MEATSHIELD_FLAG_Y = -2526

; Wait point on the approach route where the Sin stops to issue the meat-shield flag.
Global Const $VB_MEATSHIELD_TRIGGER_X = -3944
Global Const $VB_MEATSHIELD_TRIGGER_Y = -4781

Global $varajar_berserkers_farm_setup = False
Global $varajar_margrid_dead = False
Global $varajar_morgahn_dead = False
Global $varajar_log_handle = -1
Global $varajar_log_file = ''
Global $varajar_log_run_number = 0
Global $varajar_log_timer


;~ Main method to farm Norn Berserkers
Func VarajarBerserkersFarm()
	If Not $varajar_berserkers_farm_setup And SetupVarajarBerserkersFarm() == $FAIL Then Return $PAUSE
	$varajar_log_run_number += 1
	VarajarLogInit()
	VarajarLogWrite('run_start', 'setup=' & $varajar_berserkers_farm_setup)
	Local $result = VarajarBerserkersFarmLoop()
	VarajarLogWrite('run_end', 'result=' & $result)
	VarajarLogClose()
	Return $result
EndFunc


;~ Farm setup : travel to Olafstead and prepare player + team
Func SetupVarajarBerserkersFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_OLAFSTEAD, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_HARD_MODE)
	If SetupPlayerVarajarBerserkers() == $FAIL Then Return $FAIL
	If SetupTeamVarajarBerserkers() == $FAIL Then Warn('Could not set up full hero team. Continuing with what is available')
	$varajar_berserkers_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerVarajarBerserkers()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_ASSASSIN Then
		Warn('Should run this farm as assassin')
		Return $FAIL
	EndIf
	If HeroHasTemplate(0, $VARAJAR_BERSERKERS_SKILLBAR) Then
		Info('Varajar Berserkers player: template already loaded, skipping')
	Else
		LoadSkillTemplate($VARAJAR_BERSERKERS_SKILLBAR)
		RandomSleep(250)
	EndIf
	; Activate weapon set 1 for the Hundred Blades + Whirlwind spike
	ChangeWeaponSet(1)
	RandomSleep(150)
	Return $SUCCESS
EndFunc


Func SetupTeamVarajarBerserkers()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up team')
	LeaveParty()

	; Margrid and Morgahn are required; the other five are meat shields
	Local $requiredOk = True
	$requiredOk = $requiredOk And (AddRequiredHero($ID_MARGRID_THE_SLY) == $SUCCESS)
	$requiredOk = $requiredOk And (AddRequiredHero($ID_GENERAL_MORGAHN) == $SUCCESS)

	AddRequiredHero($ID_KOSS)
	AddRequiredHero($ID_MOX)
	AddRequiredHero($ID_MELONNI)
	AddRequiredHero($ID_KAHMU)
	AddRequiredHero($ID_JORA)

	; Load hero builds (skip any that are already loaded)
	VarajarLoadHeroTemplate($VB_MARGRID, $VARAJAR_MARGRID_SKILLBAR, 'Margrid')
	VarajarLoadHeroTemplate($VB_MORGAHN, $VARAJAR_MORGAHN_SKILLBAR, 'Morgahn')
	VarajarLoadHeroTemplate(3, $VARAJAR_KOSS_SKILLBAR, 'Koss')
	VarajarLoadHeroTemplate(4, $VARAJAR_MOX_SKILLBAR, 'MOX')
	VarajarLoadHeroTemplate(5, $VARAJAR_MOX_SKILLBAR, 'Melonni')
	VarajarLoadHeroTemplate(6, $VARAJAR_MOX_SKILLBAR, 'Kahmu')
	VarajarLoadHeroTemplate(7, $VARAJAR_JORA_SKILLBAR, 'Jora')

	; Open only Margrid (hero 1) and Morgahn (hero 2) hero panels
	VarajarOpenHeroPanels()

	; Disable skills that the bot commands manually
	DisableHeroSkillSlot($VB_MARGRID, $VB_MARGRID_EOE)
	DisableHeroSkillSlot($VB_MARGRID, $VB_MARGRID_WINNOWING)
	DisableHeroSkillSlot($VB_MORGAHN, $VB_MORGAHN_ENDURING_HARMONY)
	DisableHeroSkillSlot($VB_MORGAHN, $VB_MORGAHN_MAKE_HASTE)
	DisableHeroSkillSlot($VB_MORGAHN, $VB_MORGAHN_BLADETURN_REFRAIN)
	DisableHeroSkillSlot($VB_MORGAHN, $VB_MORGAHN_INCOMING)

	; Margrid + Morgahn (the important casters) avoid combat; the five meat shields
	; guard the player so they tank enemy aggro on the approach instead of fleeing.
	SetHeroBehaviour($VB_MARGRID, $ID_HERO_AVOIDING)
	SetHeroBehaviour($VB_MORGAHN, $ID_HERO_AVOIDING)
	For $i = 3 To 7
		SetHeroBehaviour($i, $ID_HERO_GUARDING)
	Next

	Return $requiredOk ? $SUCCESS : $FAIL
EndFunc


;~ Load a hero template only if it is not already loaded
Func VarajarLoadHeroTemplate($heroIndex, $templateCode, $heroName)
	If HeroHasTemplate($heroIndex, $templateCode) Then
		Info('Varajar Berserkers ' & $heroName & ': template already loaded, skipping')
		Return
	EndIf
	LoadSkillTemplate($templateCode, $heroIndex)
	RandomSleep(150)
EndFunc


;~ Send a panel key to the GW window (inlined from SupportTeam.au3 so this farm is self-contained)
Func VarajarSendPanelKey($key)
	Local $hWnd = GetWindowHandle()
	If $hWnd <> 0 Then WinActivate($hWnd)
	Sleep(80 + GetPing())
	ControlSend($hWnd, '', '', $key)
EndFunc


;~ Open only Margrid (hero 1) and Morgahn (hero 2) hero panels
Func VarajarOpenHeroPanels()
	CloseAllPanels()
	Sleep(150 + GetPing())
	ToggleHeroPanel(1)
	Sleep(130 + GetPing())
	VarajarSendPanelKey('9')
	Sleep(130 + GetPing())
EndFunc


;~ Move out of Olafstead into Varajar Fells
Func VarajarBerserkersGoToZone()
	TravelToOutpost($ID_OLAFSTEAD, $district_name)
	While GetMapID() <> $ID_VARAJAR_FELLS
		Info('Moving to Varajar Fells')
		MoveTo(222, 756)
		Move(-1435, 1217)
		RandomSleep(5000)
		WaitMapLoading($ID_VARAJAR_FELLS, 10000, 2000)
	WEnd
EndFunc


;~ Called while moving to flag critical hero deaths (Margrid + Morgahn) so the run can be aborted
Func VarajarCheckCriticalHeroesAlive()
	If IsHeroDead($VB_MARGRID) Then $varajar_margrid_dead = True
	If IsHeroDead($VB_MORGAHN) Then $varajar_morgahn_dead = True
EndFunc


;~ Run from the Varajar Fells entry to the split spot
Func VarajarBerserkersRunToSplit()
	$varajar_margrid_dead = False
	$varajar_morgahn_dead = False
	; Direct route re-recorded 2026-09-06 17:18 (path_action_20260906_171841.csv) which passes through the
	; dangerous-troop flag point; tail merged from path_action_20260906_170233.csv to reach the split spot.
	Local $route[241][2] = [ _
		[-2252, 831], _
		[-2269, 796], _
		[-2312, 727], _
		[-2351, 661], _
		[-2389, 594], _
		[-2426, 528], _
		[-2465, 460], _
		[-2513, 397], _
		[-2561, 335], _
		[-2608, 274], _
		[-2653, 216], _
		[-2702, 153], _
		[-2749, 92], _
		[-2792, 27], _
		[-2831, -42], _
		[-2867, -111], _
		[-2903, -179], _
		[-2939, -247], _
		[-2977, -319], _
		[-3013, -386], _
		[-3046, -455], _
		[-3076, -525], _
		[-3106, -598], _
		[-3133, -669], _
		[-3162, -744], _
		[-3184, -813], _
		[-3203, -894], _
		[-3222, -969], _
		[-3234, -1044], _
		[-3245, -1119], _
		[-3257, -1196], _
		[-3269, -1276], _
		[-3280, -1354], _
		[-3292, -1430], _
		[-3304, -1510], _
		[-3315, -1588], _
		[-3327, -1663], _
		[-3338, -1739], _
		[-3334, -1818], _
		[-3317, -1895], _
		[-3297, -1969], _
		[-3271, -2043], _
		[-3243, -2109], _
		[-3221, -2162], _
		[-3194, -2217], _
		[-3167, -2270], _
		[-3139, -2324], _
		[-3107, -2386], _
		[-3072, -2456], _
		[-3038, -2522], _
		[-3003, -2590], _
		[-2966, -2662], _
		[-2931, -2731], _
		[-2896, -2799], _
		[-2880, -2869], _
		[-2850, -2937], _
		[-2815, -3005], _
		[-2780, -3073], _
		[-2743, -3146], _
		[-2708, -3213], _
		[-2673, -3282], _
		[-2649, -3356], _
		[-2643, -3432], _
		[-2668, -3509], _
		[-2707, -3575], _
		[-2733, -3645], _
		[-2766, -3714], _
		[-2812, -3775], _
		[-2866, -3831], _
		[-2925, -3881], _
		[-2987, -3930], _
		[-3049, -3976], _
		[-3122, -4001], _
		[-3194, -4026], _
		[-3263, -4060], _
		[-3331, -4096], _
		[-3380, -4152], _
		[-3424, -4217], _
		[-3468, -4281], _
		[-3513, -4348], _
		[-3557, -4411], _
		[-3603, -4473], _
		[-3653, -4531], _
		[-3708, -4591], _
		[-3763, -4644], _
		[-3823, -4691], _
		[-3885, -4736], _
		[-3947, -4777], _
		[-3944, -4781], _
		[-4003, -4787], _
		[-4083, -4795], _
		[-4162, -4795], _
		[-4238, -4794], _
		[-4312, -4791], _
		[-4391, -4788], _
		[-4468, -4784], _
		[-4547, -4778], _
		[-4623, -4772], _
		[-4701, -4759], _
		[-4777, -4746], _
		[-4852, -4732], _
		[-4923, -4717], _
		[-5002, -4700], _
		[-5080, -4678], _
		[-5155, -4655], _
		[-5228, -4631], _
		[-5300, -4605], _
		[-5373, -4580], _
		[-5445, -4555], _
		[-5517, -4530], _
		[-5593, -4501], _
		[-5648, -4478], _
		[-5702, -4454], _
		[-5763, -4426], _
		[-5838, -4392], _
		[-5906, -4360], _
		[-5974, -4324], _
		[-6046, -4284], _
		[-6108, -4245], _
		[-6177, -4201], _
		[-6243, -4159], _
		[-6306, -4119], _
		[-6373, -4077], _
		[-6440, -4035], _
		[-6506, -3997], _
		[-6575, -3959], _
		[-6643, -3923], _
		[-6712, -3890], _
		[-6776, -3859], _
		[-6844, -3826], _
		[-6918, -3803], _
		[-6992, -3784], _
		[-7067, -3768], _
		[-7143, -3756], _
		[-7224, -3750], _
		[-7300, -3749], _
		[-7384, -3751], _
		[-7460, -3755], _
		[-7498, -3717], _
		[-7558, -3704], _
		[-7634, -3712], _
		[-7713, -3723], _
		[-7787, -3735], _
		[-7859, -3749], _
		[-7937, -3763], _
		[-8014, -3777], _
		[-8092, -3792], _
		[-8168, -3806], _
		[-8247, -3822], _
		[-8317, -3839], _
		[-8403, -3862], _
		[-8478, -3885], _
		[-8550, -3910], _
		[-8619, -3937], _
		[-8690, -3966], _
		[-8762, -3997], _
		[-8831, -4027], _
		[-8903, -4061], _
		[-8955, -4086], _
		[-9010, -4114], _
		[-9059, -4139], _
		[-9110, -4165], _
		[-9162, -4192], _
		[-9214, -4218], _
		[-9269, -4247], _
		[-9320, -4273], _
		[-9371, -4299], _
		[-9426, -4327], _
		[-9474, -4352], _
		[-9526, -4379], _
		[-9576, -4406], _
		[-9631, -4434], _
		[-9678, -4459], _
		[-9737, -4489], _
		[-9788, -4516], _
		[-9839, -4543], _
		[-9890, -4570], _
		[-9944, -4598], _
		[-9995, -4624], _
		[-10046, -4651], _
		[-10099, -4679], _
		[-10147, -4704], _
		[-10199, -4731], _
		[-10251, -4758], _
		[-10306, -4787], _
		[-10359, -4814], _
		[-10410, -4841], _
		[-10463, -4868], _
		[-10514, -4895], _
		[-10566, -4922], _
		[-10617, -4949], _
		[-10644, -5086], _
		[-10693, -5119], _
		[-10741, -5152], _
		[-10788, -5185], _
		[-10835, -5218], _
		[-10882, -5252], _
		[-10932, -5288], _
		[-10979, -5321], _
		[-11026, -5355], _
		[-11076, -5392], _
		[-11122, -5426], _
		[-11168, -5460], _
		[-11215, -5494], _
		[-11263, -5528], _
		[-11312, -5563], _
		[-11355, -5593], _
		[-11406, -5628], _
		[-11452, -5659], _
		[-11501, -5691], _
		[-11552, -5725], _
		[-11597, -5754], _
		[-11650, -5788], _
		[-11702, -5822], _
		[-11749, -5853], _
		[-11796, -5884], _
		[-11845, -5916], _
		[-11892, -5946], _
		[-11945, -5979], _
		[-11991, -6008], _
		[-12045, -6041], _
		[-12093, -6072], _
		[-12145, -6104], _
		[-12193, -6135], _
		[-12242, -6165], _
		[-12292, -6195], _
		[-12342, -6225], _
		[-12393, -6252], _
		[-12445, -6281], _
		[-12494, -6309], _
		[-12544, -6338], _
		[-12596, -6367], _
		[-12646, -6396], _
		[-12699, -6426], _
		[-12752, -6456], _
		[-12802, -6485], _
		[-12852, -6513], _
		[-12903, -6542], _
		[-12953, -6571], _
		[-13003, -6599], _
		[-13000, -6620] _
	]

	Local $meatShieldsFlagged = False
	For $i = 0 To UBound($route) - 1
		If $varajar_margrid_dead Or $varajar_morgahn_dead Then
			VarajarLogWrite('approach_death', 'wp=' & $i & ' margrid=' & $varajar_margrid_dead & ' morgahn=' & $varajar_morgahn_dead)
			Return False
		EndIf
		MoveTo($route[$i][0], $route[$i][1], 100, VarajarCheckCriticalHeroesAlive)
		VarajarLogWrite('approach', 'wp=' & $i)
		If IsPlayerDead() Then
			VarajarLogWrite('approach_death', 'wp=' & $i & ' player')
			Return False
		EndIf

		; Midway: once we pass the dangerous troop, flag meat shields (4-7) onto it so they tank
		; it instead of it killing Margrid/Morgahn. Koss (3) stays guarding the player.
		If Not $meatShieldsFlagged And ComputeDistance($route[$i][0], $route[$i][1], $VB_MEATSHIELD_TRIGGER_X, $VB_MEATSHIELD_TRIGGER_Y) < 100 Then
			For $h = 4 To 7
				CommandHero($h, $VB_MEATSHIELD_FLAG_X, $VB_MEATSHIELD_FLAG_Y)
			Next
			$meatShieldsFlagged = True
			VarajarLogWrite('flag_meatshields', $VB_MEATSHIELD_FLAG_X & ',' & $VB_MEATSHIELD_FLAG_Y)
			; Wait so the meat shields pull aggro before we continue to the split spot
			RandomSleep(2000)
		EndIf
	Next
	Return True
EndFunc


;~ Split spot choreography : wait, EoE, Enduring Harmony + Make Haste, flag heroes away
Func VarajarBerserkersSplit()
	; Wait for all heroes to catch up
	RandomSleep(3000)

	; Margrid plants Edge of Extinction, then Winnowing (+4 physical damage to foes in spirit range)
	UseHeroSkillEx($VB_MARGRID, $VB_MARGRID_EOE)
	UseHeroSkillEx($VB_MARGRID, $VB_MARGRID_WINNOWING)
	RandomSleep(500)

	; Morgahn casts Vocal Was Sogolon, then Enduring Harmony, then Make Haste, then Bladeturn
	; Refrain, then Incoming on the player. Enduring Harmony MUST land before Make Haste (MH gets
	; +50% duration from EH). Use UseHeroSkillEx (waits for the cast to actually start recharging)
	; so the order is deterministic instead of racy.
	UseHeroSkillEx($VB_MORGAHN, $VB_MORGAHN_VOCAL_WAS_SOGOLON)
	PingSleep(200)
	UseHeroSkillEx($VB_MORGAHN, $VB_MORGAHN_ENDURING_HARMONY, GetMyAgent())
	; Shroud of Distress (8) cast later, alongside Enduring Harmony, so it lasts into the aggro + spike
	UseSkillEx($VB_SHROUD_OF_DISTRESS)
	RandomSleep(1000)
	UseHeroSkillEx($VB_MORGAHN, $VB_MORGAHN_MAKE_HASTE, GetMyAgent())
	; Incoming then Bladeturn Refrain right after Make Haste — the Sin starts running at the same time
	UseHeroSkillEx($VB_MORGAHN, $VB_MORGAHN_INCOMING, GetMyAgent())
	UseHeroSkillEx($VB_MORGAHN, $VB_MORGAHN_BLADETURN_REFRAIN, GetMyAgent())
	RandomSleep(500)

	; Flag Margrid (1), Morgahn (2) and Koss (3) far away (back toward the run start) so they
	; cannot loot. Meat shields 4-7 were already flagged onto the dangerous troop during the approach.
	CommandHero($VB_MARGRID, $VB_FLAG_AWAY_X, $VB_FLAG_AWAY_Y)
	CommandHero($VB_MORGAHN, $VB_FLAG_AWAY_X, $VB_FLAG_AWAY_Y)
	CommandHero(3, $VB_FLAG_AWAY_X, $VB_FLAG_AWAY_Y)
	RandomSleep(500)
EndFunc


;~ Aggro the berserkers, wait for the ball, then spike
Func VarajarBerserkersAggroAndSpike()
	; Run the full aggro path from the split spot to gather all berserkers
	; Re-recorded 2026-09-06 18:32 (path_action_20260906_183254.csv): pull circle with a fuller southwest corner
	Local $aggroPath[164][2] = [ _
		[-13000, -6620], _
		[-13372, -6519], _
		[-13448, -6494], _
		[-13515, -6469], _
		[-13591, -6439], _
		[-13663, -6409], _
		[-13740, -6378], _
		[-13803, -6350], _
		[-13873, -6314], _
		[-13945, -6277], _
		[-14015, -6242], _
		[-14087, -6205], _
		[-14156, -6170], _
		[-14226, -6134], _
		[-14291, -6101], _
		[-14362, -6065], _
		[-14433, -6029], _
		[-14499, -5995], _
		[-14568, -5954], _
		[-14628, -5908], _
		[-14689, -5856], _
		[-14741, -5804], _
		[-14795, -5750], _
		[-14852, -5693], _
		[-14908, -5637], _
		[-14963, -5582], _
		[-15016, -5529], _
		[-15070, -5474], _
		[-15125, -5420], _
		[-15172, -5360], _
		[-15207, -5292], _
		[-15215, -5218], _
		[-15207, -5138], _
		[-15239, -5067], _
		[-15272, -4998], _
		[-15267, -4941], _
		[-15300, -4874], _
		[-15360, -4846], _
		[-15419, -4809], _
		[-15473, -4754], _
		[-15541, -4710], _
		[-15618, -4689], _
		[-15693, -4673], _
		[-15768, -4659], _
		[-15846, -4646], _
		[-15923, -4641], _
		[-15998, -4644], _
		[-16074, -4648], _
		[-16148, -4659], _
		[-16226, -4672], _
		[-16300, -4686], _
		[-16373, -4702], _
		[-16453, -4720], _
		[-16528, -4738], _
		[-16597, -4754], _
		[-16680, -4777], _
		[-16755, -4800], _
		[-16827, -4827], _
		[-16896, -4859], _
		[-16970, -4893], _
		[-17035, -4924], _
		[-17107, -4960], _
		[-17176, -4995], _
		[-17245, -5031], _
		[-17313, -5067], _
		[-17368, -5097], _
		[-17449, -5140], _
		[-17509, -5172], _
		[-17583, -5211], _
		[-17655, -5246], _
		[-17726, -5279], _
		[-17798, -5313], _
		[-17863, -5343], _
		[-17936, -5378], _
		[-18006, -5410], _
		[-18072, -5442], _
		[-18140, -5474], _
		[-18215, -5509], _
		[-18280, -5539], _
		[-18350, -5572], _
		[-18425, -5607], _
		[-18500, -5643], _
		[-18569, -5675], _
		[-18640, -5708], _
		[-18709, -5741], _
		[-18780, -5776], _
		[-18836, -5805], _
		[-18907, -5846], _
		[-18974, -5894], _
		[-19034, -5944], _
		[-19088, -6001], _
		[-19139, -6064], _
		[-19184, -6125], _
		[-19230, -6188], _
		[-19274, -6256], _
		[-19294, -6323], _
		[-19299, -6402], _
		[-19332, -6473], _
		[-19365, -6544], _
		[-19391, -6615], _
		[-19411, -6689], _
		[-19422, -6770], _
		[-19434, -6844], _
		[-19480, -6910], _
		[-19522, -6970], _
		[-19547, -7046], _
		[-19499, -7097], _
		[-19420, -7098], _
		[-19347, -7120], _
		[-19285, -7166], _
		[-19219, -7210], _
		[-19154, -7251], _
		[-19089, -7292], _
		[-19023, -7334], _
		[-18957, -7374], _
		[-18888, -7409], _
		[-18816, -7441], _
		[-18755, -7461], _
		[-18680, -7478], _
		[-18589, -7496], _
		[-18521, -7507], _
		[-18439, -7518], _
		[-18361, -7529], _
		[-18280, -7522], _
		[-18207, -7509], _
		[-18127, -7496], _
		[-18053, -7484], _
		[-17974, -7470], _
		[-17902, -7472], _
		[-17823, -7469], _
		[-17753, -7437], _
		[-17687, -7400], _
		[-17625, -7366], _
		[-17555, -7329], _
		[-17478, -7303], _
		[-17402, -7314], _
		[-17339, -7343], _
		[-17260, -7379], _
		[-17193, -7415], _
		[-17127, -7455], _
		[-17059, -7498], _
		[-16994, -7538], _
		[-16932, -7578], _
		[-16868, -7623], _
		[-16807, -7668], _
		[-16743, -7717], _
		[-16681, -7728], _
		[-16614, -7684], _
		[-16555, -7640], _
		[-16498, -7592], _
		[-16442, -7538], _
		[-16386, -7481], _
		[-16330, -7423], _
		[-16277, -7365], _
		[-16219, -7311], _
		[-16148, -7283], _
		[-16076, -7254], _
		[-16014, -7211], _
		[-15944, -7183], _
		[-15872, -7154], _
		[-15801, -7125], _
		[-15729, -7097], _
		[-15686, -7080], _
		[-15653, -7067] _
	]

	; Run the aggro path - all but the final kill-spot waypoint.
	Local $aggroMoveOptions = CloneMap($default_move_options)
	$aggroMoveOptions['moveVariance'] = 0
	$aggroMoveOptions['moveTimeout'] = 20 * 1000
	; I Am Unstoppable (1) ~7s into the pull so it lasts through the spike at the kill spot
	Local $iauCast = False
	Local $iauTimer = TimerInit()
	For $i = 0 To UBound($aggroPath) - 2
		MoveAvoidingBodyBlock($aggroPath[$i][0], $aggroPath[$i][1], $aggroMoveOptions)
		If IsPlayerDead() Then Return False
		If Not $iauCast And TimerDiff($iauTimer) >= 7000 Then
			UseSkillEx($VB_I_AM_UNSTOPPABLE)
			$iauCast = True
		EndIf
	Next

	; Final approach to the kill spot
	MoveTo($aggroPath[UBound($aggroPath) - 1][0], $aggroPath[UBound($aggroPath) - 1][1])
	If IsPlayerDead() Then Return False
	VarajarLogWrite('spike_stop')

	; Standing still now. Spike order: Protector's Defense (2) -> Soldier's Defense (3)
	; -> Ebon Battle Standard (4) -> 3s ball-up -> Unseen Fury (7, blinds)
	; -> Hundred Blades (5) -> Whirlwind (6)
	UseSkillEx($VB_PROTECTORS_DEFENSE)
	VarajarLogWrite('cast_2', '', $VB_PROTECTORS_DEFENSE)
	UseSkillEx($VB_SOLDIERS_DEFENSE)
	VarajarLogWrite('cast_3', '', $VB_SOLDIERS_DEFENSE)
	UseSkillEx($VB_EBON_BATTLE_STANDARD)
	VarajarLogWrite('cast_4', '', $VB_EBON_BATTLE_STANDARD)
	; Wait 2s so the foes ball up before blinding them all
	RandomSleep(2000)
	; I Am Unstoppable (1) recast — its 30s recharge is up around now
	UseSkillEx($VB_I_AM_UNSTOPPABLE)
	VarajarLogWrite('cast_1', '', $VB_I_AM_UNSTOPPABLE)
	UseSkillEx($VB_UNSEEN_FURY)
	VarajarLogWrite('cast_7', '', $VB_UNSEEN_FURY)
	; 2s ball-up after the blind, then spike immediately
	RandomSleep(2000)
	; Count the balled foes right before the kill so we can report the spike's kill count
	Local $foesBefore = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
	UseSkillEx($VB_HUNDRED_BLADES)
	VarajarLogWrite('cast_5', '', $VB_HUNDRED_BLADES)

	; Auto-attack to top up adrenaline for Whirlwind Attack (6), then fire it
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	If $target <> Null Then
		ChangeTarget($target)
		Local $wwTimer = TimerInit()
		While IsPlayerAlive() And GetSkillbarSkillAdrenaline($VB_WHIRLWIND_ATTACK) < 130 And TimerDiff($wwTimer) < 8000
			Attack($target)
			VarajarLogWrite('pre6_spam', 'adrenaline=' & GetSkillbarSkillAdrenaline($VB_WHIRLWIND_ATTACK))
			RandomSleep(150)
		WEnd
		If IsPlayerAlive() And GetSkillbarSkillAdrenaline($VB_WHIRLWIND_ATTACK) >= 130 Then
			UseSkillEx($VB_WHIRLWIND_ATTACK, $target)
			VarajarLogWrite('cast_6', 'adrenaline=' & GetSkillbarSkillAdrenaline($VB_WHIRLWIND_ATTACK))
		Else
			VarajarLogWrite('cast_6_fail', 'adrenaline=' & GetSkillbarSkillAdrenaline($VB_WHIRLWIND_ATTACK))
		EndIf
	EndIf

	; Let the spike's damage resolve, then count survivors to report how many foes it killed
	RandomSleep(500)
	Local $foesAfter = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
	Local $foesKilled = $foesBefore - $foesAfter
	VarajarLogWrite('spike_kills', 'killed=' & $foesKilled & ';before=' & $foesBefore & ';after=' & $foesAfter)
	Info('Spike killed ' & $foesKilled & ' foes')

	; Loot immediately after the spike - do not wait for stragglers, they can kill us
	PickUpItems(Null, VarajarBerserkersShouldPickItem)

	Return IsPlayerAlive()
EndFunc


;~ Force-pick map pieces (trophy) in addition to the default loot filter
Func VarajarBerserkersShouldPickItem($item)
	Local $itemID = DllStructGetData($item, 'ModelID')
	If IsMapPiece($itemID) Then Return True
	Return DefaultShouldPickItem($item)
EndFunc


;~ Farm loop : one full run
Func VarajarBerserkersFarmLoop()
	VarajarBerserkersGoToZone()
	If GetMapID() <> $ID_VARAJAR_FELLS Then Return $FAIL

	If Not VarajarBerserkersRunToSplit() Then
		If $varajar_margrid_dead Then Info('Margrid died during the run - resigning and restarting')
		If $varajar_morgahn_dead Then Info('Morgahn died during the run - resigning and restarting')
		ResignAndReturnToOutpost($ID_OLAFSTEAD)
		Return $FAIL
	EndIf
	VarajarBerserkersSplit()
	If Not VarajarBerserkersAggroAndSpike() Then Return $FAIL

	Info('Picking up loot')
	RandomSleep(1000)
	PickUpItems(Null, VarajarBerserkersShouldPickItem)

	ResignAndReturnToOutpost($ID_OLAFSTEAD)
	Return $SUCCESS
EndFunc


;~ CSV debug logging (MissingDaughter style) so spike timing and skill-5 delays
;~ are visible per run. Columns include the Whirlwind Attack (6) adrenaline so
;~ we can see exactly when it is ready to fire.
Func VarajarLogInit()
	Local $timestamp = @YEAR & @MON & @MDAY & '_' & @HOUR & @MIN & @SEC
	$varajar_log_file = @ScriptDir & '/logs/varajar_berserkers_debug-' & GetCharacterName() & '-run' & $varajar_log_run_number & '-' & $timestamp & '.csv'
	$varajar_log_handle = FileOpen($varajar_log_file, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	$varajar_log_timer = TimerInit()
	Info('Varajar Berserkers CSV: ' & $varajar_log_file)
	If $varajar_log_handle == -1 Then Return
	FileWriteLine($varajar_log_handle, 'time_ms;run;event;energy;hp;map_id;x;y;skill;skill_ready;casting;adrenaline6;note')
EndFunc


Func VarajarLogClose()
	If $varajar_log_handle == -1 Then Return
	FileClose($varajar_log_handle)
	$varajar_log_handle = -1
EndFunc


Func VarajarLogWrite($eventName, $note = '', $skillSlot = -1)
	If $varajar_log_handle == -1 Then Return
	Local $timeMs = Int(TimerDiff($varajar_log_timer))
	Local $me = GetMyAgent()
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')
	Local $energy = Round(GetEnergy(), 1)
	Local $hp = Round(DllStructGetData($me, 'HealthPercent'), 3)
	Local $mapID = GetMapID()
	Local $skillReady = -1
	If $skillSlot > 0 Then $skillReady = IsRecharged($skillSlot) ? 1 : 0
	Local $adrenaline6 = GetSkillbarSkillAdrenaline($VB_WHIRLWIND_ATTACK)
	Local $safeNote = StringReplace(StringReplace($note, ';', ','), @CRLF, ' ')
	FileWriteLine($varajar_log_handle, $timeMs & ';' & $varajar_log_run_number & ';' & $eventName & ';' & $energy & ';' & $hp & ';' & $mapID & ';' & $x & ';' & $y & ';' & $skillSlot & ';' & $skillReady & ';' & (IsCasting($me) ? 1 : 0) & ';' & $adrenaline6 & ';' & $safeNote)
EndFunc
