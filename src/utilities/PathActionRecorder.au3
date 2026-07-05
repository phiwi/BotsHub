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
	& '- Ctrl+Alt+7: capture current mouse position for HALCYON dialog calibration' & @CRLF _
	& '- Ctrl+Alt+8: NPC snap — logs all NPCs, target, merchant items, trader state' & @CRLF _
	& '- Ctrl+Alt+9: Dialog snap — logs trader quote state, gold, inventory' & @CRLF _
	& '- Ctrl+Alt+0: FULL memory dump — all state for conset reverse-engineering' & @CRLF _
	& '- Ctrl+Alt+P: toggle PacketSend logging ON/OFF (captures outgoing network packets)'
Global Const $PATH_ACTION_RECORDER_DURATION = 30 * 60 * 1000
Global Const $PATH_ACTION_RECORDER_INTERVAL_MS = 200
Global Const $PATH_ACTION_RECORDER_STATUS_INTERVAL_MS = 1500
Global Const $PATH_ACTION_RECORDER_MIN_POS_DELTA = 35
Global Const $PATH_ACTION_RECORDER_STATIC_SCAN_INTERVAL_MS = 1200
Global Const $PATH_ACTION_RECORDER_STATIC_SCAN_RANGE = $RANGE_COMPASS
Global Const $PATH_ACTION_RECORDER_STATIC_SCAN_MAX_ROWS = 8
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
Global $path_action_recorder_last_static_scan_time = 0
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
	HotKeySet('^!8', 'MarkNPCSnapHotkey')
	HotKeySet('^!9', 'MarkDialogSnapHotkey')
	HotKeySet('^!0', 'MarkMemoryDumpHotkey')
	HotKeySet('^!p', 'TogglePacketLogHotkey')
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
	HotKeySet('^!8')
	HotKeySet('^!9')
	HotKeySet('^!0')
	HotKeySet('^!p')
	PacketLogTeardown()
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
	$path_action_recorder_last_static_scan_time = 0
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
	FileWriteLine($path_action_recorder_handle, '# STATIC_NEAR uses target_id=static_agent_id, target_model_id=gadget_id, note=model=<model_id>;dist=<n>;known_chest=<0/1>')
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

	If ($timeMs - $path_action_recorder_last_static_scan_time) >= $PATH_ACTION_RECORDER_STATIC_SCAN_INTERVAL_MS Then
		PathActionRecorderWriteStaticObjects($timeMs, $x, $y, $hp, $energy, $mapID, $castSkillID)
		$path_action_recorder_last_static_scan_time = $timeMs
	EndIf
EndFunc


Func PathActionRecorderWriteStaticObjects($timeMs, $x, $y, $hp, $energy, $mapID, $castSkillID)
	Local $me = GetMyAgent()
	If $me == Null Then Return

	Local $agents = GetAgentArray($ID_AGENT_TYPE_STATIC)
	If Not IsArray($agents) Or UBound($agents) <= 0 Then Return

	Local $rows = 0
	For $agent In $agents
		Local $dist = Int(GetDistance($me, $agent))
		If $dist > $PATH_ACTION_RECORDER_STATIC_SCAN_RANGE Then ContinueLoop

		Local $agentID = DllStructGetData($agent, 'ID')
		Local $gadgetID = DllStructGetData($agent, 'GadgetID')
		Local $modelID = DllStructGetData($agent, 'ModelID')
		Local $knownChest = ($MAP_CHESTS_IDS[$gadgetID] <> Null) ? 1 : 0
		Local $note = 'model=' & $modelID & ';dist=' & $dist & ';known_chest=' & $knownChest
		PathActionRecorderWriteEvent($timeMs, 'STATIC_NEAR', $x, $y, $hp, $energy, $mapID, $agentID, $gadgetID, $castSkillID, $note)

		$rows += 1
		If $rows >= $PATH_ACTION_RECORDER_STATIC_SCAN_MAX_ROWS Then ExitLoop
	Next
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


