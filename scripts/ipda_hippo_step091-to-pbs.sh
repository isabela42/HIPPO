#!/bin/bash

version="1.0.00"
usage(){
echo "
Written by Isabela Almeida
Based on Jonathan Beesley R script
Created on Aug 01, 2024
Last modified on Aug 11, 2026
Version: ${version}

Description: Write and submit PBS jobs for step 091 of HIPPO
(HiChIP Integration Pipeline for PBS Operations).

Usage: bash ipda_hippo_step091-to-pbs.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"

Resources baseline: -m 10 -c 1 -w "01:00:00"

Tracks will have the following format:
chrom | chromStart | chromEnd | name | score | value | exp | color | sourceChrom | sourceStart | sourceEnd | sourceName | sourceStrand | targetChrom | targetStart | targetEnd | targetName | targetStrand

columns description (from <https://genome.ucsc.edu/goldenpath/help/examples/interact/interact.as>)

string chrom:        'Chromosome (or contig, scaffold, etc.). For interchromosomal, use 2 records'
uint chromStart:     'Start position of lower region. For interchromosomal, set to chromStart of this region'
uint chromEnd:       'End position of upper region. For interchromosomal, set to chromEnd of this region'
string name:         'Name of item, for display.  Usually 'sourceName/targetName' or empty'
uint score:          'Score from 0-1000.'
double value:        'Strength of interaction or other data value. Typically basis for score'
string exp:          'Experiment name (metadata for filtering). Use . if not applicable'
string color:        'Item color.  Specified as r,g,b or hexadecimal #RRGGBB or html color name, as in //www.w3.org/TR/css3-color/#html4.'
string sourceChrom:  'Chromosome of source region (directional) or lower region. For non-directional interchromosomal, chrom of this region.'
uint sourceStart:    'Start position source/lower/this region'
uint sourceEnd:      'End position in chromosome of source/lower/this region'
string sourceName:   'Identifier of source/lower/this region'
string sourceStrand: 'Orientation of source/lower/this region: + or -.  Use . if not applicable'
string targetChrom:  'Chromosome of target region (directional) or upper region. For non-directional interchromosomal, chrom of other region'
uint targetStart:    'Start position in chromosome of target/upper/this region'
uint targetEnd:      'End position in chromosome of target/upper/this region'
string targetName:   'Identifier of target/upper/this region'
string targetStrand: 'Orientation of target/upper/this region: + or -.  Use . if not applicable'

## Input:

-i <path/to/input/files>    Input TSV files including path FROM working
                            directory. This TSV file should contain:

                            Col1:
                            stem of analysis
                            e.g. H3K27ac-OC

                            Col2:
                            path/from/working/dir/to/HiCDCPlus/interaction-calls_DATE/
                            containing stem_combined_result.txt.gz files
                            
                            Col3:
                            path/from/working/dir/to/HiCDCPlus/interactions-ucsc-browser/output/folder/
                            txt files will be named as path above and stem from files in Col2

-p <PBS stem>               Stem for PBS file names
-e <email>                  Email for PBS job
-m <INT>                    Memory INT required for PBS job in GB
-c <INT>                    Number of CPUS required for PBS job
-w <HH:MM:SS>               Clock walltime required for PBS job

## Output:

logfile.txt                 Logfile with commands executed and date
PBS files                   PBS files created

Pipeline description:

#   010 Index building (1Bowtie)
#   020 Identify restriction fragments after digestion (1HiC-Pro)
#   030 Get chromosome sizes (1Awk)
#   040 Create HiChIP config files (1Bash)
#   050 Run HiC-Pro complete workflow (1HiC-Pro)
#   060 Construct features (1HiCDC+)
#   070 20kb range quality control (1HiCDC+)
#   080 5kb range interaction calls (1HiCDC+)
#-->090 Create UCSC browser tracks (1 txt.gz, 2 pgl)
#   100 Intersect calls with BED coordinates (1pgltools)
#   110 Targeted allele-specific looping (1SamTools, 2R plots)
#   120 Extract ChIP signals from HiChIP data (1deepTools)

Please contact Isabela Almeida at mb.isabela42@gmail.com if you encounter any problems.
"
}

## Display help message
if [ -z "$1" ] || [[ $1 == -h ]] || [[ $1 == --help ]]; then
	usage
	exit
fi

#  ____       _   _   _                 
# / ___|  ___| |_| |_(_)_ __   __ _ ___ 
# \___ \ / _ \ __| __| | '_ \ / _` / __|
#  ___) |  __/ |_| |_| | | | | (_| \__ \
# |____/ \___|\__|\__|_|_| |_|\__, |___/
#                             |___/     

## Save execution ID
pid=`echo $$` #$BASHPID

## User name within your cluster environment
user=`whoami`

## Exit when any command fails
set -e

#................................................
#  Input parameters from command line
#................................................

## Get parameters from command line flags
while getopts "i:p:e:m:c:w:h:v" flag
do
    case "${flag}" in
        i) input="${OPTARG}";;       # Input files including path
        p) pbs_stem="${OPTARG}";;    # Stem for PBS file names
        e) email="${OPTARG}";;       # Email for PBS job
        m) mem="${OPTARG}";;         # Memory required for PBS job
        c) ncpus="${OPTARG}";;       # Number of CPUS required for PBS job
        w) walltime="${OPTARG}";;    # Clock walltime required for PBS job
        h) Help ; exit;;             # Print Help and exit
        v) echo "${version}"; exit;; # Print version and exit
        ?) echo script usage: bash ipda_hippo_step091-to-pbs.sh -i path/to/input/files -p PBS stem -e email -m INT -c INT -w "HH:MM:SS" >&2
           exit;;
    esac
