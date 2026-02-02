#!/bin/sh

# parameters
INTERFACE="$1"
TIMES="$2"

rx() { awk -v IF="$INTERFACE" '$1 == IF ":" {print $2}' /proc/net/dev; }
tx() { awk -v IF="$INTERFACE" '$1 == IF ":" {print $10}' /proc/net/dev; }


apply_cake() {
    DL=$1
    UL=$2

    tc qdisc del dev $INTERFACE root 2>/dev/null
    tc qdisc del dev $INTERFACE ingress 2>/dev/null
    tc qdisc del dev ifb_${INTERFACE} root 2>/dev/null

    # Upload (egress)
    tc qdisc add dev $INTERFACE root cake bandwidth ${UL}bps \
        besteffort triple-isolate rtt 100ms

    # Ingress redirect
    tc qdisc add dev $INTERFACE handle ffff: ingress
    tc filter add dev $INTERFACE parent ffff: \
        protocol all u32 match u32 0 0 \
        action mirred egress redirect dev ifb_${INTERFACE}

    # Download (ingress)
    tc qdisc add dev ifb_${INTERFACE} root cake bandwidth ${DL}bps \
        besteffort triple-isolate rtt 100ms
}

MAX_RX=0
MAX_TX=0

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
    sleep $TIMES;
    RX1=$(rx); TX1=$(tx)
    sleep 1
    RX2=$(rx); TX2=$(tx)

    RX_BPS=$((RX2-RX1))
    TX_BPS=$((TX2-TX1))
    
    printf " Ingress    : %s\n" "$(format_rate $RX_BPS)"
    printf " Egress     : %s\n\n" "$(format_rate $TX_BPS)"

    apply_cake "$RX_BPS" "$TX_BPS"

done