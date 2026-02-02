#!/bin/sh

IF=$1  # in running script e.g. ./real_time_bandwith.sh eth0

rx() { awk -v IF="$IF" '$1 == IF ":" {print $2}' /proc/net/dev; }
tx() { awk -v IF="$IF" '$1 == IF ":" {print $10}' /proc/net/dev; }

RX1=$(rx)
TX1=$(tx)

sleep $2 # second input after calling this file

RX2=$(rx)
TX2=$(tx)

RX_BPS=$(( (RX2 - RX1) * 8 ))
TX_BPS=$(( (TX2 - TX1) * 8 ))

format_rate() {
    v=$1
    if [ "$v" -ge 1048576 ]; then
        printf "%.2f Mibit/s\n" "$(awk "BEGIN{print $v/1048576}")"
    elif [ "$v" -ge 1024 ]; then
        printf "%.2f Kibit/s\n" "$(awk "BEGIN{print $v/1024}")"
    else
        printf "%d bit/s\n" "$v"
    fi
}

printf "Ingress: "
format_rate "$RX_BPS"
printf "Egress:  "
format_rate "$TX_BPS"
printf "\n"
