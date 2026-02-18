LAST_DL=0
LAST_UL=0

diff_update() {
    local PERCENTAGE=${1:-5}

    measure_kbps 1

    echo "Current → RX:${RX_KBPS}kbit TX:${TX_KBPS}kbit"

    # If no previous value, just initialize and apply once
    if [ "$LAST_DL" -eq 0 ] || [ "$LAST_UL" -eq 0 ]; then
        LAST_DL=${MIN_RX:-3000} # using 3Mbits as default
        LAST_UL=${MIN_TX:-3000}

        # LAST_DL=$RX_KBPS
        # LAST_UL=$TX_KBPS

        echo "Initial CAKE → DL:${LAST_DL}kbit UL:${LAST_UL}kbit"
        apply_cake "$LAST_DL" "$LAST_UL"
        return
    fi

    # Avoid division if last value is 0
    if [ "$LAST_DL" -gt 0 ]; then
        DL_DIFF=$(awk -v a="$RX_KBPS" -v b="$LAST_DL" \
    'BEGIN { if (b>0) printf "%d", ((a-b)/b)*100; else print 0 }')
        # DL_DIFF=$(( (RX_KBPS - LAST_DL) * 100 / LAST_DL ))
        [ "$DL_DIFF" -lt 0 ] && DL_DIFF=$(( -DL_DIFF ))
    else
        DL_DIFF=0
    fi

    if [ "$LAST_UL" -gt 0 ]; then
        UL_DIFF=$(awk -v a="$TX_KBPS" -v b="$LAST_UL" \
    'BEGIN { if (b>0) printf "%d", ((a-b)/b)*100; else print 0 }')
        # UL_DIFF=$(( (TX_KBPS - LAST_UL) * 100 / LAST_UL ))
        [ "$UL_DIFF" -lt 0 ] && UL_DIFF=$(( -UL_DIFF ))
    else
        UL_DIFF=0
    fi

    # add here just if grater than min rx & tx then update
    # Enforce minimum bandwidth floor
    NEW_DL=$RX_KBPS
    NEW_UL=$TX_KBPS

    # If measured is below minimum, clamp it
    [ "$NEW_DL" -lt "$MIN_RX" ] && NEW_DL=$MIN_RX
    [ "$NEW_UL" -lt "$MIN_TX" ] && NEW_UL=$MIN_TX


    if [ "$DL_DIFF" -ge "$PERCENTAGE" ] || \
       [ "$UL_DIFF" -ge "$PERCENTAGE" ]; then

        echo "Updating CAKE → DL:${NEW_DL}kbps UL:${NEW_UL}kbps"

        apply_cake "$NEW_DL" "$NEW_UL"

        LAST_DL=$NEW_DL
        LAST_UL=$NEW_UL
    fi

    # if [ "$DL_DIFF" -ge "$PERCENTAGE" ] || \
    #    [ "$UL_DIFF" -ge "$PERCENTAGE" ]; then

    #     echo "Updating CAKE → DL:${RX_KBPS}kbps UL:${TX_KBPS}kbps"

    #     apply_cake "$RX_KBPS" "$TX_KBPS"

    #     LAST_DL=$RX_KBPS
    #     LAST_UL=$TX_KBPS
    # fi
}