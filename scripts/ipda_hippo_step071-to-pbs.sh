#!/bin/bash

version="1.0.00"
usage(){
echo "
Written by Isabela Almeida
Based on Jonathan Beesley R script
Created on Jul 04, 2024
Last modified on Aug 11, 2026
Version: ${version}

Description: Write and submit PBS jobs for step 071 of HIPPO
(HiChIP Integration Pipeline for PBS Operations).

Usage: bash ipda_hippo_step071-to-pbs.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"

Resources baseline: -m 50 -c 3 -w "03:00:00"

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
                            path/from/working/dir/to/HiC-Pro/output_DATE/
                            folder containing sample folders

                            Col4:
                            path/from/working/dir/to/HiCDCPlus/QC/output/folder/

                            Col5:
                            path/from/col3/to/allValidPairs file
                            e.g.
                            if you file is in:
                            path/from/working/dir/to/HiC-Pro/output_DATE/SAMPLE/hic_results/data/data/data.allValidPairs
                            col5 value should be:
                            /hic_results/data/data/data.allValidPairs

                            Col6:
                            No. of samples and description string
                            e.g. "two biological replicates"

                            Col7:
                            sample description separated by ;
                            e.g.
                            - SAMPLEID1: GroupA > Sample 1: description;- SAMPLEID2: GroupA > Sample 2: description;- SAMPLEID3: GroupB > Sample 3: description;- SAMPLEIDN: GroupN > Sample N: description

                            Col8:
                            replicate names and ids separated by ; in the following format
                            e.g.
                            GroupA = c(paste0(outdir,'/SAMPLEID1.ints.txt'),paste0(outdir,'/SAMPLEID2.ints.txt')),;GroupB = c(paste0(outdir,'/SAMPLEID3.ints.txt'),paste0(outdir,'/SAMPLEID4.ints.txt')),;GroupN = c(paste0(outdir,'/SAMPLEIDN1.ints.txt'),paste0(outdir,'/SAMPLEIDN2.ints.txt')))

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
#-->070 20kb range quality control (1HiCDC+)
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
        ?) echo script usage: bash ipda_hippo_step071-to-pbs.sh -i path/to/input/files -p PBS stem -e email -m INT -c INT -w "HH:MM:SS" >&2
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
logfile=logfile_ipda_hippo_step071-to-pbs_${thislogdate}.txt

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
echo "## Executing bash ipda_hippo_step071-to-pbs.sh"
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
echo "## Executing bash ipda_hippo_step071-to-pbs.sh"
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
cut -f1 ${input} | sort | uniq | while read stem; do echo "module load ${module_pandoc}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

