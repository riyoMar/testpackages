#!/bin/sh

IFACE="phy0-sta0"
IFB="ifb4phy0-sta0"

# $1 = measurement interval in seconds
INTERVAL=${1:-3}

# Load IFB module once
modprobe ifb

# Create IFB if it doesn't exist
ip link show ${IFB} >/dev/null 2>&1 || ip link add ${IFB} type ifb
ip link set ${IFB} up

# Function to format rate
format_rate() {
    v=$1
    if [ "$v" -ge 1048576 ]; then
        printf "%.2f Mbit/s" "$(awk "BEGIN{print $v/1048576}")"
    elif [ "$v" -ge 1024 ]; then
        printf "%.2f Kbit/s" "$(awk "BEGIN{print $v/1024}")"
    else
        printf "%d bit/s" "$v"
    fi
}

# Function to read /proc/net/dev
rx() { awk -v IF="$IFACE" '$1 == IF ":" {print $2}' /proc/net/dev; }
tx() { awk -v IF="$IFACE" '$1 == IF ":" {print $10}' /proc/net/dev; }

# Cleanup old qdiscs before starting loop
tc qdisc del dev ${IFACE} root 2>/dev/null
tc qdisc del dev ${IFACE} ingress 2>/dev/null
tc qdisc del dev ${IFB} root 2>/dev/null

# Infinite loop
while true; do
    # --- Measure traffic over INTERVAL ---
    RX1=$(rx)
    TX1=$(tx)

    sleep $INTERVAL

    RX2=$(rx)
    TX2=$(tx)

    RX_BPS=$(( (RX2 - RX1) * 8 / INTERVAL ))
    TX_BPS=$(( (TX2 - TX1) * 8 / INTERVAL ))

    printf "\nMeasured over %d second(s):\n" "$INTERVAL"
    printf "Ingress (download): %s\n" "$(format_rate $RX_BPS)"
    printf "Egress  (upload):   %s\n" "$(format_rate $TX_BPS)"

    # --- Remove previous qdiscs ---
    tc qdisc del dev ${IFACE} root 2>/dev/null
    tc qdisc del dev ${IFACE} ingress 2>/dev/null
    tc qdisc del dev ${IFB} root 2>/dev/null

    # --- Apply CAKE with measured bandwidth ---
    # EGRESS
    tc qdisc add dev ${IFACE} root cake \
      bandwidth ${TX_BPS}bps \
      besteffort \
      triple-isolate \
      nonat \
      nowash \
      no-ack-filter \
      split-gso \
      rtt 100ms \
      raw overhead 0

    # INGRESS REDIRECT
    tc qdisc add dev ${IFACE} handle ffff: ingress
    tc filter add dev ${IFACE} parent ffff: \
      protocol all u32 match u32 0 0 \
      action mirred egress redirect dev ${IFB}

    # INGRESS
    tc qdisc add dev ${IFB} root cake \
      bandwidth ${RX_BPS}bps \
      besteffort \
      triple-isolate \
      nonat \
      wash \
      no-ack-filter \
      split-gso \
      rtt 100ms \
      raw overhead 0

    printf "CAKE applied using measured bandwidth.\n"
done
