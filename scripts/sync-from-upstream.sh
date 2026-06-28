#!/usr/bin/env bash
# ============================================================================
# sync-from-upstream.sh
#
# Holt die neuesten Änderungen von caustic-kronos/BotsHub (upstream) in
# deinen lokalen master-Branch. Deine eigenen uncommitteten Änderungen
# werden vorher sicher zwischengespeichert (stash) und danach wieder
# hergestellt.
#
# Einfach doppelklicken oder:
#   ./scripts/sync-from-upstream.sh
# ============================================================================

set -e

echo "=== Sync from upstream (caustic-kronos → lokal) ==="

# --- Schritt 0: Sind wir im richtigen Verzeichnis? ---
cd "$(dirname "$0")/.."
echo "→ Arbeite in: $(pwd)"

# --- Schritt 1: Lokale Änderungen zwischenspeichern ---
HAS_CHANGES=false
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "→ Sichere lokale Änderungen mit 'git stash'..."
    git stash push -u -m "sync-from-upstream: auto-stash vor pull"
    HAS_CHANGES=true
else
    echo "→ Arbeitsverzeichnis ist sauber, kein stash nötig."
fi

# --- Schritt 2: Von upstream (caustic-kronos) holen und mergen ---
echo "→ Hole neueste Änderungen von upstream..."
git fetch upstream --prune

echo "→ Merge upstream/master in lokalen master..."
if ! git merge --no-edit upstream/master; then
    echo ""
    echo "!!! MERGE-KONFLIKT !!!"
    echo "    Löse die Konflikte manuell auf, dann:"
    echo "      git add . && git merge --continue"
    echo "    Oder brich ab mit:"
    echo "      git merge --abort"
    if $HAS_CHANGES; then
        echo "    Deine gestashten Änderungen sind noch in 'git stash list'."
        echo "    Nach dem Merge: git stash pop"
    fi
    exit 1
fi

# --- Schritt 3: Gestashte Änderungen wiederherstellen ---
if $HAS_CHANGES; then
    echo "→ Stelle lokale Änderungen wieder her..."
    if ! git stash pop; then
        echo ""
        echo "!!! STASH-KONFLIKT !!!"
        echo "    Deine Änderungen konnten nicht sauber angewendet werden."
        echo "    Die Änderungen sind noch im stash:"
        echo "      git stash list"
        echo "    Löse Konflikte manuell, dann:"
        echo "      git stash drop   (wenn erledigt)"
    fi
fi

echo ""
echo "=== Fertig! Lokaler master ist auf dem neuesten Stand. ==="
