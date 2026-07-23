#!/bin/bash

version="1.0.0"
usage(){
echo "
Written by Isabela Almeida
Created on Jul 22, 2026
Last modified on Jul 22, 2026
Version: ${version}

Description: Write and submit PBS jobs for step 111 of HIPPO
(HiChIP Integration Pipeline for PBS Operations).

Usage: bash ipda_hippo_step111-to-pbs.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"

Resources used for pipeline in-house: -m 1 -c 1 -w "01:00:00"

## Input:

-i <path/to/input/files>    Input TSV files including path FROM working
                            directory. This TSV file should contain:
                            
                            Col1:
                            sample-stem

                            Col2:
                            /path/from/working/dir/to/bowtie_results/bwt2/data/input.bwt2pairs.bam
                            Note: from HIPPO 050 step if multiple input.bam files, then space separate these,
                            e.g. /path/from/working/dir/to/input1.bam /path/from/working/dir/to/input2.bam
                            and flag merge yes on col3

                            Col3:
                            yes|no
                            yes to merge the different BAM files, where Col1 remains the same but different files are space separated
                            no to proceed without merging - single file provided.

                            Col4:
                            INT
                            1-based bins where interactions are dispersed. 
                            This is the bin size used for the interaction calls in step 060 of HIPPO.

                            Col5:
                            INT
                            chromosome of lower interaction window,
                            e.g. 17 for window 17:30890001-30895000

                            Col6:
                            INT
                            start coordinate of lower interaction window,
                            eg. 30890001 for window 17:30890001-30895000

                            Col7:
                            INT
                            chromosome of upper interaction window,
                            e.g. 17 for window 17:32205001-32210000

                            Col8:
                            INT
                            start coordinate of upper interaction window,
                            eg. 32205001 for window 17:32205001-32210000

                            Col9:
                            stem-window-of-interest
                            For each window of interest, provide a window stem,
                            e.g. rs62070652 if looking for that SNP

                            Col10:
                            SNP-coordinates
                            Note: structure as 17:30894259-30894259

                            Col11:
                            /path/from/working/dir/to/reference.genome.fasta

                            It does not matter if same stem 
                            appears more than once on this input file,
                            as long as it is associated with only one counts.tsv file.
                            Use stem to combine different samples (in counts.tsv) in the same plot.

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
#   090 Create UCSC browser tracks (1 txt.gz, 2 pgl)
#   100 Intersect calls with BED coordinates (1pgltools)
#-->110 Targeted allele-specific looping (1SamTools, 2R plots)

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
        ?) echo script usage: bash ipda_hippo_step111-to-pbs.sh -i path/to/input/files -p PBS stem -e email -m INT -c INT -w "HH:MM:SS" >&2
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
logfile=logfile_ipda_hippo_step111-to-pbs_${thislogdate}.txt

#................................................
#  Set and create output path
#................................................

## Set stem for output directories
outpath_hippo111_samtools="hippo111_asl_SamTools_${thislogdate}"

## Create output directories
mkdir -p ${outpath_hippo111_samtools}

#................................................
#  Required modules, softwares and libraries
#................................................

# SamTools 1.9
module_Samtools="samtools/1.9"

#................................................
#  Print Execution info to user
#................................................

date
echo "## Executing bash ipda_hippo_step111-to-pbs.sh"
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
echo "## Output files saved to:       ${outpath_hippo111_samtools}"
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
echo "## Executing bash ipda_hippo_step111-to-pbs.sh"
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
echo "## Output files saved to:       ${outpath_hippo111_samtools}"
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
cut -f1 ${input} | sort | uniq | while read stem; do echo "#PBS -m abe" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
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
cut -f1 ${input} | sort | uniq | while read stem; do echo "module load ${module_Samtools}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done