;~ Ctrl+Alt+8: Snapshot aller NPCs in Range + Trader-Quote-State
Func MarkNPCSnapHotkey()
	Local $me = GetMyAgent()
	If $me == Null Then Return

	Local $myX = Int(DllStructGetData($me, 'X'))
	Local $myY = Int(DllStructGetData($me, 'Y'))
	Local $mapID = GetMapID()

	Info('=== NPC SNAP === map=' & $mapID & ' pos=(' & $myX & ',' & $myY & ')')

	; Aktuelles Target
	Local $target = GetCurrentTarget()
	If $target <> Null Then
		Local $tID = DllStructGetData($target, 'ID')
		Local $tModel = DllStructGetData($target, 'ModelID')
		Local $tType = DllStructGetData($target, 'Type')
		Info('  TARGET: AgentID=' & $tID & ' ModelID=' & $tModel & ' Type=' & $tType)
	Else
		Info('  TARGET: none')
	EndIf

	; Alle NPCs in Compass-Range
	Local $npcs = GetAgentArray($ID_AGENT_TYPE_NPC)
	Local $count = 0
	For $npc In $npcs
		Local $dist = Int(GetDistance($me, $npc))
		If $dist > $RANGE_COMPASS Then ContinueLoop
		Local $nID = DllStructGetData($npc, 'ID')
		Local $nModel = DllStructGetData($npc, 'ModelID')
		Local $nAlleg = DllStructGetData($npc, 'Allegiance')
		Info('  NPC[' & $count & ']: AgentID=' & $nID & ' ModelID=' & $nModel & ' Dist=' & $dist & ' Alleg=' & $nAlleg)
		$count += 1
	Next
	Info('  Total NPCs in compass: ' & $count)

	; Trader/Merchant state
	Local $processHandle = GetProcessHandle()
	Local $quoteID = MemoryRead($processHandle, $trader_quote_ID)
	Local $costID = MemoryRead($processHandle, $trader_cost_ID)
	Local $costVal = MemoryRead($processHandle, $trader_cost_value)
	Info('  TRADER: QuoteID=' & $quoteID & ' CostID=' & $costID & ' CostValue=' & $costVal)

	; Merchant items
	Local $merchBase = GetMerchantItemsBase()
	Local $merchSize = GetMerchantItemsSize()
	Info('  MERCHANT: Base=' & $merchBase & ' Size=' & $merchSize)
	For $i = 0 To _Min(19, $merchSize - 1)
		Local $itemID = MemoryRead($processHandle, $merchBase + 4 * $i)
		If $itemID Then
			Local $offsets[] = [0, 0x18, 0x40, 0xB8, 4 * $itemID]
			Local $itemPtr = MemoryReadPtr($processHandle, $base_address_ptr, $offsets)
			If $itemPtr[1] Then
				Local $itemModel = MemoryRead($processHandle, $itemPtr[1] + 0x2C)
				Local $itemVal = MemoryRead($processHandle, $itemPtr[1] + 0x24, 'short')
				Info('  MERCH[' & $i & ']: ItemID=' & $itemID & ' ModelID=' & $itemModel & ' Value=' & $itemVal)
			Else
				Info('  MERCH[' & $i & ']: ItemID=' & $itemID & ' Ptr=NULL')
			EndIf
		EndIf
	Next
	Info('=== NPC SNAP END ===')
EndFunc


