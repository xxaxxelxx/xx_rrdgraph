#!/bin/bash
CUSTOMER=$1

# checking the environment
LINKED_CONTAINER=$(env | grep '_ENV_' | head -n 1 | awk '{print $1}' | sed 's/_ENV_.*//')
LB_HOST="$(cat /etc/hosts | grep -iw ${LINKED_CONTAINER} | awk '{print $1}')"



./collect.sh $LB_HOST $RRD_LOOP $CUSTOMER

#bash

exit
