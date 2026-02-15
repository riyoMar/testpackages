rx() {
    awk -v IF="$IFACE" '$1 == IF ":" {print $2}' /proc/net/dev
}