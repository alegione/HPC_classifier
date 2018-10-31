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

# Look for a 'Parameters' text file in a 'metadata' folder that stores the user input
# If no file is present, or the variables are present in the file, set the variables to 'nil'
if [ -e "$1" ]; then
	echo -e "${BLUE}Parameter file detected...obtaining previously entered options${NOCOLOUR}"
	ParFile="$1"

	if grep -i -q "Email" $ParFile; then email=$(grep -i "Email" $ParFile | cut -f2); echo -e "${GREEN}Email: $email${NOCOLOUR}";else email="nil"; fi
	if grep -i -q "Project" $ParFile; then Project=$(grep -i "Project" $ParFile | cut -f2); echo -e "${GREEN}Project: $Project${NOCOLOUR}";else Project="nil"; fi
	if grep -i -q "Original reads" $ParFile; then ReadDir=$(grep -i "Original reads" $ParFile | cut -f2); echo -e "${GREEN}Reads directory: $ReadDir${NOCOLOUR}";else ReadDir="nil";fi
	if grep -i -q "Minimum score" $ParFile; then MinScore=$(grep -i "Minimum score" $ParFile | cut -f2);echo -e "${GREEN}Minimum score: $MinScore${NOCOLOUR}";else MinScore="nil";fi
  if grep -i -q "Minimum alignment" $ParFile; then MinAlign=$(grep -i "Minimum alignment" $ParFile | cut -f2);echo -e "${GREEN}Minimum alignment: $MinAlign${NOCOLOUR}";else MinAlign="nil";fi
  if grep -i -q "CPUs" $ParFile; then cpus=$(grep -i "CPUs" $ParFile | cut -f2);echo -e "${GREEN}CPUs: $cpus${NOCOLOUR}";else cpus="nil";fi


	sleep 1
else
	email="nil"
	Project="nil"
	ReadDir="nil"
	MinScore="nil"
	MinAlign="nil"
  cpus="nil"
fi


#email
if [ $email == "nil" ]; then
  echo -e "${BLUE}Please enter your email address: ${NOCOLOUR}"
  echo -e "${GREEN}"
  read -e email
  echo -e "${NOCOLOUR}"
fi

#project name?
if [ $Project == "nil" ]; then
#ask user the name of the project for file name/directory purposes
	echo -e "${BLUE}Please enter a project title:${NOCOLOUR}"
	read -e Project
	echo -e "${BLUE}You entered: ${GREEN}$Project${NOCOLOUR}"
fi



#output current queue?
#determine available cpus?
echo -e "${BLUE}Current jobs running and scheduled on the BigMem partition${NOCOLOUR}"
echo -e "${PURPLE}"
squeue -p bigmem
echo -e "${NOCOLOUR}"

#determine available cores?
cpusInUse=$(squeue -p bigmem -t R -o "%C" | tail -n +2 | awk '{s+=$1} END {print s}')
availablecpus=$((68 - cpusInUse))


Switch="0"
if [ $cpus == "nil" ]; then
  while [ $Switch -eq "0" ]; do
    echo -e "${BLUE}Please enter the number of CPUs you would like to use: ${NOCOLOUR}"
    if [ $availablecpus -gt "0" ]; then
      echo -e "${YELLOW}We recommend a number lower than $availablecpus if you don't want to wait!${NOCOLOUR}"
    fi

    echo -e "${GREEN}"
    read -e cpus
    echo -e "${NOCOLOUR}"

    if [ $cpus -lt "37" ]; then
      Switch="1"
    else
      echo -e "${RED}There are only 36 cpus available!! Please choose a smaller number${NOCOLOUR}"
    fi
  done
fi

#scoring method
Switch="0"
if [ $scoring == "nil" ]; then
  while [ $Switch -eq "0" ]; do
    echo -e "${BLUE}Please enter the number corresponding the scoring system you would like to use: ${NOCOLOUR}"
    echo -e "${YELLOW}1 - Single Hit Equivalent Length (SHEL)${NOCOLOUR}"
    echo -e "${YELLOW}2 - Length${NOCOLOUR}"
    echo -e "${YELLOW}3 - Log Length${NOCOLOUR}"
    echo -e "${YELLOW}4 - Normalised (SHEL / Length)${NOCOLOUR}"

    echo -e "${GREEN}"
    read -e scoring
    echo -e "${NOCOLOUR}"

    case $scoring in
      1)
        echo -e "${GREEN}Single Hit Equivalent Length (SHEL) selected${NOCOLOUR}"
        scoring="SHEL"
        Switch="1"
        ;;
      2)
        echo -e "${GREEN}Length based scoring selected${NOCOLOUR}"
        scoring="LENGTH"
        Switch="1"
        ;;
      3)
        echo -e "${GREEN}Log10 length based scoring selected${NOCOLOUR}"
        scoring="LOGLENGTH"
        Switch="1"
        ;;
      4)
        echo -e "${GREEN}Normalised score selected${NOCOLOUR}"
        scoring="NORMA"
        Switch="1"
        ;;
      *)
        echo -e "${RED}Please select a number from 1 to 4${NOCOLOUR}"
        Switch="0"
        ;;
    esac
  done