## Write Rmd file
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Write Rmd file" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "---" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "title: \"Quality control\"" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "subtitle: \"HiCDC+ differential interactions\"" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "author: \"Isabela Almeida\"" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "date: \"\`r Sys.Date()\`\"" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "output: rmdformats::downcute" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "---" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r setup, include=FALSE}" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo 'knitr::opts_chunk$set(echo=TRUE, message=TRUE)' >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "# Load Libraries" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r load-libraries, echo=TRUE, message=FALSE}" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "library(\"HiCDCPlus\")" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "library(\"DESeq2\")" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "library(\"ggplot2\")" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "library(\"ggsci\")" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "library(\"ggrepel\")" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "library(\"data.table\")" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "library(\"dplyr\")" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "# Run HiCDC+" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "Setting main path and input files from " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r main-paths}" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do bintolenfile=`grep "${stem}" ${input} | cut -f2 | sort | uniq`; echo "bintolenfile <- \"${bintolenfile}\"" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do validPairsdir=`grep "${stem}" ${input} | cut -f3 | sort | uniq`; echo "validPairsdir <- \"${validPairsdir}\"" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do outdir=`grep "${stem}" ${input} | cut -f4 | sort | uniq`; echo "outdir <- \"${outdir}\"" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "The following HiC-Pro samples were found" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r samples}" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "# samples" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "s <- dir(validPairsdir)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
#cut -f1 ${input} | sort | uniq | while read stem; do echo "s <- dir(validPairsdir, pattern = 'allValidPairs')" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "s" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "With respective HiC-Pro allValidPairs file" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r valid-pairs}" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "# file paths - individual replicates" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do path2validpairs=`grep "${stem}" ${input} | cut -f5 | sort | uniq`; echo 'hicfile_paths <- paste0(validPairsdir, s,' "'"${path2validpairs}"'"')' >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "hicfile_paths" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "# HiCDC+ with 20kb range" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "Running HiCDC+ with 20kb ranges allows us to see differential interactions as a normalization between the different samples." >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r hicdc-qc}" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "# set indexfile - create union of interactions across all samples" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "indexfile <- data.frame()" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "indexlist <- list()" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "# import" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "for(hicfile_path in hicfile_paths){" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  sampleid <- strsplit(hicfile_path, split = \"/\")[[1]][10]" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  output_path <- paste0(outdir, sampleid, '.ints.txt')" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  # generate gi_list instance [binned genome, each chrom is a list element] (up to 35 GB)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  gi_list <- generate_bintolen_gi_list(bintolen_path = bintolenfile)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  message(\"generate_bintolen_gi_list done\")" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  # add counts from allValidPairs file" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  gi_list <- add_hicpro_allvalidpairs_counts(gi_list, allvalidpairs_path = hicfile_path)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  # expand features for modeling" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  gi_list <- expand_1D_features(gi_list)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  message(\"running HiC-DC+\")" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  # set seed for HiC-DC downsampling for modeling" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  set.seed(1010)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  # run interaction calling" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  gi_list <- HiCDCPlus_parallel(gi_list, ssize=0.1, ncore = ${ncpus})" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  # write to a list" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  for (i in seq(length(gi_list))){" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo '    indexfile <- unique(rbind(indexfile, as.data.frame(gi_list[[i]][gi_list[[i]]$qvalue<=0.05])[c('"'seqnames1','start1','start2')]))" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo '    indexlist[[sampleid]] <- indexfile' >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  }" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  #write results to a text file" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  gi_list_write(gi_list, fname = output_path)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "}" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "# combine the list of sample specific interactions and make unique" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "indexfile2 <- bind_rows(indexlist) %>% distinct() %>% setNames(c('chrom', 'start', 'end')) %>% valr::bed_sort(by_chrom = T)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "# save index file - union of significant interactions at Xkb" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "colnames(indexfile2) <- c('chr','startI','startJ')" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "data.table::fwrite(indexfile2," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "                   paste0(outdir,'/indices.txt.gz')," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "                   sep='\t',row.names=FALSE,quote=FALSE)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "# Differential analysis" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do nsampletype=`grep "${stem}" ${input} | cut -f6 | sort | uniq`; echo "Here, we have ${nsampletype} for each sample, namely:" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do grep "${stem}" ${input} | cut -f7 | sort | uniq | tr ';' '\n' | while read sampled; do echo "${sampled}" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done ; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r diff}" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "# comparison list" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "comp_list <- list(" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do grep "${stem}" ${input} | cut -f8 | sort | uniq | tr ';' '\n' | while read sample; do echo "                  ${sample}" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "                  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "chrs <- list(\"chr1\", \"chr2\", \"chr3\", \"chr4\", \"chr5\"," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "             \"chr6\", \"chr7\", \"chr8\", \"chr9\", \"chr10\"," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "             \"chr11\", \"chr12\", \"chr13\", \"chr14\", \"chr15\"," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "             \"chr16\", \"chr17\", \"chr18\", \"chr19\", \"chr20\"," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "             \"chr21\", \"chr22\", \"chrX\")" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "             " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "for(chr in chrs){" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  hicdcdiff(input_paths = comp_list," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "          filter_file = paste0(outdir,'/indices.txt.gz')," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "          output_path = paste0(outdir,'/diff_analysis_merged/')," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "          fitType = 'mean'," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "          chrs = chr," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "          binsize = 5000," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "          DESeq.save = TRUE," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "          diagnostics = F)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "}" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "# Plots" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "PCA plots for each chromosome are available below. Please note that with DESeq2 only PC1 and PC2 are stored https://www.biostars.org/p/333436/" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r pca, warning = FALSE, echo=FALSE, eval=TRUE}" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "chrs <- list(\"chr1\", \"chr2\", \"chr3\", \"chr4\", \"chr5\"," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "             \"chr6\", \"chr7\", \"chr8\", \"chr9\", \"chr10\"," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "             \"chr11\", \"chr12\", \"chr13\", \"chr14\", \"chr15\"," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "             \"chr16\", \"chr17\", \"chr18\", \"chr19\", \"chr20\"," >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "             \"chr21\", \"chr22\", \"chrX\")" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "             " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "for(chr in chrs){" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  # size factors" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  x <- readRDS(paste0(outdir,'diff_analysis_merged/',chr,'_DESeq2_obj.rds'))" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  x <- DESeq2::estimateSizeFactors(x)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  # PCA" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  rld <- DESeq2::rlog(x)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  pcaData <- DESeq2::plotPCA(rld, returnData=TRUE)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  percentVar <- round(100 * attr(pcaData, \"percentVar\"))" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  pc1pc2_plot <- ggplot(pcaData, aes(PC1, PC2, colour = condition)) +" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "    geom_point(size=3) + " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "    ggsci::scale_color_igv() + " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "    ggrepel::geom_text_repel(data = pcaData, aes(PC1, PC2, colour = condition, label = name)) +" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "    xlab(paste0(\"PC1: \",percentVar[1],\"% variance\")) +" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "    ylab(paste0(\"PC2: \",percentVar[2],\"% variance\")) +" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "    ggtitle(chr) +" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "    coord_fixed()" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "    " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  print(pc1pc2_plot)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "  ggsave(paste0(outdir,chr,'_PC1-PC2.svg'), plot = pc1pc2_plot)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
# cut -f1 ${input} | sort | uniq | while read stem; do echo "  " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
# cut -f1 ${input} | sort | uniq | while read stem; do echo "  pc2pc3_plot <- ggplot(pcaData, aes(PC2, PC3, colour = condition)) +" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
# cut -f1 ${input} | sort | uniq | while read stem; do echo "    geom_point(size=3) + " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
# cut -f1 ${input} | sort | uniq | while read stem; do echo "    ggsci::scale_color_igv() + " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
# cut -f1 ${input} | sort | uniq | while read stem; do echo "    ggrepel::geom_text_repel(data = pcaData, aes(PC1, PC2, colour = condition, label = name)) +" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
# cut -f1 ${input} | sort | uniq | while read stem; do echo "    xlab(paste0(\"PC1: \",percentVar[1],\"% variance\")) +" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
# cut -f1 ${input} | sort | uniq | while read stem; do echo "    ylab(paste0(\"PC2: \",percentVar[2],\"% variance\")) +" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
# cut -f1 ${input} | sort | uniq | while read stem; do echo "    ggtitle(chr) +" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
# cut -f1 ${input} | sort | uniq | while read stem; do echo "    coord_fixed()" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
# cut -f1 ${input} | sort | uniq | while read stem; do echo "    " >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
# cut -f1 ${input} | sort | uniq | while read stem; do echo "  print(pc2pc3_plot)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
# cut -f1 ${input} | sort | uniq | while read stem; do echo "  ggsave(paste0(outdir,chr,'PC2-PC3.svg'), plot = pc2pc3_plot)" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "}" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${pbs_stem}_${stem}_${thislogdate}.Rmd; done

## Write PBS command lines
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Run step" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Render Rmd at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do outdir=`grep "${stem}" ${input} | cut -f4 | sort | uniq`; echo "Rscript -e \"rmarkdown::render('$PWD/${pbs_stem}_${stem}_${thislogdate}.Rmd', output_dir = '${outdir}')\"" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

#................................................
#  Submit PBS jobs
#................................................

## Submit PBS jobs 
ls ${pbs_stem}_*${thislogdate}.pbs | while read pbs; do echo ; echo "#................................................" ; echo "# This is PBS: ${pbs}" ;  echo "#" ; echo "# main command line(s): $(tail -n1 ${pbs})" ; echo "#" ; echo "# now submitting PBS" ; echo "qsub ${pbs}" ; qsub ${pbs} ; echo "#................................................" ; done

date ## Status of all user jobs (including HIPPO step 071 jobs) at
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