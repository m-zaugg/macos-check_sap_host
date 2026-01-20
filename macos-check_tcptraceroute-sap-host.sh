#!/bin/bash

PORT=3200

TARGETS=(
    "a62prodapha00.infra.be.ch"
    "a62prodapha01.infra.be.ch"
)

LOGFILE="$HOME/sap-host-tcptraceroute.log"

echo "Starte host-unabhängiges TCP-Traceroute Monitoring mit Änderungsdetektion ..."
echo "Ziele: ${TARGETS[*]}"
echo "Logfile: $LOGFILE"
echo "---------------------------------------------"

# Für jeden Host einen eigenen Prozess starten
for TARGET in "${TARGETS[@]}"; do
(
    LAST_ROUTE=""

    while true; do
        TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

        # Route erfassen (nur Hop-Liste extrahieren)
        CURRENT_ROUTE=$(tcptraceroute "$TARGET" "$PORT" 2>&1)

        # Nur die Hop-Zeilen extrahieren (Start mit Zahl)
        CLEAN_ROUTE=$(echo "$CURRENT_ROUTE" | grep -E "^[ ]*[0-9]+[ ]")

        # Wenn erste Messung → speichern und loggen
        if [ -z "$LAST_ROUTE" ]; then
            LAST_ROUTE="$CLEAN_ROUTE"
            echo "[$TIMESTAMP] Initiale Route für $TARGET gespeichert." | tee -a "$LOGFILE"
            echo "$CLEAN_ROUTE" | tee -a "$LOGFILE"
            echo "---------------------------------------------" | tee -a "$LOGFILE"
        else
            # Vergleich
            if [ "$CLEAN_ROUTE" != "$LAST_ROUTE" ]; then
                echo "[$TIMESTAMP] *** ROUTE ÄNDERUNG für $TARGET ***" | tee -a "$LOGFILE"
                echo "--- Alte Route ---" | tee -a "$LOGFILE"
                echo "$LAST_ROUTE" | tee -a "$LOGFILE"
                echo "--- Neue Route ---" | tee -a "$LOGFILE"
                echo "$CLEAN_ROUTE" | tee -a "$LOGFILE"
                echo "---------------------------------------------" | tee -a "$LOGFILE"

                LAST_ROUTE="$CLEAN_ROUTE"
            fi
        fi
    done
) &
done

wait