done

#................................................
#  Set Logfile stem
#................................................

## Set Logfile stem
# it contains all the executed commands with date/time;
# the output files general metrics (such as size);
# and memory/CPU usage for all executions
thislogdate=$(date +'%d%m%Y%H%M%S%Z')
human_thislogdate=`date`
logfile=logfile_ipda_hippo_step091-to-pbs_${thislogdate}.txt

#................................................
#  Required modules, softwares and libraries
#................................................

# R 4.2.0
module_R=R/4.2.0

#................................................
#  Print Execution info to user
#................................................

date
echo "## Executing bash ipda_hippo_step091-to-pbs.sh"
echo "## This execution PID: ${pid}"
echo
echo "## Given inputs:"
echo
echo "## Input files:                 ${input}"
echo "## PBS stem:                    ${pbs_stem}"
echo "## Email for PBS notifications: ${email}"
echo "## PBS job memory required:     ${mem}"
echo "## PBS job NCPUS required:      ${ncpus}"
echo "## PBS job walltime required:   ${walltime}"
echo
echo "## Outputs created:"
echo
echo "## Output files saved to:       user-set"
echo "## logfile will be saved as:    ${logfile}"
echo

# ____  _             _   _                   
#/ ___|| |_ __ _ _ __| |_(_)_ __   __ _       
#\___ \| __/ _` | '__| __| | '_ \ / _` |      
# ___) | || (_| | |  | |_| | | | | (_| |_ _ _ 
#|____/ \__\__,_|_|   \__|_|_| |_|\__, (_|_|_)
#                                 |___/  

#................................................
#  Print Execution info to logfile
#................................................

exec &> "${logfile}"

date
echo "## Executing bash ipda_hippo_step091-to-pbs.sh"
echo "## This execution PID: ${pid}"
echo
echo "## Given inputs:"
echo
echo "## Input files:                 ${input}"
echo "## PBS stem:                    ${pbs_stem}"
echo "## Email for PBS notifications: ${email}"
echo "## PBS job memory required:     ${mem}"
echo "## PBS job NCPUS required:      ${ncpus}"
echo "## PBS job walltime required:   ${walltime}"
echo
echo "## Outputs created:"
echo
echo "## Output files saved to:       user-set"
echo "## This is logfile:             ${logfile}"

set -v

#................................................
#  Create PBS files
#................................................

## Write PBS header
cut -f1 ${input} | sort | uniq | while read stem; do echo "#!/bin/sh" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "##########################################################################" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Script:  ${pbs_stem}_${stem}_${thislogdate}.pbs" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Author:  Isabela Almeida" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Created: ${human_thislogdate} at QIMR Berghofer (Brisbane, Australia) - VSC" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Updated: ${human_thislogdate} at QIMR Berghofer (Brisbane, Australia) - VSC" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Version: v01" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Email:   ${email}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "##########################################################################" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

## Write PBS directives
cut -f1 ${input} | sort | uniq | while read stem; do echo "#PBS -N ${pbs_stem}_${stem}_${thislogdate}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#PBS -r n" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#PBS -l mem=${mem}GB,walltime=${walltime},ncpus=${ncpus}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#PBS -m ae" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#PBS -M ${email}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

## Write directory setting
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Set main working directory" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "## Change to main directory" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo 'cd ${PBS_O_WORKDIR}' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo ; echo "WARNING: The main directory for this run was set to ${PBS_O_WORKDIR}"; echo ' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

## Write load modules
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Load Softwares, Libraries and Modules" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Load tools"' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "module load ${module_R}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

