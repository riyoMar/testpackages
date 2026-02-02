#!/bin/sh

IFACE="phy0-sta0"
IFB="ifb4phy0-sta0"

INTERVAL=${1:-3}     # seconds
SAFETY=92            # percent of peak bandwidth
REAPPLY_DELTA=10     # percent change required to reapply CAKE

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

apply_cake() {
    DL=$1
    UL=$2

    echo
    echo "Applying CAKE:"
    echo " Download: $(format_rate $DL)"
    echo " Upload  : $(format_rate $UL)"

    tc qdisc del dev $IFACE root 2>/dev/null
    tc qdisc del dev $IFACE ingress 2>/dev/null
    tc qdisc del dev $IFB root 2>/dev/null

    # Upload (egress)
    tc qdisc add dev $IFACE root cake bandwidth ${UL}bps \
        besteffort triple-isolate rtt 100ms

    # Ingress redirect
    tc qdisc add dev $IFACE handle ffff: ingress
    tc filter add dev $IFACE parent ffff: \
        protocol all u32 match u32 0 0 \
        action mirred egress redirect dev $IFB

    # Download (ingress)
    tc qdisc add dev $IFB root cake bandwidth ${DL}bps \
        besteffort triple-isolate rtt 100ms
}

# Setup IFB
modprobe ifb
ip link show $IFB >/dev/null 2>&1 || ip link add $IFB type ifb
ip link set $IFB up

MAX_RX=0
MAX_TX=0
APPLIED_DL=0
APPLIED_UL=0

echo "Starting continuous CAKE auto-tuning (interval: ${INTERVAL}s)"

while true; do
    RX1=$(rx); TX1=$(tx)
    sleep $INTERVAL
    RX2=$(rx); TX2=$(tx)

    RX_BPS=$(( (RX2 - RX1) * 8 / INTERVAL ))
    TX_BPS=$(( (TX2 - TX1) * 8 / INTERVAL ))

    [ "$RX_BPS" -gt "$MAX_RX" ] && MAX_RX=$RX_BPS
    [ "$TX_BPS" -gt "$MAX_TX" ] && MAX_TX=$TX_BPS

    DL=$(( MAX_RX * SAFETY / 100 ))
    UL=$(( MAX_TX * SAFETY / 100 ))

    printf "\nMeasured over %ds:\n" "$INTERVAL"
    printf " Ingress now : %s\n" "$(format_rate $RX_BPS)"
    printf " Egress  now : %s\n" "$(format_rate $TX_BPS)"
    printf " Peak RX     : %s\n" "$(format_rate $MAX_RX)"
    printf " Peak TX     : %s\n" "$(format_rate $MAX_TX)"

    # Apply CAKE first time
    if [ "$APPLIED_DL" -eq 0 ]; then
        apply_cake "$DL" "$UL"
        APPLIED_DL=$DL
        APPLIED_UL=$UL
        continue
    fi

    # Check if bandwidth changed significantly
    DIFF_DL=$(( (DL - APPLIED_DL) * 100 / APPLIED_DL ))
    DIFF_UL=$(( (UL - APPLIED_UL) * 100 / APPLIED_UL ))

    [ "$DIFF_DL" -lt 0 ] && DIFF_DL=$(( -DIFF_DL ))
    [ "$DIFF_UL" -lt 0 ] && DIFF_UL=$(( -DIFF_UL ))

    if [ "$DIFF_DL" -ge "$REAPPLY_DELTA" ] || [ "$DIFF_UL" -ge "$REAPPLY_DELTA" ]; then
        echo
        echo "Bandwidth changed significantly, reapplying CAKE..."
        apply_cake "$DL" "$UL"
        APPLIED_DL=$DL
        APPLIED_UL=$UL
    fi
done
