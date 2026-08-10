#!/bin/bash

version="1.0.00"
usage(){
echo "
Written by Isabela Almeida
Based on Jonathan Beesley R script
Created on Jul 04, 2024
Last modified on Aug 11, 2026
Version: ${version}

Description: Write and submit PBS jobs for step 061 of HIPPO
(HiChIP Integration Pipeline for PBS Operations).

Usage: bash ipda_hippo_step061-to-pbs.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"

Resources baseline: -m 10 -c 1 -w "01:00:00"

Note: The R script generated can be run interactively on a HPC with an X11 Application, e.g. XQuartz.

## Input:

-i <path/to/input/files>    Input TSV files including path FROM working
                            directory. This TSV file should contain:
                            
                            Col1:
                            path/from/working/dir/to/stem
                            of output bintolen file, which will be saved as
                            stem_bintolen.txt.gz
                            e.g.: stem could be hg38_20kb_GATC_GANTC
                            file will be saved as hg38_20kb_GATC_GANTC_bintolen.txt.gz
                            in the specified path

                            Col2:
                            INT
                            INT of binsize
                            e.g. 20000 for quality control
                                 5000 for actual analysis

                            Col3:
                            name of species
                            e.g. Hsapiens

                            Col4:
                            genomic assembly version
                            e.g. hg38

                            Col5:
                            comma separated and double quoted restriction enzyme cut patterns
                            e.g. "GATC","GANTC"

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
#-->060 Construct features (1HiCDC+)
#   070 20kb range quality control (1HiCDC+)
#   080 5kb range interaction calls (1HiCDC+)
#   090 Create UCSC browser tracks (1 txt.gz, 2 pgl)
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
        ?) echo script usage: bash ipda_hippo_step061-to-pbs.sh -i path/to/input/files -p PBS stem -e email -m INT -c INT -w "HH:MM:SS" >&2
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
logfile=logfile_ipda_hippo_step061-to-pbs_${thislogdate}.txt

#................................................
#  Required modules, softwares and libraries
#................................................

# R 4.2.0
module_R=R/4.2.0

#................................................
#  Print Execution info to user
#................................................

date
echo "## Executing bash ipda_hippo_step061-to-pbs.sh"
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
echo "## Executing bash ipda_hippo_step061-to-pbs.sh"
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
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#!/bin/sh" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "##########################################################################" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#  Script:  ${pbs_stem}_${stem}_${thislogdate}.pbs" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#  Author:  Isabela Almeida" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#  Created: ${human_thislogdate} at QIMR Berghofer (Brisbane, Australia) - VSC" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#  Updated: ${human_thislogdate} at QIMR Berghofer (Brisbane, Australia) - VSC" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#  Version: v01" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#  Email:   ${email}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "##########################################################################" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

## Write PBS directives
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#PBS -N ${pbs_stem}_${stem}_${thislogdate}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#PBS -r n" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#PBS -l mem=${mem}GB,walltime=${walltime},ncpus=${ncpus}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#PBS -m ae" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#PBS -M ${email}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

## Write directory setting
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#  Set main working directory" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "## Change to main directory" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo 'cd ${PBS_O_WORKDIR}' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo 'echo ; echo "WARNING: The main directory for this run was set to ${PBS_O_WORKDIR}"; echo ' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

## Write load modules
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#  Load Softwares, Libraries and Modules" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo 'echo "## Load tools"' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "module load ${module_R}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

## Write R file
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#  Write R file" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; binsize=`grep "${bin2lenpath}" ${input} | cut -f2 | sort | uniq`; echo "library(\"HiCDCPlus\")" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; binsize=`grep "${bin2lenpath}" ${input} | cut -f2 | sort | uniq`; echo "bintolenpath <- \"${bin2lenpath}\" ## this file is digested genome that will get used for each hicdcplus run" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; binsize=`grep "${bin2lenpath}" ${input} | cut -f2 | sort | uniq`; echo "# construct features relevant to modeling (GC content, mappability etc)" >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; binsize=`grep "${bin2lenpath}" ${input} | cut -f2 | sort | uniq`; echo "construct_features(output_path = bintolenpath," >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; binsize=`grep "${bin2lenpath}" ${input} | cut -f2 | sort | uniq`; species=`grep "${bin2lenpath}" ${input} | cut -f3 | sort | uniq`; genomeversion=`grep "${bin2lenpath}" ${input} | cut -f4 | sort | uniq`; echo "                   gen = \"${species}\", gen_ver = \"${genomeversion}\"," >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; binsize=`grep "${bin2lenpath}" ${input} | cut -f2 | sort | uniq`; cutpattern=`grep "${bin2lenpath}" ${input} | cut -f5 | sort | uniq`; echo "                   sig = c(${cutpattern})," >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; binsize=`grep "${bin2lenpath}" ${input} | cut -f2 | sort | uniq`; echo "                   bin_type = \"Bins-uniform\"," >> ${pbs_stem}_${stem}_${thislogdate}.r; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; binsize=`grep "${bin2lenpath}" ${input} | cut -f2 | sort | uniq`; echo "                   binsize = ${binsize})" >> ${pbs_stem}_${stem}_${thislogdate}.r; done

## Write PBS command lines
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#  Run step" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo 'echo "## Run R script at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read bin2lenpath; do stem=`echo ${bin2lenpath} | rev | cut -d"/" -f1 | rev` ; echo "Rscript ${pbs_stem}_${stem}_${thislogdate}.r" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done


#................................................
#  Submit PBS jobs
#................................................

## Submit PBS jobs 
ls ${pbs_stem}_*${thislogdate}.pbs | while read pbs; do echo ; echo "#................................................" ; echo "# This is PBS: ${pbs}" ;  echo "#" ; echo "# main command line(s): $(tail -n1 ${pbs})" ; echo "#" ; echo "# now submitting PBS" ; echo "qsub ${pbs}" ; qsub ${pbs} ; echo "#................................................" ; done

date ## Status of all user jobs (including HIPPO step 061 jobs) at
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
sed -i 's,${module_R},'"${module_R}"',g' "$logfile"
sed -i 's,${logfile},'"${logfile}"',g' "$logfile"
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > tmp ; mv tmp $logfile
set +v