;~ Ctrl+Alt+9: Trader-Quote-State Snapshot (nach Dialog-Klick drücken)
Func MarkDialogSnapHotkey()
	Local $processHandle = GetProcessHandle()
	Local $quoteID = MemoryRead($processHandle, $trader_quote_ID)
	Local $costID = MemoryRead($processHandle, $trader_cost_ID)
	Local $costVal = MemoryRead($processHandle, $trader_cost_value)

	Info('=== DIALOG SNAP ===')
	Info('  TraderQuoteID=' & $quoteID)
	Info('  TraderCostID=' & $costID)
	Info('  TraderCostValue=' & $costVal)
	Info('  MapID=' & GetMapID() & ' MapType=' & GetMapType())

	; Auch Gold checken
	Info('  GoldCharacter=' & GetGoldCharacter() & ' GoldStorage=' & GetGoldStorage())

	; Inventar-Count der 4 Materialien
	Info('  Inv Iron=' & _PathRecorderCountMaterial($ID_IRON_INGOT) & ' Dust=' & _PathRecorderCountMaterial($ID_PILE_OF_GLITTERING_DUST) & ' Feathers=' & _PathRecorderCountMaterial($ID_FEATHER) & ' Bones=' & _PathRecorderCountMaterial($ID_BONE))

	; Conset-Items im Inventar
	Info('  Inv Grail=' & _PathRecorderCountMaterial($ID_GRAIL_OF_MIGHT) & ' Essence=' & _PathRecorderCountMaterial($ID_ESSENCE_OF_CELERITY) & ' Armor=' & _PathRecorderCountMaterial($ID_ARMOR_OF_SALVATION))
	Info('=== DIALOG SNAP END ===')
EndFunc


;~ Hilfsfunktion: Material im Inventar zählen
Func _PathRecorderCountMaterial($modelID)
	Local $total = 0
	For $bagIndex = 1 To 5
		Local $bag = GetBag($bagIndex)
		If $bag == Null Then ContinueLoop
		For $slot = 1 To DllStructGetData($bag, 'Slots')
			Local $item = GetItemBySlot($bagIndex, $slot)
			If DllStructGetData($item, 'ModelID') == $modelID Then
				$total += DllStructGetData($item, 'Quantity')
			EndIf
		Next
	Next
	Return $total
EndFunc


