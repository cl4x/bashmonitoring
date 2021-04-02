#!/bin/bash

echo "Controllo preliminare..."
INNMAP=$( apt list nmap | grep installato | wc -l )
if [ "$INNMAP" != "1" ]; then echo "Installo NMAP..."; apt install nmap; fi
INCURL=$( apt list nmap | grep installato | wc -l )
if [ "$INCURL" != "1" ]; then echo "Installo CURL..."; apt install curl; fi

MYNAME=$( cat monitoring.conf | grep "^MYNAME" | awk -F"=" '{ print $2 }' );
LOGENABLE=$( cat monitoring.conf | grep "^LOGENABLE" | awk -F"=" '{ print $2 }' );
LOGPATH=$( cat monitoring.conf | grep "^LOGPATH" | awk -F"=" '{ print $2 }' );
TELEGRAMBOTENABLE=$( cat monitoring.conf | grep "^TELEGRAMBOTENABLE" | awk -F"=" '{ print $2 }' );
TELEGRAMAPIBOT=$( cat monitoring.conf | grep "^TELEGRAMAPIBOT" | awk -F"=" '{ print $2 }' );
TELEGRAMCHATID=$( cat monitoring.conf | grep "^TELEGRAMCHATID" | awk -F"=" '{ print $2 }' );


