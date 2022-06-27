#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

# for ideas --> https://www.ncbi.nlm.nih.gov/orffinder/

library(shiny)
# library(tibble)
library(ggplot2)
library(dplyr)

# library(ggpubr)
# theme_set(theme_pubr())

# https://rstudio.github.io/shinythemes/

# https://cran.r-project.org/web/packages/reticulate/vignettes/versions.html
library(reticulate)
use_python('/usr/bin/python3')
# use_virtualenv("~/myenv")
# use_condaenv("myenv")

# setwd('/home/alisson/work/github_chiquitto_ProkaORFShiny')

source('./genomic_map.R')

orf.script = 'orf_finder.py'
orf.result <- source_python(orf.script)

sample.orf.file = '/home/alisson/work/github_chiquitto_ProkaORFShiny/samples/Random1.fa'

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # App title ----
  titlePanel("ORF Finder com Shiny"),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      # Input: Select a file ----
      fileInput("file1", "Choose FASTA File"),
      
      tags$hr(),
      
      uiOutput("selectSeqNumber"),
      
      # Horizontal line ----
      tags$hr(),
      sliderInput('tmin', "Tamanho mínimo da ORF", 15, 200, 30,
                  step = 5, round = TRUE)
      
    ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      tabsetPanel(type = 'tabs',
                  tabPanel('Histograma de cobertura',
                           plotOutput(outputId = "distPlot1")),
                  tabPanel('Regiões das ORFs',
                           plotOutput(outputId = "distPlot2")),
                  tabPanel('% ACGT',
                           plotOutput(outputId = "acgtPlot")),
                  tabPanel('Sumário',
                           verbatimTextOutput("summary")),
                  tabPanel('ORFs encontradas',
                           tableOutput("contents")),
                  tabPanel('Exportar',
                           downloadButton("downloadORFs", label = "Download ORFs"))
                  
      )
      
    )
    
  )
)

# Define server logic to read selected file ----
server <- function(input, output) {
  
  getDfOrf <- reactive({
    # print("getDfOrf()")
    # return (open.df(sample.orf.file , input$tmin))
    
    inFile <- input$file1
    if (is.null(inFile)) return (NULL)
    
    tminorf <- input$tmin
    print(paste0('Tamanho minimo da orf: ', tminorf))
    
    res.table <- open.df(inFile$datapath, tminorf)
    
    return (res.table)
  })
  
  getAcgtDf <- reactive({
    # print("getAcgtDf()")
    # return (open.acgt.df(sample.orf.file))
    
    inFile <- input$file1
    # if (is.null(inFile)) return (NULL)
    
    res.table <- open.acgt.df(inFile$datapath)
    
    return (res.table)
  })
  
  getDfOrfFiltrado <- reactive({
    # print("getDfOrfFiltrado()")
    if(is.null(input$selectSeqNumber)) return (NULL)
    
    df.orf <- getDfOrf()
    if(is.null(df.orf)) return (NULL)
    
    return (df.orf %>% filter(seq_id == input$selectSeqNumber))
  })
  
  output$selectSeqNumber <- renderUI({
    df.orf <- getDfOrf()
    if (is.null(df.orf)) return(NULL)
    
    selectInput("selectSeqNumber",
                label = "ID da sequência:",
                choices = unique(df.orf$seq_id),
                multiple = FALSE)
  })
  
  # Generate a summary of the dataset ----
  output$summary <- renderPrint({
    df.orf <- getDfOrfFiltrado()
    if(is.null(df.orf)) return (NULL)
    
    summary(df.orf[, which(names(df.orf) %in% c("pos_start", "pos_end", "orf_len", "cobertura"))], digits = 2)
  })
  
  output$contents <- renderTable({
    df.orf <- getDfOrfFiltrado()
    if(is.null(df.orf)) return (NULL)
    
    return (df.orf)
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

    return (genomic_map(df.orf, mainTitle=input$selectSeqNumber))
    
  })
  
  # % ACGT
  output$acgtPlot <- renderPlot({
    df <- getAcgtDf()
    
    # Evita que dê erro
    if(is.null(df)) return(NULL)
    
    g <- ggplot(df, aes(y = seqs)) +
      geom_bar(aes(fill = atcg), position = position_stack(reverse = TRUE)) +
      theme(legend.position = "top") + 
      labs(title = "Contagem ACGT por sequência", x = "Contagem em %", y = "Nome da sequência", fill ='')
    g
  })
  
  # Download button
  output$downloadORFs <- downloadHandler(
      filename = function() {
        paste('orfs.csv', sep='')
      },
      content = function(con) {
        write.csv(getDfOrf(), con)
      }
    )
  
}

open.df <- function(datapath, tmin) {
  res.table <- print_csv(datapath , tmin)
  # View(res.table)
  
  # res.table <- head(res.table, n = 100)
  
  res.table <- res.table[, -which(names(res.table) %in% c("orf", "orf_nt", "orf_aa"))]
  res.table$cobertura = res.table$orf_len / res.table$seq_len * 100
  
  return (res.table)
}

open.acgt.df <- function(datapath) {
  res.table <- getCountatcg(datapath)
  # View(res.table)
  
  return (res.table)
}

# Run the application 
shinyApp(ui = ui, server = server)