;~ Ctrl+Alt+0: Kompletter Memory-Dump für Conset-Reverse-Engineering.
;~ Drücke VOR der NPC-Interaktion, NACH Dialog-Öffnen, und NACH dem Kauf.
Func MarkMemoryDumpHotkey()
	Local $processHandle = GetProcessHandle()
	Local $me = GetMyAgent()
	Local $myX = 0, $myY = 0
	If $me <> Null Then
		$myX = Int(DllStructGetData($me, 'X'))
		$myY = Int(DllStructGetData($me, 'Y'))
	EndIf

	Info('')
	Info('╔══════════════════════════════════════════════════════════╗')
	Info('║         FULL MEMORY DUMP — Conset Reverse-Engineering     ║')
	Info('╠══════════════════════════════════════════════════════════╣')
	Info('║ Map=' & GetMapID() & ' Type=' & GetMapType() & ' Pos=(' & $myX & ',' & $myY & ')')
	Info('║ Gold: Char=' & GetGoldCharacter() & ' Storage=' & GetGoldStorage())
	Info('╠══════════════════════════════════════════════════════════╣')

	; ── Target ──
	Local $target = GetCurrentTarget()
	If $target <> Null Then
		Info('║ TARGET: AgentID=' & DllStructGetData($target, 'ID') & ' ModelID=' & DllStructGetData($target, 'ModelID') & ' Type=' & DllStructGetData($target, 'Type'))
	Else
		Info('║ TARGET: none')
	EndIf

	; ── Nearest NPC ──
	If $me <> Null Then
		Local $nearestNpc = GetNearestNPCToCoords($myX, $myY)
		If $nearestNpc <> Null Then
			Info('║ NEAREST NPC: AgentID=' & DllStructGetData($nearestNpc, 'ID') & ' ModelID=' & DllStructGetData($nearestNpc, 'ModelID') & ' Dist=' & Int(GetDistance($me, $nearestNpc)))
		EndIf
	EndIf

	; ── Trader State ──
	Local $quoteID = MemoryRead($processHandle, $trader_quote_ID)
	Local $costID  = MemoryRead($processHandle, $trader_cost_ID)
	Local $costVal = MemoryRead($processHandle, $trader_cost_value)
	Info('╠══════════════════════════════════════════════════════════╣')
	Info('║ TRADER STATE:')
	Info('║   TraderQuoteID  = ' & $quoteID)
	Info('║   TraderCostID   = ' & $costID)
	Info('║   TraderCostValue= ' & $costVal)

	; ── Raw bytes um Trader-Quote-Speicher ──
	Local $rawQuote = MemoryRead($processHandle, $trader_quote_ID, 'byte[16]')
	Local $rawCost  = MemoryRead($processHandle, $trader_cost_ID, 'byte[16]')
	Info('║   Raw QuoteID[0..15] = ' & $rawQuote)
	Info('║   Raw CostID[0..15]  = ' & $rawCost)

	; ── Merchant Items ──
	Local $merchBase = GetMerchantItemsBase()
	Local $merchSize = GetMerchantItemsSize()
	Info('╠══════════════════════════════════════════════════════════╣')
	Info('║ MERCHANT: Base=0x' & Hex($merchBase) & ' Size=' & $merchSize)
	Local $foundCount = 0
	For $i = 0 To $merchSize - 1
		Local $merchItemID = MemoryRead($processHandle, $merchBase + 4 * $i)
		If $merchItemID Then
			Local $offsets[] = [0, 0x18, 0x40, 0xB8, 4 * $merchItemID]
			Local $itemPtr = MemoryReadPtr($processHandle, $base_address_ptr, $offsets)
			If $itemPtr[1] Then
				Local $mID = MemoryRead($processHandle, $itemPtr[1] + 0x2C)
				Local $val = MemoryRead($processHandle, $itemPtr[1] + 0x24, 'short')
				Local $rawBytes = MemoryRead($processHandle, $itemPtr[1], 'byte[64]')
				Info('║   [' & $i & '] ItemID=' & $merchItemID & ' ModelID=' & $mID & ' Value=' & $val)
				Info('║       Raw[0..63]=' & $rawBytes)
				$foundCount += 1
			Else
				Info('║   [' & $i & '] ItemID=' & $merchItemID & ' Ptr=NULL')
			EndIf
		EndIf
	Next
	Info('║   Valid items: ' & $foundCount)

	; ── Inventory: 4 Mats + 3 Consets ──
	Info('╠══════════════════════════════════════════════════════════╣')
	Info('║ INVENTORY:')
	Info('║   Iron=' & _PathRecorderCountMaterial($ID_IRON_INGOT) & ' Dust=' & _PathRecorderCountMaterial($ID_PILE_OF_GLITTERING_DUST))
	Info('║   Feathers=' & _PathRecorderCountMaterial($ID_FEATHER) & ' Bones=' & _PathRecorderCountMaterial($ID_BONE))
	Info('║   Grail=' & _PathRecorderCountMaterial($ID_GRAIL_OF_MIGHT) & ' Essence=' & _PathRecorderCountMaterial($ID_ESSENCE_OF_CELERITY) & ' Armor=' & _PathRecorderCountMaterial($ID_ARMOR_OF_SALVATION))

	; ── Craft Item Struct State ──
	Info('╠══════════════════════════════════════════════════════════╣')
	Info('║ CRAFT_ITEM_STRUCT (vor Enqueue):')
	Local $craftRaw = MemoryRead($processHandle, DllStructGetPtr($CRAFT_ITEM_STRUCT), 'byte[' & DllStructGetSize($CRAFT_ITEM_STRUCT) & ']')
	Info('║   Ptr=' & DllStructGetPtr($CRAFT_ITEM_STRUCT) & ' Size=' & DllStructGetSize($CRAFT_ITEM_STRUCT) & ' Data=' & $craftRaw)

	; ── BUY_ITEM_STRUCT State ──
	Info('║ BUY_ITEM_STRUCT (vor Enqueue):')
	Local $buyRaw = MemoryRead($processHandle, DllStructGetPtr($BUY_ITEM_STRUCT), 'byte[' & DllStructGetSize($BUY_ITEM_STRUCT) & ']')
	Info('║   Ptr=' & DllStructGetPtr($BUY_ITEM_STRUCT) & ' Size=' & DllStructGetSize($BUY_ITEM_STRUCT) & ' Data=' & $buyRaw)

	; ── Ring-Buffer State (Enqueue-System) ──
	Local $qc = MemoryRead($processHandle, GetLabel('QueueCounter'))
	Local $qs = GetLabel('QueueSize')
	Local $qb = GetLabel('QueueBase')
	Info('╠══════════════════════════════════════════════════════════╣')
	Info('║ RING BUFFER:')
	Info('║   QueueCounter=' & $qc & ' QueueSize=' & $qs & ' QueueBase=0x' & Hex($qb))
	; Nächsten 3 Slots dumpen (aktueller + 2 folgende)
	For $slotOffset = 0 To 2
		Local $slotIdx = Mod($qc + $slotOffset, $qs)
		Local $slotAddr = $qb + 256 * $slotIdx
		Local $slotData = MemoryRead($processHandle, $slotAddr, 'byte[24]')
		Local $cmdPtr = MemoryRead($processHandle, $slotAddr, 'ptr')
		Local $cmdName = '(empty)'
		If $cmdPtr <> 0 Then
			If $cmdPtr = GetLabel('CommandBuyItem') Then $cmdName = 'BuyItem'
			If $cmdPtr = GetLabel('CommandSellItem') Then $cmdName = 'SellItem'
			If $cmdPtr = GetLabel('CommandCraftItem') Then $cmdName = 'CraftItem'
			If $cmdPtr = GetLabel('CommandCollectorExchange') Then $cmdName = 'CollectorExchange'
			If $cmdPtr = GetLabel('CommandTraderBuy') Then $cmdName = 'TraderBuy'
			If $cmdPtr = GetLabel('CommandTraderSell') Then $cmdName = 'TraderSell'
			If $cmdPtr = GetLabel('CommandRequestQuote') Then $cmdName = 'RequestQuote'
			If $cmdPtr = GetLabel('CommandRequestQuoteSell') Then $cmdName = 'RequestQuoteSell'
		EndIf
		Info('║   Slot[' & $slotIdx & '] @ 0x' & Hex($slotAddr) & ' Cmd=' & $cmdName & ' Raw[0..23]=' & $slotData)
	Next

	Info('╚══════════════════════════════════════════════════════════╝')
	Info('')
