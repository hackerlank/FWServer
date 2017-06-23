#!/bin/sh
ls
ulimit -c unlimited
ulimit -n 20480

FILE=$0 
FILE=${FILE%.*}
FILE=${FILE##*/}
expath=$FILE
echo $expath
cd ./skynet
ln -sf skynet $expath
./$expath ../config/skynet_gm.config

