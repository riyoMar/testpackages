#!/bin/sh

# parameters
INTERFACE="$1"
TIMES="${2:-3}"
IFB="ifb_${INTERFACE}"

[ -z "$INTERFACE" ] && {
    echo "Usage: $0 <interface> [interval]"
    exit 1
}

# read RX / TX bytes
rx() { awk -v IF="$INTERFACE" '$1 == IF ":" {print $2}' /proc/net/dev; }
tx() { awk -v IF="$INTERFACE" '$1 == IF ":" {print $10}' /proc/net/dev; }

# IFB setup (minimal)
modprobe ifb 2>/dev/null
ip link show "$IFB" >/dev/null 2>&1 || ip link add "$IFB" type ifb
ip link set "$IFB" up

apply_cake() {
    DL=$1
    UL=$2

    tc qdisc del dev "$INTERFACE" root 2>/dev/null
    tc qdisc del dev "$INTERFACE" ingress 2>/dev/null
    tc qdisc del dev "$IFB" root 2>/dev/null

    # Upload (egress)
    tc qdisc add dev "$INTERFACE" root cake bandwidth ${UL}bps \
        besteffort triple-isolate rtt 100ms

    # Ingress redirect
    tc qdisc add dev "$INTERFACE" handle ffff: ingress
    tc filter add dev "$INTERFACE" parent ffff: \
        protocol all u32 match u32 0 0 \
        action mirred egress redirect dev "$IFB"

    # Download (ingress)
    tc qdisc add dev "$IFB" root cake bandwidth ${DL}bps \
        besteffort triple-isolate rtt 100ms
}

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

while true; do
    RX1=$(rx)
    TX1=$(tx)

    sleep "$TIMES"

    RX2=$(rx)
    TX2=$(tx)

    # bytes → bits/sec
    RX_BPS=$(( (RX2 - RX1) * 8 / TIMES ))
    TX_BPS=$(( (TX2 - TX1) * 8 / TIMES ))

    printf " Ingress    : %s\n" "$(format_rate $RX_BPS)"
    printf " Egress     : %s\n\n" "$(format_rate $TX_BPS)"

    apply_cake "$RX_BPS" "$TX_BPS"
done