EndFunc


#Region PacketSend Hook — Reverse-Engineering für Conset-Crafting
; ═══════════════════════════════════════════════════════════
; Ctrl+Alt+P toggelt einen Detour auf GWs PacketSend-Funktion.
; Jedes ausgehende Netzwerk-Paket wird geloggt (Header + Payload).
; Damit lässt sich das Crafting-Paket beim manuellen Kauf bei
; Eyja/Kwat/Alcus identifizieren und später via SendPacket replizieren.
;
; Nutzung:
;   1. PathActionRecorder starten
;   2. Ctrl+Alt+P drücken → "Packet log ON"
;   3. Zu Eyja laufen, Dialog öffnen, EIN Stück craften
;   4. Ctrl+Alt+P drücken → "Packet log OFF"
;   5. Im Log das Craft-Paket identifizieren (erkennbar am Header)
; ═══════════════════════════════════════════════════════════

Global $packet_log_active = False
Global $packet_log_code_addr = 0
Global $packet_log_data_addr = 0
Global $packet_log_last_counter = 0
Global $packet_log_trampoline_bytes = ''

; Offsets in der Data-Region (64 bytes total):
;   +0:  counter (4 bytes)
;   +4:  size    (4 bytes)
;   +8:  data    (56 bytes — header + payload)


