

library(phyloseq)
library(biomformat)
library(vegan)
library(ggplot2)
library(dplyr)
library(ANCOMBC)
library(microbiome)
library(RColorBrewer)
#1. Import and Create data  object----
# Read the BIOM file
biom_data <- read_biom("results/table.biom")
physeq <- import_biom(biom_data)
physeq

#import the metadata
metadata <-  read.csv("metagenomics_metadata.csv")
#2. Data Exploration and transformation -----
#Aligning names
row.names(metadata) <- metadata[ ,3]
row.names(metadata)
sample_names(physeq)

sample_data(physeq) <- metadata
sample_data(physeq)
# Rarefaction
#High stepsize used due to sample depth
otu_table <- as.data.frame(t(otu_table(physeq)))
rare_curve <- rarecurve(otu_table, step = 100000)

#3. Relative abundance transformation and plots----
physeq_rel <- transform_sample_counts(physeq, function(x) x / sum(x))
#Plot showing relative abundance of all phyla present in the samples
physeq_phy <- tax_glom(physeq_rel, taxrank = "Rank2")
df <- psmelt(physeq_phy)
ggplot(df, aes(x = Sample, y = Abundance, fill = Rank2)) +
  geom_bar(stat = "identity", position = "stack") +
  labs(y = "Relative Abundance", x = "Sample")


#Global Top 20 Phyla
rank_phylum <- "Rank2"

# Sum OTU abundances by phylum across all samples
phyla_sums <- tapply(taxa_sums(physeq_rel), tax_table(physeq_rel)[, rank_phylum], sum, na.rm = TRUE)

# Select top 20 phyla
top20_phyla <- names(sort(phyla_sums, decreasing = TRUE))[1:20]

# Keep only OTUs belonging to top 20 phyla
physeq_top20_phyla <- prune_taxa(tax_table(physeq_rel)[, rank_phylum] %in% top20_phyla, physeq_rel)


# Melt for plotting
df_phyla <- psmelt(physeq_top20_phyla)


# Create enough colors for all phyla, including "Other"
num_phyla <- length(unique(df_phyla[[rank_phylum]]))
phyla_colors <- setNames(
  colorRampPalette(brewer.pal(12, "Set3"))(num_phyla),
  unique(df_phyla[[rank_phylum]])
)
# Plot global top 20 phyla
ggplot(df_phyla, aes(x = Sample, y = Abundance, fill = .data[[rank_phylum]])) +
  geom_bar(stat="identity") +
  scale_fill_manual(values = phyla_colors) +
  theme(axis.text.x = element_text(angle=90, hjust=1)) +
  labs(y="Relative abundance", fill="Phylum") +
  ggtitle("Global Top 20 Phyla Across Samples")

#Top 20 Genus
rank_genus <- "Rank6"

# Extract genus column safely
genus_vec <- as.vector(tax_table(physeq_rel)[, rank_genus])

# Replace NA / empty / unknown with "Unclassified"
genus_vec[is.na(genus_vec) | genus_vec == "" | genus_vec == " "] <- "Unclassified"


# Aggregate at genus level
physeq_genus <- tax_glom(physeq_rel, taxrank = rank_genus, NArm = FALSE)

# Melt for easier manipulation
df_genus <- psmelt(physeq_genus)

# Top 20 genus globally
top20_genus <- df_genus %>%
  group_by(.data[[rank_genus]]) %>%
  summarise(TotalAbundance = sum(Abundance), .groups = "drop") %>%
  arrange(desc(TotalAbundance)) %>%
  slice_head(n = 20) %>%
  pull(.data[[rank_genus]])

# Mark others as "Other"
df_genus <- df_genus %>%
  mutate(Genus = ifelse(.data[[rank_genus]] %in% top20_genus,
                          as.character(.data[[rank_genus]]),
                          "Other"))

# Colors for each genus to give distinct coloring

