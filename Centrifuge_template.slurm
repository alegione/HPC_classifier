#!/bin/bash
#SBATCH --account=            # PUT THE punimXXXX value here for the project name
#SBATCH --partition=bigmem
#SBATCH --job-name="Classification"
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=150GB
#SBATCH --time=1-00:00:00
#SBATCH --mail-type=ALL      # Type of email notification- BEGIN,END,FAIL,ALL
#SBATCH --mail-user=         # PUT YOUR EMAIL HERE


module load centrifuge/1.0.3-intel-2016.u3
module load recentrifuge/20181019-intel-2017.u2

#REPLACE XXXXXX, THIS SHOULD BE WHATEVER YOU PUT IN 'ACCOUNT'
ProjectDir="/data/cephfs/XXXXXXXX/"

basename -s ".fastq" $ProjectDir/Reads_to_run/*.fastq > $ProjectDir/readlist.txt

#Edit below at a later date....
#MinScore="300"
#MinAlign="50"


# Loops through readlist.txt and does centrifuge/recentrifuge/filter/recentrifuge on each file IF they haven't been run before

while read i; do
# If the file hasn't been run before, create a directory for it
     if [ ! -d $ProjectDir/centrifuge-results/$i ]; then
          mkdir $ProjectDir/centrifuge-results/$i
     fi
# Run centrifuge on the file listed in the readlist.txt
     if [ ! -e $ProjectDir/centrifuge-results/$i/$i.classification.tsv ]; then
          echo $(date)
          echo "$i centrifuge"
          centrifuge  -p 32 -x $ProjectDir/database/nt/nt -U $ProjectDir/Reads_to_run/$i.fastq --report-file $ProjectDir/centrifuge-results/$i/$i.report.txt -S $ProjectDir/centrifuge-results/$i/$i.classification.tsv
     fi
# Run Recentrifuge on centrifuge results
     if [ ! -e $ProjectDir/centrifuge-results/$i/$i.classification.html ]; then
          echo $(date)
          echo "$i recentrifuge"
          recentrifuge.py -n $ProjectDir/database/recentrifugeTaxDump/taxdump -f $ProjectDir/centrifuge-results/$i/$i.classification.tsv -o $ProjectDir/centrifuge-results/$i/$i.classification.html
     fi
# Filter reads based on a hit score of at least 300 and a length of at least 50
     if [ ! -e $ProjectDir/centrifuge-results/$i/$i.filt300.tsv ]; then
          echo $(date)
          echo "Filtering centrifuge results for $i"
          awk ' $4 >= 300 && $6 >= 50 ' $ProjectDir/centrifuge-results/$i/$i.classification.tsv > $ProjectDir/centrifuge-results/$i/$i.filt300.tsv
     fi
# Produce recentrifuge results on filtered reads
     if [ ! -e $ProjectDir/centrifuge-results/$i/$i.filt300.html ]; then
          echo $(date)
          echo "Running recentrifuge on filtered results for $i"
          recentrifuge.py -n $ProjectDir/database/recentrifugeTaxDump/taxdump -f $ProjectDir/centrifuge-results/$i/$i.filt300.tsv -o $ProjectDir/centrifuge-results/$i/$i.filt300.html
     fi
# Produce kraken report, currently disabled
#     if [ ! -e $ProjectDir/centrifuge-results/$i/$i.300kraken.tsv ]; then
#          centrifuge-kreport -x $ProjectDir/database/nt/nt $ProjectDir/centrifuge-results/$i/$i.classification.tsv > $ProjectDir/centrifuge-results/$i/$i.kraken.tsv
#          centrifuge-kreport -x $ProjectDir/database/nt/nt $ProjectDir/centrifuge-results/$i/$i.class300.tsv > $ProjectDir/centrifuge-results/$i/$i.300kraken.tsv
#     fi

done < $ProjectDir/readlist.txt
