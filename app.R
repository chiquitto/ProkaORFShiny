#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tibble)
library(ggplot2)

library(ggpubr)
theme_set(theme_pubr())

# https://rstudio.github.io/shinythemes/

library(reticulate)
use_python('/usr/bin/python3')

setwd('/home/alisson/work/github_chiquitto_ProkaORFShiny')

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
    return (open.df(sample.orf.file , input$tmin))
    
    inFile <- input$file1
    if (is.null(inFile)) return (NULL)
    
    tminorf <- input$tmin
    print(paste0('Tamanho da orf: ', tminorf))
    
    res.table <- open.df(inFile$datapath, tminorf)
    
    return (res.table)
  })
  
  # Generate a summary of the dataset ----
  output$summary <- renderPrint({
    df.orf <- getDfOrf()
    if(is.null(df.orf)) return (NULL)
    
    summary(df.orf, digits = 2)
  })
  
  output$contents <- renderTable({
    df.orf <- getDfOrf()
    if(is.null(df.orf)) return (NULL)
    
    return (df.orf)
    
    df <- as.data.frame( do.call(cbind, lapply(df.orf, summary, digits = 2) ))
    df
  }, rownames = TRUE, digits = 2)
  
  # ORF Coverage
  output$distPlot1 <- renderPlot({
    df.orf <- getDfOrf()
    
    if(is.null(df.orf)) return (NULL)
    
    h = hist(df.orf$cobertura, plot=FALSE)
    h$density = h$counts / sum(h$counts) * 100
    
    plot(
      h,
      type = "p",
      main = "Coverage Density",
      ylab = "Density (%)",
      xlab = "ORF Coverage (%)",
      freq = FALSE
    )
  })
  
  # ORF size
  output$distPlot2 <- renderPlot({
    df.orf <- getDfOrf()
    
    if(is.null(df.orf)) return (NULL)
    
    # plot(
    #   density(df.orf$cobertura),
    #   main = "Coverage Density",
    #   ylab = "Density (count)",
    #   xlab = "ORF Coverage (%)",
    #   freq = FALSE
    # )
    
    a <- ggplot(df.orf, aes(x = orf_len))
    b <- a +
      geom_density(aes(y = ..density..), alpha = 0.2, fill = "#FF0000")
      # geom_density(aes(y = (..count..)/sum(..count..)), alpha = 0.5, fill = "#FF0000") +
      # scale_y_continuous(labels = scales::percent)
      # scale_y_continuous(labels = function(x) paste0(x, "%"))
    
    
    return (b)
  })
  
}

open.df <- function(datapath, tmin) {
  res.table <- print_csv(datapath , tmin)
  # View(res.table)
  
  # res.table <- head(res.table, n = 100)
  
  res.table <- res.table[, -which(names(res.table) %in% c("seq_id", "orf", "orf_nt", "orf_aa"))]
  res.table$cobertura = res.table$orf_len / res.table$seq_len * 100
  
  return (res.table)
}

# Run the application 
shinyApp(ui = ui, server = server)
