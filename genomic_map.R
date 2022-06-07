# R genomic map
# install.packages("chromoMap")
library(chromoMap)

genomic_map <- function(df.orf) {
  tmp <- df.orf %>%
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
  for (row in 1:nrow(df.orf)) {
    chr_name <- paste0("Seq", df.orf[row, "seq_pos"], "[", df.orf[row, "strand"], ",", df.orf[row, "frame"], "]")
    elem_name <- paste0(chr_name, df.orf[row, "pos_start"], "-", df.orf[row, "pos_end"])
    
    anno.data <- rbind(anno.data, data.frame(
      elem_name = elem_name, chr_name = chr_name,
      elem_start = df.orf[row, "pos_start"], elem_end = df.orf[row, "pos_end"]))
  }
  
  return (chromoMap(list(chr.data), list(anno.data)))

}