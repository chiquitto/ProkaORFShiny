library(shiny)

# Define UI for data upload app ----
ui <- fluidPage(
  
  # App title ----
  titlePanel("Uploading Files"),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      # Input: Select a file ----
      fileInput("file1", "Choose CSV File",
                multiple = FALSE,
                accept = c("text/csv",
                           "text/comma-separated-values,text/plain",
                           ".csv")),
      
      # Horizontal line ----
      tags$hr(),
      
      # Input: Checkbox if file has header ----
      checkboxInput("header", "Header", TRUE),
      
      # Input: Select separator ----
      radioButtons("sep", "Separator",
                   choices = c(Comma = ",",
                               Semicolon = ";",
                               Tab = "\t"),
                   selected = ","),
      
      # Input: Select quotes ----
      radioButtons("quote", "Quote",
                   choices = c(None = "",
                               "Double Quote" = '"',
                               "Single Quote" = "'"),
                   selected = '"'),
      
      # Horizontal line ----
      tags$hr(),
      
      # Input: Select number of rows to display ----
      radioButtons("disp", "Display",
                   choices = c(Head = "head",
                               All = "all"),
                   selected = "head")
      
    ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      
      # Output: Verbatim text for data summary ----
      verbatimTextOutput("summary"),
      
      # Output: Data file ----
      tableOutput("contents"),
      
      # Output: Histogram ----
      plotOutput(outputId = "distPlot")
      
    )
    
  )
)

# Define server logic to read selected file ----
server <- function(input, output) {
  
  datasetInput <- reactive({
    inFile <- input$file1
    if (is.null(inFile)) return(NULL)
    
    df <- read.csv(inFile$datapath,
                   header = TRUE, # input$header,
                   sep = input$sep,
                   quote = input$quote)
    df
    
    #data <- read.csv(inFile$datapath, header = TRUE)
    #data
  })
  
  #req(input$file1)
  
  # df <- read.csv(input$file1$datapath,
  #                header = input$header,
  #                sep = input$sep,
  #                quote = input$quote)
  
  # Generate a summary of the dataset ----
  output$summary <- renderPrint({
    # dataset <- df
    summary(datasetInput())
  })
  
  # Show the first "n" observations ----
  output$contents <- renderTable({
    head(datasetInput(), n = 10)
  })
  
  output$distPlot <- renderPlot({
    x    <- datasetInput()
    bins <- seq(min(x), max(x), length.out = 10)
    
    hist(x$A, breaks = bins, col = "#75AADB", border = "white",
         xlab = "Waiting time to next eruption (in mins)",
         main = "Histogram of waiting times")
    
  })
  
}

# Create Shiny app ----
shinyApp(ui, server)