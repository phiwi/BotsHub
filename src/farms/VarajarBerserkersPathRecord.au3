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

; Reuse the Varajar Berserkers setup + split choreography, and the path-action recorder
#include 'VarajarBerserkers.au3'
#include '../utilities/PathActionRecorder.au3'


; ==== Constants ====
Global Const $VARAJAR_BERSERKERS_PATH_RECORD_DURATION = 10 * 60 * 1000


;~ Run the Varajar Berserkers setup, split (Make Haste on the Sin), then switch to
;~ path recording so the player can manually run the pull circle and produce a CSV
;~ recording of the route (saved to doc/path_action_recordings/).
Func VarajarBerserkersPathRecordFarm()
	If Not $varajar_berserkers_farm_setup And SetupVarajarBerserkersFarm() == $FAIL Then Return $PAUSE

	VarajarBerserkersGoToZone()
	If GetMapID() <> $ID_VARAJAR_FELLS Then Return $FAIL

	If Not VarajarBerserkersRunToSplit() Then
		If $varajar_margrid_dead Or $varajar_morgahn_dead Then Info('Hero died during the run - resigning')
		ResignAndReturnToOutpost($ID_OLAFSTEAD)
		Return $FAIL
	EndIf

	; Split choreography: EoE, Shroud, Vocal Was Sogolon, Enduring Harmony, then Make Haste
	VarajarBerserkersSplit()

	; Switch to path recording so the player can run the circle manually
	RegisterPathActionRecorderHotkeys()
	Info('Path recording started - run the pull circle manually now (Ctrl+Alt+R to stop recording)')
	StartPathActionRecorder()

	; Wait for the player to manually run the circle and stop the bot
	While $runtime_status == 'RUNNING'
		Sleep(250)
	WEnd

	StopPathActionRecorder()
	TeardownPathActionRecorderHotkeys()

	Return $runtime_status <> 'RUNNING' ? $PAUSE : $SUCCESS
EndFunc
