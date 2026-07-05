# Conset Reverse-Engineering: Memory Dump Guide

## Ziel
Herausfinden, welche Transaktion beim Kauf eines Conset-Items (Grail of Might, Essence of Celerity, Armor of Salvation) an den NPCs in Embark Beach stattfindet, damit wir diese in `ConsetBuyer.au3` automatisieren können.

## Hintergrund
Die Conset-NPCs (Eyja, Kwat, Alcus Nailbiter) verwenden einen anderen Interface-Typ als normale Händler oder Materialtrader. Alle bisherigen Ansätze sind gescheitert:
- `BuyItem` mit Trader-Transaction → GW lehnt ab
- `TraderRequest` → Items werden durch `bag==0 AND AgentID==0` Filter ausgefiltert
- `CraftItem` (Transaction Type 3) → Struct ist vorhanden aber nie getestet

Wir müssen daher per Memory-Dump analysieren, was GW *wirklich* macht, wenn man manuell ein Conset-Item kauft.

## Vorbereitung

### 1. BotsHub mit PathActionRecorder starten
Starte BotsHub und wähle den **PathActionRecorder** aus dem Utility-Menü. Der Recorder registriert alle Hotkeys und loggt in die `Info()`-Ausgabe (Logfile + Konsole).

### 2. Character vorbereiten
- Stelle sicher, dass du genug Gold (mind. 20.000g = 2.500g × 8 für alle 10 Consets + Reserve) und alle 4 Materialien (Iron, Dust, Feathers, Bones) im Inventar hast.
- Reise nach **Embark Beach** (Map ID 857).

### 3. Zu Eyja navigieren
Eyja steht in Embark Beach bei Koordinaten **(3339, 616)**. Laufe zu ihr hin, bis sie in Reichweite ist (du solltest sie anklicken können).

## Messablauf

Führe die folgenden Schritte **exakt in dieser Reihenfolge** aus. Drücke nach JEDEM Schritt `Ctrl+Alt+0` um einen vollständigen Memory-Snapshot zu erstellen:

### Schritt A: Vor der Interaktion
1. Stehe in Reichweite von Eyja (aber noch NICHT mit ihr interagiert)
2. Drücke `Ctrl+Alt+0` → **"PRE-INTERACTION"** im Log notieren

### Schritt B: Nach Dialog-Öffnen
1. Klicke Eyja an, um den Dialog zu öffnen
2. Warte, bis das Dialogfenster vollständig geladen ist
3. Drücke `Ctrl+Alt+0` → **"DIALOG-OPEN"** im Log notieren

### Schritt C: Craft-Request (Item auswählen)
1. Klicke im Dialog auf z.B. "Grail of Might" (das öffnet das Craft-Fenster mit Materialliste)
2. Warte bis das Craft-Fenster erscheint
3. Drücke `Ctrl+Alt+0` → **"CRAFT-WINDOW"** im Log notieren

### Schritt D: Nach dem Kauf
1. Klicke "Craft" (oder den Bestätigungs-Button), um EIN Stück zu kaufen
2. Warte bis die Transaktion abgeschlossen ist (Item erscheint im Inventar, Gold wurde abgezogen)
3. Drücke `Ctrl+Alt+0` → **"AFTER-CRAFT-1"** im Log notieren

### Schritt E: Zweiter Kauf (optional, zur Bestätigung)
1. Klicke erneut "Craft" für ein zweites Stück
2. Warte bis fertig
3. Drücke `Ctrl+Alt+0` → **"AFTER-CRAFT-2"** im Log notieren

## Auswertung

### Was jeder Dump enthält
- **Map & Position**: Map ID, Koordinaten
- **Gold**: Character + Storage
- **Target**: Dein aktuell anvisierter NPC
- **Nearest NPC**: Der nächste NPC mit Distanz
- **Trader State**: `TraderQuoteID`, `TraderCostID`, `TraderCostValue` + Raw Bytes
- **Merchant Items**: Alle Items im Händler-Fenster mit ModelID, Value, und 64 Bytes Raw-Daten
- **Inventory**: Counts von Iron, Dust, Feathers, Bones, Grail, Essence, Armor
- **CRAFT_ITEM_STRUCT**: Raw Bytes (vor Enqueue)
- **BUY_ITEM_STRUCT**: Raw Bytes (vor Enqueue)

### Worauf du achten solltest
Vergleiche die Dumps vor und nach jedem Schritt. Relevante Änderungen:

| Was | Erwartete Änderung |
|-----|-------------------|
| `TraderQuoteID` | Sollte sich beim Dialog-Öffnen von 0 auf eine ID ändern |
| `TraderCostID` | Sollte die Material-Anforderungen widerspiegeln |
| `TraderCostValue` | Könnte sich beim Craft auf den Gold-Preis (250) setzen |
| `Merchant Items` | Die Raw-Bytes könnten nach dem Kauf andere Werte zeigen |
| Gold im Inventar | Sollte nach Kauf um 250g sinken |
| Conset-Count | Sollte nach Kauf um +1 steigen |

## Logs auswerten

Die Logs findest du in `c:\BotsHub\logs\`. Suche nach den `FULL MEMORY DUMP` Blöcken und vergleiche sie.

Markiere im Logfile jeden Dump mit deinem Label (z.B. `PRE-INTERACTION`, `DIALOG-OPEN`, etc.) als Kommentar, damit du später weißt, welcher Dump zu welchem Schritt gehört.

## Nächste Schritte

Nach der Analyse der Dumps wissen wir:
1. Ob `TraderCostID`/`TraderCostValue` gesetzt werden (dann können wir `TraderRequest` + `TraderBuy` verwenden)
2. Ob sich die Merchant-Item-Structs ändern (dann brauchen wir einen anderen Ansatz)
3. Ob `CRAFT_ITEM_STRUCT` verwendet wird (Transaction Type 3)

Basierend darauf implementieren wir dann die korrekte Transaktion in `ConsetBuyer.au3`.