fi

#filtering parametres


Switch="0"

while [ $Switch -eq "0" ]; do
  echo -e "${BLUE}The set filtering values are:"
  echo -e "${YELLOW}Minimum score of at least $MinScore AND minimum alignment of at least $MinAlign"
  echo -e "${BLUE}Would you like to keep them? (Y/N)"
  read -e -N 1 choice
  choice=$(echo -e "$choice" | tr '[:upper:]' '[:lower:]')
  if [ $choice = "y" ]; then
    Switch="1"
  else
    echo -e "${BLUE}The minimum centrifuge score to keep:${NOCOLOUR}"
    read -e MinScore
    echo -e "${BLUE}The minimum centrifuge alignment to keep:${NOCOLOUR}"
    read -e MinAlign
    Switch="1"
  fi
done

#single direction or paired reads??

#grouped or individual recentrifuge

#confirm details

#build run file
  #different run file for paired reads and groups

ProjectDir="/data/cephfs/0528/"

basename -s ".fastq" $ProjectDir/Reads_to_run/*.fastq > $ProjectDir/readlist.txt


cat << EOT >> "$ProjectDir/$Project.slurm"
#!/bin/bash
#SBATCH --account=0528
#SBATCH --partition=bigmem
#SBATCH --job-name="$Project"
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=$cpus
#SBATCH --mem=150GB
#SBATCH --time=1-00:00:00
#SBATCH --mail-type=ALL      # Type of email notification- BEGIN,END,FAIL,ALL
#SBATCH --mail-user=$email

module load centrifuge/1.0.3-intel-2016.u3
module load recentrifuge/20181019-intel-2017.u2

# Loops through readlist.txt and does centrifuge/recentrifuge/filter/recentrifuge on each file IF they haven't been run before

while read i; do
# If the file hasn't been run before, create a directory for it
     if [ ! -d $ProjectDir/centrifuge-results/$i ]; then
          mkdir $ProjectDir/centrifuge-results/$i
     fi
# Run centrifuge on the file listed in the readlist.txt
     if [ ! -e $ProjectDir/centrifuge-results/$i/$i.classification.tsv ]; then
          echo $(date)
          echo "Running centrifuge on read: $i"
          centrifuge  -p $cpus --scoring $scoring -x $ProjectDir/database/nt/nt -U $ProjectDir/Reads_to_run/$i.fastq --report-file $ProjectDir/centrifuge-results/$i/$i.report.txt -S $ProjectDir/centrifuge-results/$i/$i.classification.tsv
     fi
# Run Recentrifuge on centrifuge results
     if [ ! -e $ProjectDir/centrifuge-results/$i/$i.classification.html ]; then
          echo $(date)
          echo "Running recentrifuge on centrifuge output for $i"
          recentrifuge.py -n $ProjectDir/database/recentrifugeTaxDump/taxdump -f $ProjectDir/centrifuge-results/$i/$i.classification.tsv -o $ProjectDir/centrifuge-results/$i/$i.classification.html
     fi
# Filter reads based on a hit score of at least 300 and a length of at least 50
     if [ ! -e $ProjectDir/centrifuge-results/$i/$i.filt300.tsv ]; then
          echo $(date)
          echo "Filtering centrifuge results for $i with a minimum score of $MinScore and minimum alignment of $MinAlign"
          awk ' $4 >= $MinScore && $6 >= $MinAlign ' $ProjectDir/centrifuge-results/$i/$i.classification.tsv > $ProjectDir/centrifuge-results/$i/$i.filt300.tsv
     fi
# Produce recentrifuge results on filtered reads
     if [ ! -e $ProjectDir/centrifuge-results/$i/$i.filt300.html ]; then
          echo $(date)
          echo "Running recentrifuge on filtered results for $i"
          recentrifuge.py -n $ProjectDir/database/recentrifugeTaxDump/taxdump -f $ProjectDir/centrifuge-results/$i/$i.filt300.tsv -o $ProjectDir/centrifuge-results/$i/$i.filt300.html
     fi

done < $ProjectDir/readlist.txt

EOT

#run it
sbatch "$ProjectDir/$Project.slurm"
