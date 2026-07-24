args <- commandArgs(trailingOnly = TRUE)
input_counts <- args[which(args == "--inputc") + 1]
outdir <- args[which(args == "--outdir") + 1]
outstem <- args[which(args == "--outstem") + 1]

print_help <- function() {
  cat("
Written by Isabela Almeida
Created on Jul 21, 2026
Last modified on Jul 22, 2026
Version: 1.0.0

Description: Write and submit PBS jobs for step 112 of HIPPO
(HiChIP Integration Pipeline for PBS Operations).

Usage: Rscript ipda_hippo_step112.r [options]

Options:
  --inputc FILE          Compilation of all sample TSV files from hippo111_asl_SamTools_DATE with header
                         e.g. grep 'sample' hippo111_asl_SamTools_DATE/*.counts.tsv > counts.tsv;
                         grep -v 'sample' hippo111_asl_SamTools_DATE/*.counts.tsv >> counts.tsv
  --outdir DIR           Output directory
  --outstem STEM         Output file stem
  --help                 Show this help message

Example:
  Rscript ipda_hippo_step112.r --inputc /path/from/working/dir/to/counts.tsv --outdir /path/from/working/dir/to/hippo112_asl-plots_R_DATE --outstem stem

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
\n")
}

# Show help if requested or no args
if (length(args) == 0 || "--help" %in% args) {
  print_help()
  quit(save = "no")
}

## Load libraries
library(ggplot2)
library(tidyr)
library(RColorBrewer)
library(dplyr)

## Set input/output paths
out_pointrange <- file.path(outdir, paste0(outstem, ".pointrange.pdf"))
out_barplot <- file.path(outdir, paste0(outstem, ".counts.pdf"))
out_binomialplot <- file.path(outdir, paste0(outstem, ".binomdist.pdf"))

## Import data/metadata
counts <- read.delim(input_counts, header = TRUE, stringsAsFactors = FALSE)

## Run binomial test for every sample
counts <- counts %>%
  rowwise() %>%
  mutate(
    bt = list(binom.test(c(ref, alt)))
  ) %>%
  mutate(
    p = bt$estimate,
    lower = bt$conf.int[1],
    upper = bt$conf.int[2],
    p.value = bt$p.value,
    significance = case_when(
      p.value < 0.001 ~ "***",
      p.value < 0.01  ~ "**",
      p.value < 0.05  ~ "*",
      TRUE            ~ "ns"
    )
  ) %>%
  select(-bt) %>%
  ungroup()

counts_long <- pivot_longer(
  counts,
  cols = c(ref, alt),
  names_to = "allele",
  values_to = "count"
)

binom_counts <- counts %>%
  rowwise() %>%
  do({
    data.frame(
      sample = .$sample,
      Successes = 0:.$total,
      Probability = dbinom(
        0:.$total,
        size = .$total,
        prob = 0.5
      ),
      observed = .$ref,
      direction = ifelse(
        .$ref > .$total / 2,
        "Ref enriched",
        "Alt enriched"
      ),
      p.value = .$p.value,
      significance = .$significance
    )
  }) %>%
  ungroup()


## Source functions
pointrangeplot <- function(counts){
    ggplot(counts, aes(x = sample , y = p)) +
    geom_pointrange(aes(ymin = lower, ymax = upper),
                  size = 0.8) +
    geom_hline(yintercept = 0.5,
             linetype = 2,
             colour = "red") +
    labs(
        x = "",
        y = "Reference allele fraction"
    ) +
    theme_classic(base_size = 13)
}

barplot <- function(counts_long) {
  ggplot(counts_long, aes(allele, count, fill = allele)) +
    geom_col(width = 0.7) +
    facet_wrap(~sample) +
    scale_fill_brewer(palette = "Blues") +
    theme_classic(base_size = 13)+
    theme(
        legend.position = "none",
        panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.7),
        strip.text = element_text(face = "bold")
    )
}

binomialplot <- function(binom_counts) {
  annotation_df <- binom_counts %>%
    group_by(sample) %>%
    summarise(
      observed = first(observed),
      direction = first(direction),
      significance = first(significance),
      p.value = first(p.value),
      max_probability = max(Probability),
      .groups = "drop"
    )

  ggplot(binom_counts, aes(x = Successes, y = Probability)) +
  geom_segment(
    aes(x = Successes, xend = Successes, y = 0, yend = Probability),
    linewidth = 0.3, colour = "black"
  ) +
  geom_vline(aes(xintercept = observed), colour = "#2166AC", linewidth = 0.6) +
  geom_text(
    data = annotation_df,
    aes(
      x = observed,
      y = 0.125,
      label = paste0("Ref = ", observed, "\n", direction, "\n", significance, " (p = ", format.pval(p.value, digits = 3), ")")
    ),
    colour = "#2166AC",
    nudge_x = 0.5,
    hjust = 0,
    size = 2,
    fontface = "plain"
  ) +
  facet_wrap(~sample, scales = "free_x") +
  labs(
    subtitle = "Null hypothesis: p = 0.5",
    x = "Number of reference reads",
    y = "Probability"
  ) +
  theme_classic(base_size = 13) +
  theme(
    strip.background = element_blank()
  ) +
  coord_cartesian(clip = "off")
}

# Error bar plot showing estimated reference allele fractions (95% CIs)
pointrange <- pointrangeplot(counts)
ggsave(file.path(out_pointrange), plot = pointrange, width = 5, height = 5, dpi = 100)

# Counts
barplotcounts <- barplot(counts_long)
ggsave(file.path(out_barplot), plot = barplotcounts, width = 5, height = 5, dpi = 100)

# Binomial distribution
binomdist <- binomialplot(binom_counts)
ggsave(file.path(out_binomialplot), plot = binomdist, width = 5, height = 5, dpi = 100)