## Write R file
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Write R file" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "# load libraries" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "library(dplyr)" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.r; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "# data" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do interactiondir=`grep "${stem}" ${input} | cut -f2 | sort | uniq`; echo "interactiondir <- \"${interactiondir}\"" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do outputdir=`grep "${stem}" ${input} | cut -f3 | sort | uniq`; echo "outputdir <- \"${outputdir}\" # save all the output files in 1 dir, makes it easier to gzip, copy, upload" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.r; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "# import results files" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "samples <- sapply(strsplit(list.files(interactiondir, pattern = \"\\\\.txt.gz$\"),\"_\"), \`[\`, 1) # if you had a dir per sample: dir(interactiondir)" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.r; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "# function to create UCSC track" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "make_ucsc_tracks <- function(d){" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  hc1 <- read.delim(d)" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  # filter; transform q values; convert inf to max" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  hc1 <- hc1 %>% filter(qvalue <= 0.01)" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  hc1\$score <- -log10(hc1\$qvalue)" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  hc1\$score[is.infinite(hc1\$score)] <- max(hc1\$score[!is.infinite(hc1\$score)])" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  hc2 <- as.data.frame(hc1) %>%" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "    mutate(name = \".\", score = round(score/max(score) * 1000, 0)," >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "           value = round(-log10(qvalue), 2), exp = \".\", colour = 0," >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "           sourceChrom = chrI, sourceStart = startI, sourceEnd = endI, sourceName = \".\", sourceStrand = \".\"," >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "           targetChrom = chrJ, targetStart = startJ, targetEnd = endJ, targetName = \".\", targetStrand = \".\") %>%" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "    select(chrI, startI, endJ, name, score, value, exp, colour, sourceChrom:targetStrand)" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  return(hc2)" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "}" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.r; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "# make a track for each sample in dir" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "for(i in samples){" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  outputfile <- paste0(outputdir, \"/ucsc_\", i, \".txt\")" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  trackline <- paste0(\"track type=interact name=\", i, \" description=\", i, \" maxHeightPixels=200:100:50 useScore=on visibility=full scoreMin=0\")" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  j <- Sys.glob(paste0(interactiondir, \"/\", i, \"*\", \".txt.gz\"))" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
#cut -f1 ${input} | sort | uniq | while read stem; do echo "  j <- paste0(interactiondir, \"/\", i, \"_combined_result.txt.gz\")" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  x1 <- make_ucsc_tracks(j)" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  writeLines(trackline, outputfile)" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  write.table(x1, outputfile, append = T, quote = F, row.names = F, col.names = F, sep = \"\t\")" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "}" >> ${pbs_stem}_${stem}_${thislogdate}.r; done

## Write PBS command lines
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Run step" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Run R script at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do outputdir=`grep "${stem}" ${input} | cut -f3 | sort | uniq`; mkdir -p ${outputdir}; echo "Rscript ${pbs_stem}_${stem}_${thislogdate}.r" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Gzip output files at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do outputdir=`grep "${stem}" ${input} | cut -f3 | sort | uniq`; echo "ls ${outputdir}/*.txt | while read t; do gzip \${t} ; done" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

#................................................
#  Submit PBS jobs
#................................................

## Submit PBS jobs 
ls ${pbs_stem}_*${thislogdate}.pbs | while read pbs; do echo ; echo "#................................................" ; echo "# This is PBS: ${pbs}" ;  echo "#" ; echo "# main command line(s): $(tail -n4 ${pbs} | head -n1)" ; echo "#                       $(tail -n1 ${pbs})" ; echo "#" ; echo "# now submitting PBS" ; echo "qsub ${pbs}" ; qsub ${pbs} ; echo "#................................................" ; done

date ## Status of all user jobs (including HIPPO step 091 jobs) at
qstat -u "$user"

# This will remove $VARNAMES from output file with the actual $VARVALUE
# allowing for easily retracing commands
sed -i 's,${input},'"${input}"',g' "$logfile"
sed -i 's,${pbs_stem},'"${pbs_stem}"',g' "$logfile"
sed -i 's,${email},'"${email}"',g' "$logfile"
sed -i 's,${mem},'"${mem}"',g' "$logfile"
sed -i 's,${ncpus},'"${ncpus}"',g' "$logfile"
sed -i 's,${walltime},'"${walltime}"',g' "$logfile"
sed -i 's,${human_thislogdate},'"${human_thislogdate}"',g' "$logfile"
sed -i 's,${thislogdate},'"${thislogdate}"',g' "$logfile"
sed -i 's,${user},'"${user}"',g' "$logfile"
sed -i 's,${module_hicpro},'"${module_hicpro}"',g' "$logfile"
sed -i 's,${module_R},'"${module_R}"',g' "$logfile"
sed -i 's,${logfile},'"${logfile}"',g' "$logfile"
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > tmp ; mv tmp $logfile
set +v