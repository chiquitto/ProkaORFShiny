library(karyoploteR)

# TODO
# see Gviz package for visualization of ORFs <https://ivanek.github.io/Gviz/>
# see paper with example charts <https://www.nature.com/articles/s41467-021-24617-4 charts>

genomic_map <- function(df.orf, mainTitle=NA) {
  chr.name <- function(df) {
    # return (paste0("Seq", df$seq_pos, "[", df$strand, ",", df$frame, "]"))
    strand <- if(df$strand==1) "+" else "-"
    return (paste0("Frame", df$frame, strand))
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
  custom.cytobands <- toGRanges(data.frame(chr=chr.data,
                                           start=start.data,
                                           end=end.data,
                                           name=name.data,
                                           gieStain=gieStain.data))
  
  pp <- getDefaultPlotParams(plot.type=6)
  # pp$leftmargin <- 0.15
  pp$data2outmargin <- 30
  kp <- plotKaryotype(genome = custom.genome, cytobands = custom.cytobands, plot.type=6, plot.params = pp)
  if (!is.null(mainTitle)) kpAddMainTitle(kp, paste0("Sequence ID: ", mainTitle) ) # cex=2
  kpAddBaseNumbers(kp, tick.dist = 1000, add.units = TRUE, cex = 0.75)
  
  return (kp)
}