## Write PBS command lines
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Run step" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Merge input BAM files at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do flag_merge=`grep "${stem}" ${input} | cut -f3 | sort | uniq`; if [[ $flag_merge = "yes" ]]; then mergebam=`grep "${stem}" ${input} | cut -f2 | sort | uniq`; echo "samtools cat -o ${outpath_hippo111_samtools}/${stem}.merged.bam ${mergebam}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; elif [[ $flag_merge = "no" ]]; then echo "#Flag to do not merge file" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; else echo "Unknown flag provided. Please provide either yes or no and try again" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; fi; done
cut -f1 ${input} | sort | uniq | while read stem; do flag_merge=`grep "${stem}" ${input} | cut -f3 | sort | uniq`; if [[ $flag_merge = "yes" ]]; then echo "inputbam=\"${outpath_hippo111_samtools}/${stem}.merged.bam\"" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; elif [[ $flag_merge = "no" ]]; then nonmergebam=`grep "${stem}" ${input} | cut -f2 | sort | uniq`; echo "inputbam=\"${nonmergebam}\"" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; else echo "Unknown flag provided. Please provide either yes or no and try again" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; fi; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Sort input BAM files at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "samtools sort -@${ncpus} -o ${outpath_hippo111_samtools}/${stem}.sorted.bam \${inputbam}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Index BAM file at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "samtools index -@${ncpus} ${outpath_hippo111_samtools}/${stem}.sorted.bam" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Find correct bins at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do grep "${stem}" ${input} | cut -f9 | sort | uniq | while read window; do bin=`grep "${stem}" ${input} | cut -f4 | sort | uniq`; chr1=`grep -E "${stem}.*${window}" ${input} | cut -f5 | sort | uniq`; start1=`grep -E "${stem}.*${window}" ${input} | cut -f6 | sort | uniq`; chr2=`grep -E "${stem}.*${window}" ${input} | cut -f7 | sort | uniq`; start2=`grep -E "${stem}.*${window}" ${input} | cut -f8 | sort | uniq`; echo "chr1=${chr1}; startr1=${start1}; bin=${bin}; startw1=\$(( (startr1-1)/bin*bin + 1 )); endw1=\$(( startw1 + bin - 1 )); ${window}_coordw1=\`echo "\${chr1}:\${startw1}-\${endw1}"\`\tchr2=${chr2}; startr2=${start2}; bin=${bin}; startw2=\$(( (startr2-1)/bin*bin + 1 )); endw2=\$(( startw2 + bin - 1 )); ${window}_coordw2=\`echo "\${chr2}:\${startw2}-\${endw2}"\`" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Filter BAM file to window coordinates of interest at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do grep "${stem}" ${input} | cut -f9 | sort | uniq | while read window; do echo "samtools view -@${ncpus} -b -h ${outpath_hippo111_samtools}/${stem}.sorted.bam \${${window}_coordw1} \${${window}_coordw2} > ${outpath_hippo111_samtools}/${stem}.${window}.bam" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Index window BAM files at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do grep "${stem}" ${input} | cut -f9 | sort | uniq | while read window; do echo "samtools index -@${ncpus} ${outpath_hippo111_samtools}/${stem}.${window}.bam" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Count ref and alt allele occurrences at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do grep "${stem}" ${input} | cut -f9 | sort | uniq | while read window; do snp=`grep -E "${stem}.*${window}" ${input} | cut -f10 | sort | uniq`; ref=`grep "${stem}" ${input} | cut -f11 | sort | uniq`; echo "samtools mpileup -f ${ref} -r ${snp} -o ${outpath_hippo111_samtools}/${stem}.${window}.mpileup ${outpath_hippo111_samtools}/${stem}.${window}.bam" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Write counts to file at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo -e \"sample\tref\talt\ttotal\" >> ${outpath_hippo111_samtools}/${stem}.counts; grep "${stem}" ${input} | cut -f9 | sort | uniq | while read window; do echo "ref=\`cut -f5 ${outpath_hippo111_samtools}/${stem}.${window}.mpileup.txt | awk '{print gsub(/[.,]/, "")}'\`; alt=\`cut -f5 ${outpath_hippo111_samtools}/${stem}.${window}.mpileup | awk '{print gsub(/[ACGTNacgtn]/, "")}'\`; total=$((ref + alt)) echo -e \"${stem}_${window}\t\${ref}\t\${alt}\t\${total}\" >> ${outpath_hippo111_samtools}/${stem}.counts" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done; done

#................................................
#  Submit PBS jobs
#................................................

## Submit PBS jobs 
ls ${pbs_stem}_*${thislogdate}.pbs | while read pbs; do echo ; echo "#................................................" ; echo "# This is PBS: ${pbs}" ;  echo "#" ; echo "# main command line(s): $(tail -n20 ${pbs} | head -n1)" ; echo "#                       $(tail -n22 ${pbs} | head -n1)"; echo "#                       $(tail -n21 ${pbs} | head -n1)"; echo "#                       $(tail -n18 ${pbs} | head -n1)"; echo "#                       $(tail -n15 ${pbs} | head -n1)"; echo "#                       $(tail -n12 ${pbs} | head -n1)"; echo "#                       $(tail -n10 ${pbs} | head -n1)"; echo "#                       $(tail -n7 ${pbs} | head -n1)"; echo "#                       $(tail -n4 ${pbs} | head -n1)"; echo "#                       $(tail -n1 ${pbs})"; echo "#" ; echo "# now submitting PBS" ; echo "qsub ${pbs}" ; qsub ${pbs} ; echo "#................................................" ; done

date ## Status of all user jobs (including HIPPO step 111 jobs) at
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
sed -i 's,${module_Samtools},'"${module_Samtools}"',g' "$logfile"
sed -i 's,${outpath_hippo111_samtools},'"${outpath_hippo111_samtools}"',g' "$logfile"
sed -i 's,${logfile},'"${logfile}"',g' "$logfile"
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > tmp ; mv tmp $logfile
set +v