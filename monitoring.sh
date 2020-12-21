#!/bin/bash

if [ -f monitoring.conf ]; then 
        SLEEPTIME=$( cat monitoring.conf | grep "^SLEEPTIME" | awk -F"=" '{ print $2 }' );
        SLEEPPROC=$( cat monitoring.conf | grep "^SLEEPPROC" | awk -F"=" '{ print $2 }' );
else
        echo "SLEEPTIME=5" > monitoring.conf;
        echo "SLEEPPROC=10" >> monitoring.conf;
        SLEEPTIME=5;
        SLEEPPROC=10;
fi

echo "Controllo preliminare..."
INNMAP=$( apt list nmap | grep installato | wc -l )
if [ "$INNMAP" != "1" ]; then echo "Installo NMAP..."; apt install nmap; fi
INCURL=$( apt list nmap | grep installato | wc -l )
if [ "$INCURL" != "1" ]; then echo "Installo CURL..."; apt install nmap; fi

red='\e[0;31m'
RED='\e[1;31m'
blue='\e[0;34m'
BLUE='\e[1;34m'
cyan='\e[0;36m'
CYAN='\e[1;36m'
GREEN='\E[2;32m'
YELLOW='\e[93m'
BLINK='\e[5m'
NC='\e[0m'
BGREDWHITE='\e[101m'
TOTCHECK=1
clear

check () {

        COUNT=1
        TOTCOUNT=$( cat monitoring.hosts | grep -v "^#" | wc -l )

        echo -e "$YELLOW ============================================================================ $TOTCHECK ===================================================================================="

        while [ $COUNT -le $TOTCOUNT ]; do
                ACTTIPO=$( cat monitoring.hosts | grep -v "^#" | sed -n $COUNT\p | awk -F";" '{ print $1 }' )
                ACTDESCR=$( cat monitoring.hosts | grep -v "^#" | sed -n $COUNT\p | awk -F";" '{ print $2 }' )
                ACTHOST=$( cat monitoring.hosts | grep -v "^#" | sed -n $COUNT\p | awk -F";" '{ print $3 }' )
                ACTOPZIONE=$( cat monitoring.hosts | grep -v "^#" | sed -n $COUNT\p | awk -F";" '{ print $4 }' )

                if [ "$ACTTIPO" == "iochtml" ]; then
                        REPLY=$( curl -s $ACTHOST | grep "iocisono" | wc -l );
                fi

                if [ "$ACTTIPO" == "ping" ]; then
                        REPLY=$( ping -c 1 -W 2 $ACTHOST | grep "1 received" | wc -l );
                fi

                if [ "$ACTTIPO" == "porta" ]; then
                        REPLY=$( nmap -p $ACTOPZIONE $ACTHOST | grep "open" | wc -l );
                fi

                if [ "$ACTTIPO" == "strhtml" ]; then
                        REPLY=$( curl -s $ACTHOST | grep "$ACTOPZIONE" | wc -l );
                fi

                if [ "$REPLY" == "1" ]; then echo -e "$GREEN [ Host UP ]        $YELLOW $ACTDESCR $CYAN         Tipologia controllo $GREEN $ACTTIPO     $CYAN Verifica dell'host $GREEN $ACTHOST $NC";
                else echo -e "$RED$BLINK [ Host DOWN ]  $NC$BGREDWHITE $ACTDESCR $NC$CYAN$BLINK         Tipologia controllo $RED $ACTTIPO       $CYAN Verifica dell'host $RED $ACTHOST $NC"; sleep 1; fi

                let COUNT=COUNT+1
                if [ $TOTCHECK -gt 1 ]; then sleep $SLEEPTIME; fi
        done
        sleep $SLEEPPROC
        let TOTCHECK=TOTCHECK+1
        check
}

check
exit 0
