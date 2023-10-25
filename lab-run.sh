#!/bin/bash

kubekeep -k javahttp

sleep 25

./port-forward.sh javahttptest &

lab-client -javahttp

###

kubekeep -k javagrpc

sleep 25

./port-forward.sh javagrpctest &

lab-client -javagrpc

###

kubekeep -k gohttp

sleep 25

./port-forward.sh gohttptest &

lab-client -gohttp

###

#kubekeep -k gogrpc

#sleep 25

#./port-forward.sh gogrpctest &

#lab-client -gogrpc

