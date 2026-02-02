#!/bin/sh

IFACE="phy0-sta0"
IFB="ifb4phy0-sta0"

tc qdisc del dev ${IFACE} root 2>/dev/null
tc qdisc del dev ${IFACE} ingress 2>/dev/null
tc qdisc del dev ${IFB} root 2>/dev/null

ip link set ${IFB} down 2>/dev/null
ip link del ${IFB} 2>/dev/null
