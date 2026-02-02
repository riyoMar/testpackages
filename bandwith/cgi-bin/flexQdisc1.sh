#!/bin/sh

IFACE="phy0-sta0"
IFB="ifb4phy0-sta0"

# $1 = measurement interval (seconds)
INTERVAL=${1:-3}

# Safety margin (percent of measured peak)
SAFETY=92

rx() { awk -v IF="$IFACE" '$1 == IF ":" {print $2}' /proc/net/dev; }
tx() { awk -v IF="$IFACE" '$1 == IF ":" {print $10}' /proc/net/dev; }

format_rate() {
    v=$1
    if [ "$v" -ge 1000000 ]; then
        awk "BEGIN{printf \"%.2f Mbit/s\", $v/1000000}"
    elif [ "$v" -ge 1000 ]; then
        awk "BEGIN{printf \"%.2f Kbit/s\", $v/1000}"
    else
        printf "%d bit/s" "$v"
    fi
}

modprobe ifb
ip link show $IFB >/dev/null 2>&1 || ip link add $IFB type ifb
ip link set $IFB up

MAX_RX=0
MAX_TX=0
COUNT=0

echo "Measuring link capacity (Ctrl+C to stop)..."

while true; do
    RX1=$(rx); TX1=$(tx)
    sleep $INTERVAL
    RX2=$(rx); TX2=$(tx)

    RX_BPS=$(( (RX2 - RX1) * 8 / INTERVAL ))
    TX_BPS=$(( (TX2 - TX1) * 8 / INTERVAL ))

    [ "$RX_BPS" -gt "$MAX_RX" ] && MAX_RX=$RX_BPS
    [ "$TX_BPS" -gt "$MAX_TX" ] && MAX_TX=$TX_BPS

    COUNT=$((COUNT+1))

    printf "\nSample %d:\n" "$COUNT"
    printf "Ingress: %s\n" "$(format_rate $RX_BPS)"
    printf "Egress : %s\n" "$(format_rate $TX_BPS)"
    printf "Peak RX: %s\n" "$(format_rate $MAX_RX)"
    printf "Peak TX: %s\n" "$(format_rate $MAX_TX)"

    # After ~10 samples, apply CAKE once
    if [ "$COUNT" -eq 10 ]; then
        DL=$(( MAX_RX * SAFETY / 100 ))
        UL=$(( MAX_TX * SAFETY / 100 ))

        echo
        echo "Applying CAKE:"
        echo "Download: $(format_rate $DL)"
        echo "Upload  : $(format_rate $UL)"

        tc qdisc del dev $IFACE root 2>/dev/null
        tc qdisc del dev $IFACE ingress 2>/dev/null
        tc qdisc del dev $IFB root 2>/dev/null

        # Egress (upload)
        tc qdisc add dev $IFACE root cake bandwidth ${UL}bps \
            besteffort triple-isolate rtt 100ms

        # Ingress redirect
        tc qdisc add dev $IFACE handle ffff: ingress
        tc filter add dev $IFACE parent ffff: \
            protocol all u32 match u32 0 0 \
            action mirred egress redirect dev $IFB

        # Ingress (download)
        tc qdisc add dev $IFB root cake bandwidth ${DL}bps \
            besteffort triple-isolate rtt 100ms

        echo "CAKE applied. Exiting."
        exit 0
    fi
done
