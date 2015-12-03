#!/bin/bash
LOOP=$1
CUSTOMER=$2
test -z $LOOP && exit;
test -z $CUSTOMER && exit;

# COLORS ##############################################################################
#		       RED    ORANGE YELLOW DGREEN GREEN  BLUE   PINK   VIOLET PURPLE #	
A_COLOR_DARK=(  000000 CC3118 CC7016 C9B215 8FBC8F 24BC14 1598C3 B415C7 C71585 4D18E4 )
A_COLOR_LIGHT=( 000000 EA644A EC9D48 ECD748 3CB371 54EC48 48C4EC DE48EC FF1493 7648EC )
#######################################################################################
PANGO_SPACE='&#32;'
DISPLAY_TIME_LIST="1d 1w 5w 1y"
if [ "x$CUSTOMER" == "xadmin" ]; then
    while true; do
	    for RRDFILE in /customer/$CUSTOMER/_*.rrd; do
		test -r $RRDFILE || continue
		RRDFILE_BNAME="$(basename $RRDFILE)"
		RRDFILE_BNAME_BODY="${RRDFILE_BNAME%*\.rrd}"
		MACHINE_IP="$(echo $RRDFILE_BNAME_BODY | sed 's|_||' | sed 's|\-|\.|g')"
		for DISPLAY_TIME in $DISPLAY_TIME_LIST; do
		    rrdtool graph /customer/$CUSTOMER/$RRDFILE_BNAME_BODY.${DISPLAY_TIME}.png --slope-mode \
			--font DEFAULT:7: \
			--title "$MACHINE_IP // CPU load" \
			--watermark " $MACHINE_IP @ $(date) " \
			-h 200 -w 800 \
			--rigid \
			--upper-limit 100 \
			--pango-markup \
			-c CANVAS#000000 -c BACK#000000 -c FONT#FFFFFF \
			--end now --start end-${DISPLAY_TIME} \
			--vertical-label "CPU load in %" \
			DEF:cpuload=$RRDFILE:cpuload:MAX \
			AREA:cpuload#${A_COLOR_LIGHT[1]}:"cpu load in %" \
			VDEF:cpuloadmax=cpuload,MAXIMUM VDEF:cpuloavg=cpuload,AVERAGE VDEF:cpuloadmin=cpuload,MINIMUM \
			GPRINT:cpuloadmax:MAXIMUM${PANGO_SPACE}%6.0lf${PANGO_SPACE}%% GPRINT:cpuloadavg:AVERAGE${PANGO_SPACE}%6.0lf${PANGO_SPACE}%% GPRINT:cpuloadmin:MINIMUM${PANGO_SPACE}%6.0lf${PANGO_SPACE}%% \
			LINE1:cpuload#${A_COLOR_DARK[1]}:
		done
	    done
	sleep $LOOP
    done
else
    while true; do
	sleep $LOOP
    done
fi

exit
################################################################################################################################

#if [ "x$CUSTOMER" == "xadmin" ]; then
#    while true; do
#	OIFS=$IFS; IFS=$'\n'; A_MACHINES=($(curl --connect-timeout 3 -s "http://$LB_HOST/listmachines.php")); IFS=$OIFS
#	for MACHINE in ${A_MACHINES[@]}; do
#	    OIFS=$IFS; IFS='|'; A_MACHINE_DATA=($(echo "$MACHINE")); IFS=$OIFS
#	    IP=${A_MACHINE_DATA[0]}
#	    C_IP=$(echo $IP | sed 's|\.|\-|g')
#	    C_BW=${A_MACHINE_DATA[1]}
#	    C_BWLOAD=${A_MACHINE_DATA[2]}
#	    C_LOAD=${A_MACHINE_DATA[3]}
#	    RRDFILE="/customer/$CUSTOMER/_$C_IP.rrd"
#	    test -f $RRDFILE || (
#		ITEMS_DAY=$(( $((2 * 24 * 60 * 60)) / $(( $RRD_LOOP * 1 )) ))
#		ITEMS_WEEK=$(( $((8 * 24 * 60 * 60)) / $(( $RRD_LOOP * 4 )) ))
#		ITEMS_MONTH=$(( $((32 * 24 * 60 * 60)) / $(( $RRD_LOOP * 12 )) ))
#		ITEMS_YEAR=$(( $((366 * 24 * 60 * 60)) / $(( $RRD_LOOP * 100 )) ))
#		rrdtool create $RRDFILE \
#		--step $RRD_LOOP \
#		DS:bw:GAUGE:$(($RRD_LOOP*2)):U:U \
#		DS:bwlimit:GAUGE:$(($RRD_LOOP*2)):U:U \
#		DS:cpuload:GAUGE:$(($RRD_LOOP*2)):U:U \
#		RRA:MAX:0.5:1:$ITEMS_DAY \
#		RRA:MAX:0.5:4:$ITEMS_WEEK \
#		RRA:MAX:0.5:12:$ITEMS_MONTH \
#		RRA:MAX:0.5:100:$ITEMS_YEAR
#	    )
#	    rrdtool update $RRDFILE N:$C_BW:$C_BWLOAD:$C_LOAD
#	done
#	sleep $RRD_LOOP
#    done
#else
#    while true; do
#	OIFS=$IFS; IFS=$'\n'; A_MOUNTPOINTS=($(curl --connect-timeout 3 -s "http://$LB_HOST/listmountpoints.php?mnt=$CUSTOMER")); IFS=$OIFS
#	for MNT in ${A_MOUNTPOINTS[@]}; do
#	    C_VALUE=$(curl --connect-timeout 3 -s "http://$LB_HOST/listeners.php?mnt=$MNT")
#	    C_MNT=$(echo $MNT | sed 's|^/||' | sed 's|\.|\_|g')
#	    RRDFILE="/customer/$CUSTOMER/_$C_MNT.rrd"
#	    test -f $RRDFILE || (
#		ITEMS_DAY=$(( $((2 * 24 * 60 * 60)) / $(( $RRD_LOOP * 1 )) ))
#		ITEMS_WEEK=$(( $((8 * 24 * 60 * 60)) / $(( $RRD_LOOP * 4 )) ))
#		ITEMS_MONTH=$(( $((32 * 24 * 60 * 60)) / $(( $RRD_LOOP * 12 )) ))
#		ITEMS_YEAR=$(( $((366 * 24 * 60 * 60)) / $(( $RRD_LOOP * 100 )) ))
#		rrdtool create $RRDFILE \
#		--step $RRD_LOOP \
#		DS:$C_MNT:GAUGE:$(($RRD_LOOP*2)):U:U \
#		RRA:MAX:0.5:1:$ITEMS_DAY \
#		RRA:MAX:0.5:4:$ITEMS_WEEK \
#		RRA:MAX:0.5:12:$ITEMS_MONTH \
#		RRA:MAX:0.5:100:$ITEMS_YEAR
#	    )
#	    rrdtool update $RRDFILE N:$C_VALUE
#	done
#	sleep $RRD_LOOP
#    done
#fi
#exit



