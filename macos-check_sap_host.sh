#!/bin/bash

# Nur FQDNs angeben – Port ist global definiert
PORT=3200

SERVERS=(
    "web01.example.org"
    "db.example.org"
    "backup01.example.org"
)

LOGFILE="$HOME/netcat_fqdn_check.log"

echo "Starte Initial-DNS-Checks..."

declare -A RESOLVED_IPS

resolve_ip() {
    local host="$1"

    # DNS-Auflösung via dig
    local ip
    ip=$(dig +short "$host" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n1)

    if [[ -z "$ip" ]]; then
        echo "UNRESOLVED"
    else
        echo "$ip"
    fi
}

# --- Initiale DNS-Auflösung ---
for HOST in "${SERVERS[@]}"; do
    IP=$(resolve_ip "$HOST")

    if [[ "$IP" == "UNRESOLVED" ]]; then
        echo "FEHLER: Host '$HOST' konnte nicht aufgelöst werden. Abbruch."
        exit 1
    fi

    RESOLVED_IPS["$HOST"]="$IP"
    echo "OK: $HOST → ${RESOLVED_IPS[$HOST]}"
done

echo "Alle Hosts erfolgreich aufgelöst. Monitoring startet..."
echo "Logfile: $LOGFILE"
echo

# --- Monitoring-Schleife ---
while true; do
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

    for HOST in "${SERVERS[@]}"; do
        IP="${RESOLVED_IPS[$HOST]}"

        if nc -z -w1 "$IP" "$PORT"; then
            echo "$TIMESTAMP [$HOST] OK: $HOST ($IP):$PORT erreichbar" >> "$LOGFILE"
        else
            echo "$TIMESTAMP [$HOST] FAIL: $HOST ($IP):$PORT NICHT erreichbar" >> "$LOGFILE"
        fi
    done

    sleep 1
done
