library(dplyr)

# R genomic map
# install.packages("chromoMap")
library(chromoMap)

library(reticulate)
use_python('/usr/bin/python3')

orf.script = 'orf_finder.py'
orf.result <- source_python(orf.script)

sample.orf.file = '/home/alisson/work/github_chiquitto_ProkaORFShiny/samples/Random1.fa'

res.table <- print_csv(sample.orf.file , 15)

# res.table <- head(res.table, n = 10)

res.table <- res.table[, -which(names(res.table) %in% c("orf", "orf_nt", "orf_aa"))]
# res.table$cobertura = res.table$orf_len / res.table$seq_len * 100

tmp <- res.table %>%
  group_by(seq_pos, strand, frame) %>%
  summarise(
    seq_len = max(seq_len)
  )

chr.data <- data.frame(chr_name = character(), start = numeric(), end = numeric())
for (row in 1:nrow(tmp)) {
  chr_name <- paste0("Seq", tmp[row, "seq_pos"], "[", tmp[row, "strand"], ",", tmp[row, "frame"], "]")
  seq_len <- tmp[row, "seq_len"]
  
  chr.data <- rbind(chr.data, data.frame(chr_name = chr_name, start = 1, end = seq_len))
}
rm(tmp)

anno.data <- data.frame(elem_name = character(), chr_name = character(),
                        elem_start = numeric(), elem_end = numeric())
for (row in 1:nrow(res.table)) {
  chr_name <- paste0("Seq", res.table[row, "seq_pos"], "[", res.table[row, "strand"], ",", res.table[row, "frame"], "]")
  elem_name <- paste0(chr_name, res.table[row, "pos_start"], "-", res.table[row, "pos_end"])
  
  anno.data <- rbind(anno.data, data.frame(
    elem_name = elem_name, chr_name = chr_name,
    elem_start = res.table[row, "pos_start"], elem_end = res.table[row, "pos_end"]))
}

chromoMap(list(chr.data), list(anno.data), segment_annotation=T)


