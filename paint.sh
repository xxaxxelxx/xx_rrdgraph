#!/bin/bash
LB_HOST=$1
RRD_LOOP=$2
CUSTOMER=$3
test -z $LB_HOST && exit;
test -z $RRD_LOOP && exit;
test -z $CUSTOMER && exit;

if [ "x$CUSTOMER" == "xadmin" ]; then
    while true; do
	OIFS=$IFS; IFS=$'\n'; A_MACHINES=($(curl --connect-timeout 3 -s "http://$LB_HOST/listmachines.php")); IFS=$OIFS
	for MACHINE in ${A_MACHINES[@]}; do
	    OIFS=$IFS; IFS='|'; A_MACHINE_DATA=($(echo "$MACHINE")); IFS=$OIFS
	    IP=${A_MACHINE_DATA[0]}
	    C_IP=$(echo $IP | sed 's|\.|\-|g')
	    C_BW=${A_MACHINE_DATA[1]}
	    C_BWLOAD=${A_MACHINE_DATA[2]}
	    C_LOAD=${A_MACHINE_DATA[3]}
	    RRDFILE="/customer/$CUSTOMER/_$C_IP.rrd"
	    test -f $RRDFILE || (
		ITEMS_DAY=$(( $((2 * 24 * 60 * 60)) / $(( $RRD_LOOP * 1 )) ))
		ITEMS_WEEK=$(( $((8 * 24 * 60 * 60)) / $(( $RRD_LOOP * 4 )) ))
		ITEMS_MONTH=$(( $((32 * 24 * 60 * 60)) / $(( $RRD_LOOP * 12 )) ))
		ITEMS_YEAR=$(( $((366 * 24 * 60 * 60)) / $(( $RRD_LOOP * 100 )) ))
		rrdtool create $RRDFILE \
		--step $RRD_LOOP \
		DS:bw:GAUGE:$(($RRD_LOOP*2)):U:U \
		DS:bwlimit:GAUGE:$(($RRD_LOOP*2)):U:U \
		DS:cpuload:GAUGE:$(($RRD_LOOP*2)):U:U \
		RRA:MAX:0.5:1:$ITEMS_DAY \
		RRA:MAX:0.5:4:$ITEMS_WEEK \
		RRA:MAX:0.5:12:$ITEMS_MONTH \
		RRA:MAX:0.5:100:$ITEMS_YEAR
	    )
	    rrdtool update $RRDFILE N:$C_BW:$C_BWLOAD:$C_LOAD
	done
	sleep $RRD_LOOP
    done
else
    while true; do
	OIFS=$IFS; IFS=$'\n'; A_MOUNTPOINTS=($(curl --connect-timeout 3 -s "http://$LB_HOST/listmountpoints.php?mnt=$CUSTOMER")); IFS=$OIFS
	for MNT in ${A_MOUNTPOINTS[@]}; do
	    C_VALUE=$(curl --connect-timeout 3 -s "http://$LB_HOST/listeners.php?mnt=$MNT")
	    C_MNT=$(echo $MNT | sed 's|^/||' | sed 's|\.|\_|g')
	    RRDFILE="/customer/$CUSTOMER/_$C_MNT.rrd"
	    test -f $RRDFILE || (
		ITEMS_DAY=$(( $((2 * 24 * 60 * 60)) / $(( $RRD_LOOP * 1 )) ))
		ITEMS_WEEK=$(( $((8 * 24 * 60 * 60)) / $(( $RRD_LOOP * 4 )) ))
		ITEMS_MONTH=$(( $((32 * 24 * 60 * 60)) / $(( $RRD_LOOP * 12 )) ))
		ITEMS_YEAR=$(( $((366 * 24 * 60 * 60)) / $(( $RRD_LOOP * 100 )) ))
		rrdtool create $RRDFILE \
		--step $RRD_LOOP \
		DS:$C_MNT:GAUGE:$(($RRD_LOOP*2)):U:U \
		RRA:MAX:0.5:1:$ITEMS_DAY \
		RRA:MAX:0.5:4:$ITEMS_WEEK \
		RRA:MAX:0.5:12:$ITEMS_MONTH \
		RRA:MAX:0.5:100:$ITEMS_YEAR
	    )
	    rrdtool update $RRDFILE N:$C_VALUE
	done
	sleep $RRD_LOOP
    done
fi
exit



