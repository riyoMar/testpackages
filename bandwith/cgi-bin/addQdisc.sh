#!/bin/sh

IFACE="phy0-sta0"
IFB="ifb4phy0-sta0"

DOWN="$1"
UP="$2"

# DOWN="85Mbit"
# UP="10Mbit"

# Load IFB support
modprobe ifb

# Create IFB device (SQM-style name)
ip link add ${IFB} type ifb 2>/dev/null
ip link set ${IFB} up

# Clear existing qdiscs (safe restart)
tc qdisc del dev ${IFACE} root 2>/dev/null
tc qdisc del dev ${IFACE} ingress 2>/dev/null
tc qdisc del dev ${IFB} root 2>/dev/null

# ----- EGRESS (upload) -----
tc qdisc add dev ${IFACE} root cake \
  bandwidth ${UP} \
  besteffort \
  triple-isolate \
  nonat \
  nowash \
  no-ack-filter \
  split-gso \
  rtt 100ms \
  raw overhead 0

# ----- INGRESS REDIRECT -----
tc qdisc add dev ${IFACE} handle ffff: ingress

tc filter add dev ${IFACE} parent ffff: \
  protocol all u32 match u32 0 0 \
  action mirred egress redirect dev ${IFB}

# ----- INGRESS (download) -----
tc qdisc add dev ${IFB} root cake \
  bandwidth ${DOWN} \
  besteffort \
  triple-isolate \
  nonat \
  wash \
  no-ack-filter \
  split-gso \
  rtt 100ms \
  raw overhead 0
