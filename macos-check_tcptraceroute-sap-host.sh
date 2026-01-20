#!/bin/bash

# Port für tcptraceroute
PORT=3200

# Intervall zwischen den Durchläufen (in Sekunden)
INTERVAL=1

# Ziele als Bash-3.2-kompatibles Array
TARGETS=(
    "1.2.3.4"
    "example.com"
    "10.20.30.40"
)

LOGFILE="tcptrace.log"

echo "Starte TCP-Traceroute Monitoring auf Port $PORT ..."
echo "Ziele: ${TARGETS[*]}"
echo "Logfile: $LOGFILE"
echo "---------------------------------------------"

while true; do
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

    # Array seriell durchlaufen
    for TARGET in "${TARGETS[@]}"; do
        echo "[$TIMESTAMP] Prüfe $TARGET ..." | tee -a "$LOGFILE"

        tcptraceroute "$TARGET" "$PORT" 2>&1 | tee -a "$LOGFILE"

        echo "---------------------------------------------" | tee -a "$LOGFILE"
    done

    sleep "$INTERVAL"
done
