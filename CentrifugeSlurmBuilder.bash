#!/bin/bash

#Set colour variables
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
NOCOLOUR='\033[0m'

#get screen size and maximise
LINE=`xrandr -q | grep Screen`
WIDTH=`echo ${LINE} | awk '{ print $8 }'`
HEIGHT=`echo ${LINE} | awk '{ print $10 }' | awk -F"," '{ print $1 }'`
echo -e "\e[4;$HEIGHT;${WIDTH}t"

#username (only needed for when not on hpc)

#password??

#email
if [ $email == "nil" ]; then
  echo -e "${BLUE}Please enter your email address: ${NOCOLOUR}"
	read -e email
fi

#project name?

#output current queue?
#determine available cpus?
#determine available cores?
Switch="0"
if [ $cpus == "nil" ]; then
  while [ $Switch -eq "0" ]; do
    echo -e "${BLUE}Please enter the number of CPUs you would like to use: ${NOCOLOUR}"
    if [ $availablecpus -gt "0" ]; then
      echo -e "${YELLOW}We recommend a number lower than $availablecpus if you don't want to wait!${NOCOLOUR}"
    fi
    read -e cpus
    if [ $cpus -lt "37" ]; then
      Switch="1"
    else
      echo -e "${RED}There are only 36 cpus available!! Please choose a smaller number${NOCOLOUR}"
  done
fi

#scoring method

#filtering parametres

#single direction or paired reads??

#grouped or individual recentrifuge

#confirm details

#build run file
  #different run file for paired reads and groups

#run it