;~ Ctrl+Alt+P: Packet-Logging ein-/ausschalten
Func TogglePacketLogHotkey()
	If $packet_log_active Then
		PacketLogTeardown()
		Info('Packet log OFF')
	Else
		If PacketLogSetup() Then
			Info('Packet log ON — capturing outgoing packets. Press Ctrl+Alt+P to stop.')
		Else
			Warn('Packet log setup failed')
		EndIf
	EndIf
EndFunc


;~ Installiert den PacketSend-Detour in GW
Func PacketLogSetup()
	Local $processHandle = GetProcessHandle()
	Local $packetSendAddr = GetLabel('PacketSend')
	If $packetSendAddr = 0 Then
		Warn('PacketSend label not found — is GWA2 initialized?')
		Return False
	EndIf

	; ── 1. Original-Bytes sichern (für Trampoline) ──
	$packet_log_trampoline_bytes = MemoryRead($processHandle, $packetSendAddr, 'byte[5]')

	; ── 2. Data-Region allokieren (64 bytes) ──
	Local $allocData = SafeDllCall13($kernel_handle, 'ptr', 'VirtualAllocEx', _
		'handle', $processHandle, 'ptr', 0, 'ulong_ptr', 64, 'dword', 0x1000, 'dword', 0x40)
	$packet_log_data_addr = $allocData[0]
	If $packet_log_data_addr = 0 Then
		Warn('Failed to allocate data region for packet logger')
		Return False
	EndIf

	; ── 3. Code-Region allokieren ──
	Local $codeSize = 128
	Local $allocCode = SafeDllCall13($kernel_handle, 'ptr', 'VirtualAllocEx', _
		'handle', $processHandle, 'ptr', 0, 'ulong_ptr', $codeSize, 'dword', 0x1000, 'dword', 0x40)
	$packet_log_code_addr = $allocCode[0]
	If $packet_log_code_addr = 0 Then
		Warn('Failed to allocate code region for packet logger')
		SafeDllCall9($kernel_handle, 'int', 'VirtualFreeEx', 'int', $processHandle, 'ptr', $packet_log_data_addr, 'int', 0, 'int', 0x8000)
		$packet_log_data_addr = 0
		Return False
	EndIf

	; ── 4. Hook-Code schreiben ──
	; Assembly (x86, NASM-ish):
	;   PacketLogProc:
	;     pushfd                     ; 9C
	;     pushad                     ; 60
	;     mov esi,[esp+0x2C]         ; 8B 74 24 2C  — dataPtr (arg3, nach pushad: +0x24+8)
	;     mov edx,[esp+0x28]         ; 8B 54 24 28  — size    (arg2)
	;     mov dword[dataAddr+4],edx  ; 89 15 <dataAddr+4>  — store size
	;     mov ecx,edx                ; 8B CA
	;     cmp ecx,56                 ; 83 F9 38
	;     jle +2                     ; 7E 02
	;     mov ecx,56                 ; B9 38 00 00 00
	;     mov edi,dataAddr+8         ; BF <dataAddr+8>
	;     rep movsb                  ; F3 A4
	;     mov edx,dword[dataAddr]    ; 8B 15 <dataAddr>
	;     inc edx                    ; 42
	;     mov dword[dataAddr],edx    ; 89 15 <dataAddr>
	;     popad                      ; 61
	;     popfd                      ; 9D
	;     ; trampoline: 5 original bytes + JMP back
	;     ; Dieser Teil wird separat geschrieben
	Local $hookCode = '0x9C60'                           ; pushfd; pushad
	$hookCode &= '8B74242C'                              ; mov esi,[esp+2C]
	$hookCode &= '8B542428'                              ; mov edx,[esp+28]
	$hookCode &= '8915' & SwapEndian(Hex($packet_log_data_addr + 4, 8))  ; mov [dataAddr+4],edx
	$hookCode &= '8BCA'                                  ; mov ecx,edx
	$hookCode &= '83F938'                                ; cmp ecx,56
	$hookCode &= '7E02'                                  ; jle +2
	$hookCode &= 'B938000000'                            ; mov ecx,56
	$hookCode &= 'BF' & SwapEndian(Hex($packet_log_data_addr + 8, 8))  ; mov edi,dataAddr+8
	$hookCode &= 'F3A4'                                  ; rep movsb
	$hookCode &= '8B15' & SwapEndian(Hex($packet_log_data_addr, 8))  ; mov edx,[dataAddr]
	$hookCode &= '42'                                    ; inc edx
	$hookCode &= '8915' & SwapEndian(Hex($packet_log_data_addr, 8))  ; mov [dataAddr],edx
	$hookCode &= '619D'                                  ; popad; popfd
	; Trampoline: 5 original bytes + JMP back to PacketSend+5
	$hookCode &= $packet_log_trampoline_bytes            ; original instruction bytes
	Local $jmpBackOffset = ($packetSendAddr + 5) - ($packet_log_code_addr + StringLen($hookCode)/2 + 5)
	$hookCode &= 'E9' & SwapEndian(Hex($jmpBackOffset, 8))  ; JMP PacketSend+5

	WriteBinary($processHandle, $hookCode, $packet_log_code_addr)

	; ── 5. Detour installieren: JMP von PacketSend → PacketLogProc ──
	Local $jmpOffset = $packet_log_code_addr - $packetSendAddr - 5
	WriteBinary($processHandle, 'E9' & SwapEndian(Hex($jmpOffset, 8)), $packetSendAddr)

	; ── 6. Polling starten ──
	$packet_log_last_counter = MemoryRead($processHandle, $packet_log_data_addr)
	$packet_log_active = True
	AdlibRegister('PacketLogPollCallback', 250)

	Return True
