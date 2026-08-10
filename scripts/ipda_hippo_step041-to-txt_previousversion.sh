#!/bin/bash

version="1.0.00"
usage(){
echo "
Written by Isabela Almeida
Created on Jul 04, 2024
Last modified on Aug 11, 2026
Version: ${version}

Description: Write and submit PBS jobs for step 041 of HIPPO
(HiChIP Integration Pipeline for PBS Operations).

Usage: bash ipda_hippo_step041-to-txt.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"

Resources baseline: -m 500 -c 2 -w "150:00:00"
Note: This will only need 1 GB, 1 CPU and a couple of seconds.
      However, resources must match those used for submissing hippo_step051.

## Input:

-i <path/to/input/files>    Input TSV files including path FROM working
                            directory. This TSV file should contain:
                            
                            Col1:
                            path/from/working/dir/to/raw/data/folder/
                            Note: put "/" at the end of path!

                            Col2:
                            PAIR1_EXT
                            e.g. _R1 or _1

                            Col3:
                            PAIR2_EXT
                            e.g. _R2 or _2

                            Col4:
                            path/from/working/dir/to/bowtie2/index

                            Col5:
                            stem of reference genome

                            Col6:
                            path/from/working/dir/to/chrom.genome-stem.sizes

                            Col7:
                            path/from/working/dir/to/genome-stem_enzymes.bed

                            Col8:
                            ligation-site1_ligation-site2_ligation-siten
                            e.g.: For the Arima kit:
                            GATCGATC_GAATGATC_GACTGATC_GAGTGATC_GATTGATC_GAATAATC_GAATACTC_GAATAGTC_GAATATTC_GACTAATC_GACTACTC_GACTAGTC_GACTATTC_GAGTAATC_GAGTACTC_GAGTAGTC_GAGTATTC_GATTAATC_GATTACTC_GATTAGTC_GATTATTC_GATCAATC_GATCACTC_GATCAGTC_GATCATTC

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
#-->040 Create HiChIP config files (1Bash)
#   050 Run HiC-Pro complete workflow (1HiC-Pro)
#   060 Construct features (1HiCDC+)
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
        ?) echo script usage: bash ipda_hippo_step041-to-txt.sh -i path/to/input/files -p PBS stem -e email -m INT -c INT -w "HH:MM:SS" >&2
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
logfile=logfile_ipda_hippo_step041-to-txt_${thislogdate}.txt

#................................................
#  Required modules, softwares and libraries
#................................................

# Samtools 1.17
module_samtools=samtools/1.17

#................................................
#  Print Execution info to user
#................................................

date
echo "## Executing bash ipda_hippo_step041-to-txt.sh"
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
echo "## Executing bash ipda_hippo_step041-to-txt.sh"
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
#  Create HiC-Pro config files
#................................................

## Write HiC-Pro config files
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "# Please change the variable settings below if necessary" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done

cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#########################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "## Paths and Settings  - Do not edit !" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#########################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "TMP_DIR = tmp" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "LOGS_DIR = logs" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "BOWTIE2_OUTPUT_DIR = bowtie_results" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "MAPC_OUTPUT = hic_results" >> config-hicpro_${file}_${thislogdate}.txt; done
#cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "RAW_DIR = rawdata" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done

cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "## SYSTEM AND SCHEDULER - Start Editing Here !!" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "N_CPU = ${ncpus}" >> config-hicpro_${file}_${thislogdate}.txt; done
#cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "SORT_RAM = 768M" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "LOGFILE = hicpro_${pbs_stem}.log" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "JOB_NAME = ${pbs_stem}" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "JOB_MEM = ${mem}" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "JOB_WALLTIME = ${walltime}" >> config-hicpro_${file}_${thislogdate}.txt; done
#cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "JOB_QUEUE = bigmen" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "JOB_MAIL = ${email}" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done

cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#########################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "## Data" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#########################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "RAW_DIR = rawdata" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; pair1ext=`grep "${path_folder}" ${input} | cut -f2 | sort | uniq`; echo "PAIR1_EXT = ${pair1ext}" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; pair2ext=`grep "${path_folder}" ${input} | cut -f3 | sort | uniq`; echo "PAIR2_EXT = ${pair2ext}" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done

cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "## Alignment options" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "FORMAT = phred33" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "MIN_MAPQ = 20" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; bt2index=`grep "${path_folder}" ${input} | cut -f4 | sort | uniq`; echo "BOWTIE2_IDX_PATH = ${bt2index}" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "BOWTIE2_GLOBAL_OPTIONS = --very-sensitive -L 30 --score-min L,-0.6,-0.2 --end-to-end --reorder" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "BOWTIE2_LOCAL_OPTIONS =  --very-sensitive -L 20 --score-min L,-0.6,-0.2 --end-to-end --reorder" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done

cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "## Annotation files" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; refstem=`grep "${path_folder}" ${input} | cut -f5 | sort | uniq`; echo "REFERENCE_GENOME = ${refstem}" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; chrsizes=`grep "${path_folder}" ${input} | cut -f6 | sort | uniq`; echo "GENOME_SIZE = ${chrsizes}" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done

cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "## Allele specific analysis" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "ALLELE_SPECIFIC_SNP = " >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done

#cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
#cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "## Capture Hi-C analysis" >> config-hicpro_${file}_${thislogdate}.txt; done
#cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
#cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done
#cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "CAPTURE_TARGET =" >> config-hicpro_${file}_${thislogdate}.txt; done
#cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "REPORT_CAPTURE_REPORTER = 1" >> config-hicpro_${file}_${thislogdate}.txt; done
#cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done

cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "## Digestion Hi-C" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; fragments=`grep "${path_folder}" ${input} | cut -f7 | sort | uniq`; echo "GENOME_FRAGMENT = ${fragments}" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; ligation=`grep "${path_folder}" ${input} | cut -f8 | sort | uniq`; echo ${ligation} | tr '_' '\n' | while read site; do echo "LIGATION_SITE = ${site}" >> config-hicpro_${file}_${thislogdate}.txt; done; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "MIN_FRAG_SIZE = 100" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "MAX_FRAG_SIZE = 100000" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "MIN_INSERT_SIZE =" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "MAX_INSERT_SIZE =" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done

cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "## Hi-C processing" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "MIN_CIS_DIST =" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "GET_ALL_INTERACTION_CLASSES = 1" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "GET_PROCESS_SAM = 0" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "RM_SINGLETON = 1" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "RM_MULTI = 1" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "RM_DUP = 1" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done

cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "## Contact Maps" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "BIN_SIZE = 5000 20000 40000 150000 500000" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "MATRIX_FORMAT = complete" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done

cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "## Normalization" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "#######################################################################" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "MAX_ITER = 100" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "FILTER_LOW_COUNT_PERC = 0.02" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "FILTER_HIGH_COUNT_PERC = 0" >> config-hicpro_${file}_${thislogdate}.txt; done
cut -f1 ${input} | sort | uniq | while read path_folder; do file=`echo ${path_folder} | rev | cut -d"/" -f2 | rev` ; echo "EPS = 0.1" >> config-hicpro_${file}_${thislogdate}.txt; done

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
sed -i 's,${pair1ext},'"${pair1ext}"',g' "$logfile"
sed -i 's,${pair2ext},'"${pair2ext}"',g' "$logfile"
sed -i 's,${bt2index},'"${bt2index}"',g' "$logfile"
sed -i 's,${refstem},'"${refstem}"',g' "$logfile"
sed -i 's,${chrsizes},'"${chrsizes}"',g' "$logfile"
sed -i 's,${fragments},'"${fragments}"',g' "$logfile"
sed -i 's,${ligation},'"${ligation}"',g' "$logfile"
sed -i 's,${logfile},'"${logfile}"',g' "$logfile"
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > tmp ; mv tmp $logfile
set +v