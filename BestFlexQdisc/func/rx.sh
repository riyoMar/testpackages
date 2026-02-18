rx() {
    awk -v INTERFACE="$INTERFACE" '$1 == INTERFACE ":" {print $2}' /proc/net/dev
}