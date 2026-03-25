# Comparative Taxonomic Profiling of the Human Gut Microbiome in Herbivorous and Omnivorous Diets
Metagenomics is the study of genetic material recovered directly from environmental samples such as soil, water, or the human gut without the need to culture individual species in the laboratory (Kushwaha et al., 2022). In this context, it enables the taxonomic classification of microbial communities present within a given environment.

The aim of this project is to evaluate appropriate methods, software tools, and parameter settings for shotgun metagenomic analysis, and to apply these approaches to human gut microbiome data in order to perform comparative taxonomic profiling between herbivorous and omnivorous diets.

Studying the gut microbiome is essential for understanding the composition of microbial communities within the human gut, including bacteria, fungi, and viruses that influence host health, immune regulation, and nutrient metabolism. Alterations in this taxonomic composition which are often referred to as dysbiosis have been associated with a range of diseases and may serve as potential biomarkers for diagnosis and disease monitoring (Hou et al., 2022).

Furthermore, characterizing the microbial composition of a healthy gut can aid in identifying protective communities that resist pathogenic colonization, as well as detecting the emergence of potentially harmful microorganisms. Beyond composition, such analyses also provide insight into microbial function. In this study, a taxonomic approach is used to investigate differential abundance of gut microorganisms in relation to dietary patterns, specifically comparing herbivorous and omnivorous diets (Meeks et al., 2022).

In order to properly study gut microbiome taxonomy across different diets  using shotgun metagenomics, we must use appropriate and effective tools and software for the data provided to achieve accurate results.

## Method Comparison
Kraken2 is a preferred classification tool due to a number of factors. Firstly, when compared to other classification tools like Kraken1 and CLARK, it is considerably faster and also shows an 85% improvement in memory usage in comparison to Kraken1. In comparison to KrakenUniq, its databases can be built faster, and there is extensive availability of reliable prebuilt databases, while still maintaining a comparable false positive rate to KrakenUniq. For a general overview to understand the overall taxonomic structure without a focus on novel organisms, Kraken2 is optimal (Wood et al., 2019).

The Kraken2 standard database is a good choice for an overview analysis, as it has higher classification rates than the MiniKraken and standard-16 databases and uses less storage space than the core nt database, giving it a good balance between accuracy and storage optimization (Liu et al., 2024).

Re-estimation of abundances using Bracken is standard for pipelines using Kraken2, as it overcomes the limitations of Kraken2, which sometimes overestimates abundances (Lu et al., 2016).

ANCOM-BC2 (Analysis of Compositions of Microbiomes with Bias Correction 2) is preferred for this analysis due to its ability to handle the complex challenges of microbiome data and its superior ability to control the false discovery rate in differential abundance analysis when compared to other methods like LOCOM and LinDA (Lin & Peddada, 2023).

# Methods

## Data Acquisition

The dataset used for this analysis was obtained from the NCBI database under BioProject accession SRP126540. It consisted of six samples in SRA file format with files each for both diet types(Vegan and Omnivore diets). SRR files were converted to FASTQ files using SRA Toolkit Release 3.3.0 (The Sequence Read Archive (SRA), n.d.). The prebuilt database(standard) for kraken2 was downloaded from the github page maintained by the creators of the software. 

`-- split files` : ensures fileswith paired reads  get properly read

`-- threads `: was used to specify the number of cores to use while running the program

`--temp` : was used to specify the temporary location to write files to in order to maintain memory usage

## Quality Control

Quality control checks were performed using FastQC v0.12.1 for each individual FASTQ file and were viewed collectively using MultiQC v1.33 (Babraham Bioinformatics - FastQC A Quality Control Tool for High Throughput Sequence Data, n.d.; Ewels et al., 2016).

## Classification
Classification was performed using Kraken2 v2.1.6 with the Kraken2 standard database (Wood et al., 2019). The following parameters were used:

`--db`: to specify the database

`--paired`: to specify paired reads

`--report`: to generate a report file with taxonomic abundances

## Re-estimation
Re-estimation was performed using Bracken v3.0 with the same Kraken2 database and default options to produce a species-level report (Lu et al., 2017).

## Relative abundance
The data were imported into R v4.5.1 using the biomformat package v1.36.0, and Phyloseq v1.52.0 was used to calculate the relative abundance of the respective taxa of interest using the `transform_sample_counts` function and standard R functions for division (McDonald et al., 2012; McMurdie & Holmes, 2013).

