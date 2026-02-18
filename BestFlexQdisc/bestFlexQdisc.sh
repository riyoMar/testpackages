#!/bin/sh

# parameters
INTERFACE=$1
# IFB
# TIMES=$2
DIFF_PERCENTAGE=$2
# CUT_PERCENTAGE
MIN_RX=$3
MIN_TX=$4

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
# SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# import functions
. "$SCRIPT_DIR/func/rx.sh"
. "$SCRIPT_DIR/func/tx.sh"
. "$SCRIPT_DIR/func/measure_kbps.sh"
. "$SCRIPT_DIR/func/apply_cake.sh"
. "$SCRIPT_DIR/func/diff_update.sh"

modprobe ifb 2>/dev/null
ip link show "ifb_${INTERFACE}" >/dev/null 2>&1 || ip link add "ifb_${INTERFACE}" type ifb
ip link set "ifb_${INTERFACE}" up

while true; do
    diff_update "$DIFF_PERCENTAGE"
done
