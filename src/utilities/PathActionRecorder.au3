#CS ===========================================================================
; Author: GitHub Copilot (prototype for BotsHub)
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
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $PATH_ACTION_RECORDER_INFORMATIONS = 'Utility recorder for farm routing and manual action markers.' & @CRLF _
	& 'Start this utility, then play manually and mark important moments with hotkeys.' & @CRLF _
	& 'Auto markers are also added for key perma and combat events.' & @CRLF _
	& 'Hotkeys:' & @CRLF _
	& '- Ctrl+Alt+R: toggle recording on/off' & @CRLF _
	& '- Ctrl+Alt+1: mark HOLD spot' & @CRLF _
	& '- Ctrl+Alt+2: mark LURE start' & @CRLF _
	& '- Ctrl+Alt+3: mark BALL ready' & @CRLF _
	& '- Ctrl+Alt+4: mark KILL start' & @CRLF _
	& '- Ctrl+Alt+5: mark LOOT start' & @CRLF _
	& '- Ctrl+Alt+6: mark HALCYON button click (adds 0-5s quest/Rion snapshots)' & @CRLF _
	& '- Ctrl+Alt+7: capture current mouse position for HALCYON dialog calibration'
Global Const $PATH_ACTION_RECORDER_DURATION = 30 * 60 * 1000
Global Const $PATH_ACTION_RECORDER_INTERVAL_MS = 200
Global Const $PATH_ACTION_RECORDER_STATUS_INTERVAL_MS = 1500
Global Const $PATH_ACTION_RECORDER_MIN_POS_DELTA = 35
Global Const $PATH_ACTION_RECORDER_DP_TO_SF_WINDOW_MS = 7000
Global Const $PATH_ACTION_RECORDER_HANAKU_MODEL_ID = 4029
Global Const $PATH_ACTION_RECORDER_LOG_FOLDER = @ScriptDir & '\doc\path_action_recordings\'
Global Const $PATH_ACTION_RECORDER_OUTCAST_QUEST_ID = $ID_QUEST_PROTECT_THE_HALCYON
Global Const $PATH_ACTION_RECORDER_OUTCAST_QUEST_OBJECTIVE_BYTES = 128
Global Const $PATH_ACTION_RECORDER_OUTCAST_RION_X = 10631
Global Const $PATH_ACTION_RECORDER_OUTCAST_RION_Y = -3441

Global $path_action_recorder_setup = False
Global $path_action_recorder_active = False
Global $path_action_recorder_file = ''
Global $path_action_recorder_handle = -1
Global $path_action_recorder_start_timer = Null
Global $path_action_recorder_last_pos_x = 0
Global $path_action_recorder_last_pos_y = 0
Global $path_action_recorder_last_pos_time = 0
Global $path_action_recorder_last_skill_id = -1
Global $path_action_recorder_last_target_id = -1
Global $path_action_recorder_last_map_id = -1
Global $path_action_recorder_last_status_time = 0
Global $path_action_recorder_last_dp_cast_time = -1000000
Global $path_action_recorder_kill_rotation_seen = False


;~ Main loop
Func PathActionRecorderFarm()
	If Not $path_action_recorder_setup Then SetupPathActionRecorder()
	If Not $path_action_recorder_active Then StartPathActionRecorder()

	While $runtime_status == 'RUNNING'
		Sleep(250)
	WEnd

	StopPathActionRecorder()
	TeardownPathActionRecorderHotkeys()
	$path_action_recorder_setup = False
	Return $runtime_status <> 'RUNNING' ? $PAUSE : $SUCCESS
EndFunc


Func SetupPathActionRecorder()
	Info('Setting up path/action recorder utility')
	RegisterPathActionRecorderHotkeys()
	Info('Recorder hotkeys active. Use Ctrl+Alt+R to start/stop a new recording file.')
	$path_action_recorder_setup = True
EndFunc


Func RegisterPathActionRecorderHotkeys()
	HotKeySet('^!r', 'TogglePathActionRecorderHotkey')
	HotKeySet('^!1', 'MarkHoldHotkey')
	HotKeySet('^!2', 'MarkLureHotkey')
	HotKeySet('^!3', 'MarkBallHotkey')
	HotKeySet('^!4', 'MarkKillHotkey')
	HotKeySet('^!5', 'MarkLootHotkey')
	HotKeySet('^!6', 'MarkHalcyonClickHotkey')
	HotKeySet('^!7', 'MarkHalcyonDialogCalibrationHotkey')
