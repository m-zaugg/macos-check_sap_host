#!/bin/bash

# Port für tcptraceroute
PORT=3200

# Ziele
TARGETS=(
    "a62prodapha00.infra.be.ch"
    "a62prodapha01.infra.be.ch"
)

LOGFILE="$HOME/sap-host-tcptraceroute.log"

echo "Starte TCP-Traceroute Monitoring auf Port $PORT ..."
echo "Ziele: ${TARGETS[*]}"
echo "Logfile: $LOGFILE"
echo "---------------------------------------------"

# ---------------------------------------------
# Start-Abfrage: Änderungsdetektion aktivieren?
# ---------------------------------------------
echo -n "Änderungsdetektion aktivieren (y/n): "
read ENABLE_CHANGE_DETECT

if [ "$ENABLE_CHANGE_DETECT" = "y" ] || [ "$ENABLE_CHANGE_DETECT" = "Y" ]; then
    CHANGE_DETECT=true
    echo "Änderungsdetektion ist AKTIV."
else
    CHANGE_DETECT=false
    echo "Änderungsdetektion ist DEAKTIVIERT."
fi

echo "---------------------------------------------"

# ---------------------------------------------
# PID-Liste für Subtasks
# ---------------------------------------------
PIDS=""

# ---------------------------------------------
# Für jeden Host einen eigenen Prozess starten
# ---------------------------------------------
for TARGET in "${TARGETS[@]}"; do
(
    LAST_ROUTE=""

    while true; do
        TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

        # Route erfassen
        RAW_ROUTE=$(tcptraceroute "$TARGET" "$PORT" 2>&1)

        # Nur Hop-Zeilen extrahieren (für Vergleich)
        CLEAN_ROUTE=$(echo "$RAW_ROUTE" | grep -E "^[ ]*[0-9]+[ ]")

        if [ "$CHANGE_DETECT" = true ]; then
            # Änderungsdetektion aktiv
            if [ -z "$LAST_ROUTE" ]; then
                LAST_ROUTE="$CLEAN_ROUTE"
                echo "[$TIMESTAMP] Initiale Route für $TARGET gespeichert." | tee -a "$LOGFILE"
                echo "$RAW_ROUTE" | tee -a "$LOGFILE"
                echo "---------------------------------------------" | tee -a "$LOGFILE"
            else
                if [ "$CLEAN_ROUTE" != "$LAST_ROUTE" ]; then
                    echo "[$TIMESTAMP] *** ROUTE ÄNDERUNG für $TARGET ***" | tee -a "$LOGFILE"
                    echo "--- Alte Route ---" | tee -a "$LOGFILE"
                    echo "$LAST_ROUTE" | tee -a "$LOGFILE"
                    echo "--- Neue Route ---" | tee -a "$LOGFILE"
                    echo "$RAW_ROUTE" | tee -a "$LOGFILE"
                    echo "---------------------------------------------" | tee -a "$LOGFILE"

                    LAST_ROUTE="$CLEAN_ROUTE"
                fi
            fi
        else
            # Änderungsdetektion deaktiviert
            echo "[$TIMESTAMP] Prüfe $TARGET ..." | tee -a "$LOGFILE"
            echo "$RAW_ROUTE" | tee -a "$LOGFILE"
            echo "---------------------------------------------" | tee -a "$LOGFILE"
        fi

    done
) &
PID=$!
PIDS="$PIDS $PID"
echo "Subtask für $TARGET gestartet (PID $PID)"
done

# ---------------------------------------------
# Trap für sauberes Beenden aller Subtasks
# ---------------------------------------------
trap "echo 'Beende Subtasks...'; kill $PIDS 2>/dev/null; wait $PIDS 2>/dev/null; exit 0" INT TERM

# Hauptprozess wartet auf Subtasks
wait