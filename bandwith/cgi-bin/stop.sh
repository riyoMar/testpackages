#!/bin/sh

IFACE="${1:-phy0-sta0}"
IFB="ifb_${IFACE}"

tc qdisc del dev "${IFACE}" root 2>/dev/null
tc qdisc del dev "${IFACE}" ingress 2>/dev/null
tc qdisc del dev "${IFB}" root 2>/dev/null

ip link set "${IFB}" down 2>/dev/null
ip link del "${IFB}" 2>/dev/null

echo "flex-qdisc stopped on ${IFACE}"