## Diversity measures
Alpha diversity plots were generated using the `plot_richness` function from the Phyloseq v1.52.0 package, while beta diversity plots were generated using the ordinate function from the same package. The distance metric chosen was Bray–Curtis to account for differential abundance rather than just presence/absence (McMurdie & Holmes, 2013).

## Differential abundance
Singletons were removed prior to differential abundance analysis, and the data were subsetted to the top 1000 most abundant genera. Differential abundance was calculated using ANCOM-BC2 v2.10.1. The fixed formula and structural zero variable were set to the diet variable, while `lib_cut` was set to 1000 to remove samples with low sequencing depth. Other default parameters were retained to preserve the accuracy of the method (Lin & Peddada, 2023).

# Results 
## Quality Assessment
Quality assessment of raw sequencing reads was performed using FastQC and summarized with MultiQC. Per-base sequence quality scores across all samples were consistently high, with the majority of bases exhibiting Phred quality scores above 30. Per-sequence quality score distributions were tightly clustered, with the majority of reads falling within high-confidence score ranges. Per-base N content was negligible across all samples. The proportion of ambiguous nucleotides (N) remained near zero across read positions, without position-specific spikes. There were little to no overrepresented sequences and adapted content detected by FastQC. Collectively, these quality metrics demonstrate that the sequencing data are of high technical quality and suitable for taxonomic profiling and other downstream  analysis without extensive quality trimming. 
Reports can be seen at [QC reports](https://iroayotoki2.github.io/Metagenomics/)

## Relative Abundance 
Relative abundance plots made at both the phylum and genus level reveal important information about the samples, at the phylum level all the samples consisted largely of 4 main phyla (acidobacteriota, acinomycetota, bacteroidota and bacillota) while at the genus level at least 75% of each sample consisted of a random distribution of about 20 samples while the other 25% was contained the other genera that were not observed in these plots. There is no visible diet based distribution found from this analysis step this is possibly due to small sample size.

![Phyla Plot](Plots/Top20phyla.jpeg)

Figure 1: Top 20 Phylum-Level Relative Abundance Across Samples
Stacked bar plot illustrating the relative abundance of the top 20 phyla across all samples. Each bar corresponds to an individual sample grouped by diet (Omnivore vs. Vegan). The plot reveals overall taxonomic structure at a higher classification level, showing dominant phyla shared across samples as well as variation in their relative proportions between dietary groups
![Genus Plot](Plots/Top20genus.jpeg)

Figure 2: Top 20 Genus-Level Relative Abundance Across Samples
Stacked bar plot showing the relative abundance of the top 20 most abundant genera across all samples, with remaining genera grouped as “Other.” Each bar represents an individual sample categorized by diet (Omnivore vs. Vegan). Differences in genus composition highlight variability both within and between dietary groups, with certain genera showing higher relative abundance in specific diets.

## Alpha Diversity 
Alpha diversity analysis revealed differences in richness and evenness between diet groups. Richness-based metrics, including Observed features, Chao1, ACE, and Fisher indices, were generally higher in omnivore samples compared to vegetarian samples, suggesting increased taxonomic richness in the omnivore group. However, substantial variability was observed among omnivore replicates, including one notably low-richness sample. In contrast, vegetarian samples displayed more consistent richness estimates. Shannon diversity values were comparable between the two groups, indicating that overall diversity, accounting for both richness and evenness, did not differ markedly. However, Simpson and inverse Simpson indices highlighted reduced evenness in at least one omnivore sample, consistent with dominance by a few taxa, whereas vegetarian samples exhibited more uniform community structure. Overall, these results suggest that while omnivore-associated communities may harbor greater richness, vegetarian-associated communities appear more even and less variable across samples.
![Alpha diversity Plot](Plots/Alpha_Diversity.jpeg)

Figure 3:  Alpha diversity across omnivore and vegetarian samples using multiple metrics (Observed, Chao1, ACE, Shannon, Simpson, inverse Simpson, Fisher). Omnivore samples generally show higher richness but greater variability, including a low-richness outlier, while vegetarian samples display more consistent diversity. Shannon values are similar between groups, whereas Simpson-based indices indicate more even community structure in vegetarian samples.
