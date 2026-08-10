#!/bin/bash

version="1.0.00"
usage(){
echo "
Written by Isabela Almeida
Based on Jonathan Beesley R script
Created on Jul 29, 2024
Last modified on Aug 11, 2026
Version: ${version}

Description: Write and submit PBS jobs for step 081 of HIPPO
(HiChIP Integration Pipeline for PBS Operations).

Usage: bash ipda_hippo_step081-to-pbs.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"

Resources baseline: -m 100 -c 5 -w "05:00:00"

Note: The Rmd script generated can be run interactively on a HPC with an X11 Application, e.g. XQuartz.

## Input:

-i <path/to/input/files>    Input TSV files including path FROM working
                            directory. This TSV file should contain:

                            Col1:
                            stem of analysis
                            e.g. H3K27ac

                            Col2:
                            path/from/working/dir/to/bintolen.txt.gz
                            file created with ipda_hippo_step061-to-pbs.sh

                            Col3:
                            path/from/working/dir/to/HiC-Pro/output_DATE/SAMPLEID/hic_results/data/data/data.allValidPairs
                            Please note, HiC-Pro creates a data.allValidPairs file and chr names may be just INT 
                            instead of chrINT. This script will create a data.allValidPairs.chr file with chrINT.
                            Please provide path to original file (without .chr).
                            Change line 291 and comment lines 324-326 if this is not needed.

                            Col4:
                            path/from/working/dir/to/HiCDCPlus/interaction-calls/output/folder/

                            Col5:
                            SAMPLE ID
                            e.g.
                            OVHiChIP1

                            Col6:
                            genomic assembly version
                            e.g. hg38

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
#-->080 5kb range interaction calls (1HiCDC+)
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
        ?) echo script usage: bash ipda_hippo_step081-to-pbs.sh -i path/to/input/files -p PBS stem -e email -m INT -c INT -w "HH:MM:SS" >&2
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
logfile=logfile_ipda_hippo_step081-to-pbs_${thislogdate}.txt

#................................................
#  Required modules, softwares and libraries
#................................................

# R 4.2.0
module_R=R/4.2.0

# Pandoc 3.1.1
module_pandoc=pandoc/3.1.1

#................................................
#  Print Execution info to user
#................................................

date
echo "## Executing bash ipda_hippo_step081-to-pbs.sh"
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
echo "## Executing bash ipda_hippo_step081-to-pbs.sh"
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
cut -f5 ${input} | sort | uniq | while read sample; do echo "#!/bin/sh" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "##########################################################################" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#  Script:  ${pbs_stem}_${sample}_${thislogdate}.pbs" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#  Author:  Isabela Almeida" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#  Created: ${human_thislogdate} at QIMR Berghofer (Brisbane, Australia) - VSC" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#  Updated: ${human_thislogdate} at QIMR Berghofer (Brisbane, Australia) - VSC" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#  Version: v01" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#  Email:   ${email}" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "##########################################################################" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done

## Write PBS directives
cut -f5 ${input} | sort | uniq | while read sample; do echo "#PBS -N ${pbs_stem}_${sample}_${thislogdate}" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#PBS -r n" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#PBS -l mem=${mem}GB,walltime=${walltime},ncpus=${ncpus}" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#PBS -m ae" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#PBS -M ${email}" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done

## Write directory setting
cut -f5 ${input} | sort | uniq | while read sample; do echo "#................................................" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#  Set main working directory" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#................................................" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "## Change to main directory" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo 'cd ${PBS_O_WORKDIR}' >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo 'echo ; echo "WARNING: The main directory for this run was set to ${PBS_O_WORKDIR}"; echo '; echo " >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done

## Write load modules
cut -f5 ${input} | sort | uniq | while read sample; do echo "#................................................" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#  Load Softwares, Libraries and Modules" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#................................................" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo 'echo "## Load tools"' >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "module load ${module_R}" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "module load ${module_pandoc}" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done

