#!/bin/sh

# parameters
IFACE="$1"
IFB="ifb_${1}"
INTERVAL=${2:-3}     # seconds
SAFETY=70            # percent of peak bandwidth                # best 70
REAPPLY_DELTA=5     # percent change required to reapply CAKE  # best 5

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
# functions
. "$SCRIPT_DIR/func/rx.sh"
. "$SCRIPT_DIR/func/tx.sh"
. "$SCRIPT_DIR/func/format_rate.sh"
. "$SCRIPT_DIR/func/apply_cake.sh"


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
