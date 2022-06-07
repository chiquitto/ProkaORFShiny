# if (!requireNamespace("BiocManager", quietly = TRUE))
#   install.packages("BiocManager")
# BiocManager::install("karyoploteR")

library(karyoploteR)
library(dplyr)

library(reticulate)
use_python('/usr/bin/python3')

orf.script = 'orf_finder.py'
orf.result <- source_python(orf.script)

sample.orf.file = '/home/alisson/work/github_chiquitto_ProkaORFShiny/samples/Random1.fa'
df.orf <- print_csv(sample.orf.file , 15)

df.orf <- df.orf %>% filter(seq_pos == 0)

chr.name <- function(df) {
  return (paste0("Seq", df$seq_pos, "[", df$strand, ",", df$frame, "]"))
}

# Sequence data

seq.df <- df.orf %>%
  group_by(seq_pos, strand, frame) %>%
  summarise(
    seq_len = max(seq_len)
  )

chr.data <- c()
end.data <- c()
for (row in 1:nrow(seq.df)) {
  chr.data[row] <- chr.name(seq.df[row,])
  end.data[row] <- seq.df[row, "seq_len"]
}
start.data = rep(1, row)
custom.genome <- toGRanges(data.frame(chr=chr.data, start=start.data, end=end.data))

# Cytobands data

pos <- list()
chr.data <- c()
start.data <- c()
end.data <- c()
name.data <- c()
gieStain.data <- c()
i <- 1

for (row in 1:nrow(df.orf)) {
  key <- chr.name(df.orf[row,])
  
  if (is.null(pos[[key]])) {
    pos[key] <- 0
    
    chr.data[i] <- chr.name(df.orf[row,])
    start.data[i] <- 1
    end.data[i] <- df.orf[row, "seq_len"]
    name.data[i] <- paste0(chr.data[row], "nnn")
    gieStain.data[i] <- "gpos25"
    i <- i + 1
  }
  
  chr.data[i] <- chr.name(df.orf[row,])
  start.data[i] <- df.orf[row, "pos_start"]
  end.data[i] <- df.orf[row, "pos_end"]
  name.data[i] <- paste0(chr.data[row], "orf")
  gieStain.data[i] <- "acen"
  
  i = i + 1
}
custom.cytobands <- toGRanges(data.frame(chr=chr.data, start=start.data, end=end.data, name=name.data, gieStain=gieStain.data))

pp <- getDefaultPlotParams(plot.type=6)
pp$leftmargin <- 0.15
kp <- plotKaryotype(genome = custom.genome, cytobands = custom.cytobands, plot.type=6, plot.params = pp)
