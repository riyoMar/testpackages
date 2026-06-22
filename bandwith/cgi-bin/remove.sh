#!/bin/sh

echo "Stopping flex-qdisc..."

/etc/init.d/flex-qdisc stop
/etc/init.d/flex-qdisc disable 2>/dev/null

rm -f /etc/init.d/flex-qdisc
rm -rf /etc/flex-qdisc

echo "flex-qdisc successfully removed!"
echo