## Write Rmd file
cut -f5 ${input} | sort | uniq | while read sample; do echo "#................................................" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#  Write Rmd file" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#................................................" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "---" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do stem=`grep "${sample}" ${input} | cut -f1 | sort | uniq`; echo "title: \"${stem} - ${sample}\"" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "subtitle: \"HiCDC+ interactions calls\"" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "author: \"Isabela Almeida\"" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "date: \"\`r Sys.Date()\`\"" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "output: rmdformats::downcute" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "---" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "\`\`\`{r setup, include=FALSE}" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo 'knitr::opts_chunk$set(echo=TRUE, message=TRUE)' >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "\`\`\`" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "# Load Libraries" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "\`\`\`{r load-libraries, echo=TRUE, message=FALSE}" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "library(\"HiCDCPlus\")" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "\`\`\`" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "# Run HiCDC+" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "Setting main path and input files from " >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "\`\`\`{r main-paths}" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do bintolenfile=`grep "${sample}" ${input} | cut -f2 | sort | uniq`; echo "bintolenfile <- \"${bintolenfile}\"" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do validpairsfile=`grep "${sample}" ${input} | cut -f3 | sort | uniq`; echo "validpairsfile <- \"${validpairsfile}.chr\"" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do outdir=`grep "${sample}" ${input} | cut -f4 | sort | uniq`; echo "outdir <- \"${outdir}\"" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "\`\`\`" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "# HiCDC+ with N kb interactions range (defined by user supplied bintolen file)" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "Running HiCDC+ with 5kb ranges allows us to obtain close interaction range calls." >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "\`\`\`{r hicdc}" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "# generate gi_list instance [binned genome, each chrom is a list element] (up to 35 GB)" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "gi_list <- generate_bintolen_gi_list(bintolen_path = bintolenfile)" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "# add counts from allValidPairs file" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "gi_list <- add_hicpro_allvalidpairs_counts(gi_list, allvalidpairs_path = validpairsfile)" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "# expand features for modeling" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "gi_list <- expand_1D_features(gi_list)" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "# run HiC-DC+ on ${ncpus}k cores and set seed for HiC-DC downsampling for modeling" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "set.seed(1010)" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "gi_list <- HiCDCPlus_parallel(gi_list, ncore = ${ncpus})" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
#cut -f5 ${input} | sort | uniq | while read sample; do echo "#write normalized counts (observed/expected) to a .hic file" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
#cut -f5 ${input} | sort | uniq | while read sample; do stem=`grep "${sample}" ${input} | cut -f1 | sort | uniq`; genomeversion=`grep "${sample}" ${input} | cut -f6 | sort | uniq`; echo "hicdc2hic(gi_list,hicfile=paste0(outdir,'/${stem}-${sample}_combined_result.hic'),mode='normcounts',gen_ver='${genomeversion}')" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
#cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#write results to a text file" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done
cut -f5 ${input} | sort | uniq | while read sample; do stem=`grep "${sample}" ${input} | cut -f1 | sort | uniq`; echo "gi_list_write(gi_list, rows = 'significant', fname = paste0(outdir,'/${stem}-${sample}_combined_result.txt.gz'))" >> ${pbs_stem}_${sample}_${thislogdate}.Rmd; done

## Write PBS command lines
cut -f5 ${input} | sort | uniq | while read sample; do echo "#................................................" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#  Run step" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "#................................................" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo 'echo "## Rename INT to chrINT at" ; date ; echo' >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do validpairsfile=`grep "${sample}" ${input} | cut -f3 | sort | uniq`; echo "if [ ! -f ${validpairsfile}.chr ]; then sed -E 's/^(\S+\s+)(\S+\s+)(\S+\s+)(\S+\s+)(\S+)/\1chr\2\3\4chr\5/' ${validpairsfile} > ${validpairsfile}.chr ; else echo "file already exists" ; fi" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do echo "" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done

cut -f5 ${input} | sort | uniq | while read sample; do echo 'echo "## Render Rmd at" ; date ; echo' >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done
cut -f5 ${input} | sort | uniq | while read sample; do outdir=`grep "${sample}" ${input} | cut -f4 | sort | uniq`; echo "Rscript -e \"rmarkdown::render('$PWD/${pbs_stem}_${sample}_${thislogdate}.Rmd', output_dir = '${outdir}')\"" >> ${pbs_stem}_${sample}_${thislogdate}.pbs; done

#................................................
#  Submit PBS jobs
#................................................

## Submit PBS jobs 
ls ${pbs_stem}_*${thislogdate}.pbs | while read pbs; do echo ; echo "#................................................" ; echo "# This is PBS: ${pbs}" ;  echo "#" ; echo "# main command line(s): $(tail -n1 ${pbs})" ; echo "#" ; echo "# now submitting PBS" ; echo "qsub ${pbs}" ; qsub ${pbs} ; echo "#................................................" ; done

date ## Status of all user jobs (including HIPPO step 081 jobs) at
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
sed -i 's,${module_pandoc},'"${module_pandoc}"',g' "$logfile"
sed -i 's,${logfile},'"${logfile}"',g' "$logfile"
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > tmp ; mv tmp $logfile
set +v