EndFunc


;~ Entfernt den Detour und gibt die allokierten Regionen frei
Func PacketLogTeardown()
	If Not $packet_log_active Then Return
	AdlibUnRegister('PacketLogPollCallback')
	$packet_log_active = False

	Local $processHandle = GetProcessHandle()
	Local $packetSendAddr = GetLabel('PacketSend')

	; Original-Bytes wiederherstellen
	If $packetSendAddr <> 0 And $packet_log_trampoline_bytes <> '' Then
		WriteBinary($processHandle, $packet_log_trampoline_bytes, $packetSendAddr)
	EndIf

	; Allokierten Speicher freigeben
	If $packet_log_code_addr <> 0 Then
		SafeDllCall9($kernel_handle, 'int', 'VirtualFreeEx', 'int', $processHandle, 'ptr', $packet_log_code_addr, 'int', 0, 'int', 0x8000)
		$packet_log_code_addr = 0
	EndIf
	If $packet_log_data_addr <> 0 Then
		SafeDllCall9($kernel_handle, 'int', 'VirtualFreeEx', 'int', $processHandle, 'ptr', $packet_log_data_addr, 'int', 0, 'int', 0x8000)
		$packet_log_data_addr = 0
	EndIf
	$packet_log_trampoline_bytes = ''
EndFunc


;~ AdlibRegister-Callback: prüft auf neue Pakete und loggt sie
Func PacketLogPollCallback()
	If Not $packet_log_active Then Return
	Local $processHandle = GetProcessHandle()
	If $packet_log_data_addr == 0 Then Return

	Local $counter = MemoryRead($processHandle, $packet_log_data_addr)
	If $counter == $packet_log_last_counter Then Return
	$packet_log_last_counter = $counter

	Local $size = MemoryRead($processHandle, $packet_log_data_addr + 4)
	Local $rawData = MemoryRead($processHandle, $packet_log_data_addr + 8, 'byte[' & _Min($size, 56) & ']')

	; Header (erste 4 Bytes) extrahieren und in lesbarer Form loggen
	Local $headerHex = StringMid($rawData, 3, 8) ; 0xHHHHHHHH → HHHHHHHH
	Info('[PACKET] size=' & $size & ' header=0x' & $headerHex & ' raw=' & $rawData)
EndFunc
#EndRegion PacketSend Hook
