# Outcast Halcyon - First Test Runbook

## Ziel
In einem einzigen Testlauf moeglichst viel Optimierungssignal gewinnen:
- Start-Flow korrekt? (Quest reset -> Cavalon -> Quest nehmen -> Zos -> Boreas)
- Rion-Phase stabil?
- Wellen-Wartefenster und Stack-Erkennung passend?
- Choreo getroffen? (Spirits -> Rotting/Escape -> Lacerate -> Rotting/Escape -> Ship Hug/Necrosis)

## Wichtige Marker im Recorder
Der Bot schreibt Marker mit Prefix `OH_`:
- `OH_RUN_START`, `OH_RUN_END_SUCCESS|FAIL`
- `OH_QUEST_CHECK_BEGIN|DONE`, `OH_QUEST_ABANDON_*`
- `OH_QUEST_TAKE_ATTEMPT_<n>_MODEL_<id>`, `OH_QUEST_TAKE_WRONG_MODEL_<id>`, `OH_QUEST_TAKE_NPC_NOT_FOUND`
- `OH_LEXIS_SCAN_MODEL_<id>_D_<dist>`
- `OH_TRAVEL_CAVALON`, `OH_TRAVEL_ZOS_BEGIN|DONE`, `OH_MAP_BOREAS_EXPLORABLE`
- `OH_RION_PHASE_BEGIN|DONE`, `OH_RION_INTERACT`
- `OH_WAVE_<n>_WAIT_BEGIN|DONE`, `OH_WAVE_<n>_STACKED|STACK_TIMEOUT`
- `OH_WAVE_<n>_FIGHT_BEGIN|DONE`
- `OH_SPIRITS_CAST_BEGIN|DONE`, `OH_ROTTING_CAST`, `OH_EBON_ESCAPE`
- `OH_HUG_SHIP`, `OH_SHIP_NECROSIS`
- `OH_LOOT_BEGIN|DONE`

## Schnelle CLI-Auswertung (Git Bash)

### 1) Nur Marker
```bash
awk -F';' '$2=="MARK" {print $1";"$11}' doc/path_action_recordings/path_action_YYYYMMDD_HHMMSS.csv
```

### 2) Marker + Skillcasts nebeneinander
```bash
awk -F';' '$2=="MARK" || $2=="SKILL_CAST" {print $1";"$2";"$10";"$11}' doc/path_action_recordings/path_action_YYYYMMDD_HHMMSS.csv
```

### 3) Relevante Skills filtern
Skill IDs:
- Rotting Flesh=106
- Lacerate=961
- Toxicity=1472
- Edge of Extinction=464
- Ebon Escape=2420
- EVAS=2235
- Necrosis=2103
- Run as One=811

```bash
awk -F';' '$2=="SKILL_CAST" && ($10==106 || $10==961 || $10==1472 || $10==464 || $10==2420 || $10==2235 || $10==2103 || $10==811) {print $1";"$3";"$4";"$10";"$11}' doc/path_action_recordings/path_action_YYYYMMDD_HHMMSS.csv
```

### 4) Wartefenster am Hold-Spot checken
```bash
awk -F';' '$2=="POS" && $3>9600 && $3<9900 && $4<-6100 && $4>-6500 {print $1";"$3";"$4}' doc/path_action_recordings/path_action_YYYYMMDD_HHMMSS.csv
```

## Erwartete Reihenfolge (high-level)
1. Quest-Check/Abandon falls vorhanden
2. Cavalon
3. Quest bei Lexis aktiv
4. Zos -> Boreas explorable
5. Rion-Phase + Event start
6. Hold-Spot
7. Welle 1/2/3 je: WaitStack -> Fight-Choreo
8. Loot
9. Resign

## Erfolgskriterien fuer Test 1
- Kein Quest-Reward-Handling
- Quest-Take nutzt Captain Lexis ModelID 3654 (kein `OH_QUEST_TAKE_WRONG_MODEL_*`)
- Keine fehlenden `OH_WAVE_<n>_FIGHT_BEGIN` Marker
- Mindestens 2x `OH_ROTTING_CAST` + 2x `OH_EBON_ESCAPE` pro Welle
- `OH_HUG_SHIP` vor Ende jeder Welle
- Lauf endet mit `OH_RUN_END_SUCCESS` oder liefert klaren Fail-Marker
