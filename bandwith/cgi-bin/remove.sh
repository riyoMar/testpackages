#!/bin/sh

echo "Stopping flex-qdisc..."

/etc/init.d/flex-qdisc stop
/etc/init.d/flex-qdisc disable 2>/dev/null

# rm -f /etc/flex-qdisc/flex-qdisc
rm -f /tmp/flex-qdisc.state

# rmdir /etc/flex-qdisc 2>/dev/null

rm -f /etc/init.d/flex-qdisc
rm -rf /etc/flex-qdisc
# rm -f /etc/flex-qdisc/remove

echo "flex-qdisc successfully removed."