#!/bin/bash
LOOP=$1
CUSTOMER=$2
LOOP=300
CUSTOMER=bbradio
test -z $LOOP && exit;
test -z $CUSTOMER && exit;

# COLORS ##############################################################################
#		       1      2      3      4      5      6      7      8      8      #
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
		    rrdtool graph /customer/$CUSTOMER/$RRDFILE_BNAME_BODY.cpuload.${DISPLAY_TIME}.png --slope-mode \
			--font DEFAULT:7: \
			--title "$MACHINE_IP // CPU load" \
			--watermark " $MACHINE_IP @ $(date) " \
			-h 200 -w 800 \
			--rigid \
			--pango-markup \
			--upper-limit 100 \
			-c CANVAS#000000 -c BACK#000000 -c FONT#FFFFFF \
			--end now --start end-${DISPLAY_TIME} \
			--vertical-label "CPU load in %" \
			DEF:cpuload=$RRDFILE:cpuload:MAX \
			AREA:cpuload#${A_COLOR_LIGHT[1]}:"cpu load in %" \
			VDEF:cpuloadmax=cpuload,MAXIMUM VDEF:cpuloadavg=cpuload,AVERAGE VDEF:cpuloadmin=cpuload,MINIMUM \
			GPRINT:cpuloadmax:"%6.0lf%S%% MAX" GPRINT:cpuloadavg:"%6.0lf%S%% AVG" GPRINT:cpuloadmin:"%6.0lf%S%% MIN\\c" \
			LINE1:cpuload#${A_COLOR_DARK[5]}:
		    rrdtool graph /customer/$CUSTOMER/$RRDFILE_BNAME_BODY.bwload.${DISPLAY_TIME}.png --slope-mode \
			--font DEFAULT:7: \
			--title "$MACHINE_IP // Bandwidth load" \
			--watermark " $MACHINE_IP @ $(date) " \
			-h 200 -w 800 \
			--rigid \
			--pango-markup \
			-c CANVAS#000000 -c BACK#000000 -c FONT#FFFFFF \
			--end now --start end-${DISPLAY_TIME} \
			--vertical-label "Bandwidth load in kbps" \
			--alt-autoscale-max \
			DEF:bw=$RRDFILE:bw:MAX \
			DEF:bwlimit=$RRDFILE:bwlimit:MAX \
			AREA:bw#${A_COLOR_LIGHT[5]}:"Bandwidth load in kbps" \
			VDEF:bwmax=bw,MAXIMUM VDEF:bwavg=bw,AVERAGE VDEF:bwmin=bw,MINIMUM \
			GPRINT:bwmax:"%6.0lf kbps MAX" GPRINT:bwavg:"%6.0lf kbps AVG" GPRINT:bwmin:"%6.0lf kbps MIN\\c" \
			LINE1:bw#${A_COLOR_DARK[5]}: \
			LINE1:bwlimit#${A_COLOR_DARK[1]}:
		done
	    done
	sleep $LOOP
    done
