#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
# library(tibble)
library(ggplot2)
library(dplyr)

# library(ggpubr)
# theme_set(theme_pubr())

# https://rstudio.github.io/shinythemes/

library(reticulate)
use_python('/usr/bin/python3')

setwd('/home/alisson/work/github_chiquitto_ProkaORFShiny')

source('./genomic_map.R')

orf.script = 'orf_finder.py'
orf.result <- source_python(orf.script)

sample.orf.file = '/home/alisson/work/github_chiquitto_ProkaORFShiny/samples/Random1.fa'

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # App title ----
  titlePanel("Uploading Files"),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      # Input: Select a file ----
      fileInput("file1", "Choose fasta File"),
      
      tags$hr(),
      
      uiOutput("selectSeqNumber"),
      
      # Horizontal line ----
      tags$hr(),
      sliderInput('tmin', "Tamanho mínimo da orf", 15, 200,15)
      
    ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      
      # Output: Histogram ----
      plotOutput(outputId = "distPlot1"),
      
      plotOutput(outputId = "distPlot2"),
      
      # Output: Verbatim text for data summary ----
      verbatimTextOutput("summary"),
      
      # Output: Data file ----
      tableOutput("contents")
      
    )
    
  )
)

# Define server logic to read selected file ----
server <- function(input, output) {
  
  getDfOrf <- reactive({
    print("getDfOrf()")
    
    return (open.df(sample.orf.file , input$tmin))
    
    inFile <- input$file1
    if (is.null(inFile)) return (NULL)
    
    tminorf <- input$tmin
    print(paste0('Tamanho minimo da orf: ', tminorf))
    
    res.table <- open.df(inFile$datapath, tminorf)
    
    return (res.table)
  })
  
  getDfOrfFiltrado <- reactive({
    print("getDfOrfFiltrado()")
    if(is.null(input$selectSeqNumber)) return (NULL)
    
    df.orf <- getDfOrf()
    if(is.null(df.orf)) return (NULL)
    
    return (df.orf %>% filter(seq_id == input$selectSeqNumber))
  })
  
  output$selectSeqNumber <- renderUI({
    df.orf <- getDfOrf()
    if (is.null(df.orf)) return(NULL)
    
    selectInput("selectSeqNumber",
                label = "Selecione uma sequência:",
                choices = unique(df.orf$seq_id),
                multiple = FALSE)
  })
  
  # Generate a summary of the dataset ----
  output$summary <- renderPrint({
    df.orf <- getDfOrf()
    if(is.null(df.orf)) return (NULL)
    
    return (input$selectSeqNumber)
    # summary(df.orf, digits = 2)
  })
  
  output$contents <- renderTable({
    df.orf <- getDfOrf()
    if(is.null(df.orf)) return (NULL)
    
    return (df.orf)
    
    # df <- as.data.frame( do.call(cbind, lapply(df.orf, summary, digits = 2) ))
    # df
  }, rownames = TRUE, digits = 2)
  
  # ORF Coverage
  output$distPlot1 <- renderPlot({
    df.orf <- getDfOrfFiltrado()
    
    if(is.null(df.orf)) return (NULL)
    
    h = hist(df.orf$cobertura, plot=FALSE)
    h$density = h$counts / sum(h$counts) * 100
    
    plot(
      h,
      main = "Coverage Density",
      ylab = "Density (%)",
      xlab = "ORF Coverage (%)",
      freq = FALSE
    )
  })
  
  # ORF size
  output$distPlot2 <- renderPlot({
    df.orf <- getDfOrfFiltrado()

    if(is.null(df.orf)) return (NULL)

    return (genomic_map(df.orf))
    
  })
  
}

open.df <- function(datapath, tmin) {
  res.table <- print_csv(datapath , tmin)
  # View(res.table)
  
  # res.table <- head(res.table, n = 100)
  
  res.table <- res.table[, -which(names(res.table) %in% c("orf", "orf_nt", "orf_aa"))]
  res.table$cobertura = res.table$orf_len / res.table$seq_len * 100
  
  return (res.table)
}

# Run the application 
shinyApp(ui = ui, server = server)
