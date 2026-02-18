tx() {
    awk -v INTERFACE="$INTERFACE" '$1 == INTERFACE ":" {print $10}' /proc/net/dev
}