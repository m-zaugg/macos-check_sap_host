#!/bin/bash

PORT=3200

SERVERS=(
    "a62prodapha00.infra.be.ch"
    "a62prodapha01.infra.be.ch"
)

IPS=()   # gleiche Reihenfolge wie SERVERS

LOGFILE="$HOME/sap-host-check.log"

echo "Starte Initial-DNS-Checks..."

resolve_ip() {
    local host="$1"
    local ip

    ip=$(dig +short "$host" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n1)

    if [ -z "$ip" ]; then
        echo "UNRESOLVED"
    else
        echo "$ip"
    fi
}

# --- Initiale DNS-Auflösung ---
for HOST in "${SERVERS[@]}"; do
    IP=$(resolve_ip "$HOST")

    if [ "$IP" = "UNRESOLVED" ]; then
        echo "FEHLER: Host '$HOST' konnte nicht aufgelöst werden. Abbruch."
        exit 1
    fi

    IPS+=("$IP")
    echo "OK: $HOST → $IP"
done

echo "Alle Hosts erfolgreich aufgelöst. Monitoring startet..."
echo "Logfile: $LOGFILE"
echo

# --- Monitoring-Schleife ---
while true; do
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

    for i in "${!SERVERS[@]}"; do
        HOST="${SERVERS[$i]}"
        IP="${IPS[$i]}"

        if nc -G 1 -w 1 -v "$IP" "$PORT"; then
            echo "$TIMESTAMP [$HOST] OK: $HOST ($IP):$PORT erreichbar" >> "$LOGFILE"
        else
            echo "$TIMESTAMP [$HOST] FAIL: $HOST ($IP):$PORT NICHT erreichbar" >> "$LOGFILE"
        fi
    done

    sleep 1
done
