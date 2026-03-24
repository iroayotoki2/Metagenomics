#!/bin/bash
#SBATCH --account=def-cottenie
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --time=08:00:00
#SBATCH --job-name=kraken2_array
#SBATCH --output=kraken2_%A_%a.out
#SBATCH --array=0-5

module load StdEnv/2023 kraken2/2.1.6

DB=/home/iroayo/scratch/kraken_db
OUTDIR=$SCRATCH/kraken2_results
FASTQDIR=/home/iroayo/scratch/Assignment3/fastq_files

mkdir -p "$OUTDIR"

FILES=("$FASTQDIR"/*_1.fastq)

IN1=${FILES[$SLURM_ARRAY_TASK_ID]}
BASE=$(basename "$IN1" _1.fastq)
IN2="$FASTQDIR/${BASE}_2.fastq"

kraken2 \
  --db "$DB" \
  --threads $SLURM_CPUS_PER_TASK \
  --paired "$IN1" "$IN2" \
  --report "$OUTDIR/${BASE}.report" \
  --output "$OUTDIR/${BASE}.out"