if [ -f monitoring.downstate ]; then rm monitoring.downstate; fi
touch monitoring.downstate


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
                RETRY=$( cat monitoring.conf | grep "^RETRY" | awk -F"=" '{ print $2 }' );
                DAYFROM=$( cat monitoring.conf | grep "^DAYFROM" | awk -F"=" '{ print $2 }' );
                DAYTO=$( cat monitoring.conf | grep "^DAYTO" | awk -F"=" '{ print $2 }' );
        else
                echo "SLEEPTIME=5" > monitoring.conf;
                echo "SLEEPPROC=10" >> monitoring.conf;
                echo "RETRY=2" >> monitoring.conf;
                echo "LOGENABLE=1" >> monitoring.conf;
                echo "LOGPATH=monitoring.log" >> monitoring.conf;
                echo "DAYFROM=7" >> monitoring.conf;
                echo "DAYTO=19" >> monitoring.conf;
                SLEEPTIME=5;
                SLEEPPROC=10;
                RETRY=2;
                LOGENABLE=1;
                LOGPATH="monitorning.log";
        fi
        COUNT=1
        TOTCOUNT=$( cat monitoring.hosts | grep -v "^#" | wc -l )

        tput cup 0 0; echo -e "$YELLOW ============================================================================ $TOTCHECK ===================================================================================="
        tput cup 0 25; echo $( date +%c )
        tput cup 0 0; echo -e "$GREEN$BLINK >>> Running... $NC";

        while [ $COUNT -le $TOTCOUNT ]; do
                ACTNOTIFICA=$( cat monitoring.hosts | grep -v "^#" | sed -n $COUNT\p | awk -F";" '{ print $1 }' )
                ACTTIPO=$( cat monitoring.hosts | grep -v "^#" | sed -n $COUNT\p | awk -F";" '{ print $2 }' )
                ACTDESCR=$( cat monitoring.hosts | grep -v "^#" | sed -n $COUNT\p | awk -F";" '{ print $3 }' )
                ACTHOST=$( cat monitoring.hosts | grep -v "^#" | sed -n $COUNT\p | awk -F";" '{ print $4 }' )
                ACTOPZIONE=$( cat monitoring.hosts | grep -v "^#" | sed -n $COUNT\p | awk -F";" '{ print $5 }' )
                let ACTVIDEOLINE=COUNT;
                let ACTVIDEOLINEPRE=ACTVIDEOLINE-1;

                if [ "$ACTTIPO" == "iochtml" ]; then
                        REPLY=$( curl -s $ACTHOST | grep "iocisono" | wc -l );
                        if [ "$REPLY" != "1" ]; then
                                RETRYCOUNT=1
                                while [ $RETRYCOUNT -le $RETRY ]; do
                                        if [ "$REPLY" != "1" ]; then 
                                                tput cup 0 0; echo -e "$RED$BLINK >>> Retry $RETRYCOUNT    $NC";
                                                REPLY=$( curl -s $ACTHOST | grep "iocisono" | wc -l ); 
                                        fi
                                sleep 2
                                let RETRYCOUNT=RETRYCOUNT+1
                                done;
                        fi;
                fi

                if [ "$ACTTIPO" == "ping" ]; then
                        REPLY=$( ping -c 1 -W 2 $ACTHOST | grep "1 received" | wc -l );
                        if [ "$REPLY" != "1" ]; then
                                RETRYCOUNT=1
                                while [ $RETRYCOUNT -le $RETRY ]; do
                                        if [ "$REPLY" != "1" ]; then
                                                tput cup 0 0; echo -e "$RED$BLINK >>> Retry $RETRYCOUNT    $NC";
                                                REPLY=$( ping -c 1 -W 2 $ACTHOST | grep "1 received" | wc -l );
                                        fi
                                sleep 2
                                let RETRYCOUNT=RETRYCOUNT+1
                                done;
                        fi;
                fi

                if [ "$ACTTIPO" == "porta" ]; then
                        REPLY=$( nmap -n -p $ACTOPZIONE $ACTHOST | grep "open" | wc -l );
                        if [ "$REPLY" != "1" ]; then
                                RETRYCOUNT=1
                                while [ $RETRYCOUNT -le $RETRY ]; do
                                        if [ "$REPLY" != "1" ]; then
                                                tput cup 0 0; echo -e "$RED$BLINK >>> Retry $RETRYCOUNT    $NC";
                                                REPLY=$( nmap -n -p $ACTOPZIONE $ACTHOST | grep "open" | wc -l );
                                        fi
                                sleep 2
                                let RETRYCOUNT=RETRYCOUNT+1
                                done;
                        fi;
                fi

                if [ "$ACTTIPO" == "strhtml" ]; then
                        REPLY=$( curl -s $ACTHOST | grep "$ACTOPZIONE" | wc -l );
                        if [ "$REPLY" != "1" ]; then
                                RETRYCOUNT=1
                                while [ $RETRYCOUNT -le $RETRY ]; do
                                        if [ "$REPLY" != "1" ]; then
                                                tput cup 0 0; echo -e "$RED$BLINK >>> Retry $RETRYCOUNT    $NC";
                                                REPLY=$( curl -s $ACTHOST | grep "$ACTOPZIONE" | wc -l );
                                        fi
                                sleep 2
                                let RETRYCOUNT=RETRYCOUNT+1
                                done;
                        fi;
                fi

                if [ "$REPLY" == "1" ]; then 
                        tput cup $ACTVIDEOLINEPRE 0; echo -e "  "
                        tput cup $ACTVIDEOLINE 0; echo -e "$BLINK >$NC"
                        tput cup $ACTVIDEOLINE 2; echo -e "$YELLOW $TOTCHECK"
                        tput cup $ACTVIDEOLINE 7; echo -e "$GREEN [ Host UP ]$NC";
                        tput cup $ACTVIDEOLINE 20; echo -e "$YELLOW $ACTDESCR";
                        tput cup $ACTVIDEOLINE 53; echo -e "$CYAN Tipologia controllo $GREEN $ACTTIPO"
                        tput cup $ACTVIDEOLINE 85; echo -e "$CYAN Verifica dell'host $GREEN $ACTHOST $NC";
                        DOWNSTATE=$( cat monitoring.downstate | grep "$ACTDESCR" | wc -l )
                        if [ "$DOWNSTATE" == "1" ]; then
                                if [ "$LOGENABLE" == "1" ] && [ "$LOGPATH" != "" ]; then
                                        DATALOG=$( date +%c );
                                        echo "$DATALOG - HOST DOWN - $ACTDESCR - $ACTHOST ( Controllo $ACTTIPO - tentativi $RETRY )" >> $LOGPATH;
                                fi;
                                if [ "$TELEGRAMBOTENABLE" == "1" ] && [ "$TELEGRAMAPIBOT" != "" ] && [ "$TELEGRAMCHATID" != "" ]; then
                                        NOTIFICAUNO=0; 
                                        ORANOW=$( date +%k | awk '{ print $1 }' );
                                        if [ "$ACTNOTIFICA" == "1" ] && [ $ORANOW -ge $DAYFROM ] && [ $ORANOW -le $DAYTO ]; then NOTIFICAUNO=1; fi;
                                        if [ "$ACTNOTIFICA" == "2" ] || [ "$NOTIFICAUNO" == "1" ]; then
                                                FRASE="https://api.telegram.org/bot$TELEGRAMAPIBOT/sendMessage?chat_id=$TELEGRAMCHATID&text=Bash Monitoring $MYNAME: <b>!!!!!HOST_UP!!!!!</b> $ACTDESCR - <i>TipologiaControllo $ACTTIPO - VerificaHost $ACTHOST</i>&parse_mode=html";
                                                curl -s "$FRASE" > /dev/null;
                                        fi;
                                fi;
                                sed -i /$ACTDESCR/d monitoring.downstate > /dev/null;
                        fi;
                else 
                        tput cup $ACTVIDEOLINEPRE 0; echo -e "  "
                        tput cup $ACTVIDEOLINE 0; echo -e "$BLINK >$NC"
                        tput cup $ACTVIDEOLINE 2; echo -e "$YELLOW $TOTCHECK"
                        tput cup $ACTVIDEOLINE 7; echo -e "$RED$BLINK [Host DOWN]$NC"
                        tput cup $ACTVIDEOLINE 20; echo -e "$NC$BGREDWHITE $ACTDESCR $NC$CYAN$BLINK"
                        tput cup $ACTVIDEOLINE 53; echo -e " Tipologia controllo $RED $ACTTIPO";
                        tput cup $ACTVIDEOLINE 85; echo -e "$CYAN Verifica dell'host $RED $ACTHOST $NC";
                        DOWNSTATE=$( cat monitoring.downstate | grep "$ACTDESCR" | wc -l )
                        if [ "$DOWNSTATE" == "0" ]; then
                                if [ "$LOGENABLE" == "1" ] && [ "$LOGPATH" != "" ]; then
                                        DATALOG=$( date +%c );
                                        echo "$DATALOG - HOST DOWN - $ACTDESCR - $ACTHOST ( Controllo $ACTTIPO - tentativi $RETRY )" >> $LOGPATH;
                                fi;
                                if [ "$TELEGRAMBOTENABLE" == "1" ] && [ "$TELEGRAMAPIBOT" != "" ] && [ "$TELEGRAMCHATID" != "" ]; then
                                        NOTIFICAUNO=0; 
                                        ORANOW=$( date +%k | awk '{ print $1 }' );
                                        if [ "$ACTNOTIFICA" == "1" ] && [ $ORANOW -ge $DAYFROM ] && [ $ORANOW -le $DAYTO ]; then NOTIFICAUNO=1; fi;
                                        if [ "$ACTNOTIFICA" == "2" ] || [ "$NOTIFICAUNO" == "1" ]; then
                                                FRASE="https://api.telegram.org/bot$TELEGRAMAPIBOT/sendMessage?chat_id=$TELEGRAMCHATID&text=Bash Monitoring $MYNAME: <b>!!!!!HOST_DOWN!!!!!</b> $ACTDESCR - <i>TipologiaControllo $ACTTIPO - VerificaHost $ACTHOST - Tentativi $RETRY</i>&parse_mode=html";
                                                curl -s "$FRASE" > /dev/null;
                                        fi;
                                fi;
                                echo "$ACTDESCR" >> monitoring.downstate;
                        fi;
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
