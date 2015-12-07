#!/bin/bash
LOOP=$1
CUSTOMER=$2
OIFS=$IFS; IFS=$'|'; A_GROUPMARKERS=($(echo "$3")); IFS=$OIFS
A_GROUPMARKERS+=('_')

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
INDEXTIMEMODE="1d"
TOTALSTRING="Total"

function indexer() {
CUSTOMER=$1
TIMEMODELINE="$( for TMODE in $DISPLAY_TIME_LIST; do echo -n "<a href=$TMODE.html>$TMODE</a>"; done)"

for TIMEMODE in $DISPLAY_TIME_LIST; do
    BODY=""
    HEADER=$(cat html.header | \
	sed "s|<CUSTOMER>|$CUSTOMER|g" | \
	sed "s|<TIMEMODELINE>|$TIMEMODELINE|g" \
	)
    FOOTER=$(cat html.footer | \
	sed "s|<DATE>|$(date)|g" | \
	sed "s|<COPYRIGHT>|MIT License|g" \
	)
    for PNGFILE in /customer/$CUSTOMER/*.$TIMEMODE.png; do
	BODY="$BODY<p><img src=\"$(basename $PNGFILE)\">"
    done

    echo "$HEADER" > /customer/$CUSTOMER/$TIMEMODE.html
    echo "$BODY" >> /customer/$CUSTOMER/$TIMEMODE.html
    echo "$FOOTER" >> /customer/$CUSTOMER/$TIMEMODE.html
    if [ "x$TIMEMODE" == "x$INDEXTIMEMODE" ]; then
	cp -f /customer/$CUSTOMER/$TIMEMODE.html /customer/$CUSTOMER/index.html
    fi
done

}


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
	LIST_PROCESSED=""
	GROUPMARKER=""
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
	# create the lines
	for GROUPMARKER in ${A_GROUPMARKERS[@]}; do
	    DEFLINE="";CDEFLINE="";MOUNT_ID_PREV="";MOUNT_ID="";AREALINE="";OUTLINE="";NUM=0
	    TESTLINE="";TNUM=0
	    for RRDFILE in /customer/$CUSTOMER/*${GROUPMARKER}*.rrd; do
		test -r $RRDFILE || continue
		NUM=$(($NUM + 1))
		TNUM=$(($TNUM + 21))
		RRDFILE_BNAME="$(basename $RRDFILE)"
		echo "$LIST_PROCESSED" | grep -w "$RRDFILE_BNAME" > /dev/null && continue
		LIST_PROCESSED="$LIST_PROCESSED $RRDFILE_BNAME"
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
		TOTALSPACELEN=$(($MAXPRINTLEN - ${#TOTALSTRING}))
		TOTALSPACE="$(for a in `seq $TOTALSPACELEN`; do echo -n '&#32;'; done)"
		rrdtool graph /customer/$CUSTOMER/$CUSTOMER.$GROUPMARKER.${DISPLAY_TIME}.png --slope-mode \
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
		    $OUTLINE \
		    COMMENT:"  ${TOTALSTRING}${TOTALSPACE}" \
		    VDEF:allmax=${MOUNT_ID}show,MAXIMUM VDEF:allmin=${MOUNT_ID}show,MINIMUM VDEF:allavg=${MOUNT_ID}show,AVERAGE GPRINT:allmax:"MAX\:%6.0lf" GPRINT:allavg:"AVG\:%6.0lf" GPRINT:allmin:"MIN\:%6.0lf\c"
	    done
	done
	indexer $CUSTOMER
	sleep $LOOP
    done
fi

exit


