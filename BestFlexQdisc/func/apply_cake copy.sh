apply_cake() {
    DL=$1
    UL=$2

    # Upload (egress)
    tc qdisc replace dev "$INTERFACE" root cake bandwidth ${UL}kbit \
        besteffort triple-isolate rtt 100ms

    # Ensure ingress exists
    tc qdisc show dev "$INTERFACE" | grep -q "ingress ffff:" || \
        tc qdisc add dev "$INTERFACE" handle ffff: ingress

    # Ensure redirect exists
    tc filter show dev "$INTERFACE" | grep -q "mirred" || \
        tc filter add dev "$INTERFACE" parent ffff: \
            protocol all u32 match u32 0 0 \
            action mirred egress redirect dev "ifb_${INTERFACE}"

    # Download (ingress)
    tc qdisc replace dev "ifb_${INTERFACE}" root cake bandwidth ${DL}kbit \
        besteffort triple-isolate rtt 100ms
}
