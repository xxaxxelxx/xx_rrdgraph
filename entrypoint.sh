#!/bin/bash
CUSTOMER=$1

cp -f *.css /customer/

./paint.sh $LOOP $CUSTOMER $GROUPMARKER

exit
