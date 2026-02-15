tx() {
    awk -v IF="$IFACE" '$1 == IF ":" {print $10}' /proc/net/dev
}