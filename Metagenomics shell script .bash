#Assignment3
mkdir -p Assignment3 && cd Assignment3

#Generating the fastq files from the SRR files using the SRA toolkit
for SRR in ./SRR*
do
fasterq-dump "$SRR" 
  --split-files \
  --threads 8 \
  --temp /scratch/$USER
done
fastqc SRR*.fastq
multiqc .
sbatch kraken2_script.sh
for REPORT in *.report
do
  BASE=${REPORT%.report}
  bracken -d ~/scratch/kraken_db -i "$REPORT" -o "${BASE}.bracken" -r 150
done
mv SRR8146935_bracken_species.report Omnivore_1.report
mv SRR8146936_bracken_species.report Omnivore_2.report
mv SRR8146937_bracken_species.report Vegan_1.report
mv SRR8146938_bracken_species.report Omnivore_3.report
mv SRR8146939_bracken_species.report Vegan_2.report
mv SRR8146940_bracken_species.report Vegan_3.report
kraken-biom Omnivore_1.report Omnivore_2.report Omnivore_3.report Vegan_1.report Vegan_2.report Vegan_3.report

#scp from DRAC to local system from terminal
scp  -r "iroayo@narval.alliancecan.ca:/home/iroayo/scratch/kraken2_results/results" C:\Users\User\Downloads\Metagenomics_results\
scp  -r "iroayo@narval.alliancecan.ca:/home/iroayo/scratch/kraken2_script.sh" C:\Users\User\Downloads\Metagenomics_results\