EndFunc


Func TeardownPathActionRecorderHotkeys()
	HotKeySet('^!r')
	HotKeySet('^!1')
	HotKeySet('^!2')
	HotKeySet('^!3')
	HotKeySet('^!4')
	HotKeySet('^!5')
	HotKeySet('^!6')
	HotKeySet('^!7')
EndFunc


Func TogglePathActionRecorderHotkey()
	If $path_action_recorder_active Then
		StopPathActionRecorder()
	Else
		StartPathActionRecorder()
	EndIf
EndFunc


Func StartPathActionRecorder()
	If $path_action_recorder_active Then Return

	Local $timestamp = @YEAR & StringFormat('%02d', @MON) & StringFormat('%02d', @MDAY) & '_' _
		& StringFormat('%02d', @HOUR) & StringFormat('%02d', @MIN) & StringFormat('%02d', @SEC)
	$path_action_recorder_file = $PATH_ACTION_RECORDER_LOG_FOLDER & 'path_action_' & $timestamp & '.csv'
	$path_action_recorder_handle = FileOpen($path_action_recorder_file, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	If $path_action_recorder_handle == -1 Then
		Warn('Could not open recorder file: ' & $path_action_recorder_file)
		Return
	EndIf

	$path_action_recorder_start_timer = TimerInit()
	$path_action_recorder_last_pos_time = 0
	$path_action_recorder_last_skill_id = -1
	$path_action_recorder_last_target_id = -1
	$path_action_recorder_last_map_id = -1
	$path_action_recorder_last_status_time = 0
	$path_action_recorder_last_dp_cast_time = -1000000
	$path_action_recorder_kill_rotation_seen = False

	Local $me = GetMyAgent()
	If $me <> Null Then
		$path_action_recorder_last_pos_x = Int(DllStructGetData($me, 'X'))
		$path_action_recorder_last_pos_y = Int(DllStructGetData($me, 'Y'))
	Else
		$path_action_recorder_last_pos_x = 0
		$path_action_recorder_last_pos_y = 0
	EndIf

	$path_action_recorder_active = True
	FileWriteLine($path_action_recorder_handle, '# Path Action Recorder v2')
	FileWriteLine($path_action_recorder_handle, '# map_id=' & GetMapID() & ';map_type=' & GetMapType())
	FileWriteLine($path_action_recorder_handle, '# columns: time_ms;event;x;y;hp;energy;map_id;target_id;target_model_id;casting_skill_id;note')
	FileWriteLine($path_action_recorder_handle, '# HERO_POS uses target_id=hero_agent_id, target_model_id=hero_model_id, note=hero_index=<n>')
	AdlibRegister('PathActionRecorderTick', $PATH_ACTION_RECORDER_INTERVAL_MS)
	Info('Recorder started: ' & $path_action_recorder_file)
EndFunc


Func StopPathActionRecorder()
	If Not $path_action_recorder_active Then Return
	AdlibUnRegister('PathActionRecorderTick')

	PathActionRecorderMark('RECORDING_STOP')
	If $path_action_recorder_handle <> -1 Then FileClose($path_action_recorder_handle)

	$path_action_recorder_handle = -1
	$path_action_recorder_active = False
	$path_action_recorder_start_timer = Null
	Info('Recorder stopped')
EndFunc


Func PathActionRecorderTick()
	If Not $path_action_recorder_active Or $path_action_recorder_handle == -1 Then Return

	Local $me = GetMyAgent()
	If $me == Null Then Return

	Local $x = Int(DllStructGetData($me, 'X'))
	Local $y = Int(DllStructGetData($me, 'Y'))
	Local $hp = Round(DllStructGetData($me, 'HealthPercent') * 100, 1)
	Local $energy = Round(GetEnergy($me), 1)
	Local $mapID = GetMapID()
	Local $timeMs = Round(TimerDiff($path_action_recorder_start_timer), 0)
	Local $castSkillID = DllStructGetData($me, 'Skill')

	If $mapID <> $path_action_recorder_last_map_id Then
		PathActionRecorderWriteEvent($timeMs, 'MAP', $x, $y, $hp, $energy, $mapID, 0, 0, $castSkillID, 'Map changed / refreshed')
		$path_action_recorder_last_map_id = $mapID
	EndIf

	If Abs($x - $path_action_recorder_last_pos_x) >= $PATH_ACTION_RECORDER_MIN_POS_DELTA _
		Or Abs($y - $path_action_recorder_last_pos_y) >= $PATH_ACTION_RECORDER_MIN_POS_DELTA _
		Or ($timeMs - $path_action_recorder_last_pos_time) >= 1000 Then
		PathActionRecorderWriteEvent($timeMs, 'POS', $x, $y, $hp, $energy, $mapID, 0, 0, $castSkillID, '')
		$path_action_recorder_last_pos_x = $x
		$path_action_recorder_last_pos_y = $y
		$path_action_recorder_last_pos_time = $timeMs
	EndIf

	If $castSkillID <> $path_action_recorder_last_skill_id Then
		If $castSkillID <> 0 Then
			Local $castSlot = GetSkillSlotForSkillID($castSkillID)
			Local $castNote = $castSlot == 0 ? '' : 'slot=' & $castSlot
			PathActionRecorderWriteEvent($timeMs, 'SKILL_CAST', $x, $y, $hp, $energy, $mapID, 0, 0, $castSkillID, $castNote)
			PathActionRecorderAutoMarkSkill($timeMs, $x, $y, $hp, $energy, $mapID, $castSkillID)
		EndIf
		$path_action_recorder_last_skill_id = $castSkillID
	EndIf

	Local $target = GetCurrentTarget()
	Local $targetID = 0
	Local $targetModelID = 0
	If $target <> Null Then
		$targetID = DllStructGetData($target, 'ID')
		$targetModelID = DllStructGetData($target, 'ModelID')
	EndIf
	If $targetID <> $path_action_recorder_last_target_id Then
		PathActionRecorderWriteEvent($timeMs, 'TARGET_CHANGE', $x, $y, $hp, $energy, $mapID, $targetID, $targetModelID, $castSkillID, '')
		If $path_action_recorder_last_target_id == 0 And $targetID <> 0 Then
			PathActionRecorderWriteEvent($timeMs, 'MARK', $x, $y, $hp, $energy, $mapID, $targetID, $targetModelID, $castSkillID, 'AUTO_TARGET_ACQUIRED')
		EndIf
		If $targetID == 0 And $path_action_recorder_last_target_id <> 0 Then
			PathActionRecorderWriteEvent($timeMs, 'MARK', $x, $y, $hp, $energy, $mapID, 0, 0, $castSkillID, 'AUTO_TARGET_LOST')
		EndIf
		If $PATH_ACTION_RECORDER_HANAKU_MODEL_ID <> 0 And $targetModelID == $PATH_ACTION_RECORDER_HANAKU_MODEL_ID Then
			PathActionRecorderWriteEvent($timeMs, 'MARK', $x, $y, $hp, $energy, $mapID, $targetID, $targetModelID, $castSkillID, 'AUTO_HANAKU_TARGET_LOCK')
		EndIf
		$path_action_recorder_last_target_id = $targetID
	EndIf

	If ($timeMs - $path_action_recorder_last_status_time) >= $PATH_ACTION_RECORDER_STATUS_INTERVAL_MS Then
		Local $sfMs = PathRecorderGetBestEffectTimeRemaining($ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP)
		Local $sodMs = PathRecorderGetBestEffectTimeRemaining($ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP)
		Local $caMs = GetEffectTimeRemaining($ID_CRITICAL_AGILITY)
		Local $statusNote = 'sf_ms=' & Round($sfMs, 0) & ';sod_ms=' & Round($sodMs, 0) & ';ca_ms=' & Round($caMs, 0)
		PathActionRecorderWriteEvent($timeMs, 'STATUS', $x, $y, $hp, $energy, $mapID, $targetID, $targetModelID, $castSkillID, $statusNote)
		PathActionRecorderWriteHeroPositions($timeMs, $mapID)
		$path_action_recorder_last_status_time = $timeMs
	EndIf
EndFunc


Func PathActionRecorderWriteHeroPositions($timeMs, $mapID)
	Local $heroCount = GetHeroCount()
	For $heroIndex = 1 To $heroCount
		Local $heroAgentID = GetHeroID($heroIndex)
		If $heroAgentID == 0 Then ContinueLoop

		Local $heroAgent = GetAgentByID($heroAgentID)
		If $heroAgent == Null Then ContinueLoop

		Local $hx = Int(DllStructGetData($heroAgent, 'X'))
		Local $hy = Int(DllStructGetData($heroAgent, 'Y'))
		Local $hhp = Round(DllStructGetData($heroAgent, 'HealthPercent') * 100, 1)
		Local $hEnergy = Round(GetEnergy($heroAgent), 1)
		Local $hModelID = DllStructGetData($heroAgent, 'ModelID')
		PathActionRecorderWriteEvent($timeMs, 'HERO_POS', $hx, $hy, $hhp, $hEnergy, $mapID, $heroAgentID, $hModelID, 0, 'hero_index=' & $heroIndex)
	Next
EndFunc


Func PathActionRecorderMark($note)
	If Not $path_action_recorder_active Or $path_action_recorder_handle == -1 Then Return

	Local $timeMs = Round(TimerDiff($path_action_recorder_start_timer), 0)
	Local $me = GetMyAgent()
	Local $x = 0, $y = 0, $hp = 0, $energy = 0, $castSkillID = 0
	Local $mapID = GetMapID()
	Local $targetID = 0, $targetModelID = 0

	If $me <> Null Then
		$x = Int(DllStructGetData($me, 'X'))
		$y = Int(DllStructGetData($me, 'Y'))
		$hp = Round(DllStructGetData($me, 'HealthPercent') * 100, 1)
		$energy = Round(GetEnergy($me), 1)
		$castSkillID = DllStructGetData($me, 'Skill')
	EndIf

	Local $target = GetCurrentTarget()
	If $target <> Null Then
		$targetID = DllStructGetData($target, 'ID')
		$targetModelID = DllStructGetData($target, 'ModelID')
	EndIf

	PathActionRecorderWriteEvent($timeMs, 'MARK', $x, $y, $hp, $energy, $mapID, $targetID, $targetModelID, $castSkillID, $note)
	Info('Recorder mark: ' & $note)
EndFunc


Func PathActionRecorderWriteOutcastQuestSnapshot($tag)
	If Not $path_action_recorder_active Or $path_action_recorder_handle == -1 Then Return

	Local $timeMs = Round(TimerDiff($path_action_recorder_start_timer), 0)
	Local $me = GetMyAgent()
	Local $x = 0, $y = 0, $hp = 0, $energy = 0, $castSkillID = 0
	Local $mapID = GetMapID()
	Local $targetID = 0, $targetModelID = 0
	If $me <> Null Then
		$x = Int(DllStructGetData($me, 'X'))
		$y = Int(DllStructGetData($me, 'Y'))
		$hp = Round(DllStructGetData($me, 'HealthPercent') * 100, 1)
		$energy = Round(GetEnergy($me), 1)
		$castSkillID = DllStructGetData($me, 'Skill')
	EndIf

	Local $target = GetCurrentTarget()
	If $target <> Null Then
		$targetID = DllStructGetData($target, 'ID')
		$targetModelID = DllStructGetData($target, 'ModelID')
	EndIf

	Local $questState = 'NOT_FOUND'
	Local $objectiveHex = 'NA'
	Local $objectiveLen = 0
	Local $quest = GetQuestByID($PATH_ACTION_RECORDER_OUTCAST_QUEST_ID)
	If $quest <> Null Then
		$questState = DllStructGetData($quest, 'LogState')
		Local $obj = GetQuestEncryptedObjectives($PATH_ACTION_RECORDER_OUTCAST_QUEST_ID, $PATH_ACTION_RECORDER_OUTCAST_QUEST_OBJECTIVE_BYTES)
		If $obj <> Null Then
			$objectiveHex = $obj
			$objectiveLen = StringLen($obj)
		EndIf
	EndIf

	Local $rionNpc = GetNearestNPCToCoords($PATH_ACTION_RECORDER_OUTCAST_RION_X, $PATH_ACTION_RECORDER_OUTCAST_RION_Y)
	Local $rionNpcID = 0
	Local $rionNpcModel = 0
	Local $rionNpcDist = -1
	Local $playerToRionNpcDist = -1
	If $rionNpc <> Null Then
		$rionNpcID = DllStructGetData($rionNpc, 'ID')
		$rionNpcModel = DllStructGetData($rionNpc, 'ModelID')
		$rionNpcDist = Int(GetDistanceToPoint($rionNpc, $PATH_ACTION_RECORDER_OUTCAST_RION_X, $PATH_ACTION_RECORDER_OUTCAST_RION_Y))
		If $me <> Null Then $playerToRionNpcDist = Int(GetDistance($me, $rionNpc))
	EndIf

	Local $threat = GetNearestEnemyToCoords($PATH_ACTION_RECORDER_OUTCAST_RION_X, $PATH_ACTION_RECORDER_OUTCAST_RION_Y)
	Local $threatModel = 0
	Local $threatDist = -1
	If $threat <> Null Then
		$threatModel = DllStructGetData($threat, 'ModelID')
		$threatDist = Int(GetDistanceToPoint($threat, $PATH_ACTION_RECORDER_OUTCAST_RION_X, $PATH_ACTION_RECORDER_OUTCAST_RION_Y))
	EndIf

	Local $foesNearRion = CountFoesInRangeOfCoords($PATH_ACTION_RECORDER_OUTCAST_RION_X, $PATH_ACTION_RECORDER_OUTCAST_RION_Y, 900)
	Local $foesNearPlayer = ($me == Null) ? -1 : CountFoesInRangeOfAgent($me, 1200)
	Local $isMoving = ($me == Null) ? -1 : (GetIsMoving($me) ? 1 : 0)
	Local $isCasting = ($me == Null) ? -1 : (GetIsCasting($me) ? 1 : 0)
	Local $isAttacking = ($me == Null) ? -1 : (GetIsAttacking($me) ? 1 : 0)

	Local $note = 'tag=' & $tag _
		& ';quest_state=' & $questState _
		& ';objective=' & $objectiveHex _
		& ';objective_len=' & $objectiveLen _
		& ';rion_npc_id=' & $rionNpcID _
		& ';rion_npc_model=' & $rionNpcModel _
		& ';rion_npc_dist=' & $rionNpcDist _
		& ';player_rion_dist=' & $playerToRionNpcDist _
		& ';threat_model=' & $threatModel _
		& ';threat_dist=' & $threatDist _
		& ';foes_rion_900=' & $foesNearRion _
		& ';foes_player_1200=' & $foesNearPlayer _
		& ';me_moving=' & $isMoving _
		& ';me_casting=' & $isCasting _
		& ';me_attacking=' & $isAttacking

	PathActionRecorderWriteEvent($timeMs, 'QUEST_SNAPSHOT', $x, $y, $hp, $energy, $mapID, $targetID, $targetModelID, $castSkillID, $note)
EndFunc


Func MarkHalcyonClickHotkey()
	If Not $path_action_recorder_active Then Return
	PathActionRecorderMark('HALCYON_CLICK_MANUAL')
	PathActionRecorderWriteOutcastQuestSnapshot('CLICK_T0')
	Sleep(350)
	PathActionRecorderWriteOutcastQuestSnapshot('CLICK_T350')
	Sleep(650)
	PathActionRecorderWriteOutcastQuestSnapshot('CLICK_T1000')
	Sleep(1500)
	PathActionRecorderWriteOutcastQuestSnapshot('CLICK_T2500')
	Sleep(2500)
	PathActionRecorderWriteOutcastQuestSnapshot('CLICK_T5000')
EndFunc


Func MarkHalcyonDialogCalibrationHotkey()
	If Not $path_action_recorder_active Then Return

	Local $mouse = MouseGetPos()
	If @error Or UBound($mouse) < 2 Then
		PathActionRecorderMark('HALCYON_CALIBRATION_MOUSE_ERROR')
		Return
	EndIf

	Local $mx = $mouse[0]
	Local $my = $mouse[1]
	Local $hwnd = WinGetHandle('[CLASS:ArenaNet_Dx_Window_Class]')
	If @error Or $hwnd == '' Then $hwnd = WinGetHandle('[TITLE:Guild Wars]')
	If @error Or $hwnd == '' Then
		PathActionRecorderMark('HALCYON_CALIBRATION_NO_GW_WINDOW;x=' & $mx & ';y=' & $my)
		Return
	EndIf

	Local $pos = WinGetPos($hwnd)
	If @error Or UBound($pos) < 4 Then
		PathActionRecorderMark('HALCYON_CALIBRATION_NO_WINPOS;x=' & $mx & ';y=' & $my)
		Return
	EndIf

	Local $left = $pos[0]
	Local $top = $pos[1]
	Local $width = $pos[2]
	Local $height = $pos[3]
	If $width <= 0 Or $height <= 0 Then
		PathActionRecorderMark('HALCYON_CALIBRATION_BAD_WINPOS;x=' & $mx & ';y=' & $my)
		Return
	EndIf

	Local $rx = ($mx - $left) / $width
	Local $ry = ($my - $top) / $height
	PathActionRecorderMark('HALCYON_CALIBRATION_POS;x=' & $mx & ';y=' & $my & ';rx=' & Round($rx, 4) & ';ry=' & Round($ry, 4) & ';w=' & $width & ';h=' & $height)
EndFunc


Func PathActionRecorderWriteEvent($timeMs, $eventName, $x, $y, $hp, $energy, $mapID, $targetID, $targetModelID, $castSkillID, $note)
	If $path_action_recorder_handle == -1 Then Return
	Local $safeNote = StringReplace($note, ';', ',')
	FileWriteLine($path_action_recorder_handle, $timeMs & ';' & $eventName & ';' & $x & ';' & $y & ';' & $hp & ';' & $energy & ';' & $mapID & ';' & $targetID & ';' & $targetModelID & ';' & $castSkillID & ';' & $safeNote)
EndFunc


Func PathActionRecorderAutoMarkSkill($timeMs, $x, $y, $hp, $energy, $mapID, $castSkillID)
	Switch $castSkillID
		Case $ID_DEADLY_PARADOX
			$path_action_recorder_last_dp_cast_time = $timeMs
			PathActionRecorderWriteEvent($timeMs, 'MARK', $x, $y, $hp, $energy, $mapID, 0, 0, $castSkillID, 'AUTO_DP_CAST')

		Case $ID_SHADOW_FORM, $ID_SHADOW_FORM_PVP
			PathActionRecorderWriteEvent($timeMs, 'MARK', $x, $y, $hp, $energy, $mapID, 0, 0, $castSkillID, 'AUTO_SF_CAST')
			If ($timeMs - $path_action_recorder_last_dp_cast_time) <= $PATH_ACTION_RECORDER_DP_TO_SF_WINDOW_MS Then
				PathActionRecorderWriteEvent($timeMs, 'MARK', $x, $y, $hp, $energy, $mapID, 0, 0, $castSkillID, 'AUTO_PERMA_CHAIN_DP_SF')
			EndIf

		Case $ID_SHROUD_OF_DISTRESS, $ID_SHROUD_OF_DISTRESS_PVP
			PathActionRecorderWriteEvent($timeMs, 'MARK', $x, $y, $hp, $energy, $mapID, 0, 0, $castSkillID, 'AUTO_SOD_CAST')

		Case $ID_CRITICAL_AGILITY
			PathActionRecorderWriteEvent($timeMs, 'MARK', $x, $y, $hp, $energy, $mapID, 0, 0, $castSkillID, 'AUTO_CRITICAL_AGILITY_CAST')

		Case $ID_GRENTHS_AURA
			PathActionRecorderWriteEvent($timeMs, 'MARK', $x, $y, $hp, $energy, $mapID, 0, 0, $castSkillID, 'AUTO_GRENTHS_AURA_CAST')

		Case $ID_CRIPPLING_VICTORY, $ID_REAP_IMPURITIES
			If Not $path_action_recorder_kill_rotation_seen Then
				$path_action_recorder_kill_rotation_seen = True
				PathActionRecorderWriteEvent($timeMs, 'MARK', $x, $y, $hp, $energy, $mapID, 0, 0, $castSkillID, 'AUTO_KILL_ROTATION_START')
			EndIf
	EndSwitch
EndFunc


Func GetSkillSlotForSkillID($skillID)
	If $skillID == 0 Then Return 0
	For $slot = 1 To 8
		If GetSkillbarSkillID($slot) == $skillID Then Return $slot
	Next
	Return 0
EndFunc


Func PathRecorderGetBestEffectTimeRemaining($skillID1, $skillID2 = 0)
	Local $v1 = GetEffectTimeRemaining($skillID1)
	If $skillID2 == 0 Then Return $v1
	Local $v2 = GetEffectTimeRemaining($skillID2)
	Return $v2 > $v1 ? $v2 : $v1
EndFunc


Func MarkHoldHotkey()
	PathActionRecorderMark('HOLD_SPOT')
EndFunc


Func MarkLureHotkey()
	PathActionRecorderMark('LURE_START')
EndFunc


Func MarkBallHotkey()
	PathActionRecorderMark('BALL_READY')
EndFunc


Func MarkKillHotkey()
	PathActionRecorderMark('KILL_START')
EndFunc


Func MarkLootHotkey()
	PathActionRecorderMark('LOOT_START')
EndFunc
