#!/bin/bash
LOOP=$1
CUSTOMER=$2
OIFS=$IFS; IFS=$'+'; A_GROUPMARKERS=($(echo "$3")); IFS=$OIFS
A_GROUPMARKERS+=('_')


#LOOP=300
#CUSTOMER=bbradio
test -z $LOOP && exit;
test -z $CUSTOMER && exit;

# COLORS ##############################################################################
#		       1      2      3      4      5      6      7      8      8      #
#		       RED    ORANGE YELLOW DGREEN GREEN  BLUE   PINK   VIOLET PURPLE #	
#A_COLOR_DARK=(  000000 CC3118 CC7016 C9B215 8FBC8F 24BC14 1598C3 B415C7 C71585 4D18E4 )
#A_COLOR_LIGHT=( 000000 EA644A EC9D48 ECD748 3CB371 54EC48 48C4EC DE48EC FF1493 7648EC )
A_COLOR_DARK=( 000000 FFFF00 FFD700 FFA500 FF8C00 FF7F50 FF4500 FF0000 DC143C FF69B4 FF1493 FF00FF DA70D6 9370DB 663399 00BFFF 1E90FF 0000FF 00008B 7FFF00 00FF00 228B22 6B8E23 )
A_COLOR_LIGHT=( 000000 FFFF00 FFD700 FFA500 FF8C00 FF7F50 FF4500 FF0000 DC143C FF69B4 FF1493 FF00FF DA70D6 9370DB 663399 00BFFF 1E90FF 0000FF 00008B 7FFF00 00FF00 228B22 6B8E23 )
#######################################################################################
PANGO_SPACE='&#32;'
DISPLAY_TIME_LIST="1d 1w 5w 1y"
INDEXTIMEMODE="1d"
TOTALSTRING="Total"

