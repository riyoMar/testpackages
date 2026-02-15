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