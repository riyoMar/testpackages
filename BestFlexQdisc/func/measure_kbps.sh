measure_kbps() {
    local INTERVAL=${1:-1}

    local RX1=$(rx)
    local TX1=$(tx)

    sleep "$INTERVAL"

    local RX2=$(rx)
    local TX2=$(tx)

    # Protect against counter wrap
    if [ "$RX2" -lt "$RX1" ]; then
        RX_DIFF=0
    else
        RX_DIFF=$((RX2 - RX1))
    fi

    if [ "$TX2" -lt "$TX1" ]; then
        TX_DIFF=0
    else
        TX_DIFF=$((TX2 - TX1))
    fi

    RX_KBPS=$((RX_DIFF * 8 / 1000 / INTERVAL))
    TX_KBPS=$((TX_DIFF * 8 / 1000 / INTERVAL))
}