function indexer() {
CUSTOMER=$1
TIMEMODELINE="$( for TMODE in $DISPLAY_TIME_LIST; do echo -n "<a href=$TMODE.html>$TMODE</a>\&nbsp;"; done)"

for TIMEMODE in $DISPLAY_TIME_LIST; do
    BODY=""
    TITLE="$(echo $CUSTOMER | tr [[:lower:]] [[:upper:]]) STATUS"
    HEADER=$(cat html.header | \
	sed "s|<TITLE>|$TITLE|g" | \
	sed "s|<CUSTOMER>|$CUSTOMER|g" | \
	sed "s|<TIMEMODELINE>|$TIMEMODELINE|g" \
	)
    if [ "x$CUSTOMER" != "xadmin" ]; then
	HEADER="$HEADER <a href='logs/'>LOGS</a><p><hr>"
    fi
    FOOTER=$(cat html.footer | \
	sed "s|<DATE>|$(date)|g" | \
	sed "s|<COPYRIGHT>|<a href=https://opensource.org/licenses/MIT>MIT License</a>|g" \
	)
    if [ "x$CUSTOMER" == "xadmin" ]; then
	for PNGFILE in /customer/$CUSTOMER/_ALL.*.$TIMEMODE.png; do
	    MACHINE_ID_OLD="$MACHINE_ID"
	    MACHINE_ID="${PNGFILE%%\.*}"
	    if [ "x$MACHINE_ID" == "x$MACHINE_ID_OLD" ]; then
		BODY="$BODY <img src=\"$(basename $PNGFILE)\">"
	    else
		BODY="$BODY <p><img src=\"$(basename $PNGFILE)\">"
	    fi
	done	    
	for PNGFILE in /customer/$CUSTOMER/_[[:digit:]]*.$TIMEMODE.png; do
	    MACHINE_ID_OLD="$MACHINE_ID"
	    MACHINE_ID="${PNGFILE%%\.*}"
	    if [ "x$MACHINE_ID" == "x$MACHINE_ID_OLD" ]; then
		BODY="$BODY <img src=\"$(basename $PNGFILE)\">"
	    else
		BODY="$BODY <p><img src=\"$(basename $PNGFILE)\">"
	    fi
	done	    
    else
	for PNGFILE in /customer/$CUSTOMER/*.$TIMEMODE.png; do
	    BODY="$BODY<p><img src=\"$(basename $PNGFILE)\">"
	done
    fi

    echo "$HEADER" > /customer/$CUSTOMER/$TIMEMODE.html
    echo "$BODY" >> /customer/$CUSTOMER/$TIMEMODE.html
    echo "$FOOTER" >> /customer/$CUSTOMER/$TIMEMODE.html
    if [ "x$TIMEMODE" == "x$INDEXTIMEMODE" ]; then
	cp -f /customer/$CUSTOMER/$TIMEMODE.html /customer/$CUSTOMER/index.html
    fi
    test -r main.css && \
    cp -f main.css /customer/$CUSTOMER/
    test -r $CUSTOMER.css && \
    cp -f $CUSTOMER.css /customer/$CUSTOMER/
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
		    case $DISPLAY_TIME in
			1d)
			    GRIDSTYLE="--x-grid MINUTE:15:HOUR:1:MINUTE:120:0:%R"
			;;
			*)
			    GRIDSTYLE=""
			;;
		    esac
		    if [ "x$RRDFILE_BNAME_BODY" == "x_ALL" ]; then
			rrdtool graph /customer/$CUSTOMER/$RRDFILE_BNAME_BODY.bw.${DISPLAY_TIME}.png --slope-mode \
			    --font DEFAULT:7: \
			    --title "$MACHINE_IP // Bandwidth load" \
			    --watermark " $MACHINE_IP @ $(date) " \
			    -h 200 -w 800 $GRIDSTYLE \
			    --lower-limit 0 \
			    --rigid \
			    --pango-markup \
			    -c CANVAS#000000 -c BACK#000000 -c FONT#FFFFFF \
			    --end now --start end-${DISPLAY_TIME} \
			    --vertical-label "Bandwidth load in bit/s" \
			    --alt-autoscale-max \
			    DEF:bwkbit=$RRDFILE:bw:MAX \
			    CDEF:bw=bwkbit,1000,* \
			    AREA:bw#ff8000:"Bandwidth load" \
			    VDEF:bwcur=bw,LAST VDEF:bwmax=bw,MAXIMUM VDEF:bwavg=bw,AVERAGE VDEF:bwmin=bw,MINIMUM \
			    GPRINT:bwcur:"%6.0lf %Sbit/s CUR" GPRINT:bwmax:"%6.0lf %Sbit/s MAX" GPRINT:bwavg:"%6.0lf %Sbit/s AVG" GPRINT:bwmin:"%6.0lf %Sbit/s MIN\\c" \
			    LINE1:bw#0000FF: > dev/null 2>&1

			rrdtool graph /customer/$CUSTOMER/$RRDFILE_BNAME_BODY.listeners.${DISPLAY_TIME}.png --slope-mode \
			    --font DEFAULT:7: \
			    --title "$MACHINE_IP // Listeners" \
			    --watermark " $MACHINE_IP @ $(date) " \
			    -h 200 -w 800 $GRIDSTYLE \
			    --lower-limit 0 \
			    --rigid \
			    --pango-markup \
			    -c CANVAS#000000 -c BACK#000000 -c FONT#FFFFFF \
			    --end now --start end-${DISPLAY_TIME} \
			    --vertical-label "Listeners" \
			    --alt-autoscale-max \
			    DEF:listeners=$RRDFILE:listeners:MAX \
			    AREA:listeners#ff3399:"Listeners" \
			    VDEF:listcur=listeners,LAST VDEF:listmax=listeners,MAXIMUM VDEF:listavg=listeners,AVERAGE VDEF:listmin=listeners,MINIMUM \
			    GPRINT:listcur:"%6.0lf CUR" GPRINT:listmax:"%6.0lf MAX" GPRINT:listavg:"%6.0lf AVG" GPRINT:listmin:"%6.0lf MIN\\c" \
			    LINE1:listeners#0000FF: > dev/null 2>&1
		    else
			rrdtool graph /customer/$CUSTOMER/$RRDFILE_BNAME_BODY.cpuload.${DISPLAY_TIME}.png --slope-mode \
			    --font DEFAULT:7: \
			    --title "$MACHINE_IP // CPU load" \
			    --watermark " $MACHINE_IP @ $(date) " \
			    -h 200 -w 800 $GRIDSTYLE \
			    --rigid \
			    --pango-markup \
			    --upper-limit 100 \
			    --lower-limit 0 \
			    -c CANVAS#000000 -c BACK#000000 -c FONT#FFFFFF \
			    --end now --start end-${DISPLAY_TIME} \
			    --vertical-label "CPU load in %" \
			    DEF:cpuload=$RRDFILE:cpuload:MAX \
			    AREA:cpuload#0080FF:"cpu load in %" \
			    VDEF:cpuloadcur=cpuload,LAST VDEF:cpuloadmax=cpuload,MAXIMUM VDEF:cpuloadavg=cpuload,AVERAGE VDEF:cpuloadmin=cpuload,MINIMUM \
			    GPRINT:cpuloadcur:"%6.0lf%S%% CUR" GPRINT:cpuloadmax:"%6.0lf%S%% MAX" GPRINT:cpuloadavg:"%6.0lf%S%% AVG" GPRINT:cpuloadmin:"%6.0lf%S%% MIN\\c" \
			    LINE1:cpuload#0000FF: \
			    LINE1:75#FFFFFF77::dashes > dev/null 2>&1

			rrdtool graph /customer/$CUSTOMER/$RRDFILE_BNAME_BODY.bwload.${DISPLAY_TIME}.png --slope-mode \
			    --font DEFAULT:7: \
			    --title "$MACHINE_IP // Bandwidth load" \
			    --watermark " $MACHINE_IP @ $(date) " \
			    -h 200 -w 800 $GRIDSTYLE \
			    --lower-limit 0 \
			    --rigid \
			    --pango-markup \
			    -c CANVAS#000000 -c BACK#000000 -c FONT#FFFFFF \
			    --end now --start end-${DISPLAY_TIME} \
			    --vertical-label "Bandwidth load in bit/s" \
			    --alt-autoscale-max \
			    DEF:bwkbit=$RRDFILE:bw:MAX \
			    DEF:bwkbitlimit=$RRDFILE:bwlimit:MAX \
			    CDEF:bw=bwkbit,1000,* \
			    CDEF:bwlimit=bwkbitlimit,1000,* \
			    AREA:bw#00FF40:"Bandwidth load" \
			    VDEF:bwcur=bw,LAST VDEF:bwmax=bw,MAXIMUM VDEF:bwavg=bw,AVERAGE VDEF:bwmin=bw,MINIMUM \
			    GPRINT:bwcur:"%6.0lf %Sbit/s CUR" GPRINT:bwmax:"%6.0lf %Sbit/s MAX" GPRINT:bwavg:"%6.0lf %Sbit/s AVG" GPRINT:bwmin:"%6.0lf %Sbit/s MIN\\c" \
			    LINE1:bw#0000FF: \
			    LINE1:bwlimit#DC143C:  > dev/null 2>&1
		    fi
		done
	    done
	indexer $CUSTOMER
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
#TEST	    TESTLINE="";TNUM=0
	    for RRDFILE in /customer/$CUSTOMER/*${GROUPMARKER}*.rrd; do
		test -r $RRDFILE || continue
		RRDFILE_BNAME="$(basename $RRDFILE)"
		echo "$LIST_PROCESSED" | grep -w "$RRDFILE_BNAME" > /dev/null && continue
		NUM=$(($NUM + 1))
#TEST		TNUM=$(($TNUM + 21))
		LIST_PROCESSED="$LIST_PROCESSED $RRDFILE_BNAME"
		RRDFILE_BNAME_BODY="${RRDFILE_BNAME%*\.rrd}"
		MOUNT_ID_PREV="$MOUNT_ID"
		MOUNT_ID="$(echo $RRDFILE_BNAME_BODY | sed 's|^_||')"
		MOUNT_PRINT="$(echo $RRDFILE_BNAME_BODY | sed 's|^_||' | sed 's|\_|\.|g')"
		PADDEDSPACELEN=$(($MAXPRINTLEN - ${#MOUNT_PRINT}))
		PADDEDSPACE="$(for a in `seq $PADDEDSPACELEN`; do echo -n '&#32;'; done)"

		DEFLINE="$DEFLINE DEF:${MOUNT_ID}=${RRDFILE}:${MOUNT_ID:0:19}:MAX"
#TEST		TESTLINE="$TESTLINE CDEF:${MOUNT_ID}test=${MOUNT_ID},$TNUM,+"
		if [ "x$MOUNT_ID_PREV" == "x" ]; then
#TEST		    CDEFLINE="$CDEFLINE CDEF:${MOUNT_ID}show=${MOUNT_ID}test"
		    CDEFLINE="$CDEFLINE CDEF:${MOUNT_ID}show=${MOUNT_ID}"
		else
#TEST		    CDEFLINE="$CDEFLINE CDEF:${MOUNT_ID}show=${MOUNT_ID_PREV}show,${MOUNT_ID}test,+"
		    CDEFLINE="$CDEFLINE CDEF:${MOUNT_ID}show=${MOUNT_ID_PREV}show,${MOUNT_ID},+"
		fi
#TEST		AREALINE="$AREALINE AREA:${MOUNT_ID}test#${A_COLOR_LIGHT[$NUM]}:${MOUNT_PRINT}${PADDEDSPACE}:STACK VDEF:${MOUNT_ID}max=${MOUNT_ID}test,MAXIMUM VDEF:${MOUNT_ID}min=${MOUNT_ID}test,MINIMUM VDEF:${MOUNT_ID}avg=${MOUNT_ID}test,AVERAGE GPRINT:${MOUNT_ID}max:MAX\:%6.0lf GPRINT:${MOUNT_ID}avg:AVG\:%6.0lf GPRINT:${MOUNT_ID}min:MIN\:%6.0lf\\c"
		AREALINE="$AREALINE AREA:${MOUNT_ID}#${A_COLOR_LIGHT[$NUM]}:${MOUNT_PRINT}${PADDEDSPACE}:STACK VDEF:${MOUNT_ID}cur=${MOUNT_ID},LAST VDEF:${MOUNT_ID}max=${MOUNT_ID},MAXIMUM VDEF:${MOUNT_ID}min=${MOUNT_ID},MINIMUM VDEF:${MOUNT_ID}avg=${MOUNT_ID},AVERAGE GPRINT:${MOUNT_ID}cur:CUR\:%6.0lf GPRINT:${MOUNT_ID}max:MAX\:%6.0lf GPRINT:${MOUNT_ID}avg:AVG\:%6.0lf GPRINT:${MOUNT_ID}min:MIN\:%6.0lf\\c"
		OUTLINE="$OUTLINE LINE1:${MOUNT_ID}show#000000:"
#		OUTLINE="$OUTLINE LINE1:${MOUNT_ID}show#${A_COLOR_DARK[$NUM]}:"
	    done
	    # create the graph
	    for DISPLAY_TIME in $DISPLAY_TIME_LIST; do		    
		case $DISPLAY_TIME in
		    1d)
			GRIDSTYLE="--x-grid MINUTE:15:HOUR:1:MINUTE:120:0:%R"
		    ;;
		    *)
		        GRIDSTYLE=""
		    ;;
		esac
		TOTALSPACELEN=$(($MAXPRINTLEN - ${#TOTALSTRING}))
		TOTALSPACE="$(for a in `seq $TOTALSPACELEN`; do echo -n '&#32;'; done)"
		rrdtool graph /customer/$CUSTOMER/$CUSTOMER.$GROUPMARKER.${DISPLAY_TIME}.png --slope-mode \
		    --font DEFAULT:7: \
		    --title "$CUSTOMER // Listeners" \
		    --watermark " $CUSTOMER // listeners @ $(date) " \
		    -h 400 -w 800 $GRIDSTYLE \
		    --rigid \
		    --lower-limit 0 \
		    --pango-markup \
		    -c CANVAS#000000 -c BACK#000000 -c FONT#FFFFFF \
		    --end now --start end-${DISPLAY_TIME} \
		    --vertical-label "listeners" \
		    $DEFLINE \
		    $CDEFLINE \
		    $AREALINE \
		    $OUTLINE \
		    LINE1:${MOUNT_ID}show#FFFFFF: \
		    COMMENT:"  ${TOTALSTRING}${TOTALSPACE}" \
		    VDEF:allcur=${MOUNT_ID}show,LAST VDEF:allmax=${MOUNT_ID}show,MAXIMUM VDEF:allmin=${MOUNT_ID}show,MINIMUM VDEF:allavg=${MOUNT_ID}show,AVERAGE GPRINT:allcur:"CUR\:%6.0lf" GPRINT:allmax:"MAX\:%6.0lf" GPRINT:allavg:"AVG\:%6.0lf" GPRINT:allmin:"MIN\:%6.0lf\c" \
		    LINE1:allavg#666666::dashes LINE1:allcur#00FF00::dashes  > dev/null 2>&1
#TEST		    $TESTLINE \
#		    --alt-autoscale-max \
	    done
	done
	indexer $CUSTOMER
	sleep $LOOP
    done
fi

exit


