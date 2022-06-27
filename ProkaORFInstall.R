install.packages("shiny")
install.packages("ggplot2")
install.packages("dplyr")
install.packages("reticulate")

install.packages(c("MASS", "nlme"))

if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

BiocManager::install("karyoploteR")
