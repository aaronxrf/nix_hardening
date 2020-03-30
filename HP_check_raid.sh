#!/bin/bash
PATH=/usr/sbin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DISPLAY=:0.0
clientname='NAME'
#shis atmetis tikai pirmo adresi del -m1 !
myipvar="$(cat /etc/network/interfaces | grep address | grep -oh -m1 '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')"

if [[ $(hpacucli ctrl all show config | grep -oh -m1 'Failed') = "Failed" ]] ;
        then hpacucli ctrl all show config | mail -s "Problemas ar RAID: $clientname! `echo host:$HOSTNAME` IP:$myipvar" example@example.com
        else hpacucli ctrl all show config
fi