else
    while true; do
	# create the lines
	DEFLINE="";CDEFLINE="";MOUNT_ID_PREV="";MOUNT_ID="";AREALINE="";OUTLINE="";NUM=0;TESTLINE="";TNUM=0
	MAXPRINTLEN=0
	for RRDFILE in /customer/$CUSTOMER/_*.rrd; do
	    test -r $RRDFILE || continue
	    RRDFILE_BNAME="$(basename $RRDFILE)"
	    RRDFILE_BNAME_BODY="${RRDFILE_BNAME%*\.rrd}"
	    MOUNT_PRINT="$(echo $RRDFILE_BNAME_BODY | sed 's|^_||' | sed 's|\_|\.|g')"
	    if [ ${#MOUNT_PRINT} -gt $MAXPRINTLEN ]; then
		MAXPRINTLEN=${#MOUNT_PRINT}
	    fi
	done
	for RRDFILE in /customer/$CUSTOMER/_*.rrd; do
	    NUM=$(($NUM + 1))
	    TNUM=$(($TNUM + 21))
	    test -r $RRDFILE || continue
	    RRDFILE_BNAME="$(basename $RRDFILE)"
	    RRDFILE_BNAME_BODY="${RRDFILE_BNAME%*\.rrd}"
	    MOUNT_ID_PREV="$MOUNT_ID"
	    MOUNT_ID="$(echo $RRDFILE_BNAME_BODY | sed 's|^_||')"
	    MOUNT_PRINT="$(echo $RRDFILE_BNAME_BODY | sed 's|^_||' | sed 's|\_|\.|g')"
	    PADDEDSPACELEN=$(($MAXPRINTLEN - ${#MOUNT_PRINT}))
	    PADDEDSPACE="$(for a in `seq $PADDEDSPACELEN`; do echo -n '&#32;'; done)"
	    
	    echo "$MOUNT_ID" | grep '\-ch' > /dev/null
	    if [ $? -ne 0 ]; then
		echo "def lining simulcats..."
		DEFLINE="$DEFLINE DEF:${MOUNT_ID}=${RRDFILE}:${MOUNT_ID}:MAX"
		TESTLINE="$TESTLINE CDEF:${MOUNT_ID}test=${MOUNT_ID},$TNUM,+"
		if [ "x$MOUNT_ID_PREV" == "x" ]; then
		    CDEFLINE="$CDEFLINE CDEF:${MOUNT_ID}show=${MOUNT_ID}test"
		else
		    CDEFLINE="$CDEFLINE CDEF:${MOUNT_ID}show=${MOUNT_ID_PREV}show,${MOUNT_ID}test,+"
		fi
		echo "area lining simulcats..."
		AREALINE="$AREALINE AREA:${MOUNT_ID}test#${A_COLOR_LIGHT[$NUM]}:${MOUNT_PRINT}${PADDEDSPACE}:STACK VDEF:${MOUNT_ID}max=${MOUNT_ID}test,MAXIMUM VDEF:${MOUNT_ID}min=${MOUNT_ID}test,MINIMUM VDEF:${MOUNT_ID}avg=${MOUNT_ID}test,AVERAGE GPRINT:${MOUNT_ID}max:MAX\:%6.0lf GPRINT:${MOUNT_ID}avg:AVG\:%6.0lf GPRINT:${MOUNT_ID}min:MIN\:%6.0lf\\c"
		OUTLINE="$OUTLINE LINE1:${MOUNT_ID}show#${A_COLOR_DARK[$NUM]}:"
	    else
		    echo "lining channels..."
	    fi
	done
	# create the graph
	for DISPLAY_TIME in $DISPLAY_TIME_LIST; do		    
	    rrdtool graph /customer/$CUSTOMER/$CUSTOMER.simulcast.${DISPLAY_TIME}.png --slope-mode \
		--font DEFAULT:7: \
		--title "$CUSTOMER // Simulcast listeners" \
		--watermark " $CUSTOMER // simulcast @ $(date) " \
		-h 200 -w 800 \
		--rigid \
		--alt-autoscale-max \
		--lower-limit 0 \
		--pango-markup \
		-c CANVAS#000000 -c BACK#000000 -c FONT#FFFFFF \
		--end now --start end-${DISPLAY_TIME} \
		--vertical-label "listeners" \
		$DEFLINE \
		$TESTLINE \
		$CDEFLINE \
		$AREALINE \
		$OUTLINE
	done
	sleep $LOOP
    done
fi
#			--pango-markup \
#			GPRINT:cpuloadmax:MAX%6.0lf%%%S GPRINT:cpuloadavg:AVG:%6.0lf%%%S GPRINT:cpuloadmin:MIN%6.0lf%%%S \
#			GPRINT:cpuloadmax:MAX%6.0lf%S%% \

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