num_genus <- length(unique(df_genus$Genus))
genus_colors <- setNames(
  colorRampPalette(brewer.pal(12, "Paired"))(num_genus),
  unique(df_genus$Genus)
)

# Plot
#Genus used to avoid misclassification at specie level
ggplot(df_genus, aes(x = Sample, y = Abundance, fill = Genus)) +
  geom_bar(stat="identity") +
  scale_fill_manual(values = genus_colors) +
  theme(axis.text.x = element_text(angle=90, hjust=1)) +
  labs(y="Relative abundance", fill="Genus") +
  ggtitle("Top 20 Genus with Others Grouped")
#4. Alpha diversity----
plot_richness(physeq, color = "Diet")

#5. Beta Diversity ----
#PCoA with bray-curtis.
ord.pcoa.bray <- ordinate(physeq, method="PCoA", distance="bray")
plot_ordination(physeq, ord.pcoa.bray, color="Diet", title="Bray PCoA") + geom_point(size = 4)

# NMDS with  bray-curtis.
ord.nmds.bray <- ordinate(physeq, method="NMDS", distance="bray")
plot_ordination(physeq, ord.nmds.bray, color="Diet", title="Bray NMDS") + geom_point(size = 4)
#PERMANOVA
#No significance seen 
PERMANOVA <- adonis2(phyloseq::distance(physeq, method = "bray") ~ Diet, data = metadata)
PERMANOVA


#6. Differential Abundance ----

#Subsetting to top 1000 genera for computational feasibility


physeq_genus2 <- tax_glom(physeq, taxrank = "Rank6")
# Get top 1000 genera globally
top_taxa <- names(sort(taxa_sums(physeq_genus2), decreasing = TRUE))[1:1000]

# Prune to top 1000
physeq_top1000 <- prune_taxa(top_taxa, physeq_genus2)
#Removing genera only present in 1 sample
physeq_top1000 <- prune_taxa(
  rowSums(otu_table(physeq_top1000) > 0) >= 2,
  physeq_top1000
)

#Creating new Diet variable to be used for structural zeroes
metadata$Diet_S0 <- metadata$Diet
sample_data(physeq) <- metadata
#ANCOMBC
ancombc.out <- ancombc2(data = physeq_top1000, tax_level = "Rank6",
                        fix_formula = "Diet", rand_formula = NULL,
                        p_adj_method = "holm", pseudo_sens = F,
                        prv_cut = 0, lib_cut = 1000, s0_perc = 0.05,
                        group = "Diet_S0", struc_zero = TRUE, neg_lb =F)

aancombc.out$zero_ind
#Only 3 genera that are missing across the whole Omnivore group
subset(ancombc.out$zero_ind, 
       `structural_zero (Diet_S0 = Vegetarian)` != `structural_zero (Diet_S0 = Omnivore)`)
#Checking the differential abundances
#No statistical significance
ancombc.out$res
ancombc.sig <- subset(ancombc.out$res, q_DietVegetarian < 0.05)
ancombc.sig

#LFC taxa 
lfc_df <- ancombc.out$res 


#Select top 30 by absolute LFC (only for non-structural zeros)
top_lfc <- lfc_df %>%
  arrange(desc(abs(lfc_DietVegetarian))) %>%
  slice_head(n = 30)


# Plot
ggplot(top_lfc, aes(x = lfc_DietVegetarian,
                    y = reorder(taxon, lfc_DietVegetarian))) +
  geom_point(size = 3, shape = ifelse(is.na(top_lfc$lfc_DietVegetarian), 4, 16)) +
  geom_errorbar(aes(xmin = lfc_DietVegetarian - se_DietVegetarian,
                    xmax = lfc_DietVegetarian + se_DietVegetarian),
                na.rm = TRUE) +
  geom_vline(xintercept = 0, color = "red") +
  labs(x = "Log Fold Change (DietVegetarian)",
       y = "Taxon")