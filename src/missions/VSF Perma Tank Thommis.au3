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
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'
#include '../utilities/SupportTeam.au3'
#include 'VSF Perma Tank.au3'

Opt('MustDeclareVars', True)

Global Const $VSF_PERMA_TANK_THOMMIS_FARM_INFORMATIONS = 'Voltaic Spear Farm (Thommis restart mode):' & @CRLF _
	& '- Starts directly from Slaver''s Exile / Justiciar Thommis wing' & @CRLF _
	& '- Intended for shrine restart after death inside Thommis part' & @CRLF _
	& '- Reuses VSF Perma Tank part-2 logic (flag, prep, kite, hold)'
Global Const $VSF_PERMA_TANK_THOMMIS_FARM_DURATION = 4 * 60 * 1000


Func VSFPermaTankThommisFarm()
	$vsf_run_number += 1
	VSFDebugLogInit()
	VSFDebugLogSnapshot('run_start', 'mode=thommis_only')

	Local $result = VSFPermaTankThommisRunLoop()

	VSFDebugLogSnapshot('run_end', 'mode=thommis_only;result=' & $result)
	VSFDebugLogClose()
	Return $result
EndFunc


Func VSFPermaTankThommisRunLoop()
	Info('VSF Thommis run: starting directly from Slaver''s Exile / Thommis wing')
	VSFResetBuffTimers()
	$vsf_setup_done = True
	$vsf_part2_use_pcons = False

	If GetMapID() <> $ID_SLAVERS_EXILE And GetMapID() <> $ID_SLAVERS_EXILE_LVL_1 Then
		Warn('VSF Thommis run: unsupported map ' & GetMapID() & ' (expected Slaver''s Exile or Thommis wing)')
		Return $FAIL
	EndIf

	If GetMapID() == $ID_SLAVERS_EXILE Then
		Info('VSF Thommis run: entering Justiciar Thommis wing')
	EndIf

	Local $result = VSFRunSlaversLevel1Part()
	$vsf_part2_use_pcons = True
	Return $result
EndFunc
