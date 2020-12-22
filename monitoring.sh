#!/bin/bash

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
        if [ -f monitoring.conf ]; then
                SLEEPTIME=$( cat monitoring.conf | grep "^SLEEPTIME" | awk -F"=" '{ print $2 }' );
                SLEEPPROC=$( cat monitoring.conf | grep "^SLEEPPROC" | awk -F"=" '{ print $2 }' );
        else
                echo "SLEEPTIME=5" > monitoring.conf;
                echo "SLEEPPROC=10" >> monitoring.conf;
                SLEEPTIME=5;
                SLEEPPROC=10;
        fi
        COUNT=1
        TOTCOUNT=$( cat monitoring.hosts | grep -v "^#" | wc -l )

        tput cup 0 0; echo -e "$YELLOW ============================================================================ $TOTCHECK ===================================================================================="
        tput cup 0 25; echo $( date +%c )
        tput cup 0 0; echo -e "$GREEN$BLINK >>> Running... $NC";

        while [ $COUNT -le $TOTCOUNT ]; do
                ACTTIPO=$( cat monitoring.hosts | grep -v "^#" | sed -n $COUNT\p | awk -F";" '{ print $1 }' )
                ACTDESCR=$( cat monitoring.hosts | grep -v "^#" | sed -n $COUNT\p | awk -F";" '{ print $2 }' )
                ACTHOST=$( cat monitoring.hosts | grep -v "^#" | sed -n $COUNT\p | awk -F";" '{ print $3 }' )
                ACTOPZIONE=$( cat monitoring.hosts | grep -v "^#" | sed -n $COUNT\p | awk -F";" '{ print $4 }' )
                let ACTVIDEOLINE=COUNT;
                let ACTVIDEOLINEPRE=ACTVIDEOLINE-1;

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

                if [ "$REPLY" == "1" ]; then 
                        tput cup $ACTVIDEOLINEPRE 0; echo -e "  "
                        tput cup $ACTVIDEOLINE 0; echo -e "$BLINK >$NC"
                        tput cup $ACTVIDEOLINE 2; echo -e "$YELLOW $TOTCHECK"
                        tput cup $ACTVIDEOLINE 6; echo -e "$GREEN [ Host UP ]$NC";
                        tput cup $ACTVIDEOLINE 20; echo -e "$YELLOW $ACTDESCR";
                        tput cup $ACTVIDEOLINE 53; echo -e "$CYAN Tipologia controllo $GREEN $ACTTIPO"
                        tput cup $ACTVIDEOLINE 85; echo -e "$CYAN Verifica dell'host $GREEN $ACTHOST $NC";
                else 
                        tput cup $ACTVIDEOLINEPRE 0; echo -e "  "
                        tput cup $ACTVIDEOLINE 0; echo -e "$BLINK >$NC"
                        tput cup $ACTVIDEOLINE 2; echo -e "$YELLOW $TOTCHECK"
                        tput cup $ACTVIDEOLINE 6; echo -e "$RED$BLINK [Host DOWN]$NC"
                        tput cup $ACTVIDEOLINE 20; echo -e "$NC$BGREDWHITE $ACTDESCR $NC$CYAN$BLINK"
                        tput cup $ACTVIDEOLINE 53; echo -e " Tipologia controllo $RED $ACTTIPO";
                        tput cup $ACTVIDEOLINE 85; echo -e "$CYAN Verifica dell'host $GREEN $ACTHOST $NC";
                fi

                let COUNT=COUNT+1
                if [ $TOTCHECK -gt 1 ]; then 
                        tput cup 0 0; echo -e "$YELLOW$BLINK <<< Sleep...  $NC"; 
                        sleep $SLEEPTIME; 
                        tput cup 0 0; echo -e "$GREEN$BLINK >>> Running... $NC"; 
                fi
        done
        tput cup $ACTVIDEOLINE 0; echo -e "  "
        tput cup 0 0; echo -e "$YELLOW$BLINK <<< Sleep...  $NC";
        sleep $SLEEPPROC; 
        tput cup 0 0; echo -e "$GREEN$BLINK >>> Running... $NC"; 
        let TOTCHECK=TOTCHECK+1
        check
}

check
exit 0
